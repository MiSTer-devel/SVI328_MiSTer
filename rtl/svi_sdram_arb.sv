// SDRAM reads for the tape player (rtl/cassette.v) and the megaROM page
// prefetch (rtl/svi_megarom.sv), one at a time through sdram.sv's port.
//
// sdram.sv starts a read on a rising edge of rd and drops ready (unless the
// word is the one it read last); ready rises one clock before the data. Each
// read here is: rd up for one clock, wait for ready, take dout the clock after.
//
// The tape player keeps its own handshake (a rising edge of its rd, then wait
// for ready): its request is caught on the edge and answered with its byte
// held in cas_data. It goes first; the prefetch has ~120 ms to spare.
// Nothing new starts while hold (an ioctl download writing the SDRAM).

module svi_sdram_arb (
    input             clk,
    input             hold,

    input             cas_rd,
    input      [24:0] cas_addr,
    output reg  [7:0] cas_data = 0,
    output            cas_ready,

    input             mr_req,
    input      [24:0] mr_addr,
    output reg        mr_ack = 0,
    output reg  [7:0] mr_data = 0,

    output reg        rd = 0,
    output reg [24:0] addr = 0,
    input       [7:0] dout,
    input             ready
);

localparam IDLE = 3'd0, ISSUE = 3'd1, WAIT = 3'd2, TAKE = 3'd3, GAP = 3'd4;

reg  [2:0] st = IDLE;
reg        owner = 0;          // 0 tape, 1 megaROM
reg        cas_rd_r = 0, cas_pend = 0;
reg [24:0] cas_a = 0;

assign cas_ready = ~cas_pend;

always @(posedge clk) begin
    mr_ack   <= 0;
    cas_rd_r <= cas_rd;
    if (cas_rd & ~cas_rd_r) begin
        cas_pend <= 1;
        cas_a    <= cas_addr;
    end

    case (st)
        IDLE: if (!hold) begin
            if (cas_pend) begin
                owner <= 0; addr <= cas_a;   rd <= 1; st <= ISSUE;
            end else if (mr_req) begin
                owner <= 1; addr <= mr_addr; rd <= 1; st <= ISSUE;
            end
        end
        ISSUE: begin rd <= 0; st <= WAIT; end
        WAIT:  if (ready) st <= TAKE;
        TAKE: begin
            if (owner) begin mr_data <= dout; mr_ack <= 1; end
            else begin cas_data <= dout; cas_pend <= 0; end
            st <= GAP;
        end
        GAP:   st <= IDLE;              // the requester moves to its next address
        default: st <= IDLE;
    endcase
end

endmodule
