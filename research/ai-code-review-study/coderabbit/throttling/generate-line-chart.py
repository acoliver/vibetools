#!/usr/bin/env python3
import csv
from datetime import date
from pathlib import Path
from xml.sax.saxutils import escape

BASE = Path(__file__).resolve().parent
SOURCE = BASE / "pr-activity-by-week.csv"
DATA = BASE / "chart-timeseries.csv"
OUTPUT = BASE / "activity-over-time.svg"
REPOSITORIES = ["llxprt-code", "llxprt-jefe", "llxprt-luther"]
REPOSITORY_COLORS = {
    "llxprt-code": "#2563eb",
    "llxprt-jefe": "#dc2626",
    "llxprt-luther": "#16a34a",
}
AGGREGATE_SERIES = [
    ("pr_events", "PR events", "#7c3aed"),
    ("completed_review_signals", "Successful reviews", "#0891b2"),
    ("blocked_comments", "Throttles", "#be123c"),
]
REPOSITORY_PANELS = [
    ("pr_creations", "PRs opened"),
    ("estimated_push_updates", "PR updates (commit proxy)"),
    ("completed_review_signals", "Completed review signals"),
    ("blocked_comments", "Throttle events"),
]
START = date.fromisoformat("2026-06-01")

with SOURCE.open(newline="") as source:
    source_rows = list(csv.DictReader(source))
weeks = sorted(
    {
        row["week_start"]
        for row in source_rows
        if date.fromisoformat(row["week_start"]) >= START
    }
)
lookup = {(row["week_start"], row["repository"]): row for row in source_rows}
rows = []
for week in weeks:
    aggregate = {
        "week_start": week,
        "repository": "all-llxprt",
        "pr_creations": 0,
        "estimated_push_updates": 0,
        "completed_review_signals": 0,
        "blocked_comments": 0,
    }
    for repository in REPOSITORIES:
        source = lookup.get((week, repository), {})
        row = {"week_start": week, "repository": repository}
        for metric, _ in REPOSITORY_PANELS:
            row[metric] = int(float(source.get(metric) or 0))
            aggregate[metric] += row[metric]
        row["pr_events"] = row["pr_creations"] + row["estimated_push_updates"]
        rows.append(row)
    aggregate["pr_events"] = (
        aggregate["pr_creations"] + aggregate["estimated_push_updates"]
    )
    rows.append(aggregate)
with DATA.open("w", newline="") as target:
    writer = csv.DictWriter(
        target,
        fieldnames=[
            "week_start",
            "repository",
            "pr_creations",
            "estimated_push_updates",
            "pr_events",
            "completed_review_signals",
            "blocked_comments",
        ],
    )
    writer.writeheader()
    writer.writerows(rows)

width, height = 1180, 1140
left, right, top = 78, 28, 104
panel_height, panel_gap = 164, 36
plot_width = width - left - right
font = "font-family='-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif'"
parts = [
    f"<svg xmlns='http://www.w3.org/2000/svg' width='{width}' height='{height}' viewBox='0 0 {width} {height}'>",
    "<rect width='100%' height='100%' fill='white'/>",
    f"<text x='{left}' y='34' font-size='22' font-weight='700' {font}>Weekly llxprt PR activity and CodeRabbit outcomes</text>",
    f"<text x='{left}' y='57' font-size='13' fill='#475569' {font}>2026-06-01 through 2026-07-14; final week is partial</text>",
]


def add_axes(y_top, title, maximum, show_dates):
    y_bottom = y_top + panel_height
    parts.append(
        f"<text x='{left}' y='{y_top - 10}' font-size='15' font-weight='650' fill='#0f172a' {font}>{escape(title)}</text>"
    )
    for grid_index in range(5):
        value = maximum * grid_index / 4
        y = y_bottom - panel_height * grid_index / 4
        parts.extend(
            [
                f"<line x1='{left}' y1='{y:.1f}' x2='{left + plot_width}' y2='{y:.1f}' stroke='#e2e8f0' stroke-width='1'/>",
                f"<text x='{left - 10}' y='{y + 4:.1f}' text-anchor='end' font-size='11' fill='#64748b' {font}>{value:.0f}</text>",
            ]
        )
    for week_index, week in enumerate(weeks):
        x = left + plot_width * week_index / max(1, len(weeks) - 1)
        parts.append(
            f"<line x1='{x:.1f}' y1='{y_top}' x2='{x:.1f}' y2='{y_bottom}' stroke='#f1f5f9' stroke-width='1'/>"
        )
        if show_dates:
            parts.append(
                f"<text x='{x:.1f}' y='{y_bottom + 20}' text-anchor='middle' font-size='11' fill='#64748b' {font}>{week[5:]}</text>"
            )
    return y_bottom


