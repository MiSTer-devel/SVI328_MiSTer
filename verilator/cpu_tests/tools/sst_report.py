#!/usr/bin/env python3
"""Summarise SingleStepTests results (sst_main.cpp output) as Markdown.

usage: python3 -I sst_report.py results/tv80_sst.tsv results/t80_sst.tsv > results/summary.md

Input columns: file, tests, pass, doc_fail, undoc_only, field=count,..., cycle hist,
examples (field|example ;; ...), strobe offsets.
"""
import sys

ED_OFFICIAL = {0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B, 0x4D, 0x4F,
               0x50, 0x51, 0x52, 0x53, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x5E, 0x5F,
               0x60, 0x61, 0x62, 0x67, 0x68, 0x69, 0x6A, 0x6F, 0x72, 0x73, 0x78, 0x79, 0x7A, 0x7B,
               0xA0, 0xA1, 0xA2, 0xA3, 0xA8, 0xA9, 0xAA, 0xAB, 0xB0, 0xB1, 0xB2, 0xB3, 0xB8, 0xB9, 0xBA, 0xBB}
XY_OFFICIAL = {0x09, 0x19, 0x21, 0x22, 0x23, 0x29, 0x2A, 0x2B, 0x34, 0x35, 0x36, 0x39, 0x46, 0x4E, 0x56,
               0x5E, 0x66, 0x6E, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x77, 0x7E, 0x86, 0x8E, 0x96, 0x9E,
               0xA6, 0xAE, 0xB6, 0xBE, 0xE1, 0xE3, 0xE5, 0xE9, 0xF9}
GROUPS = ['base', 'CB', 'ED', 'DD', 'FD', 'DDCB', 'FDCB']


def classify(name):
    t = name.split('_')
    t = [x for x in t if x]
    if t[0] == 'cb':
        op = int(t[1], 16)
        return 'CB', 'SLL' if 0x30 <= op <= 0x37 else None
    if t[0] == 'ed':
        op = int(t[1], 16)
        return 'ED', None if op in ED_OFFICIAL else 'undocumented ED'
    if t[0] in ('dd', 'fd'):
        g = t[0].upper()
        if t[1] == 'cb':
            op = int(t[2], 16)
            return g + 'CB', None if (op & 7) == 6 else 'register-copy form'
        op = int(t[1], 16)
        return g, None if op in XY_OFFICIAL else 'prefix on non-HL op / IXH,IXL'
    return 'base', None


def load(path):
    rows = []
    for line in open(path):
        c = line.rstrip('\n').split('\t')
        if len(c) < 5:
            continue
        while len(c) < 9:
            c.append('')
        rows.append(dict(file=c[0], tests=int(c[1]), npass=int(c[2]), doc=int(c[3]), undoc=int(c[4]),
                         fields=c[5], hist=c[6], ex=c[7], strobes=c[8]))
    return rows


def table(rows, cpu):
    out = ['### %s: SingleStepTests by group' % cpu, '',
           '| group | opcodes | tests | pass | fail (documented behaviour) | fail (undocumented flags/WZ/strobe timing only) |',
           '|---|---|---|---|---|---|']
    for g in GROUPS:
        for off in (True, False):
            rs = [r for r in rows if classify(r['file'])[0] == g and (classify(r['file'])[1] is None) == off]
            if not rs:
                continue
            lab = g + (' (official)' if off else ' (undocumented opcodes)')
            out.append('| %s | %d | %d | %d | %d | %d |' % (
                lab, len(rs), sum(r['tests'] for r in rs), sum(r['npass'] for r in rs),
                sum(r['doc'] for r in rs), sum(r['undoc'] for r in rs)))
    t = rows
    out.append('| **all** | %d | %d | %d | %d | %d |' % (len(t), sum(r['tests'] for r in t), sum(r['npass'] for r in t),
                                                     sum(r['doc'] for r in t), sum(r['undoc'] for r in t)))
    out.append('')
    return out


def failures(rows, cpu, doc):
    key = 'doc' if doc else 'undoc'
    out = ['### %s: opcodes with %s' % (cpu, 'documented-behaviour failures' if doc else
                                        'undocumented-only failures (f53 = flag bits 5/3 or Zilog "unknown" flags)'), '',
           '| opcode | kind | failing tests | fields | first example |', '|---|---|---|---|---|']
    for r in rows:
        if r[key] == 0:
            continue
        g, u = classify(r['file'])
        parts = [x for x in r['file'].split('_') if x]
        if len(parts) == 3:
            parts.insert(2, 'd')
        name = ' '.join(parts).upper()
        cnt = dict(kv.split('=') for kv in r['fields'].split(',') if '=' in kv)
        ex = sorted(r['ex'].split(' ;; '), key=lambda e: -int(cnt.get(e.split('|')[0], 0)))
        # first example of a field that makes it a failure of this kind
        pick = ex[0]
        for e in ex:
            f = e.split('|')[0]
            if doc and f not in ('f53', 'wz', 'q', 'bustime'):
                pick = e
                break
        out.append('| %s | %s | %d | %s | `%s` |' % (name, u or 'official', r[key], r['fields'].replace(',', ', '),
                                                    pick.split('|', 1)[-1].replace('|', '/')))
    out.append('')
    return out


def main():
    out = ['# SingleStepTests/z80 results', '']
    for path in sys.argv[1:]:
        cpu = path.split('/')[-1].split('_')[0]
        rows = load(path)
        out += table(rows, cpu)
        out += failures(rows, cpu, True)
        out += failures(rows, cpu, False)
    print('\n'.join(out))


if __name__ == '__main__':
    main()
