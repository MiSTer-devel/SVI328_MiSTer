# Z80 CPU tests: tv80 vs T80, and t80sv

**Update 2026-11-17: the hardware build and the simulator both use t80sv now** (`../../rtl/t80sv`,
`t80sv_T80pa`, a SystemVerilog translation of T80 0250 by Rodimus, patched here to pass every
SingleStepTests case; `rtl/t80sv/README.md`). `rtl/T80` (T80 0247) was removed; the bench's T80
slot is now t80sv, built straight from the SystemVerilog (no GHDL step), and also checks Q.
Results in `results/t80sv/`:

- SingleStepTests: **1,604,000 / 1,604,000** pass, every field including WZ, Q, flag bits 5/3,
  bus cycle order and strobe positions (`t80sv_summary.md`).
- Interrupt acknowledge timing: exact in every case, with and without the M1 wait state
  (`t80sv_irq*.tsv`), the same as T80.
- With the M1 wait state (`t80sv_sst_m1wait.tsv`): only `EI` (FB, DD FB, FD FB) differs, in
  IFF1/IFF2 at the bench's sample point: T80 sets them in T2 of the next fetch and the wait state
  moves T2 later. The original T80 does the same, and an interrupt pending before `EI` is still
  taken after the next instruction (the irq case "INT low before EI" is exact).
- ZEXDOC / ZEXALL: 67 / 67 each (`t80sv_zexdoc.log`, `t80sv_zexall.log`).

The sections below are the earlier tv80 vs T80 0247 study; its T80 numbers (`results/t80_*`)
come from the removed `rtl/T80` through GHDL (see git history before this change for that
Makefile and `ghdl/tb_t80.vhd`). New runs write to `results/latest/` (git-ignored).

Question: is tv80 (`../rtl_sv/tv80`, the CPU of the Verilator simulator, copied from
ColecoAdam_MiSTer where it runs on hardware) correct enough to replace T80 (`../../rtl/T80`,
`T80pa` with `Mode => 0` in `rtl/cv_console.vhd`, what the hardware build uses) in the SVI-328
core? Both are tested against the same suites through the same C++ bench:

- **SingleStepTests/z80**: 1604 opcodes x 1000 tests (registers, RAM, bus cycles, T-states)
- **ZEXDOC / ZEXALL** under a small CP/M BDOS stub
- **interrupt acknowledge** timing (IM 0/1/2, NMI, from HALT, EI delay)
- the same with the **SVI-328 M1 wait state** (`--m1wait`)

