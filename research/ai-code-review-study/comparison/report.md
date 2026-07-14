# Selective exact-head matched comparison: Alibaba OCR and CodeRabbit

**Repositories:** `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, `vybestack/llxprt-luther`
**GitHub evidence retrieved:** 2026-07-14 with authenticated `gh` only
**Canonical sources:** [matched PRs](sources/matched-prs.csv), [classified findings](sources/matched-findings.csv), [semantic overlaps](sources/semantic-overlap.csv), [excluded iterations](sources/excluded-review-iterations.csv)

## Executive summary

This analysis corrects the earlier reports' principal comparison weakness: **OCR and CodeRabbit are compared on the same six pull requests, two per repository, and on the same reviewed head SHA in every pair**. No near-head or PR-only pair is pooled into the results.[S1]

The six selected exact-head iterations emitted **85 raw OCR findings and 32 raw CodeRabbit findings**. After within-review semantic deduplication, that was **74 OCR and 31 CodeRabbit normalized findings**. OCR's selected iterations therefore emitted 2.39 times as many normalized findings, but also had a higher duplicate rate: **11/85 (12.9%) versus 1/32 (3.1%)**.[S1]

A transparent selective classification took up to six normalized findings per reviewer per PR, retaining all findings where fewer existed. This produced **56 classified findings: OCR 33 and CodeRabbit 23**. Ten cross-review semantic overlap groups were found in that sample: **8 exact and 2 semantic**. Relative to the 46-finding semantic union, overlap was **10/46 (21.7%)**; OCR had **23/33 (69.7%)** sample findings outside an overlap group and CodeRabbit had **13/23 (56.5%)**.[S2][S3]

The adjudicated subsets were strikingly similar, not evidence of one reviewer dominating:

- OCR: 11 valid, 2 partial, 3 invalid, 17 unadjudicated. Among adjudicated rows, valid-or-partial was **13/16 (81.3%)**.
- CodeRabbit: 8 valid, 2 partial, 2 invalid, 11 unadjudicated. Among adjudicated rows, valid-or-partial was **10/12 (83.3%)**.

Those are **paired descriptive observations from a selective sample**, not population precision estimates and not a causal model comparison. The raw difference in finding volume cannot establish reviewer superiority because prompts, models, review timing, reruns, PR size, file selection, and action visibility differ. Half the classified rows were unadjudicated (**28/56, 50.0%**).[S2]

**Decision conclusion:** use the reviewers as complementary hypothesis generators, preserve technical adjudication, and deduplicate across them. On exact same-head inputs they frequently converged on the same material invariant, but each also produced useful unique findings. Neither existing report should retain wording that readers could interpret as a head-to-head superiority claim.

## Research question

On the same PRs and, where possible, the same head SHA, how did Alibaba OpenCodeReview (OCR) and CodeRabbit differ in finding volume, duplication, semantic overlap, validity, action, and usefulness?

## Methodology

### Cohort selection

1. Candidate PRs were inspected through GitHub's API with `gh` only.
2. OCR was identified by `github-actions[bot]` inline comments carrying repository markers such as `llxprt-code-ocr-inline`, `jefe-ocr-inline`, or `luther-ocr-inline`, plus the corresponding OpenCodeReview summary.
3. CodeRabbit was identified only as `coderabbitai[bot]`.
4. A PR was eligible only when both reviewers had completed substantive root inline findings.
5. The original reviewed SHA came from each review comment's `original_commit_id`, not the mutable current `commit_id`.
6. The chosen iteration minimized timing distance while requiring an exact reviewed-head match. All six pairs are therefore `exact-head`; no unlike match-quality strata are pooled.[S1][S5]
7. Explicit `Review limit reached` iterations were excluded, while completed inline reviews on those PRs were retained. Mutable `Review skipped` and `Reviews paused` summary states were also logged as noncompleted states but did not erase an already completed exact-head review.[S4]

### Finding extraction and normalization

- **Raw finding:** a root inline comment in the selected exact-head iteration.
- **Normalized finding:** a semantic issue unit after collapsing repeated or semantically equivalent comments within one reviewer iteration. Examples include three repeated registry-cleanup comments in code #2547, repeated line-index boilerplate in Jefe #181, and duplicate missing-resume reports in Luther #110.
- **Classified sample:** up to six normalized findings per reviewer per PR, retaining all when fewer than six existed. Selection prioritized traceability, overlap detection, substantive breadth, and disconfirming cases. This cap prevents the very large OCR batches from dominating classification labor, but it also means validity/usefulness percentages describe the selected rows only—not all 105 normalized emitted findings.[S1][S2]
- **Overlap:** `exact` when both comments state the same defect/invariant; `semantic` when the factual core is shared but scope or proposed remedy differs.[S3]
- **Validity:** `valid`, `partial`, `invalid`, or `unadjudicated`. Missing linked disposition remains unknown.
- **Action:** `fixed`, `dismissed`, `deferred`, or `no-action`.
- **Action quality:** `appropriate` only when the linked response matches the classified validity and scope; otherwise `unverifiable` where no disposition exists.
- **Usefulness:** high for material correctness/security/concurrency/test protection, medium for worthwhile robustness or maintainability, and low for cosmetic, speculative, duplicate, or marginal feedback.
- Per instruction, comments posted under human-looking identities are treated as **LLM-authored actions**, not personal human adjudications.

### Source quality and weighting

| Evidence | Authority | Directness | Rigor | Relevance | Weight |
|---|---:|---:|---:|---:|---|
| GitHub root comments, replies, PR metadata via `gh` | 5/5 | 5/5 | 4/5 | 5/5 | Primary |
| `original_commit_id` and timestamps | 5/5 | 5/5 | 5/5 | 5/5 | Controls matching |
| Explicit fix/dismiss/withdraw replies | 5/5 | 5/5 | 4/5 | 5/5 | Controls disposition |
| Analyst normalization and usefulness coding | 2/5 | 4/5 | 3/5 | 5/5 | Transparent derived layer |

The primary GitHub record controls factual observations. Analyst coding cannot convert an unanswered finding into a success or failure.

## Cohort inventory

| ID | Repository PR | State | Selected SHA | Quality | OCR time | CR time | Gap | PR size (add/del/files) | Raw OCR/CR | Normalized OCR/CR |
|---|---|---|---|---|---|---|---:|---:|---:|---:|
| P01 | code [#2462](https://github.com/vybestack/llxprt-code/pull/2462) | merged | `66b27be6` | exact-head | 14:45:57Z | 14:50:38Z | 281s | 731/131/15 | 4/1 | 4/1 |
| P02 | code [#2547](https://github.com/vybestack/llxprt-code/pull/2547) | open at retrieval | `4a50e2b7` | exact-head | 07:32:59Z | 07:36:52Z | 233s | 11063/1050/100 | 21/1 | 17/1 |
| P03 | Jefe [#181](https://github.com/vybestack/llxprt-jefe/pull/181) | merged | `f2409b7f` | exact-head | 19:52:02Z | 20:02:40Z | 638s | 2174/376/25 | 22/8 | 18/8 |
| P04 | Jefe [#288](https://github.com/vybestack/llxprt-jefe/pull/288) | merged | `4e4a43c0` | exact-head | 01:25:24Z | 01:32:14Z | 410s | 878/85/19 | 5/7 | 5/7 |
| P05 | Luther [#110](https://github.com/vybestack/llxprt-luther/pull/110) | merged | `af9922e6` | exact-head | 18:58:40Z | 16:36:12Z | 8548s | 8434/709/69 | 23/12 | 21/11 |
| P06 | Luther [#133](https://github.com/vybestack/llxprt-luther/pull/133) | merged | `2b7d7576` | exact-head | 07:30:23Z | 07:30:50Z | 27s | 6255/1109/20 | 10/3 | 9/3 |

The size columns are retrieval-time PR totals, not necessarily the exact selected-head diff. This is a confounder, not a covariate-adjusted model.[S1]

## Results

### Full selected-iteration volume and duplication

```text
Normalized findings emitted (selected exact-head iterations)
OCR         74 | ##########################################################################
CodeRabbit  31 | ###############################

