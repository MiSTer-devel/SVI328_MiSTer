// CPU test bench for tv80e / T80pa (selected at build time with -DCPU_TV80 or -DCPU_T80).
//
//   sst  FILE.txt...      SingleStepTests/z80 (converted by tools/sst_convert.py); one result line per file
//   zex  FILE.com         CP/M program (ZEXDOC/ZEXALL) at 0100h with a BDOS stub; console on stdout
//   irq                   interrupt acknowledge timing (IM 0/1/2, NMI, from HALT)
//
// Options: --m1wait (SVI-328 M1 wait-state circuit), --verbose N (print N failing tests per file),
//          --max-t N (zex: stop after N T-states)
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>
#include "verilated.h"
#include "harness.h"

#if defined(CPU_TV80)
#include "cpu_tv80.h"
typedef CpuTV80 Cpu;
#elif defined(CPU_T80)
#include "cpu_t80.h"
typedef CpuT80 Cpu;
#else
#error "define CPU_TV80 or CPU_T80"
#endif

double sc_time_stamp() { return 0; }

static Cpu *cpu;
static Bus *bus;
static bool m1wait = false;
static int verbose = 3;
static bool trace = false;
static long max_t = 400;

// ---------------------------------------------------------------------------------------------
// SingleStepTests
// ---------------------------------------------------------------------------------------------
enum Field {
  F_PC, F_SP, F_A, F_FDOC, F_FXY, F_B, F_C, F_D, F_E, F_H, F_L, F_I, F_R, F_IX, F_IY,
  F_AF_, F_BC_, F_DE_, F_HL_, F_IM, F_IFF1, F_IFF2, F_WZ, F_RAM, F_CYC, F_BUS, F_BUST, F_PORT, F_N
};
static const char *fname[F_N] = {"pc", "sp", "a", "f", "f53", "b", "c", "d", "e", "h", "l", "i", "r",
                                 "ix", "iy", "af_", "bc_", "de_", "hl_", "im", "iff1", "iff2", "wz",
                                 "ram", "cycles", "bus", "bustime", "ports"};

struct Test {
  std::string name;
  Regs ini, fin;
  std::vector<std::pair<uint16_t, uint8_t>> ram0, ram1;
  int ncyc = 0;
  std::vector<Txn> txn;
  std::vector<std::array<int, 3>> ports;
};

static bool read_regs(FILE *f, Regs &r) {
  int v[25];
  for (int i = 0; i < 25; i++) if (fscanf(f, "%d", &v[i]) != 1) return false;
  r.pc = v[0]; r.sp = v[1]; r.a = v[2]; r.b = v[3]; r.c = v[4]; r.d = v[5]; r.e = v[6]; r.f = v[7];
  r.h = v[8]; r.l = v[9]; r.i = v[10]; r.r = v[11]; r.ei = v[12]; r.wz = v[13]; r.ix = v[14]; r.iy = v[15];
  r.af_ = v[16]; r.bc_ = v[17]; r.de_ = v[18]; r.hl_ = v[19]; r.im = v[20]; r.p = v[21]; r.q = v[22];
  r.iff1 = v[23]; r.iff2 = v[24];
  return true;
}
static bool read_test(FILE *f, Test &t) {
  char tag[8], name[128];
  int n;
  if (fscanf(f, "%7s %127s", tag, name) != 2) return false;
  t.name = name;
  fscanf(f, "%7s", tag); read_regs(f, t.ini);
  fscanf(f, "%7s %d", tag, &n); t.ram0.resize(n);
  for (auto &p : t.ram0) { int a, v; fscanf(f, "%d %d", &a, &v); p = {(uint16_t)a, (uint8_t)v}; }
  fscanf(f, "%7s", tag); read_regs(f, t.fin);
  fscanf(f, "%7s %d", tag, &n); t.ram1.resize(n);
  for (auto &p : t.ram1) { int a, v; fscanf(f, "%d %d", &a, &v); p = {(uint16_t)a, (uint8_t)v}; }
  fscanf(f, "%7s %d", tag, &t.ncyc);
  fscanf(f, "%7s %d", tag, &n); t.txn.resize(n);
  for (auto &x : t.txn) { int ti, k, a, d; fscanf(f, "%d %d %d %d", &ti, &k, &a, &d); x = {ti, k, (uint16_t)a, d, false}; }
  fscanf(f, "%7s %d", tag, &n); t.ports.resize(n);
  for (auto &p : t.ports) fscanf(f, "%d %d %d", &p[0], &p[1], &p[2]);
  return true;
}

