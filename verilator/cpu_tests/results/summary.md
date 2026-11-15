# SingleStepTests/z80 results

### tv80: SingleStepTests by group

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

### tv80: opcodes with documented-behaviour failures

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|
| 27 | official | 488 | f=488 | `27_0000: F exp 87 got 83` |
| DD 13 | prefix on non-HL op / IXH,IXL | 1000 | b=2, c=1000, d=4, e=1000 | `DD_13_0000: exp E4 got E5` |
| DD 1B | prefix on non-HL op / IXH,IXL | 1000 | b=1, c=1000, d=1, e=1000 | `DD_1B_0000: exp 24 got 23` |
| DD 27 | prefix on non-HL op / IXH,IXL | 480 | f=480 | `DD_27_0001: F exp 15 got 11` |
| DD CB D 00 | register-copy form | 1000 | cycles=1000 | `DD_CB____00_0000: instruction did not end within max T` |
| DD CB D 01 | register-copy form | 1000 | cycles=1000 | `DD_CB____01_0000: instruction did not end within max T` |
| DD CB D 02 | register-copy form | 1000 | cycles=1000 | `DD_CB____02_0000: instruction did not end within max T` |
| DD CB D 03 | register-copy form | 1000 | cycles=1000 | `DD_CB____03_0000: instruction did not end within max T` |
| DD CB D 04 | register-copy form | 1000 | cycles=1000 | `DD_CB____04_0000: instruction did not end within max T` |
| DD CB D 05 | register-copy form | 1000 | pc=1, f=1, f53=1, l=1, ram=1, cycles=1000, bus=1 | `DD_CB____05_0000: instruction did not end within max T` |
| DD CB D 07 | register-copy form | 1000 | cycles=1000 | `DD_CB____07_0000: instruction did not end within max T` |
| DD CB D 08 | register-copy form | 1000 | cycles=1000 | `DD_CB____08_0000: instruction did not end within max T` |
| DD CB D 09 | register-copy form | 1000 | cycles=1000 | `DD_CB____09_0000: instruction did not end within max T` |
| DD CB D 0A | register-copy form | 1000 | cycles=1000 | `DD_CB____0A_0000: instruction did not end within max T` |
| DD CB D 0B | register-copy form | 1000 | cycles=1000 | `DD_CB____0B_0000: instruction did not end within max T` |
| DD CB D 0C | register-copy form | 1000 | cycles=1000 | `DD_CB____0C_0000: instruction did not end within max T` |
| DD CB D 0D | register-copy form | 1000 | cycles=1000 | `DD_CB____0D_0000: instruction did not end within max T` |
| DD CB D 0F | register-copy form | 1000 | cycles=1000 | `DD_CB____0F_0000: instruction did not end within max T` |
| DD CB D 10 | register-copy form | 1000 | cycles=1000 | `DD_CB____10_0000: instruction did not end within max T` |
| DD CB D 11 | register-copy form | 1000 | cycles=1000 | `DD_CB____11_0000: instruction did not end within max T` |
| DD CB D 12 | register-copy form | 1000 | cycles=1000 | `DD_CB____12_0000: instruction did not end within max T` |
| DD CB D 13 | register-copy form | 1000 | cycles=1000 | `DD_CB____13_0000: instruction did not end within max T` |
| DD CB D 14 | register-copy form | 1000 | cycles=1000 | `DD_CB____14_0000: instruction did not end within max T` |
| DD CB D 15 | register-copy form | 1000 | cycles=1000 | `DD_CB____15_0000: instruction did not end within max T` |
| DD CB D 17 | register-copy form | 1000 | cycles=1000 | `DD_CB____17_0000: instruction did not end within max T` |
| DD CB D 18 | register-copy form | 1000 | cycles=1000 | `DD_CB____18_0000: instruction did not end within max T` |
| DD CB D 19 | register-copy form | 1000 | cycles=1000 | `DD_CB____19_0000: instruction did not end within max T` |
| DD CB D 1A | register-copy form | 1000 | cycles=1000 | `DD_CB____1A_0000: instruction did not end within max T` |
| DD CB D 1B | register-copy form | 1000 | cycles=1000 | `DD_CB____1B_0000: instruction did not end within max T` |
| DD CB D 1C | register-copy form | 1000 | cycles=1000 | `DD_CB____1C_0000: instruction did not end within max T` |
| DD CB D 1D | register-copy form | 1000 | cycles=1000 | `DD_CB____1D_0000: instruction did not end within max T` |
| DD CB D 1F | register-copy form | 1000 | cycles=1000 | `DD_CB____1F_0000: instruction did not end within max T` |
| DD CB D 20 | register-copy form | 1000 | cycles=1000 | `DD_CB____20_0000: instruction did not end within max T` |
| DD CB D 21 | register-copy form | 1000 | cycles=1000 | `DD_CB____21_0000: instruction did not end within max T` |
| DD CB D 22 | register-copy form | 1000 | cycles=1000 | `DD_CB____22_0000: instruction did not end within max T` |
| DD CB D 23 | register-copy form | 1000 | cycles=1000 | `DD_CB____23_0000: instruction did not end within max T` |
| DD CB D 24 | register-copy form | 1000 | cycles=1000 | `DD_CB____24_0000: instruction did not end within max T` |
| DD CB D 25 | register-copy form | 1000 | cycles=1000 | `DD_CB____25_0000: instruction did not end within max T` |
| DD CB D 27 | register-copy form | 1000 | cycles=1000 | `DD_CB____27_0000: instruction did not end within max T` |
| DD CB D 28 | register-copy form | 1000 | cycles=1000 | `DD_CB____28_0000: instruction did not end within max T` |
| DD CB D 29 | register-copy form | 1000 | cycles=1000 | `DD_CB____29_0000: instruction did not end within max T` |
| DD CB D 2A | register-copy form | 1000 | cycles=1000 | `DD_CB____2A_0000: instruction did not end within max T` |
| DD CB D 2B | register-copy form | 1000 | cycles=1000 | `DD_CB____2B_0000: instruction did not end within max T` |
| DD CB D 2C | register-copy form | 1000 | cycles=1000 | `DD_CB____2C_0000: instruction did not end within max T` |
| DD CB D 2D | register-copy form | 1000 | cycles=1000 | `DD_CB____2D_0000: instruction did not end within max T` |
| DD CB D 2F | register-copy form | 1000 | cycles=1000 | `DD_CB____2F_0000: instruction did not end within max T` |
| DD CB D 30 | register-copy form | 1000 | cycles=1000 | `DD_CB____30_0000: instruction did not end within max T` |
| DD CB D 31 | register-copy form | 1000 | cycles=1000 | `DD_CB____31_0000: instruction did not end within max T` |
| DD CB D 32 | register-copy form | 1000 | cycles=1000 | `DD_CB____32_0000: instruction did not end within max T` |
| DD CB D 33 | register-copy form | 1000 | cycles=1000 | `DD_CB____33_0000: instruction did not end within max T` |
| DD CB D 34 | register-copy form | 1000 | cycles=1000 | `DD_CB____34_0000: instruction did not end within max T` |
| DD CB D 35 | register-copy form | 1000 | cycles=1000 | `DD_CB____35_0000: instruction did not end within max T` |
| DD CB D 37 | register-copy form | 1000 | cycles=1000 | `DD_CB____37_0000: instruction did not end within max T` |
| DD CB D 38 | register-copy form | 1000 | cycles=1000 | `DD_CB____38_0000: instruction did not end within max T` |
| DD CB D 39 | register-copy form | 1000 | cycles=1000 | `DD_CB____39_0000: instruction did not end within max T` |
| DD CB D 3A | register-copy form | 1000 | cycles=1000 | `DD_CB____3A_0000: instruction did not end within max T` |
| DD CB D 3B | register-copy form | 1000 | cycles=1000 | `DD_CB____3B_0000: instruction did not end within max T` |
| DD CB D 3C | register-copy form | 1000 | cycles=1000 | `DD_CB____3C_0000: instruction did not end within max T` |
| DD CB D 3D | register-copy form | 1000 | cycles=1000 | `DD_CB____3D_0000: instruction did not end within max T` |
| DD CB D 3F | register-copy form | 1000 | cycles=1000 | `DD_CB____3F_0000: instruction did not end within max T` |
| DD CB D 40 | register-copy form | 1000 | cycles=1000 | `DD_CB____40_0000: instruction did not end within max T` |
| DD CB D 41 | register-copy form | 1000 | cycles=1000 | `DD_CB____41_0000: instruction did not end within max T` |
| DD CB D 42 | register-copy form | 1000 | cycles=1000 | `DD_CB____42_0000: instruction did not end within max T` |
| DD CB D 43 | register-copy form | 1000 | cycles=1000 | `DD_CB____43_0000: instruction did not end within max T` |
| DD CB D 44 | register-copy form | 1000 | cycles=1000 | `DD_CB____44_0000: instruction did not end within max T` |
| DD CB D 45 | register-copy form | 1000 | cycles=1000 | `DD_CB____45_0000: instruction did not end within max T` |
| DD CB D 47 | register-copy form | 1000 | cycles=1000 | `DD_CB____47_0000: instruction did not end within max T` |
| DD CB D 48 | register-copy form | 1000 | cycles=1000 | `DD_CB____48_0000: instruction did not end within max T` |
| DD CB D 49 | register-copy form | 1000 | cycles=1000 | `DD_CB____49_0000: instruction did not end within max T` |
| DD CB D 4A | register-copy form | 1000 | pc=1, f=1, f53=1, cycles=1000, bus=1 | `DD_CB____4A_0000: instruction did not end within max T` |
| DD CB D 4B | register-copy form | 1000 | cycles=1000 | `DD_CB____4B_0000: instruction did not end within max T` |
| DD CB D 4C | register-copy form | 1000 | cycles=1000 | `DD_CB____4C_0000: instruction did not end within max T` |
| DD CB D 4D | register-copy form | 1000 | cycles=1000 | `DD_CB____4D_0000: instruction did not end within max T` |
| DD CB D 4F | register-copy form | 1000 | cycles=1000 | `DD_CB____4F_0000: instruction did not end within max T` |
| DD CB D 50 | register-copy form | 1000 | cycles=1000 | `DD_CB____50_0000: instruction did not end within max T` |
| DD CB D 51 | register-copy form | 1000 | cycles=1000 | `DD_CB____51_0000: instruction did not end within max T` |
| DD CB D 52 | register-copy form | 1000 | cycles=1000 | `DD_CB____52_0000: instruction did not end within max T` |
| DD CB D 53 | register-copy form | 1000 | cycles=1000 | `DD_CB____53_0000: instruction did not end within max T` |
| DD CB D 54 | register-copy form | 1000 | cycles=1000 | `DD_CB____54_0000: instruction did not end within max T` |
| DD CB D 55 | register-copy form | 1000 | cycles=1000 | `DD_CB____55_0000: instruction did not end within max T` |
| DD CB D 57 | register-copy form | 1000 | cycles=1000 | `DD_CB____57_0000: instruction did not end within max T` |
| DD CB D 58 | register-copy form | 1000 | cycles=1000 | `DD_CB____58_0000: instruction did not end within max T` |
| DD CB D 59 | register-copy form | 1000 | cycles=1000 | `DD_CB____59_0000: instruction did not end within max T` |
| DD CB D 5A | register-copy form | 1000 | cycles=1000 | `DD_CB____5A_0000: instruction did not end within max T` |
| DD CB D 5B | register-copy form | 1000 | cycles=1000 | `DD_CB____5B_0000: instruction did not end within max T` |
| DD CB D 5C | register-copy form | 1000 | cycles=1000 | `DD_CB____5C_0000: instruction did not end within max T` |
| DD CB D 5D | register-copy form | 1000 | cycles=1000 | `DD_CB____5D_0000: instruction did not end within max T` |
| DD CB D 5F | register-copy form | 1000 | cycles=1000 | `DD_CB____5F_0000: instruction did not end within max T` |
| DD CB D 60 | register-copy form | 1000 | cycles=1000 | `DD_CB____60_0000: instruction did not end within max T` |
| DD CB D 61 | register-copy form | 1000 | cycles=1000 | `DD_CB____61_0000: instruction did not end within max T` |
| DD CB D 62 | register-copy form | 1000 | cycles=1000 | `DD_CB____62_0000: instruction did not end within max T` |
| DD CB D 63 | register-copy form | 1000 | cycles=1000 | `DD_CB____63_0000: instruction did not end within max T` |
| DD CB D 64 | register-copy form | 1000 | cycles=1000 | `DD_CB____64_0000: instruction did not end within max T` |
| DD CB D 65 | register-copy form | 1000 | cycles=1000 | `DD_CB____65_0000: instruction did not end within max T` |
| DD CB D 67 | register-copy form | 1000 | pc=1, f=1, cycles=1000, bus=1 | `DD_CB____67_0000: instruction did not end within max T` |
| DD CB D 68 | register-copy form | 1000 | cycles=1000 | `DD_CB____68_0000: instruction did not end within max T` |
| DD CB D 69 | register-copy form | 1000 | cycles=1000 | `DD_CB____69_0000: instruction did not end within max T` |
| DD CB D 6A | register-copy form | 1000 | cycles=1000 | `DD_CB____6A_0000: instruction did not end within max T` |
| DD CB D 6B | register-copy form | 1000 | pc=1, f=1, f53=1, cycles=1000, bus=1 | `DD_CB____6B_0000: instruction did not end within max T` |
| DD CB D 6C | register-copy form | 1000 | cycles=1000 | `DD_CB____6C_0000: instruction did not end within max T` |
| DD CB D 6D | register-copy form | 1000 | cycles=1000 | `DD_CB____6D_0000: instruction did not end within max T` |
| DD CB D 6F | register-copy form | 1000 | cycles=1000 | `DD_CB____6F_0000: instruction did not end within max T` |
| DD CB D 70 | register-copy form | 1000 | cycles=1000 | `DD_CB____70_0000: instruction did not end within max T` |
| DD CB D 71 | register-copy form | 1000 | cycles=1000 | `DD_CB____71_0000: instruction did not end within max T` |
| DD CB D 72 | register-copy form | 1000 | cycles=1000 | `DD_CB____72_0000: instruction did not end within max T` |
| DD CB D 73 | register-copy form | 1000 | cycles=1000 | `DD_CB____73_0000: instruction did not end within max T` |
| DD CB D 74 | register-copy form | 1000 | cycles=1000 | `DD_CB____74_0000: instruction did not end within max T` |
| DD CB D 75 | register-copy form | 1000 | cycles=1000 | `DD_CB____75_0000: instruction did not end within max T` |
| DD CB D 77 | register-copy form | 1000 | cycles=1000 | `DD_CB____77_0000: instruction did not end within max T` |
| DD CB D 78 | register-copy form | 1000 | cycles=1000 | `DD_CB____78_0000: instruction did not end within max T` |
| DD CB D 79 | register-copy form | 1000 | cycles=1000 | `DD_CB____79_0000: instruction did not end within max T` |
| DD CB D 7A | register-copy form | 1000 | cycles=1000 | `DD_CB____7A_0000: instruction did not end within max T` |
| DD CB D 7B | register-copy form | 1000 | cycles=1000 | `DD_CB____7B_0000: instruction did not end within max T` |
| DD CB D 7C | register-copy form | 1000 | cycles=1000 | `DD_CB____7C_0000: instruction did not end within max T` |
| DD CB D 7D | register-copy form | 1000 | cycles=1000 | `DD_CB____7D_0000: instruction did not end within max T` |
| DD CB D 7F | register-copy form | 1000 | cycles=1000 | `DD_CB____7F_0000: instruction did not end within max T` |
| DD CB D 80 | register-copy form | 1000 | cycles=1000 | `DD_CB____80_0000: instruction did not end within max T` |
| DD CB D 81 | register-copy form | 1000 | cycles=1000 | `DD_CB____81_0000: instruction did not end within max T` |
| DD CB D 82 | register-copy form | 1000 | cycles=1000 | `DD_CB____82_0000: instruction did not end within max T` |
| DD CB D 83 | register-copy form | 1000 | cycles=1000 | `DD_CB____83_0000: instruction did not end within max T` |
| DD CB D 84 | register-copy form | 1000 | cycles=1000 | `DD_CB____84_0000: instruction did not end within max T` |
| DD CB D 85 | register-copy form | 1000 | cycles=1000 | `DD_CB____85_0000: instruction did not end within max T` |
| DD CB D 87 | register-copy form | 1000 | cycles=1000 | `DD_CB____87_0000: instruction did not end within max T` |
| DD CB D 88 | register-copy form | 1000 | cycles=1000 | `DD_CB____88_0000: instruction did not end within max T` |
| DD CB D 89 | register-copy form | 1000 | cycles=1000 | `DD_CB____89_0000: instruction did not end within max T` |
| DD CB D 8A | register-copy form | 1000 | cycles=1000 | `DD_CB____8A_0000: instruction did not end within max T` |
| DD CB D 8B | register-copy form | 1000 | cycles=1000 | `DD_CB____8B_0000: instruction did not end within max T` |
| DD CB D 8C | register-copy form | 1000 | cycles=1000 | `DD_CB____8C_0000: instruction did not end within max T` |
| DD CB D 8D | register-copy form | 1000 | cycles=1000 | `DD_CB____8D_0000: instruction did not end within max T` |
| DD CB D 8F | register-copy form | 1000 | cycles=1000 | `DD_CB____8F_0000: instruction did not end within max T` |
| DD CB D 90 | register-copy form | 1000 | cycles=1000 | `DD_CB____90_0000: instruction did not end within max T` |
| DD CB D 91 | register-copy form | 1000 | cycles=1000 | `DD_CB____91_0000: instruction did not end within max T` |
| DD CB D 92 | register-copy form | 1000 | cycles=1000 | `DD_CB____92_0000: instruction did not end within max T` |
| DD CB D 93 | register-copy form | 1000 | cycles=1000 | `DD_CB____93_0000: instruction did not end within max T` |
| DD CB D 94 | register-copy form | 1000 | cycles=1000 | `DD_CB____94_0000: instruction did not end within max T` |
| DD CB D 95 | register-copy form | 1000 | cycles=1000 | `DD_CB____95_0000: instruction did not end within max T` |
| DD CB D 97 | register-copy form | 1000 | cycles=1000 | `DD_CB____97_0000: instruction did not end within max T` |
| DD CB D 98 | register-copy form | 1000 | cycles=1000 | `DD_CB____98_0000: instruction did not end within max T` |
| DD CB D 99 | register-copy form | 1000 | cycles=1000 | `DD_CB____99_0000: instruction did not end within max T` |
| DD CB D 9A | register-copy form | 1000 | cycles=1000 | `DD_CB____9A_0000: instruction did not end within max T` |
| DD CB D 9B | register-copy form | 1000 | cycles=1000 | `DD_CB____9B_0000: instruction did not end within max T` |
| DD CB D 9C | register-copy form | 1000 | cycles=1000 | `DD_CB____9C_0000: instruction did not end within max T` |
| DD CB D 9D | register-copy form | 1000 | cycles=1000 | `DD_CB____9D_0000: instruction did not end within max T` |
| DD CB D 9F | register-copy form | 1000 | cycles=1000 | `DD_CB____9F_0000: instruction did not end within max T` |
| DD CB D A0 | register-copy form | 1000 | cycles=1000 | `DD_CB____A0_0000: instruction did not end within max T` |
| DD CB D A1 | register-copy form | 1000 | cycles=1000 | `DD_CB____A1_0000: instruction did not end within max T` |
| DD CB D A2 | register-copy form | 1000 | cycles=1000 | `DD_CB____A2_0000: instruction did not end within max T` |
| DD CB D A3 | register-copy form | 1000 | cycles=1000 | `DD_CB____A3_0000: instruction did not end within max T` |
| DD CB D A4 | register-copy form | 1000 | cycles=1000 | `DD_CB____A4_0000: instruction did not end within max T` |
| DD CB D A5 | register-copy form | 1000 | cycles=1000 | `DD_CB____A5_0000: instruction did not end within max T` |
| DD CB D A7 | register-copy form | 1000 | cycles=1000 | `DD_CB____A7_0000: instruction did not end within max T` |
| DD CB D A8 | register-copy form | 1000 | cycles=1000 | `DD_CB____A8_0000: instruction did not end within max T` |
| DD CB D A9 | register-copy form | 1000 | cycles=1000 | `DD_CB____A9_0000: instruction did not end within max T` |
| DD CB D AA | register-copy form | 1000 | cycles=1000 | `DD_CB____AA_0000: instruction did not end within max T` |
| DD CB D AB | register-copy form | 1000 | cycles=1000 | `DD_CB____AB_0000: instruction did not end within max T` |
| DD CB D AC | register-copy form | 1000 | cycles=1000 | `DD_CB____AC_0000: instruction did not end within max T` |
| DD CB D AD | register-copy form | 1000 | cycles=1000 | `DD_CB____AD_0000: instruction did not end within max T` |
| DD CB D AF | register-copy form | 1000 | cycles=1000 | `DD_CB____AF_0000: instruction did not end within max T` |
| DD CB D B0 | register-copy form | 1000 | cycles=1000 | `DD_CB____B0_0000: instruction did not end within max T` |
| DD CB D B1 | register-copy form | 1000 | cycles=1000 | `DD_CB____B1_0000: instruction did not end within max T` |
| DD CB D B2 | register-copy form | 1000 | cycles=1000 | `DD_CB____B2_0000: instruction did not end within max T` |
| DD CB D B3 | register-copy form | 1000 | cycles=1000 | `DD_CB____B3_0000: instruction did not end within max T` |
| DD CB D B4 | register-copy form | 1000 | cycles=1000 | `DD_CB____B4_0000: instruction did not end within max T` |
| DD CB D B5 | register-copy form | 1000 | cycles=1000 | `DD_CB____B5_0000: instruction did not end within max T` |
| DD CB D B7 | register-copy form | 1000 | cycles=1000 | `DD_CB____B7_0000: instruction did not end within max T` |
| DD CB D B8 | register-copy form | 1000 | pc=1, f=1, b=1, cycles=1000, bus=1 | `DD_CB____B8_0000: instruction did not end within max T` |
| DD CB D B9 | register-copy form | 1000 | cycles=1000 | `DD_CB____B9_0000: instruction did not end within max T` |
| DD CB D BA | register-copy form | 1000 | cycles=1000 | `DD_CB____BA_0000: instruction did not end within max T` |
| DD CB D BB | register-copy form | 1000 | cycles=1000 | `DD_CB____BB_0000: instruction did not end within max T` |
| DD CB D BC | register-copy form | 1000 | cycles=1000 | `DD_CB____BC_0000: instruction did not end within max T` |
| DD CB D BD | register-copy form | 1000 | cycles=1000 | `DD_CB____BD_0000: instruction did not end within max T` |
| DD CB D BF | register-copy form | 1000 | cycles=1000 | `DD_CB____BF_0000: instruction did not end within max T` |
| DD CB D C0 | register-copy form | 1000 | cycles=1000 | `DD_CB____C0_0000: instruction did not end within max T` |
| DD CB D C1 | register-copy form | 1000 | cycles=1000 | `DD_CB____C1_0000: instruction did not end within max T` |
| DD CB D C2 | register-copy form | 1000 | cycles=1000 | `DD_CB____C2_0000: instruction did not end within max T` |
| DD CB D C3 | register-copy form | 1000 | cycles=1000 | `DD_CB____C3_0000: instruction did not end within max T` |
| DD CB D C4 | register-copy form | 1000 | pc=1, h=1, ram=1, cycles=1000, bus=1 | `DD_CB____C4_0000: instruction did not end within max T` |
| DD CB D C5 | register-copy form | 1000 | cycles=1000 | `DD_CB____C5_0000: instruction did not end within max T` |
| DD CB D C7 | register-copy form | 1000 | cycles=1000 | `DD_CB____C7_0000: instruction did not end within max T` |
| DD CB D C8 | register-copy form | 1000 | cycles=1000 | `DD_CB____C8_0000: instruction did not end within max T` |
| DD CB D C9 | register-copy form | 1000 | cycles=1000 | `DD_CB____C9_0000: instruction did not end within max T` |
| DD CB D CA | register-copy form | 1000 | cycles=1000 | `DD_CB____CA_0000: instruction did not end within max T` |
| DD CB D CB | register-copy form | 1000 | cycles=1000 | `DD_CB____CB_0000: instruction did not end within max T` |
| DD CB D CC | register-copy form | 1000 | cycles=1000 | `DD_CB____CC_0000: instruction did not end within max T` |
| DD CB D CD | register-copy form | 1000 | cycles=1000 | `DD_CB____CD_0000: instruction did not end within max T` |
| DD CB D CF | register-copy form | 1000 | cycles=1000 | `DD_CB____CF_0000: instruction did not end within max T` |
| DD CB D D0 | register-copy form | 1000 | cycles=1000 | `DD_CB____D0_0000: instruction did not end within max T` |
| DD CB D D1 | register-copy form | 1000 | cycles=1000 | `DD_CB____D1_0000: instruction did not end within max T` |
| DD CB D D2 | register-copy form | 1000 | cycles=1000 | `DD_CB____D2_0000: instruction did not end within max T` |
| DD CB D D3 | register-copy form | 1000 | cycles=1000 | `DD_CB____D3_0000: instruction did not end within max T` |
| DD CB D D4 | register-copy form | 1000 | cycles=1000 | `DD_CB____D4_0000: instruction did not end within max T` |
| DD CB D D5 | register-copy form | 1000 | cycles=1000 | `DD_CB____D5_0000: instruction did not end within max T` |
| DD CB D D7 | register-copy form | 1000 | cycles=1000 | `DD_CB____D7_0000: instruction did not end within max T` |
| DD CB D D8 | register-copy form | 1000 | cycles=1000 | `DD_CB____D8_0000: instruction did not end within max T` |
| DD CB D D9 | register-copy form | 1000 | cycles=1000 | `DD_CB____D9_0000: instruction did not end within max T` |
| DD CB D DA | register-copy form | 1000 | cycles=1000 | `DD_CB____DA_0000: instruction did not end within max T` |
| DD CB D DB | register-copy form | 1000 | cycles=1000 | `DD_CB____DB_0000: instruction did not end within max T` |
| DD CB D DC | register-copy form | 1000 | cycles=1000 | `DD_CB____DC_0000: instruction did not end within max T` |
| DD CB D DD | register-copy form | 1000 | cycles=1000 | `DD_CB____DD_0000: instruction did not end within max T` |
| DD CB D DF | register-copy form | 1000 | cycles=1000 | `DD_CB____DF_0000: instruction did not end within max T` |
| DD CB D E0 | register-copy form | 1000 | cycles=1000 | `DD_CB____E0_0000: instruction did not end within max T` |
| DD CB D E1 | register-copy form | 1000 | cycles=1000 | `DD_CB____E1_0000: instruction did not end within max T` |
| DD CB D E2 | register-copy form | 1000 | cycles=1000 | `DD_CB____E2_0000: instruction did not end within max T` |
| DD CB D E3 | register-copy form | 1000 | cycles=1000 | `DD_CB____E3_0000: instruction did not end within max T` |
| DD CB D E4 | register-copy form | 1000 | cycles=1000 | `DD_CB____E4_0000: instruction did not end within max T` |
| DD CB D E5 | register-copy form | 1000 | cycles=1000 | `DD_CB____E5_0000: instruction did not end within max T` |
| DD CB D E7 | register-copy form | 1000 | pc=1, a=1, f=1, ram=1, cycles=1000, bus=1 | `DD_CB____E7_0000: instruction did not end within max T` |
| DD CB D E8 | register-copy form | 1000 | cycles=1000 | `DD_CB____E8_0000: instruction did not end within max T` |
| DD CB D E9 | register-copy form | 1000 | cycles=1000 | `DD_CB____E9_0000: instruction did not end within max T` |
| DD CB D EA | register-copy form | 1000 | cycles=1000 | `DD_CB____EA_0000: instruction did not end within max T` |
| DD CB D EB | register-copy form | 1000 | cycles=1000 | `DD_CB____EB_0000: instruction did not end within max T` |
| DD CB D EC | register-copy form | 1000 | cycles=1000 | `DD_CB____EC_0000: instruction did not end within max T` |
| DD CB D ED | register-copy form | 1000 | cycles=1000 | `DD_CB____ED_0000: instruction did not end within max T` |
| DD CB D EF | register-copy form | 1000 | cycles=1000 | `DD_CB____EF_0000: instruction did not end within max T` |
| DD CB D F0 | register-copy form | 1000 | cycles=1000 | `DD_CB____F0_0000: instruction did not end within max T` |
| DD CB D F1 | register-copy form | 1000 | cycles=1000 | `DD_CB____F1_0000: instruction did not end within max T` |
| DD CB D F2 | register-copy form | 1000 | cycles=1000 | `DD_CB____F2_0000: instruction did not end within max T` |
| DD CB D F3 | register-copy form | 1000 | cycles=1000 | `DD_CB____F3_0000: instruction did not end within max T` |
| DD CB D F4 | register-copy form | 1000 | cycles=1000 | `DD_CB____F4_0000: instruction did not end within max T` |
| DD CB D F5 | register-copy form | 1000 | cycles=1000 | `DD_CB____F5_0000: instruction did not end within max T` |
| DD CB D F7 | register-copy form | 1000 | cycles=1000 | `DD_CB____F7_0000: instruction did not end within max T` |
| DD CB D F8 | register-copy form | 1000 | cycles=1000 | `DD_CB____F8_0000: instruction did not end within max T` |
| DD CB D F9 | register-copy form | 1000 | cycles=1000 | `DD_CB____F9_0000: instruction did not end within max T` |
| DD CB D FA | register-copy form | 1000 | cycles=1000 | `DD_CB____FA_0000: instruction did not end within max T` |
| DD CB D FB | register-copy form | 1000 | cycles=1000 | `DD_CB____FB_0000: instruction did not end within max T` |
| DD CB D FC | register-copy form | 1000 | cycles=1000 | `DD_CB____FC_0000: instruction did not end within max T` |
| DD CB D FD | register-copy form | 1000 | cycles=1000 | `DD_CB____FD_0000: instruction did not end within max T` |
| DD CB D FF | register-copy form | 1000 | cycles=1000 | `DD_CB____FF_0000: instruction did not end within max T` |
| DD E3 | official | 1000 | bus=1000 | `DD_E3_0000: exp [MR:A5E8=DD MR:A5E9=E3 MR:F86E=C0 MR:F86F=2B MW:F86F=76 MW:F86E=12] got [MR:A5E8=DD MR:A5E9=E3 MR:F86E=C0 MW:F86E=12 MR:F86F=2B MW:F86F=76]` |
| E3 | official | 1000 | bus=1000 | `E3_0000: exp [MR:69CA=E3 MR:6CFD=E4 MR:6CFE=E8 MW:6CFE=D7 MW:6CFD=49] got [MR:69CA=E3 MR:6CFD=E4 MW:6CFD=49 MR:6CFE=E8 MW:6CFE=D7]` |
| ED 5F | official | 477 | f=477, f53=756 | `ED_5F_0001: F exp 0C got 8C` |
| ED 67 | official | 1000 | bus=1000 | `ED_67_0000: exp [MR:F938=ED MR:F939=67 MR:098F=38 MW:098F=23] got [MR:F938=ED MR:F939=67 MR:F93A=00 MR:098F=38 MW:098F=23]` |
| ED 77 | undocumented ED | 643 | im=643 | `ED_77_0000: exp 1 got 2` |
| ED 7E | undocumented ED | 670 | im=670 | `ED_7E_0002: exp 2 got 1` |
| FD 13 | prefix on non-HL op / IXH,IXL | 1000 | b=3, c=1000, d=3, e=1000 | `FD_13_0000: exp 77 got 78` |
| FD 1B | prefix on non-HL op / IXH,IXL | 1000 | b=4, c=1000, d=5, e=1000 | `FD_1B_0000: exp 99 got 98` |
| FD 27 | prefix on non-HL op / IXH,IXL | 449 | f=449 | `FD_27_0004: F exp 05 got 01` |
| FD CB D 00 | register-copy form | 1000 | cycles=1000 | `FD_CB____00_0000: instruction did not end within max T` |
| FD CB D 01 | register-copy form | 1000 | cycles=1000 | `FD_CB____01_0000: instruction did not end within max T` |
| FD CB D 02 | register-copy form | 1000 | cycles=1000 | `FD_CB____02_0000: instruction did not end within max T` |
| FD CB D 03 | register-copy form | 1000 | cycles=1000 | `FD_CB____03_0000: instruction did not end within max T` |
| FD CB D 04 | register-copy form | 1000 | cycles=1000 | `FD_CB____04_0000: instruction did not end within max T` |
| FD CB D 05 | register-copy form | 1000 | cycles=1000 | `FD_CB____05_0000: instruction did not end within max T` |
| FD CB D 07 | register-copy form | 1000 | cycles=1000 | `FD_CB____07_0000: instruction did not end within max T` |
| FD CB D 08 | register-copy form | 1000 | cycles=1000 | `FD_CB____08_0000: instruction did not end within max T` |
| FD CB D 09 | register-copy form | 1000 | cycles=1000 | `FD_CB____09_0000: instruction did not end within max T` |
| FD CB D 0A | register-copy form | 1000 | cycles=1000 | `FD_CB____0A_0000: instruction did not end within max T` |
| FD CB D 0B | register-copy form | 1000 | cycles=1000 | `FD_CB____0B_0000: instruction did not end within max T` |
| FD CB D 0C | register-copy form | 1000 | cycles=1000 | `FD_CB____0C_0000: instruction did not end within max T` |
| FD CB D 0D | register-copy form | 1000 | cycles=1000 | `FD_CB____0D_0000: instruction did not end within max T` |
| FD CB D 0F | register-copy form | 1000 | cycles=1000 | `FD_CB____0F_0000: instruction did not end within max T` |
| FD CB D 10 | register-copy form | 1000 | cycles=1000 | `FD_CB____10_0000: instruction did not end within max T` |
| FD CB D 11 | register-copy form | 1000 | cycles=1000 | `FD_CB____11_0000: instruction did not end within max T` |
| FD CB D 12 | register-copy form | 1000 | cycles=1000 | `FD_CB____12_0000: instruction did not end within max T` |
| FD CB D 13 | register-copy form | 1000 | cycles=1000 | `FD_CB____13_0000: instruction did not end within max T` |
| FD CB D 14 | register-copy form | 1000 | cycles=1000 | `FD_CB____14_0000: instruction did not end within max T` |
| FD CB D 15 | register-copy form | 1000 | cycles=1000 | `FD_CB____15_0000: instruction did not end within max T` |
| FD CB D 17 | register-copy form | 1000 | cycles=1000 | `FD_CB____17_0000: instruction did not end within max T` |
| FD CB D 18 | register-copy form | 1000 | cycles=1000 | `FD_CB____18_0000: instruction did not end within max T` |
| FD CB D 19 | register-copy form | 1000 | cycles=1000 | `FD_CB____19_0000: instruction did not end within max T` |
| FD CB D 1A | register-copy form | 1000 | cycles=1000 | `FD_CB____1A_0000: instruction did not end within max T` |
| FD CB D 1B | register-copy form | 1000 | cycles=1000 | `FD_CB____1B_0000: instruction did not end within max T` |
| FD CB D 1C | register-copy form | 1000 | cycles=1000 | `FD_CB____1C_0000: instruction did not end within max T` |
| FD CB D 1D | register-copy form | 1000 | cycles=1000 | `FD_CB____1D_0000: instruction did not end within max T` |
| FD CB D 1F | register-copy form | 1000 | cycles=1000 | `FD_CB____1F_0000: instruction did not end within max T` |
| FD CB D 20 | register-copy form | 1000 | cycles=1000 | `FD_CB____20_0000: instruction did not end within max T` |
| FD CB D 21 | register-copy form | 1000 | cycles=1000 | `FD_CB____21_0000: instruction did not end within max T` |
| FD CB D 22 | register-copy form | 1000 | cycles=1000 | `FD_CB____22_0000: instruction did not end within max T` |
| FD CB D 23 | register-copy form | 1000 | cycles=1000 | `FD_CB____23_0000: instruction did not end within max T` |
| FD CB D 24 | register-copy form | 1000 | cycles=1000 | `FD_CB____24_0000: instruction did not end within max T` |
| FD CB D 25 | register-copy form | 1000 | cycles=1000 | `FD_CB____25_0000: instruction did not end within max T` |
| FD CB D 27 | register-copy form | 1000 | cycles=1000 | `FD_CB____27_0000: instruction did not end within max T` |
| FD CB D 28 | register-copy form | 1000 | cycles=1000 | `FD_CB____28_0000: instruction did not end within max T` |
| FD CB D 29 | register-copy form | 1000 | cycles=1000 | `FD_CB____29_0000: instruction did not end within max T` |
| FD CB D 2A | register-copy form | 1000 | cycles=1000 | `FD_CB____2A_0000: instruction did not end within max T` |
| FD CB D 2B | register-copy form | 1000 | cycles=1000 | `FD_CB____2B_0000: instruction did not end within max T` |
| FD CB D 2C | register-copy form | 1000 | cycles=1000 | `FD_CB____2C_0000: instruction did not end within max T` |
| FD CB D 2D | register-copy form | 1000 | cycles=1000 | `FD_CB____2D_0000: instruction did not end within max T` |
| FD CB D 2F | register-copy form | 1000 | cycles=1000 | `FD_CB____2F_0000: instruction did not end within max T` |
| FD CB D 30 | register-copy form | 1000 | cycles=1000 | `FD_CB____30_0000: instruction did not end within max T` |
| FD CB D 31 | register-copy form | 1000 | cycles=1000 | `FD_CB____31_0000: instruction did not end within max T` |
| FD CB D 32 | register-copy form | 1000 | cycles=1000 | `FD_CB____32_0000: instruction did not end within max T` |
| FD CB D 33 | register-copy form | 1000 | cycles=1000 | `FD_CB____33_0000: instruction did not end within max T` |
| FD CB D 34 | register-copy form | 1000 | cycles=1000 | `FD_CB____34_0000: instruction did not end within max T` |
| FD CB D 35 | register-copy form | 1000 | cycles=1000 | `FD_CB____35_0000: instruction did not end within max T` |
| FD CB D 37 | register-copy form | 1000 | cycles=1000 | `FD_CB____37_0000: instruction did not end within max T` |
| FD CB D 38 | register-copy form | 1000 | cycles=1000 | `FD_CB____38_0000: instruction did not end within max T` |
| FD CB D 39 | register-copy form | 1000 | cycles=1000 | `FD_CB____39_0000: instruction did not end within max T` |
| FD CB D 3A | register-copy form | 1000 | cycles=1000 | `FD_CB____3A_0000: instruction did not end within max T` |
| FD CB D 3B | register-copy form | 1000 | cycles=1000 | `FD_CB____3B_0000: instruction did not end within max T` |
| FD CB D 3C | register-copy form | 1000 | cycles=1000 | `FD_CB____3C_0000: instruction did not end within max T` |
| FD CB D 3D | register-copy form | 1000 | cycles=1000 | `FD_CB____3D_0000: instruction did not end within max T` |
| FD CB D 3F | register-copy form | 1000 | cycles=1000 | `FD_CB____3F_0000: instruction did not end within max T` |
| FD CB D 40 | register-copy form | 1000 | cycles=1000 | `FD_CB____40_0000: instruction did not end within max T` |
| FD CB D 41 | register-copy form | 1000 | cycles=1000 | `FD_CB____41_0000: instruction did not end within max T` |
| FD CB D 42 | register-copy form | 1000 | cycles=1000 | `FD_CB____42_0000: instruction did not end within max T` |
| FD CB D 43 | register-copy form | 1000 | cycles=1000 | `FD_CB____43_0000: instruction did not end within max T` |
| FD CB D 44 | register-copy form | 1000 | cycles=1000 | `FD_CB____44_0000: instruction did not end within max T` |
| FD CB D 45 | register-copy form | 1000 | cycles=1000 | `FD_CB____45_0000: instruction did not end within max T` |
| FD CB D 47 | register-copy form | 1000 | cycles=1000 | `FD_CB____47_0000: instruction did not end within max T` |
| FD CB D 48 | register-copy form | 1000 | cycles=1000 | `FD_CB____48_0000: instruction did not end within max T` |
| FD CB D 49 | register-copy form | 1000 | cycles=1000 | `FD_CB____49_0000: instruction did not end within max T` |
| FD CB D 4A | register-copy form | 1000 | cycles=1000 | `FD_CB____4A_0000: instruction did not end within max T` |
| FD CB D 4B | register-copy form | 1000 | cycles=1000 | `FD_CB____4B_0000: instruction did not end within max T` |
| FD CB D 4C | register-copy form | 1000 | cycles=1000 | `FD_CB____4C_0000: instruction did not end within max T` |
| FD CB D 4D | register-copy form | 1000 | cycles=1000 | `FD_CB____4D_0000: instruction did not end within max T` |
| FD CB D 4F | register-copy form | 1000 | cycles=1000 | `FD_CB____4F_0000: instruction did not end within max T` |
| FD CB D 50 | register-copy form | 1000 | cycles=1000 | `FD_CB____50_0000: instruction did not end within max T` |
| FD CB D 51 | register-copy form | 1000 | cycles=1000 | `FD_CB____51_0000: instruction did not end within max T` |
| FD CB D 52 | register-copy form | 1000 | cycles=1000 | `FD_CB____52_0000: instruction did not end within max T` |
| FD CB D 53 | register-copy form | 1000 | cycles=1000 | `FD_CB____53_0000: instruction did not end within max T` |
| FD CB D 54 | register-copy form | 1000 | cycles=1000 | `FD_CB____54_0000: instruction did not end within max T` |
| FD CB D 55 | register-copy form | 1000 | cycles=1000 | `FD_CB____55_0000: instruction did not end within max T` |
| FD CB D 57 | register-copy form | 1000 | pc=1, f=1, f53=1, cycles=1000, bus=1 | `FD_CB____57_0000: instruction did not end within max T` |
| FD CB D 58 | register-copy form | 1000 | cycles=1000 | `FD_CB____58_0000: instruction did not end within max T` |
| FD CB D 59 | register-copy form | 1000 | cycles=1000 | `FD_CB____59_0000: instruction did not end within max T` |
| FD CB D 5A | register-copy form | 1000 | cycles=1000 | `FD_CB____5A_0000: instruction did not end within max T` |
| FD CB D 5B | register-copy form | 1000 | cycles=1000 | `FD_CB____5B_0000: instruction did not end within max T` |
| FD CB D 5C | register-copy form | 1000 | cycles=1000 | `FD_CB____5C_0000: instruction did not end within max T` |
| FD CB D 5D | register-copy form | 1000 | cycles=1000 | `FD_CB____5D_0000: instruction did not end within max T` |
| FD CB D 5F | register-copy form | 1000 | cycles=1000 | `FD_CB____5F_0000: instruction did not end within max T` |
| FD CB D 60 | register-copy form | 1000 | cycles=1000 | `FD_CB____60_0000: instruction did not end within max T` |
| FD CB D 61 | register-copy form | 1000 | cycles=1000 | `FD_CB____61_0000: instruction did not end within max T` |
| FD CB D 62 | register-copy form | 1000 | cycles=1000 | `FD_CB____62_0000: instruction did not end within max T` |
| FD CB D 63 | register-copy form | 1000 | cycles=1000 | `FD_CB____63_0000: instruction did not end within max T` |
| FD CB D 64 | register-copy form | 1000 | cycles=1000 | `FD_CB____64_0000: instruction did not end within max T` |
| FD CB D 65 | register-copy form | 1000 | cycles=1000 | `FD_CB____65_0000: instruction did not end within max T` |
| FD CB D 67 | register-copy form | 1000 | cycles=1000 | `FD_CB____67_0000: instruction did not end within max T` |
| FD CB D 68 | register-copy form | 1000 | cycles=1000 | `FD_CB____68_0000: instruction did not end within max T` |
| FD CB D 69 | register-copy form | 1000 | cycles=1000 | `FD_CB____69_0000: instruction did not end within max T` |
| FD CB D 6A | register-copy form | 1000 | cycles=1000 | `FD_CB____6A_0000: instruction did not end within max T` |
| FD CB D 6B | register-copy form | 1000 | cycles=1000 | `FD_CB____6B_0000: instruction did not end within max T` |
| FD CB D 6C | register-copy form | 1000 | cycles=1000 | `FD_CB____6C_0000: instruction did not end within max T` |
| FD CB D 6D | register-copy form | 1000 | cycles=1000 | `FD_CB____6D_0000: instruction did not end within max T` |
| FD CB D 6F | register-copy form | 1000 | cycles=1000 | `FD_CB____6F_0000: instruction did not end within max T` |
| FD CB D 70 | register-copy form | 1000 | cycles=1000 | `FD_CB____70_0000: instruction did not end within max T` |
| FD CB D 71 | register-copy form | 1000 | cycles=1000 | `FD_CB____71_0000: instruction did not end within max T` |
| FD CB D 72 | register-copy form | 1000 | cycles=1000 | `FD_CB____72_0000: instruction did not end within max T` |
| FD CB D 73 | register-copy form | 1000 | cycles=1000 | `FD_CB____73_0000: instruction did not end within max T` |
| FD CB D 74 | register-copy form | 1000 | cycles=1000 | `FD_CB____74_0000: instruction did not end within max T` |
| FD CB D 75 | register-copy form | 1000 | cycles=1000 | `FD_CB____75_0000: instruction did not end within max T` |
| FD CB D 77 | register-copy form | 1000 | cycles=1000 | `FD_CB____77_0000: instruction did not end within max T` |
| FD CB D 78 | register-copy form | 1000 | cycles=1000 | `FD_CB____78_0000: instruction did not end within max T` |
| FD CB D 79 | register-copy form | 1000 | cycles=1000 | `FD_CB____79_0000: instruction did not end within max T` |
| FD CB D 7A | register-copy form | 1000 | cycles=1000 | `FD_CB____7A_0000: instruction did not end within max T` |
| FD CB D 7B | register-copy form | 1000 | cycles=1000 | `FD_CB____7B_0000: instruction did not end within max T` |
| FD CB D 7C | register-copy form | 1000 | cycles=1000 | `FD_CB____7C_0000: instruction did not end within max T` |
| FD CB D 7D | register-copy form | 1000 | cycles=1000 | `FD_CB____7D_0000: instruction did not end within max T` |
| FD CB D 7F | register-copy form | 1000 | cycles=1000 | `FD_CB____7F_0000: instruction did not end within max T` |
| FD CB D 80 | register-copy form | 1000 | cycles=1000 | `FD_CB____80_0000: instruction did not end within max T` |
| FD CB D 81 | register-copy form | 1000 | cycles=1000 | `FD_CB____81_0000: instruction did not end within max T` |
| FD CB D 82 | register-copy form | 1000 | cycles=1000 | `FD_CB____82_0000: instruction did not end within max T` |
| FD CB D 83 | register-copy form | 1000 | cycles=1000 | `FD_CB____83_0000: instruction did not end within max T` |
| FD CB D 84 | register-copy form | 1000 | cycles=1000 | `FD_CB____84_0000: instruction did not end within max T` |
| FD CB D 85 | register-copy form | 1000 | cycles=1000 | `FD_CB____85_0000: instruction did not end within max T` |
| FD CB D 87 | register-copy form | 1000 | cycles=1000 | `FD_CB____87_0000: instruction did not end within max T` |
| FD CB D 88 | register-copy form | 1000 | cycles=1000 | `FD_CB____88_0000: instruction did not end within max T` |
| FD CB D 89 | register-copy form | 1000 | cycles=1000 | `FD_CB____89_0000: instruction did not end within max T` |
| FD CB D 8A | register-copy form | 1000 | cycles=1000 | `FD_CB____8A_0000: instruction did not end within max T` |
| FD CB D 8B | register-copy form | 1000 | cycles=1000 | `FD_CB____8B_0000: instruction did not end within max T` |
| FD CB D 8C | register-copy form | 1000 | cycles=1000 | `FD_CB____8C_0000: instruction did not end within max T` |
| FD CB D 8D | register-copy form | 1000 | pc=1, f=1, f53=1, l=1, ram=1, cycles=1000, bus=1 | `FD_CB____8D_0000: instruction did not end within max T` |
| FD CB D 8F | register-copy form | 1000 | cycles=1000 | `FD_CB____8F_0000: instruction did not end within max T` |
| FD CB D 90 | register-copy form | 1000 | cycles=1000 | `FD_CB____90_0000: instruction did not end within max T` |
| FD CB D 91 | register-copy form | 1000 | cycles=1000 | `FD_CB____91_0000: instruction did not end within max T` |
| FD CB D 92 | register-copy form | 1000 | cycles=1000 | `FD_CB____92_0000: instruction did not end within max T` |
| FD CB D 93 | register-copy form | 1000 | cycles=1000 | `FD_CB____93_0000: instruction did not end within max T` |
| FD CB D 94 | register-copy form | 1000 | cycles=1000 | `FD_CB____94_0000: instruction did not end within max T` |
| FD CB D 95 | register-copy form | 1000 | cycles=1000 | `FD_CB____95_0000: instruction did not end within max T` |
| FD CB D 97 | register-copy form | 1000 | cycles=1000 | `FD_CB____97_0000: instruction did not end within max T` |
| FD CB D 98 | register-copy form | 1000 | cycles=1000 | `FD_CB____98_0000: instruction did not end within max T` |
| FD CB D 99 | register-copy form | 1000 | cycles=1000 | `FD_CB____99_0000: instruction did not end within max T` |
| FD CB D 9A | register-copy form | 1000 | cycles=1000 | `FD_CB____9A_0000: instruction did not end within max T` |
| FD CB D 9B | register-copy form | 1000 | cycles=1000 | `FD_CB____9B_0000: instruction did not end within max T` |
| FD CB D 9C | register-copy form | 1000 | cycles=1000 | `FD_CB____9C_0000: instruction did not end within max T` |
| FD CB D 9D | register-copy form | 1000 | cycles=1000 | `FD_CB____9D_0000: instruction did not end within max T` |
| FD CB D 9F | register-copy form | 1000 | cycles=1000 | `FD_CB____9F_0000: instruction did not end within max T` |
| FD CB D A0 | register-copy form | 1000 | cycles=1000 | `FD_CB____A0_0000: instruction did not end within max T` |
| FD CB D A1 | register-copy form | 1000 | cycles=1000 | `FD_CB____A1_0000: instruction did not end within max T` |
| FD CB D A2 | register-copy form | 1000 | cycles=1000 | `FD_CB____A2_0000: instruction did not end within max T` |
| FD CB D A3 | register-copy form | 1000 | cycles=1000 | `FD_CB____A3_0000: instruction did not end within max T` |
| FD CB D A4 | register-copy form | 1000 | cycles=1000 | `FD_CB____A4_0000: instruction did not end within max T` |
| FD CB D A5 | register-copy form | 1000 | cycles=1000 | `FD_CB____A5_0000: instruction did not end within max T` |
| FD CB D A7 | register-copy form | 1000 | cycles=1000 | `FD_CB____A7_0000: instruction did not end within max T` |
| FD CB D A8 | register-copy form | 1000 | cycles=1000 | `FD_CB____A8_0000: instruction did not end within max T` |
| FD CB D A9 | register-copy form | 1000 | cycles=1000 | `FD_CB____A9_0000: instruction did not end within max T` |
| FD CB D AA | register-copy form | 1000 | pc=1, f=1, f53=1, d=1, ram=1, cycles=1000, bus=1 | `FD_CB____AA_0000: instruction did not end within max T` |
| FD CB D AB | register-copy form | 1000 | cycles=1000 | `FD_CB____AB_0000: instruction did not end within max T` |
| FD CB D AC | register-copy form | 1000 | pc=1, h=1, cycles=1000, bus=1 | `FD_CB____AC_0000: instruction did not end within max T` |
| FD CB D AD | register-copy form | 1000 | cycles=1000 | `FD_CB____AD_0000: instruction did not end within max T` |
| FD CB D AF | register-copy form | 1000 | cycles=1000 | `FD_CB____AF_0000: instruction did not end within max T` |
| FD CB D B0 | register-copy form | 1000 | cycles=1000 | `FD_CB____B0_0000: instruction did not end within max T` |
| FD CB D B1 | register-copy form | 1000 | cycles=1000 | `FD_CB____B1_0000: instruction did not end within max T` |
| FD CB D B2 | register-copy form | 1000 | pc=1, d=1, ram=1, cycles=1000, bus=1 | `FD_CB____B2_0000: instruction did not end within max T` |
| FD CB D B3 | register-copy form | 1000 | pc=1, e=1, cycles=1000, bus=1 | `FD_CB____B3_0000: instruction did not end within max T` |
| FD CB D B4 | register-copy form | 1000 | cycles=1000 | `FD_CB____B4_0000: instruction did not end within max T` |
| FD CB D B5 | register-copy form | 1000 | cycles=1000 | `FD_CB____B5_0000: instruction did not end within max T` |
| FD CB D B7 | register-copy form | 1000 | cycles=1000 | `FD_CB____B7_0000: instruction did not end within max T` |
| FD CB D B8 | register-copy form | 1000 | cycles=1000 | `FD_CB____B8_0000: instruction did not end within max T` |
| FD CB D B9 | register-copy form | 1000 | cycles=1000 | `FD_CB____B9_0000: instruction did not end within max T` |
| FD CB D BA | register-copy form | 1000 | cycles=1000 | `FD_CB____BA_0000: instruction did not end within max T` |
| FD CB D BB | register-copy form | 1000 | cycles=1000 | `FD_CB____BB_0000: instruction did not end within max T` |
| FD CB D BC | register-copy form | 1000 | cycles=1000 | `FD_CB____BC_0000: instruction did not end within max T` |
| FD CB D BD | register-copy form | 1000 | cycles=1000 | `FD_CB____BD_0000: instruction did not end within max T` |
| FD CB D BF | register-copy form | 1000 | cycles=1000 | `FD_CB____BF_0000: instruction did not end within max T` |
| FD CB D C0 | register-copy form | 1000 | cycles=1000 | `FD_CB____C0_0000: instruction did not end within max T` |
| FD CB D C1 | register-copy form | 1000 | cycles=1000 | `FD_CB____C1_0000: instruction did not end within max T` |
| FD CB D C2 | register-copy form | 1000 | cycles=1000 | `FD_CB____C2_0000: instruction did not end within max T` |
| FD CB D C3 | register-copy form | 1000 | cycles=1000 | `FD_CB____C3_0000: instruction did not end within max T` |
| FD CB D C4 | register-copy form | 1000 | cycles=1000 | `FD_CB____C4_0000: instruction did not end within max T` |
| FD CB D C5 | register-copy form | 1000 | cycles=1000 | `FD_CB____C5_0000: instruction did not end within max T` |
| FD CB D C7 | register-copy form | 1000 | cycles=1000 | `FD_CB____C7_0000: instruction did not end within max T` |
| FD CB D C8 | register-copy form | 1000 | cycles=1000 | `FD_CB____C8_0000: instruction did not end within max T` |
| FD CB D C9 | register-copy form | 1000 | cycles=1000 | `FD_CB____C9_0000: instruction did not end within max T` |
| FD CB D CA | register-copy form | 1000 | cycles=1000 | `FD_CB____CA_0000: instruction did not end within max T` |
| FD CB D CB | register-copy form | 1000 | cycles=1000 | `FD_CB____CB_0000: instruction did not end within max T` |
| FD CB D CC | register-copy form | 1000 | cycles=1000 | `FD_CB____CC_0000: instruction did not end within max T` |
| FD CB D CD | register-copy form | 1000 | pc=1, l=1, cycles=1000, bus=1 | `FD_CB____CD_0000: instruction did not end within max T` |
| FD CB D CF | register-copy form | 1000 | cycles=1000 | `FD_CB____CF_0000: instruction did not end within max T` |
| FD CB D D0 | register-copy form | 1000 | cycles=1000 | `FD_CB____D0_0000: instruction did not end within max T` |
| FD CB D D1 | register-copy form | 1000 | cycles=1000 | `FD_CB____D1_0000: instruction did not end within max T` |
| FD CB D D2 | register-copy form | 1000 | cycles=1000 | `FD_CB____D2_0000: instruction did not end within max T` |
| FD CB D D3 | register-copy form | 1000 | cycles=1000 | `FD_CB____D3_0000: instruction did not end within max T` |
| FD CB D D4 | register-copy form | 1000 | cycles=1000 | `FD_CB____D4_0000: instruction did not end within max T` |
| FD CB D D5 | register-copy form | 1000 | cycles=1000 | `FD_CB____D5_0000: instruction did not end within max T` |
| FD CB D D7 | register-copy form | 1000 | cycles=1000 | `FD_CB____D7_0000: instruction did not end within max T` |
| FD CB D D8 | register-copy form | 1000 | cycles=1000 | `FD_CB____D8_0000: instruction did not end within max T` |
| FD CB D D9 | register-copy form | 1000 | cycles=1000 | `FD_CB____D9_0000: instruction did not end within max T` |
| FD CB D DA | register-copy form | 1000 | cycles=1000 | `FD_CB____DA_0000: instruction did not end within max T` |
| FD CB D DB | register-copy form | 1000 | cycles=1000 | `FD_CB____DB_0000: instruction did not end within max T` |
| FD CB D DC | register-copy form | 1000 | cycles=1000 | `FD_CB____DC_0000: instruction did not end within max T` |
| FD CB D DD | register-copy form | 1000 | cycles=1000 | `FD_CB____DD_0000: instruction did not end within max T` |
| FD CB D DF | register-copy form | 1000 | cycles=1000 | `FD_CB____DF_0000: instruction did not end within max T` |
| FD CB D E0 | register-copy form | 1000 | pc=1, f=1, f53=1, b=1, cycles=1000, bus=1 | `FD_CB____E0_0000: instruction did not end within max T` |
| FD CB D E1 | register-copy form | 1000 | cycles=1000 | `FD_CB____E1_0000: instruction did not end within max T` |
| FD CB D E2 | register-copy form | 1000 | cycles=1000 | `FD_CB____E2_0000: instruction did not end within max T` |
| FD CB D E3 | register-copy form | 1000 | cycles=1000 | `FD_CB____E3_0000: instruction did not end within max T` |
| FD CB D E4 | register-copy form | 1000 | cycles=1000 | `FD_CB____E4_0000: instruction did not end within max T` |
| FD CB D E5 | register-copy form | 1000 | cycles=1000 | `FD_CB____E5_0000: instruction did not end within max T` |
| FD CB D E7 | register-copy form | 1000 | cycles=1000 | `FD_CB____E7_0000: instruction did not end within max T` |
| FD CB D E8 | register-copy form | 1000 | cycles=1000 | `FD_CB____E8_0000: instruction did not end within max T` |
| FD CB D E9 | register-copy form | 1000 | cycles=1000 | `FD_CB____E9_0000: instruction did not end within max T` |
| FD CB D EA | register-copy form | 1000 | cycles=1000 | `FD_CB____EA_0000: instruction did not end within max T` |
| FD CB D EB | register-copy form | 1000 | cycles=1000 | `FD_CB____EB_0000: instruction did not end within max T` |
| FD CB D EC | register-copy form | 1000 | cycles=1000 | `FD_CB____EC_0000: instruction did not end within max T` |
| FD CB D ED | register-copy form | 1000 | cycles=1000 | `FD_CB____ED_0000: instruction did not end within max T` |
| FD CB D EF | register-copy form | 1000 | cycles=1000 | `FD_CB____EF_0000: instruction did not end within max T` |
| FD CB D F0 | register-copy form | 1000 | cycles=1000 | `FD_CB____F0_0000: instruction did not end within max T` |
| FD CB D F1 | register-copy form | 1000 | cycles=1000 | `FD_CB____F1_0000: instruction did not end within max T` |
| FD CB D F2 | register-copy form | 1000 | cycles=1000 | `FD_CB____F2_0000: instruction did not end within max T` |
| FD CB D F3 | register-copy form | 1000 | cycles=1000 | `FD_CB____F3_0000: instruction did not end within max T` |
| FD CB D F4 | register-copy form | 1000 | cycles=1000 | `FD_CB____F4_0000: instruction did not end within max T` |
| FD CB D F5 | register-copy form | 1000 | cycles=1000 | `FD_CB____F5_0000: instruction did not end within max T` |
| FD CB D F7 | register-copy form | 1000 | cycles=1000 | `FD_CB____F7_0000: instruction did not end within max T` |
| FD CB D F8 | register-copy form | 1000 | cycles=1000 | `FD_CB____F8_0000: instruction did not end within max T` |
| FD CB D F9 | register-copy form | 1000 | cycles=1000 | `FD_CB____F9_0000: instruction did not end within max T` |
| FD CB D FA | register-copy form | 1000 | cycles=1000 | `FD_CB____FA_0000: instruction did not end within max T` |
| FD CB D FB | register-copy form | 1000 | cycles=1000 | `FD_CB____FB_0000: instruction did not end within max T` |
| FD CB D FC | register-copy form | 1000 | cycles=1000 | `FD_CB____FC_0000: instruction did not end within max T` |
| FD CB D FD | register-copy form | 1000 | cycles=1000 | `FD_CB____FD_0000: instruction did not end within max T` |
| FD CB D FF | register-copy form | 1000 | cycles=1000 | `FD_CB____FF_0000: instruction did not end within max T` |
| FD E3 | official | 1000 | bus=1000 | `FD_E3_0000: exp [MR:4B65=FD MR:4B66=E3 MR:61E8=59 MR:61E9=94 MW:61E9=F3 MW:61E8=A1] got [MR:4B65=FD MR:4B66=E3 MR:61E8=59 MW:61E8=A1 MR:61E9=94 MW:61E9=F3]` |

