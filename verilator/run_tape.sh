#!/bin/sh
# run_tape.sh OUTDIR TAPE CMD1 [CMD2_FRAME CMD2] -- load a tape and log; extra args passed through
out=$1; tape=$2; shift 2
mkdir -p "$out"
exec ${SIM:-./obj_dir/Vsvi_sim} --tape "$tape" --tape-log --text-end --every 500 --outdir "$out" "$@" > "$out/log.txt" 2>&1