// number of M1 cycles of the instruction, from the file name ("dd_cb___06" -> 2)
static int m1_count(const std::string &base) {
  int n = 1;
  size_t i = 0;
  while (i + 2 <= base.size()) {
    std::string b = base.substr(i, 2);
    if (b == "cb" || b == "ed") return n + 1;
    if (b == "dd" || b == "fd") {
      n++;
      if (base.compare(i + 3, 2, "cb") == 0) return n;  // DD CB d op: d and op are not M1 reads
      i += 3;
      continue;
    }
    return n;
  }
  return n;
}

// Flags the Zilog manual defines for the instruction (S Z H PV N C = D7); X/Y (28) never
static int doc_flag_mask(const std::string &b) {
  auto is = [&](const char *p) { return b == p; };
  // INI/IND/OUTI/OUTD and repeats: the manual gives Z (B-1 = 0), "N set", "C not affected",
  // S H P/V unknown. Real silicon sets N = bit 7 of the byte and changes C, H, P/V (which is
  // what the tests expect), so only Z is both documented and true.
  if (is("ed_a2") || is("ed_a3") || is("ed_aa") || is("ed_ab") || is("ed_b2") || is("ed_b3") || is("ed_ba") || is("ed_bb"))
    return 0x40;
  // BIT b: Z, H=1, N=0, C unaffected; S and P/V "unknown"
  int op = -1;
  if (b.size() == 5 && b.compare(0, 3, "cb_") == 0) op = strtol(b.c_str() + 3, 0, 16);
  if (b.size() == 11 && b.compare(3, 6, "cb____") == 0) op = strtol(b.c_str() + 9, 0, 16);
  if (op >= 0x40 && op < 0x80) return 0x53;
  return 0xd7;
}

struct Delta {  // per (kind, fetch) histogram of RTL-vs-test strobe offset
  std::map<int, long> h;
};

static std::string hex(int v, int w) { char b[16]; snprintf(b, sizeof b, "%0*X", w, v); return b; }