The original comparison (results/, sections below up to "Shared bugs") was made on unmodified
cores. **tv80 has since been fixed** in `../rtl_sv/tv80` (2026-11-15): see
[tv80 fixes](#tv80-fixes-2026-11-15); `tv80_fixes.patch` is the diff against ColecoAdam_MiSTer's
`rtl/tv80`, and `results/fix/` holds the reruns. Line numbers in the older sections refer to the
unmodified files.

## Recommendation (short)

*Update 2026-11-15:* after the fixes below, tv80 passes every documented-behaviour test
(1,589,074 of 1,604,000 SingleStepTests pass in all; T80 1,544,679), every interrupt timing case
exactly, and ZEXDOC/ZEXALL 67/67. T80 still stays in the SVI hardware build: it was already correct, and tv80's one-T-state
bus strobes would need hardware testing against the SVI glue logic for no gain. The fixed tv80 is
what the simulator runs, and the patch is worth offering to ColecoAdam_MiSTer.

Original recommendation, on the unmodified cores:

**T80 is the more correct CPU and should stay in the hardware build.** It passes every
documented-behaviour check except bugs that tv80 shares with it, all T-state counts are exact,
and its pins follow the Z80 datasheet to the half T-state.

**tv80 is usable for SVI software that sticks to documented instructions, but it is not a drop-in
improvement over T80.** It has two documented-flag bugs that T80 doesn't have (DAA P/V, and S/Z
after `LD A,R`), it derails on all 448 undocumented `DD CB`/`FD CB` register-copy opcodes (it never
issues another M1), its NMI and IM 2 acknowledges are 4 and 2 T-states too long, and its bus
strobes are one T-state wide instead of the Z80 shapes the SVI glue logic was written for. For
the SVI-specific concerns (tape loading counts loop iterations; the BIOS uses IM 1 only, see
below) both cores give identical, exact timing, M1 wait state included. The only thing tv80
does better is IM 2 with a vector that a device drives only during IORQ (T80pa latches it too
late), which nothing on the SVI uses; so there is no reason to switch. tv80's real advantage is
simulation speed (7 M T-states/s in Verilator against 1.9 M for the T80 netlist). If the
simulator should match the hardware, use T80 there too (`gen/t80pa_synth.v`, see below), or fix
the tv80 bugs listed in [tv80 bugs](#tv80-bugs-not-in-t80) first.

## Build and run

Needs Verilator 5 (built with 5.044), python3, git, curl. (GHDL was needed only for the removed T80 netlist.)

    make vectors        # SingleStepTests (git, 1.3 GB JSON) + ZEXDOC/ZEXALL into vectors/, JSON -> vectors/sst_txt
    make                # obj_tv80/Vtv80e and obj_t80sv/VT80pa
    make sst            # all 1.6M tests on both CPUs (about 15 s each) -> results/latest/{tv80,t80sv}_sst.tsv, summary.md
    make sst-one OP=ed_b0   # one opcode file, first failures printed
    make sst-m1wait     # with the SVI M1 wait state -> results/latest/*_sst_m1wait.tsv
    make irq            # interrupt acknowledge timing -> results/latest/*_irq*.tsv
    make zex            # ZEXDOC+ZEXALL on both CPUs, 4 jobs in parallel; hours (see below)

The bench binaries take `sst FILE.txt...`, `zex FILE.com [--max-t N]`, `irq`, and
`--m1wait`, `--verbose N` (failing tests printed per file), `--trace` (pins per T-state),
`--inta-hold` (irq: device keeps the vector on the bus for the whole acknowledge M1).

Downloaded data lives in `vectors/` (ignored by git). Sources:

| data | source | version / sha1 |
|---|---|---|
| SingleStepTests/z80 v1 | https://github.com/SingleStepTests/z80 | commit ebe1875d48f374bcfd4b505d8eb8ee751568b5f7 |
| zexdoc.com | https://github.com/anotherlin/z80emu `testfiles/` | 2b91e88db9460567e23c1bc2b9903b6cd004ceae |
| zexall.com | same | 1dbdf5c84c262e83cafacd26db787fba68b9605d |
| zexdoc.z80 / zexall.z80 (source) | same | 437e8ce51ac85bf1dc225e26967d63ece8fe13ca / 592ccdc459ee3ddbe93cd687fe7f41ad8a76b453 |

(`zex.sha1`, checked by `make vectors`.) The JSON is only parsed (`tools/sst_convert.py`); the
ZEX programs run only inside the simulated CPU.

## How the bench works

Files: `sst_main.cpp` (test runner, CP/M stub, interrupt cases), `harness.h` (flat 64 KB memory,
I/O ports, bus-cycle recorder, SVI M1 wait circuit), `cpu_tv80.h` / `cpu_t80.h` (one adapter
per core), `tools/sst_convert.py` (JSON -> text), `tools/sst_report.py` (Markdown tables).

**Clocking.** tv80e: one `clk` with `cen=1` is one T-state, as in `svi_console.sv`. T80pa: one T-state
is one `CLK` with `CEN_p` then one with `CEN_n`, as `clk_en_3m58_p/_n` on hardware; pins are
sampled after each half. `WAIT_n=1` unless `--m1wait`, which models the two 74LS74s of
`cv_console.vhd` (`m1_wait_q` toggling on each `CEN_p` while `M1_n` is low): one wait per M1.

**Loading a test.** Reset, then: tv80 registers are written through Verilator `public_flat_rw`
(`tv80.vlt`: ACC, F, A'F', I, R, SP, PC, the address register, the register file, IFF1/2, IM,
TmpAddr). T80 is loaded with its own `DIRSet`/`DIR` port (made for save states), plus WZ, which
is not in DIR: the bench writes the netlist register behind the `wz` signal (`gen/t80_wz.h`,
found by the Makefile). The first `CEN_p` edge after reset ends T80's reset state and executes
`SetWZ` of the dummy IR=00, so WZ is written again after that edge.

**Ending a test.** Memory not listed in the test reads 00 (NOP). The instruction ends at the
(n+1)-th M1, n = number of opcode M1 cycles from the file name (1, 2 for CB/ED/DD/FD, 2 for
DD CB d op). Final **PC = address of that M1**, **R and I = refresh address of that M1** (so
both are what the pins show, not an internal register), other registers are read after
T3 of that fetch. T-states = distance between the first and the (n+1)-th M1.

**Compared:** A, F (split into documented flags and bits 5/3), B C D E H L, IX IY SP PC, AF' BC'
DE' HL', I, R, IFF1, IFF2, IM, WZ (T80 only), RAM, T-states, the ordered list of bus cycles
(memory/I/O, read/write, address, data), I/O writes, and the T-state of every strobe.

**Not compared:** `ei`, `p`, `q` (internal latches no core exposes; Q is what SCF/CCF X/Y flags
depend on, P the `LD A,I/R` interrupt quirk). **WZ (MEMPTR) for tv80**: tv80 has no MEMPTR,
`TmpAddr` is a scratch register, so its WZ is not compared; its effect shows up as wrong flag
bits 5/3 after `BIT n,(HL)`.

**Documented vs undocumented.** A test is a *documented-behaviour* failure when anything other
than flag bits 5/3, WZ, or strobe position is wrong, using the flags the Zilog manual defines for
the instruction: all of S Z H P/V N C, except `BIT` (Z H N C only; S and P/V "unknown") and
INI/IND/OUTI/OUTD and repeats (Z only: the manual says "N set, C unaffected", real silicon puts
data bit 7 in N and changes C/H/P/V, which is what the tests expect). Opcodes are also
split into official and undocumented (SLL, DD/FD on non-HL instructions and IXH/IXL, ED
duplicates and holes, DD CB register-copy forms).

**Strobe convention.** SingleStepTests show every strobe as a one-sample pulse; each core puts
its strobes at a fixed offset from that (tv80: memory 0, I/O -1; T80: memory read -1, write 0,
I/O -1 T-states, `run.mk`). A strobe anywhere else is a `bustime` failure.

### T80 via GHDL --synth

`ghdl --synth --out=verilog` works on rtl/T80 after two source edits in a copy (`gen/`; Quartus
accepts the originals): `u0 : work.T80` -> `u0 : entity work.T80` (direct entity instantiation
needs `entity`), and in T80.vhd `ioq and x"7"` (9-bit and 4-bit operands) -> `ioq and "000000111"`.

GHDL 5.1.1 has a synthesis bug on this design: **the concurrent `DI_Reg <= DI;` of T80.vhd:1045
is dropped**, leaving `di_reg` undriven in the core module (`verilator --lint-only -Wall` reports
UNDRIVEN; iverilog shows Z). Every non-M1 memory read then returned garbage. The Makefile adds
`assign di_reg = di;` back and fails if any UNDRIVEN signal remains.

The patched netlist was then checked against a **GHDL simulation of the VHDL** (`ghdl/tb_t80.vhd`
drives T80pa exactly like `cpu_t80.h` and prints the same pin trace: address, write data and all
strobes after every `CLK` edge, plus `REG` at the end): **identical on 320,800 tests** (200 per
opcode file, `make ghdl-check N=200`). The T80 results below are therefore the VHDL's.

GHDL simulation runs about 50k T-states/s here (Verilator netlist: 1.9 M/s; tv80: 7 M/s).
SingleStepTests in GHDL would be practical (about 15 minutes), ZEXALL would not (about 10 days).

## SingleStepTests results

Full per-opcode lists with an example per failing field: `results/summary.md`.

### tv80

| group | opcodes | tests | pass | fail (documented behaviour) | fail (undocumented flags/WZ/strobe timing only) |
|---|---|---|---|---|---|
| base (official) | 252 | 252000 | 250064 | 1488 | 448 |
| CB (official) | 248 | 248000 | 241966 | 0 | 6034 |
| CB (undocumented opcodes) | 8 | 8000 | 8000 | 0 | 0 |
| ED (official) | 56 | 56000 | 34784 | 1477 | 19739 |
| ED (undocumented opcodes) | 24 | 24000 | 21935 | 1313 | 752 |
| DD (official) | 39 | 39000 | 38000 | 1000 | 0 |
| DD (undocumented opcodes) | 213 | 213000 | 209626 | 2480 | 894 |
| FD (official) | 39 | 39000 | 38000 | 1000 | 0 |
| FD (undocumented opcodes) | 213 | 213000 | 209683 | 2449 | 868 |
| DDCB (official) | 32 | 32000 | 26044 | 0 | 5956 |
| DDCB (undocumented opcodes) | 224 | 224000 | 0 | 224000 | 0 |
| FDCB (official) | 32 | 32000 | 26037 | 0 | 5963 |
| FDCB (undocumented opcodes) | 224 | 224000 | 0 | 224000 | 0 |
| **all** | 1604 | 1604000 | 1104139 | 459207 | 40654 |

### T80 (T80pa, Mode 0)

| group | opcodes | tests | pass | fail (documented behaviour) | fail (undocumented flags/WZ/strobe timing only) |
|---|---|---|---|---|---|
| base (official) | 252 | 252000 | 240606 | 1000 | 10394 |
| CB (official) | 248 | 248000 | 248000 | 0 | 0 |
| CB (undocumented opcodes) | 8 | 8000 | 8000 | 0 | 0 |
| ED (official) | 56 | 56000 | 39048 | 0 | 16952 |
| ED (undocumented opcodes) | 24 | 24000 | 20687 | 1313 | 2000 |
| DD (official) | 39 | 39000 | 36000 | 1000 | 2000 |
| DD (undocumented opcodes) | 213 | 213000 | 202175 | 2000 | 8825 |
| FD (official) | 39 | 39000 | 36000 | 1000 | 2000 |
| FD (undocumented opcodes) | 213 | 213000 | 202163 | 2000 | 8837 |
| DDCB (official) | 32 | 32000 | 32000 | 0 | 0 |
| DDCB (undocumented opcodes) | 224 | 224000 | 224000 | 0 | 0 |
| FDCB (official) | 32 | 32000 | 32000 | 0 | 0 |
| FDCB (undocumented opcodes) | 224 | 224000 | 224000 | 0 | 0 |
| **all** | 1604 | 1604000 | 1544679 | 8313 | 51008 |

(T80's undocumented-only count is higher than tv80's only because WZ is compared for T80 and
not for tv80.)

R and I: no failures on either core, including all prefixed instructions (R is checked on the
refresh address bus). IFF1/IFF2: no failures. RAM contents: no failures except as a consequence
of the tv80 DD CB lock-up.

### Failure categories, documented behaviour

| # | instruction | tv80 | T80 | what happens | example (test: expected / got) |
|---|---|---|---|---|---|
| 1 | `DAA` (27, also DD/FD 27) | 488/1000 fail | ok | P/V is the parity of the 9-bit intermediate, carry bit included | `27_0000`: A=F3 F=4E -> F exp 87 got 83 (P/V) |
| 2 | `LD A,R` (ED 5F) | 477/1000 fail | ok | S and Z are taken from I instead of R | `ED_5F_0001`: F exp 0C got 8C (S) |
| 3 | `DD CB d op` / `FD CB d op`, op&7 != 6 (448 undocumented register-copy forms, incl. BIT aliases) | all fail | ok | after the d/op reads the CPU never asserts M1 again; it keeps reading memory without M1 or refresh for as long as it runs (checked 20,000 T) | `DD_CB____00_0000`: no next M1 |
| 4 | `RRD` (ED 67) | all fail (bus only) | ok | an extra memory read of PC (the byte after the instruction) before reading (HL); registers, RAM, 18 T-states correct | `ED_67_0000`: exp `MR:098F MW:098F`, got `MR:F93A MR:098F MW:098F` |
| 5 | `EX (SP),HL/IX/IY` (E3, DD/FD E3) | all fail (bus only) | all fail (bus only) | cycle order read L, write L, read H, write H instead of read, read, write H, write L; RAM and timing correct | `E3_0000`: exp `MR:6CFD MR:6CFE MW:6CFE MW:6CFD`, got `MR:6CFD MW:6CFD MR:6CFE MW:6CFE` |
| 6 | `DD/FD 13`, `DD/FD 1B` (INC/DEC DE with an ignored prefix) | all fail | all fail | increments/decrements BC instead of DE (the 16-bit inc/dec register select falls through to the prefix path) | `DD_13_0000`: C exp E4 got E5, E exp 66 got 65 |
| 7 | `ED 77`, `ED 7F` (undocumented NOPs) / `ED 7E` (undocumented IM 2) | fail | fail | ED 77/7F change IM, ED 7E does not set IM 2 | `ED_77_0000`: IM exp 1 got 2; `ED_7E_0002`: IM exp 2 got 1 |

Category 3 does not depend on how the bench loads state: from reset, the program
`LD IX,1000h; RLC (IX+0),B (DD CB 00 00); LD C,9; LD DE,msg; CALL 5; JP 0` prints its message on
T80 and nothing on tv80 (200,000 T-states); with `DD CB 00 06` (`RLC (IX+0)`) tv80 prints it too.

Categories 5-7 are shared (tv80 is a translation of T80). Category 6 is in tv80_core.v:964-967
and T80.vhd:860-864 (`RegAddrA` only redirects HL to IX/IY; for DE with XY_State set it falls
to `RegAddrA_r`, which addresses BC). Category 1 is tv80_alu.v:277 `F_Out[Flag_P] = ~(^DAA_Q);`
with `DAA_Q` 9 bits wide (T80_ALU.vhd:264 uses bits 7..0). Category 2 is tv80_core.v:785-786
(`F[Flag_Z] <= (I == 0); F[Flag_S] <= I[7];` in the `LD A,R` branch, copied from `LD A,I`).

### Failure categories, undocumented flags / WZ / strobe position only

| category | tv80 | T80 |
|---|---|---|
| bits 5/3 after `SCF`/`CCF` (needs Q) | 37, 3F, DD/FD 37/3F (~22% of tests) | same |
| bits 5/3 after `BIT n,(HL)`, `BIT n,(IX+d)` (need WZ) | all 24 opcodes, ~75% of tests | ok |
| bits 5/3 after `IN r,(C)` / `IN F,(C)`, `LD A,I`, `LD A,R`, `CPI`, `CPD` | wrong (~75% of tests) | ok |
| bits 5/3 when `LDIR/LDDR/CPIR/CPDR/INIR/...` repeat (PC-based X/Y, found in 2018) | wrong | wrong (~75% of repeating tests) |
| N/H/P/V/C of INI/IND/OUTI/OUTD and repeats (silicon behaviour) | wrong (~94% of tests) | ok, except repeats |
| WZ (MEMPTR) | not modelled | wrong after `LD A,(BC)/(DE)/(nn)` (not set), `LD (nn),rr` / `LD rr,(nn)` (nn instead of nn+1), `RET` / taken `RET cc` (high byte), `RRD/RLD`, `CPI/CPD` (off by one), `CPIR`/block I/O repeats, 4/1000 `OUT (n),A` |
| strobe position | INI/IND/INIR/INDR: I/O read 1 T early and memory write 1 T early (same 16/21 T total); RLD: (HL) read 3 T late (18 T total) | none |

## Timing

**T-states per instruction: exact on both cores for every one of the 1604 opcodes** (all 1000
tests each), except tv80's 448 locked-up DD/FD CB register-copy forms. With `--m1wait` both take
exactly one extra T-state per M1 cycle on every test (SVI-328 hardware timing; tv80 lock-ups excluded), so loop counts in
the SVI BIOS tape routines come out the same on both.

**Pin timing** (`--trace`, and `VT80pa pindump` for half T-states; Z80 datasheet in brackets):

| cycle | T80pa (half-T resolution) | tv80e (changes only on the cen edge) |
|---|---|---|
| M1 fetch | M1 T1-T2, MREQ+RD from T1 falling to T3 rising, refresh MREQ T3 falling to T4 falling, RFSH T3-T4 [same] | M1 T1-T2, MREQ+RD during T2 only, refresh MREQ during T3 only, RFSH T3-T4 |
| memory read | MREQ+RD T1 falling to T3 falling [same] | MREQ+RD during T2 only |
| memory write | MREQ T1 falling to T3 falling, WR T2 falling to T3 falling [same] | MREQ+WR during T2 only, data only while WR is low |
| I/O read/write | IORQ+RD/WR from T2 rising to T3 falling, TW inserted [same] | IORQ+RD/WR during T2 and TW |
| data latched | memory read at mid-T3, opcode at start of T3 [T3 rising / T3 falling] | end of T2 (the T3 edge) |

T80pa reproduces the datasheet. tv80e's strobes are one T-state long (two for I/O) and start a
half T-state late, with no address setup before MREQ; the SVI glue (cv_console/svi_mapper/SDRAM
at 42.954545 MHz, 12 clk_sys per T-state) was built and tested with T80pa's shapes. tv80 runs on
hardware in ColecoAdam_MiSTer, so the shapes can work, but a switch on the SVI core would have to
be checked on hardware (the simulator's SDRAM has no latency and cannot show this).

**Interrupt acknowledge** (`results/*_irq.tsv`, T-states from the start of the acknowledge M1 to
the first M1 of the handler; `--m1wait` adds exactly one to every case on both cores):

| case | Z80 | tv80 | T80 |
|---|---|---|---|
| IM 1 | 13 | 13 | 13 |
| IM 0, RST 38h on the bus | 13 | 13 | 13 |
| IM 2 | 19 | **21** | **wrong handler** (see below) |
| NMI | 11 | **15** | 11 |
| IM 1 / IM 2 out of HALT (pushed PC = HALT+1) | ok | ok | ok |
| INT already low before `EI; NOP` (taken after the NOP) | ok | ok | ok |

- tv80 NMI: the acknowledge M1 is 7 T and the stack writes 4 T each (`MW 7FFF@T9, MW 7FFE@T13`;
  T80, which matches the Z80's 5+3+3: `MW 7FFF@T7, MW 7FFE@T10`). tv80 IM 2: the second stack write is 4 T after the first and the table reads follow
  (`MW@T9, MW@T13, MR 80FE@T17, MR 80FF@T20`).
- T80pa IM 2: the vector is latched into WZ from `DI_Reg`, which T80pa captures at mid-T3 of
  the acknowledge M1 (T80pa.vhd:177; WZ(7:0) <= DI_Reg at T80.vhd:670-671), after IORQ_n and M1_n have gone high and the address
  bus shows the refresh address. With a device that drives the vector only during IORQ+M1, the
  table is read from (I, 00h) instead of (I, vector) (`MR 8000@T14` instead of `80FE`); this is
  the same with `--inta-hold` (vector held for the whole M1), because M1 has also ended. A real
  Z80 samples the vector at the start of T3. **The SVI-328 BIOS uses IM 1 only** (`ED 56` twice,
  no `ED 5E` in `software/mister11/boot.rom`), and nothing on the SVI drives a vector, so this
  does not affect the core.
- T80pa does not reset `IntCycleD_n`; after power-up (registers at 0) IORQ_n is low during the
  first M1, which looks like an interrupt acknowledge to an external decoder. After any later reset
  it is "11". The bench runs a few NOPs once at start-up to get past it.

## ZEXDOC / ZEXALL

`zex FILE.com`: program at 0100h, `JP FE00h` at 0005h (also SP = FE00h), a BDOS stub at FE00h
that does functions 2 and 9 with `OUT (1),A` (the bench prints port 1 writes), `HALT` at 0000h;
the run ends at the fetch from 0000h. The stub runs on the CPU under test, so no internal state
is needed.

Results (`results/{tv80,t80}_{zexdoc,zexall}.log`; 46.7 billion T-states per run):

| | ZEXDOC (documented flags) | ZEXALL (all flags) | wall time |
|---|---|---|---|
| tv80 | 66/67 OK; `<daa,cpl,scf,ccf>` ERROR (crc expected 9b4ba675, found d623e49e) | 64/67 OK; `<daa,cpl,scf,ccf>` ERROR (6d2dd213 / 204590f8), `cpd<r>` ERROR (134b622d / d0ecd9bb), `cpi<r>` ERROR (2da42d19 / f7644b3b) | 1 h 40 min |
| T80 | **67/67 OK** | **67/67 OK** | 7 h 08 min |

The tv80 failures are the ones SingleStepTests found: `<daa,...>` in ZEXDOC is the DAA P/V bug
(category 1; documented flag), `cpi<r>`/`cpd<r>` in ZEXALL are flag bits 5/3 of CPI/CPD/CPIR/CPDR
(undocumented). ZEXALL does not exercise WZ or Q, so T80's WZ gaps and SCF/CCF X/Y do not show here.
ZEXALL under GHDL simulation of the VHDL would take about 10 days (50k T-states/s); the
Verilator netlist was used instead, after the pin-by-pin check against GHDL above.

## tv80 bugs not in T80

1. `DAA`: P/V includes the carry bit (tv80_alu.v:277). Documented behaviour, 49% of DAA tests.
2. `LD A,R`: S and Z from I (tv80_core.v:785-786). Documented behaviour.
3. `DD CB d op` / `FD CB d op` with op&7 != 6: CPU stops issuing M1 cycles and never recovers.
   Undocumented opcodes, but the failure is a lock-up, not a wrong result.
4. `RRD`: extra read of the byte after the instruction.
   (ZEXDOC: `<daa,cpl,scf,ccf>` fails from item 1; ZEXALL also fails `cpi<r>`/`cpd<r>`.)
5. NMI acknowledge 15 T (11), IM 2 acknowledge 21 T (19).
6. No MEMPTR: bits 5/3 after `BIT n,(HL)`; wrong bits 5/3 and block-I/O flags in many places
   where T80 is right.
7. One-T-state bus strobes (see Timing).

## Shared bugs (tv80 and T80)

1. `DD/FD 13`, `DD/FD 1B` change BC instead of DE.
2. `EX (SP),HL/IX/IY` bus cycle order (result correct).
3. `ED 77/7F` change IM, `ED 7E` doesn't select IM 2.
4. Bits 5/3 after `SCF/CCF` (no Q) and in repeating block instructions.

T80 only: WZ is incomplete (see above), IM 2 vector latched late, `IntCycleD_n` not reset.

## tv80 fixes (2026-11-15)

Made in `../rtl_sv/tv80` (the simulator's copy; ColecoAdam_MiSTer is not touched). Every change
was checked against the Zilog Z80 CPU User Manual (UM0080, `refs/docs/chips/Zilog_Z80_UM0080.*`)
or, for undocumented behaviour, Sean Young's *The Undocumented Z80 Documented* v0.6
(`refs/docs/chips/z80_undoc/`), and against T80 where T80 was already right; then against
SingleStepTests, the interrupt cases, and ZEXDOC/ZEXALL. Patch: `tv80_fixes.patch`
(3 files, about 220 lines added, 80 removed).

| # | Bug | Fix | Reference |
|---|---|---|---|
| 1 | DAA P/V counted the carry bit | parity of `DAA_Q[7:0]` | UM0080 DAA |
| 2 | LD A,R took S/Z from I | S/Z (and bits 5/3) from R; LD A,I also sets bits 5/3 | UM0080 LD A,R; Young |
| 3 | DD/FD 13 and 1B changed BC | a DD/FD prefix only redirects HL in 16-bit INC/DEC | Young 3.2 (prefix ignored) |
| 4 | ED 77 set IM 2, ED 7E did not | IM 2 decode is ED 5E/7E; ED 77 is a NOP | Young 3.4 |
| 5 | 448 DD CB / FD CB register-copy opcodes locked up | T80's scheme: new mcode input `XY_State`, output `XYbit_undoc`; operand from (IX+d), result to (IX+d) and the register; BIT b,(IX+d) takes bits 5/3 from IX+d (held in TmpAddr) | Young 3.5, 4.1 |
| 6 | RLD/RRD bus order (RRD read the byte after the instruction) | Sorgelig's T80 fix: MR (HL) in M2, internal M3, MW in M4, `I_RXDD` keeps the data | UM0080 RLD/RRD timing |
| 7 | EX (SP),HL/IX/IY wrote before reading the second byte (T80 too) | MR SP, MR SP+1, MW SP+1, MW SP; (SP) is held in TmpAddr[7:0] and written to L at the end (new mcode output `Save_TmpL`) | UM0080 EX (SP),HL; SingleStepTests bus order |
| 8 | NMI acknowledge 15 T, IM 2 21 T | stack writes 3 T (as T80); no automatic waits in the NMI M1 (only INT has IORQ) | UM0080 interrupt timing |
| 9 | CPI/CPD bits 5/3 (ZEXALL `cpi<r>`/`cpd<r>`) | n = A - (HL) - H, bits 3 and 1 (as T80) | Young 4.2 |
| 10 | IN r,(C) bits 5/3 | copies of the byte read (as T80) | Young |
| 11 | INI/IND/OUTI/OUTD flags and strobe timing | T80's microcode (4/5/4/3 and 4/5/3/4 T) and its N/H/C/P formula | Young 4.3 |

Results with the fixes (`results/fix/`):

| | SingleStepTests pass | documented-behaviour failures | undocumented only | interrupt cases |
|---|---|---|---|---|
| tv80 before | 1,104,139 | 459,207 | 40,654 | NMI 15 T, IM 2 21 T |
| **tv80 fixed** | **1,589,074** | **0** | 14,926 | all exact, with and without `--m1wait` |
| T80 | 1,544,679 | 8,313 | 51,008 | IM 2 reads the wrong table entry |

With `--m1wait` the fixed tv80 gives the same 1,589,074. **ZEXDOC 67/67 and ZEXALL 67/67 OK** on
the fixed core (`results/fix/tv80_zex{doc,all}.log`, 46.7 billion T-states each), the same as T80.

What is left (all undocumented flag bits 5/3, which ZEXDOC does not check):
- `BIT n,(HL)` (CB 46..7E): needs MEMPTR (WZ), which tv80 doesn't have.
- `SCF`/`CCF` (and with a DD/FD prefix): need the Q register.
- Repeating block instructions while they repeat (LDIR/LDDR/CPIR/CPDR/INIR/INDR/OTIR/OTDR):
  bits 5/3 (and for the I/O ones H and P) come from PC; found after Young's document. T80 fails
  these too.

Also checked: the simulator (BASIC boot, Disk BASIC `FILES`, CP/M 2.24 at 80 columns, `CLOAD` of
Three Wall Smash and Treasure Chest), Verilator `-Wall` lint (one new SYNCASYNCNET note of the
kind the original already has), and Quartus 17.0 Analysis & Synthesis of `tv80e` alone for
Cyclone V (0 errors, no latches, only warnings already present in the original code).

