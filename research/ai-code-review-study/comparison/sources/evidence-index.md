# Matched-comparison evidence index

**Retrieval date:** 2026-07-14
**Acquisition:** authenticated GitHub CLI (`gh`) only
**Scope:** selective same-PR, exact-head OCR/CodeRabbit comparison across the three repositories

No credentials, unrelated issue content, or bulk raw API snapshots are retained.

## Source records

### S1 — Matched cohort and reviewed-head evidence

- File: [matched-prs.csv](matched-prs.csv)
- Source type: primary GitHub PR metadata and review-comment metadata plus derived normalization counts
- Reviewer identities:
  - OCR: `github-actions[bot]` comments containing repository OCR markers
  - CodeRabbit: `coderabbitai[bot]`
- Match field: root review comment `original_commit_id`
- Exact PR URLs:
  - <https://github.com/vybestack/llxprt-code/pull/2462>
  - <https://github.com/vybestack/llxprt-code/pull/2547>
  - <https://github.com/vybestack/llxprt-jefe/pull/181>
  - <https://github.com/vybestack/llxprt-jefe/pull/288>
  - <https://github.com/vybestack/llxprt-luther/pull/110>
  - <https://github.com/vybestack/llxprt-luther/pull/133>
- Result: six exact-head pairs; two per repository. No near-head or PR-only row enters aggregate results.
- Limitation: PR additions/deletions/files are retrieval-time total metadata, not exact selected-head diff sizes.

### S2 — Classified selective finding sample

- File: [matched-findings.csv](matched-findings.csv)
- Source type: analyst classification of primary GitHub review threads and dispositions
- Coverage: 56 rows; OCR 33 and CodeRabbit 23
- Selection: up to six normalized findings per reviewer per PR, retaining all where fewer existed
- Fields: reviewer, exact SHA/time, category, validity, action, action quality, usefulness, disposition link, and overlap group
- Limitation: selective sample, not a probability sample and not complete validity coding of all 105 normalized selected-iteration findings.

### S3 — Semantic overlap crosswalk

- File: [semantic-overlap.csv](semantic-overlap.csv)
- Source type: analyst normalization linking primary comments
- Coverage: ten groups; eight exact and two semantic
- Rule: exact means the same defect/invariant; semantic means a shared factual core with different scope or remedy.
- Limitation: semantic equivalence is analyst-coded, though every member has an exact GitHub URL.

### S4 — Excluded iteration ledger

- File: [excluded-review-iterations.csv](excluded-review-iterations.csv)
- Source type: current mutable CodeRabbit issue-comment states
- Exact state URLs:
  - <https://github.com/vybestack/llxprt-code/pull/2462#issuecomment-4922139346>
  - <https://github.com/vybestack/llxprt-code/pull/2547#issuecomment-4954209618>
  - <https://github.com/vybestack/llxprt-jefe/pull/288#issuecomment-4964256014>
  - <https://github.com/vybestack/llxprt-luther/pull/110#issuecomment-4886708289>
  - <https://github.com/vybestack/llxprt-luther/pull/133#issuecomment-4949785176>
- Rule: explicit `Review limit reached` iterations are excluded. Existing completed root reviews on the same PR remain included. `Review skipped` and `Reviews paused` are recorded as noncompleted states, not quality observations.
- Limitation: issue comments are edited in place, so one URL may represent the latest retained state rather than every historical attempt.

### S5 — Compact thread extracts

- File: [thread-extracts.md](thread-extracts.md)
- Source type: short paraphrases and quotations from primary threads
- Coverage: shared findings, unique findings, accepted fixes, technical dismissals, and unadjudicated cases
- Sanitization: generated hidden metadata, long model analysis chains, external account identifiers, and unrelated material omitted.

### S6 — Reproducibility commands

- File: [commands.md](commands.md)
- Source type: command record
- Contains only `gh`, `jq`, Python standard-library, `find`, and `grep` commands; no credentials.

### S7 — Artifact inventory

- File: [file-inventory.txt](file-inventory.txt)
- Source type: local validation output
- Purpose: verifies the package is compact and contains no raw snapshot directory.

## Primary OCR summary markers

These mutable summaries establish repository-specific OCR identity and tool/version, but inline `original_commit_id` controls selected-head matching:

- code #2462: <https://github.com/vybestack/llxprt-code/pull/2462#issuecomment-4922163669>
- code #2547: <https://github.com/vybestack/llxprt-code/pull/2547#issuecomment-4954250320>
- Jefe #181: <https://github.com/vybestack/llxprt-jefe/pull/181#issuecomment-4937936212>
- Jefe #288: <https://github.com/vybestack/llxprt-jefe/pull/288#issuecomment-4964297169>
- Luther #110: <https://github.com/vybestack/llxprt-luther/pull/110#issuecomment-4887233982>
- Luther #133: <https://github.com/vybestack/llxprt-luther/pull/133#issuecomment-4949796172>

## Evidence boundaries

Included: PR metadata; OCR and CodeRabbit root inline comments; direct replies; aggregate disposition comments; mutable review-state comments; exact GitHub object URLs.

Excluded: application-runtime claims not shown in threads; issues unrelated to the selected PRs; raw API dumps; credentials; hidden generated review payloads; unmatched PR quality rows.

All comments under human-looking identities are treated as LLM-authored actions according to the research directive. This is an analytical attribution rule, not an independent identity finding.

## Validation outcome

All 89 unique GitHub object URLs present in the four canonical CSVs were resolved successfully with `gh api` on 2026-07-14. CSV widths and aggregates were recomputed locally; all relative Markdown links resolved; the final inventory contains nine files and no raw snapshot directory.
