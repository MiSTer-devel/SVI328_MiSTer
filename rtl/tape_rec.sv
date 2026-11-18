// SVI-318/328 tape recorder: turns what the BIOS writes on PPI C5 (CSAVE,
// BSAVE"CAS:", SAVE"CAS:") back into a CAS file, written through an hps_io
// virtual disk (OSD "Tape save").
//
// The BIOS writes every bit as one square wave cycle, high half then low half
// (measured in the simulator): a 1 is ~740 + 740 Z80 clocks (2.4 kHz), a 0 is
// ~1490 + 1490 (1.2 kHz); the low half of the last bit of a byte can stretch to
// ~1780. Each half is timed in Z80 clocks (so tape turbo, which runs the Z80
// 4x, changes nothing) and called short or long at 1110. Two equal halves make
// a bit; a mixed pair means the count started on the wrong half, so the first
// one is dropped (this also takes either polarity).
//
// A block is the leader (55h, no start bits), 7Fh, then bytes as a 0 start bit
// and 8 bits MSB first: exactly what rtl/cassette.v plays. On 55h 7Fh in the
// bit stream the recorder writes 16 x 55h + 7Fh (the CAS block mark), then
// every framed byte. The block ends when the motor stops or nothing is written
// for 6000 Z80 clocks (1.7 ms; the BIOS leaves ~0.5 s between blocks).
//
// The file: the CAS bytes from offset 0, in 512-byte sectors. Main can't grow a
// mounted image, so the file must already be big enough (a blank one is in
// releases/); what isn't recorded keeps its old contents, except the rest of
// the last sector, which is zeros. Mounting rewinds to the start. Recording
// goes on across blocks and files, as on a real tape, until the file is full.
//
// Sectors: two 512-byte banks. A full bank is written out while the other
// fills; at the end of every block the bank in use is written as it stands
// (the same sector is written again when more data comes), so the file is
// complete whenever the motor is off.

module tape_rec (
    input             clk,
    input             ce_cpu,        // one per Z80 clock (turbo included)
    input             cas_out,       // PPI C5: tape write data
    input             motor_on,

    input             img_mounted,   // hps_io VD for "Tape save"
    input             img_readonly,
    input      [63:0] img_size,
    output reg [31:0] sd_lba = 0,
    output            sd_rd,
    output reg        sd_wr = 0,
    input             sd_ack,
    input       [8:0] sd_buff_addr,
    output reg  [7:0] sd_buff_din,

    output reg        active = 0,    // a writable file is mounted
    output            recording,     // inside a block (bytes going to the file)
    output reg        full = 0,      // the file is full
    output reg [24:0] length = 0     // bytes recorded since the mount
);

localparam [15:0] TH  = 16'd1110;   // short / long half
localparam [15:0] GAP = 16'd6000;   // end of block

assign sd_rd = 1'b0;

// sector side (declared first: the byte side uses them)
reg  [7:0] buff[1024];
reg        bank = 0;
reg  [8:0] ptr = 0;
reg [31:0] cur_lba = 0;
reg [10:0] clr = 0;           // bytes still to clear (bank switch: 512, mount: 1024)
reg  [9:0] clr_a = 0;
reg  [1:0] dirty = 0;
reg [31:0] lba_of[2];
reg        busy = 0, wbank = 0;
reg        mount_now = 0;
reg [40:0] rec_size = 0;      // img_size is shared by every VD: latched at mount
wire       flush_ack;

// ---------------------------------------------------------------- bits
reg  [15:0] cnt = 0;
reg         out_r = 1, motor_r = 0;
reg         pend = 0, pend_l = 0;    // a half is waiting for its pair
reg         bit_v = 0, bit_d = 0;    // a bit (one clock)
reg         blk_end = 0;             // one clock
wire        edge_ = cas_out ^ out_r;

