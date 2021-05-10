//============================================================================
//  SVI-328 based on Sorgelig's ColecoVision Mister port
//
//  
//  Copyright (C) 2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


// TODO
//  - Complete Keyboard Mapping
//  - Make Memory size select from OSD
//  - Select PAL/NTSC
//  - OSD Load Keyboard Map 
//  - Tape Load Graphical wave
//  - Tape Counter (bytes)

// Done
//  - Rewind on CAS load or Reset
//  - LED_Disk on Tape Load

//Core : 
//Z80 - 3,5555Mhz
//AY - z80/2 = 1,777 Mhz
//Mess :
//Z80 - 3,579545
//AY - 1,789772

//`define Bram


module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

`ifdef USE_DDRAM
	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
`endif

`ifdef USE_SDRAM
	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

//assign ADC_BUS = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
 
assign LED_USER   = ioctl_download;
assign LED_DISK  = {1'b0, svi_audio_in};
assign LED_POWER  = 0;
assign BUTTONS    = 0;
assign VGA_SCALER = 0;

wire [1:0] ar = status[2:1];
wire vga_de;
reg  en216p;
always @(posedge CLK_VIDEO) en216p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);

video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE(en216p ? 10'd216 : 10'd0),
	.CROP_OFF(0),
	.SCALE(status[11:10])
);

`include "build_id.v" 
parameter CONF_STR = {
	"SVI328;;",
	"-;",
	"F1,BINROM,Load Cartridge;",
	"OF,Tape Input,File,ADC;",
	"D0F2,CAS,Cas File;",
	"D0TD,Tape Rewind;",
	"-;",
	"O12,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O79,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"O6,Border,No,Yes;",
	"OAB,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O3,Joysticks swap,No,Yes;",
	"R0,Reset;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////

wire clk_sys;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.locked(pll_locked)
);

reg ce_10m7 = 0;
reg ce_5m3 = 0;
reg ce_21m3 = 0;
always @(posedge clk_sys) begin
	reg [2:0] div;
	
	div <= div+1'd1;
	ce_10m7 <= !div[1:0];
	ce_5m3  <= !div[2:0];
	ce_21m3 <= div[0];
end

/////////////////  HPS  ///////////////////////////

wire [31:0] status;
wire  [1:0] buttons;

wire [31:0] joy0, joy1;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire        ioctl_wait = ~sdram_rdy;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire [10:0] PS2Keys;
 
hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),

	.status_menumask({status[15]}),	
	
	.ps2_key(PS2Keys),
	
	.joystick_0(joy0), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy1)

);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1] | (ioctl_download && ioctl_isROM);

////////////////  KeyBoard  ///////////////////////


wire [3:0] svi_row;
wire [7:0] svi_col;
sviKeyboard KeyboardSVI
(
	.clk		(clk_sys),
	.reset	(reset),
	
	.keys		(PS2Keys),
	.svi_row (svi_row),
	.svi_col (svi_col)
	
);


wire [15:0] cpu_ram_a;
wire        ram_we_n, ram_rd_n, ram_ce_n;
wire  [7:0] ram_di;
wire  [7:0] ram_do;


wire [13:0] vram_a;
wire        vram_we;
wire  [7:0] vram_di;
wire  [7:0] vram_do;

spram #(14) vram
(
	.clock(clk_sys),
	.address(vram_a),
	.wren(vram_we),
	.data(vram_do),
	.q(vram_di)
);


wire sdram_rdy;

`ifdef Bram
spram #(18) ram
(
	.clock(clk_sys),
	.address(ioctl_download ? {ioctl_index[0],ioctl_addr[15:0]} : ram_a),
	.wren((ioctl_wr | ( isRam & ~(ram_we_n | ram_ce_n)))), 
	.data(ioctl_wr ? ioctl_dout : ram_do),
	.q(ram_di)
);
assign sdram_rdy = 1'b1; 
`else 

