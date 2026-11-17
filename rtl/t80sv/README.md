# t80sv (Z80 CPU)

`t80sv_all.sv` is t80sv by Rodimus: a SystemVerilog translation of the T80 Z80 core (T80 0250,
MiSTer-devel lineage), cycle-identical to the VHDL, with drop-in tops that keep the VHDL ports.
The SVI core uses `t80sv_T80pa` with `Mode => 0` (`rtl/cv_console.vhd`, and the simulator's
`verilator/rtl_sv/svi_console.sv`), driven by `CEN_p` / `CEN_n` exactly as T80pa was.

The file has four fixes on top of the version received from the author (2026-11-17);
`t80sv_fixes.patch` is the diff against it. The same fixes were made in the VHDL T80 0250 and
sent back to the author with the test bench.

1. `DD/FD INC DE`, `DEC DE`: changed BC instead of DE.
2. Q register: flag bits 5 / 3 after `SCF` / `CCF`.
3. MEMPTR (WZ) for about 60 opcodes (`LD A,(rr)`, `LD A,(nn)`, `LD (nn),rr`, `RET`,
   `OUT (n),A`, `RLD` / `RRD`, `CPI` / `CPD`).
4. Repeating block instructions: flag bits 5 / 3 from PC, H and P/V of `INIR` / `OTIR` /
   `INDR` / `OTDR`.

With them it passes all 1,604,000 SingleStepTests/z80 cases (registers, WZ, Q, flags, memory,
I/O, T-states, bus cycle order, strobe positions), every interrupt acknowledge timing case with
and without the SVI M1 wait state, and ZEXDOC / ZEXALL (`verilator/cpu_tests`,
`results/t80sv/`). Fixes 2 and 4 are gated to Z80 modes; 8080 and GB modes are unchanged.

License: T80's BSD-style terms (Daniel Wallner and the other T80 authors) and Rodimus, in
`LICENSE` and at the top of `t80sv_all.sv`.
