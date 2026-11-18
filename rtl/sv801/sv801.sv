// SV-801 disk controller: FD1793 at ports 30h-33h, drive / motor latch at
// 34h, density / side latch at 38h (MAME bus/svi3x8/slot/sv801.cpp, the CP/M
// BIOS sources in refs/docs/cpm). The CPU polls INTRQ / DRQ at port 34h; the
// card has no interrupt or DMA line and no ROM (Disk BASIC and CP/M boot
// through the BASIC ROM).
//
//   30h R status    W command        34h R bit 7 INTRQ, bit 6 DRQ
//   31h   track                      34h W bit 0/1 drive 0/1 select, 2/3 motor
//   32h   sector                     38h W bit 0 FM (1) / MFM (0), bit 1 side
//   33h   data
//
// Two drives (A: and B:, one FD1793 replica each: the CPU talks to the
// selected one, as the real card's single FD1793 talks to the selected drive). Images: raw .dsk as MAME's svi_dsk.cpp, 172032 bytes
// (single-sided, 40 tracks) or 346112 (double-sided, sides interleaved by
// track); track 0 side 0 is 18 x 128 bytes, every other track 17 x 256.
// After teiram's Calypso port (svi328/sv801/sv801.sv). With enable = 0 the
// ports don't answer (reads give FF), as with no card in the expander.

module sv801 (
    input         clk,
    input         ce,             // FDC timebase (~1.79 MHz; not sped up by tape turbo)
    input         reset,
    input         enable,         // OSD: the card is present

    input         iorq,           // I/O cycle (not interrupt acknowledge)
    input         rd,
    input         wr,
    input  [7:0]  addr,
    input  [7:0]  din,
    output [7:0]  dout,
    output        dout_en,        // this card drives the data bus

    // one set per drive: [0] = A:, [1] = B: (hps_io VD 0 and 1)
    input   [1:0] img_mounted,
    input         img_readonly,
    input  [63:0] img_size,
    output [31:0] sd_lba0,
    output [31:0] sd_lba1,
    output  [1:0] sd_rd,
    output  [1:0] sd_wr,
    input   [1:0] sd_ack,
    input   [8:0] sd_buff_addr,
    input   [7:0] sd_buff_dout,
    output  [7:0] sd_buff_din0,
    output  [7:0] sd_buff_din1,
    input         sd_buff_wr,

    output        led             // a drive motor is on
);

wire sel_fdc = enable && iorq && addr[7:2] == 6'b001100;   // 30h-33h
wire sel_34  = enable && iorq && addr == 8'h34;
wire sel_38  = enable && iorq && addr == 8'h38;

reg  [3:0] drivesel = 4'd0;
reg  [1:0] side_density = 2'd0;
reg  [1:0] fdd_ready = 2'b00;
reg  [1:0] layout = 2'b00;
reg  [1:0] wp = 2'b00;
wire [1:0] drq, intrq;
wire [7:0] fdc_dout[2];

// Drive B: is the selected one only when bit 1 is set and bit 0 is not; with
// no drive selected the FDC still answers (drive A:'s replica, not ready).
wire       drv = drivesel[1] & ~drivesel[0];

assign dout    = sel_34 ? {intrq[drv], drq[drv], 6'd0} : fdc_dout[drv];
assign dout_en = rd && (sel_fdc || sel_34);
assign led     = drivesel[2] | drivesel[3];

always @(posedge clk) begin
    reg [1:0] old_mounted;
    reg       old_wr;
    old_mounted <= img_mounted;
    for (int i = 0; i < 2; i++) begin
        if (~old_mounted[i] & img_mounted[i]) begin
            fdd_ready[i] <= |img_size;
            wp[i]        <= img_readonly;
            // 2A000h single-sided, 54800h double-sided (bit 14 tells them apart)
            layout[i]    <= ~img_size[14];
        end
    end

    old_wr <= wr && (sel_34 || sel_38);
    if (reset) begin
        drivesel     <= 4'd0;
        side_density <= 2'd0;
    end else if (wr && !old_wr) begin
        if (sel_34) drivesel     <= din[3:0];
        if (sel_38) side_density <= din[1:0];
    end
end

wire [31:0] lba[2];
wire  [7:0] bdin[2];
assign sd_lba0 = lba[0];
assign sd_lba1 = lba[1];
assign sd_buff_din0 = bdin[0];
assign sd_buff_din1 = bdin[1];

genvar d;
generate
    for (d = 0; d < 2; d = d + 1) begin : drive
        wd1793 #(.RWMODE(1), .EDSK(0)) fdc
        (
            .clk_sys(clk),
            .ce(ce),
            .reset(reset),
            .io_en(1'b1),
            .rd(rd && sel_fdc && drv == d),
            .wr(wr && sel_fdc && drv == d),
            .addr(addr[1:0]),
            .din(din),
            .dout(fdc_dout[d]),
            .drq(drq[d]),
            .intrq(intrq[d]),
            .busy(),

            .wp(wp[d]),

            .size_code(3'd5),
            .layout(layout[d]),
            .side(side_density[1]),
            .ready(fdd_ready[d] & drivesel[d]),
            .prepare(),

            .img_mounted(img_mounted[d]),
            .img_size(img_size[19:0]),

            .sd_lba(lba[d]),
            .sd_rd(sd_rd[d]),
            .sd_wr(sd_wr[d]),
            .sd_ack(sd_ack[d]),
            .sd_buff_addr(sd_buff_addr),
            .sd_buff_dout(sd_buff_dout),
            .sd_buff_din(bdin[d]),
            .sd_buff_wr(sd_buff_wr),

            .input_active(1'b0),
            .input_addr(20'd0),
            .input_data(8'd0),
            .input_wr(1'b0),
            .buff_din(8'd0),
            .buff_addr(),
            .buff_read()
        );
    end
endgenerate

endmodule
