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

// Done
//  - Rewind on CAS load or Reset
//  - LED_Disk on Tape Load
//  - Tape Load Graphical wave (file only)
//  - Tape Counter (progress bar)

//Core : 
//Z80 - 3,5555Mhz
//AY - z80/2 = 1,777 Mhz
//Mess :
//Z80 - 3,579545
//AY - 1,789772



module emu
(
	`include "sys/emu_ports.vh"
);


//assign ADC_BUS = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
 
assign LED_USER   = ioctl_download;
assign LED_DISK  = {1'b0, svi_audio_in | (cfg[23] & fdc_led)};
assign LED_POWER  = 0;
assign BUTTONS    = 0;
assign VGA_SCALER = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;


wire [127:0] status;
reg  [127:0] cfg = 0;    // settings latched at reset (below)

wire [1:0] ar = cfg[2:1];
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
	.SCALE(cfg[11:10])
);

`include "build_id.v" 
// OSD after ~/dev2/osd-standard.md and tape-standard.md. Status bits keep
// their old positions, so saved settings stay valid.
//   live:  1 Tape input (media), 3 Joysticks swap (input), 16 Tape speed
//          (taken when the deck starts), 17 Tape overlay, 19 Tape audio,
//          buttons 13 Rewind tape, 18 Eject cartridge
//   reset: everything else, latched into cfg (Apply and reset)
parameter CONF_STR = {
	"SVI328;;",
	"-;",
	"F1,BINROM,Cartridge;",
	"H1F2,CAS,Tape;",
	"h1-;",
	"H2S0,DSK,Disk;",
	"h2-;",
	"F0,ROM,Load ROM;",
	"-;",
	"O[22],Memory,SV-807 (160K),Standard;",
	"-;",
	"P1,Machine;",
	"P2,Video;",
	"P3,Input;",
	"P4,Audio;",
	"-;",
	"h0-,Changes pending;",
	"R[0],Apply and reset;",

	"P1O[21],Model,SVI-328,SVI-318;",
	"P1O[23],SV-801 disk,Off,On;",
	"P1O[24],SV-806 80-column,Off,On;",
	"P1-;",
	"P1O[15],Tape input,File,ADC;",
	"H1P1O[16],Tape speed,4x,Normal;",
	"h1P1-;",
	"P1-;",
	"H1P1T[13],Rewind tape;",
	"h1P1-;",
	"P1T[18],Eject cartridge;",

	"P2O[2:1],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P2O[11:10],Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P2O[8:7],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"H3P2O[25],Display,VDP,80-column;",
	"h3P2-;",
	"P2O[20],Video standard,PAL,NTSC;",
	"P2O[6],Border,No,Yes;",
	"H1P2O[17],Tape overlay,On,Off;",
	"h1P2-;",

	"P3O[3],Joysticks swap,No,Yes;",

	"H1P4O[19],Tape audio,Off,On;",
	"h1P4-;",

	"I,Tape ready (rewound);",
	"J,Fire;",
	"jn,A;",
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

// 1.79 MHz for the FDC (ce_5m3 / 3): the disk's timebase, not sped up by turbo.
reg ce_1m79 = 0;
always @(posedge clk_sys) begin
	reg [1:0] d3;
	ce_1m79 <= 0;
	if (ce_5m3) begin
		d3 <= (d3 == 2'd2) ? 2'd0 : d3 + 2'd1;
		ce_1m79 <= (d3 == 2'd0);
	end
end

// 12 MHz on average for the SV-806 dot clock (its own crystal on the card):
// every 3 or 4 clk_sys, 12 / 42.954545 exactly over time.
reg ce_12m = 0;
always @(posedge clk_sys) begin
	reg [26:0] acc;
	if (acc >= 27'd85909090 - 27'd24000000) begin
		acc <= acc + 27'd24000000 - 27'd85909090;
		ce_12m <= 1;
	end else begin
		acc <= acc + 27'd24000000;
		ce_12m <= 0;
	end
end


/////////////////  HPS  ///////////////////////////

wire  [1:0] buttons;

wire [31:0] joy0, joy1;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire        sdram_rdy;
wire        ioctl_wait = ~sdram_rdy;
// ioctl index: [5:0] the OSD row, [7:6] which extension / bootN.rom.
wire ioctl_isBASIC = ioctl_index == 8'h00;          // boot.rom, boot0.rom, Load ROM
wire ioctl_isCART  = ioctl_index[5:0] == 6'd1;      // Cartridge (.bin 01h, .rom 41h)
wire ioctl_isROM   = ioctl_isBASIC | ioctl_isCART;  // CPU memory {index[0], A15:0}
wire ioctl_isCAS   = ioctl_index[5:0] == 6'd2;
wire ioctl_is806   = ioctl_index == 8'h40;          // boot1.rom: SV-806 character ROM
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire [10:0] PS2Keys;
 
wire        img_mounted, img_readonly;
wire [63:0] img_size;
wire [31:0] sd_lba;
wire        sd_rd, sd_wr, sd_ack, sd_buff_wr;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout, sd_buff_din;

hps_io #(.CONF_STR(CONF_STR), .VDNUM(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

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

	.status_menumask({12'd0, ~status[24], ~status[23], status[15], pending}),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	.sd_lba('{sd_lba}),
	.sd_blk_cnt('{6'd0}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.info_req(info_req),
	.info(8'd1),
	
	.ps2_key(PS2Keys),
	
	.joystick_0(joy0), // HPS joy [4:0] {Fire, Up, Down, Left, Right}
	.joystick_1(joy1)

);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1] | (ioctl_download && ioctl_isROM) | status[18];

// Settings the machine runs with, taken from the OSD at every reset (osd-standard
// rule 1). "Changes pending" while one of them differs from the OSD.
always @(posedge clk_sys) if (reset) cfg <= status;
wire pending = {status[24:20], status[2:1], status[11:6]} != {cfg[24:20], cfg[2:1], cfg[11:6]};

// Eject cartridge (status[18]): the cartridge leaves the machine at once,
// and the machine resets as when a cartridge is pulled out with the power on.
reg  eject_r = 0;
always @(posedge clk_sys) eject_r <= status[18];
wire cart_eject = status[18] & ~eject_r;

// Tape mount: "Tape ready (rewound)" (tape-standard rule 5).
reg  info_req = 0;
reg  cas_dl_end_r = 0;
always @(posedge clk_sys) begin
	cas_dl_end_r <= ioctl_download && ioctl_isCAS;
	info_req <= cas_dl_end_r & ~(ioctl_download && ioctl_isCAS);
end

// Tape speed (status[16]: 0 = 4x, 1 = Normal) is taken when the deck starts,
// so changing it mid-load does nothing until the next motor start.
wire motor;          // from cv_console: PPI C4, 0 = tape motor on
reg turbo_sel = 0;
reg motor_r = 1;
always @(posedge clk_sys) begin
	motor_r <= motor;
	if (motor_r & ~motor) turbo_sel <= ~status[16];   // motor: 0 = on
end
// The deck plays while the motor is on and the tape has not run out. A game that
// leaves the motor bit on after loading (Mr. Do!, Kung Fu Master) then runs at
// normal speed and without the status bar (tape-standard rules 6 and 20; the X1
// reference plays only while mounted and not ended).
wire tape_ended;
wire deck_plays   = ~motor & ~tape_ended;
wire turbo_active = turbo_sel & deck_plays & ~status[15];

// Z80 clock enables. Normal: 42.954545/12 = 3.579545 MHz (the same rate cv_clock
// derives from ce_10m7). Turbo: 42.954545/3 = 14.32 MHz, 4x, only while the tape
// motor runs (tape-standard rules 6-9); the tape plays 4x faster with it
// (cassette.turbo), so the BIOS's pulse-counting loops at 2164h see the same
// counts. The spacing changes only at a CPU clock boundary, so CEN_p and CEN_n
// always alternate.
reg       ce_cpu_p = 0, ce_cpu_n = 0;
reg [3:0] cpu_div = 0;
reg       cpu_turbo = 0;     // spacing in use for the current CPU clock
always @(posedge clk_sys) begin
	ce_cpu_p <= 0;
	ce_cpu_n <= 0;
	if (cpu_div == 0) begin
		ce_cpu_p  <= 1;
		cpu_turbo <= turbo_active;
		cpu_div   <= turbo_active ? 4'd2 : 4'd11;
	end else begin
		cpu_div <= cpu_div - 1'd1;
		if (cpu_div == (cpu_turbo ? 4'd1 : 4'd6)) ce_cpu_n <= 1;
	end
end


////////////////  KeyBoard  ///////////////////////


wire [3:0] svi_row;
wire [7:0] svi_col, svi_col_kbd;
// The SVI-318 has no numeric keypad: rows 9 and 10 read FF (MAME svi318 KEY.9/10
// unused; the keypad is added by the svi328 input ports).
assign svi_col = (cfg[21] && (svi_row == 4'd9 || svi_row == 4'd10)) ? 8'hFF : svi_col_kbd;
sviKeyboard KeyboardSVI
(
	.clk		(clk_sys),
	.reset	(reset),
	
	.keys		(PS2Keys),
	.svi_row (svi_row),
	.svi_col (svi_col_kbd)
	
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



// CPU memory: the whole 256 KB mapper space {bank[1:0], A15:0} in block RAM
// (BASIC ROM at 00000, cartridge at 10000, RAM banks), so every CPU access
// answers in one clock at any CPU speed (tape turbo runs the Z80 at 14 MHz,
// where an SDRAM read with a refresh in the way is too slow and the core has
// no wait for it). The tape image lives in SDRAM instead (below).
spram #(18) ram
(
	.clock(clk_sys),
	.address((ioctl_download && ioctl_isROM) ? {ioctl_index[0],ioctl_addr[15:0]} : ram_a),
	.wren((ioctl_wr && ioctl_isROM) | (isRam & ~m806_ramdis & ~(ram_we_n | ram_ce_n))),
	.data((ioctl_wr && ioctl_isROM) ? ioctl_dout : ram_do),
	.q(ram_di)
);


wire [17:0] ram_a;
wire isRam, open_bus;

// Cartridge: loaded through index 1 at 10000-1FFFF; cart_last is the offset of
// its last byte, so the rest of the 64 KB cartridge space reads FF.
reg        cart_loaded = 1'b0;
reg [15:0] cart_last;
always @(posedge clk_sys) begin
	if (ioctl_wr && ioctl_download && ioctl_index[5:0] == 6'd1) begin
		cart_loaded <= 1'b1;
		cart_last   <= ioctl_addr[15:0];
	end
	if (cart_eject) cart_loaded <= 1'b0;
end

svi_mapper RamMapper
(
	.addr_i     (cpu_ram_a),
	.RegMap_i   (ay_port_b),
	.cart_loaded(cart_loaded),
	.cart_last  (cart_last),
	.model_318  (cfg[21]),
	.expanded   (~cfg[22]),
	.addr_o     (ram_a),
	.ram        (isRam),
	.open_bus   (open_bus)
);


////////////////  Console  ////////////////////////

wire [10:0] audio;
// Tape audio (status[19], acts at once): the tape signal on the tape bit of
// the mix, as the machine's own SOUND ON (PPI C6) puts it there.
wire        tape_mon = status[19] & ~status[15] & play & (CAS_status != 0) & CAS_dout;
wire [10:0] audio_mix = audio | {1'b0, tape_mon, 9'd0};
assign AUDIO_L = {audio_mix,5'd0};
assign AUDIO_R = {audio_mix,5'd0};
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
	.pal_i(~cfg[20]),
	.clk_en_10m7_i(ce_10m7),
	.clk_en_5m3_i(ce_5m3),
	.clk_en_cpu_p_i(ce_cpu_p),
	.clk_en_cpu_n_i(ce_cpu_n),
	.reset_n_i(~reset),

	.svi_row_o(svi_row),
	.svi_col_i(svi_col),	
	
	.svi_tap_i(svi_audio_in),
	.tape_ready_n_i(~(tape_loaded | status[15])),//status[15] ? tape_in : (CAS_status != 0 ? CAS_dout : 1'b0)),

	.motor_o(motor),

	.joy0_i(~{joya[4],joya[0],joya[1],joya[2],joya[3]}), //SVI {Fire,Right, Left, Down, Up} // HPS {Fire,Up, Down, Left, Right}
	.joy1_i(~{joyb[4],joyb[0],joyb[1],joyb[2],joyb[3]}),

	.cpu_ram_a_o(cpu_ram_a),
	.cpu_ram_we_n_o(ram_we_n),
	.cpu_ram_ce_n_o(ram_ce_n),
	.cpu_ram_rd_n_o(ram_rd_n),
	.cpu_ram_d_i(open_bus ? 8'hFF : ram_di),
	.cpu_ram_d_o(ram_do),

	.ay_port_b(ay_port_b),

	.cpu_iorq_n_o(cpu_iorq_n),
	.cpu_m1_n_o(cpu_m1_n),
	.ext_d_en_i(fdc_dout_en | m806_dout_en),
	.ext_d_i(fdc_dout_en ? fdc_dout : m806_dout),
	.ext_wait_n_i(~m806_wait),
	.turbo_i(turbo_active),
	
	.vram_a_o(vram_a),
	.vram_we_o(vram_we),
	.vram_d_o(vram_do),
	.vram_d_i(vram_di),

	.border_i(cfg[6]),
	.rgb_r_o(R),
	.rgb_g_o(G),
	.rgb_b_o(B),
	.hsync_n_o(hsync),
	.vsync_n_o(vsync),
	.hblank_o(hblank),
	.vblank_o(vblank),
	.hcount_o(),
	.vcount_o(),

	.audio_o(audio)
);


/////////////////  VIDEO  /////////////////////////

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

// 4 choices in 2 bits (bit 9 was always 0, so saved .CFG files keep their value)
wire [1:0] scale = cfg[8:7];
wire [1:0] sl = scale ? scale - 1'd1 : 2'd0;

// Display (status[25], acts at once): the VDP, or the SV-806's own monochrome
// output (a second monitor on the real machine). Only with the card present.
wire show80 = cfg[24] & status[25];

// SV-806 blanking from the CRTC's display enable: vertical blanking starts at
// the first line without DE and ends with the first DE.
reg m806_vb = 1, m806_line_de = 0, m806_hs_r = 0;
always @(posedge CLK_VIDEO) if (ce_12m) begin
	m806_hs_r <= m806_hs;
	if (m806_de) begin
		m806_line_de <= 1;
		m806_vb <= 0;
	end
	if (m806_hs & ~m806_hs_r) begin
		if (~m806_line_de) m806_vb <= 1;
		m806_line_de <= 0;
	end
end

reg hs_o, vs_o;
always @(posedge CLK_VIDEO) begin
	if (show80) begin
		hs_o <= m806_hs;
		vs_o <= m806_vs;
	end else begin
		hs_o <= ~hsync;
		if(~hs_o & ~hsync) vs_o <= ~vsync;
	end
end
wire freeze_sync;

wire [23:0] rgb80 = (m806_de & m806_video) ? 24'h33FF33 : 24'h000000;   // green phosphor (MAME)
wire [23:0] rgb_o = show80 ? rgb80 : ov_rgb;

video_mixer #(.LINE_LENGTH(640), .GAMMA(1)) video_mixer
(
	.*,

	.ce_pix(show80 ? ce_12m : ce_5m3),

	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),

	.VGA_DE(vga_de),
	.R(rgb_o[23:16]),
	.G(rgb_o[15:8]),
	.B(rgb_o[7:0]),

	// Positive pulses.
	.HSync(hs_o),
	.VSync(vs_o),
	.HBlank(show80 ? ~m806_de : hblank),
	.VBlank(show80 ? (m806_vb & ~m806_de) : vblank)
);




/////////////////  Expansion cards  /////////////////////////

wire        cpu_iorq_n, cpu_m1_n;
wire  [7:0] fdc_dout, m806_dout;
wire        fdc_dout_en, m806_dout_en, m806_wait, m806_ramdis;

// SV-801 disk controller (OSD Machine > SV-801 disk, taken at reset).
sv801 sv801
(
	.clk(clk_sys),
	.ce(ce_1m79),
	.reset(reset),
	.enable(cfg[23]),

	.iorq(~cpu_iorq_n & cpu_m1_n),
	.rd(~ram_rd_n),
	.wr(~ram_we_n),
	.addr(cpu_ram_a[7:0]),
	.din(ram_do),
	.dout(fdc_dout),
	.dout_en(fdc_dout_en),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.led(fdc_led)
);
wire fdc_led;

// SV-806 80-column card (OSD Machine > SV-806 80-column, taken at reset).
wire m806_video, m806_hs, m806_vs, m806_de;
sv806 sv806
(
	.clk(clk_sys),
	.cpu_ce(ce_cpu_p),
	.pix_ce(ce_12m),
	.reset(reset),
	.enable(cfg[24]),

	.cpu_addr(cpu_ram_a),
	.cpu_din(ram_do),
	.cpu_mreq_n(ram_ce_n),
	.cpu_iorq_n(cpu_iorq_n | ~cpu_m1_n),
	.cpu_rd_n(ram_rd_n),
	.cpu_wr_n(ram_we_n),

	.cpu_dout(m806_dout),
	.dout_en(m806_dout_en),
	.cpu_wait(m806_wait),
	.ramdis(m806_ramdis),

	.rom_wr(ioctl_wr && ioctl_download && ioctl_is806),
	.rom_addr_w(ioctl_addr[11:0]),
	.rom_din(ioctl_dout),

	.video(m806_video),
	.hsync(m806_hs),
	.vsync(m806_vs),
	.de(m806_de)
);


/////////////////  Tape In   /////////////////////////

wire tape_in;
wire tape_adc, tape_adc_act;

assign tape_in = tape_adc_act & tape_adc;

ltc2308_tape #(.ADC_RATE(120000), .CLK_RATE(42954545)) tape
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
wire [24:0] CAS_addr;
wire [7:0] CAS_di;

reg [24:0] tape_end;
always @(posedge clk_sys) begin
 if (ioctl_download && ioctl_isCAS) tape_end <= ioctl_addr;
end

// Tape image in SDRAM (32 MB: no size limit in practice; the old 256 KB
// block RAM buffer wrapped bigger tapes). Written by the CAS download
// (ioctl_wait holds Main while the SDRAM is busy), read by the player.
assign SDRAM_CLK = ~clk_sys;
sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

	.wtbt(0),
	.addr((ioctl_download && ioctl_isCAS) ? ioctl_addr : CAS_addr),
	.rd(CAS_rd),
	.dout(CAS_di),
	.din(ioctl_dout),
	.we(ioctl_wr && ioctl_isCAS),
	.ready(sdram_rdy)
);


assign play = ~motor;
assign rewind = status[13] | (ioctl_download && ioctl_isCAS) | reset; //status[13];

wire [24:0] CAS_pos;
wire        CAS_tick;
assign tape_ended = (CAS_status == 3'd5);   // cassette.v ENDED

cassette CASReader(

  .clk(clk_sys), 
  .Q(ce_21m3), //  42.954545/2
  .play(play), 
  .rewind(rewind),
  .tape_end(tape_end),
  .turbo(turbo_active),

  .sdram_addr(CAS_addr),
  .sdram_data(CAS_di),
  .sdram_rd(CAS_rd),
  .sdram_ready(sdram_rdy),
  .pos(CAS_pos),

  .data(CAS_dout),
  .tick(CAS_tick),
  .status(CAS_status)

);

/////////////////  Tape status bar and next-step hint  /////////////////

reg  cas_dl_r = 0, tape_loaded = 0;
wire cas_dl = ioctl_download && ioctl_isCAS;
always @(posedge clk_sys) begin
	cas_dl_r <= cas_dl;
	if (cas_dl) tape_loaded <= 1'b1;
end

wire         tape_hint_show;
wire   [4:0] tape_hint_len;
wire [175:0] tape_hint_text;
wire [223:0] tape_status_word;
wire         tape_status_req, tape_status_ack;
wire  [23:0] ov_rgb;

svi_tape_hint tape_hint
(
	.clk(clk_sys),
	.dl_start(cas_dl & ~cas_dl_r),
	.dl_wr(cas_dl & ioctl_wr),
	.dl_addr(ioctl_addr[24:0]),
	.dl_data(ioctl_dout),
	.position(CAS_pos),
	.playing(play),
	.ps2_key(PS2Keys),
	.show(tape_hint_show),
	.len(tape_hint_len),
	.text(tape_hint_text)
);

svi_tape_status tape_status
(
	.clk(clk_sys),
	.dl_start(cas_dl & ~cas_dl_r),
	.dl_wr(cas_dl & ioctl_wr),
	.dl_data(ioctl_dout),
	.dl_busy(cas_dl),
	.loaded(tape_loaded),
	.playing(deck_plays & tape_loaded & ~cas_dl),
	.fast(turbo_active),
	.tick(CAS_tick),
	.position(CAS_pos),
	.length(tape_end + 25'd1),
	.hint_show(tape_hint_show & tape_loaded & ~cas_dl),
	.hint_len(tape_hint_len),
	.hint_text(tape_hint_text),
	.status(tape_status_word),
	.req(tape_status_req),
	.ack(tape_status_ack)
);

svi_tape_overlay #(.FACTOR(4'd4)) tape_overlay
(
	.clk(CLK_VIDEO),
	.ce_pix(ce_5m3),
	.hblank(hblank),
	.vblank(vblank),
	.enable(~status[17] & ~status[15]),
	.status(tape_status_word),
	.req(tape_status_req),
	.ack(tape_status_ack),
	.rgb_in({R, G, B}),
	.rgb_out(ov_rgb)
);

endmodule
