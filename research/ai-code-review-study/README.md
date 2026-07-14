# AI code-review study

A reproducible documentary study of CodeRabbit and Alibaba OpenCodeReview (OCR)
across `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, and
`vybestack/llxprt-luther`.

The study compares finding quality and specialization, local versus PR OCR,
provider reliability, CodeRabbit throttling, StepFun versus GLM-5.2 output, and
OCR duplicate mechanisms. It is descriptive rather than a vendor ranking: the
matched evidence supports complementary coverage, and provider comparisons have
important coverage and period confounders.

## Start here

- [`megareport.pdf`](megareport.pdf) — typeset 26-page publication. If GitHub's
  inline preview is truncated, use [Download raw PDF](https://raw.githubusercontent.com/acoliver/vibetools/main/research/ai-code-review-study/megareport.pdf).
- [`megareport.md`](megareport.md) — publication source.
- [`compiled-reports.md`](compiled-reports.md) — anthology of the seven canonical reports.
- [`dist/ai-code-review-study-evidence.zip`](dist/ai-code-review-study-evidence.zip) —
  the PDF plus the reports, evidence tables, figures, and generators it references.

## Repository layout

| Path | Contents |
| --- | --- |
| [`comparison/`](comparison/) | Exact-head OCR versus CodeRabbit matched cohort and evidence. |
| [`coderabbit/`](coderabbit/) | CodeRabbit review-quality retrospective and throttling analysis. |
| [`ocr/`](ocr/) | PR/local retrospective, reliability, provider quality, and duplicate analysis. |
| [`figures/`](figures/) | Publication figures, chart inputs, and comparison chart generator. |
| [`latex/`](latex/) | LaTeX preamble, Pandoc table-width filter, and DOCX styling generator. |
| [`dist/`](dist/) | Portable evidence archive. |

Analysis-specific generators and validators remain beside their inputs—for
example, `ocr/provider-quality/build_dataset.py`,
`ocr/reliability/generate-reliability-chart.py`, and
`coderabbit/throttling/generate-line-chart.py`. This keeps each evidence package
independently auditable.

## Rebuild the publication

The checked-in PDF was generated on macOS with Pandoc 3.8, Tectonic 0.15, and
system Charter/Helvetica Neue/Menlo fonts. The DOCX post-processor requires
`python-docx`.

```sh
./build-publication.sh
```

The script rebuilds `megareport.pdf` and an editable `megareport.docx`. The DOCX
is a generated local artifact and is intentionally not part of the evidence
archive.

## Evidence and privacy

The package contains derived CSV data, selected excerpts, GitHub URLs, command
records, source hashes, and publication figures. Raw local OCR session logs and
credentials are not included. Before publication:

- credentials and private-key patterns were scanned;
- personal absolute paths were replaced with `$HOME`, `$TMPDIR`, or
  `$MOUNTED_WORKSPACE` placeholders;
- only evidence relevant to the study was retained;
- all GitHub evidence was acquired through `gh` and points to public repository
  objects.

`SHA256SUMS` records the package payload. Nested `file-inventory.txt` files are
regenerated after path sanitization and therefore describe the public package,
not the original private filesystem layout.

## Important limitations

- Samples are purposive and cannot estimate population-wide reviewer precision.
- Half of the exact-head classified comparison lacked linked adjudication.
- The StepFun side of the only exact provider pair had 16 failed subtasks.
- Mutable GitHub summaries and retained local logs are incomplete historical
  records.
- Subscription and policy changes confound cost, availability, and quality
  comparisons.
