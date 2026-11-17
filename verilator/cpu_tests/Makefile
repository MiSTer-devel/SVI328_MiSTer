# Z80 CPU test bench: t80sv_T80pa (rtl/t80sv, the CPU of the hardware build and the
# simulator) and tv80e (verilator/rtl_sv/tv80, `make tv80` in the simulator).
# See README.md.
#
#   make                 build both benches (obj_t80sv/VT80pa, obj_tv80/Vtv80e)
#   make vectors         download SingleStepTests/z80 + ZEXDOC/ZEXALL into vectors/, convert the JSON
#   make sst             all SingleStepTests on both CPUs -> results/{tv80,t80sv}_sst.tsv
#   make sst-m1wait      same with the SVI-328 M1 wait state -> results/*_sst_m1wait.tsv
#   make irq             interrupt acknowledge timing -> results/*_irq*.tsv
#   make zex             ZEXDOC + ZEXALL on both CPUs (hours; run it in the background) -> results/*_zex*.log
#   make report          results/summary.md from the .tsv files
#   make clean
TV80   = ../rtl_sv/tv80
T80SV  = ../../rtl/t80sv/t80sv_all.sv
PY     = python3 -I

VFLAGS = --cc --exe --build -j 0 --no-timing -Wno-fatal -Wno-lint -Wno-style \
	--x-assign fast --x-initial fast --noassert -O3 -CFLAGS "-O2 -std=c++17"

TV80_SRC = $(TV80)/tv80_alu.v $(TV80)/tv80_core.v $(TV80)/tv80_mcode.v $(TV80)/tv80_reg.v $(TV80)/tv80e.v
TV80_EXE = obj_tv80/Vtv80e
T80_EXE  = obj_t80sv/VT80pa

all: $(TV80_EXE) $(T80_EXE)

$(TV80_EXE): tv80.vlt $(TV80_SRC) sst_main.cpp harness.h cpu_tv80.h
	verilator $(VFLAGS) --Mdir obj_tv80 --top-module tv80e +incdir+$(TV80) -CFLAGS -DCPU_TV80 \
		tv80.vlt $(TV80_SRC) sst_main.cpp

$(T80_EXE): $(T80SV) T80pa_t80sv.sv t80sv.vlt t80sv_regs.h sst_main.cpp harness.h cpu_t80.h
	verilator $(VFLAGS) --Mdir obj_t80sv --top-module T80pa -CFLAGS -DCPU_T80 -CFLAGS -I.. \
		t80sv.vlt $(T80SV) T80pa_t80sv.sv sst_main.cpp

include run.mk

clean:
	rm -rf obj_tv80 obj_t80sv

.PHONY: all clean
