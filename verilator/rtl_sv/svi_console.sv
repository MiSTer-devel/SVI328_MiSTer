//-----------------------------------------------------------------------------
// SVI-318/328 machine: SystemVerilog port of rtl/cv_console.vhd (+ cv_addr_dec,
// cv_bus_mux, 74ls74 M1 wait) for Verilator.
//
// Same structure and signal meaning as the VHDL the hardware build uses. The
// differences are the CPU (tv80e instead of T80pa, as in ColecoAdam_MiSTer) and
// the VDP (vdp18v, ColecoAdam's SystemVerilog TMS9918A with its accuracy fixes
// and SVI's vsync change ported). Keep them in step with the VHDL until the
// hardware build moves to these files.
//-----------------------------------------------------------------------------

module svi_console #(
  parameter is_pal_g     = 1,
  parameter compat_rgb_g = 0
) (
  input               clk_i,
  input               pal_i,            // 1 = PAL, 0 = NTSC (cv_console.vhd pal_i)
  input               clk_en_10m7_i,
  input               clk_en_5m3_i,
  input               clk_en_cpu_p_i,   // Z80 enables from the top (turbo-capable)
  input               clk_en_cpu_n_i,
  input               reset_n_i,

  output logic [3:0]  svi_row_o,
  input        [7:0]  svi_col_i,

  input               svi_tap_i,
  input               tape_ready_n_i,   // PPI A6: 0 = a tape is in the deck
  output              motor_o,

  // active low: {fire, right, left, down, up}
  input        [4:0]  joy0_i,
  input        [4:0]  joy1_i,

  output       [15:0] cpu_ram_a_o,
  output              cpu_ram_ce_n_o,
  output              cpu_ram_rd_n_o,
  output              cpu_ram_we_n_o,
  input        [7:0]  cpu_ram_d_i,
  output       [7:0]  cpu_ram_d_o,

  output       [7:0]  ay_port_b,

  // expansion cards (cv_console.vhd: same ports)
  output              cpu_iorq_n_o,
  output              cpu_m1_n_o,
  input               ext_d_en_i,
  input        [7:0]  ext_d_i,
  input               ext_wait_n_i,
  input               turbo_i,       // Z80 at 4x: pace VDP accesses (as cv_console.vhd)

  output       [13:0] vram_a_o,
  output              vram_we_o,
  output       [7:0]  vram_d_o,
  input        [7:0]  vram_d_i,

  input               border_i,
  output       [7:0]  rgb_r_o,
  output       [7:0]  rgb_g_o,
  output       [7:0]  rgb_b_o,
  output              hsync_n_o,
  output              vsync_n_o,
  output              hblank_o,
  output              vblank_o,

  output       [10:0] audio_o,

  // debug taps for the simulator
  output       [7:0]  dbg_portc,
  output              dbg_m1_n,
  output              dbg_iorq_n,
  output              dbg_rd_n,
  output              dbg_wr_n,
  output       [7:0]  dbg_d_to_cpu,
  output       [7:0]  dbg_d_from_cpu
);

  logic por_n_s, reset_n_s;
  logic clk_en_3m58_p_s, clk_en_3m58_n_s;
  logic clk_en_1m79_p_s, clk_en_1m79_n_s;

  logic wait_n_s, int_n_s, nmi_n_s;
  logic iorq_n_s, m1_n_s, rd_n_s, wr_n_s, mreq_n_s, rfsh_n_s;
  logic [15:0] a_s;
  logic [7:0]  d_to_cpu_s, d_from_cpu_s;

  logic [7:0]  d_from_vdp_s;
  logic        vdp_int_n_s;
  logic [7:0]  ay_d_s;
  logic [9:0]  ay_sound;
  logic [7:0]  d_from_8255, portc_8255;

  logic ram_ce_n_s, vdp_r_n_s, vdp_w_n_s;
  logic ay_addr_we_n_s, ay_data_we_n_s, ay_data_rd_n_s, u8255_cs_n_s;

  logic key_beep, motor;
  logic [7:0] ay_latch_b;
  logic [3:0] ay_reg;
  logic       ay_b_out;

  assign motor_o = motor;
  assign audio_o = {key_beep, ((portc_8255[6] & svi_tap_i) | portc_8255[5]), 9'd0} | {ay_sound, 1'b0};

  assign int_n_s = vdp_int_n_s;
  assign nmi_n_s = 1'b1;

  // Reset -------------------------------------------------------------------
  cv_por por_b (.clk_i(clk_i), .por_n_o(por_n_s));
  assign reset_n_s = por_n_s & reset_n_i;

  // Clocks: Z80 enables from the top (cv_console.vhd: same), PSG enable = 5.3/3 --------------------------------
  assign clk_en_3m58_p_s = clk_en_cpu_p_i;
  assign clk_en_3m58_n_s = clk_en_cpu_n_i;
  cv_clock clock_b2 (
    .clk_i(clk_i), .clk_en_10m7_i(clk_en_5m3_i), .reset_n_i(reset_n_s),
    .clk_en_3m58_p_o(clk_en_1m79_p_s), .clk_en_3m58_n_o(clk_en_1m79_n_s));

  // CPU ---------------------------------------------------------------------