def add_line(values, color, label, y_top, maximum):
    points = []
    for week_index, (week, value) in enumerate(zip(weeks, values)):
        x = left + plot_width * week_index / max(1, len(weeks) - 1)
        y = y_top + panel_height - panel_height * value / maximum
        points.append((x, y, value, week))
    encoded = " ".join(f"{x:.1f},{y:.1f}" for x, y, _, _ in points)
    parts.append(
        f"<polyline points='{encoded}' fill='none' stroke='{color}' stroke-width='3' stroke-linejoin='round' stroke-linecap='round'/>"
    )
    for x, y, value, week in points:
        parts.extend(
            [
                f"<circle cx='{x:.1f}' cy='{y:.1f}' r='3.5' fill='{color}'/>",
                f"<title>{escape(label)} {week}: {value}</title>",
            ]
        )

aggregate_rows = {
    row["week_start"]: row for row in rows if row["repository"] == "all-llxprt"
}
aggregate_max = max(
    int(aggregate_rows[week][metric])
    for metric, _, _ in AGGREGATE_SERIES
    for week in weeks
)
aggregate_max = max(5, aggregate_max)
aggregate_top = top
add_axes(
    aggregate_top,
    "All projects: PR events vs successful reviews vs throttles",
    aggregate_max,
    False,
)
for index, (metric, label, color) in enumerate(AGGREGATE_SERIES):
    values = [int(aggregate_rows[week][metric]) for week in weeks]
    add_line(values, color, label, aggregate_top, aggregate_max)
    x = 650 + index * 160
    parts.extend(
        [
            f"<line x1='{x}' y1='82' x2='{x + 24}' y2='82' stroke='{color}' stroke-width='3'/>",
            f"<text x='{x + 31}' y='87' font-size='12' fill='#334155' {font}>{escape(label)}</text>",
        ]
    )

repository_legend_y = top + panel_height + 24
for index, repository in enumerate(REPOSITORIES):
    x = 650 + index * 155
    parts.extend(
        [
            f"<line x1='{x}' y1='{repository_legend_y}' x2='{x + 24}' y2='{repository_legend_y}' stroke='{REPOSITORY_COLORS[repository]}' stroke-width='3'/>",
            f"<text x='{x + 31}' y='{repository_legend_y + 5}' font-size='12' fill='#334155' {font}>{escape(repository)}</text>",
        ]
    )

repository_rows = [row for row in rows if row["repository"] in REPOSITORIES]
for panel_index, (metric, title) in enumerate(REPOSITORY_PANELS, start=1):
    y_top = top + panel_index * (panel_height + panel_gap)
    maximum = max(int(row[metric]) for row in repository_rows) or 1
    maximum = max(5, maximum)
    add_axes(y_top, title, maximum, panel_index == len(REPOSITORY_PANELS))
    for repository in REPOSITORIES:
        by_week = {
            row["week_start"]: row
            for row in repository_rows
            if row["repository"] == repository
        }
        values = [int(by_week[week][metric]) for week in weeks]
        add_line(values, REPOSITORY_COLORS[repository], repository, y_top, maximum)

parts.append(
    f"<text x='{left}' y='{height - 15}' font-size='11' fill='#64748b' {font}>PR events = PRs opened + estimated follow-up commit updates. Reviews and throttles are retained GitHub signals, not billing events.</text>"
)
parts.append("</svg>")
OUTPUT.write_text("\n".join(parts) + "\n")
print(f"wrote {DATA} ({len(rows)} rows) and {OUTPUT}")
