# Spectravideo SVI-328 / SVI-318

Core by fpganoob on misterfpga.org.

Place the BASIC ROM in `games/SVI328/boot.rom` (SV Extended BASIC 1.1 for the
SVI-328; another ROM can be picked for one session with **Load ROM**). For the
SV-806 80-column card, place its 4 KB character ROM (`svi806.rom`, MAME
`sv806.ic27`) in `games/SVI328/boot1.rom`.

## OSD

| Row | Page | |
|---|---|---|
| Cartridge | top | a cartridge image (`.bin` / `.rom`, up to 64 KB) |
| Tape | top | a `.cas` tape image (hidden when Tape input = ADC) |
| Disk | top | a `.dsk` disk image for the SV-801 (shown when SV-801 disk = On) |
| Load ROM | top | another BASIC ROM for this session |
| Memory | top | `SV-807 (160K)` (default): banks 21, 22, 31 and 32 present, as with the SV-807 RAM expansion; `Standard`: the machine alone |
| Model | Machine | `SVI-328` (64 KB) or `SVI-318` (16 KB at C000-FFFF) |
| SV-801 disk | Machine | `Off` (default) / `On`: the disk controller |
| SV-806 80-column | Machine | `Off` (default) / `On`: the 80-column card |
| Tape input | Machine | `File` (the Tape slot) or `ADC` (a real cassette player on the ADC input) |
| Tape speed | Machine | `4x` (default) or `Normal`; see below |
| Rewind tape, Eject cartridge | Machine | buttons |
| Aspect ratio, Scale, Scandoubler Fx, Border | Video | |
| Video standard | Video | `PAL` (default, 50 Hz, TMS9929A) or `NTSC` (60 Hz, TMS9928A) |
| Display | Video | `VDP` or `80-column` (with the SV-806 on): which of the machine's two video outputs to show |
| Tape overlay | Video | `On` (default) / `Off` |
| Joysticks swap | Input | |
| Tape audio | Audio | `Off` (default) / `On`: hear the tape while it loads |

Settings take effect at **Apply and reset** ("Changes pending" shows while
they differ from what the machine runs); media, buttons, Tape speed, Tape
overlay, Tape audio, Display and Joysticks swap act at once.

## Tapes

Load a `.cas` file in the **Tape** slot, then type the command the tape needs
(the tape status box at the bottom left shows it: `TYPE CLOAD ↵`):

| First file on the tape | Command |
|---|---|
| tokenized BASIC (header type D3h) | `CLOAD`, then `RUN` when it says `Ok` (the box shows `TYPE RUN ↵`) |
| machine code (D0h) | `BLOAD"CAS:",R` |
| ASCII BASIC (EAh) | `RUN"CAS:"` |

The hint is read from the tape's first header only, never from the file name.
It matches the load command named in 199 of the 200 TOSEC tapes that name one.

While the tape plays the box shows elapsed / total time (at the real tape
speed), `x4` while turbo is on, and a progress bar.

**Tape speed 4x** runs the Z80 and the tape 4 times faster, only while the
deck plays: the motor is on and the tape has not reached its end. The machine
runs at normal speed as soon as the BIOS stops the motor or the tape runs out
(Mr. Do! and Kung Fu Master leave the motor on), so games never run fast. The
BIOS times the tape with CPU loops, so it reads the same bits at either speed.
While turbo is on, the Z80 waits on a VDP access until the VDP has stored the
previous one, so a game that draws while it loads (Kung Fu Master's menu)
draws correctly. The setting is taken each time the motor starts.

Mounting a tape rewinds it; a reset also rewinds it.

## Keyboard

The keys map by position, except where noted:

| SVI key | PC key |
|---|---|
| `:` / `;` | `;` key: `;` unshifted, `:` with Shift (as printed on a PC; the SVI key is the other way round) |
| STOP | F8 or F6 |
| SELECT | F7 |
| PRINT | F9 |
| CLS | Home |
| INS | Insert |
| DEL | Delete |
| left / right GRAPH | left Alt or left Win / right Alt or right Win |
| keypad (SVI-328) | PC keypad (the SVI-318 has no keypad: those rows read as no key) |

## Cartridges

Load a cartridge in the **Cartridge** slot; the machine resets into it.
**Eject cartridge** takes it out and resets into BASIC. Cartridge space
that the image doesn't fill reads FF.

## Disks (SV-801)

Set **SV-801 disk** to `On`, Apply and reset, then mount a `.dsk` in **Disk**
and reset: the BASIC ROM boots Disk BASIC or CP/M from it. Images are the raw
format MAME uses (`svi_dsk`): 172032 bytes single-sided or 346112 bytes
double-sided, 40 tracks, track 0 side 0 with 18 x 128-byte sectors and every
other track 17 x 256. One drive (A:). `.imd` images have to be converted first.

The controller is an FD1793 at ports 30h-34h and 38h, as the SV-801. Its
FD1793 is Sorgelig's wd1793 with the SVI geometry added in teiram's Calypso
port of this core.

## 80 columns (SV-806)

Set **SV-806 80-column** to `On` and Apply and reset; CP/M then uses 80
columns. The card has its own monochrome monitor output on the real machine,
so **Display** chooses which output the MiSTer shows: `VDP` for the normal
picture, `80-column` for the card's (green). The card's 6845 runs from its own
12 MHz dot clock: 80 x 24 characters, 50 Hz.

## I/O ports

As on the STM-A schematic (sheet 2, IC21 LS138): A7 = 1 and A6 = 0 select the
VDP, PSG and PPI, A4-A2 pick one; A5, A1 and A0 are not decoded, so each port
also answers 20h higher (VDP write 80-83/A0-A3, VDP read 84-87/A4-A7, PSG latch
88-8B/A8-AB, PSG write 8C-8F/AC-AF, PSG read 90-93/B0-B3, PPI write 94-97/B4-B7,
PPI read 98-9B/B8-BB).

## Memory map

PSG port B selects the banks as on the real machine: ROMEN0 and ROMEN1 map
the cartridge's upper 32 KB in two independent 16 KB halves and only while
the cartridge bank is selected (STM-A schematic, as MAME). Port B reads FF
until the BIOS makes it an output, as the AY's pull-ups do.

## Simulator

`verilator/` holds a Verilator simulator of the core for development; see
`verilator/README.md`.
