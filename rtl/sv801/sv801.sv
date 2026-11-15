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
// One drive (drive 0). Images: raw .dsk as MAME's svi_dsk.cpp, 172032 bytes
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

    input         img_mounted,
    input         img_readonly,
    input  [63:0] img_size,
    output [31:0] sd_lba,
    output        sd_rd,
    output        sd_wr,
    input         sd_ack,
    input   [8:0] sd_buff_addr,
    input   [7:0] sd_buff_dout,
    output  [7:0] sd_buff_din,
    input         sd_buff_wr,

    output        led             // drive 0 motor
);

wire sel_fdc = enable && iorq && addr[7:2] == 6'b001100;   // 30h-33h
wire sel_34  = enable && iorq && addr == 8'h34;
wire sel_38  = enable && iorq && addr == 8'h38;

reg  [3:0] drivesel = 4'd0;
reg  [1:0] side_density = 2'd0;
reg        fdd_ready = 1'b0;
reg        layout = 1'b0;
reg        wp = 1'b0;
wire       drq, intrq;
wire [7:0] fdc_dout;

assign dout    = sel_34 ? {intrq, drq, 6'd0} : fdc_dout;
assign dout_en = rd && (sel_fdc || sel_34);
assign led     = drivesel[2];

always @(posedge clk) begin
    reg old_mounted, old_wr;
    old_mounted <= img_mounted;
    if (~old_mounted & img_mounted) begin
        fdd_ready <= |img_size;
        wp        <= img_readonly;
        // 2A000h single-sided, 54800h double-sided (bit 14 tells them apart)
        layout    <= ~img_size[14];
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

wd1793 #(.RWMODE(1), .EDSK(0)) fdc
(
    .clk_sys(clk),
    .ce(ce),
    .reset(reset),
    .io_en(1'b1),
    .rd(rd && sel_fdc),
    .wr(wr && sel_fdc),
    .addr(addr[1:0]),
    .din(din),
    .dout(fdc_dout),
    .drq(drq),
    .intrq(intrq),
    .busy(),

    .wp(wp),

    .size_code(3'd5),
    .layout(layout),
    .side(side_density[1]),
    .ready(fdd_ready & drivesel[0]),
    .prepare(),

    .img_mounted(img_mounted),
    .img_size(img_size[19:0]),

    .sd_lba(sd_lba),
    .sd_rd(sd_rd),
    .sd_wr(sd_wr),
    .sd_ack(sd_ack),
    .sd_buff_addr(sd_buff_addr),
    .sd_buff_dout(sd_buff_dout),
    .sd_buff_din(sd_buff_din),
    .sd_buff_wr(sd_buff_wr),

    .input_active(1'b0),
    .input_addr(20'd0),
    .input_data(8'd0),
    .input_wr(1'b0),
    .buff_din(8'd0),
    .buff_addr(),
    .buff_read()
);

endmodule
