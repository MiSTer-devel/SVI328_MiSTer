# SingleStepTests/z80 results

### t80sv: SingleStepTests by group

| group | opcodes | tests | pass | fail (documented behaviour) | fail (undocumented flags/WZ/strobe timing only) |
|---|---|---|---|---|---|
| base (official) | 252 | 252000 | 252000 | 0 | 0 |
| CB (official) | 248 | 248000 | 248000 | 0 | 0 |
| CB (undocumented opcodes) | 8 | 8000 | 8000 | 0 | 0 |
| ED (official) | 56 | 56000 | 56000 | 0 | 0 |
| ED (undocumented opcodes) | 24 | 24000 | 24000 | 0 | 0 |
| DD (official) | 39 | 39000 | 39000 | 0 | 0 |
| DD (undocumented opcodes) | 213 | 213000 | 213000 | 0 | 0 |
| FD (official) | 39 | 39000 | 39000 | 0 | 0 |
| FD (undocumented opcodes) | 213 | 213000 | 213000 | 0 | 0 |
| DDCB (official) | 32 | 32000 | 32000 | 0 | 0 |
| DDCB (undocumented opcodes) | 224 | 224000 | 224000 | 0 | 0 |
| FDCB (official) | 32 | 32000 | 32000 | 0 | 0 |
| FDCB (undocumented opcodes) | 224 | 224000 | 224000 | 0 | 0 |
| **all** | 1604 | 1604000 | 1604000 | 0 | 0 |

### t80sv: opcodes with documented-behaviour failures

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|

### t80sv: opcodes with undocumented-only failures (f53 = flag bits 5/3 or Zilog "unknown" flags)

| opcode | kind | failing tests | fields | first example |
|---|---|---|---|---|