static void run_sst_file(const char *path, std::map<std::string, Delta> &deltas) {
  FILE *f = fopen(path, "r");
  if (!f) { perror(path); return; }
  std::string base = path;
  base = base.substr(base.find_last_of('/') + 1);
  base = base.substr(0, base.size() - 4);
  int nm1 = m1_count(base);
  int fdoc = doc_flag_mask(base);
  long count[F_N] = {0};
  std::string example[F_N];
  std::map<std::string, std::map<int, long>> fdelta;
  long ntest = 0, npass = 0, ndoc = 0, nundoc = 0;
  std::map<int, long> cyc_hist;  // rtl - test T-state difference
  int shown = 0;
  Test t;
  while (read_test(f, t)) {
    ntest++;
    memset(bus->mem, 0, sizeof bus->mem);
    for (auto &p : t.ram0) bus->mem[p.first] = p.second;
    bus->in_ports.clear();
    for (auto &p : t.ports) if (p[2] == 0) bus->in_ports.push_back({(uint16_t)p[0], (uint8_t)p[1]});
    bus->clear_events();
    bus->m1wait = m1wait;
    cpu->reset();
    cpu->load(t.ini);
    bus->prev = cpu->pins();
    Regs got;
    long boundary = -1;
    bool have = false;
    for (long ti = 0; ti < max_t; ti++) {
      bus->t = ti;
      cpu->tstate(*bus);
      if (trace) { Pins q = cpu->pins(); fprintf(stderr, "  T%ld m1%d mreq%d iorq%d rd%d wr%d rfsh%d A=%04X\n", ti, q.m1, q.mreq, q.iorq, q.rd, q.wr, q.rfsh, q.a); }
      if (boundary < 0 && (int)bus->m1s.size() > nm1) boundary = bus->m1s[nm1].t;
      if (boundary >= 0 && ti == boundary + 2) { cpu->read(got); have = true; }
      if (boundary >= 0 && ti >= boundary + 3) break;
    }
    unsigned bad[F_N] = {0};
    std::string detail[F_N];
    auto chk = [&](int fld, int exp, int g, int w) {
      if (exp != g) { bad[fld] = 1; detail[fld] = "exp " + hex(exp, w) + " got " + hex(g, w); }
    };
    if (!have || bus->m1s.empty()) {
      bad[F_CYC] = 1; detail[F_CYC] = "instruction did not end within max T";
    } else {
      // PC, R and I as seen on the bus at the next opcode fetch
      got.pc = bus->m1s[nm1].a;
      int rf = -1;
      for (auto &e : bus->rfsh) if (e.t >= boundary) { rf = e.a; break; }
      if (rf >= 0) { got.r = rf & 0xff; got.i = rf >> 8; }
      const Regs &e = t.fin;
      chk(F_PC, e.pc, got.pc, 4); chk(F_SP, e.sp, got.sp, 4); chk(F_A, e.a, got.a, 2);
      // documented flags (Zilog manual); the rest of S Z H P/V N C is "unknown" for that instruction
      chk(F_FDOC, e.f & fdoc, got.f & fdoc, 2); chk(F_FXY, e.f & 0x28, got.f & 0x28, 2);
      if (!bad[F_FDOC] && (e.f & 0xd7 & ~fdoc) != (got.f & 0xd7 & ~fdoc)) bad[F_FXY] = 1;
      if (bad[F_FDOC] || bad[F_FXY]) {
        std::string s = "F exp " + hex(e.f, 2) + " got " + hex(got.f, 2);
        if (bad[F_FDOC]) detail[F_FDOC] = s;
        if (bad[F_FXY]) detail[F_FXY] = s;
      }
      chk(F_B, e.b, got.b, 2); chk(F_C, e.c, got.c, 2); chk(F_D, e.d, got.d, 2); chk(F_E, e.e, got.e, 2);
      chk(F_H, e.h, got.h, 2); chk(F_L, e.l, got.l, 2); chk(F_I, e.i, got.i, 2); chk(F_R, e.r, got.r, 2);
      chk(F_IX, e.ix, got.ix, 4); chk(F_IY, e.iy, got.iy, 4); chk(F_AF_, e.af_, got.af_, 4);
      chk(F_BC_, e.bc_, got.bc_, 4); chk(F_DE_, e.de_, got.de_, 4); chk(F_HL_, e.hl_, got.hl_, 4);
      chk(F_IM, e.im, got.im, 1); chk(F_IFF1, e.iff1, got.iff1, 1); chk(F_IFF2, e.iff2, got.iff2, 1);
      if (Cpu::has_wz) chk(F_WZ, e.wz, got.wz, 4);
      for (auto &p : t.ram1)
        if (bus->mem[p.first] != p.second && !bad[F_RAM]) {
          bad[F_RAM] = 1;
          detail[F_RAM] = "(" + hex(p.first, 4) + ") exp " + hex(p.second, 2) + " got " + hex(bus->mem[p.first], 2);
        }
      long cyc = bus->m1s[nm1].t - bus->m1s[0].t;
      long expc = t.ncyc + (m1wait ? nm1 : 0);
      cyc_hist[(int)(cyc - expc)]++;
      if (cyc != expc) { bad[F_CYC] = 1; detail[F_CYC] = "exp " + std::to_string(expc) + " got " + std::to_string(cyc); }
      // bus transactions of this instruction (before the next opcode fetch)
      std::vector<Txn> g;
      for (auto &x : bus->txns) if (x.t < boundary) g.push_back(x);
      std::stable_sort(g.begin(), g.end(), [](const Txn &a, const Txn &b) { return a.t < b.t; });
      static const char *kn[] = {"MR", "MW", "IR", "IW", "INTA"};
      auto ts = [&](const std::vector<Txn> &v, size_t n) {
        std::string s;
        for (size_t k = 0; k < v.size() && k < n; k++)
          s += std::string(k ? " " : "") + kn[v[k].kind] + ":" + hex(v[k].a, 4) + "=" + (v[k].d < 0 ? "??" : hex(v[k].d, 2));
        return s;
      };
      bool seq_ok = g.size() == t.txn.size();
      for (size_t k = 0; seq_ok && k < g.size(); k++)
        if (g[k].kind != t.txn[k].kind || g[k].a != t.txn[k].a || (t.txn[k].d >= 0 && g[k].d != t.txn[k].d)) seq_ok = false;
      if (!seq_ok) { bad[F_BUS] = 1; detail[F_BUS] = "exp [" + ts(t.txn, 12) + "] got [" + ts(g, 12) + "]"; }
      // strobe timing relative to the first opcode fetch
      if (seq_ok && !g.empty()) {
        long g0 = bus->m1s[0].t, t0 = 0;  // both relative to the start of the instruction's first M1
        std::string td;
        for (size_t k = 0; k < g.size(); k++) {
          int d = (int)((g[k].t - g0) - (t.txn[k].t - t0));
          std::string key = std::string(kn[g[k].kind]) + (g[k].m1 ? "(M1)" : "");
          deltas[key].h[d]++;
          fdelta[key][d]++;
          // expected strobe offsets are filled in by expect_delta()
          extern int expect_delta(int kind, bool m1);
          if (!m1wait && d != expect_delta(g[k].kind, g[k].m1) && td.empty())
            td = std::string(kn[g[k].kind]) + ":" + hex(g[k].a, 4) + " at T" + std::to_string(g[k].t - g0) +
                 ", test T" + std::to_string(t.txn[k].t - t0);
        }
        if (!td.empty()) { bad[F_BUST] = 1; detail[F_BUST] = td; }
      }
      // ports
      std::vector<std::pair<int, int>> pw;
      for (auto &x : g) if (x.kind == K_IOWR) pw.push_back({x.a, x.d});
      std::vector<std::pair<int, int>> ew;
      for (auto &p : t.ports) if (p[2] == 1) ew.push_back({p[0], p[1]});
      if (pw != ew) {
        bad[F_PORT] = 1;
        detail[F_PORT] = "OUT exp " + std::to_string(ew.size()) + " got " + std::to_string(pw.size());
        if (!ew.empty() && !pw.empty()) detail[F_PORT] += " (" + hex(ew[0].first, 4) + "=" + hex(ew[0].second, 2) +
                                                            " vs " + hex(pw[0].first, 4) + "=" + hex(pw[0].second, 2) + ")";
      }
    }
    bool any = false, doc = false;
    for (int k = 0; k < F_N; k++)
      if (bad[k]) {
        any = true;
        if (k != F_FXY && k != F_WZ && k != F_BUST) doc = true;
        if (!count[k]++) example[k] = t.name + ": " + detail[k];
      }
    if (!any) npass++;
    else if (doc) ndoc++;
    else nundoc++;
    if (any && shown < verbose) {
      shown++;
      fprintf(stderr, "FAIL %s:", t.name.c_str());
      for (int k = 0; k < F_N; k++) if (bad[k]) fprintf(stderr, " %s(%s)", fname[k], detail[k].c_str());
      fprintf(stderr, "\n");
    }
  }
  fclose(f);
  // file \t tests \t pass \t docfail \t undoconly \t field=count;... \t cyclehist \t examples
  printf("%s\t%ld\t%ld\t%ld\t%ld\t", base.c_str(), ntest, npass, ndoc, nundoc);
  bool first = true;
  for (int k = 0; k < F_N; k++) if (count[k]) { printf("%s%s=%ld", first ? "" : ",", fname[k], count[k]); first = false; }
  printf("\t");
  first = true;
  for (auto &h : cyc_hist) { printf("%s%+d:%ld", first ? "" : ",", h.first, h.second); first = false; }
  printf("\t");
  first = true;
  for (int k = 0; k < F_N; k++) if (count[k]) { printf("%s%s|%s", first ? "" : " ;; ", fname[k], example[k].c_str()); first = false; }
  printf("\t");
  first = true;
  for (auto &k : fdelta) {
    printf("%s%s", first ? "" : ";", k.first.c_str());
    for (auto &h : k.second) printf(" %+d:%ld", h.first, h.second);
    first = false;
  }
  printf("\n");
  fflush(stdout);
}

