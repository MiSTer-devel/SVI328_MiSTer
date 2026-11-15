// SV-806 80-column card: HD6845 CRTC (ports 50h address, 51h data), 2 KB of
// display RAM that port 58h bit 0 maps over F000-F7FF, a 4 KB character
// generator, and its own monochrome video output.
//
// After teiram's Calypso port of this core (svi328/svi806/svi806_top.sv, read
// from the STM-I schematic): the 12 MHz dot clock, 7 dots per character
// (12 MHz / 7: with the CP/M BIOS's R0 = 107 a line is 63 us, 15.9 kHz;
// R4/R5 give 317 lines, 50 Hz), the WAIT circuit (IC24/IC25) that holds the
// Z80 on a display-RAM access until the CRTC's next character slot, and the
// character ROM addressed as {code, row[3:0]}. The Altera RAM/ROM megafunctions
// are replaced by inferred block RAM here, and the character ROM is loaded at
// core start (boot1.rom = svi806.rom, MAME sv806.ic27).
//
// With enable = 0 the card is absent: its ports and RAM don't answer, port 51h
// reads FF, and the CP/M BIOS (nit80: OUT 50h,0Fh; OUT 51h,0; IN 51h) finds no
// card.

module sv806 (
    input         clk,
    input         cpu_ce,         // Z80 clock enable (positive phase)
    input         pix_ce,         // 12 MHz dot clock enable
    input         reset,
    input         enable,

    input  [15:0] cpu_addr,
    input   [7:0] cpu_din,
    input         cpu_mreq_n,
    input         cpu_iorq_n,     // I/O cycle only (not interrupt acknowledge)
    input         cpu_rd_n,
    input         cpu_wr_n,

    output  [7:0] cpu_dout,
    output        dout_en,        // the card drives the data bus (read)
    output        cpu_wait,
    output        ramdis,         // the card's RAM replaces main RAM at this address

    // character ROM load (boot1.rom)
    input         rom_wr,
    input  [11:0] rom_addr_w,
    input   [7:0] rom_din,

    output reg    video = 1'b0,
    output        hsync,
    output        vsync,
    output reg    de = 1'b0
);

wire [13:0] crtc_ma;
wire  [4:0] crtc_ra;
wire  [7:0] crtc_do;
wire        crtc_de, crtc_cursor;
wire        crtc_ce, crtc_ce_n, chrld;

wire ioreq_n  = cpu_iorq_n | (cpu_rd_n & cpu_wr_n);
wire crten_n  = ~(enable && cpu_addr[7:4] == 4'h5 && !ioreq_n);
wire crtcs_n  = cpu_addr[3] | crten_n;           // 50h/51h: CRTC
wire crtex_en = crten_n | ~cpu_addr[3];          // 0 during an I/O cycle at 58h

reg crtex = 1'b0;
always @(posedge clk) begin
    reg crtex_en_last;
    crtex_en_last <= crtex_en;
    if (reset) crtex <= 1'b0;
    else if (~crtex_en_last & crtex_en) crtex <= cpu_din[0];
end

wire vram = enable && !cpu_mreq_n && cpu_addr[15:11] == 5'b11110 && crtex;
assign ramdis = vram;

// WAIT: set at the start of a display-RAM access, released after the next
// CRTC character slot (IC24-1, IC24-2, IC25).
reg wait_n = 1'b1, wait_clr = 1'b0, pre_wait_clr = 1'b0;
assign cpu_wait = ~wait_n;
always @(posedge clk) begin
    reg last_vram;
    last_vram <= vram;
    if (wait_clr) wait_n <= 1'b1;
    else if (~last_vram & vram) wait_n <= 1'b0;
    if (crtc_ce_n) pre_wait_clr <= ~wait_n;
    if (crtc_ce)   wait_clr <= pre_wait_clr;
end
wire mpx = pre_wait_clr | wait_clr;              // the CPU owns the RAM

reg crtc_en = 1'b0;
always @(posedge clk) begin
    if (cpu_ce) crtc_en <= ~ioreq_n;
    else if (ioreq_n) crtc_en <= 1'b0;
end

// Character timing: 7 dots per character.
reg [2:0] cnt = 3'b001;
always @(posedge clk) if (pix_ce) cnt <= (cnt == 3'b111) ? 3'b001 : cnt + 3'd1;
assign crtc_ce   = pix_ce && cnt == 3'b001;
assign crtc_ce_n = pix_ce && cnt == 3'b100;
assign chrld     = pix_ce && cnt == 3'b111;

// Display RAM (2 KB): port A the CRTC, port B the CPU.
reg [7:0] vram_mem [0:2047];
reg [7:0] vram_q, vram_cpu_q;
always @(posedge clk) vram_q <= vram_mem[crtc_ma[10:0]];
always @(posedge clk) begin
    if (mpx & ~cpu_wr_n & vram) vram_mem[cpu_addr[10:0]] <= cpu_din;
    vram_cpu_q <= vram_mem[cpu_addr[10:0]];
end

// Character ROM (4 KB): {code, row}.
reg [7:0] rom_mem [0:4095];
reg [7:0] rom_data;
always @(posedge clk) begin
    if (rom_wr) rom_mem[rom_addr_w] <= rom_din;
    rom_data <= rom_mem[{vram_q, crtc_ra[3:0]}];
end

reg cursor = 1'b0;
always @(posedge clk) begin
    reg [7:0] pixel_data;
    if (pix_ce) begin
        video <= pixel_data[7] | cursor;
        pixel_data <= {pixel_data[6:0], 1'b0};
        if (chrld) pixel_data <= rom_data;
    end
end

um6845r crtc
(
    .CLOCK(clk),
    .CLKEN(crtc_ce),
    .nRESET(~reset),
    .CRTC_TYPE(1'b0),

    .ENABLE(crtc_en),
    .nCS(crtcs_n),
    .R_nW(~cpu_rd_n),
    .RS(cpu_addr[0]),
    .DI(cpu_din),
    .DO(crtc_do),

    .VSYNC(vsync),
    .HSYNC(hsync),
    .DE(crtc_de),
    .FIELD(),
    .CURSOR(crtc_cursor),

    .MA(crtc_ma),
    .RA(crtc_ra)
);

always @(posedge clk) begin
    if (reset) de <= 1'b0;
    else if (crtc_ce) de <= crtc_de;
end

always @(posedge clk) begin
    if (reset) cursor <= 1'b0;
    else if (chrld) cursor <= crtc_cursor;
end

assign cpu_dout = !crten_n ? crtc_do : vram_cpu_q;
assign dout_en  = (!crten_n && !crtcs_n || vram) && !cpu_rd_n;

endmodule
