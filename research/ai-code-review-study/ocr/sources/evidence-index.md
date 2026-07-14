# OCR evidence index

Access date: **2026-07-14**. GitHub evidence was obtained only with `gh`; no web fetch was used. Source quality labels: **A** = direct platform/run output, **B** = retained local artifact with incomplete run metadata, **C** = human triage/interpretation.

## GitHub evidence

| ID | Evidence | Exact URL | Quality | Material limitation |
|---|---|---|---|---|
| G1 | code PR 2462 | https://github.com/vybestack/llxprt-code/pull/2462 | A | Inline comments include multiple reruns; summary is mutable. |
| G2 | code PR 2462 OCR summary | https://github.com/vybestack/llxprt-code/pull/2462#issuecomment-4922163669 | A | At access: updated 2026-07-12, SHA `242091f…`, 1 finding; historical values overwritten. |
| G3 | code PR 2547 | https://github.com/vybestack/llxprt-code/pull/2547 | A | Open at access; cumulative diff and comments continued changing. |
| G4 | code PR 2547 OCR summary | https://github.com/vybestack/llxprt-code/pull/2547#issuecomment-4954250320 | A | At access: SHA `a0fc66c…`, 39 findings; 425 OCR-authored inline records existed across reruns. |
| G5 | Jefe PR 181 | https://github.com/vybestack/llxprt-jefe/pull/181 | A | Multiple commits/reruns. |
| G6 | Jefe PR 181 OCR summary | https://github.com/vybestack/llxprt-jefe/pull/181#issuecomment-4937936212 | A | At access: SHA `f2409b7…`, 23 findings. |
| G7 | Jefe PR 275 | https://github.com/vybestack/llxprt-jefe/pull/275 | A | Open at access; multiple reruns. |
| G8 | Jefe PR 275 OCR summary | https://github.com/vybestack/llxprt-jefe/pull/275#issuecomment-4960583592 | A | At access: SHA `a8c54f0…`, 3 findings; historical inline comments remain. |
| G9 | Luther PR 110 | https://github.com/vybestack/llxprt-luther/pull/110 | A | Summary did not retain an Actions URL. |
| G10 | Luther PR 110 OCR summary | https://github.com/vybestack/llxprt-luther/pull/110#issuecomment-4887233982 | A | At access: SHA `429c3fb…`, 50 findings; historical values overwritten. |
| G11 | Luther PR 133 | https://github.com/vybestack/llxprt-luther/pull/133 | A | One-commit PR but many repeated inline OCR records. |
| G12 | Luther PR 133 OCR summary | https://github.com/vybestack/llxprt-luther/pull/133#issuecomment-4949796172 | A | At access: SHA `ebdd316…`, 2 findings. |
| G13 | Jefe PR 236 (disconfirming case) | https://github.com/vybestack/llxprt-jefe/pull/236 | A | Posted summary and retained triage disagree in head/count metadata. |
| G14 | Jefe PR 236 OCR summary | https://github.com/vybestack/llxprt-jefe/pull/236#issuecomment-4950162896 | A | At access: SHA `37df654…`, 31 findings, run https://github.com/vybestack/llxprt-jefe/actions/runs/29259301030. |

See [github-pr-snapshots.md](github-pr-snapshots.md) for acquisition-time summary fields and all 36 sampled inline URLs.

## Local evidence and provenance

