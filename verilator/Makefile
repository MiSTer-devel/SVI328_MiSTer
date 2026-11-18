# Verilator simulator for the SVI-328 core. Needs Verilator 5.x and zlib.
#   make            build obj_dir/Vsvi_sim
#   make clean
RTL     = ../rtl
SV      = rtl_sv
TOP     = svi_sim
EXE     = obj_dir/V$(TOP)

V_SRC = sim.vlt svi_sim.sv \
	$(SV)/svi_console.sv $(SV)/svi_keyboard.sv $(SV)/cv_por.sv $(SV)/cv_clock.sv \
	$(SV)/vdp18v/vdp18_pkg.sv $(SV)/vdp18v/vdp18_clk_gen.sv $(SV)/vdp18v/vdp18_core.sv \
	$(SV)/vdp18v/vdp18_addr_mux.sv $(SV)/vdp18v/vdp18_col_mux.sv $(SV)/vdp18v/vdp18_cpuio.sv \
	$(SV)/vdp18v/vdp18_ctrl.sv $(SV)/vdp18v/vdp18_hor_vert.sv $(SV)/vdp18v/vdp18_pattern.sv \
	$(SV)/vdp18v/vdp18_sprite.sv \
	$(RTL)/t80sv/t80sv_all.sv \
	$(RTL)/svi_mapper.v $(RTL)/cassette.v $(RTL)/tape_rec.sv $(RTL)/svi_megarom.sv $(RTL)/svi_sdram_arb.sv gen/square_gen.v $(RTL)/jt8255.v $(RTL)/tape_overlay.sv \
	$(RTL)/sv801/sv801.sv $(RTL)/sv801/wd1793.sv $(RTL)/sv806/sv806.sv $(RTL)/sv806/sv806_auto.sv $(RTL)/sv806/um6845r.v \
	$(RTL)/Jt49/jt49_bus.v $(RTL)/Jt49/jt49.v $(RTL)/Jt49/jt49_cen.v $(RTL)/Jt49/jt49_div.v \
	$(RTL)/Jt49/jt49_eg.v $(RTL)/Jt49/jt49_exp.v $(RTL)/Jt49/jt49_noise.v

# --no-timing: tv80 (make tv80) uses "<= #1"
V_FLAGS = --cc --exe --build -j 0 --top-module $(TOP) --no-timing -Wno-fatal -Wno-lint -Wno-style \
	--x-assign fast --x-initial fast --noassert -O3 \
	+incdir+$(SV)/vdp18v +incdir+$(SV)/tv80 +incdir+$(RTL) \
	-CFLAGS "-O2 -std=c++17" -LDFLAGS "-lz"

all: $(EXE)

# Same file as rtl/square_gen.v with the phase step x4 (sim clock is 1/4 of clk_sys)
gen/square_gen.v: $(RTL)/square_gen.v
	mkdir -p gen
	sed "s/parameter STP = 24'hEF3/parameter STP = 24'h3BCC/" $< > $@
	grep -q "24'h3BCC" $@

$(EXE): $(V_SRC) gen/square_gen.v sim_main.cpp Makefile
	verilator $(V_FLAGS) $(V_SRC) sim_main.cpp

# full-rate build: clk_sys clock, Svi328.sv's enables and tape turbo, rtl/square_gen.v
FULL_SRC = $(subst gen/square_gen.v,$(RTL)/square_gen.v,$(V_SRC))
full: obj_full/V$(TOP)

obj_full/V$(TOP): $(FULL_SRC) sim_main.cpp Makefile
	verilator $(V_FLAGS) --Mdir obj_full -GFULL=1 -CFLAGS -DSIM_FULL=1 $(FULL_SRC) sim_main.cpp

# tv80e (rtl_sv/tv80) instead of the hardware's t80sv
TV80_SRC = $(filter-out $(RTL)/t80sv/%,$(V_SRC)) \
	$(SV)/tv80/tv80_alu.v $(SV)/tv80/tv80_core.v $(SV)/tv80/tv80_mcode.v $(SV)/tv80/tv80_reg.v $(SV)/tv80/tv80e.v
tv80: obj_tv80/V$(TOP)

obj_tv80/V$(TOP): $(TV80_SRC) gen/square_gen.v sim_main.cpp Makefile
	verilator $(V_FLAGS) --Mdir obj_tv80 +define+SIM_TV80 -CFLAGS -DSIM_TV80 $(TV80_SRC) sim_main.cpp

clean:
	rm -rf obj_dir obj_full obj_tv80 gen