// Strobe offsets (RTL minus SingleStepTests, T-states, relative to the opcode fetch) that
// are just the different sampling convention and occur for every instruction.
static int exp_delta[5][2];
int expect_delta(int kind, bool m1) { return exp_delta[kind][m1]; }

// ---------------------------------------------------------------------------------------------
// Pin trace of the first N tests of each file, and the same tests as input for ghdl/tb_t80.vhd
// (T80 only): the GHDL simulation of the original VHDL must give the identical trace.
// ---------------------------------------------------------------------------------------------
#ifdef CPU_T80
static void run_pindump(const char *tbin, const std::vector<std::string> &files, int per_file) {
  FILE *o = fopen(tbin, "w");
  if (!o) { perror(tbin); return; }
  cpu->no_wz = true;
  for (auto &path : files) {
    FILE *f = fopen(path.c_str(), "r");
    if (!f) continue;
    Test t;
    for (int n = 0; n < per_file && read_test(f, t); n++) {
      const Regs &r = t.ini;
      int nt = t.ncyc + 4;
      fprintf(o, "%s\n%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", t.name.c_str(),
              r.pc, r.sp, r.a, r.f, r.b, r.c, r.d, r.e, r.h, r.l, r.i, r.r, r.ix, r.iy, r.af_, r.bc_, r.de_, r.hl_,
              r.im, r.iff1, r.iff2, nt);
      fprintf(o, "%zu", t.ram0.size());
      for (auto &p : t.ram0) fprintf(o, " %d %d", p.first, p.second);
      int nin = 0;
      for (auto &p : t.ports) nin += p[2] == 0;
      fprintf(o, "\n%d", nin);
      for (auto &p : t.ports) if (p[2] == 0) fprintf(o, " %d %d", p[0], p[1]);
      fprintf(o, "\n");
      memset(bus->mem, 0, sizeof bus->mem);
      for (auto &p : t.ram0) bus->mem[p.first] = p.second;
      bus->in_ports.clear();
      for (auto &p : t.ports) if (p[2] == 0) bus->in_ports.push_back({(uint16_t)p[0], (uint8_t)p[1]});
      bus->clear_events();
      cpu->reset();
      cpu->load(t.ini);
      bus->prev = cpu->pins();
      printf("T %s\n", t.name.c_str());
      bus->dump = stdout;
      for (int ti = 0; ti < nt; ti++) { bus->t = ti; cpu->tstate(*bus); }
      bus->dump = nullptr;
      printf("R ");
      cpu->dump_reg(stdout);
    }
    fclose(f);
  }
  fprintf(o, "END\n");
  fclose(o);
}
#endif

