# Evidence index

Access date: **2026-07-14**. See [source extracts](source-extracts.md) for redacted claims and limitations.

| ID | Source | Type / authority | Use | Limitation |
|---|---|---|---|---|
| E1 | `run-events.csv` source paths/hashes | Direct local execution | Canonical 145-attempt ledger | Retained, nonrandom subset; original logs are mutable temporary files |
| E2 | `~/.opencodereview/config.json*` | Direct configuration metadata | Provider/model transition bounds | Config timestamp is not necessarily switch time; credentials excluded |
| E3 | `~/.opencodereview/sessions/**/*.jsonl` | Direct session artifacts | Repository/time corroboration | 18.3 GB; 1,081/3,154 empty; not counted as independent runs |
| E4 | [Parent OCR report](../report.md) | Prior structured local/PR research | 23 local versus 36 PR sample | Different sampling and inputs |
| E5 | [PR-2462 overlap](../sources/pr2462-overlap-snapshot.md) | Near-matched manual comparison | 4 local, 3 PR-side, zero overlap | Inputs not identical; no causal recall claim |
| E6 | [Ollama pricing](https://ollama.com/pricing) | Official Tier 1 | Current price/limits | Not user's invoice; page can change |
| E7 | [Ollama cloud docs](https://docs.ollama.com/cloud) | Official Tier 1 | Cloud/API characterization | No historical account record |
| E8 | [Z.ai overview](https://docs.z.ai/devpack/overview) | Official Tier 1 | Models and estimated quotas | Dynamic/estimated limits; current page |
| E9 | [Z.ai usage policy](https://docs.z.ai/devpack/usage-policy) | Official Tier 1 | Dynamic concurrency policy | Does not explain a specific 429 |
| E10 | [Z.ai FAQ](https://docs.z.ai/devpack/faq) | Official Tier 1 | Quota exhaustion behavior | Current policy, not historical invoice |
| E11 | [Step Plan overview](https://platform.stepfun.com/docs/zh/step-plan/overview) | Official Tier 1 | Current tiers, Credits, prices | Chinese current terms may differ from purchase terms |
| E12 | [Step-3.7-Flash](https://platform.stepfun.com/docs/zh/guides/models/step-3.7-flash) | Official Tier 1 | Model/rate evidence | PAYG rates are not per-run subscription charges |
| E13 | [StepFun agreement](https://platform.stepfun.com/docs/zh/step-plan/paid-service-agreement) | Official Tier 1 | Dynamic limits and failure modes | General policy, not incident root-cause record |
| E14 | User-supplied account chronology | Authoritative for user facts | Ollama top subscription; old top-tier annual Z.ai; StepFun Pro→Max | No independent amount/date verification |

## Source weighting

Official pages score high on authority/directness for current public terms, but low for the user's historical transaction. Local execution output scores highest for individual run status. Configuration snapshots score high for provider/model existence and medium for exact transition timing. User-supplied account tiers are accepted as facts per task instruction but exact timestamps are inferred only where a credential snapshot bounds a change.

## Hash provenance

Every canonical event stores source SHA-256 in `run-events.csv`. `file-inventory.txt` stores hashes for all final checked-in artifacts except itself; a self-hash would be recursive. Temporary credentials/config files are never copied or hashed into the report inventory.