Duplicate source comments removed
OCR         11/85 | ########### 12.9%
CodeRabbit   1/32 | #            3.1%
```

The six within-PR normalized count differences (`OCR - CodeRabbit`) were `+3, +16, +10, -2, +10, +6`; mean `+7.17`, median `+8`. This is a **yield description**, not evidence that more findings were more correct or more useful. P02 and P05 were much larger PRs; OCR and CodeRabbit also used different review systems and likely different prompts/models.[S1]

### Classified-sample overlap

| Measure | Raw n | Percentage |
|---|---:|---:|
| Exact overlap groups | 8/10 | 80.0% of overlap groups |
| Semantic overlap groups | 2/10 | 20.0% of overlap groups |
| Semantic union | 46 | `33 + 23 - 10` |
| Overlap / union | 10/46 | 21.7% |
| OCR rows in overlap | 10/33 | 30.3% |
| CodeRabbit rows in overlap | 10/23 | 43.5% |
| OCR-only sample rows | 23/33 | 69.7% |
| CodeRabbit-only sample rows | 13/23 | 56.5% |

```text
Classified semantic union (n=46)
Shared groups       10 | ########## 21.7%
OCR-only units      23 | ####################### 50.0%
CodeRabbit-only     13 | ############# 28.3%
```

Because the classified rows were selected rather than randomly sampled, these overlap percentages must not be generalized to all findings.[S2][S3]

### Validity

| Reviewer | Valid | Partial | Invalid | Unadjudicated | Adjudicated valid-or-partial |
|---|---:|---:|---:|---:|---:|
| OCR | 11/33 (33.3%) | 2/33 (6.1%) | 3/33 (9.1%) | 17/33 (51.5%) | 13/16 (81.3%) |
| CodeRabbit | 8/23 (34.8%) | 2/23 (8.7%) | 2/23 (8.7%) | 11/23 (47.8%) | 10/12 (83.3%) |

```text
OCR (n=33)          CR (n=23)
valid        11     valid         8
partial       2     partial       2
invalid       3     invalid       2
unknown      17     unknown      11
```

The 81.3% and 83.3% values differ by one adjudicated finding and are selection-sensitive. They are not estimates of reviewer precision. If `partial` is excluded from the numerator, strict valid shares are OCR **11/16 (68.8%)** and CodeRabbit **8/12 (66.7%)**.[S2]

### Usefulness

| Reviewer | High | Medium | Low |
|---|---:|---:|---:|
| OCR | 14/33 (42.4%) | 9/33 (27.3%) | 10/33 (30.3%) |
| CodeRabbit | 8/23 (34.8%) | 7/23 (30.4%) | 8/23 (34.8%) |

```text
High usefulness
OCR         14/33 | ############## 42.4%
CodeRabbit   8/23 | ########       34.8%