// ---------------------------------------------------------------------------------------------
// CP/M: ZEXDOC / ZEXALL
// ---------------------------------------------------------------------------------------------
static const uint8_t bdos_stub[] = {
    0x79, 0xFE, 0x02, 0x28, 0x06, 0xFE, 0x09, 0x28, 0x06, 0xC9, 0x00,  // FE00: LD A,C; CP 2; JR Z; CP 9; JR Z; RET
    0x7B, 0xD3, 0x01, 0xC9,                                            // FE0B: LD A,E; OUT (1),A; RET
    0x1A, 0xFE, 0x24, 0xC8, 0xD3, 0x01, 0x13, 0x18, 0xF7};             // FE0F: LD A,(DE); CP '$'; RET Z; OUT (1),A; INC DE; JR FE0F

static int run_zex(const char *path, long long maxt) {
  FILE *f = fopen(path, "rb");
  if (!f) { perror(path); return 1; }
  memset(bus->mem, 0, sizeof bus->mem);
  size_t n = fread(bus->mem + 0x100, 1, 0xFE00 - 0x100, f);
  fclose(f);
  fprintf(stderr, "%s: %zu bytes at 0100h, cpu %s%s\n", path, n, Cpu::name(), m1wait ? " +M1 wait" : "");
  bus->mem[0] = 0x76;                                         // warm boot: HALT
  bus->mem[5] = 0xC3; bus->mem[6] = 0x00; bus->mem[7] = 0xFE;  // JP FE00 (and SP top = FE00)
  memcpy(bus->mem + 0xFE00, bdos_stub, sizeof bdos_stub);
  bus->clear_events();
  bus->m1wait = m1wait;
  cpu->reset();
  Regs r;
  r.pc = 0x100; r.sp = 0xFE00;
  cpu->load(r);
  bus->prev = cpu->pins();
  long outs = 0;
  long long tt = 0;
  for (tt = 0; tt < maxt; tt++) {
    bus->t = tt;
    cpu->tstate(*bus);
    if (bus->out_count != outs) {
      outs = bus->out_count;
      if ((bus->last_out_port & 0xff) == 1) { fputc(bus->last_out_val, stdout); fflush(stdout); }
    }
    if (!bus->m1s.empty()) {
      if (bus->m1s.back().a == 0x0000) break;
      if (bus->m1s.size() > 4096) bus->m1s.erase(bus->m1s.begin(), bus->m1s.end() - 2);
    }
    if (bus->txns.size() > 4096) bus->txns.clear();
    if (bus->rfsh.size() > 4096) bus->rfsh.clear();
    if (bus->iowr.size() > 4096) bus->iowr.clear();
  }
  printf("\n[%s: %s after %lld T-states]\n", Cpu::name(), tt < maxt ? "warm boot" : "T-state limit", tt);
  return 0;
}

