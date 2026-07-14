# Alibaba OpenCodeReview retrospective: PR and local review evidence

**Repositories:** `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, `vybestack/llxprt-luther`
**Evidence acquired:** 2026-07-14
**Canonical data:** [PR findings](sources/sampled-findings.csv), [local findings](sources/local-findings.csv), [evidence index](sources/evidence-index.md)

## Executive summary

This retrospective classifies **36 OCR findings from six PRs**, balanced at 12 findings per repository, and separately examines **23 parseable findings from three retained local OCR artifacts**. Comments made under human-looking identities are treated as LLM-authored actions.

### PR finding quality and action

| Measure | Result |
|---|---:|
| Fully valid | **27/36 (75.0%)** |
| Partially valid or overstated | **8/36 (22.2%)** |
| Invalid | **1/36 (2.8%)** |
| Fixed by the LLM | **33/36 (91.7%)** |
| Explained and dismissed | **2/36 (5.6%)** |
| Deferred intentionally | **1/36 (2.8%)** |
| High usefulness | **14/36 (38.9%)** |
| Medium usefulness | **13/36 (36.1%)** |
| Low usefulness | **9/36 (25.0%)** |

Within this purposive, response-rich sample, the LLM's action was appropriate for all 36 findings. That does **not** estimate action quality across all OCR use: the sample favors findings with traceable responses and final-source evidence.

OCR's best PR findings involved lifecycle, state ordering, resource ownership, error semantics, and concurrency. Its weakest output consisted of duplicate reports, cosmetic maintenance advice, speculative performance claims, and claims made against stale architecture. Jefe [PR 236](https://github.com/vybestack/llxprt-jefe/pull/236) is important disconfirming evidence: retained triage concluded that a large batch warranted no code changes because findings were stale, invalid, out of scope, or disproportionately low priority.

### Local versus PR result

The local and PR sets are **not direct recall competitors**. The PR sample is a balanced, adjudicated retrospective; the local sample is opportunistic retained evidence with native OCR category/severity labels and incomplete run metadata.

The only near-matched content comparison was code PR 2462. A retained local log had four findings, while three unique actionable findings were posted later that day on the PR's final head. Manual semantic matching found **zero overlaps**. This does not demonstrate nondeterminism under identical inputs: the local artifact lacks the reviewed SHA, range, prompt/rules, model/provider, and worktree state.

The strongest evidence-backed explanation is that local and PR OCR often review **different artifacts at different stages**: cumulative PR diffs versus focused remediation deltas, different SHAs and timing, different selected files, and mutable PR summaries that combine historical reruns. Prompt/model/configuration and uncommitted-state differences remain plausible but unestablished.

### Matched OCR–CodeRabbit addendum

A more selective [same-PR, exact-head comparison](../comparison/report.md) was subsequently constructed from six PRs, two per repository. In those selected iterations, OCR emitted **74 normalized findings** versus CodeRabbit's **31** and had a higher duplicate rate: **11/85 (12.9%)** versus **1/32 (3.1%)**. In the 56-row classified sample, OCR had **13 valid-or-partial findings among 16 adjudicated (81.3%)**, while CodeRabbit had **10/12 (83.3%)**; **28/56 rows were unadjudicated**. Ten semantic overlap groups were identified, and both reviewers produced unique validated fixes.

These are paired descriptive results, not causal evidence of reviewer superiority. The OCR-only **75.0% fully-valid** and **91.7% fixed** figures in this report remain sample-specific and are not cross-review benchmarks.

## Research design

### PR sample

Six findings were classified from each of:

- code [PR 2462](https://github.com/vybestack/llxprt-code/pull/2462) and [PR 2547](https://github.com/vybestack/llxprt-code/pull/2547)
- Jefe [PR 181](https://github.com/vybestack/llxprt-jefe/pull/181) and [PR 275](https://github.com/vybestack/llxprt-jefe/pull/275)
- Luther [PR 110](https://github.com/vybestack/llxprt-luther/pull/110) and [PR 133](https://github.com/vybestack/llxprt-luther/pull/133)

The rows were chosen for traceability across OCR finding, LLM response, remediation commit/final source, and later outcome. Duplicate findings remain rows when OCR emitted them independently because duplication is part of review quality.

### Rubric

- **Category:** correctness, lifecycle/resource handling, maintainability, tests, observability/error semantics, performance, robustness, or concurrency.
- **Validity:** `valid`, `partial` when the factual core was real but impact/premise was overstated, or `invalid` when contradicted by source/tests.
- **Action:** `fixed`, `explained-dismissed`, or `deferred`.
- **Action quality:** appropriate when the response matched validity, scope, and final behavior.
- **Usefulness:** high for material risk prevention, medium for worthwhile robustness/maintainability/test strengthening, and low for duplicate, cosmetic, speculative, or marginal feedback.

### Local sample

| Source | Context | Findings |
|---|---|---:|
| L1 | `$TMPDIR/ocr_review_pr2462.log`; associated by filename, exact SHA/range absent | 4 |
| L2 | `$TMPDIR/ocr_review_2544.log`; issue-2544 remediation, **not** PR 2547 | 11 |
| L3 | mounted composite Jefe OCR log; only parseable Jefe text retained | 8 |
| **Total** | | **23** |

Local rows preserve OCR's own category and severity. They were not independently re-tested as part of the PR adjudication denominator. Session JSONL corroborated phrases but was not counted again.

## PR OCR results

### Validity

```text
Valid         27/36  75.0%  ###########################
Partial        8/36  22.2%  ########
Invalid        1/36   2.8%  #
```

### LLM action

```text
Fixed                 33/36  91.7%  #################################
Explained-dismissed    2/36   5.6%  ##
Deferred                1/36   2.8%  #
```

### Action quality

```text
Appropriate    36/36  100.0%  ####################################
Partial         0/36    0.0%
Inappropriate   0/36    0.0%
Unverifiable    0/36    0.0%
```

This perfect observed action score reflects a response-rich, completed-disposition sample and must not be generalized as a population rate.

### Usefulness

```text
High    14/36  38.9%  ##############
Medium  13/36  36.1%  #############
Low      9/36  25.0%  #########
```

### Finding categories

```text
Correctness       7/36  19.4%  #######
Lifecycle         7/36  19.4%  #######
Maintainability   7/36  19.4%  #######
Tests             6/36  16.7%  ######
Observability     3/36   8.3%  ###
Performance       3/36   8.3%  ###
Robustness        2/36   5.6%  ##
Concurrency       1/36   2.8%  #
```

### By repository

| Repository | Valid / partial / invalid | Fixed / explained / deferred | High / medium / low usefulness |
|---|---:|---:|---:|
| llxprt-code | 9 / 3 / 0 | 11 / 1 / 0 | 5 / 6 / 1 |
| llxprt-jefe | 9 / 3 / 0 | 11 / 0 / 1 | 4 / 4 / 4 |
| llxprt-luther | 9 / 2 / 1 | 11 / 1 / 0 | 5 / 3 / 4 |

## Representative PR cases

### High-value defects

1. **OAuth permanent wedge — code PR 2462.** OCR identified that cleanup happened only after authentication settled, allowing an abandoned browser flow to leave the in-flight guard occupied permanently. The LLM added a bounded timeout/race and tests. [Finding](https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3551881606)
2. **Dead cancellation — Jefe PR 275.** `cancel_pending()` ran after the relevant detail had been cleared, making cancellation unreachable. The remediation moved cancellation before state clearing. [Finding](https://github.com/vybestack/llxprt-jefe/pull/275#discussion_r3572637939)
3. **Transport and timer cleanup — code PR 2547.** OCR found a failed-connect transport leak and a refresh timer not cleared on all exits. Both were addressed in [`7841dae`](https://github.com/vybestack/llxprt-code/commit/7841dae14094d2ccc04ddcce7628491537ff6e6d).
4. **Lease ownership coverage — Luther PR 133.** OCR identified missing `Some(expected_run_id)` guard coverage; final source added matching- and mismatching-owner tests. [Finding](https://github.com/vybestack/llxprt-luther/pull/133#discussion_r3565579059)
5. **SQLite concurrency — Luther PR 110.** OCR found that the poller connection lacked `busy_timeout`; the final code configured a bounded timeout. [Finding](https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525455138)

### Partially valid or lower-value findings

- The SSE deprecation handling in code PR 2462 was narrow, but OCR's examples of known phrase variants were speculative. Broadening it with tests was still reasonable.
- Jefe PR 275 genuinely dropped a failure event, but OCR overstated the loading-state consequence. The LLM fixed the error visibility while rejecting the false premise.
- Luther PR 133 had removable SQL allocation/cloning, but OCR did not establish material hot-path cost.
- Code finding C11 and Luther finding L5 duplicated other findings and therefore had low marginal value.
- Luther finding L11 claimed placeholder arithmetic was hardcoded and insufficiently tested. Source evidence contradicted it, and the LLM appropriately dismissed it. [Thread](https://github.com/vybestack/llxprt-luther/pull/133#discussion_r3565680912)

The complete 36-row classification and evidence links are in [sampled-findings.csv](sources/sampled-findings.csv).

## Local OCR findings

### Native category and severity

```text
Local categories (n=23)
Bug              13/23  56.5%  #############
Maintainability   4/23  17.4%  ####
Test              3/23  13.0%  ###
Performance       2/23   8.7%  ##
Documentation     1/23   4.3%  #

