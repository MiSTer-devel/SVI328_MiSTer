// Simulation top for the SVI-328 core: Svi328.sv minus hps_io / SDRAM /
// video_mixer / overlay, with the same mapper, cassette player and memory map.
//
// Clocking, two builds:
//   make       (FULL=0, obj_dir/)  sim clock = the 10.7 MHz rate (hardware: clk_sys
//              42.954545 MHz with ce_10m7 = /4), ce_10m7 = 1. The cassette player
//              steps on Q edges (hardware: ce_21m48, 21.477 MHz); here 5.369 MHz,
//              so gen/square_gen.v has STP x4. Same bit timing. No turbo. ~4x faster.
//   make full  (FULL=1, obj_full/) sim clock = clk_sys, with Svi328.sv's clock
//              enables, CPU enable generator and tape turbo, and rtl/square_gen.v.
module svi_sim #(
  parameter CAS_AW = 22,         // tape buffer (hardware: SDRAM, 32 MB); 4 MB here
  parameter FULL   = 0           // 1: clk = clk_sys (42.954545 MHz), Svi328.sv's enables and tape turbo
) (
  input               clk,
  input               reset,     // = Svi328.sv reset (RESET | status[0] | ROM download)

  // preload (like ioctl): target 0 = SDRAM (boot ROM at 00000, cart at 10000), 1 = CAS buffer
  input               dl_busy,       // ioctl_download
  input               dl_wr,
  input      [1:0]    dl_target,     // 0 CPU memory, 1 CAS, 2 SV-806 character ROM (boot1.rom), 3 cartridge (ioctl index 1)
  input      [24:0]   dl_addr,
  input      [7:0]    dl_data,
  input      [24:0]   tape_end,
  input               tape_rewind,   // OSD "Tape Rewind" (status[13]) / CAS download

  input               tape_turbo,    // OSD Tape speed = 4x (FULL builds only)
  input      [10:0]   ps2_key,
  input      [31:0]   joy0,          // HPS order {.., fire[4], up[3], down[2], left[1], right[0]}
  input      [31:0]   joy1,
  input               border,
  input               overlay_off,   // OSD Tape overlay = Off
  input               ntsc,          // OSD Video standard = NTSC
  input               model_318,     // OSD Model = SVI-318
  input               mem_std,       // OSD Memory = Standard (no SV-807)
  input               fdc_on,        // OSD SV-801 disk = On
  input               m806_on,       // OSD SV-806 80-column = On
  input       [1:0]   display,       // OSD Display: 0 Auto, 1 80-column, 2 VDP
  // SD (hps_io): VD 0 / 1 = SV-801 drives A: / B:, VD 2 = Tape save
  input      [2:0]    img_mounted,
  input               img_readonly,
  input      [31:0]   img_size,
  output     [31:0]   sd_lba0,
  output     [31:0]   sd_lba1,
  output     [31:0]   sd_lba2,
  output     [2:0]    sd_rd,
  output     [2:0]    sd_wr,
  input      [2:0]    sd_ack,
  input      [8:0]    sd_buff_addr,
  input      [7:0]    sd_buff_dout,
  output     [7:0]    sd_buff_din0,
  output     [7:0]    sd_buff_din1,
  output     [7:0]    sd_buff_din2,
  input               sd_buff_wr,
  output              rec_active,
  output              rec_busy,
  output              rec_full,
  output     [24:0]   rec_length,
  output              mega_on,

  output     [7:0]    R, G, B,
  output              HSync, VSync, HBlank, VBlank,
  output              ce_pix,
  output     [10:0]   audio,

  // debug
  output              motor,
  output              turbo,
  output     [24:0]   cas_addr,
  output              cas_dout,
  output     [2:0]    cas_status,
  output     [15:0]   cpu_a,
  output              cpu_m1_n,
  output              cpu_iorq_n,
  output              cpu_rd_n,
  output              cpu_wr_n,
  output     [7:0]    cpu_din,
  output     [7:0]    cpu_dout,
  output              m806_vram_wr,  // debug: CPU write to SV-806 display RAM
  output     [7:0]    ppi_portc,
  output     [7:0]    psg_port_b
);

  wire motor_n;   // PPI C4: 0 = motor on
  wire [7:0] vR, vG, vB;     // VDP picture before the tape overlay
  wire       vHB, vVB;
  wire       m806_ramdis;
  wire       iorq_n, m1_n;
  wire [7:0] fdc_dout, m806_dout;
  wire       fdc_dout_en, m806_dout_en, m806_wait;
  reg  ce_10m7 = 1'b0, ce_5m37 = 1'b0, cas_q = 1'b0;
  reg  ce_cpu_p = 1'b0, ce_cpu_n = 1'b0;
  wire turbo_active;
  wire [2:0] CAS_status;   // cassette.v state (5 = ENDED)

  generate if (FULL) begin : g_full
    // exactly Svi328.sv: ce_10m7 = /4, ce_5m37 = /8, ce_21m48 = div[0]
    reg [2:0] div = 3'd0;
    always @(posedge clk) begin
      div     <= div + 1'd1;
      ce_10m7 <= !div[1:0];
      ce_5m37  <= !div[2:0];
      cas_q   <= div[0];
    end
    reg turbo_sel = 1'b0, motor_r = 1'b1;
    always @(posedge clk) begin
      motor_r <= motor_n;
      if (motor_r & ~motor_n) turbo_sel <= tape_turbo;
    end
    assign turbo_active = turbo_sel & ~motor_n & (CAS_status != 3'd5);  // not after the tape ends (as Svi328.sv)
    reg [3:0] cpu_div = 4'd0;
    reg       cpu_turbo = 1'b0;
    always @(posedge clk) begin
      ce_cpu_p <= 1'b0;
      ce_cpu_n <= 1'b0;
      if (cpu_div == 0) begin
        ce_cpu_p  <= 1'b1;
        cpu_turbo <= turbo_active;
        cpu_div   <= turbo_active ? 4'd2 : 4'd11;
      end else begin
        cpu_div <= cpu_div - 1'd1;
        if (cpu_div == (cpu_turbo ? 4'd1 : 4'd6)) ce_cpu_n <= 1'b1;
      end
    end
  end else begin : g_fast
    // clk = the 10.7 MHz rate: ce_10m7 = 1, ce_5m37 = /2, Z80 = /3 (cv_clock), cassette Q
    // at clk/2 with square_gen's STP x4 (gen/square_gen.v). No turbo.
    always @(posedge clk) begin
      ce_10m7 <= 1'b1;
      ce_5m37  <= ~ce_5m37;
      cas_q   <= ~cas_q;
    end
    reg [1:0] cnt = 2'd0;
    always @(posedge clk) cnt <= (cnt == 0) ? 2'd2 : cnt - 1'd1;
    always @(*) begin ce_cpu_p = (cnt == 0); ce_cpu_n = (cnt == 2); end
    assign turbo_active = 1'b0;
  end endgenerate

  // FDC timebase: ce_5m37 / 3 (Svi328.sv ce_1m79). SV-806 dots: 12 MHz on
  // average (Svi328.sv ce_12m); the fast build has no 12 MHz, so 10.7 there.
  reg ce_1m79 = 1'b0, ce_12m = 1'b0;
  reg [1:0] d3 = 2'd0;
  always @(posedge clk) begin
    ce_1m79 <= 1'b0;
    if (ce_5m37) begin d3 <= (d3 == 2'd2) ? 2'd0 : d3 + 2'd1; ce_1m79 <= (d3 == 2'd0); end
  end
  generate if (FULL) begin : g_12m
    reg [26:0] acc = 27'd0;
    always @(posedge clk)
      if (acc >= 27'd85909090 - 27'd24000000) begin acc <= acc + 27'd24000000 - 27'd85909090; ce_12m <= 1'b1; end
      else begin acc <= acc + 27'd24000000; ce_12m <= 1'b0; end
  end else begin : g_12m_fast
    always @(posedge clk) ce_12m <= 1'b1;
  end endgenerate
  // Display (Svi328.sv show80): Auto follows the screen the software writes to
  // (rtl/sv806/sv806_auto.sv; 0.2 s hold at either sim clock rate)
  wire auto80;
  sv806_auto #(.HOLD(FULL ? 23 : 21)) sv806_auto (.clk(clk), .reset(reset), .enable(m806_on),
    .m806_wr(m806_ramdis & ~ram_we_n),
    .vdp_wr(~iorq_n & m1_n & ~ram_we_n & ram_a16[7:6] == 2'b10 & ram_a16[4:2] == 3'b000),
    .show80(auto80));
  wire on80 = m806_on & ((display == 2'd1) | ((display == 2'd0) & auto80));
  assign ce_pix = on80 ? ce_12m : ce_5m37;

  // Keyboard ------------------------------------------------------------------
  wire [3:0] svi_row;
  wire [7:0] svi_col, svi_col_kbd;
  svi_keyboard kbd (.clk(clk), .reset(reset), .keys(ps2_key), .svi_row(svi_row), .svi_col(svi_col_kbd));
  // SVI-318: no keypad, rows 9-10 read FF (as Svi328.sv)
  assign svi_col = (model_318 && (svi_row == 4'd9 || svi_row == 4'd10)) ? 8'hFF : svi_col_kbd;

  // CPU memory: Svi328.sv's 256 KB block RAM {bank, A15:0}, registered read ---
  reg  [7:0] sdram [0:262143] /*verilator public*/;
  wire [15:0] ram_a16;
  wire        ram_we_n, ram_rd_n, ram_ce_n;
  wire [7:0]  ram_do;
  wire [17:0] ram_a;
  wire        is_ram;
  wire [7:0]  ay_port_b;

  wire        open_bus;
  reg         cart_loaded = 1'b0;
  reg  [15:0] cart_last = 16'd0;
  wire dl_cart = dl_target == 2'd3;
  always @(posedge clk)
    if (dl_wr && ((dl_target == 2'd0 && dl_addr[16]) || dl_cart)) begin
      cart_loaded <= 1'b1;
      cart_last   <= (dl_cart && |dl_addr[24:16]) ? 16'hFFFF : dl_addr[15:0];   // Svi328.sv
    end
  svi_mapper mapper (.addr_i(ram_a16), .RegMap_i(ay_port_b), .cart_loaded(cart_loaded),
                     .cart_last(cart_last),
                     .model_318(model_318), .expanded(~mem_std), .addr_o(ram_a), .ram(is_ram), .open_bus(open_bus));

  reg  [7:0] ram_di;
  always @(posedge clk) begin
    if (dl_wr && dl_target == 2'd0) sdram[dl_addr[17:0]] <= dl_data;
    else if (dl_wr && dl_cart && ~|dl_addr[24:16]) sdram[{2'b01, dl_addr[15:0]}] <= dl_data;
    else if (is_ram && !m806_ramdis && !(ram_we_n | ram_ce_n)) sdram[ram_a] <= ram_do;
    ram_di <= sdram[ram_a];
  end

  // VRAM ----------------------------------------------------------------------
  reg  [7:0] vram [0:16383] /*verilator public*/;
  wire [13:0] vram_a;
  wire        vram_we;
  wire [7:0]  vram_do;
  reg  [7:0]  vram_di;
  always @(posedge clk) begin
    vram_di <= vram[vram_a];
    if (vram_we) begin vram[vram_a] <= vram_do; vram_di <= vram_do; end
  end

  // SDRAM (Svi328.sv): the tape image, and the cartridge at 1000000h for the
  // megaROM pages, read through svi_sdram_arb. Modelled as sdram.sv's
  // handshake: a rising edge of rd drops ready; ready rises again one clock
  // before the data, 8 clocks later, or 16 every fourth read (a refresh).
  reg  [7:0] cas_ram [0:(1<<CAS_AW)-1];
  reg  [7:0] mega_ram [0:1048575];
  wire [24:0] CAS_addr, CAS_rd_addr;
  wire        CAS_rd;
  wire [7:0]  CAS_di;
  wire        cas_ready;
  wire        sdr_rd;
  wire [24:0] sdr_addr;
  reg  [7:0]  sdr_dout;
  reg         sdr_ready = 1'b1, sdr_rd_r = 1'b0;
  reg  [4:0]  sdr_cnt = 5'd0;
  reg  [1:0]  sdr_nth = 2'd0;
  wire        sdram_dl = dl_busy && (dl_target == 2'd1 || dl_cart);
  always @(posedge clk) begin
    if (dl_wr && dl_target == 2'd1) cas_ram[dl_addr[CAS_AW-1:0]] <= dl_data;
    if (dl_wr && dl_cart && ~|dl_addr[24:20]) mega_ram[dl_addr[19:0]] <= dl_data;
    sdr_rd_r <= sdr_rd;
    if (sdr_rd && !sdr_rd_r) begin
      sdr_ready <= 1'b0;
      sdr_cnt   <= (sdr_nth == 0) ? 5'd16 : 5'd8;
      sdr_nth   <= sdr_nth + 1'd1;
    end else if (sdr_cnt != 0) begin
      sdr_cnt <= sdr_cnt - 1'd1;
      if (sdr_cnt == 2) sdr_ready <= 1'b1;
      if (sdr_cnt == 1) sdr_dout <= sdr_addr[24] ? mega_ram[sdr_addr[19:0]] : cas_ram[sdr_addr[CAS_AW-1:0]];
    end
  end

  wire        mega_req, mega_ack;
  wire [24:0] mega_addr;
  wire  [7:0] mega_data, mega_q;
  svi_sdram_arb sdram_arb (
    .clk(clk), .hold(sdram_dl),
    .cas_rd(CAS_rd), .cas_addr(CAS_rd_addr), .cas_data(CAS_di), .cas_ready(cas_ready),
    .mr_req(mega_req), .mr_addr(mega_addr), .mr_ack(mega_ack), .mr_data(mega_data),
    .rd(sdr_rd), .addr(sdr_addr), .dout(sdr_dout), .ready(sdr_ready));

  // megaROM (ce_5m37 is the 5.37 MHz rate in both builds: 8 Hz pages)
  svi_megarom megarom (
    .clk(clk), .ce_5m37(ce_5m37),
    .dl(dl_busy && dl_cart), .dl_wr(dl_wr && dl_cart), .dl_addr(dl_addr), .dl_data(dl_data),
    .eject(1'b0), .active(mega_on),
    .rd_req(mega_req), .rd_addr(mega_addr), .rd_ack(mega_ack), .rd_data(mega_data),
    .cpu_a(ram_a[13:0]), .cpu_q(mega_q));

  wire CAS_dout, CAS_tick;
  cassette CASReader (
    .clk(clk), .Q(cas_q),
    .play(~motor_n), .rewind(tape_rewind | reset), .tape_end(tape_end), .turbo(turbo_active),
    .sdram_addr(CAS_rd_addr), .pos(CAS_addr), .sdram_data(CAS_di), .sdram_rd(CAS_rd),
    .sdram_ready(cas_ready),
    .data(CAS_dout), .tick(CAS_tick), .status(CAS_status));
  // square_gen's STP is 4 x 24'hEF3 here: the Makefile builds gen/square_gen.v from rtl/

  wire svi_audio_in = (CAS_status != 0) ? CAS_dout : 1'b0;

  // Machine -------------------------------------------------------------------
  wire hsync_n, vsync_n;
  svi_console #(.is_pal_g(1)) console (
    .clk_i(clk), .pal_i(~ntsc), .clk_en_10m7_i(ce_10m7), .clk_en_5m37_i(ce_5m37),
    .clk_en_cpu_p_i(ce_cpu_p), .clk_en_cpu_n_i(ce_cpu_n), .reset_n_i(~reset),
    .svi_row_o(svi_row), .svi_col_i(svi_col),
    .svi_tap_i(svi_audio_in), .tape_ready_n_i(~(tape_loaded | rec_active)), .motor_o(motor_n),
    .joy0_i(~{joy0[4], joy0[0], joy0[1], joy0[2], joy0[3]}),
    .joy1_i(~{joy1[4], joy1[0], joy1[1], joy1[2], joy1[3]}),
    .cpu_ram_a_o(ram_a16), .cpu_ram_ce_n_o(ram_ce_n), .cpu_ram_rd_n_o(ram_rd_n),
    .cpu_ram_we_n_o(ram_we_n), .cpu_ram_d_i(open_bus ? 8'hFF : (mega_on && ram_a[17:16] == 2'b01) ? mega_q : ram_di), .cpu_ram_d_o(ram_do),
    .ay_port_b(ay_port_b),
    .cpu_iorq_n_o(iorq_n), .cpu_m1_n_o(m1_n),
    .ext_d_en_i(fdc_dout_en | m806_dout_en), .ext_d_i(fdc_dout_en ? fdc_dout : m806_dout),
    .ext_wait_n_i(~m806_wait),
    .turbo_i(turbo_active),
    .vram_a_o(vram_a), .vram_we_o(vram_we), .vram_d_o(vram_do), .vram_d_i(vram_di),
    .border_i(border),
    .rgb_r_o(vR), .rgb_g_o(vG), .rgb_b_o(vB),
    .hsync_n_o(hsync_n), .vsync_n_o(vsync_n), .hblank_o(vHB), .vblank_o(vVB),
    .audio_o(audio),
    .dbg_portc(ppi_portc), .dbg_m1_n(cpu_m1_n), .dbg_iorq_n(cpu_iorq_n),
    .dbg_rd_n(cpu_rd_n), .dbg_wr_n(cpu_wr_n),
    .dbg_d_to_cpu(cpu_din), .dbg_d_from_cpu(cpu_dout));

  // Tape status bar and hint (Svi328.sv, rtl/tape_overlay.sv) ----------------
  reg  cas_dl_r = 1'b0, tape_loaded = 1'b0;
  wire cas_dl = dl_busy && dl_target == 2'd1;
  always @(posedge clk) begin
    cas_dl_r <= cas_dl;
    if (cas_dl) tape_loaded <= 1'b1;
  end
  wire         hint_show;
  wire   [4:0] hint_len;
  wire [175:0] hint_text;
  wire [223:0] ts_word;
  wire         ts_req, ts_ack;
  svi_tape_hint tape_hint (
    .clk(clk), .dl_start(cas_dl & ~cas_dl_r), .dl_wr(cas_dl & dl_wr), .dl_addr(dl_addr),
    .dl_data(dl_data), .position(CAS_addr), .playing(~motor_n), .ps2_key(ps2_key),
    .show(hint_show), .len(hint_len), .text(hint_text));
  svi_tape_status tape_status (
    .clk(clk), .dl_start(cas_dl & ~cas_dl_r), .dl_wr(cas_dl & dl_wr), .dl_data(dl_data),
    .dl_busy(cas_dl), .loaded(tape_loaded), .playing(~motor_n & (CAS_status != 3'd5) & tape_loaded & ~cas_dl),
    .fast(turbo_active), .tick(CAS_tick), .position(CAS_addr), .length(tape_end + 25'd1),
    .hint_show(hint_show & tape_loaded & ~cas_dl), .hint_len(hint_len), .hint_text(hint_text),
    .status(ts_word), .req(ts_req), .ack(ts_ack));
  svi_tape_overlay #(.FACTOR(4'd4)) tape_overlay (
    .clk(clk), .ce_pix(ce_5m37), .hblank(vHB), .vblank(vVB), .enable(~overlay_off),
    .status(ts_word), .req(ts_req), .ack(ts_ack),
    .rgb_in({vR, vG, vB}), .rgb_out({oR, oG, oB}));

  // Expansion cards (Svi328.sv) ------------------------------------------------
  sv801 sv801 (
    .clk(clk), .ce(ce_1m79), .reset(reset), .enable(fdc_on),
    .iorq(~iorq_n & m1_n), .rd(~ram_rd_n), .wr(~ram_we_n), .addr(ram_a16[7:0]),
    .din(ram_do), .dout(fdc_dout), .dout_en(fdc_dout_en),
    .img_mounted(img_mounted[1:0]), .img_readonly(img_readonly), .img_size({32'd0, img_size}),
    .sd_lba0(sd_lba0), .sd_lba1(sd_lba1), .sd_rd(sd_rd[1:0]), .sd_wr(sd_wr[1:0]), .sd_ack(sd_ack[1:0]),
    .sd_buff_addr(sd_buff_addr), .sd_buff_dout(sd_buff_dout),
    .sd_buff_din0(sd_buff_din0), .sd_buff_din1(sd_buff_din1),
    .sd_buff_wr(sd_buff_wr), .led());
  // Tape save (Svi328.sv tape_rec): PPI C5 timed in Z80 clocks
  tape_rec tape_rec (
    .clk(clk), .ce_cpu(ce_cpu_p), .cas_out(ppi_portc[5]), .motor_on(~motor_n),
    .img_mounted(img_mounted[2]), .img_readonly(img_readonly), .img_size({32'd0, img_size}),
    .sd_lba(sd_lba2), .sd_rd(sd_rd[2]), .sd_wr(sd_wr[2]), .sd_ack(sd_ack[2]),
    .sd_buff_addr(sd_buff_addr), .sd_buff_din(sd_buff_din2),
    .active(rec_active), .recording(rec_busy), .full(rec_full), .length(rec_length));
  wire m806_video, m806_hs, m806_vs, m806_de;
  sv806 sv806 (
    .clk(clk), .cpu_ce(ce_cpu_p), .pix_ce(ce_12m), .reset(reset), .enable(m806_on),
    .cpu_addr(ram_a16), .cpu_din(ram_do), .cpu_mreq_n(ram_ce_n), .cpu_iorq_n(iorq_n | ~m1_n),
    .cpu_rd_n(ram_rd_n), .cpu_wr_n(ram_we_n),
    .cpu_dout(m806_dout), .dout_en(m806_dout_en), .cpu_wait(m806_wait), .ramdis(m806_ramdis),
    .rom_wr(dl_wr && dl_target == 2'd2), .rom_addr_w(dl_addr[11:0]), .rom_din(dl_data),
    .video(m806_video), .hsync(m806_hs), .vsync(m806_vs), .de(m806_de));

  // Display: VDP or the SV-806 output (Svi328.sv show80)
  wire [7:0] oR, oG, oB;
  reg m806_vb = 1'b1, m806_line_de = 1'b0, m806_hs_r = 1'b0;
  always @(posedge clk) if (ce_12m) begin
    m806_hs_r <= m806_hs;
    if (m806_de) begin m806_line_de <= 1'b1; m806_vb <= 1'b0; end
    if (m806_hs & ~m806_hs_r) begin if (~m806_line_de) m806_vb <= 1'b1; m806_line_de <= 1'b0; end
  end
  wire px80 = m806_de & m806_video;
  assign R = on80 ? (px80 ? 8'h33 : 8'h00) : oR;
  assign G = on80 ? (px80 ? 8'hFF : 8'h00) : oG;
  assign B = on80 ? (px80 ? 8'h33 : 8'h00) : oB;
  assign HBlank = on80 ? ~m806_de : vHB;
  assign VBlank = on80 ? (m806_vb & ~m806_de) : vVB;

  assign HSync      = on80 ? m806_hs : ~hsync_n;
  assign VSync      = on80 ? m806_vs : ~vsync_n;
  assign motor      = ~motor_n;   // 1 = motor on
  assign turbo      = turbo_active;
  assign cas_addr   = CAS_addr;
  assign cas_dout   = CAS_dout;
  assign cas_status = CAS_status;
  assign m806_vram_wr = m806_ramdis & ~ram_we_n;
  assign cpu_a      = ram_a16;
  assign psg_port_b = ay_port_b;

endmodule
