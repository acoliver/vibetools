# Source extracts

Access date: **2026-07-14**. Credentials and unrelated payloads are excluded. Finding hashes are SHA-256 over the complete prose in `provider-findings.csv`; excerpts below are shortened.

## E1 — exact Z.ai matched run (`QZC`)

- Source: `$TMPDIR/ocr_zai_glm.log`
- Source SHA-256: `456fbe11d20140fa62e87f84bdfdfc5b2613fa5ccb77454de29b8b77d8f17df5`
- Exact session: `~/.opencodereview/sessions/Users-acoliver-projects-llxprt-branch-5-llxprt-code/500dc34f-fc7c-4043-9b18-df16906b825c.jsonl`
- Direct extract: status `success`; 90 files; 61 comments; 13,425,145 total tokens; 162,437 output tokens; 50m45s.
- Input identity: repeated `git show b8ee089626e88952161a17191e213e33048d5e5c:...` markers.
- Limitation: five pre-result file-read errors appear even though terminal warnings are empty.

Representative findings:

- `QZC-001`, finding hash `50eeb3330ef13032678e7b346e945927141503a445ccb80fa837377c26612283`: “The `afterEach` hook is registered inside the `importActual` function body... a new duplicate `afterEach` hook is registered.” This was technically grounded and fixed, but emitted eight times across mismatched paths.
- `QZC-036`, finding hash `2ad333cc2809c56510eaedb84c27b92154a3257b91d779d26bcce10f00cbba1a`: “TypeScript does not deep-merge `paths` when extending a config—the child’s `paths` entirely replaces the parent’s.” This is specific and technically reasoned, though not directly changed by the paired remediation commit.
- `QZC-051`, finding hash `448cf7f82968c455bfc755dfb545bfa15d83320252a06df7b4b207a62935e1b3`: “The `.filter(({ file }) => existsSync(file))` silently drops any manifest entry whose file doesn’t exist on disk.” This is concrete and actionable.

## E2 — exact StepFun matched run (`QSC`)

- Source: `$TMPDIR/ocr_final.log`
- Source SHA-256: `89f2dea57bdc5a10ecd5a229fdba4b98e01cae740bf8c90466c553d7f65b2082`
- Exact session: `~/.opencodereview/sessions/Users-acoliver-projects-llxprt-branch-5-llxprt-code/b76d72c5-4f7b-4e8d-9a25-dbee349062f7.jsonl`
- Direct extract: status `completed_with_errors`; 90 files; 31 comments; 6,018,483 total tokens; 837,081 output tokens; 1h42m59s.
- Provider evidence: 16 warnings name `https://api.stepfun.ai/step_plan/v1/...` and report concurrency `current: 16, limit: 15`.
- Input identity: `git show b8ee089626e88952161a17191e213e33048d5e5c:...` marker.

Representative findings:

- `QSC-008`, finding hash `e595cd340e11f07babc2cd765b4b409706dc3f09fb7d6e1b7927fb9686fd5a7a`: “Treating the socket `end` event as equivalent to `close` ... will likely cause duplicate destroy/error handling.” The same root claim was repeated three times.
- `QSC-021`, finding hash `9d96e01eee2884b201c2e774d1d75e91f58f6235f859549b0e3863b7e83829ab`: “`Bun.spawnSync` has no process-level timeout... this script blocks indefinitely.” This is specific, technically grounded, and not directly actioned in the paired remediation commit.
- `QSC-025`, finding hash `e876c9535af1ae02871dcee4619c6be6a27ca86bb207e44414d5eb446c945bb0`: “`resetModules` is a silent no-op... tests ... silently leak module state.” The remediation commit changed silent no-ops to explicit unsupported-operation errors.
- `QSC-030`, finding hash `291048394acc4c45c986bdce990a494257715384012f7dbdd3be1b4802089d13`: “`restoreAll()` clears `this.snapshots` before checking for restoration errors... prevents retrying failed restorations.” Directly actioned.

## E3 — direct Z.ai endpoint companion

- Source: `$TMPDIR/ocr_zai_final.log`
- Source SHA-256: `5484f23b671ecea19c6d94a4b3481eebc7144ec1453188ab53ba13f284f521ef`
- Exact session: `~/.opencodereview/sessions/Users-acoliver-projects-llxprt-branch-5-llxprt-code/5e097d3d-102e-416f-ad02-a0616c543e94.jsonl`
- Direct extract: same 90-file commit review, started 10m14s before `QZC`; warnings name `https://api.z.ai/api/anthropic/v1/messages`.
- Use: corroborates that the operator-named `ocr_zai_glm.log` belongs to the adjacent Z.ai rerun series. The retained Z.ai config names model `glm-5.2`.
- Limitation: E3 is not the primary matched Z.ai output because it was partial and had a different finding set.