| ID | Original path | SHA-256 | Extraction / provenance | Quality |
|---|---|---|---|---|
| L1 | `$TMPDIR/ocr_review_pr2462.log` | `3709e681117933b7a918a145bca23cdd7dcfefa39df2e60201f1fd198517ec61` | ANSI-stripped 4 findings; filename associates PR 2462; session S1 phrase-corroborates. SHA/range/config absent. [Excerpt](excerpts/local-pr2462.txt). | B |
| L2 | `$TMPDIR/ocr_review_2544.log` | `c377ad7695bd130ba4715dced54bb45eb60ecf53a4d39b109bfbc23c1bde06fe` | Parsed JSON summary/comments/session; provider error payload omitted. Local issue-2544 remediation, explicitly **not** PR 2547. [Excerpt](excerpts/local-issue2544.txt). | A for local output; B for context |
| L3 | `$TMPDIR/jefe-issue241-staged-review-20260714/.jefe/ocr_review.log` | `39eff0419f2d80f83139d74bc5722dbc2d5414ec667fdf22587e7d20031cc8de` | Composite file: unrelated llxprt JSON excluded; eight Jefe text blocks retained and session S3 phrase-corroborated. Exact PR CI equivalence not established. [Excerpt](excerpts/local-jefe-pr236.txt). | B |
| L4 | `$TMPDIR/jefe-issue241-staged-review-20260714/.jefe/ocr-triage.md` | `94ecf409effa57b2157cdd6f862b8a65a754cd59fdb87764892043ba40c44016` | Human triage of PR 236; exact counts retained. Head says `790d224`, unlike current GitHub summary SHA. Category headings sum to 31 although narrative says 30. [Excerpt](excerpts/local-jefe-pr236.txt). | C |
| L5 | `$TMPDIR/ocr-batch6.md` | `076996db48f1bcb21aad1b96c8f553924c3d1dca5c21fe5d8f4a04296789a7ad` | Three resolved Jefe OCR findings, all no-action. PR/run identity absent. [Excerpt](excerpts/local-jefe-pr236.txt). | C |
| S1 | `$HOME/.opencodereview/sessions/Users-acoliver-projects-llxprt-branch-1-llxprt-code/216fc204-dbc1-4ac7-9bb7-307a7f4fb579.jsonl` | `d57f86800dbacaf0cdd6faa8c8ca1467545d4b9b1b356fa0386c71f1eed93470` | Exact-phrase match to L1; full history not copied. [Excerpt](excerpts/session-excerpts.md). | B |
| S2 | `$HOME/.opencodereview/sessions/Volumes-XS1000-acoliver-projects-llxprt-branch-9-llxprt-code/cac77643-9472-4aaa-8415-fc73ec875a3f.jsonl` | `12fe5090e10a4da73156305ffbe7573693905698b06ed028ec144075a7d0ce0c` | Corroborates unrelated JSON prefix excluded from L3. [Excerpt](excerpts/session-excerpts.md). | B |
| S3 | `$HOME/.opencodereview/sessions/Volumes-XS1000-acoliver-projects-jefe-branch-1/82ba0c9f-73e4-419a-9ec4-17b404c214bb.jsonl` | `214bd782f011b21e12fa22c1693c7c934b8725b90317482781235eaade2b5348` | Exact-phrase match to L3's Jefe portion; full history not copied. [Excerpt](excerpts/session-excerpts.md). | B |

## Dataset definitions

- [sampled-findings.csv](sampled-findings.csv): 36 purposively selected, traceable PR findings—six each from code PRs 2462/2547, Jefe PRs 181/275, and Luther PRs 110/133. Each row records analyst-classified category, validity, subsequent LLM action, action quality, usefulness, and finding/action evidence. It is a balanced response-rich sample, not a frequency or population-precision estimate.
- [local-findings.csv](local-findings.csv): 23 parseable local outputs: L1=4, L2=11, L3=8. Local category/severity labels are copied from OCR output. L4/L5 adjudication evidence is not silently expanded into finding rows because L4's category totals conflict and L5 lacks run identity.
- [github-pr-snapshots.md](github-pr-snapshots.md) preserves acquisition-time mutable summaries and broader PR-history evidence. Its earlier chronological extraction is supporting source material, not the canonical classified 36-row dataset.
- PR classifications are analyst judgments corroborated with linked responses, commits, and final source where available. Local findings remain outside the PR validity/action denominators unless explicitly discussed as triage evidence.
