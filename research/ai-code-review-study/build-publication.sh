#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

for command in pandoc tectonic python3; do
  command -v "$command" >/dev/null || {
    printf 'required command not found: %s\n' "$command" >&2
    exit 1
  }
done

pandoc megareport.md \
  --from=gfm+raw_html \
  --resource-path=. \
  --lua-filter=latex/table-widths.lua \
  --toc \
  --toc-depth=2 \
  --number-sections \
  --top-level-division=chapter \
  --pdf-engine=tectonic \
  -V documentclass=report \
  -V classoption=oneside \
  -V papersize=letter \
  -V fontsize=10.5pt \
  -V subtitle= \
  -H latex/preamble.tex \
  -o megareport.pdf

raw_base="$(mktemp -t ai-code-review-study.XXXXXX)"
raw_docx="${raw_base}.docx"
mv "$raw_base" "$raw_docx"
trap 'rm -f "$raw_docx"' EXIT

pandoc megareport.md \
  --from=gfm+raw_html \
  --resource-path=. \
  --toc \
  --toc-depth=2 \
  --number-sections \
  -o "$raw_docx"

python3 latex/style_docx.py "$raw_docx" megareport.docx
printf 'built %s and %s\n' "$ROOT/megareport.pdf" "$ROOT/megareport.docx"
