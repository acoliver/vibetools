# OCR provider-period finding quality

**Repositories:** `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, `vybestack/llxprt-luther`
**Providers/models:** Z.ai / GLM-5.2 versus StepFun / Step-3.7-Flash
**Retained evidence window:** 2026-07-10–2026-07-14 (-03:00)
**Primary evidence:** [exact matched pair](matched-reruns.csv), [finding dataset](provider-findings.csv), [quality summary](quality-summary.csv)

## Executive conclusion

**Observation:** In the only defensible exact rerun pair, Z.ai GLM-5.2 produced **61 findings (0.678/file)** and **51 deduplicated claims (0.567/file)**, while StepFun Step-3.7-Flash produced **31 findings (0.344/file)** and **29 deduplicated claims (0.322/file)** over the same commit and 90-file denominator. Z.ai’s findings were more verbose (**93.51 versus 76.35 words/finding**), more redundant (**16.4% versus 6.5% duplicate/rephrase rate**), and much more often stale or attached to the wrong context (**29.5% versus 0.0%**). StepFun had a higher concentration of high/medium-usefulness findings (**54.8% versus 41.0%**) and a slightly higher deduplicated-claim action rate (**34.5% versus 31.4%**). Strict validity was similar (**57.4% Z.ai versus 54.8% StepFun**), as was high/critical severity concentration (**34.4% versus 35.5%**). [E1][E2][E5][E6]

**Interpretation:** Retained evidence supports a **volume-versus-concentration difference**, not a quality winner. Z.ai surfaced more hypotheses and more unique claims, but at higher verbosity, repetition, and context-misattribution cost. StepFun’s shorter report was denser in useful claims and cleaner in location specificity, but it also missed coverage: **16 subtasks failed** under provider-reported concurrency. That failure can itself explain part of the lower finding volume. [E1][E2]

**Conclusion:** There is **medium confidence** that these two matched outputs differ in review style: Z.ai was broader/more verbose and StepFun was more concise/less redundant. There is only **low confidence** that StepFun was intrinsically more actionable or that Z.ai had intrinsically higher recall, and **no defensible causal evidence that either model family is superior**. Endpoint, model family, period, and workload remain entangled. No attributable Ollama GLM-5.2 quality run was found. [E3][E4]

## Research design

The primary comparison is matched pair `M001`:

| Attribute | Z.ai side | StepFun side |
|---|---|---|
| Run | QZC | QSC |
| Model | GLM-5.2 | Step-3.7-Flash |
| Repository | llxprt-code | llxprt-code |
| Commit | `b8ee0896…e5c` | `b8ee0896…e5c` |
| Start | 2026-07-13 22:14:42 | 2026-07-13 22:24:37 |
| Reported files | 90 | 90 |
| Terminal status | success | completed with errors |
| Provider subtasks in warnings | 0 | 16 |

The exact selected-file manifest and changed-line denominator were not retained. Z.ai emitted five pre-result file-read errors despite `success`; StepFun emitted one pre-result read error plus 16 failed provider subtasks. The pair is therefore matched on repository, commit, near-time, and reported file denominator, but not demonstrably on completed-file coverage. See [methodology](methodology.md).

A secondary six-run stratified sample supplies one retained run per provider per repository: **187 findings / 308 reviewed-file observations**. The Jefe/Luther runs are unmatched and differ in date, head/range retention, remediation stage, and likely diff size/concurrency. They are descriptive only.

![Matched finding volume](matched-finding-volume.svg)

## Exact matched-pair results

### Finding volume and overlap

| Measure | Z.ai GLM-5.2 | StepFun 3.7 Flash |
|---|---:|---:|
| Findings | 61 | 31 |
| Findings/reviewed file | 0.677778 | 0.344444 |
| Deduplicated claims | 51 | 29 |
| Unique claims/reviewed file | 0.566667 | 0.322222 |
| Distinct finding paths | 36 | 19 |
| Overlapping semantic claim groups | 10 | 10 |
| Claim-side overlap | 10/51 (19.6%) | 10/29 (34.5%) |

The deduplicated union is 70 claims and Jaccard overlap is **10/70 = 0.142857**. Low overlap means the outputs emphasized different issues; it does not prove either found more true defects. Ten overlap groups included reporter flags, unsafe endpoint mocks, duplicate socket close handling, the LSP Vitest dependency, real-timer flakiness, environment cleanup, repeated `importActual` hooks, and failed snapshot restoration.

### Severity and category mix

| Mix | Z.ai | StepFun |
|---|---:|---:|
| Critical | 1/61 (1.6%) | 0/31 |
| High | 20/61 (32.8%) | 11/31 (35.5%) |
| Medium | 25/61 (41.0%) | 15/31 (48.4%) |
| Low | 15/61 (24.6%) | 5/31 (16.1%) |
| Bug/correctness/reliability | 28/61 (45.9%) | 22/31 (71.0%) |
| Maintainability | 22/61 (36.1%) | 7/31 (22.6%) |
| Test | 8/61 (13.1%) | 2/31 (6.5%) |

StepFun labeled a larger share as defect-oriented and fewer as maintainability/test issues. Severity concentration was nearly equal: critical+high was **34.4% Z.ai versus 35.5% StepFun**. Because severity/category are model-generated labels, these are style signals, not independent defect severity.

### Validity and technical grounding

All 92 pair findings were independently adjudicated:

| Adjudication | Z.ai | StepFun |
|---|---:|---:|
| Valid | 35/61 (57.4%) | 17/31 (54.8%) |
| Partial | 22/61 (36.1%) | 10/31 (32.3%) |
| Invalid/unsupported | 4/61 (6.6%) | 4/31 (12.9%) |
| Valid + partial | 57/61 (93.4%) | 27/31 (87.1%) |

**Observation:** strict validity differed by only 2.5 percentage points. Z.ai’s supported share was 6.3 points higher, but many partial findings were defensive or assumption-heavy. StepFun’s four invalid findings form a larger percentage because its denominator is half as large.

**Interpretation:** neither output was clearly more technically grounded on strict validity. Z.ai more often supplied extensive causal narratives and cross-file references, but that detail sometimes became speculative or was attached to the wrong path. StepFun was generally more direct, but some claims still assumed runtime semantics not established by the excerpt.

Representative evidence:

- Z.ai specificity: `QZC-036` explained that child TypeScript `paths` replaces rather than deep-merges parent mappings (finding SHA `2ad333cc…ba1a`).
- Z.ai actionability: `QZC-051` identified silently dropped manifest entries (SHA `448cf7f8…e1b3`).
- StepFun specificity: `QSC-021` distinguished per-test timeout from an unbounded `Bun.spawnSync` child (SHA `9d96e01…29ab`).
- StepFun actionability: `QSC-025` identified silent `resetModules` no-ops (SHA `e876c953…bb0`), and the remediation changed them to explicit unsupported-operation errors. Full paths/hashes and concise quotations are in [source extracts](source-extracts.md).

### Verbosity and redundancy

| Measure | Z.ai | StepFun |
|---|---:|---:|
| Finding prose words | 5,704 | 2,367 |
| Mean words/finding | 93.51 | 76.35 |
| Duplicate/rephrased emissions | 10/61 (16.4%) | 2/31 (6.5%) |
| Suggestion attached | 55/61 (90.2%) | 14/31 (45.2%) |

Z.ai was **22.5% more verbose per finding** and emitted **2.41×** as much total finding prose. Its largest redundancy cluster repeated the `importActual`/`afterEach` root cause eight times, often on mismatched paths. StepFun’s main redundancy cluster repeated the proxy socket `end`/`close` concern three times. Z.ai supplied suggestions more often, but suggestion presence is not correctness.

The StepFun run used far more output tokens (**837,081 versus 162,437**) despite shorter final prose. That measures hidden review/tool-generation behavior, not report verbosity, and is not treated as quality.

### Specificity and stale context

| Measure | Z.ai | StepFun |
|---|---:|---:|
| Positive line number | 43/61 (70.5%) | 29/31 (93.5%) |
| Stale/misattributed context | 18/61 (29.5%) | 0/31 (0.0%) |

Z.ai repeatedly attached valid root claims to `bunfig.toml`, `package.json`, or other paths whose `existing_code` belonged to `test-setup/augment-bun-vi.ts`, `stub-helpers.ts`, or LSP code. This is a material triage defect: even a correct claim costs time when location metadata is wrong. StepFun had two file-level line-zero findings but no manually confirmed mismatched code/path in the pair.

### Usefulness and action/fix evidence

| Measure | Z.ai | StepFun |
|---|---:|---:|
| High usefulness | 9/61 (14.8%) | 5/31 (16.1%) |
| Medium usefulness | 16/61 (26.2%) | 12/31 (38.7%) |
| Low usefulness | 36/61 (59.0%) | 14/31 (45.2%) |
| High + medium | 25/61 (41.0%) | 17/31 (54.8%) |
| Findings fixed after pair | 23/61 (37.7%) | 10/31 (32.3%) |
| Deduplicated claims fixed | 16/51 (31.4%) | 10/29 (34.5%) |

The direct action source is later commit `e8a4ad1d5`, explicitly titled `fix(test): address Bun migration review findings`. It moved `afterEach` to module scope, hardened unsupported mock APIs, added LSP Vitest, improved endpoint/persistence tests, and changed stub restoration behavior, among other fixes. [E6]

Finding-level action slightly favors Z.ai because repeated versions of a fixed claim each count as actioned. After deduplication, StepFun is 3.1 points higher. This small one-pair difference is not a stable provider ranking. Both models saw the code before the same remediation, so overlap fixes cannot be credited causally to one.

No-action triage:

| Reason | Z.ai | StepFun |
|---|---:|---:|
| Partial/speculative or remedy not selected | 17 | 7 |
| Valid but no direct change in remediation commit | 16 | 8 |
| Duplicate/rephrased claim | 3 | 2 |
| Invalid/unsupported | 2 | 4 |
| **Total no direct fix** | **38** | **21** |

Some duplicate findings were actioned because their shared root claim was fixed; the no-action table therefore contains only duplicate emissions whose root claim was not directly changed.

## Cross-repository descriptive sample

| Provider | Runs | Repositories | Files | Findings | Findings/file | Words/finding | High+critical |
|---|---:|---|---:|---:|---:|---:|---:|
| Z.ai / GLM-5.2 | 3 | code, jefe, luther | 148 | 102 | 0.689189 | 84.70 | 35/102 (34.3%) |
| StepFun / Step-3.7-Flash | 3 | code, jefe, luther | 160 | 85 | 0.531250 | 71.86 | 31/85 (36.5%) |

Per-repository finding density was inconsistent:

- llxprt-code exact pair: Z.ai **0.678** versus StepFun **0.344**.
- llxprt-jefe unmatched: Z.ai **27/48 = 0.563** versus StepFun **19/52 = 0.365**.
- llxprt-luther unmatched: Z.ai **14/10 = 1.400** versus StepFun **35/18 = 1.944**, reversing direction.

This reversal is evidence against a simple provider-level volume rule. The Luther reviews covered different issues/remediation stages; the StepFun run also showed nine file-not-found context messages. The aggregate is a workload mixture, not an experiment.

## Provider, family, and period effects

### Direct observations

- Z.ai rows are GLM-5.2; StepFun rows are Step-3.7-Flash. [E4]
- No quality run was directly attributable to Ollama GLM-5.2.
- Most sampled Z.ai runs are earlier; sampled StepFun runs are later and often post-remediation.
- The exact pair narrows date/head/workload differences but does not separate model family from endpoint and is coverage-confounded by StepFun concurrency errors.

### Interpretation

- **Model-family effect:** not identifiable. Each model appears through one endpoint/provider only.
- **Provider-endpoint effect:** may contribute to coverage and output behavior, especially the 16 StepFun endpoint failures, but cannot be separated from model behavior.
- **Period/workload effect:** clearly material in unmatched data; repository and remediation-stage direction changes.
- **Ollama versus Z.ai GLM-5.2:** not estimable because no attributable Ollama quality run exists.

## Confidence assessment

| Conclusion | Confidence | Reason |
|---|---|---|
| Z.ai report was more verbose in M001 | High | Direct full-prose counts, same commit/denominator |
| Z.ai report was more redundant in M001 | Medium-high | Manual claim grouping is transparent; one pair |
| StepFun locations were cleaner in M001 | Medium-high | Large direct difference; manual stale classification |
| StepFun had denser high/medium usefulness | Medium | Full adjudication, but one unblinded rater and partial coverage |
| Strict technical validity was similar | Medium | Full pair adjudication; subjective borderline cases |
| Z.ai found more unique true defects | Low / not established | More claims, but no exhaustive ground truth and unequal completed coverage |
| StepFun was intrinsically more actionable | Low / not established | Small unique-action difference; paired exposure and remediation selection |
| Either model family is causally superior | Not supported | One pair; endpoint/model confounding; unmatched workload mixture |

## Decision guidance

1. Prefer **matched manifests and deduplicated claims** over raw finding count for future provider evaluation.
2. Require complete-file coverage before comparing finding density; rerun the 16 failed StepFun subtasks against the same immutable manifest.
3. Track provider/model, endpoint, OCR/rule hash, commit, selected/completed/failed files, changed lines/tokens, concurrency, and retry lineage in every run.
4. Score location correctness and duplicate burden as first-class quality costs.
5. Blind at least two adjudicators to provider labels and report agreement.
6. Attribute action at claim level, not emission level, and record explicit triage reasons.
7. Do not pool Z.ai GLM-5.2 with Ollama GLM-5.2; endpoint evidence must remain separate.

## Limitations

- One exact pair cannot establish a stable provider effect.
- StepFun’s pair member is partial; Z.ai also had read-context failures.
- Exact selected-file and changed-line manifests are absent.
- Retention is nonrandom and operator filenames are part of attribution.
- Unmatched repository samples differ in issue, date, range, and remediation stage.
- Adjudication is independent of the models but not blinded or multi-rater.
- Action evidence reflects developer choice and both reports, not objective defect truth.
- Later uncommitted branch-5 worktree changes were not counted as fixes.
- Reported severity and category are model labels, not external adjudication.

## Artifact map

- [provider-runs.csv](provider-runs.csv) — six directly attributable sampled runs
- [provider-findings.csv](provider-findings.csv) — 187 finding rows, with all 92 pair findings adjudicated
- [matched-reruns.csv](matched-reruns.csv) — paired input, overlap, coverage, and causal limits
- [quality-summary.csv](quality-summary.csv) — exact aggregates
- [methodology.md](methodology.md), [evidence-index.md](evidence-index.md), [source-extracts.md](source-extracts.md)
- [commands.md](commands.md), [build_dataset.py](build_dataset.py), [validation.py](validation.py), [file-inventory.txt](file-inventory.txt)
- [matched chart](matched-finding-volume.svg)

[E1]–[E8] refer to the stable source IDs in [evidence-index.md](evidence-index.md).
