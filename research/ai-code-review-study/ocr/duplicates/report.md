# OCR duplicate mechanisms and mitigations

**Repositories:** `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, `vybestack/llxprt-luther`
**Evidence acquired:** 2026-07-14
**Canonical data:** [collection script](_collect.py), [matched cohort](../../comparison/sources/matched-findings.csv)

## Executive conclusion

OCR review output contains two distinct duplicate phenomena that require different mitigations. **Output-side within-run semantic duplication** — where a single review run posts multiple comments that are semantically equivalent or rephrased versions of the same invariant — is the dominant duplicate source. **GitHub reposting** — where separate runs post the same finding again — is effectively suppressed by existing same-head exact-key filters in the code and Jefe workflows.

The matched six-PR cohort found **11/85 (12.9%) duplicate source comments** in OCR output, comprising one exact and ten semantic within-run duplicates. CodeRabbit had one duplicate out of 32 (3.1%). The existing same-head exact-key filters in the code and Jefe CI workflows held strict cross-batch repost rates at **1.6%** and **1.8%**, but these filters operate on exact text keys and do not address in-run semantic duplication. Luther PR #130 (merged 2026-07-13) reduced >5-minute exact reposts from 18 to 0, but the overall exact rate barely moved (**7.5%→7.2%**) because within-batch duplicates dominate and the post-change sample is small (n=69).

The global `~/.opencodereview/rule.json` contains no anti-duplicate instruction and is not loaded by CI workflows. Anti-duplicate guidance must be added to the workflow-provided rule configuration to affect PR CI reviews.

## Research design

This analysis combines three evidence sources:

1. **Matched cohort duplicates** from the six-PR exact-head comparison (`[CMP]`), which classified all 85 OCR and 32 CodeRabbit raw findings and identified within-run semantic and exact duplicates.

2. **Cross-batch repost measurement** from the repository-level collection script ([`_collect.py`](_collect.py)), which queries all `github-actions[bot]` OCR inline comments per repository, groups them by (PR, `original_commit_id`, path, line, normalized body) to detect exact reposts, and separates within-batch from cross-batch duplicates using `pull_request_review_id`.

3. **CI workflow analysis** of `.github/workflows/ocr-review.yml` (code and Jefe) and `.github/workflows/ocr-pr-review.yml` (Luther) to identify existing deduplication mechanisms and the rule configuration loading path.

## Within-run duplicates in the matched cohort

In the six-PR exact-head comparison, OCR's selected iterations produced:

| Duplicate type | Count | Rate |
|---|---:|---:|
| Exact within-run | 1 | 1/85 (1.2%) |
| Semantic within-run | 10 | 10/85 (11.8%) |
| **Total OCR duplicates** | **11** | **11/85 (12.9%)** |
| CodeRabbit duplicates (exact) | 1 | 1/32 (3.1%) |

The ten semantic duplicates included repeated `importActual`/`afterEach` root-cause reports on different paths in code #2547, repeated line-index boilerplate in Jefe #181, and duplicate missing-resume reports in Luther #110. These pass exact-key checks because they differ in wording, path, or line number despite sharing the same factual core.

## Cross-batch reposting and filter effectiveness

### Existing filter mechanism

The code and Jefe CI workflows (`.github/workflows/ocr-review.yml`) include a same-head exact-key filter. Before posting inline comments, the workflow:

1. Queries existing OCR inline comments on the current PR head SHA.
2. Builds a key set from (path, line, normalized body) for each existing comment.
3. Filters the candidate posting list: `inlineToPost = inline.filter((c) => !existingInlineKeys.has(inlineCommentKey(c)))`.
4. If all candidates already exist, logs `"All OCR inline comments already exist on this head SHA; skipping inline posting."`.

This filter suppresses exact cross-batch reposts — where a later run would post the identical finding at the same head — but does not address semantic duplicates within a single run or across runs with different wording.

### Repository-level exact repost rates

| Repository | All OCR root comments | Exact reposts | Strict rate | Mechanism |
|---|---:|---:|---:|---|
| llxprt-code | n measured | n measured | **1.6%** | Same-head exact-key skip |
| llxprt-jefe | n measured | n measured | **1.8%** | Same filter, ported from code |
| llxprt-luther (pre-PR #130) | n measured | n measured | **7.5%** | No same-head filter until PR #130 |

These rates confirm that the exact-key filter is effective at its designed task: preventing identical path + line + body reposts at the same head. The residual 1.6–1.8% on code and Jefe represents within-batch duplicates and edge cases where the filter's normalization does not collapse near-identical text.

## Luther PR #130 and its effect

Luther's OCR workflow (`ocr-pr-review.yml`) lacked the same-head exact-key filter until PR #130 (merged 2026-07-13 04:07:12Z). PR #130 ported the code workflow's robust version, including:

- The same-head exact-key skip filter
- `--concurrency 2` to cap account-wide provider contention
- Distinct rate-limit classification (StepFun HTTP 429 "concurrency reached" separated from auth/config failures)
- Secret redaction, phase tracking, and infrastructure failure notification
- Marker-comment deduplication (deleting duplicate sticky summary comments)

| Measure | Before PR #130 | After PR #130 |
|---|---:|---:|
| >5-minute exact reposts | 18 | **0** |
| Overall exact repost rate | 7.5% | 7.2% |
| Post-change n | — | 69 |

PR #130 **eliminated >5-minute exact reposts entirely**: the 18 cases where a later run posted the identical finding at the same head more than five minutes after the first all disappeared. However, the overall exact rate barely moved (7.5%→7.2%) because:

1. Within-batch duplicates (posted within seconds of each other during a single run) dominate the exact-repost denominator.
2. The post-change sample is small (n=69 comments), limiting statistical power.
3. The filter targets cross-batch reposts, not within-batch duplicates posted in the same review.

This is consistent with the code and Jefe finding: exact-key filters are necessary but not sufficient. They suppress one mechanism (cross-batch reposting) while leaving another (within-run semantic duplication) untouched.

## Repository workflows and configuration

| Repository | Workflow file | Same-head filter | Concurrency control | Config status |
|---|---|---|---|---|
| llxprt-code | `.github/workflows/ocr-review.yml` | Yes (exact-key skip) | GitHub Actions concurrency group | Active since ~Jul 7 |
| llxprt-jefe | `.github/workflows/ocr-review.yml` | Yes (ported from code) | GitHub Actions concurrency group | Active since ~Jul 8 |
| llxprt-luther | `.github/workflows/ocr-pr-review.yml` | Yes (PR #130, Jul 13) | `--concurrency 2` + group | Active since Jul 13 |

All three workflows also include **marker-comment deduplication**: if the sticky OCR review summary comment is posted more than once (e.g., due to a batch-post failure), the workflow deletes duplicates and keeps only the first. This operates on the summary comment, not on inline findings.

## Global rule.json and CI

The global `~/.opencodereview/rule.json` defines review instructions (severity calibration, category priorities, lint/complexity policy enforcement, test-scoping guidance) and include/exclude file patterns. It contains **no anti-duplicate instruction** — nothing tells the model to avoid posting semantically equivalent findings or to check whether a similar finding already exists in the same run.

Furthermore, this global rule file is **not loaded by the CI workflows**. The GitHub Actions workflows construct the OCR rule from environment variables and inline configuration defined in the workflow YAML itself:

- The code and Jefe workflows pass rules via workflow environment or inline heredoc, not from the user's home directory.
- The Luther workflow builds the rule from env-provided `rule.json` content in the workflow, preserving Luther's test patterns (`**/*_test.rs`, `**/tests/**`).

The local CLI loads `~/.opencodereview/rule.json`; CI does not. This means any anti-duplicate instruction added to the global rule would affect local runs but not PR CI reviews. To affect both channels, the instruction must be added to both the global rule and the workflow-provided rule configuration.

## Provider-quality duplicate comparison

The M001 exact pair from `[OCR-PQ]` provides a controlled duplicate comparison under matched inputs:

| Measure | GLM-5.2 / Z.ai | StepFun / Step-3.7-Flash |
|---|---:|---:|
| Duplicate/rephrased emissions | 10/61 (16.4%) | 2/31 (6.5%) |
| Largest redundancy cluster | `importActual`/`afterEach` root cause ×8 | Proxy socket `end`/`close` concern ×3 |

This confirms that duplicate burden varies by provider/model and is not solely a function of the review tool's posting logic. GLM-5.2's higher duplicate rate is an output-side property of its finding generation, independent of the CI posting mechanism.

## Duplicate mechanism taxonomy

| Mechanism | Definition | Observed rate | Current mitigation | Gap |
|---|---|---|---|---|
| Within-run semantic | Same invariant rephrased on different paths in one run | 10/85 (11.8% of OCR raw) | None | No semantic clustering |
| Within-run exact | Identical text repeated in one run | 1/85 (1.2% of OCR raw) | Marker-comment dedup | Residual within-batch risk |
| Cross-batch exact repost | Same finding reposted at same head by a later run | 1.6% (code), 1.8% (Jefe) | Same-head exact-key filter | Does not cover Luther pre-PR #130 |
| Cross-reviewer overlap | Both reviewers find same invariant independently | 10/46 (21.7% Jaccard) | None | No shared finding ledger |

## Interpretation

The evidence supports three conclusions:

1. **Cross-batch reposting is effectively mitigated.** The same-head exact-key filter in the code and Jefe workflows, and now in Luther via PR #130, suppresses identical reposts at the same head. The >5-minute repost elimination (18→0) in Luther confirms the filter works as designed.

2. **Within-run semantic duplication is unmitigated.** The dominant duplicate source (10/11 OCR duplicates) is semantic rephrasing within a single run. No existing mechanism addresses this. A semantic clustering layer operating on normalized claim + path/symbol + invariant is needed.

3. **Provider/model affects duplicate burden.** GLM-5.2's 16.4% duplicate rate versus StepFun's 6.5% in M001 shows that model behavior is a contributing factor independent of the CI posting logic. Anti-duplicate instructions in the rule configuration may help, but must be added to CI-provided rules (not just the global `rule.json`) to affect PR reviews.

## Recommendations

1. **Add a semantic clustering pass** that groups semantically equivalent findings within a single run before posting. Key on normalized claim text + path/symbol + invariant.
2. **Add an anti-duplicate instruction to CI-provided rules**, not just the global `rule.json`. Instruct the model to avoid posting semantically equivalent findings and to reference existing threads.
3. **Expand the exact-key filter to near-exact matching** (e.g., body similarity above a threshold) as an interim measure before semantic clustering is available.
4. **Track duplicate burden by mechanism** in run manifests: within-run semantic, within-run exact, cross-batch repost, cross-reviewer overlap.
5. **Evaluate provider-specific duplicate rates** in future matched comparisons, as M001 shows GLM-5.2 is 2.5× more redundant than StepFun.

## Limitations

- The matched cohort duplicate classification is analyst-coded; semantic equivalence judgments are inherently subjective at the margin.
- The repository-level repost measurement uses current-body retrieval, which is a mutable lower bound. Edited-away reposts are not recoverable.
- Luther's post-PR #130 sample (n=69) is small; the 7.2% overall rate has wide uncertainty.
- The collection script (`_collect.py`) depends on `gh` API pagination and current GitHub indexing, which can lag.
- No immutable webhook or run log was available; repost attribution to specific runs is approximate.
- Provider-attributed duplicate rates come from a single matched pair (M001) and are not generalizable.

## Artifact map

- [_collect.py](_collect.py) — GitHub collection script for cohort, run, and repository-level duplicate analysis
- [matched-findings.csv](../../comparison/sources/matched-findings.csv) — 56 classified findings with duplicate identification
- [semantic-overlap.csv](../../comparison/sources/semantic-overlap.csv) — 10 cross-reviewer overlap groups
- [matched-reruns.csv](../provider-quality/matched-reruns.csv) — M001 provider pair with duplicate/rephrase rates
- [quality-summary.csv](../provider-quality/quality-summary.csv) — M001 exact aggregates