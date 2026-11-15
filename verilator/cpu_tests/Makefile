# Z80 CPU test bench: tv80e (verilator/rtl_sv/tv80, used by the simulator) and
# T80pa (rtl/T80, used by the hardware build, via GHDL --synth -> Verilog).
# See README.md.
#
#   make                 build both benches (obj_tv80/Vtv80e, obj_t80/VT80pa)
#   make vectors         download SingleStepTests/z80 + ZEXDOC/ZEXALL into vectors/, convert the JSON
#   make sst             all SingleStepTests on both CPUs -> results/{tv80,t80}_sst.tsv
#   make sst-m1wait      same with the SVI-328 M1 wait state -> results/*_sst_m1wait.tsv
#   make irq             interrupt acknowledge timing -> results/*_irq*.tsv
#   make zex             ZEXDOC + ZEXALL on both CPUs (hours; run it in the background) -> results/*_zex*.log
#   make report          results/summary.md from the .tsv files
#   make clean
TV80   = ../rtl_sv/tv80
T80    = ../../rtl/T80
PY     = python3 -I

VFLAGS = --cc --exe --build -j 0 --no-timing -Wno-fatal -Wno-lint -Wno-style \
	--x-assign fast --x-initial fast --noassert -O3 -CFLAGS "-O2 -std=c++17"

TV80_SRC = $(TV80)/tv80_alu.v $(TV80)/tv80_core.v $(TV80)/tv80_mcode.v $(TV80)/tv80_reg.v $(TV80)/tv80e.v
TV80_EXE = obj_tv80/Vtv80e
T80_EXE  = obj_t80/VT80pa
T80_MOD  = T80_Reg T80_ALU T80_MCode T80 T80pa

all: $(TV80_EXE) $(T80_EXE)

$(TV80_EXE): tv80.vlt $(TV80_SRC) sst_main.cpp harness.h cpu_tv80.h
	verilator $(VFLAGS) --Mdir obj_tv80 --top-module tv80e +incdir+$(TV80) -CFLAGS -DCPU_TV80 \
		tv80.vlt $(TV80_SRC) sst_main.cpp

# rtl/T80 is copied to gen/ with two edits GHDL needs (Quartus accepts the originals):
#  - "u0 : work.T80" -> "u0 : entity work.T80" (direct entity instantiation needs "entity")
#  - T80.vhd: 'ioq and x"7"' (9-bit and 4-bit operands) -> 'ioq and "000000111"' (zero-extended)
gen/T80pa.vhd: $(foreach m,$(T80_MOD),$(T80)/$(m).vhd)
	mkdir -p gen
	for f in $(T80_MOD); do sed -E 's/: work\.(T80[A-Za-z_]*)/: entity work.\1/' $(T80)/$$f.vhd > gen/$$f.vhd; done
	sed 's/ioq := (ioq and x"7") xor/ioq := (ioq and "000000111") xor/' $(T80)/T80.vhd | \
		sed -E 's/: work\.(T80[A-Za-z_]*)/: entity work.\1/' > gen/T80.vhd
	grep -q 'ioq and "000000111"' gen/T80.vhd

gen/t80pa_synth.v: gen/T80pa.vhd
	cd gen && ghdl --synth --std=08 -fsynopsys --out=verilog -gMode=0 \
		$(foreach m,$(T80_MOD),$(m).vhd) -e T80pa > t80pa_synth.v.raw 2> synth.log
	awk '/^module /{m=$$2} {print} m ~ /^t80_[0-9]/ && $$0 == "  wire [7:0] di_reg;" {print "  assign di_reg = di; // T80.vhd:1045 DI_Reg <= DI (dropped by ghdl --synth)"; n++} \
		END{if (n != 1) exit 1}' gen/t80pa_synth.v.raw > gen/t80pa_synth.v.tmp
	verilator --lint-only -Wall +1364-2005ext+v --top-module T80pa gen/t80pa_synth.v.tmp 2>&1 | \
		grep -A1 UNDRIVEN && exit 1 || true
	mv gen/t80pa_synth.v.tmp gen/t80pa_synth.v

# WZ is not in the DIR/REG ports: find the netlist register behind the "wz" signal
gen/t80_wz.h: gen/t80pa_synth.v
	mod=$$(grep -o '^module t80_[0-9_]*' gen/t80pa_synth.v | head -1 | cut -d' ' -f2); \
	reg=$$(grep -E '^  assign wz = n[0-9]+;' gen/t80pa_synth.v | head -1 | sed -E 's/.*= (n[0-9]+);.*/\1/'); \
	test -n "$$reg" -a -n "$$mod" || { echo "wz register not found"; exit 1; }; \
	echo "#define T80_WZ(top) top->rootp->T80pa__DOT__u0__DOT__$$reg" > gen/t80_wz.h; \
	printf '`verilator_config\npublic_flat_rw -module "%s" -var "%s"\n' $$mod $$reg > gen/t80.vlt

$(T80_EXE): gen/t80pa_synth.v gen/t80_wz.h sst_main.cpp harness.h cpu_t80.h
	verilator $(VFLAGS) --Mdir obj_t80 --top-module T80pa +1364-2005ext+v -CFLAGS -DCPU_T80 -CFLAGS -I../gen \
		gen/t80.vlt gen/t80pa_synth.v sst_main.cpp

include run.mk

clean:
	rm -rf obj_tv80 obj_t80 gen

.PHONY: all clean
