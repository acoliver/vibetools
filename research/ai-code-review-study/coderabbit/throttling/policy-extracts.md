# External CodeRabbit policy extracts

**Access date:** 2026-07-14. These are compact quotations, not full snapshots. Wayback timestamps are UTC capture times. Current pages are mutable.

## P1 — 2023 official engineering blog

- Title: *How we built a cost-effective Generative AI application*
- Organization/author: CodeRabbit / Aravind Putrevu
- Published: 2023-12-22
- URL: <https://www.coderabbit.ai/blog/how-we-built-cost-effective-generative-ai-application>
- Type: official engineering explanation
- Extract: “we implemented hourly rate limits on the number of files and commits reviewed per user”; limits were “more aggressive ... for open-source users compared to trial and paid users”; example OSS policy: “3 reviews per hour (1 review every 20 minutes) ... allowing a burst of 2 back-to-back reviews.”
- Limitation: this accurately documents the 2023 implementation, not necessarily the 2025–2026 policy.

## P2 — pricing page at first VybeStack-use period

- Archived URL: <https://web.archive.org/web/20251105200221id_/https://www.coderabbit.ai/pricing>
- Archive timestamp: 2025-11-05 20:02:21 UTC
- Type: official pricing page, archived
- Extracts:
  - “Lite ... $12/month, billed annually or $15/monthly per developer” and “Unlimited pull request reviews.”
  - “Pro ... $24/month ... or $30/monthly per developer.”
  - “Working on an Open Source project? Pro is free forever ... Get unlimited reviews on public repos.”
  - Billing FAQ: “only ... developers who create pull requests”; seats could be manually assigned.
- Limitation: “unlimited” was marketing language. It did not enumerate hourly fair-use limits and conflicts with the older official engineering blog’s OSS throttling; it cannot prove unlimited throughput.

## P3 — archived 2026-05-02 plans table

- Archived URL: <https://web.archive.org/web/20260502104924id_/https://docs.coderabbit.ai/management/plans>
- Archive timestamp: 2026-05-02 10:49:24 UTC
- Type: official documentation, archived
- Extracts:
  - “The following limits are enforced per developer.”
  - PR limits in the table: Free `3 (summary only)`, Trial `4`, OSS `2`, Pro `5`, Pro+ `10`, Enterprise `12`.
  - “Rate limits use a refilling bucket model ... a 5/hour limit refills one unit every 12 minutes.”
  - Each plan was described as per developer; OSS was explicitly lower than paid plans.
- Limitation: this capture predates VybeStack’s first retained block by 38 days and is the closest archived primary policy found before the observed event period.

## P4 — June policy transition

- Archived URL: <https://web.archive.org/web/20260613223630id_/https://docs.coderabbit.ai/management/plans>
- Archive timestamp: 2026-06-13 22:36:30 UTC
- Type: official documentation, archived
- Extracts:
  - Free/OSS/Pro/Pro+/Enterprise PR availability shown as `3`, `1-10`, `5`, `10`, `12` (Free was summary-only in plan prose).
  - “Each PR review run uses one PR review ... including automatic incremental reviews after new pushes, manual `@coderabbitai review`, and manual `@coderabbitai full review`.”
  - Fair usage: sustained or concentrated activity by “one developer identity” could cause CodeRabbit to “temporarily space out additional PR reviews for that developer”; based on recent activity “in the organization.”
  - Recommended `auto_pause_after_reviewed_commits` of `1` or `2` for active branches.
- Limitation: the page did not yet disclose numeric adaptive bands. It was already live four days after VybeStack’s first retained block.

## P5 — 2026-06-24/28 disclosed adaptive bands

- Archived URLs:
  - <https://web.archive.org/web/20260624211719id_/https://docs.coderabbit.ai/management/plans>
  - <https://web.archive.org/web/20260628195617id_/https://docs.coderabbit.ai/management/plans>
- Archive timestamps: 2026-06-24 21:17:19 and 2026-06-28 19:56:17 UTC
- Type: official documentation, archived
- Extracts:
  - limits are “per developer over rolling time windows”; no top-of-hour reset.
  - Pro bands reached `1 review/hour, one review at a time` at `60+` recent seven-day reviews.
  - Pro+ bands reached that floor at `130+` recent seven-day reviews.
  - “When one developer identity reaches the 95th percentile or higher ... CodeRabbit gradually spaces out additional reviews.”
- Limitation: this is policy disclosure, not evidence of VybeStack’s subscription.

## P6 — current policy at cutoff

- URL: <https://docs.coderabbit.ai/management/plans>
- Accessed: 2026-07-14
- Type: official live documentation
- Extracts:
  - PR reviews/hour: Free `1` summary-only; OSS `1-10`; Pro `5`; Pro+ `10`; Enterprise `12`.
  - limits are per developer over rolling time windows.
  - current Pro+ adaptive floor starts at `90+` seven-day reviews, versus `130+` in the June 28 archive; Pro floor remains `60+`.
  - current docs state the 14-day default trial starts on Pro+ at 10 PR reviews/developer/hour.
- Interpretation: the Pro+ fair-use bands materially tightened between the 2026-06-28 capture and the 2026-07-14 access date. This bot-side policy change is a plausible contributor to late-period blocks.

## P7 — current automatic review accounting

- URL: <https://docs.coderabbit.ai/configuration/auto-review>
- Accessed: 2026-07-14
- Extracts:
  - `auto_incremental_review: true` is the default and reviews updates after each push.
  - `auto_pause_after_reviewed_commits: 5` is the current default.
  - automatic incremental reviews consume the same per-developer allowance as manual reviews.
  - CodeRabbit recommends `1` or `2` for noisy branches.
- Limitation: current defaults are not back-projected to every historical run; repository UI configuration can override them.

## P8 — seats and usage add-on

- Seat URL: <https://docs.coderabbit.ai/management/seat-assignment>
- Add-on URL: <https://docs.coderabbit.ai/management/usage-based-addon>
- Accessed: 2026-07-14
- Extracts:
  - trial seats are provisioned when a user raises a PR; post-trial organizations move to manual approval unless configured otherwise.
  - unseated users can still receive a free-tier summary.
  - Pro/Pro+/Enterprise can buy over-limit capacity at `$0.25` per reviewed file; the organization shares one credit balance.
  - the assigned user’s plan allowance is used first.
- Interpretation: documented throttling is developer/seat scoped inside an organization, while optional overflow billing is organization-shared.

## P9 — current pricing and legacy-plan transition

- URL: <https://www.coderabbit.ai/pricing>
- Accessed: 2026-07-14
- Extracts: Pro `$24` annual / `$30` monthly; Pro Plus `$48` annual / `$60` monthly; Free is PR summarization plus IDE/CLI reviews; only PR creators are charged.
- Changelog URL: <https://docs.coderabbit.ai/changelog>
- Search-verified changelog extract: Lite and Pro Legacy were retired on 2026-06-08 and affected customers were moved to Pro at no added cost.
- Limitation: no VybeStack billing record or announcement was found. The legacy migration is a vendor-wide alternative explanation, not evidence that VybeStack was affected.

## Archived-source discovery record

Wayback CDX returned plan-page captures at `20260502104924`, `20260613223630`, `20260624211719`, `20260626145231`, and `20260628195617`; pricing captures included `20251105200221`, `20260428154602`, and `20260711131840`. CDX URLs and commands are retained in [commands.md](commands.md).
