#!/usr/bin/env python3
"""Convert SingleStepTests/z80 JSON files to the flat text format read by sst_main.cpp.

usage: python3 -I sst_convert.py IN_DIR OUT_DIR

One output file per input file, same base name with spaces -> '_' and .txt.
Per test:
  T name
  I pc sp a b c d e f h l i r ei wz ix iy af_ bc_ de_ hl_ im p q iff1 iff2
  M n  addr val ...          initial RAM
  F (same 25 fields as I)    final registers
  N n  addr val ...          final RAM
  C ncycles
  X n  tidx kind addr data ... bus transactions; kind 0=mem rd 1=mem wr 2=io rd 3=io wr
  P n  addr val dir ...      ports (dir 0=r 1=w)
Only reads the JSON as data.
"""
import json, os, sys

REGS = ['pc', 'sp', 'a', 'b', 'c', 'd', 'e', 'f', 'h', 'l', 'i', 'r', 'ei', 'wz', 'ix', 'iy',
        'af_', 'bc_', 'de_', 'hl_', 'im', 'p', 'q', 'iff1', 'iff2']
KIND = {'r-m-': 0, '-wm-': 1, 'r--i': 2, '-w-i': 3}


def conv(t):
    out = ['T ' + t['name'].replace(' ', '_')]
    for tag, key in (('I', 'initial'), ('F', 'final')):
        s = t[key]
        out.append(tag + ' ' + ' '.join(str(int(s.get(r, 0))) for r in REGS))
        ram = s['ram']
        out.append(('M' if tag == 'I' else 'N') + ' %d ' % len(ram) +
                   ' '.join('%d %d' % (a, v) for a, v in ram))
    cyc = t['cycles']
    out.append('C %d' % len(cyc))
    tr = []
    for i, (a, d, p) in enumerate(cyc):
        if p in KIND:
            k = KIND[p]
            if k in (0, 2):  # read: data appears on the following sample
                dd = None
                for j in range(i, min(i + 3, len(cyc))):
                    if cyc[j][1] is not None:
                        dd = cyc[j][1]
                        break
                d = dd
            tr.append('%d %d %d %d' % (i, k, a, -1 if d is None else d))
        elif p != '----':
            tr.append('%d %d %d %d' % (i, 9, a, -1))  # unknown pin combination
    out.append('X %d ' % len(tr) + ' '.join(tr))
    ports = t.get('ports') or []
    out.append('P %d ' % len(ports) + ' '.join('%d %d %d' % (a, v, 0 if d == 'r' else 1)
                                             for a, v, d in ports))
    return '\n'.join(out) + '\n'


def main():
    src, dst = sys.argv[1], sys.argv[2]
    os.makedirs(dst, exist_ok=True)
    for fn in sorted(os.listdir(src)):
        if not fn.endswith('.json'):
            continue
        of = os.path.join(dst, fn[:-5].replace(' ', '_') + '.txt')
        if os.path.exists(of) and os.path.getmtime(of) >= os.path.getmtime(os.path.join(src, fn)):
            continue
        with open(os.path.join(src, fn)) as f:
            tests = json.load(f)
        with open(of + '.tmp', 'w') as f:
            for t in tests:
                f.write(conv(t))
        os.replace(of + '.tmp', of)


if __name__ == '__main__':
    main()