Low usefulness
OCR         10/33 | ##########     30.3%
CodeRabbit   8/23 | ########       34.8%
```

Usefulness is analyst-coded even when validity is unknown. Therefore a high/unadjudicated row means “potentially material if correct,” not “confirmed material defect.”[S2]

### Actions and action quality

| Reviewer | Fixed | Dismissed | Deferred | No action | Appropriate | Unverifiable |
|---|---:|---:|---:|---:|---:|---:|
| OCR | 12/33 (36.4%) | 4/33 (12.1%) | 0/33 (0%) | 17/33 (51.5%) | 16/33 (48.5%) | 17/33 (51.5%) |
| CodeRabbit | 8/23 (34.8%) | 4/23 (17.4%) | 0/23 (0%) | 11/23 (47.8%) | 12/23 (52.2%) | 11/23 (47.8%) |

All 28 rows with observable dispositions had action quality coded appropriate. This reflects the selected traceable actions and cannot be generalized to every LLM-authored response.[S2]

## Per-PR paired tables

### P01 — code #2462

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 4 / 4 / 4 | 1 / 1 / 1 |
| Exact / semantic overlap rows | 0 / 0 | 0 / 0 |
| Reviewer-only classified rows | 4 | 1 |
| Valid / partial / invalid / unknown | 3 / 1 / 0 / 0 | 1 / 0 / 0 / 0 |
| High / medium / low | 2 / 2 / 0 | 0 / 1 / 0 |
| Fixed / dismissed / deferred / no-action | 4 / 0 / 0 / 0 | 1 / 0 / 0 / 0 |
| Duplicate rate | 0/4 (0%) | 0/1 (0%) |

**Material unique defects:** both. OCR found OAuth guard contamination and wrong URL selection; CodeRabbit uniquely identified unsafe copy-paste `trust: true` documentation. All were fixed in the same disposition summary.[E1]

### P02 — code #2547

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 21 / 17 / 6 | 1 / 1 / 1 |
| Exact / semantic overlap rows | 0 / 1 | 0 / 1 |
| Reviewer-only classified rows | 5 | 0 |
| Valid / partial / invalid / unknown | 4 / 0 / 2 / 0 | 0 / 1 / 0 / 0 |
| High / medium / low | 1 / 3 / 2 | 0 / 0 / 1 |
| Fixed / dismissed / deferred / no-action | 4 / 2 / 0 / 0 | 0 / 1 / 0 / 0 |
| Duplicate rate | 4/21 (19.0%) | 0/1 (0%) |

**Material unique defects:** OCR had several unique validated fixes, but the only high-usefulness row overlapped CodeRabbit's broader test-cleanup concern. The CodeRabbit finding was partially grounded but withdrawn after the stronger black-box cleanup assertion; this is not a CodeRabbit-only defect.[E2]

### P03 — Jefe #181

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 22 / 18 / 6 | 8 / 8 / 6 |
| Exact / semantic overlap rows | 3 / 1 | 3 / 1 |
| Reviewer-only classified rows | 2 | 2 |
| Valid / partial / invalid / unknown | 0 / 0 / 0 / 6 | 0 / 0 / 0 / 6 |
| High / medium / low | 3 / 1 / 2 | 1 / 3 / 2 |
| Fixed / dismissed / deferred / no-action | 0 / 0 / 0 / 6 | 0 / 0 / 0 / 6 |
| Duplicate rate | 4/22 (18.2%) | 0/8 (0%) |

**Material unique defects:** not adjudicable. Both raised unique potentially material UI/PTY concerns, but the selected final-head comments have no linked disposition. No superiority claim is permitted.[E3]

### P04 — Jefe #288

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 5 / 5 / 5 | 7 / 7 / 6 |
| Exact / semantic overlap rows | 2 / 0 | 2 / 0 |
| Reviewer-only classified rows | 3 | 4 |
| Valid / partial / invalid / unknown | 0 / 1 / 1 / 3 | 1 / 1 / 2 / 2 |
| High / medium / low | 1 / 0 / 4 | 1 / 2 / 3 |
| Fixed / dismissed / deferred / no-action | 0 / 2 / 0 / 3 | 1 / 3 / 0 / 2 |
| Duplicate rate | 0/5 (0%) | 0/7 (0%) |

**Material unique defects:** CodeRabbit uniquely produced one validated medium-usefulness case-insensitive metadata-directory fix. Both found the potentially critical sibling-parent `NotFound` defect, and both proposed the same rejected process-batching optimization. Each reviewer also produced a technically rejected filesystem recommendation.[E4][E5]

### P05 — Luther #110

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 23 / 21 / 6 | 12 / 11 / 6 |
| Exact / semantic overlap rows | 3 / 0 | 3 / 0 |
| Reviewer-only classified rows | 3 | 3 |
| Valid / partial / invalid / unknown | 4 / 0 / 0 / 2 | 6 / 0 / 0 / 0 |
| High / medium / low | 5 / 1 / 0 | 5 / 1 / 0 |
| Fixed / dismissed / deferred / no-action | 4 / 0 / 0 / 2 | 6 / 0 / 0 / 0 |
| Duplicate rate | 2/23 (8.7%) | 1/12 (8.3%) |

**Material unique defects:** yes. CodeRabbit uniquely found and drove fixes for sub-issue pagination and API fallback. OCR uniquely raised high-impact capacity and auto-merge concerns, but those selected threads were unadjudicated, so they remain potential rather than confirmed misses. The reviewers independently converged on active-parent label semantics, missing resume metadata, and SQLite contention.[E6]

### P06 — Luther #133

| Metric | OCR | CodeRabbit |
|---|---:|---:|
| Raw / normalized / classified | 10 / 9 / 6 | 3 / 3 / 3 |
| Exact / semantic overlap rows | 0 / 0 | 0 / 0 |
| Reviewer-only classified rows | 6 | 3 |
| Valid / partial / invalid / unknown | 0 / 0 / 0 / 6 | 0 / 0 / 0 / 3 |
| High / medium / low | 2 / 2 / 2 | 1 / 0 / 2 |
| Fixed / dismissed / deferred / no-action | 0 / 0 / 0 / 6 | 0 / 0 / 0 / 3 |
| Duplicate rate | 1/10 (10.0%) | 0/3 (0%) |

**Material unique defects:** not adjudicable. OCR raised warning aggregation and concurrency-classification risks; CodeRabbit raised process-global test environment locking. No selected-head row has a linked disposition.[E7]

## Representative overlaps

1. **Listener cleanup test — semantic overlap.** OCR said post-unmount state did not prove the listener was removed; CodeRabbit listed several private listener-removal assertions. The LLM-authored response implemented an exact listener-count test. CodeRabbit agreed this black-box assertion was stronger and withdrew the extra choreography requests.[G01]
2. **Jefe selection line indices — exact overlap.** Both flagged repeated inline post-increment blocks as fragile. No selected-head action was observed.[G02]
3. **Sibling parent removal — exact overlap.** Both traced `NotFound` when a second untracked sibling revisits an already removed parent.[G06]
4. **SQLite contention — exact overlap.** Both identified the missing poller `busy_timeout`; linked replies validate and fix it.[G10]
5. **Per-path restore optimization — exact overlap and shared dismissal.** Both proposed batching `git restore`; the LLM-authored response retained per-path execution for argv safety and exact path handling, and CodeRabbit explicitly withdrew.[G07]

## Representative unique cases

### OCR-only in the classified sample

- OAuth dedup guard cross-contamination and signal-anchored URL selection in code #2462; both fixed.[O001][O002]
- Trust working-directory normalization mismatch in code #2547; fixed.[O010]
- Theme-picker mouse forwarding and selected merge-method highlight in Jefe #181; potentially material but unadjudicated.[O015][O016]
- Fatal transition unreachable in Luther #110; validated and fixed.[O027]
- Multiple artifact warnings collapsed to one in Luther #133; potentially material but unadjudicated.[O028]

### CodeRabbit-only in the classified sample

- Canonical MCP docs enabled `trust: true`; fixed with examples and a security caveat.[C001]
- Case-sensitive owned metadata-directory check on a case-insensitive host; fixed.[C011]
- Sub-issue pagination and native-API fallback in Luther #110; both fixed and verified.[C018][C019]
- Hardcoded squash merge method; fixed by selecting an allowed method.[C020]
- Cross-module process-global environment lock in Luther #133; potentially material but unadjudicated.[C022]

## Interpretation

### Observations

- Exact-head matching was achievable for all six PRs.[S1]
- OCR emitted more findings in five of six selected pairs, but also more duplicates.[S1]
- Cross-review overlap was real but limited in the selective sample: 10 shared semantic groups versus 36 reviewer-only union units.[S3]
- The two reviewers had nearly identical adjudicated valid-or-partial shares in this sample, with large unknown fractions.[S2]
- Both reviewers generated valuable unique fixes and technically rejected suggestions.[S2][E1-E7]

### Inferences

- **Complementarity is better supported than superiority.** Low overlap plus unique validated fixes on both sides supports using both when review cost permits.
- **A deduplication layer has high leverage.** Exact repeated findings appeared within OCR reruns and across reviewers.
- **Volume is not precision.** OCR's larger batches increased coverage opportunities and duplicate/noise exposure simultaneously.
- **Technical challenge is safety-critical.** The Jefe #288 Windows suggestion shows that plausible automated remediation can be unsafe; the correct workflow is verify, fix, defer, or reject with evidence.

### What this study does not establish

It does not estimate causal reviewer quality. The following remain confounders:

- exact prompt, rules, model, provider, temperature, and tool access;
- review timing and which reviewer ran first;
- mutable summaries and repeated reruns;
- PR size and exact selected-head diff size;
- file-selection and context-window policies;
- differing severity and comment-emission thresholds;
- response-selection bias in which comments received a disposition;
- selective classification rather than a probability sample.

## Recommendations

1. Retain both reviewers only with cross-review semantic deduplication keyed by head SHA, path/symbol, and normalized invariant.
2. Show immutable run manifests with reviewer, exact head/base, prompt/rules/model hashes, selected files, finding IDs, and failures.
3. Track three metrics separately: availability/blocked iterations, normalized finding yield, and adjudicated validity/usefulness.
4. Never treat unadjudicated findings as valid, invalid, or material misses.
5. Prioritize shared high-impact findings first; independent convergence is a useful triage signal, not proof.
6. Require runtime/source verification for filesystem, platform, destructive-operation, and security recommendations.
7. Prefer delta-oriented reruns and suppress unchanged normalized claims to reduce OCR's observed duplicate accumulation.
8. For a future causal comparison, randomize reviewer order, hold prompt/model/context constant where possible, classify all findings blind to reviewer, and use an independent adjudicator.

## Required revisions to the existing reports

### OCR report

**Revision required:** yes. Its 75.0% fully-valid and 91.7% fixed headline came from a response-rich OCR-only sample and must not be read as evidence that OCR is better than CodeRabbit.

**Exact replacement/addendum:**

> **Matched-cohort addendum (2026-07-14):** In a selective exact-head cohort of six same PRs, OCR emitted 74 normalized findings versus CodeRabbit's 31 and had a higher duplicate rate (11/85, 12.9%, versus 1/32, 3.1%). In the 56-row classified sample, OCR had 13 valid-or-partial findings among 16 adjudicated (81.3%), while CodeRabbit had 10/12 (83.3%); 28/56 rows were unadjudicated. Ten semantic overlap groups were identified, and both reviewers produced unique validated fixes. These are paired descriptive results, not causal evidence of OCR superiority; the earlier OCR-only 75.0% validity and 91.7% fix figures remain sample-specific and are not cross-review benchmarks.

### CodeRabbit report

**Revision required:** yes. Its 88.0% adjudicated precision remains valid for its own unmatched purposive sample, but it must not be used as a head-to-head advantage over OCR.

**Exact replacement/addendum:**

> **Matched-cohort addendum (2026-07-14):** On six exact-head same-PR pairs, the selective classified sample yielded valid-or-partial shares of 10/12 (83.3%) for adjudicated CodeRabbit rows and 13/16 (81.3%) for adjudicated OCR rows, with 11/23 and 17/33 rows respectively unadjudicated. CodeRabbit emitted fewer normalized findings in the selected iterations (31 versus 74) and fewer duplicate source comments (1/32, 3.1%, versus 11/85, 12.9%). Ten shared semantic groups and unique validated fixes from both reviewers support complementarity, not reviewer superiority. The report's earlier 88.0% precision remains an unmatched CodeRabbit-only sample statistic and must not be compared directly with OCR's separate sample.

## Confidence

- **High:** all six review pairs inspected the same original head SHA; direct GitHub metadata supports this.[S1]
- **High:** linked fixes, dismissals, withdrawals, and explicit rate-limit states occurred.[S2][S4][E1-E7]
- **Medium:** semantic normalization and overlap assignments; they are auditable but analyst-coded.[S2][S3]
- **Low-to-medium:** any generalization beyond these six PRs; selection, unadjudicated rows, and workflow confounders dominate.
- **No supported confidence:** causal claims that one reviewer is intrinsically superior.

## Limitations

- Six PRs are a selective cohort, not a random sample.
- The classified sample is capped at six normalized findings per reviewer per PR; raw/normalized volume covers complete selected iterations, while validity/usefulness does not.
- Twenty-eight of 56 rows are unadjudicated.
- P02 was still open at retrieval; later actions can change its record.
- GitHub issue summaries are mutable. `original_commit_id` and immutable inline URLs were used to control reviewed-head matching.
- Exact-head does not mean exact context: reviewer prompts, selected files, tools, and model configurations may differ.
- Review gaps ranged from 27 seconds to 8,548 seconds; same SHA prevents code drift but not external-context drift.
- PR total size is not necessarily the selected-head diff size.
- No application tests or runtime reproductions were run for this documentary audit.

## Evidence references

- **[S1]** [matched-prs.csv](sources/matched-prs.csv)
- **[S2]** [matched-findings.csv](sources/matched-findings.csv)
- **[S3]** [semantic-overlap.csv](sources/semantic-overlap.csv)
- **[S4]** [excluded-review-iterations.csv](sources/excluded-review-iterations.csv)
- **[S5]** [evidence-index.md](sources/evidence-index.md)
- **[E1-E7]** [thread-extracts.md](sources/thread-extracts.md)
- **[commands]** [commands.md](sources/commands.md)
- **[inventory]** [file-inventory.txt](sources/file-inventory.txt)
- **[O001-O033, C001-C023]** row IDs in [matched-findings.csv](sources/matched-findings.csv)
- **[G01-G10]** row IDs in [semantic-overlap.csv](sources/semantic-overlap.csv)

## Validation record

- CSV shape: 6 matched-PR rows, 56 classified-finding rows, 10 overlap rows, and 5 excluded-state rows; every row matched its header width.
- Aggregate recomputation: OCR raw/normalized 85/74; CodeRabbit raw/normalized 32/31; reviewer sample totals 33/23; validity, action, usefulness, and overlap totals recomputed from the CSV and matched the report.
- Match quality: all six rows are `exact-head`; no mixed-quality pooling.
- Relative Markdown links: all resolved after final inventory creation.
- Exact GitHub objects: all 89 unique PR, issue-comment, and review-comment URLs in the canonical CSVs returned successfully through `gh api` in four validation batches.
- Inventory: 9 files and zero `raw` snapshot directories.
- Application tests were not run, as required.
