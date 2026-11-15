// tv80e adapter for the CPU test harness (see harness.h).
// One clk with cen=1 is one T-state, as in svi_console.sv (cen = 3.58 MHz enable).
#pragma once
#include "Vtv80e.h"
#include "Vtv80e___024root.h"
#include "harness.h"

#define TV80_CORE(x) top->rootp->tv80e__DOT__i_tv80_core__DOT__##x
#define TV80_REGF(x) top->rootp->tv80e__DOT__i_tv80_core__DOT__i_reg__DOT__##x

struct CpuTV80 {
  static const char *name() { return "tv80"; }
  static constexpr bool has_wz = false;  // TmpAddr is a scratch register, not MEMPTR
  static constexpr int clocks_per_t = 1;
  Vtv80e *top;
  CpuTV80() {
    top = new Vtv80e;
    top->clk = 0; top->cen = 1; top->wait_n = 1; top->int_n = 1; top->nmi_n = 1;
    top->busrq_n = 1; top->di = 0; top->reset_n = 1; top->eval();
  }
  Pins pins() const {
    Pins p;
    p.m1 = !top->m1_n; p.mreq = !top->mreq_n; p.iorq = !top->iorq_n; p.rd = !top->rd_n;
    p.wr = !top->wr_n; p.rfsh = !top->rfsh_n; p.halt = !top->halt_n; p.a = top->A; p.dout = top->dout;
    return p;
  }
  void reset() {
    top->reset_n = 0; top->clk = 0; top->eval();
    for (int i = 0; i < 4; i++) { top->clk = 1; top->eval(); top->clk = 0; top->eval(); }
    top->reset_n = 1; top->eval();
  }
  // after reset(): the core is at M1/T1 with A = PC = 0; overwrite the state
  void load(const Regs &r) {
    TV80_CORE(ACC) = r.a; TV80_CORE(F) = r.f;
    TV80_CORE(Ap) = r.af_ >> 8; TV80_CORE(Fp) = r.af_ & 0xff;
    TV80_CORE(I) = r.i; TV80_CORE(R) = r.r;
    TV80_CORE(SP) = r.sp; TV80_CORE(PC) = r.pc; TV80_CORE(A) = r.pc;
    TV80_CORE(TmpAddr) = r.wz;
    TV80_CORE(Alternate) = 0;
    TV80_CORE(IntE_FF1) = r.iff1; TV80_CORE(IntE_FF2) = r.iff2; TV80_CORE(IStatus) = r.im;
    const uint16_t rp[8] = {(uint16_t)(r.b << 8 | r.c), (uint16_t)(r.d << 8 | r.e), (uint16_t)(r.h << 8 | r.l),
                            r.ix, r.bc_, r.de_, r.hl_, r.iy};
    for (int i = 0; i < 8; i++) { TV80_REGF(RegsH)[i] = rp[i] >> 8; TV80_REGF(RegsL)[i] = rp[i] & 0xff; }
    top->eval();
  }
  void read(Regs &r) {
    int alt = TV80_CORE(Alternate) & 1;
    auto rp = [&](int i) { return (uint16_t)(TV80_REGF(RegsH)[i] << 8 | TV80_REGF(RegsL)[i]); };
    uint16_t bc = rp(alt * 4 + 0), de = rp(alt * 4 + 1), hl = rp(alt * 4 + 2);
    r.b = bc >> 8; r.c = bc; r.d = de >> 8; r.e = de; r.h = hl >> 8; r.l = hl;
    r.bc_ = rp((1 - alt) * 4 + 0); r.de_ = rp((1 - alt) * 4 + 1); r.hl_ = rp((1 - alt) * 4 + 2);
    r.ix = rp(3); r.iy = rp(7);
    r.a = TV80_CORE(ACC); r.f = TV80_CORE(F); r.af_ = TV80_CORE(Ap) << 8 | TV80_CORE(Fp);
    r.i = TV80_CORE(I); r.r = TV80_CORE(R); r.sp = TV80_CORE(SP); r.pc = TV80_CORE(PC);
    r.wz = TV80_CORE(TmpAddr);
    r.iff1 = TV80_CORE(IntE_FF1); r.iff2 = TV80_CORE(IntE_FF2); r.im = TV80_CORE(IStatus);
  }
  // one T-state; bus(pins) returns the data bus value to drive, sample(pins) records activity
  template <class BUS> void tstate(BUS &bus) {
    top->wait_n = bus.wait_n(true);
    top->int_n = bus.int_n; top->nmi_n = bus.nmi_n;
    top->clk = 0; top->di = bus.data(pins()); top->eval();
    top->clk = 1; top->eval();
    bus.clocked(true, pins());
    bus.sample(pins());
  }

};
