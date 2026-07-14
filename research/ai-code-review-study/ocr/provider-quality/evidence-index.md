# Evidence index

Access date: **2026-07-14**. Detailed redacted extracts are in [source-extracts.md](source-extracts.md); methods are in [methodology.md](methodology.md).

| ID | Source | Authority/directness | Use | Limitation |
|---|---|---|---|---|
| E1 | `$TMPDIR/ocr_zai_glm.log`, SHA-256 `456fbe11…17df5`; exact session `…/500dc34f-….jsonl` | Direct OCR output | Z.ai side of exact pair M001 | Operator-named attribution; direct endpoint is in adjacent same-head E3 |
| E2 | `$TMPDIR/ocr_final.log`, SHA-256 `89f2dea5…b2082`; exact session `…/b76d72c5-….jsonl` | Direct OCR output | StepFun side of exact pair M001 | 16 failed subtasks make finding count coverage-confounded |
| E3 | `$TMPDIR/ocr_zai_final.log`, SHA-256 `5484f23b…21ef`; exact session `…/5e097d3d-….jsonl` | Direct same-head endpoint output | Corroborates `api.z.ai` immediately before E1 | Partial companion run, not the primary pair member |
| E4 | `~/.opencodereview/config.json*` redacted metadata; [provider timeline](../reliability/provider-timeline.csv) | Direct configuration snapshots | Models: Z.ai `glm-5.2`, StepFun `step-3.7-flash`; transition bounds | Snapshot time need not equal exact switch time; secrets excluded |
| E5 | Git object `b8ee089626e88952161a17191e213e33048d5e5c` in branch-5 worktree | Direct source/commit evidence | Immutable matched input identity | Temporary merge is not in current branch-4 object store |
| E6 | Git commit `e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf` | Direct remediation evidence | Finding action/fix adjudication | Both reports preceded it; cannot credit one provider; sibling integration line |
| E7 | QZJ/QZL/QSJ/QSL raw logs with hashes in `provider-runs.csv` | Direct OCR output | Cross-repository stratified description | Unmatched heads/ranges/stages; no causal comparison |
| E8 | [Existing run ledger](../reliability/run-events.csv), [reliability report](../reliability/report.md), and [prior source datasets](../sources/) | Structured prior local research | Discovery, chronology, confounders, prior local/PR context | Reliability is not finding quality; prior samples use other designs |
| D1 | [provider-runs.csv](provider-runs.csv) | Derived, reproducible dataset | Six-run sample and attribution evidence | Nonrandom retained sample |
| D2 | [provider-findings.csv](provider-findings.csv) | Derived + independent adjudication | 187 findings; all 92 exact-pair findings adjudicated | Single researcher; unmatched findings not adjudicated |
| D3 | [matched-reruns.csv](matched-reruns.csv) | Derived paired evidence | Overlap and input-equivalence record | Missing exact selected-file manifest |
| D4 | [quality-summary.csv](quality-summary.csv) | Derived aggregates | Exact metrics cited in report | Manual quality columns apply only to M001 |
| V1 | [validation.py](validation.py) | Reproducibility control | Aggregates, hashes, links, credentials, target-only writes | Validates documentary artifacts, not application behavior |

## Source weighting

- **Highest weight:** E1/E2/E5 for same-input observations; E6 for direct action evidence.
- **High weight with attribution caveat:** E3/E4 for endpoint/model identification.
- **Medium weight:** E7 for repository breadth because inputs are unmatched.
- **Context only:** E8. Its run-success metrics are deliberately not interpreted as finding quality.

## Independence

E1 and E2 are independent model executions over the same commit but share OCR tooling, rules, repository context, and later remediation. E3 is not independent corroboration of finding quality; it corroborates endpoint attribution. E6 can reflect triage of both reports. The unmatched samples are different workloads, not independent replications of M001.

## Retention and redaction

Raw source paths remain outside this research directory and may be mutable temporary files; SHA-256 preserves the observed identity. No raw config or session payload is copied. Credential values and unrelated data are excluded. `file-inventory.txt` hashes every final artifact except itself.
