# Cassette status

Measurements for `~/dev2/tape-standard.md` ("Results"). Hardware: a DE10-Nano
MiSTer over HDMI, test builds of 2026-11-15 (`SVI328_20261115b` has both fixes below), TOSEC `.cas` images, Tape speed
4x unless noted. Times are wall-clock from Return on the load command, read
from screenshots taken every 8-25 s, so they are good to about one interval.

## Times to title

| Tape | Command | Tape length | 4x | Normal |
|---|---|---|---|---|
| Mr. Do! (Nippon Columbia) | `CLOAD`, `RUN` | 5:01 | CLOAD < 8 s; options screen about 75 s after RUN | options screen about 300 s after RUN |
| Arkanoid (Taito) | `CLOAD`, `RUN` | 5:40 | title about 84 s after RUN | |
| Kung Fu Master (Spectravideo) | `BLOAD"CAS:",R` | 3:42 | menu about 31 s (the rest loads behind the menu, tape ends at 64 s) | menu about 128 s |
| Robocop (Ocean, Mr. Haward) | `RUN"CAS:"`, `C`, a key at "STOP THE TAPE" | 25:52 | "DISK OR CAS" at 31 s; block 1 about 100 s after `C`; menu after the key | |
| Rambo III Intro (Mr. Haward) | `RUN"CAS:"` | | scroller about 100 s | |
| Joystick 05 (SAGA & Joystick) | `CLOAD`, `RUN` | | first program (the magazine) after RUN | |
| MKOD Collection 07 (400 KB) | `CLOAD`, `RUN` | 41:54 | first program (Ping Pong) to the Konami logo | |
| Emergency Landing | `CLOAD` | | `Found:Landin`, Ok in < 8 s | |

The next-step hint showed the right command for every one of these, and
`TYPE RUN ↵` after each `CLOAD`.

## Findings on hardware (2026-11-15)

- **Turbo stayed on after the tape ended.** Mr. Do! and Kung Fu Master leave
  the motor bit on, so the bar stayed up over the game and the Z80 kept
  running at 4x. Fixed: the deck plays only while the motor is on *and* the
  tape has not reached its end (`deck_plays` in `Svi328.sv`), as the X1
  reference treats an ended tape.
- **Kung Fu Master's menu was garbled at 4x** (clean at Normal and in the
  simulator). The game draws its menu while the rest of the tape loads, and
  at 14 MHz its VDP writes came faster than the TMS9918A's one-byte buffer
  is emptied. Fixed: under turbo the Z80 waits on a VDP access until the VDP
  is not busy (`vdp_pace` in `rtl/cv_console.vhd`). Confirmed on hardware
  (build 20261115b): the menu draws cleanly at 4x while the tape plays, menu
  at about 32 s; Mr. Do! loads in the same time as before the change.

## Other checks on hardware

- OSD: top page, Machine/Video pages, "Changes pending" and Apply and reset,
  the Disk row appearing when SV-801 is switched on.
- SV-801 + SV-806: CP/M 2.24 from `cpmds.dsk`, `DIR` at 80 columns over HDMI.
- Cartridge from a `.zip` (Frantic Freddy), then Eject cartridge: back to
  BASIC without a power cycle.

## Simulator

All 19 cartridge images in the local corpus: every SVI cartridge starts. Two
images that don't are not SVI cartridges on their own: `Bloktris v1.01 .rom`
is an MSX ROM (`AB` header), and `1_svi328_msx.bin` / `2_svi328_msx.bin` are
the two halves of `SVI328_MSX.ROM` (which starts).