## E4 — provider/model configurations (redacted)

Retained config snapshots establish:

| Snapshot | Provider | Endpoint host | Protocol | Model |
|---|---|---|---|---|
| `~/.opencodereview/config.json.zai-rate-limited-bak` | `zai-anthropic` | `api.z.ai` | Anthropic | `glm-5.2` |
| `~/.opencodereview/config.json.stepfun-bak-20260713` | `stepfun` | `api.stepfun.ai` | OpenAI-compatible | `step-3.7-flash` |
| `~/.opencodereview/config.json.bak` | Ollama | Ollama cloud host | retained snapshot | `glm-5.2` |

Credential fields are omitted. The Ollama snapshot proves configuration, not a retained run in the quality sample.

## E5 — immutable reviewed commit

- Repository object available in `$HOME/projects/llxprt/branch-5/llxprt-code`.
- Commit: `b8ee089626e88952161a17191e213e33048d5e5c`
- Parents: `5e64654b42a6d973f124c308e912f4d9b4ec47d8`, `d3eefc8fd62bb964a51f6b54f75c9b409621fcd9`
- Commit time: 2026-07-13 20:40:03 -03:00
- Subject: `Temporary updated merge for OCR review`

Both E1 and E2 directly refer to this commit.

## E6 — paired remediation action

- Repository: `$HOME/projects/llxprt/branch-5/llxprt-code`
- Commit: `e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf`
- Parent: `94996d6d97058462af4b24ef4322318381a6eb11`
- Commit time: 2026-07-14 00:55:16 -03:00
- Subject: `fix(test): address Bun migration review findings`
- Directly relevant changed areas include `packages/a2a-server/src/http/*`, `packages/a2a-server/src/persistence/gcs*`, `packages/lsp/package.json`, `scripts/tests/*`, `test-setup/augment-bun-vi*`, `test-setup/bun-vitest-compat.ts`, and `test-setup/stub-helpers.ts`.

The commit is on a sibling integration line rather than a descendant of temporary merge E5. The diff nevertheless directly changes exact code and behaviors reported by the pair. It supports `fixed_after_pair`, not provider-specific causation.

## E7 — unmatched cross-repository sample

| Run | Repository | Provider/model | Source | SHA-256 | Files/findings |
|---|---|---|---|---|---:|
| QZJ | llxprt-jefe | Z.ai / GLM-5.2 | `$TMPDIR/ocr_issue184_review.log` | `1ad1566673da5974549108bc09ca3cd66e2277dce68eecf05c73da84d77d314d` | 48 / 27 |
| QZL | llxprt-luther | Z.ai / GLM-5.2 | `$TMPDIR/ocr_issue131.log` | `3e869fa7173fe68c22b6733445c17bbc5b1c0e68f0ddc404cf33fd18208be528` | 10 / 14 |
| QSJ | llxprt-jefe | StepFun / Step-3.7-Flash | `$TMPDIR/ocr_review_294_stepfun.log` | `740d11f5e0e88764210ba5c2a07269fb19905901f57e1cfdd44891243c728ecc` | 52 / 19 |
| QSL | llxprt-luther | StepFun / Step-3.7-Flash | `$TMPDIR/ocr_issue135_stepfun.log` | `3d111f20595a5c8467713d97a91ac17a39db2c5a53fefba6f09c61dc9b13ac4e` | 18 / 35 |

These are stratified descriptive runs, not matched comparisons. QSL also contains nine pre-result file-not-found messages, illustrating remediation/worktree context mismatch.

## E8 — existing reliability and prior OCR research

- `../reliability/run-events.csv`: canonical discovery ledger for 145 retained attempts.
- `../reliability/provider-timeline.csv`: redacted transition chronology.
- `../reliability/report.md`: retained-run reliability analysis.
- `../sources/local-findings.csv` and `../sources/sampled-findings.csv`: prior local/PR finding evidence.
- `../sources/pr2462-overlap-snapshot.md`: prior near-matched local/PR comparison.

These sources guide discovery and confounder assessment. Reliability success rate is not used as finding quality.
