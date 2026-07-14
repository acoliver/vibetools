# Source extracts

Access date: **2026-07-14**. Credentials and authorization values are excluded.

## Local operational evidence

### [L1] Ollama configuration snapshots

- Paths: `~/.opencodereview/config.json.bak`, `~/.opencodereview/config.json.ollama-bak`
- Metadata timestamps: 2026-06-27 17:17:41 and 20:48:06 -03:00.
- Redacted fields: provider `ollama-glm`, endpoint host `ollama.com`, OpenAI protocol, model `glm-5.2`.
- Limitation: configuration existence does not establish an exact active-use interval.

### [L2] Z.ai configuration snapshots

- Paths include `config.json.zai-rate-limited-20260710`, `config.json.pre-code-puppy-stepfun-20260711223406`, `config.json.zai-backup-20260713`, and `config.json.zai-rate-limited-bak`.
- Redacted fields: provider `zai-anthropic`, endpoint host `api.z.ai`, Anthropic protocol, model `glm-5.2`.
- Snapshot names and timestamps directly document repeated Z.ai/StepFun transitions and operator-observed rate limiting.

### [L3] StepFun configuration snapshots

- Paths include `config.json.stepfun-bak-20260713`, `config.json.stepfun-bak`, and `config.json.pre-stepfun-key-20260714045623`.
- Redacted fields: provider `stepfun`, endpoint host `api.stepfun.ai`, OpenAI protocol, model `step-3.7-flash`.
- Two different credential fingerprints existed before/after the 2026-07-14 04:56 snapshot. No key bytes are retained here.

### [L4] Direct failure and partial-output markers

- `$TMPDIR/ocr_chunk1.log`: terminal `review failed: all 4 file review(s) failed — check your LLM configuration and API key`.
- `$TMPDIR/ocr_review_2544.log`: JSON `completed_with_errors`, 12 reviewed files, 11 comments, and an `LLM completion error` from StepFun with HTTP 429 and a concurrency-limit message.
- `$TMPDIR/ocr_review_current.log`: repeated StepFun HTTP 429 `rate_limited` subtask errors.
- `$TMPDIR/ocr_review3.log`: repeated Z.ai HTTP 429 `rate_limit_error` subtask errors.
- `$TMPDIR/ocr_review_final_retry.log`: repeated Z.ai HTTP 529 `overloaded_error` subtask errors.
- Exact source hashes are row-level fields in `run-events.csv`.

### [L5] Session retention

`~/.opencodereview/sessions` contained 3,154 JSONL files (18,323,743,955 bytes): 1,941 path-attributed to llxprt-code, 432 to Jefe, 585 to Luther, and 196 other; 2,073 were nonempty and 1,081 empty. These are file counts, not run counts. Known session phrase matches in the parent [session extracts](../sources/excerpts/session-excerpts.md) corroborate selected local outputs.

### [L6] Existing local-versus-PR research

The parent [OCR retrospective](../report.md) documents 36 purposively sampled PR findings and 23 parseable local findings. Its [PR-2462 overlap snapshot](../sources/pr2462-overlap-snapshot.md) reports four local versus three later PR-side actionable findings and zero semantic overlaps, while warning that SHA/range/config equivalence is unproven.

## Official/public evidence

### [W1] Ollama pricing

URL: https://ollama.com/pricing

Official page states Pro is **US$20/month or US$200/year**, and Max is **US$100/month**. Max supports ten concurrent cloud models and five times Pro usage; plan limits include five-hour session and seven-day weekly resets. User says their account is the top consumer subscription; this report does not infer purchase price or billing interval.

### [W2] Ollama cloud documentation

URL: https://docs.ollama.com/cloud

Official documentation says cloud models may be accessed through Ollama's cloud API and require an account/API key. This supports classifying the retained `ollama.com` endpoint as cloud rather than local inference.

### [W3] Z.ai GLM Coding Plan overview

URL: https://docs.z.ai/devpack/overview

Official documentation says all plans support GLM-5.2. It describes estimated five-hour/weekly limits of Lite ~80/~400 prompts, Pro ~400/~2,000, and Max ~1,600/~8,000, with actual use depending on project complexity and repository size. It says GLM-5.2 consumes a multiplier depending on peak/off-peak policy.

### [W4] Z.ai usage policy and FAQ

URLs: https://docs.z.ai/devpack/usage-policy and https://docs.z.ai/devpack/faq

Official policy says concurrency limits are tier-dependent, dynamically adjusted with resource availability, generally Max > Pro > Lite. The FAQ says exhausted Coding Plan quota waits for the next five-hour cycle rather than consuming account balance. These pages do not document the user's historical purchase price.

### [W5] StepFun Step Plan overview

URL: https://platform.stepfun.com/docs/zh/step-plan/overview

Official Chinese documentation currently lists Flash Pro at ¥199 monthly / ¥539 quarterly / ¥1,860 annually with 8,000M monthly Credits, and Flash Max at ¥699 / ¥1,889 / ¥6,666 with 40,000M Credits. It says Credits expire monthly and Step Plan usage is separate from ordinary account balance. These current labels are “Flash Pro/Max”; the user described prior “StepFun Pro” and current “StepFun Max.” Exact historical purchase terms are not established.

### [W6] StepFun Step-3.7-Flash

URL: https://platform.stepfun.com/docs/zh/guides/models/step-3.7-flash

Official documentation lists pay-as-you-go rates per million tokens: ¥0.27 cache-hit input, ¥1.35 uncached input, and ¥8.1 output. OCR used a Step Plan endpoint, so these rates explain Credit conversion but do not prove an incremental cash charge for each retained run.

### [W7] StepFun paid-service agreement

URL: https://platform.stepfun.com/docs/zh/step-plan/paid-service-agreement

Effective 2026-05-25. Official agreement says plan limits may include request frequency, token/use caps, concurrency, and model/tool limits; limits can be dynamically adjusted; reaching a limit can reject, delay, queue, or downgrade requests. This is consistent with observed HTTP 429 concurrency failures but does not establish why any specific request was limited.
