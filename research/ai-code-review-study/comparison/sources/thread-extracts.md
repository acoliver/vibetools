# Compact matched-thread extracts

Retrieved 2026-07-14 with `gh` only. Generated hidden payloads and long analysis chains are omitted. Human-looking replies are treated as LLM-authored actions.

## E1 — code #2462: independent unique fixes from both reviewers

- OCR OAuth guard: <https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3552518703>
- OCR URL ordering: <https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3552518710>
- CodeRabbit trust docs: <https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3552555636>
- Joint disposition: <https://github.com/vybestack/llxprt-code/pull/2462#issuecomment-4926675538>

> **OCR:** the in-flight OAuth guard keys only on server name and can reuse a promise for a different server URL.
>
> **CodeRabbit:** canonical examples set `trust: true`, bypassing tool-call confirmation.
>
> **LLM-authored action:** added the server URL to the guard key; anchored extraction after the deprecation signal; removed `trust: true` from three examples and added a security caveat.

Classification: unique valid fixes from both reviewers; no semantic overlap.

## E2 — code #2547: semantic overlap with different remedy scope

- OCR: <https://github.com/vybestack/llxprt-code/pull/2547#discussion_r3568796774>
- OCR action: <https://github.com/vybestack/llxprt-code/pull/2547#discussion_r3569081019>
- CodeRabbit: <https://github.com/vybestack/llxprt-code/pull/2547#discussion_r3568818388>
- CodeRabbit response: <https://github.com/vybestack/llxprt-code/pull/2547#discussion_r3569089285>

> **OCR:** post-unmount React state does not prove the listener was removed.
>
> **CodeRabbit:** the test under-verifies core, IDE, and MCP cleanup wiring.
>
> **LLM-authored action:** measure the exact `FolderTrustChanged` listener count before mount, after registration, and after unmount.
>
> **CodeRabbit:** agreed this black-box assertion was stronger than checking private mock choreography and withdrew.

Classification: semantic overlap; OCR valid/fixed; CodeRabbit partial/dismissed after its broader remedy was narrowed.

## E3 — Jefe #181: repeated exact convergence without selected-head adjudication

- OCR line index: <https://github.com/vybestack/llxprt-jefe/pull/181#discussion_r3561601644>
- CodeRabbit line index: <https://github.com/vybestack/llxprt-jefe/pull/181#discussion_r3561658080>
- OCR confirm visuals: <https://github.com/vybestack/llxprt-jefe/pull/181#discussion_r3561603236>
- CodeRabbit confirm visuals: <https://github.com/vybestack/llxprt-jefe/pull/181#discussion_r3561658102>

Both reviewers independently identified repeated line-index increment boilerplate and loss of confirm-modal visual distinction. No direct disposition is linked to these selected final-head roots.

Classification: exact overlaps; unadjudicated; no superiority inference.

## E4 — Jefe #288: critical exact overlap

- OCR: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575420885>
- CodeRabbit: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575442408>

Both reviewers traced the same scenario: after the first untracked sibling removes an empty parent, processing the second sibling can surface `NotFound` even though cleanup reached the desired state.

Classification: exact overlap; potentially high materiality; selected threads unadjudicated.

## E5 — Jefe #288: independent technical rejection and one unique fix

- OCR symlink recommendation: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575420878>
- OCR dismissal: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575604585>
- CodeRabbit Windows recommendation: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575442403>
- CodeRabbit withdrawal: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575607047>
- CodeRabbit case-insensitive owned-path fix: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575442399>

> **LLM-authored response to OCR:** following PATH symlinks is standard Unix executable lookup behavior; rejecting them would break normal installations.
>
> **LLM-authored response to CodeRabbit:** the proposed Windows reparse-point premise was unreliable and recursive removal could traverse a target.
>
> **CodeRabbit:** agreed its suggested fix could create a correctness/safety hazard and withdrew.

The same CodeRabbit iteration uniquely found a case-sensitive `.jefe`/`.llxprt` comparison on case-insensitive hosts; the thread records it as addressed.

Classification: one invalid dismissal for each reviewer; one CodeRabbit-only valid fixed finding.

## E6 — Luther #110: three exact shared fixes and unique CodeRabbit fixes

- Shared active-parent-label concern:
  - OCR: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525454606>
  - CodeRabbit: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525236636>
- Shared missing-resume concern:
  - OCR: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525454926>
  - CodeRabbit: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525236640>
- Shared SQLite concern:
  - OCR: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525455138>
  - CodeRabbit: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525236643>
- CodeRabbit-only pagination: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525236630>
- CodeRabbit-only API fallback: <https://github.com/vybestack/llxprt-luther/pull/110#discussion_r3525236632>

Direct replies validate and fix all five concerns. CodeRabbit verification confirms pagination accumulation beyond the first 100 children and fallback after native lookup failure.

Classification: three exact overlaps fixed by both; two high-usefulness CodeRabbit-only fixes.

## E7 — Luther #133: disjoint and unadjudicated selected findings

- OCR warning aggregation: <https://github.com/vybestack/llxprt-luther/pull/133#discussion_r3565876024>
- OCR concurrent status classification: <https://github.com/vybestack/llxprt-luther/pull/133#discussion_r3565876261>
- CodeRabbit environment lock: <https://github.com/vybestack/llxprt-luther/pull/133#discussion_r3565876541>

OCR identified possible loss of multiple artifact warnings and a concurrency-status classification risk. CodeRabbit identified an unshared process-global environment-variable test lock. No selected-head disposition was observed.

Classification: reviewer-unique potential defects; all unadjudicated.

## Rate-limit state examples

- Jefe #288: <https://github.com/vybestack/llxprt-jefe/pull/288#issuecomment-4964256014>
- Luther #110: <https://github.com/vybestack/llxprt-luther/pull/110#issuecomment-4886708289>
- Luther #133: <https://github.com/vybestack/llxprt-luther/pull/133#issuecomment-4949785176>

Each current mutable comment explicitly says `Review limit reached`. Those blocked states are excluded, while completed exact-head root findings on the same PR remain in the cohort.
