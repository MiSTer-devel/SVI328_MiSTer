// Shared CPU test bench pieces: register set, pin snapshot, flat 64K memory + I/O bus model.
#pragma once
#include <cstdint>
#include <cstring>
#include <vector>

struct Regs {
  uint16_t pc = 0, sp = 0;
  uint8_t a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, h = 0, l = 0, i = 0, r = 0;
  int ei = 0;
  uint16_t wz = 0, ix = 0, iy = 0, af_ = 0, bc_ = 0, de_ = 0, hl_ = 0;
  int im = 0, p = 0, q = 0, iff1 = 0, iff2 = 0;
};

struct Pins {  // all active-high here
  bool m1 = 0, mreq = 0, iorq = 0, rd = 0, wr = 0, rfsh = 0, halt = 0;
  uint16_t a = 0;
  uint8_t dout = 0;
};

enum { K_MRD = 0, K_MWR = 1, K_IORD = 2, K_IOWR = 3, K_INTA = 4 };

struct Txn {
  long t;      // T-state index in which the strobe was first seen
  int kind;
  uint16_t a;
  int d;
  bool m1;
};
struct Ev {
  long t;
  uint16_t a;
};

struct Bus {
  uint8_t mem[65536];
  // I/O reads: value for a port address (SingleStepTests list), default
  std::vector<std::pair<uint16_t, uint8_t>> in_ports;
  uint8_t in_default = 0xff;
  uint8_t int_vector = 0xff;
  int int_n = 1, nmi_n = 1;
  bool m1wait = false;  // model the SVI-328 74LS74 M1 wait-state circuit
  int wq = 0;
  long t = 0;
  Pins prev;
  std::vector<Txn> txns;
  std::vector<Ev> m1s, rfsh, iowr;
  bool pend_mw = false, pend_iw = false;
  Txn pm, pi;
  long halt_t = -1;

  void clear_events() {
    txns.clear(); m1s.clear(); rfsh.clear(); iowr.clear();
    pend_mw = pend_iw = false; wq = 0; prev = Pins(); halt_t = -1; in_inta = false;
  }
  uint8_t port_in(uint16_t a) const {
    for (auto &p : in_ports) if (p.first == a) return p.second;
    return in_default;
  }
  bool inta_hold = false;  // device keeps the vector on the bus until M1 ends
  bool in_inta = false;
  uint8_t data(const Pins &p) const {
    if (p.iorq && p.m1) return int_vector;
    if (inta_hold && in_inta && p.m1) return int_vector;
    if (p.iorq && p.rd) return port_in(p.a);
    return mem[p.a];
  }
  // svi_console.sv: m1_wait_q toggles on every clk_en_3m58_p while M1_n is low,
  // cleared asynchronously while M1_n is high; WAIT_n = ~m1_wait_q
  int wait_n(bool) const { return m1wait ? !wq : 1; }
  void clocked(bool pedge, const Pins &p) {
    if (!m1wait) return;
    if (pedge && prev.m1) wq = !wq;
    if (!p.m1) wq = 0;
  }
  FILE *dump = nullptr;  // pin trace, one line per sample (cross-check against GHDL)
  void sample(const Pins &p) {
    if (dump) {
      if (p.wr) fprintf(dump, "%04X %02X %d%d%d%d%d%d\n", p.a, p.dout, p.m1, p.mreq, p.iorq, p.rd, p.wr, p.rfsh);
      else fprintf(dump, "%04X -- %d%d%d%d%d%d\n", p.a, p.m1, p.mreq, p.iorq, p.rd, p.wr, p.rfsh);
    }
    if (p.m1 && !prev.m1) m1s.push_back({t, p.a});
    if (p.rfsh && !prev.rfsh) rfsh.push_back({t, p.a});
    if (p.halt && halt_t < 0) halt_t = t;
    bool mr = p.mreq && p.rd, pmr = prev.mreq && prev.rd;
    if (mr && !(pmr && prev.a == p.a)) txns.push_back({t, K_MRD, p.a, mem[p.a], p.m1});
    bool ir = p.iorq && p.rd && !p.m1, pir = prev.iorq && prev.rd && !prev.m1;
    if (ir && !(pir && prev.a == p.a)) txns.push_back({t, K_IORD, p.a, port_in(p.a), false});
    bool ia = p.iorq && p.m1, pia = prev.iorq && prev.m1;
    if (ia && !pia) txns.push_back({t, K_INTA, p.a, int_vector, true});
    if (ia) in_inta = true;
    if (!p.m1) in_inta = false;
    bool mw = p.mreq && p.wr;
    if (mw) {
      if (!pend_mw) { pend_mw = true; pm = {t, K_MWR, p.a, p.dout, p.m1}; }
      pm.a = p.a; pm.d = p.dout;
    } else if (pend_mw) {
      mem[pm.a] = pm.d; txns.push_back(pm); pend_mw = false;
    }
    bool iw = p.iorq && p.wr;
    if (iw) {
      if (!pend_iw) { pend_iw = true; pi = {t, K_IOWR, p.a, p.dout, false}; }
      pi.a = p.a; pi.d = p.dout;
    } else if (pend_iw) {
      txns.push_back(pi); iowr.push_back({pi.t, (uint16_t)(pi.a)}); iowr.back().a = pi.a;
      last_out_port = pi.a; last_out_val = pi.d; out_count++;
      pend_iw = false;
    }
    prev = p;
  }
  // last completed OUT, for the CP/M stub
  uint16_t last_out_port = 0;
  uint8_t last_out_val = 0;
  long out_count = 0;
};
