# Sampled thread extracts

Retrieved 2026-07-14 with `gh` only. Excerpts are compact, remove HTML/detail boilerplate and organization identifiers, and preserve the substantive wording. URLs are the exact GitHub evidence.

## E1 — accepted test-isolation finding

- Finding: <https://github.com/vybestack/llxprt-code/pull/1980#discussion_r3383949562>
- LLM action: <https://github.com/vybestack/llxprt-code/pull/1980#discussion_r3384509999>
- CodeRabbit verification: <https://github.com/vybestack/llxprt-code/pull/1980#discussion_r3384510944>

> **CodeRabbit:** “`global.fetch` patch is not failure-safe and can leak across tests.”
>
> **LLM-authored response:** “Addressed in commit 5fa2028 by restoring global.fetch in finally blocks for both patched-fetch tests.”
>
> **CodeRabbit:** wrapping both tests in `try/finally` ensures restoration “regardless of assertion failures.”

Classification: validated; fixed; useful.

## E2 — reasoned deferral accepted by CodeRabbit

- Finding: <https://github.com/vybestack/llxprt-code/pull/2383#discussion_r3525542541>
- LLM action: <https://github.com/vybestack/llxprt-code/pull/2383#discussion_r3525634659>
- CodeRabbit withdrawal: <https://github.com/vybestack/llxprt-code/pull/2383#discussion_r3525635061>

> **LLM-authored response:** the reported Gemini fallback was fixed; only a secondary model field could lag for one turn, a distinct UX refinement.
>
> **CodeRabbit:** “that reasoning holds up” and “Deferring it is reasonable.”

Classification: validated observation; deferred; useful because it separated a real but out-of-scope refinement from the blocking defect.

## E3 — false positive challenged and withdrawn

- Finding: <https://github.com/vybestack/llxprt-code/pull/2440#discussion_r3542221688>
- LLM action: <https://github.com/vybestack/llxprt-code/pull/2440#discussion_r3544462756>
- CodeRabbit withdrawal: <https://github.com/vybestack/llxprt-code/pull/2440#discussion_r3544465535>

> **LLM-authored response:** `mapThoughtPart` is reached only after `hasThought()` proves `thought` is a string; standard boolean thought parts do not take that path.
>
> **CodeRabbit:** “you’re right … the ordering concern doesn’t apply” and withdrew the comment.

Classification: invalid; dismissed; not useful as a change request.

## E4 — accepted UI correctness finding

- Finding: <https://github.com/vybestack/llxprt-jefe/pull/147#discussion_r3540513616>
- LLM action: <https://github.com/vybestack/llxprt-jefe/pull/147#discussion_r3540576425>
- CodeRabbit verification: <https://github.com/vybestack/llxprt-jefe/pull/147#discussion_r3540578791>

> **LLM-authored response:** “Addressed in commit a034a65.”
>
> **CodeRabbit:** confirmed that `props.selection` is filtered by the corresponding detail pane before reaching `ScrollableText`.

Classification: validated; fixed; useful.

## E5 — unsafe Windows suggestion rejected

- Finding: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575442403>
- LLM action: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575604871>
- CodeRabbit withdrawal: <https://github.com/vybestack/llxprt-jefe/pull/288#discussion_r3575607047>

> **LLM-authored response:** the proposed `metadata.is_dir` premise was unreliable for reparse-point classification, while recursive removal could traverse a target.
>
> **CodeRabbit:** agreed the suggested fix was speculative and could create “a real correctness/safety hazard.”

Classification: invalid; dismissed; not useful as a change request. The challenge prevented a potentially unsafe patch.

## E6 — high-impact Git parsing fix

- Finding: <https://github.com/vybestack/llxprt-jefe/pull/299#discussion_r3578470897>
- LLM action: <https://github.com/vybestack/llxprt-jefe/pull/299#discussion_r3580234782>
- CodeRabbit verification: <https://github.com/vybestack/llxprt-jefe/pull/299#discussion_r3580237294>

> **CodeRabbit:** rename/copy detection checked only the X status column, so worktree-only records in Y could desynchronize parsing.
>
> **LLM-authored response:** both status columns now detect R/C, with NUL and newline regression tests.
>
> **CodeRabbit:** confirmed both parsers check both columns.

Classification: validated; fixed; useful.

## E7 — review-thread mutation safety

- Finding: <https://github.com/vybestack/llxprt-luther/pull/67#discussion_r3469165099>
- LLM action: <https://github.com/vybestack/llxprt-luther/pull/67#discussion_r3472398598>
- CodeRabbit verification: <https://github.com/vybestack/llxprt-luther/pull/67#discussion_r3472399736>

> **CodeRabbit:** missing review-comment IDs should fail before mutation rather than fall back to a loose PR comment.
>
> **LLM-authored response:** the marker path now rejects missing IDs and no longer falls back.
>
> **CodeRabbit:** “that addresses my concern.”

Classification: validated; fixed; useful.

## E8 — critical finding fixed before adjudication reply

- Finding: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3504179209>
- LLM action: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3507784196>
- CodeRabbit verification: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3507786592>

> **CodeRabbit:** parsing a 4096-byte bounded `git status` excerpt could omit paths and produce partial staging.
>
> **LLM-authored response:** status parsing now uses full porcelain output.
>
> **CodeRabbit:** confirmed and withdrew the now-outdated original concern.

Classification: validated; fixed; useful.

## E9 — bounded interim mitigation and explicit deferral

- Finding: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3504179183>
- LLM action: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3507781513>
- CodeRabbit response: <https://github.com/vybestack/llxprt-luther/pull/92#discussion_r3507783418>

> **LLM-authored response:** the PR bounds excerpts and writes logs, while streaming tail buffers require a larger runner refactor outside issue 84.
>
> **CodeRabbit:** accepted deferral and called the current approach “a reasonable interim mitigation.”

Classification: validated; deferred; useful.

## E10 — explicit blocked iteration on a PR that later had completed findings

- Limit message: <https://github.com/vybestack/llxprt-jefe/pull/147#issuecomment-4909587121>
- Completed inline finding on the same PR: <https://github.com/vybestack/llxprt-jefe/pull/147#discussion_r3540513616>

> **CodeRabbit:** “## Review limit reached … You’ve reached a temporary PR review limit … Next review available in: 19 minutes.”

Classification: one blocked iteration is excluded; the later completed review and its findings remain in quality analysis.

## E11 — explicit blocked iteration without a completed inline review

- Limit message: <https://github.com/vybestack/llxprt-code/pull/2565#issuecomment-4965655795>
- PR: <https://github.com/vybestack/llxprt-code/pull/2565>

> **CodeRabbit:** “## Review limit reached … You’ve reached a temporary PR review limit … Next review available in: 29 minutes.”

Classification: blocked iteration only; excluded from quality denominators rather than treated as a zero-quality review.