### tv80: opcodes with undocumented-only failures (f53 = flag bits 5/3 or Zilog "unknown" flags)

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|
| 37 | official | 229 | f53=229 | `37_0000: F exp 2D got 25` |
| 3F | official | 219 | f53=219 | `3F_0001: F exp ED got CD` |
| CB 46 | official | 734 | f53=734 | `CB_46_0000: F exp 19 got 11` |
| CB 4E | official | 758 | f53=758 | `CB_4E_0000: F exp 39 got 11` |
| CB 56 | official | 769 | f53=769 | `CB_56_0001: F exp 18 got 10` |
| CB 5E | official | 747 | f53=747 | `CB_5E_0001: F exp 31 got 11` |
| CB 66 | official | 751 | f53=751 | `CB_66_0000: F exp 18 got 10` |
| CB 6E | official | 761 | f53=761 | `CB_6E_0000: F exp 7C got 54` |
| CB 76 | official | 762 | f53=762 | `CB_76_0000: F exp 75 got 55` |
| CB 7E | official | 752 | f53=752 | `CB_7E_0000: F exp 5C got 54` |
| DD 37 | prefix on non-HL op / IXH,IXL | 454 | f53=454 | `DD_37_0001: F exp 65 got 45` |
| DD 3F | prefix on non-HL op / IXH,IXL | 440 | f53=440 | `DD_3F_0001: F exp 58 got 50` |
| DD CB D 46 | official | 764 | f53=764 | `DD_CB____46_0000: F exp 18 got 10` |
| DD CB D 4E | official | 734 | f53=734 | `DD_CB____4E_0000: F exp 18 got 10` |
| DD CB D 56 | official | 751 | f53=751 | `DD_CB____56_0000: F exp 75 got 55` |
| DD CB D 5E | official | 749 | f53=749 | `DD_CB____5E_0001: F exp 39 got 11` |
| DD CB D 66 | official | 745 | f53=745 | `DD_CB____66_0000: F exp 31 got 11` |
| DD CB D 6E | official | 724 | f53=724 | `DD_CB____6E_0001: F exp 30 got 10` |
| DD CB D 76 | official | 751 | f53=751 | `DD_CB____76_0001: F exp 5D got 55` |
| DD CB D 7E | official | 738 | f53=738 | `DD_CB____7E_0001: F exp B0 got 90` |
| ED 40 | official | 764 | f53=764 | `ED_40_0000: F exp 84 got AC` |
| ED 48 | official | 743 | f53=743 | `ED_48_0002: F exp A4 got AC` |
| ED 50 | official | 744 | f53=744 | `ED_50_0000: F exp 81 got 89` |
| ED 57 | official | 754 | f53=754 | `ED_57_0000: F exp 8D got 85` |
| ED 58 | official | 773 | f53=773 | `ED_58_0000: F exp 05 got 25` |
| ED 5F | official | 385 | f=477, f53=756 | `ED_5F_0000: F exp 20 got 00` |
| ED 60 | official | 748 | f53=748 | `ED_60_0001: F exp 01 got 09` |
| ED 68 | official | 752 | f53=752 | `ED_68_0000: F exp 2C got 24` |
| ED 6F | official | 1000 | bustime=1000 | `ED_6F_0000: MR:A681 at T12, test T9` |
| ED 70 | undocumented ED | 752 | f53=752 | `ED_70_0000: F exp A0 got 80` |
| ED 78 | official | 772 | f53=772 | `ED_78_0000: F exp 00 got 28` |
| ED A1 | official | 750 | f53=750 | `ED_A1_0000: F exp 9E got BE` |
| ED A2 | official | 1000 | f53=951, bustime=1000 | `ED_A2_0000: IR:6662 at T9, test T11` |
| ED A3 | official | 935 | f53=935 | `ED_A3_0000: F exp 97 got 82` |
| ED A9 | official | 752 | f53=752 | `ED_A9_0000: F exp 86 got A6` |
| ED AA | official | 1000 | f53=943, bustime=1000 | `ED_AA_0000: IR:FA88 at T9, test T11` |
| ED AB | official | 942 | f53=942 | `ED_AB_0000: F exp 8E got 8A` |
| ED B0 | official | 749 | f53=749 | `ED_B0_0001: F exp C4 got CC` |
| ED B1 | official | 740 | f53=740 | `ED_B1_0000: F exp 2F got 07` |
| ED B2 | official | 1000 | f53=987, bustime=1000 | `ED_B2_0000: IR:6D9D at T9, test T11` |
| ED B3 | official | 984 | f53=984 | `ED_B3_0000: F exp 0C got 0A` |
| ED B8 | official | 721 | f53=721 | `ED_B8_0000: F exp 45 got 4D` |
| ED B9 | official | 744 | f53=744 | `ED_B9_0000: F exp A7 got 8F` |
| ED BA | official | 1000 | f53=986, bustime=1000 | `ED_BA_0000: IR:6206 at T9, test T11` |
| ED BB | official | 987 | f53=987 | `ED_BB_0000: F exp 9F got A2` |
| FD 37 | prefix on non-HL op / IXH,IXL | 456 | f53=456 | `FD_37_0000: F exp A9 got A1` |
| FD 3F | prefix on non-HL op / IXH,IXL | 412 | f53=412 | `FD_3F_0000: F exp 69 got 49` |
| FD CB D 46 | official | 750 | f53=750 | `FD_CB____46_0001: F exp 31 got 11` |
| FD CB D 4E | official | 746 | f53=746 | `FD_CB____4E_0000: F exp 19 got 11` |
| FD CB D 56 | official | 732 | f53=732 | `FD_CB____56_0001: F exp 38 got 10` |
| FD CB D 5E | official | 740 | f53=740 | `FD_CB____5E_0000: F exp 74 got 54` |
| FD CB D 66 | official | 735 | f53=735 | `FD_CB____66_0002: F exp 74 got 54` |
| FD CB D 6E | official | 761 | f53=761 | `FD_CB____6E_0000: F exp 38 got 10` |
| FD CB D 76 | official | 754 | f53=754 | `FD_CB____76_0000: F exp 5D got 55` |
| FD CB D 7E | official | 745 | f53=745 | `FD_CB____7E_0000: F exp 75 got 55` |