Local OCR severity (n=23)
High      7/23  30.4%  #######
Medium    9/23  39.1%  #########
Low       7/23  30.4%  #######
```

### Representative local cases

- **PR-2462-associated log:** guard-key collision, misleading URL-index naming, possible `UnauthorizedError` subclass loss, and a multiple-URL deprecation test gap. The artifact says 12 files and four comments but records no SHA/range/config. [Excerpt](sources/excerpts/local-pr2462.txt)
- **Issue-2544 remediation:** 8/11 findings were bugs around provider/model identity and stale asynchronous state. The run completed with one subtask error, so its count is not complete-recall evidence. [Excerpt](sources/excerpts/local-issue2544.txt)
- **Mounted Jefe log:** eight parseable findings included reload-state tests, full-list cloning, pagination pending state, and fixture robustness. The composite file's unrelated JSON prefix was excluded. [Excerpt](sources/excerpts/local-jefe-pr236.txt)

## Local versus PR-posted OCR

### Descriptive counts with different denominators

| Evidence unit | Raw n | Meaning |
|---|---:|---|
| PR retrospective | 36 | Balanced, adjudicated six-PR sample |
| Retained local sample | 23 | All parseable findings in three selected local artifacts |
| PR 2462-associated local run | 4 | One retained local output; exact range unknown |
| PR 2462 later same-day PR set | 3 | Unique actionable final-head findings; duplicates/no-issue excluded |
| Jefe PR 236 current summary | 31 | Mutable latest-summary count at acquisition |
| Jefe PR 236 retained triage | 30 stated | Triage says 29 inline plus one summary; headings internally sum to 31 |

```text
PR retrospective sample    36  ####################################
Local retained sample      23  #######################
PR 236 current summary     31  ###############################
PR 236 triage stated       30  ##############################
PR 2462 local               4  ####
PR 2462 later PR unique     3  ###
```

These counts must not be read as relative recall or findings-per-run.

### Near-matched PR 2462 overlap

The PR-side comparison here is a separate same-day final-head set, **not** the six adjudicated PR-2462 rows above.

| Local finding | trailing `/mcp/` | preserve original error | empty string vs `undefined` | Local-only |
|---|---:|---:|---:|---:|
| guard-key null collision | 0 | 0 | 0 | 1 |
| misleading URL index name | 0 | 0 | 0 | 1 |
| `UnauthorizedError` subclass path | 0 | 0 | 0 | 1 |
| multiple-URL test gap | 0 | 0 | 0 | 1 |
| **PR-only** | **1** | **1** | **1** | — |

```text
Local only       4/7 union  57.1%  ####
PR only          3/7 union  42.9%  ###
Overlap          0/7 union   0.0%
Jaccard          0/7 = 0.000
```

**Measured fact:** semantic text overlap is zero for this selected set.
**Limit:** input equivalence is unproven, so this is not an experiment comparing model determinism or recall.

## Why local and PR OCR catch different things

| Mechanism | Evidence | Confidence |
|---|---|---:|
| Different SHA or diff range | PR summaries record heads; local L1 does not; PR 236 triage and current summary name different heads | High |
| Cumulative PR diff versus focused remediation delta | PRs span 15–100 files; local issue-2544 run focused on 12 remediation files | High for this sample |
| Rerun timing and mutable summaries | Historical inline comments persist while one summary is edited; code PR 2547 had 425 OCR-authored inline records but a current 39-finding summary | High |
| Different file selection or failed subtasks | Local artifacts report selected file counts and issue-2544 reports a subtask error; exact parity is unavailable | Medium |
| Stale or insufficient architecture context | PR 236 triage cites removed fields, shared-helper misreads, and reducer/dispatch boundary errors | Medium-high |
| Prompt, rules, provider, and model | Retained local and PR evidence do not prove configuration equivalence | Low / unestablished |
| Local uncommitted state | Local artifacts omit status/tree/diff hashes | Low / unestablished |

The first three mechanisms directly explain much of the divergence. Local review after remediation can concentrate on a newly edited failure mode; PR CI can surface cumulative integration issues across a wider diff. Neither channel is inherently more grounded: PR 236 shows that a broad PR review can still reason from stale or misunderstood architecture.

## Iteration effects

- High-value state and lifecycle defects often appeared in early review passes.
- Later reruns increasingly produced cleanup, naming, optimization, and test-comment concerns.
- Duplicate or rephrased findings accumulated.
- Aggregate PR comments were edited in place, obscuring historical run counts.
- Large cumulative reruns could report against obsolete code, as PR 236 demonstrates.

The retained evidence does not support a defensible numeric quality-by-iteration curve because immutable run manifests are missing.

## Conclusions

1. **OCR provides real engineering value**, especially for lifecycle, ordering, ownership, concurrency, and error-semantics invariants.
2. **OCR must remain a hypothesis generator.** Every finding needs current-source verification; PR 236 demonstrates that finding volume can coexist with poor grounding.
3. **LLM triage is part of the value chain.** In this sample the LLM fixed valid findings, preserved valid portions of overstated claims, deferred one broad refactor, documented an API limitation, and rejected an invalid test claim.
4. **One quarter of the PR sample was low value.** Deduplication and impact ranking are therefore higher-leverage improvements than suppressing all minor findings.
5. **Local and PR OCR are complementary only when run intentionally.** PR OCR is suited to cumulative integration coverage; local post-remediation OCR is suited to focused changed-state review. Their raw counts should not be merged.
6. **Large cumulative reruns are the clearest risk.** Delta-oriented reruns and immutable manifests should reduce stale-context findings.

## Recommendations

1. Record repository, `HEAD`, merge base, exact diff range, clean/dirty status, and uncommitted-diff hash with every run.
2. Record OCR version/executable hash, provider/model, prompt/rule/config hashes, selected files, failed files, and session ID.
3. Post an immutable per-head manifest containing finding ID, reviewed SHA, disposition, action commit, test, and rerun result.
4. Make remediation reruns delta-oriented and explicitly label cumulative stale findings.
5. Deduplicate normalized claim plus path/symbol/invariant across runs.
6. Require source-backed dispositions for both fixes and dismissals.
7. Prioritize correctness/lifecycle/concurrency/resource findings before cosmetic or speculative optimization findings.
8. Archive raw local and CI JSON consistently so matched-input comparisons become possible.

## Limitations

- Six PRs and 36 purposively selected findings are not a population sample.
- The 100% action-quality observation is selection-sensitive.
- The 23 local findings were opportunistically retained and mostly not independently adjudicated.
- Local and PR sets use different classification schemes and cannot support direct precision comparisons.
- Local L1/L3 omit exact range/config; L3 is composite; issue-2544 had a subtask error.
- Aggregate OCR comments are mutable, and immutable Actions artifacts were not available for every run.
- PR 236's retained triage states 30 findings while its headings sum to 31 and names a different head than the current PR summary.
- No runtime reproduction was performed for this documentary audit.

## Artifact map

- [sampled-findings.csv](sources/sampled-findings.csv) — canonical 36 adjudicated PR findings
- [local-findings.csv](sources/local-findings.csv) — canonical 23 retained local findings
- [evidence-index.md](sources/evidence-index.md) — GitHub and local provenance, hashes, and limitations
- [commands.md](sources/commands.md) — acquisition and validation commands
- [github-pr-snapshots.md](sources/github-pr-snapshots.md) — acquisition-time GitHub evidence
- [pr2462-overlap-snapshot.md](sources/pr2462-overlap-snapshot.md) — near-matched comparison evidence
- [local PR 2462 excerpt](sources/excerpts/local-pr2462.txt)
- [local issue 2544 excerpt](sources/excerpts/local-issue2544.txt)
- [mounted Jefe excerpt](sources/excerpts/local-jefe-pr236.txt)
- [session excerpts](sources/excerpts/session-excerpts.md)
- [file inventory](sources/file-inventory.txt)
