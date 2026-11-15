#!/bin/sh
# quick: run tv80 SST on given opcode files (names as in vectors/sst_txt without .txt); print op tests pass ...
cd "$(dirname "$0")/.."
for op in "$@"; do ./obj_tv80/Vtv80e --verbose 0 --delta 0 1 0 --delta 0 0 0 --delta 1 0 0 --delta 2 0 -1 --delta 3 0 -1 sst vectors/sst_txt/$op.txt 2>/dev/null | cut -f1-5; done