`ifdef SIM_T80
  // The hardware's CPU: T80pa (rtl/T80, Mode 0) as a GHDL netlist
  // (cpu_tests/gen/t80pa_synth.v), with both clock phases as on hardware.
  T80pa cpu (
    .RESET_n(reset_n_s), .CLK(clk_i), .CEN_p(clk_en_3m58_p_s), .CEN_n(clk_en_3m58_n_s),
    .WAIT_n(wait_n_s & ext_wait_n_i & vdp_wait_n_s), .INT_n(int_n_s), .NMI_n(nmi_n_s), .BUSRQ_n(1'b1),
    .OUT0(1'b0), .DI(d_to_cpu_s), .DIRSet(1'b0), .DIR(212'd0),
    .M1_n(m1_n_s), .MREQ_n(mreq_n_s), .IORQ_n(iorq_n_s), .RD_n(rd_n_s), .WR_n(wr_n_s),
    .RFSH_n(rfsh_n_s), .HALT_n(), .BUSAK_n(), .A(a_s), .DO(d_from_cpu_s), .REG());
`else
  tv80e cpu (
    .reset_n(reset_n_s), .clk(clk_i), .cen(clk_en_3m58_p_s),
    .wait_n(wait_n_s & ext_wait_n_i & vdp_wait_n_s), .int_n(int_n_s), .nmi_n(nmi_n_s), .busrq_n(1'b1),
    .m1_n(m1_n_s), .mreq_n(mreq_n_s), .iorq_n(iorq_n_s),
    .rd_n(rd_n_s), .wr_n(wr_n_s), .rfsh_n(rfsh_n_s),
    .halt_n(), .busak_n(),
    .A(a_s), .di(d_to_cpu_s), .dout(d_from_cpu_s));
`endif

  // M1 wait state (the two 74LS74s of cv_console.vhd): one wait per M1 cycle
  logic m1_wait_q;
  wire  m1_wait_clr = ~reset_n_s | m1_n_s;
  always @(posedge clk_i or posedge m1_wait_clr)
    if (m1_wait_clr) m1_wait_q <= 1'b0;
    else if (clk_en_3m58_p_s) m1_wait_q <= ~m1_wait_q;
  assign wait_n_s = ~m1_wait_q;

  // VDP access pacing under tape turbo (see cv_console.vhd vdp_pace)
  logic vdp_busy_s, vdp_pass_q, vdp_seen_q;
  wire  vdp_acc_s    = ~(vdp_r_n_s & vdp_w_n_s);
  wire  vdp_hold_s   = turbo_i & ~vdp_pass_q;
  wire  vdp_wait_n_s = ~(turbo_i & vdp_acc_s & ~vdp_seen_q);
  always_ff @(posedge clk_i) begin
    if (~reset_n_s | ~vdp_acc_s) begin
      vdp_pass_q <= 1'b0;
      vdp_seen_q <= 1'b0;
    end else begin
      if (~vdp_busy_s) vdp_pass_q <= 1'b1;
      if (vdp_pass_q & clk_en_10m7_i) vdp_seen_q <= 1'b1;
    end
  end

  // AY-3-8910 ---------------------------------------------------------------
  jt49_bus psg (
    .rst_n(reset_n_s), .clk(clk_i), .clk_en(clk_en_1m79_p_s),
    .bdir(~ay_addr_we_n_s | ~ay_data_we_n_s),
    .bc1(~ay_addr_we_n_s | ~ay_data_rd_n_s),
    .din(d_from_cpu_s), .sel(1'b0), .dout(ay_d_s),
    .sound(ay_sound), .A(), .B(), .C(), .sample(),
    .IOA_in({joy1_i[3:0], joy0_i[3:0]}), .IOA_out(),
    .IOB_in(8'hFF), .IOB_out(ay_latch_b));

  // Port B drives the bank lines only as an output (R7 bit 7); after reset it
  // is an input and the AY's pull-ups make it read FF (cv_console.vhd psg_portb).
  always @(posedge clk_i or negedge reset_n_s)
    if (~reset_n_s) begin ay_reg <= 4'd0; ay_b_out <= 1'b0; end
    else begin
      if (~ay_addr_we_n_s) ay_reg <= d_from_cpu_s[3:0];
      if (~ay_data_we_n_s && ay_reg == 4'd7) ay_b_out <= d_from_cpu_s[7];
    end
  assign ay_port_b = ay_b_out ? ay_latch_b : 8'hFF;

  // 8255 PPI ----------------------------------------------------------------
  // A: 7 tape in, 6 /ready, 5 joy2 fire, 4 joy1 fire, 3:0 paddles
  jt8255 ppi (
    .rst(~reset_n_s), .clk(clk_i),
    .addr(a_s[1:0]), .din(d_from_cpu_s), .dout(d_from_8255),
    .rdn(rd_n_s), .wrn(wr_n_s), .csn(u8255_cs_n_s),
    .porta_din({svi_tap_i, tape_ready_n_i, joy1_i[4], joy0_i[4], 4'b1111}),
    .portb_din(svi_col_i),
    .portc_din(8'd0),
    .porta_dout(), .portb_dout(), .portc_dout(portc_8255));

  assign dbg_portc = portc_8255;

  // VDP ---------------------------------------------------------------------
  vdp18_core #(.is_pal_g(is_pal_g), .compat_rgb_g(compat_rgb_g)) vdp (
    .clk_i(clk_i), .pal_i(pal_i), .clk_en_10m7_i(clk_en_10m7_i), .reset_n_i(reset_n_s),
    .csr_n_i(vdp_r_n_s | vdp_hold_s), .csw_n_i(vdp_w_n_s | vdp_hold_s), .mode_i(a_s[0]),
    .int_n_o(vdp_int_n_s),
    .cd_i(d_from_cpu_s), .cd_o(d_from_vdp_s), .cpu_busy_o(vdp_busy_s),
    .vram_we_o(vram_we_o), .vram_a_o(vram_a_o),
    .vram_d_o(vram_d_o), .vram_d_i(vram_d_i),
    .border_i(border_i), .col_o(),
    .rgb_r_o(rgb_r_o), .rgb_g_o(rgb_g_o), .rgb_b_o(rgb_b_o),
    .hsync_n_o(hsync_n_o), .vsync_n_o(vsync_n_o), .blank_n_o(),
    .hblank_o(hblank_o), .vblank_o(vblank_o), .comp_sync_n_o());

  // Address decoder (cv_addr_dec.vhd) ---------------------------------------
  always_comb begin
    ram_ce_n_s     = 1'b1;
    vdp_r_n_s      = 1'b1;
    vdp_w_n_s      = 1'b1;
    ay_addr_we_n_s = 1'b1;
    ay_data_we_n_s = 1'b1;
    ay_data_rd_n_s = 1'b1;
    u8255_cs_n_s   = 1'b1;
    if (rfsh_n_s) begin
      if (~mreq_n_s) ram_ce_n_s = 1'b0;
      if (~iorq_n_s & m1_n_s) begin
        // as rtl/cv_addr_dec.vhd: STM-A IC21 LS138, A7=1 A6=0, A4..A2 select,
        // A5/A1/A0 not decoded (80-9F mirrored at A0-BF)
        if (a_s[7:6] == 2'b10)
          case (a_s[4:2])
            3'd0: vdp_w_n_s      = wr_n_s;
            3'd1: vdp_r_n_s      = rd_n_s;
            3'd2: ay_addr_we_n_s = wr_n_s;
            3'd3: ay_data_we_n_s = wr_n_s;
            3'd4: ay_data_rd_n_s = rd_n_s;
            3'd5: u8255_cs_n_s   = wr_n_s;
            3'd6: u8255_cs_n_s   = rd_n_s;
            default: ;
          endcase
      end
    end
  end

  assign cpu_ram_a_o    = a_s;
  assign cpu_ram_ce_n_o = ram_ce_n_s;
  assign cpu_ram_we_n_o = wr_n_s;
  assign cpu_ram_rd_n_o = rd_n_s;
  assign cpu_ram_d_o    = d_from_cpu_s;

  // Bus mux (cv_bus_mux.vhd): AND of the selected sources, idle = FF -------
  assign cpu_iorq_n_o = iorq_n_s;
  assign cpu_m1_n_o   = m1_n_s;
  wire [7:0] d_mux_s;
  assign d_to_cpu_s = ext_d_en_i ? ext_d_i : d_mux_s;
  assign d_mux_s    = (ram_ce_n_s     ? 8'hFF : cpu_ram_d_i)  &
                      (vdp_r_n_s      ? 8'hFF : d_from_vdp_s) &
                      (u8255_cs_n_s   ? 8'hFF : d_from_8255)  &
                      (ay_data_rd_n_s ? 8'hFF : ay_d_s);

  // Keyboard row, click, motor latch ----------------------------------------
  always @(posedge clk_i or negedge reset_n_s)
    if (~reset_n_s) begin
      svi_row_o <= 4'd0;
      key_beep  <= 1'b0;
      motor     <= 1'b1;
    end else begin
      svi_row_o <= portc_8255[3:0];
      key_beep  <= portc_8255[7];
      motor     <= portc_8255[4];
    end

  assign dbg_m1_n       = m1_n_s;
  assign dbg_iorq_n     = iorq_n_s;
  assign dbg_rd_n       = rd_n_s;
  assign dbg_wr_n       = wr_n_s;
  assign dbg_d_to_cpu   = d_to_cpu_s;
  assign dbg_d_from_cpu = d_from_cpu_s;

endmodule