### t80: SingleStepTests by group

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

### t80: opcodes with documented-behaviour failures

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|
| DD 13 | prefix on non-HL op / IXH,IXL | 1000 | b=2, c=1000, d=4, e=1000 | `DD_13_0000: exp E4 got E5` |
| DD 1B | prefix on non-HL op / IXH,IXL | 1000 | b=1, c=1000, d=1, e=1000 | `DD_1B_0000: exp 24 got 23` |
| DD E3 | official | 1000 | bus=1000 | `DD_E3_0000: exp [MR:A5E8=DD MR:A5E9=E3 MR:F86E=C0 MR:F86F=2B MW:F86F=76 MW:F86E=12] got [MR:A5E8=DD MR:A5E9=E3 MR:F86E=C0 MW:F86E=12 MR:F86F=2B MW:F86F=76]` |
| E3 | official | 1000 | bus=1000 | `E3_0000: exp [MR:69CA=E3 MR:6CFD=E4 MR:6CFE=E8 MW:6CFE=D7 MW:6CFD=49] got [MR:69CA=E3 MR:6CFD=E4 MW:6CFD=49 MR:6CFE=E8 MW:6CFE=D7]` |
| ED 77 | undocumented ED | 643 | im=643 | `ED_77_0000: exp 1 got 2` |
| ED 7E | undocumented ED | 670 | im=670 | `ED_7E_0002: exp 2 got 1` |
| FD 13 | prefix on non-HL op / IXH,IXL | 1000 | b=3, c=1000, d=3, e=1000 | `FD_13_0000: exp 77 got 78` |
| FD 1B | prefix on non-HL op / IXH,IXL | 1000 | b=4, c=1000, d=5, e=1000 | `FD_1B_0000: exp 99 got 98` |
| FD E3 | official | 1000 | bus=1000 | `FD_E3_0000: exp [MR:4B65=FD MR:4B66=E3 MR:61E8=59 MR:61E9=94 MW:61E9=F3 MW:61E8=A1] got [MR:4B65=FD MR:4B66=E3 MR:61E8=59 MW:61E8=A1 MR:61E9=94 MW:61E9=F3]` |

