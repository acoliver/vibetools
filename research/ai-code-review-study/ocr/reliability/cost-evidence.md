# Cost evidence and model

## Separation of cost types

1. **Subscription acquisition cost** is the amount paid to obtain a plan. Current official list prices are not necessarily the user's historical transaction price.
2. **Per-review marginal cash cost** is an incremental provider charge caused by one OCR review. For included subscription quota, this may be zero until quota/add-on boundaries, but no billing ledger was inspected.
3. **Quota/opportunity cost** is included usage consumed by one review, reducing capacity for later work.
4. **Operational cost** is human/agent time spent detecting partial coverage, retrying, switching providers/accounts, deduplicating findings, and triaging outputs. This audit does not assign a monetary labor rate.

## Documented public prices (accessed 2026-07-14)

| Provider | Official evidence | Current public amount | Applicability |
|---|---|---:|---|
| Ollama | [Pricing](https://ollama.com/pricing) | Pro US$20/mo or US$200/yr; Max US$100/mo | User says top consumer subscription; exact purchase amount/billing term not documented locally. |
| Z.ai | [Overview](https://docs.z.ai/devpack/overview) | Starts at US$18/mo; public docs distinguish Lite/Pro/Max | User says an older top-tier annual subscription with higher limits. Exact historical tier label, price, and purchase date are not documented; no amount is assigned. |
| StepFun | [Step Plan overview](https://platform.stepfun.com/docs/zh/step-plan/overview) | Flash Pro ¥199/mo, ¥539/qtr, ¥1,860/yr; Flash Max ¥699/mo, ¥1,889/qtr, ¥6,666/yr | Current list prices only. User says prior Pro/current Max; exact paid amount and transition purchase terms are unknown. |
| StepFun API reference | [Step-3.7-Flash](https://platform.stepfun.com/docs/zh/guides/models/step-3.7-flash) | ¥0.27/M cached input; ¥1.35/M uncached input; ¥8.1/M output | Reference usage rates/Credit conversion; not evidence that subscription OCR runs generated separate cash charges. |

## Quantitative cost framework

For review *i*:

`economic cost_i = marginal cash_i + quota opportunity_i + retry/triage labor_i`

For a period:

`cost per fully successful retained output = (allocated subscription + add-ons + operational labor) / full successes`

The audit can compute the denominator (117 full successes), but not the numerator because invoices, add-ons, account usage ledgers, and labor time are absent. Substituting current list price would create false precision.

Observed operational burden is measurable without money: **28/145 attempts (19.3%) were not full successes**—25 partial and 3 hard failures. Nineteen partials carried HTTP 429 markers and six carried HTTP 529 overload markers. At minimum, these events required coverage awareness; filenames indicate retries/transitions, but exact added labor and retry causality cannot be reconstructed safely.

## Interpretation

- A subscription can make an individual retry have **no immediate extra cash charge** while still consuming quota and creating triage cost.
- A higher tier can increase available quota/concurrency, but the retained Max-attributed interval still had 4/10 partial outputs; that descriptive result is too small and confounded to evaluate plan value causally.
- Provider switching is a reliability hedge only if run manifests expose missing files and findings are deduplicated; otherwise it can increase review volume and operational cost without known incremental recall.
