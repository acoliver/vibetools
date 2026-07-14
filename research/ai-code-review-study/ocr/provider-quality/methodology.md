# Methodology

## Research question and scope

This audit asks whether finding **quality** differed between retained OCR runs attributable to **Z.ai / GLM-5.2** and **StepFun / Step-3.7-Flash** while work was performed on `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, and `vybestack/llxprt-luther`. The retained window is 2026-07-10 through 2026-07-14 local time (-03:00). It does not estimate provider reliability or population-wide model quality.

## Evidence hierarchy

1. Direct OCR outputs in `$TMPDIR`, including status, reviewed-file denominator, findings, warning endpoint, session ID, and—in the matched pair—the reviewed Git commit.
2. Exact retained session JSONL paths under `~/.opencodereview/sessions`, used to corroborate repository and time. Their large payloads were not copied.
3. Redacted provider/model metadata from retained `~/.opencodereview/config.json*` snapshots and the existing provider timeline.
4. The existing 145-run reliability ledger, used for discovery and chronology—not as a substitute for finding quality.
5. Local Git object and remediation evidence in the branch-5 worktree, especially commit `b8ee089626e88952161a17191e213e33048d5e5c` and later commit `e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf` (`fix(test): address Bun migration review findings`).
6. Existing local OCR/PR evidence and retained triage extracts, used as supporting context rather than independent model evaluation.

## Provider/model attribution

A run enters the six-run quality sample only if direct retained evidence supports the attribution:

- Endpoint warnings or an operator-named provider artifact establish the endpoint.
- A retained configuration snapshot establishes the model behind that endpoint.
- A configuration interval alone is admitted only with **medium** confidence and is labeled as such.

`GLM-5.2` rows in this study are **Z.ai API** rows. No sampled quality run could be directly attributed to **Ollama / GLM-5.2**. The earlier Ollama config proves configuration existed, not that a retained quality run used it. Because endpoint and model family are one-to-one in the observed quality sample, model-family effects cannot be separated from endpoint effects.

## Sample design

### Exact matched pair

`M001` is the primary comparison:

- Repository: `vybestack/llxprt-code`
- Immutable reviewed commit: `b8ee089626e88952161a17191e213e33048d5e5c`
- Same reported reviewed-file denominator: 90 files each
- Start times: 9m55s apart
- Z.ai run: `QZC`
- StepFun run: `QSC`

The exact selected-file manifest was not retained. The shared commit and equal 90-file denominator are strong matching evidence, but not proof that every selected/completed file was identical. Critically, StepFun reported 16 failed subtasks from endpoint concurrency errors; Z.ai reported zero terminal warnings but did emit five pre-result file-read errors. Finding-volume comparisons therefore remain coverage-confounded even within the pair.

### Stratified descriptive sample

One retained run per provider per repository was selected where possible, yielding six runs and 187 findings:

- Z.ai: 3 runs, 148 reviewed-file observations, 102 findings.
- StepFun: 3 runs, 160 reviewed-file observations, 85 findings.

The four unmatched Jefe/Luther runs add repository breadth but are not adjudicated as if matched. Exact SHA/range, changed-line count, selected-file manifest, OCR concurrency, and immutable prompt/rule/config hashes are missing. Dates and remediation stages differ. Their finding counts, words, severity, category, path, and line-location data are descriptive only.

## Finding extraction

`build_dataset.py` parses OCR JSON directly and strips ANSI escapes before parsing plain-text OCR blocks. Every finding receives:

- Stable local ID
- Repository, run, provider, and model
- Path and line range
- OCR category and severity
- Prose word count
- SHA-256 of the full finding prose
- A 240-character redacted excerpt
- Suggestion/existing-code presence

No credentials, full session payloads, or unrelated temporary data are copied.

## Independent adjudication

All 92 emitted findings in matched pair `M001` were independently reviewed in this research pass against the retained finding, attached code excerpt, reviewed commit where available, cross-run evidence, and subsequent remediation diff.

- **Valid:** the technical claim follows directly from the reviewed code/context; severity or exact remedy may still be debatable.
- **Partial:** a real concern exists, but the finding relies on an unverified runtime assumption, overstates impact, proposes a questionable remedy, or is mainly a defensive/style recommendation.
- **Invalid:** the stated behavior is contradicted, irrelevant to the reviewed change, or too unsupported to sustain the claim.

This is one researcher’s adjudication, not blinded multi-rater review. Borderline labels are exposed row-by-row in `provider-findings.csv`; no inter-rater reliability statistic is claimed.

## Usefulness rubric

Usefulness is intentionally stricter than validity:

- **High:** nonduplicate, valid, high/critical-severity finding.
- **Medium:** nonduplicate, valid medium-severity finding, or partial high/critical finding.
- **Low:** low-severity, invalid, duplicate/rephrased, or partial medium/low finding.

The rubric measures triage utility under a defect-prevention objective. A team prioritizing cleanup or style could rate low-severity maintainability findings differently.

## Duplicate and semantic-overlap method

Duplicate/rephrased findings were manually grouped within each matched run when they asserted the same root cause and materially the same remedy. The first group member is the primary claim; later members count as duplicate/rephrased emissions. Related but distinct consequences were not collapsed.

Cross-run semantic overlap was manually grouped at claim level. The pair has:

- 51 deduplicated Z.ai claims
- 29 deduplicated StepFun claims
- 10 overlapping claim groups
- Union = `51 + 29 - 10 = 70`
- Jaccard = `10 / 70 = 0.142857`

Overlap is not recall: neither model’s output is ground truth.

## Specificity and stale context

Two direct measures are reported:

1. A positive line number (`start_line > 0`).
2. Manual stale/misattributed context, where the emitted path does not match the attached code or the finding is attached to a nonexistent/irrelevant file context.

Line location is a weak proxy. A finding can have a line and still be wrong; a file-level finding can be valid with line 0.

## Action/fix evidence and no-action triage

Commit `e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf`, created after both matched runs and explicitly titled `fix(test): address Bun migration review findings`, is the direct action source. A finding is `fixed_after_pair` only where that diff changed the exact code/behavior identified. Because both models’ reports preceded the commit, action is evidence that a claim was useful enough to affect remediation—not evidence that one provider caused the fix.

No-action rows are triaged as:

- duplicate/rephrased claim;
- invalid/unsupported;
- partial/speculative or remedy not selected; or
- no direct change found in the review-remediation commit.

Finding-level action rates count duplicate emissions independently. Unique-claim action rates collapse duplicate groups and are the preferred actionability measure.

## Quantitative rules

- Findings per reviewed file = findings / OCR-reported files reviewed.
- Duplicate rate = later duplicate/rephrased emissions / emitted findings.
- Valid rate = valid / all adjudicated findings.
- Supported rate = (valid + partial) / all adjudicated findings.
- Stale-context rate = stale/misattributed / all adjudicated findings.
- Finding action rate = fixed findings / all adjudicated findings.
- Unique-claim action rate = fixed deduplicated claims / all deduplicated claims.
- Percentages in prose are rounded to one decimal; CSV ratios retain six decimals.

No hypothesis test is presented: there is one exact pair, findings within a run are dependent, and adjudication uncertainty dominates sampling error. A binomial test would imply false independence and precision.

## Confounders and identification limits

- StepFun’s matched run lost 16 subtasks to a provider-reported concurrency ceiling.
- Z.ai’s matched run contained file-read errors despite terminal `success`.
- The selected-file manifest and changed-line count are absent.
- Repository, language, diff size, prompt/rule version, OCR version, concurrency, date, and remediation stage vary outside the pair.
- Retention is opportunistic and nonrandom.
- Provider endpoint and model family are inseparable in this sample.
- Both runs could inspect shared repository context beyond the changed lines.
- Later commits and uncommitted worktree changes are excluded unless the exact remediation link was direct.

Accordingly, this audit supports descriptive differences and a workflow recommendation, not a causal claim that either model family is superior.