### t80: opcodes with undocumented-only failures (f53 = flag bits 5/3 or Zilog "unknown" flags)

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|
| 0A | official | 1000 | wz=1000 | `0A_0000: exp 5FCE got DAFA` |
| 1A | official | 1000 | wz=1000 | `1A_0000: exp 17B8 got A458` |
| 22 | official | 1000 | wz=1000 | `22_0000: exp C962 got C961` |
| 2A | official | 1000 | wz=1000 | `2A_0000: exp 4DCB got 4DCA` |
| 37 | official | 229 | f53=229 | `37_0000: F exp 2D got 25` |
| 3A | official | 1000 | wz=1000 | `3A_0000: exp 1005 got A204` |
| 3F | official | 219 | f53=219 | `3F_0001: F exp ED got CD` |
| C0 | official | 512 | wz=512 | `C0_0001: exp 6FDB got 42DB` |
| C8 | official | 498 | wz=498 | `C8_0000: exp 3337 got B937` |
| C9 | official | 996 | wz=996 | `C9_0000: exp EEC4 got 3BC4` |
| D0 | official | 484 | wz=484 | `D0_0004: exp 9B9E got 959E` |
| D3 | official | 4 | wz=4 | `D3_00BC: exp 9A00 got 9B00` |
| D8 | official | 454 | wz=454 | `D8_0000: exp E8D9 got 80D9` |
| DD 0A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `DD_0A_0000: exp B52B got E065` |
| DD 1A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `DD_1A_0000: exp C97A got 3E77` |
| DD 22 | official | 1000 | wz=1000 | `DD_22_0000: exp ECEB got ECEA` |
| DD 2A | official | 1000 | wz=1000 | `DD_2A_0000: exp 0601 got 0600` |
| DD 37 | prefix on non-HL op / IXH,IXL | 454 | f53=454 | `DD_37_0001: F exp 65 got 45` |
| DD 3A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `DD_3A_0000: exp 734F got 754E` |
| DD 3F | prefix on non-HL op / IXH,IXL | 440 | f53=440 | `DD_3F_0001: F exp 58 got 50` |
| DD C0 | prefix on non-HL op / IXH,IXL | 498 | wz=498 | `DD_C0_0001: exp 95BA got EBBA` |
| DD C8 | prefix on non-HL op / IXH,IXL | 507 | wz=507 | `DD_C8_0001: exp B179 got 9179` |
| DD C9 | prefix on non-HL op / IXH,IXL | 998 | wz=998 | `DD_C9_0000: exp D3AE got 44AE` |
| DD D0 | prefix on non-HL op / IXH,IXL | 491 | wz=491 | `DD_D0_0002: exp E884 got E084` |
| DD D3 | prefix on non-HL op / IXH,IXL | 4 | wz=4 | `DD_D3_02A7: exp 6100 got 6200` |
| DD D8 | prefix on non-HL op / IXH,IXL | 490 | wz=490 | `DD_D8_0000: exp 4224 got E124` |
| DD E0 | prefix on non-HL op / IXH,IXL | 508 | wz=508 | `DD_E0_0002: exp EC2B got 612B` |
| DD E8 | prefix on non-HL op / IXH,IXL | 475 | wz=475 | `DD_E8_0001: exp D054 got F254` |
| DD F0 | prefix on non-HL op / IXH,IXL | 462 | wz=462 | `DD_F0_0000: exp 116B got CB6B` |
| DD F8 | prefix on non-HL op / IXH,IXL | 498 | wz=498 | `DD_F8_0000: exp 2676 got C976` |
| E0 | official | 531 | wz=531 | `E0_0000: exp 34AB got 3AAB` |
| E8 | official | 521 | wz=521 | `E8_0000: exp F3DA got EEDA` |
| ED 43 | official | 1000 | wz=1000 | `ED_43_0000: exp 88EC got 88EB` |
| ED 4B | official | 1000 | wz=1000 | `ED_4B_0000: exp BCA7 got BCA6` |
| ED 53 | official | 1000 | wz=1000 | `ED_53_0000: exp CBF0 got CBEF` |
| ED 5B | official | 1000 | wz=1000 | `ED_5B_0000: exp 48CC got 48CB` |
| ED 63 | undocumented ED | 1000 | wz=1000 | `ED_63_0000: exp 116C got 116B` |
| ED 67 | official | 1000 | wz=1000 | `ED_67_0000: exp 0990 got 62E8` |
| ED 6B | undocumented ED | 1000 | wz=1000 | `ED_6B_0000: exp 8EF9 got 8EF8` |
| ED 6F | official | 1000 | wz=1000 | `ED_6F_0000: exp A682 got 8D06` |
| ED 73 | official | 1000 | wz=1000 | `ED_73_0000: exp A7DC got A7DB` |
| ED 7B | official | 1000 | wz=1000 | `ED_7B_0000: exp 7395 got 7394` |
| ED A1 | official | 1000 | wz=1000 | `ED_A1_0000: exp 90A2 got 90A1` |
| ED A9 | official | 1000 | wz=1000 | `ED_A9_0000: exp 4DF6 got 4DF7` |
| ED B0 | official | 749 | f53=749 | `ED_B0_0001: F exp C4 got CC` |
| ED B1 | official | 730 | f53=727, wz=3 | `ED_B1_0000: F exp 2F got 27` |
| ED B2 | official | 995 | f53=930, wz=995 | `ED_B2_0000: exp 7BD8 got 6D9E` |
| ED B3 | official | 999 | f53=925, wz=999 | `ED_B3_0000: exp 5E37 got 48EB` |
| ED B8 | official | 721 | f53=721 | `ED_B8_0000: F exp 45 got 4D` |
| ED B9 | official | 762 | f53=762 | `ED_B9_0000: F exp A7 got 87` |
| ED BA | official | 996 | f53=931, wz=996 | `ED_BA_0000: exp 4777 got 6205` |
| ED BB | official | 1000 | f53=937, wz=1000 | `ED_BB_0000: exp DD60 got E09F` |
| F0 | official | 467 | wz=467 | `F0_0003: exp D55C got EF5C` |
| F8 | official | 479 | wz=479 | `F8_0000: exp 0D36 got 1B36` |
| FD 0A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `FD_0A_0000: exp ACD8 got 8043` |
| FD 1A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `FD_1A_0000: exp 5D1F got C29A` |
| FD 22 | official | 1000 | wz=1000 | `FD_22_0000: exp 41CA got 41C9` |
| FD 2A | official | 1000 | wz=1000 | `FD_2A_0000: exp CFBF got CFBE` |
| FD 37 | prefix on non-HL op / IXH,IXL | 456 | f53=456 | `FD_37_0000: F exp A9 got A1` |
| FD 3A | prefix on non-HL op / IXH,IXL | 1000 | wz=1000 | `FD_3A_0000: exp BC98 got 9897` |
| FD 3F | prefix on non-HL op / IXH,IXL | 412 | f53=412 | `FD_3F_0000: F exp 69 got 49` |
| FD C0 | prefix on non-HL op / IXH,IXL | 521 | wz=521 | `FD_C0_0000: exp D662 got DB62` |
| FD C8 | prefix on non-HL op / IXH,IXL | 502 | wz=502 | `FD_C8_0000: exp 8BBD got EEBD` |
| FD C9 | prefix on non-HL op / IXH,IXL | 991 | wz=991 | `FD_C9_0001: exp 810F got F90F` |
| FD D0 | prefix on non-HL op / IXH,IXL | 496 | wz=496 | `FD_D0_0000: exp 2FE1 got 2BE1` |
| FD D3 | prefix on non-HL op / IXH,IXL | 3 | wz=3 | `FD_D3_00A5: exp 5500 got 5600` |
| FD D8 | prefix on non-HL op / IXH,IXL | 487 | wz=487 | `FD_D8_0000: exp 7608 got 1008` |
| FD E0 | prefix on non-HL op / IXH,IXL | 510 | wz=510 | `FD_E0_0000: exp FA0A got 9B0A` |
| FD E8 | prefix on non-HL op / IXH,IXL | 501 | wz=501 | `FD_E8_0001: exp 3EF1 got 88F1` |
| FD F0 | prefix on non-HL op / IXH,IXL | 470 | wz=470 | `FD_F0_0005: exp EC7A got 0C7A` |
| FD F8 | prefix on non-HL op / IXH,IXL | 488 | wz=488 | `FD_F8_0001: exp 0C4E got AD4E` |

