# Test data and run targets (included by Makefile)
SST_REPO = https://github.com/SingleStepTests/z80.git
SST_REV  = ebe1875d48f374bcfd4b505d8eb8ee751568b5f7
ZEX_URL  = https://raw.githubusercontent.com/anotherlin/z80emu/1c418fa0d719abab9273131113defbe276101d95/testfiles
SST_TXT  = vectors/sst_txt

# Strobe position of each core relative to SingleStepTests' convention (T-states, measured
# from the start of the instruction's first M1; same for every instruction): --delta KIND M1 D,
# KIND 0=mem rd 1=mem wr 2=io rd 3=io wr. A strobe elsewhere is reported as "bustime".
TV80_DELTA = --delta 0 1 0 --delta 0 0 0 --delta 1 0 0 --delta 2 0 -1 --delta 3 0 -1
T80_DELTA  = --delta 0 1 -1 --delta 0 0 -1 --delta 1 0 0 --delta 2 0 -1 --delta 3 0 -1

vectors: vectors/sst/v1/00.json vectors/zex/zexall.com $(SST_TXT)/00.txt

vectors/sst/v1/00.json:
	rm -rf vectors/sst
	git clone -q --filter=blob:none --sparse $(SST_REPO) vectors/sst
	cd vectors/sst && git sparse-checkout set v1 && git checkout -q $(SST_REV)

vectors/zex/zexall.com:
	mkdir -p vectors/zex
	cd vectors/zex && for f in zexdoc.com zexall.com zexdoc.z80 zexall.z80; do curl -sfLO $(ZEX_URL)/$$f; done
	cd vectors/zex && shasum -c ../../zex.sha1

$(SST_TXT)/00.txt: vectors/sst/v1/00.json
	$(PY) tools/sst_convert.py vectors/sst/v1 $(SST_TXT)

results:
	mkdir -p results

sst: all results
	./$(TV80_EXE) --verbose 0 $(TV80_DELTA) sst $(SST_TXT)/*.txt > results/tv80_sst.tsv 2> results/tv80_sst.err
	./$(T80_EXE)  --verbose 0 $(T80_DELTA)  sst $(SST_TXT)/*.txt > results/t80_sst.tsv  2> results/t80_sst.err
	$(MAKE) report

sst-m1wait: all results
	./$(TV80_EXE) --verbose 0 --m1wait sst $(SST_TXT)/*.txt > results/tv80_sst_m1wait.tsv 2>/dev/null
	./$(T80_EXE)  --verbose 0 --m1wait sst $(SST_TXT)/*.txt > results/t80_sst_m1wait.tsv  2>/dev/null

# one opcode file, a few failures printed: make sst-one OP=ed_b0
sst-one: all
	./$(TV80_EXE) --verbose 5 $(TV80_DELTA) sst $(SST_TXT)/$(OP).txt
	./$(T80_EXE)  --verbose 5 $(T80_DELTA)  sst $(SST_TXT)/$(OP).txt

irq: all results
	./$(TV80_EXE) irq > results/tv80_irq.tsv; ./$(TV80_EXE) --m1wait irq > results/tv80_irq_m1wait.tsv
	./$(T80_EXE)  irq > results/t80_irq.tsv;  ./$(T80_EXE)  --m1wait irq > results/t80_irq_m1wait.tsv
	cat results/*_irq*.tsv

report:
	$(PY) tools/sst_report.py results/tv80_sst.tsv results/t80_sst.tsv > results/summary.md

# ZEXDOC/ZEXALL: tv80 ~1.5 h each, T80 ~6-7 h each (Verilator, one core each). Copies the
# binaries first so a rebuild does not disturb running jobs.
zex: all results
	mkdir -p results/bin && cp $(TV80_EXE) $(T80_EXE) results/bin/
	for z in zexdoc zexall; do \
		results/bin/Vtv80e zex vectors/zex/$$z.com > results/tv80_$$z.log 2>&1 & \
		results/bin/VT80pa zex vectors/zex/$$z.com > results/t80_$$z.log 2>&1 & \
	done; wait

# GHDL simulation of the original T80 VHDL vs the Verilator netlist, pin by pin (N tests per opcode)
N ?= 25
ghdl/tb_t80: ghdl/tb_t80.vhd gen/T80pa.vhd
	cd ghdl && ghdl -a --std=08 -fsynopsys $(foreach m,$(T80_MOD),../gen/$(m).vhd) tb_t80.vhd && \
		ghdl -e --std=08 -fsynopsys tb_t80

ghdl-check: $(T80_EXE) ghdl/tb_t80 results
	mkdir -p results/ghdl_check
	./$(T80_EXE) pindump results/ghdl_check/tests.txt $(N) $(SST_TXT)/*.txt > results/ghdl_check/netlist_trace.txt
	./ghdl/tb_t80 -gINFILE=results/ghdl_check/tests.txt --ieee-asserts=disable | \
		grep -v '^simulation finished' > results/ghdl_check/ghdl_trace.txt
	cmp results/ghdl_check/netlist_trace.txt results/ghdl_check/ghdl_trace.txt && \
		echo "GHDL simulation and netlist identical on $$(grep -c '^T ' results/ghdl_check/netlist_trace.txt) tests" | \
		tee results/ghdl_check/result.txt
	rm -f results/ghdl_check/*_trace.txt

.PHONY: vectors sst sst-m1wait sst-one irq report zex ghdl-check