// ---------------------------------------------------------------------------------------------
// Interrupt acknowledge timing
// ---------------------------------------------------------------------------------------------
struct IrqCase {
  const char *name;
  std::vector<uint8_t> setup;  // at 0000h, followed by EI, then NOPs or HALT
  bool nmi, halt, early;       // early: request held from reset, before the EI
  uint8_t vector;
  uint16_t handler;
  int z80_t;  // documented T-states from the start of the acknowledge M1 to the handler's first M1
};

static bool inta_hold = false;  // keep the vector on the bus until M1 ends (not just during IORQ)

static void run_irq() {
  // IM 2: I=80h, vector FEh -> table at 80FEh = 9000h
  const std::vector<uint8_t> im1 = {0x31, 0x00, 0x80, 0xED, 0x56};
  const std::vector<uint8_t> im2 = {0x31, 0x00, 0x80, 0x3E, 0x80, 0xED, 0x47, 0xED, 0x5E};
  const std::vector<uint8_t> im0 = {0x31, 0x00, 0x80, 0xED, 0x46};
  std::vector<IrqCase> cs = {
      {"IM 1", im1, false, false, false, 0xFF, 0x0038, 13},
      {"IM 2", im2, false, false, false, 0xFE, 0x9000, 19},
      {"IM 0 (RST 38h on bus)", im0, false, false, false, 0xFF, 0x0038, 13},
      {"NMI", im1, true, false, false, 0xFF, 0x0066, 11},
      {"IM 1 from HALT", im1, false, true, false, 0xFF, 0x0038, 13},
      {"IM 2 from HALT", im2, false, true, false, 0xFE, 0x9000, 19},
      {"IM 1, INT low before EI", im1, false, false, true, 0xFF, 0x0038, 13},
  };
  printf("case\tz80_T\tcpu_T\tpushed_PC\tcycles in the acknowledge (T from its M1 start)\n");
  for (auto &c : cs) {
    memset(bus->mem, 0, sizeof bus->mem);
    size_t p = 0;
    for (auto b : c.setup) bus->mem[p++] = b;
    bus->mem[p++] = 0xFB;  // EI
    uint16_t after_ei = p;
    uint16_t halt_at = 0;
    if (c.halt) { halt_at = p; bus->mem[p++] = 0x76; }
    bus->mem[0x80FE] = 0x00; bus->mem[0x80FF] = 0x90;
    bus->clear_events();
    bus->m1wait = m1wait;
    bus->inta_hold = inta_hold;
    bus->int_vector = c.vector;
    bus->int_n = 1; bus->nmi_n = 1;
    cpu->reset();
    Regs r;
    cpu->load(r);
    bus->prev = cpu->pins();
    long ack = -1, hand = -1, raised = c.early ? 0 : -1;
    for (long ti = 0; ti < 2000 && hand < 0; ti++) {
      bus->t = ti;
      // raise the request after the setup has run (fetches beyond the EI)
      if (raised < 0 && !c.halt && !bus->m1s.empty() && bus->m1s.back().a >= p + 3) raised = ti;
      if (raised < 0 && c.halt && bus->halt_t >= 0 && ti > bus->halt_t + 8) raised = ti;
      if (raised >= 0) { if (c.nmi) bus->nmi_n = 0; else bus->int_n = 0; }
      bus->dump = (trace && raised >= 0 && ti < raised + 30) ? stderr : nullptr;
      if (bus->dump) fprintf(stderr, "T%ld:\n", ti);
      cpu->tstate(*bus);
      bus->dump = nullptr;
      for (size_t k = 0; k < bus->m1s.size(); k++)
        if (bus->m1s[k].a == c.handler && bus->m1s[k].t > raised && raised >= 0) { hand = bus->m1s[k].t; break; }
    }
    // acknowledge M1: the last M1 before the handler fetch (IM 2: before the table reads)
    for (size_t k = 0; k + 1 < bus->m1s.size(); k++)
      if (bus->m1s[k + 1].t == hand) ack = bus->m1s[k].t;
    if (hand < 0)  // never reached the handler: take the first acknowledge after the request
      for (auto &x : bus->txns) if ((x.kind == K_INTA || (c.nmi && x.m1)) && x.t >= raised) { 
        for (auto &m : bus->m1s) if (m.t <= x.t) ack = m.t;
        break;
      }
    int pushed = -1;
    std::vector<int> wr;
    for (auto &x : bus->txns) if (x.kind == K_MWR && ack >= 0 && x.t >= ack) wr.push_back(x.d);
    if (wr.size() >= 2) pushed = wr[0] << 8 | wr[1];
    std::string det;
    for (auto &x : bus->txns)
      if (ack >= 0 && x.t >= ack && (hand < 0 ? x.t < ack + 20 : x.t < hand)) {
        static const char *kn[] = {"MR", "MW", "IR", "IW", "INTA"};
        char b[48];
        snprintf(b, sizeof b, "%s%s %04X@T%ld", det.empty() ? "" : ", ", kn[x.kind], x.a, x.t - ack + 1);
        det += b;
      }
    const char *note = "";
    if (c.halt) note = pushed == halt_at + 1 ? " (HALT+1 ok)" : " (HALT+1 expected)";
    if (c.early) note = pushed == after_ei + 1 ? " (EI+NOP ok)" : " (EI+NOP expected)";
    int expT = c.z80_t + (m1wait ? 1 : 0);  // the acknowledge M1 gets the SVI wait state too
    char got[16];
    if (hand >= 0) snprintf(got, sizeof got, "%ld", hand - ack); else snprintf(got, sizeof got, "never");
    printf("%s\t%d\t%s\t%04X%s\t%s\n", c.name, expT, got, pushed & 0xffff, note, det.c_str());
  }
}

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  if (argc < 2) {
    fprintf(stderr, "usage: %s [--m1wait] [--verbose N] sst FILE.txt... | zex FILE.com [--max-t N] | irq\n", argv[0]);
    return 1;
  }
  cpu = new Cpu;
  bus = new Bus;
  long long maxt = 200000000000LL;
  std::vector<std::string> args;
  for (int i = 1; i < argc; i++) {
    std::string a = argv[i];
    if (a == "--m1wait") m1wait = true;
    else if (a == "--trace") trace = true;
    else if (a == "--inta-hold") inta_hold = true;
    else if (a == "--sst-max-t" && i + 1 < argc) max_t = atol(argv[++i]);
    else if (a == "--verbose" && i + 1 < argc) verbose = atoi(argv[++i]);
    else if (a == "--max-t" && i + 1 < argc) maxt = atoll(argv[++i]);
    else if (a == "--delta" && i + 3 < argc) {  // --delta KIND M1 D
      int k = atoi(argv[i + 1]), m = atoi(argv[i + 2]), d = atoi(argv[i + 3]);
      exp_delta[k][m] = d; i += 3;
    } else args.push_back(a);
  }
  if (args.empty()) return 1;
  if (args[0] == "sst") {
    std::map<std::string, Delta> deltas;
    for (size_t i = 1; i < args.size(); i++) run_sst_file(args[i].c_str(), deltas);
    for (auto &d : deltas) {
      fprintf(stderr, "strobe offset %s:", d.first.c_str());
      for (auto &h : d.second.h) fprintf(stderr, " %+d:%ld", h.first, h.second);
      fprintf(stderr, "\n");
    }
  } else if (args[0] == "zex" && args.size() > 1) {
    return run_zex(args[1].c_str(), maxt);
#ifdef CPU_T80
  } else if (args[0] == "pindump" && args.size() > 3) {
    run_pindump(args[1].c_str(), std::vector<std::string>(args.begin() + 3, args.end()), atoi(args[2].c_str()));
#endif
  } else if (args[0] == "irq") {
    run_irq();
  }
  return 0;
}
