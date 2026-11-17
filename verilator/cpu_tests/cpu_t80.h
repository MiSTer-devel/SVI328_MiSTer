// T80pa adapter: t80sv_T80pa (rtl/t80sv, Mode 0, as instanced in rtl/cv_console.vhd),
// through the wrapper T80pa_t80sv.sv. One T-state = one CLK with CEN_p followed by
// one CLK with CEN_n, like clk_en_3m58_p/_n on hardware. State is loaded with the
// core's own DIRSet/DIR port and read from REG; WZ and Fw (Q), which are not in
// DIR/REG, are poked/read directly (t80sv_regs.h, t80sv.vlt).
#pragma once
#include "VT80pa.h"
#include "VT80pa___024root.h"
#include "harness.h"
#include "t80sv_regs.h"

struct CpuT80 {
  static const char *name() { return "t80"; }
  static constexpr bool has_wz = true;
#ifdef T80_QF
  static constexpr bool has_q = true;
#else
  static constexpr bool has_q = false;
#endif
  int q_init = 0;
  static constexpr int clocks_per_t = 2;
  VT80pa *top;
  int wz_repoke = 0;
  bool no_wz = false;  // GHDL cross-check: the VHDL testbench cannot load WZ either
  uint16_t wz_init = 0;
  CpuT80() {
    top = new VT80pa;
    top->CLK = 0; top->CEN_p = 0; top->CEN_n = 0; top->WAIT_n = 1; top->INT_n = 1; top->NMI_n = 1;
    top->BUSRQ_n = 1; top->OUT0 = 0; top->DI = 0; top->DIRSet = 0; top->RESET_n = 1; top->eval();
    // T80pa does not reset IntCycleD_n: after power-up it is 00 and IORQ_n goes low during
    // the first M1 (looks like an interrupt acknowledge). Run a few NOPs once so it is 11.
    reset();
    for (int i = 0; i < 16; i++) {
      top->CEN_p = 1; top->CEN_n = 0; clk(); top->CEN_p = 0; top->CEN_n = 1; clk();
    }
    top->CEN_n = 0; top->eval();
  }
  Pins pins() const {
    Pins p;
    p.m1 = !top->M1_n; p.mreq = !top->MREQ_n; p.iorq = !top->IORQ_n; p.rd = !top->RD_n;
    p.wr = !top->WR_n; p.rfsh = !top->RFSH_n; p.halt = !top->HALT_n; p.a = top->A; p.dout = top->DO;
    return p;
  }
  void clk() { top->CLK = 1; top->eval(); top->CLK = 0; top->eval(); }
  void reset() {
    top->RESET_n = 0; top->CEN_p = 0; top->CEN_n = 0; top->eval();
    for (int i = 0; i < 4; i++) clk();
    top->RESET_n = 1; top->eval();
  }
  static void setbits(VlWide<7> &w, int lo, int n, uint32_t v) {
    for (int i = 0; i < n; i++) {
      int b = lo + i;
      if (v >> i & 1) w[b / 32] |= 1u << (b % 32); else w[b / 32] &= ~(1u << (b % 32));
    }
  }
  static uint32_t getbits(const VlWide<7> &w, int lo, int n) {
    uint32_t v = 0;
    for (int i = 0; i < n; i++) { int b = lo + i; v |= (uint32_t)(w[b / 32] >> (b % 32) & 1) << i; }
    return v;
  }
  void load(const Regs &r) {
    VlWide<7> d;
    for (int i = 0; i < 7; i++) d[i] = 0;
    setbits(d, 0, 8, r.a); setbits(d, 8, 8, r.f); setbits(d, 16, 8, r.af_ >> 8); setbits(d, 24, 8, r.af_ & 0xff);
    setbits(d, 32, 8, r.i); setbits(d, 40, 8, r.r); setbits(d, 48, 16, r.sp); setbits(d, 64, 16, r.pc);
    const uint16_t rp[8] = {(uint16_t)(r.b << 8 | r.c), (uint16_t)(r.d << 8 | r.e), (uint16_t)(r.h << 8 | r.l),
                            r.ix, r.bc_, r.de_, r.hl_, r.iy};
    for (int k = 0; k < 8; k++) setbits(d, 80 + 16 * k, 16, rp[k]);
    setbits(d, 208, 2, r.im); setbits(d, 210, 1, r.iff1); setbits(d, 211, 1, r.iff2);
    for (int i = 0; i < 7; i++) top->DIR[i] = d[i];
    top->DIRSet = 1; top->eval();
    clk();
    top->DIRSet = 0; top->eval();
    if (!no_wz) {
      T80_WZ(top) = r.wz;
      top->eval();
      wz_repoke = 1; wz_init = r.wz;
      q_init = r.q != 0;
#ifdef T80_QF
      T80_QF(top) = q_init; top->eval();
#endif
    }
  }
  void dump_reg(FILE *f) {
    for (int i = 52; i >= 0; i--) fprintf(f, "%X", getbits(top->REG, i * 4, 4));
    fprintf(f, "\n");
  }
  void read(Regs &r) {
    const VlWide<7> &g = top->REG;
    r.a = getbits(g, 0, 8); r.f = getbits(g, 8, 8);
    r.af_ = getbits(g, 16, 8) << 8 | getbits(g, 24, 8);
    r.i = getbits(g, 32, 8); r.r = getbits(g, 40, 8); r.sp = getbits(g, 48, 16); r.pc = getbits(g, 64, 16);
    uint16_t rp[8];
    for (int k = 0; k < 8; k++) rp[k] = getbits(g, 80 + 16 * k, 16);
    r.b = rp[0] >> 8; r.c = rp[0]; r.d = rp[1] >> 8; r.e = rp[1]; r.h = rp[2] >> 8; r.l = rp[2];
    r.ix = rp[3]; r.bc_ = rp[4]; r.de_ = rp[5]; r.hl_ = rp[6]; r.iy = rp[7];
    r.im = getbits(g, 208, 2); r.iff1 = getbits(g, 210, 1); r.iff2 = getbits(g, 211, 1);
    r.wz = T80_WZ(top);
#ifdef T80_QF
    r.q = T80_QF(top) ? r.f : 0;
#endif
  }
  // outputs only change on CLK rising edges, so DI for the coming edge is computed from
  // the current pins; two evals per CLK
  template <class BUS> void half(BUS &bus, bool p) {
    top->WAIT_n = bus.wait_n(p);
    top->CEN_p = p; top->CEN_n = !p;
    top->CLK = 0; top->DI = bus.data(pins()); top->eval();
    top->CLK = 1; top->eval();
    if (p && wz_repoke) {
      // The first CEN_p edge after reset leaves TState 0 (the reset state, before T1 of the
      // first fetch); it ends the dummy "instruction" IR=00, whose SetWZ executes WZ <= ID16.
      // Restore the test's WZ after it.
      wz_repoke = 0; T80_WZ(top) = wz_init; top->eval();
#ifdef T80_QF
      T80_QF(top) = q_init; top->eval();
#endif
    }
    bus.clocked(p, pins());
    bus.sample(pins());
  }
  template <class BUS> void tstate(BUS &bus) {
    top->INT_n = bus.int_n; top->NMI_n = bus.nmi_n;
    half(bus, true);
    half(bus, false);
  }

};
