#!/usr/bin/env python3
"""Targeted validation for the OCR reliability research package."""
import csv, hashlib, re, subprocess, sys
from collections import Counter
from pathlib import Path

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[1]
required=['report.md','run-events.csv','provider-timeline.csv','reliability-by-period.csv','chart-timeseries.csv','reliability-over-time.svg','reliability-over-time.png','generate-reliability-chart.py','evidence-index.md','methodology.md','commands.md','source-extracts.md','cost-evidence.md','file-inventory.txt','validation.py']
errors=[]
def check(ok,msg):
    print(('PASS' if ok else 'FAIL'),msg)
    if not ok: errors.append(msg)

check(all((BASE/x).exists() for x in required),'all 15 required artifacts exist')
with (BASE/'run-events.csv').open(newline='') as f:
    rd=csv.DictReader(f); events=list(rd); check(len(rd.fieldnames)==len(set(rd.fieldnames)),'run-events headers unique')
check(len(events)==145,'run-events has 145 rows')
check(len({r['event_id'] for r in events})==145,'event IDs unique')
check(len({tuple(r['source_path'].split(';')) for r in events})==145,'canonical source sets unique')
out=Counter(r['outcome'] for r in events)
check(out=={'success':117,'partial':25,'failure':3},f'outcome aggregate exact: {dict(out)}')
prov=Counter((r['provider'],r['outcome']) for r in events)
expected={('Z.ai','success'):66,('Z.ai','partial'):13,('Z.ai','failure'):1,('StepFun','success'):26,('StepFun','partial'):12,('StepFun','failure'):2,('unknown','success'):25}
check(prov==expected,f'provider aggregate exact: {dict(prov)}')
check(sum('HTTP 429' in r['notes'] for r in events)==19,'19 partial HTTP 429 causes')
check(sum('HTTP 529' in r['notes'] for r in events)==6,'6 partial HTTP 529 causes')
for name,n in [('provider-timeline.csv',8),('reliability-by-period.csv',7),('chart-timeseries.csv',5)]:
    with (BASE/name).open(newline='') as f: rows=list(csv.DictReader(f))
    check(len(rows)==n,f'{name} has {n} data rows')
if (BASE/'reliability-by-period.csv').exists():
    pr=list(csv.DictReader((BASE/'reliability-by-period.csv').open()))
    check(sum(int(r['attempts']) for r in pr)==145,'period attempts sum to canonical events')
    check(sum(int(r['successes']) for r in pr)==117 and sum(int(r['partials']) for r in pr)==25 and sum(int(r['hard_failures']) for r in pr)==3,'period outcomes sum exactly')
if (BASE/'chart-timeseries.csv').exists():
    cr=list(csv.DictReader((BASE/'chart-timeseries.csv').open()))
    check(sum(int(r['attempts']) for r in cr)==145,'chart attempts sum to canonical events')
    check(sum(int(r['successes']) for r in cr)==117 and sum(int(r['partials']) for r in cr)==25 and sum(int(r['failures']) for r in cr)==3,'chart outcomes sum exactly')
check((BASE/'reliability-over-time.svg').read_text().lstrip().startswith('<svg'),'SVG has SVG root')
check((BASE/'reliability-over-time.png').read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),'PNG has valid signature')
# Relative Markdown links within package and parent research tree.
for p in BASE.glob('*.md'):
    text=p.read_text()
    for link in re.findall(r'\]\(([^)]+)\)',text):
        if link.startswith(('http://','https://','#')): continue
        check((p.parent/link.split('#')[0]).resolve().exists(),f'relative link exists: {p.name} -> {link}')
# Credential scan: long opaque values and common secret/header patterns.
scan='\n'.join(p.read_text(errors='ignore') for p in BASE.iterdir() if p.suffix not in ('.png',) and p.name!='file-inventory.txt')
patterns=[r'(?i)authorization\s*:\s*bearer\s+[A-Za-z0-9._-]{8,}',r'(?i)(?:api[_ -]?key|token|secret|password)\s*[=:]\s*["\x27]?[A-Za-z0-9._-]{16,}',r'\bsk-[A-Za-z0-9_-]{12,}\b']
check(not any(re.search(x,scan) for x in patterns),'credential scan clean')
# Inventory hashes every final file except inventory itself.
inv={}
if (BASE/'file-inventory.txt').exists():
    for line in (BASE/'file-inventory.txt').read_text().splitlines()[1:]:
        if not line: continue
        path,size,sha=line.split('\t'); inv[path]=(int(size),sha)
for p in sorted(BASE.iterdir()):
    if not p.is_file() or p.name in ('file-inventory.txt','.harvest.py','.finalize.py'): continue
    rel=str(p.relative_to(ROOT)); got=(p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest())
    check(inv.get(rel)==got,f'inventory matches {p.name}')
print(f'RESULT checks_complete errors={len(errors)}')
sys.exit(bool(errors))