always @(posedge clk) begin
    bit_v   <= 0;
    blk_end <= 0;
    out_r   <= cas_out;
    motor_r <= motor_on;

    if (ce_cpu && cnt != 16'hFFFF) cnt <= cnt + 1'd1;

    if (edge_) begin
        cnt <= 0;
        if (cnt > GAP) pend <= 0;                 // first edge after a gap
        else if (!pend) begin pend <= 1; pend_l <= cnt > TH; end
        else if (pend_l != (cnt > TH)) pend_l <= cnt > TH;   // realign
        else begin
            pend  <= 0;
            bit_v <= 1;
            bit_d <= ~pend_l;                      // long = 0, short = 1
        end
    end else if (ce_cpu && cnt == GAP) begin
        pend    <= 0;
        blk_end <= 1;
    end

    if (motor_r & ~motor_on) begin
        pend    <= 0;
        blk_end <= 1;
    end
end

// ---------------------------------------------------------------- bytes
localparam HUNT = 2'd0, START = 2'd1, DATA = 2'd2;
reg  [1:0] st = HUNT;
reg [15:0] sr = 0;
reg  [7:0] byte_sr = 0;
reg  [2:0] nb = 0;
reg  [4:0] lead = 0;          // block mark bytes still to write (17 .. 1)
reg        dv = 0;            // a data byte waits in dbyte
reg  [7:0] dbyte = 0;
reg        flush = 0;         // write the bank in use at the end of a block

assign recording = st != HUNT;

// emitter: the block mark first, then data bytes
wire       e_req  = (lead != 0) | dv;
wire [7:0] e_byte = (lead != 0) ? ((lead == 5'd1) ? 8'h7F : 8'h55) : dbyte;
wire       e_ack;

always @(posedge clk) begin
    if (e_ack) begin
        if (lead != 0) lead <= lead - 1'd1;
        else dv <= 0;
    end

    if (bit_v) begin
        case (st)
            HUNT: begin
                sr <= {sr[14:0], bit_d};
                if ({sr[14:0], bit_d} == 16'h557F) begin
                    st   <= START;
                    lead <= 5'd17;
                end
            end
            START: if (!bit_d) begin st <= DATA; nb <= 0; end
            DATA: begin
                byte_sr <= {byte_sr[6:0], bit_d};
                nb      <= nb + 1'd1;
                if (nb == 3'd7) begin
                    dbyte <= {byte_sr[6:0], bit_d};
                    dv    <= 1;
                    st    <= START;
                end
            end
            default: st <= HUNT;
        endcase
    end

    if (blk_end) begin
        if (st != HUNT) flush <= 1;
        st <= HUNT;
        sr <= 0;
    end
    if (flush_ack) flush <= 0;

    if (mount_now) begin
        st <= HUNT; sr <= 0; lead <= 0; dv <= 0; flush <= 0;
    end
end

// ---------------------------------------------------------------- sectors

// a bank can be reused once it has been written out
wire       next_free = ~dirty[~bank] & ~(busy & (wbank == ~bank));
wire       room      = ({cur_lba[31:0], 9'd0} < rec_size);
assign     e_ack     = e_req & active & room & (clr == 0) & ~mount_now &
                       ~(ptr == 9'd511 & ~next_free);
assign     flush_ack = flush & (clr == 0) & ~e_req & ~mount_now;

always @(posedge clk) begin
    reg old_mounted, old_ack;

    // HPS side
    sd_buff_din <= buff[{wbank, sd_buff_addr}];

    mount_now   <= 0;
    old_mounted <= img_mounted;
    if (~old_mounted & img_mounted) begin
        active    <= (img_size != 0) & ~img_readonly;
        rec_size  <= img_size[40:0];
        mount_now <= 1;
    end

    if (mount_now) begin
        bank    <= 0;
        ptr     <= 0;
        cur_lba <= 0;
        dirty   <= 0;
        clr     <= 11'd1024;
        clr_a   <= 0;
        length  <= 0;
        full    <= 0;
    end else if (clr != 0) begin
        buff[clr_a] <= 8'd0;
        clr_a       <= clr_a + 1'd1;
        clr         <= clr - 1'd1;
    end else if (e_ack) begin
        buff[{bank, ptr}] <= e_byte;
        length <= length + 1'd1;
        ptr    <= ptr + 1'd1;
        if (ptr == 9'd511) begin
            dirty[bank]  <= 1;
            lba_of[bank] <= cur_lba;
            bank         <= ~bank;
            cur_lba      <= cur_lba + 1'd1;
            clr          <= 11'd512;
            clr_a        <= {~bank, 9'd0};
        end
    end else if (flush_ack) begin
        if (ptr != 0) begin
            dirty[bank]  <= 1;
            lba_of[bank] <= cur_lba;
        end
    end

    if (active & e_req & ~room) full <= 1;

    // writer: the older bank first
    old_ack <= sd_ack;
    if (!busy && !mount_now && clr == 0) begin
        if (dirty[~bank]) begin
            busy <= 1; wbank <= ~bank; sd_lba <= lba_of[~bank]; sd_wr <= 1;
            dirty[~bank] <= 0;
        end else if (dirty[bank] && !(e_ack || flush_ack)) begin
            busy <= 1; wbank <= bank; sd_lba <= lba_of[bank]; sd_wr <= 1;
            dirty[bank] <= 0;
        end
    end
    if (~old_ack & sd_ack) sd_wr <= 0;
    if (old_ack & ~sd_ack) busy <= 0;
end

endmodule