wire sdram_we,sdram_rd;
wire [17:0] sdram_addr;
wire  [7:0] sdram_din;
wire ioctl_isROM = (ioctl_index[5:0]<6'd2); //Index osd File is 0 (ROM) or 1(Rom Cartridge)


assign sdram_we = (ioctl_wr && ioctl_isROM) | ( isRam & ~(ram_we_n | ram_ce_n));
assign sdram_addr = (ioctl_download && ioctl_isROM) ? {ioctl_index[0],ioctl_addr[15:0]} : ram_a;
assign sdram_din = (ioctl_wr && ioctl_isROM) ? ioctl_dout : ram_do;

assign sdram_rd = ~(ram_rd_n | ram_ce_n);
assign SDRAM_CLK = ~clk_sys;
sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

   .wtbt(0),
   .addr(sdram_addr), 
   .rd(sdram_rd),
   .dout(ram_di),
   .din(sdram_din),
   .we(sdram_we), 
   .ready(sdram_rdy)
);
`endif


wire [17:0] ram_a;
wire isRam;

wire motor;

svi_mapper RamMapper
(
    .addr_i		(cpu_ram_a),
    .RegMap_i	(ay_port_b),
    .addr_o		(ram_a),
	 .ram			(isRam)
);


////////////////  Console  ////////////////////////

wire [10:0] audio;
assign AUDIO_L = {audio,5'd0};
assign AUDIO_R = {audio,5'd0};
assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign CLK_VIDEO = clk_sys;

wire [7:0] R,G,B,ay_port_b;
wire hblank, vblank;
wire hsync, vsync;

wire [31:0] joya = status[3] ? joy1 : joy0;
wire [31:0] joyb = status[3] ? joy0 : joy1;


wire svi_audio_in = status[15] ? tape_in : (CAS_status != 0 ? CAS_dout : 1'b0);

cv_console console
(
	.clk_i(clk_sys),
	.clk_en_10m7_i(ce_10m7),
	.clk_en_5m3_i(ce_5m3),
	.reset_n_i(~reset),

   .svi_row_o(svi_row),
   .svi_col_i(svi_col),	
	
	.svi_tap_i(svi_audio_in),//status[15] ? tape_in : (CAS_status != 0 ? CAS_dout : 1'b0)),

   .motor_o(motor),

	.joy0_i(~{joya[4],joya[0],joya[1],joya[2],joya[3]}), //SVI {Fire,Right, Left, Down, Up} // HPS {Fire,Up, Down, Left, Right}
	.joy1_i(~{joyb[4],joyb[0],joyb[1],joyb[2],joyb[3]}),

	.cpu_ram_a_o(cpu_ram_a),
	.cpu_ram_we_n_o(ram_we_n),
	.cpu_ram_ce_n_o(ram_ce_n),
	.cpu_ram_rd_n_o(ram_rd_n),
	.cpu_ram_d_i(ram_di),
	.cpu_ram_d_o(ram_do),

	.ay_port_b(ay_port_b),
	
	.vram_a_o(vram_a),
	.vram_we_o(vram_we),
	.vram_d_o(vram_do),
	.vram_d_i(vram_di),

	.border_i(status[6]),
	.rgb_r_o(R),
	.rgb_g_o(G),
	.rgb_b_o(B),
	.hsync_n_o(hsync),
	.vsync_n_o(vsync),
	.hblank_o(hblank),
	.vblank_o(vblank),

	.audio_o(audio)
);


/////////////////  VIDEO  /////////////////////////

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

wire [2:0] scale = status[9:7];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;

reg hs_o, vs_o;
always @(posedge CLK_VIDEO) begin
	hs_o <= ~hsync;
	if(~hs_o & ~hsync) vs_o <= ~vsync;
end

video_mixer #(.LINE_LENGTH(290), .GAMMA(1)) video_mixer
(
	.*,

	.ce_pix(ce_5m3),

	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),

	.VGA_DE(vga_de),
	.R(R),
	.G(G),
	.B(B),

	// Positive pulses.
	.HSync(hs_o),
	.VSync(vs_o),
	.HBlank(hblank),
	.VBlank(vblank)
);




/////////////////  Tape In   /////////////////////////

wire tape_in;
wire tape_adc, tape_adc_act;

assign tape_in = tape_adc_act & tape_adc;

ltc2308_tape #(.ADC_RATE(120000), .CLK_RATE(42666000)) tape
(
  .clk(clk_sys),
  .ADC_BUS(ADC_BUS),
  .dout(tape_adc),
  .active(tape_adc_act)
);


///////////// OSD CAS load //////////

wire CAS_dout;
wire [2:0] CAS_status;
wire play, rewind;
wire CAS_rd;
wire [25:0] CAS_addr;
wire [7:0] CAS_di;

wire [25:0] CAS_ram_addr;
wire CAS_ram_wren, CAS_ram_cs;
wire ioctl_isCAS = (ioctl_index[5:0] == 6'd2);

assign CAS_ram_cs = 1'b1;
assign CAS_ram_addr = (ioctl_download && ioctl_isCAS) ? ioctl_addr[17:0] : CAS_addr;
assign CAS_ram_wren = ioctl_wr && ioctl_isCAS; 

//17 128
//18 256
spram #(18) CAS_ram
(
	.clock(clk_sys),
	.cs(CAS_ram_cs),
	.address(CAS_ram_addr),	
	.wren(CAS_ram_wren), 
	.data(ioctl_dout),
	.q(CAS_di)
);


assign play = ~motor;
assign rewind = status[13] | (ioctl_download && ioctl_isCAS) | reset; //status[13];

cassette CASReader(

  .clk(ce_21m3), //  42.666/2
  .play(play), 
  .rewind(rewind),

  .sdram_addr(CAS_addr),
  .sdram_data(CAS_di),
  .sdram_rd(CAS_rd),

  .data(CAS_dout),
  .status(CAS_status)

);

endmodule