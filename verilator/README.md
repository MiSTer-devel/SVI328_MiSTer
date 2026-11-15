# SVI-328 Verilator simulator

Headless simulator for iterating on the core without a Quartus build. It runs
the core's own Verilog (`rtl/svi_mapper.v`, `rtl/cassette.v`,
`rtl/square_gen.v`, `rtl/tape_overlay.sv`, `rtl/sv801/`, `rtl/sv806/`,
`rtl/jt8255.v`, `rtl/Jt49/`) plus SystemVerilog versions of the VHDL parts in
`rtl_sv/`.

    make                       # Verilator 5.x + zlib -> obj_dir/Vsvi_sim (10.7 MHz rate, fast)
    make full                  # obj_full/Vsvi_sim: clk_sys rate, Svi328.sv's enables, --turbo
    ./obj_dir/Vsvi_sim --help

Run from this directory: the default ROM is `../software/mister11/boot.rom`.

## Examples

    # boot to BASIC, picture at frame 700, print the screen text
    ./obj_dir/Vsvi_sim --frames 700 --shots 700 --text 700 --outdir /tmp/svi

    # load a tape with the command its header asks for, log the motor against the CAS blocks
    ./obj_dir/Vsvi_sim --tape "../software/all/CAS/Kung Fu Master (1984)(Spectravideo)[BLOAD'CAS-',R].cas" \
        --type 'BLOAD"CAS:",R\n@700' --frames 20000 --every 500 --tape-log --after-motor 300

    # Disk BASIC from the SV-801, then FILES
    ./obj_dir/Vsvi_sim --disk ../software/all/DSK/diskbasic10.dsk --type 'FILES\n@1000' --frames 1400 --text 1400

    # CP/M on the SV-806, 80-column picture
    ./obj_dir/Vsvi_sim --disk ../software/all/DSK/cpmds.dsk --charrom ../software/all/SYS/svi806.rom \
        --show80 --type 'DIR\n@2300' --frames 2700 --shots 2700

    # cartridge, fire held on joystick 1 from frame 400 for 100 frames, PPI port A trace
    ./obj_dir/Vsvi_sim --cart "../software/all/CART/Frantic Freddy (1983)(Spectravideo).bin" \
        --joy f@400:100 --io-log --frames 600 --shots 450

Frames are PNG (`OUTDIR/frame_NNNNN.png`), the active picture only.

## How it maps to the hardware build

| Hardware (`Svi328.sv`, `rtl/`) | Simulator |
|---|---|
| `cv_console.vhd`, `cv_addr_dec.vhd`, `cv_bus_mux.vhd`, `74ls74.vhd` | `rtl_sv/svi_console.sv` (one file, same logic) |
| T80pa (`rtl/T80`) | tv80e (`rtl_sv/tv80`, from ColecoAdam_MiSTer 5dc296a) |
| vdp18 VHDL (`rtl/vdp18`) | vdp18v (`rtl_sv/vdp18v`, ColecoAdam's SV TMS9918A with its sprite/5th-sprite fixes; SVI's vsync change 6ca3b9c ported into `vdp18_hor_vert.sv`) |
| `keyboard_svi.vhd` | `rtl_sv/svi_keyboard.sv`, table for table, bugs included |
| `cv_por.vhd`, `cv_clock.vhd` | ColecoAdam's `cv_por.sv`, `cv_clock.sv` |
| CPU memory: block RAM `spram #(18)` `{bank,A15:0}` | array `sdram` in `svi_sim.sv`, registered read |
| tape image in SDRAM (`sdram.sv`) | `cas_ram` (4 MB) behind the same rd/ready handshake, 8 or 16 clocks latency |
| hps_io ioctl downloads (index 0 ROM, 1 cart, 2 CAS, 40h boot1.rom) | `dl_*` ports (`dl_target` 0 memory, 1 CAS, 2 SV-806 ROM), loaded while reset is held |
| hps_io SD (SV-801 image) | `sd_step()` in `sim_main.cpp`: 512-byte blocks, writes kept in memory only |
| tape overlay, Display switch | same modules / mux as `Svi328.sv` |
| `video_mixer`, ADC tape input | not modelled |

OSD settings: `--ntsc`, `--318`, `--mem-std`, `--no-overlay`, `--disk FILE`
/ `--fdc` (SV-801), `--80col` / `--show80` / `--charrom FILE` (SV-806).

**Clocks.** The sim clock is the 10.7 MHz rate (`clk_en_10m7` tied to 1),
as in ColecoAdam's simulator; hardware runs clk_sys = 42.954545 MHz with a /4
enable. The cassette player steps on rising edges of `Q`, which on hardware
come at 21.477 MHz; here they come at 5.369 MHz, so the Makefile builds
`gen/square_gen.v` from `rtl/square_gen.v` with `STP` = 4 x 24'hEF3. Bit
timing and byte stream are the same.

**Not the same as hardware:** the CPU and VDP models differ (above): tv80
fails some documented-flag tests that T80 passes (DAA, `LD A,R`; see
`cpu_tests/README.md`). In the fast build the SV-806 dot clock is 10.7 MHz
instead of 12. Something that works here and fails on a MiSTer points at
those.

## Options worth knowing

- `--tape-log` prints every motor change with `CAS_addr` and which CAS block
  (16 x 55h + 7Fh) that position is in, and how far into it.
- `--until 'TEXT'` stops when the text appears in the VDP name table (checked
  every 10 frames); `--text F,..` / `--text-end` print the name table.
- `--after-motor N` stops N frames after the motor last went off: the end of
  a tape load.
- `--profile N` samples the Z80 PC every N cycles to show where code loops.
- `--dump-ram FILE@FRAME` writes the 256 KB SDRAM window (bank layout as in
  `svi_mapper.v`: 00000 BASIC ROM, 08000 main RAM, 10000 cartridge, ...).
- `--wav FILE` writes the audio output.

Speed: about 7 frames/s on an M-series Mac, single-threaded. A real-speed
tape load (about 3 minutes, 9000 frames) takes around 20 minutes, so run
several in parallel.
