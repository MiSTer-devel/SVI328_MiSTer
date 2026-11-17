# Test data and run targets (included by Makefile)
SST_REPO = https://github.com/SingleStepTests/z80.git
SST_REV  = ebe1875d48f374bcfd4b505d8eb8ee751568b5f7
ZEX_URL  = https://raw.githubusercontent.com/anotherlin/z80emu/1c418fa0d719abab9273131113defbe276101d95/testfiles
SST_TXT  = vectors/sst_txt
# outputs (git-ignored; the committed results are in results/, results/fix/, results/t80sv/)
RES     ?= results/latest

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

$(RES):
	mkdir -p $(RES)

sst: all $(RES)
	./$(TV80_EXE) --verbose 0 $(TV80_DELTA) sst $(SST_TXT)/*.txt > $(RES)/tv80_sst.tsv 2> $(RES)/tv80_sst.err
	./$(T80_EXE)  --verbose 0 $(T80_DELTA)  sst $(SST_TXT)/*.txt > $(RES)/t80sv_sst.tsv  2> $(RES)/t80sv_sst.err
	$(MAKE) report

sst-m1wait: all $(RES)
	./$(TV80_EXE) --verbose 0 $(TV80_DELTA) --m1wait sst $(SST_TXT)/*.txt > $(RES)/tv80_sst_m1wait.tsv 2>/dev/null
	./$(T80_EXE)  --verbose 0 $(T80_DELTA) --m1wait sst $(SST_TXT)/*.txt > $(RES)/t80sv_sst_m1wait.tsv  2>/dev/null

# one opcode file, a few failures printed: make sst-one OP=ed_b0
sst-one: all
	./$(TV80_EXE) --verbose 5 $(TV80_DELTA) sst $(SST_TXT)/$(OP).txt
	./$(T80_EXE)  --verbose 5 $(T80_DELTA)  sst $(SST_TXT)/$(OP).txt

irq: all $(RES)
	./$(TV80_EXE) irq > $(RES)/tv80_irq.tsv; ./$(TV80_EXE) --m1wait irq > $(RES)/tv80_irq_m1wait.tsv
	./$(T80_EXE)  irq > $(RES)/t80sv_irq.tsv;  ./$(T80_EXE)  --m1wait irq > $(RES)/t80sv_irq_m1wait.tsv
	cat $(RES)/*_irq*.tsv

report:
	$(PY) tools/sst_report.py $(RES)/tv80_sst.tsv $(RES)/t80sv_sst.tsv > $(RES)/summary.md

# ZEXDOC/ZEXALL: tv80 ~1.5 h each, t80sv several hours each (Verilator, one core each). Copies the
# binaries first so a rebuild does not disturb running jobs.
zex: all $(RES)
	mkdir -p $(RES)/bin && cp $(TV80_EXE) $(T80_EXE) $(RES)/bin/
	for z in zexdoc zexall; do \
		$(RES)/bin/Vtv80e zex vectors/zex/$$z.com > $(RES)/tv80_$$z.log 2>&1 & \
		$(RES)/bin/VT80pa zex vectors/zex/$$z.com > $(RES)/t80sv_$$z.log 2>&1 & \
	done; wait

.PHONY: vectors sst sst-m1wait sst-one irq report zex
