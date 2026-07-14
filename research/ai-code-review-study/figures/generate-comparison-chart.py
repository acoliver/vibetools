#!/usr/bin/env python3
"""Generate comparison-performance SVG and CSV for the megareport.

Renders four panels that compare OCR and CodeRabbit on the six-PR exact-head
matched cohort. Each panel uses its own denominator, clearly labeled, so that
incompatible metrics are never shown as if they share a scale.
"""
import csv
from pathlib import Path
from xml.sax.saxutils import escape

BASE = Path(__file__).resolve().parent
SVG = BASE / "comparison-performance.svg"
PNG = BASE / "comparison-performance.png"

OCR_COLOR = "#7c3aed"
CR_COLOR = "#0891b2"

# ---------------------------------------------------------------------------
# Panels: (title, subtitle/denominator, ocr_label, ocr_value,
#          cr_label, cr_value, y_max, value_format)
# ---------------------------------------------------------------------------
PANELS = [
    {
        "title": "Normalized findings emitted",
        "subtitle": "Same six exact-head iterations",
        "ocr": ("74", 74),
        "cr": ("31", 31),
        "y_max": 85,
        "fmt": "{:.0f}",
    },
    {
        "title": "Duplicate rate",
        "subtitle": "Within-reviewer repeated comments",
        "ocr": ("12.9%", 12.9),
        "cr": ("3.1%", 3.1),
        "y_max": 20,
        "fmt": "{:.1f}%",
    },
    {
        "title": "Valid-or-partial among adjudicated",
        "subtitle": "OCR 13/16 adjudicated; CR 10/12 adjudicated",
        "ocr": ("81.3%", 81.3),
        "cr": ("83.3%", 83.3),
        "y_max": 100,
        "fmt": "{:.1f}%",
    },
    {
        "title": "Overlap & unadjudicated share",
        "subtitle": "Classified semantic union n=46; classified rows n=56",
        "ocr": ("Overlap 21.7%", 21.7),
        "cr": ("Unadjud. 50.0%", 50.0),
        "y_max": 60,
        "fmt": "{:.1f}%",
    },
]

width, height = 1000, 880
left, right, top = 90, 40, 96
panel_h, gap = 160, 30
plot_w = width - left - right
font = "font-family='-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif'"

parts = [
    f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}'"
    f" viewBox='0 0 {width} {height}'>",
    "<rect width='100%' height='100%' fill='white'/>",
    f"<text x='{left}' y='34' font-size='22' font-weight='700' {font}>"
    "OCR vs CodeRabbit: six-PR exact-head matched cohort</text>",
    f"<text x='{left}' y='57' font-size='13' fill='#475569' {font}>"
    "Each panel uses a distinct denominator. Small differences are descriptive, not superiority proof.</text>",
]

# Legend
for i, (label, color) in enumerate([("OCR", OCR_COLOR), ("CodeRabbit", CR_COLOR)]):
    x = 640 + i * 160
    parts.append(
        f"<rect x='{x}' y='74' width='24' height='14' fill='{color}' rx='2'/>"
    )
    parts.append(
        f"<text x='{x + 31}' y='86' font-size='13' fill='#334155' {font}>{label}</text>"
    )

bar_w = 60
for pi, panel in enumerate(PANELS):
    y_top = top + pi * (panel_h + gap)
    y_bot = y_top + panel_h

    parts.append(
        f"<text x='{left}' y='{y_top - 12}' font-size='15' font-weight='650' "
        f"fill='#0f172a' {font}>{escape(panel['title'])}</text>"
    )
    parts.append(
        f"<text x='{left + plot_w}' y='{y_top - 12}' text-anchor='end' "
        f"font-size='11' fill='#64748b' {font}>{escape(panel['subtitle'])}</text>"
    )

    # Grid
    for gi in range(5):
        val = panel["y_max"] * gi / 4
        gy = y_bot - panel_h * gi / 4
        parts.append(
            f"<line x1='{left}' y1='{gy:.1f}' x2='{left+plot_w}' y2='{gy:.1f}'"
            f" stroke='#e2e8f0' stroke-width='1'/>"
        )
        if panel["fmt"].endswith("%"):
            label = panel["fmt"].format(val)
        else:
            label = panel["fmt"].format(val)
        parts.append(
            f"<text x='{left-10}' y='{gy+4:.1f}' text-anchor='end' "
            f"font-size='11' fill='#64748b' {font}>{label}</text>"
        )

    # Bars
    center = left + plot_w / 2
    for bi, (txt, val, color, name) in enumerate([
        (*panel["ocr"], OCR_COLOR, "OCR"),
        (*panel["cr"], CR_COLOR, "CodeRabbit"),
    ]):
        bx = center - 95 + bi * 130 - bar_w / 2
        bh = panel_h * val / panel["y_max"]
        by = y_bot - bh
        parts.append(
            f"<rect x='{bx:.1f}' y='{by:.1f}' width='{bar_w}' height='{bh:.1f}'"
            f" fill='{color}' rx='3'/>"
        )
        parts.append(
            f"<text x='{bx+bar_w/2:.1f}' y='{by-8:.1f}' text-anchor='middle' "
            f"font-size='15' font-weight='700' fill='#0f172a' {font}>{escape(txt)}</text>"
        )
        parts.append(
            f"<text x='{bx+bar_w/2:.1f}' y='{y_bot+18:.1f}' text-anchor='middle' "
            f"font-size='12' fill='#475569' {font}>{name}</text>"
        )

parts.append(
    f"<text x='{left}' y='{height-14}' font-size='11' fill='#64748b' {font}>"
    "Source: comparison/sources/matched-prs.csv, matched-findings.csv, semantic-overlap.csv. "
    "Panel 4 compares different metrics: overlap Jaccard (OCR series) vs unadjudicated share (CR series).</text>"
)
parts.append("</svg>")
SVG.write_text("\n".join(parts) + "\n")
print(f"wrote {SVG}")

# Attempt PNG via cairosvg if available; otherwise skip gracefully.
try:
    import cairosvg

    cairosvg.svg2png(url=str(SVG), write_to=str(PNG), output_width=width * 2)
    print(f"wrote {PNG}")
except Exception as exc:  # noqa: BLE001
    print(f"PNG skipped ({exc})")
