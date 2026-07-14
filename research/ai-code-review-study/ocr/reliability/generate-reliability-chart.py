#!/usr/bin/env python3
"""Generate reliability aggregates and dependency-free SVG/PNG charts."""
import csv, struct, zlib
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

BASE=Path(__file__).resolve().parent
rows=list(csv.DictReader((BASE/'run-events.csv').open()))
periods=[
 ('P0','Retained pre-attribution','0001-01-01T00:00:00+00:00','2026-07-10T18:36:04-03:00','unknown'),
 ('P1','Z.ai first retained interval','2026-07-10T18:36:04-03:00','2026-07-12T19:48:16-03:00','Z.ai'),
 ('P2','StepFun first interval','2026-07-12T19:48:16-03:00','2026-07-13T15:43:41-03:00','StepFun'),
 ('P3','Z.ai return interval','2026-07-13T15:43:41-03:00','2026-07-13T21:21:51-03:00','Z.ai'),
 ('P4','StepFun Pro interval','2026-07-13T21:21:51-03:00','2026-07-14T04:56:23-03:00','StepFun Pro'),
 ('P5','StepFun Max interval','2026-07-14T04:56:23-03:00','2026-07-14T12:46:25-03:00','StepFun Max'),
 ('P6','Z.ai fallback interval','2026-07-14T12:46:25-03:00','9999-12-31T23:59:59+00:00','Z.ai'),
]
def dt(s): return datetime.fromisoformat(s)
def pct(n,d): return f'{100*n/d:.1f}' if d else '0.0'
period_out=[]
for pid,label,start,end,provider in periods:
    a=[r for r in rows if dt(start)<=dt(r['timestamp_local'])<dt(end)]
    c=Counter(r['outcome'] for r in a); fc=Counter(r['failure_class'] for r in a)
    p429=sum('HTTP 429' in r['notes'] or r['failure_class']=='provider HTTP 429/rate limit' for r in a)
    p529=sum('HTTP 529' in r['notes'] or r['failure_class']=='network/server error' for r in a)
    period_out.append({'period_id':pid,'period':label,'start_local':start,'end_local_exclusive':end,
      'configured_provider_or_tier':provider,'attempts':len(a),'successes':c['success'],'success_pct':pct(c['success'],len(a)),
      'partials':c['partial'],'partial_pct':pct(c['partial'],len(a)),'hard_failures':c['failure'],
      'hard_failure_pct':pct(c['failure'],len(a)),'usable_outputs':c['success']+c['partial'],
      'usable_output_pct':pct(c['success']+c['partial'],len(a)),'http_429_affected':p429,'http_529_affected':p529,
      'auth_config_failures':fc['authentication/config failure']})
with (BASE/'reliability-by-period.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(period_out[0])); w.writeheader(); w.writerows(period_out)

daily=defaultdict(Counter)
for r in rows: daily[r['timestamp_local'][:10]][r['outcome']]+=1
trans={'2026-07-10':'Z.ai snapshot','2026-07-12':'StepFun first interval','2026-07-13':'Z.ai→StepFun','2026-07-14':'Pro→Max→Z.ai'}
chart=[]
for day in sorted(daily):
    c=daily[day]; chart.append({'date':day,'attempts':sum(c.values()),'successes':c['success'],'partials':c['partial'],
      'failures':c['failure'],'usable_outputs':c['success']+c['partial'],'provider_transition':trans.get(day,'')})
with (BASE/'chart-timeseries.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(chart[0])); w.writeheader(); w.writerows(chart)

W,H=1100,650; L,R,T,B=90,40,70,110; pw=W-L-R; ph=H-T-B
maxy=max(x['attempts'] for x in chart); ymax=((maxy+9)//10)*10
def x(i): return L+(i+0.5)*pw/len(chart)
def y(v): return T+ph-v*ph/ymax
colors={'successes':'#2e7d32','partials':'#f9a825','failures':'#c62828'}
parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
 '<rect width="100%" height="100%" fill="white"/>','<text x="90" y="34" font-family="sans-serif" font-size="24" font-weight="bold">OCR reliability over retained local attempts</text>',
 '<text x="90" y="56" font-family="sans-serif" font-size="13" fill="#555">Attempt outcome by local completion date; partial output is not full coverage</text>']
for v in range(0,ymax+1,10):
    yy=y(v); parts += [f'<line x1="{L}" y1="{yy}" x2="{W-R}" y2="{yy}" stroke="#ddd"/>',f'<text x="{L-12}" y="{yy+5}" text-anchor="end" font-family="sans-serif" font-size="12">{v}</text>']
bw=pw/len(chart)*0.48
for i,row in enumerate(chart):
    bottom=0
    for key in ('successes','partials','failures'):
        val=row[key]; yy=y(bottom+val); hh=y(bottom)-yy
        parts.append(f'<rect x="{x(i)-bw/2:.1f}" y="{yy:.1f}" width="{bw:.1f}" height="{hh:.1f}" fill="{colors[key]}"/>'); bottom+=val
    parts += [f'<text x="{x(i):.1f}" y="{y(row["attempts"])-8:.1f}" text-anchor="middle" font-family="sans-serif" font-size="12">n={row["attempts"]}</text>',
      f'<text x="{x(i):.1f}" y="{H-B+22}" text-anchor="middle" font-family="sans-serif" font-size="12">{row["date"][5:]}</text>',
      f'<text x="{x(i):.1f}" y="{H-B+43}" text-anchor="middle" font-family="sans-serif" font-size="10" fill="#555">{row["provider_transition"]}</text>']
parts.append(f'<line x1="{L}" y1="{T+ph}" x2="{W-R}" y2="{T+ph}" stroke="#333"/>')
lx=180
for key,label in [('successes','Success'),('partials','Partial/subtask failure'),('failures','Hard failure')]:
    parts += [f'<rect x="{lx}" y="{H-35}" width="16" height="16" fill="{colors[key]}"/>',f'<text x="{lx+23}" y="{H-22}" font-family="sans-serif" font-size="13">{label}</text>']; lx += 180 if key!='partials' else 240
parts.append('</svg>')
(BASE/'reliability-over-time.svg').write_text('\n'.join(parts))

# Minimal RGB PNG with equivalent stacked bars and axes.
pix=bytearray([255]*(W*H*3))
def rect(x0,y0,x1,y1,c):
    for yy in range(max(0,int(y0)),min(H,int(y1))):
        for xx in range(max(0,int(x0)),min(W,int(x1))):
            k=(yy*W+xx)*3; pix[k:k+3]=bytes(c)
def line(x0,y0,x1,y1,c):
    if y0==y1: rect(x0,y0,x1+1,y0+1,c)
for v in range(0,ymax+1,10): line(L,int(y(v)),W-R,int(y(v)),(220,220,220))
line(L,T+ph,W-R,T+ph,(30,30,30))
rgb={'successes':(46,125,50),'partials':(249,168,37),'failures':(198,40,40)}
for i,row in enumerate(chart):
    bottom=0
    for key in ('successes','partials','failures'):
        val=row[key]; rect(x(i)-bw/2,y(bottom+val),x(i)+bw/2,y(bottom),rgb[key]); bottom+=val
raw=b''.join(b'\x00'+bytes(pix[r*W*3:(r+1)*W*3]) for r in range(H))
def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',W,H,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b'')
(BASE/'reliability-over-time.png').write_bytes(png)
print(f'events={len(rows)} periods={len(period_out)} chart_rows={len(chart)} svg={len((BASE/"reliability-over-time.svg").read_bytes())} png={len(png)}')
