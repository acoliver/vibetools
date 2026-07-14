# Code PR 2462 near-matched overlap snapshot

Captured 2026-07-14 with `gh api repos/vybestack/llxprt-code/pulls/2462/comments`. These are the OCR records posted on 2026-07-12 to head `242091fa678584570d5444d25922f6ae5755106d`, later than retained local L1. Duplicate body posts and the “no issues” record are shown so the derivation is auditable.

| URL | Posted UTC | Classification for comparison | Abridged body |
|---|---|---|---|
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566547813 | 15:07:52 | excluded: no issue | Test logic and assertions look correct; no issues found. |
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566547857 | 15:07:54 | actionable unique | `/mcp` preference misses a trailing slash. |
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566547890 | 15:07:55 | excluded: duplicate | Same trailing-slash body. |
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566547918 | 15:07:57 | excluded: duplicate | Same trailing-slash body. |
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566547979 | 15:07:59 | actionable unique | Generic replacement loses original error information. |
| https://github.com/vybestack/llxprt-code/pull/2462#discussion_r3566562816 | 15:17:11 | actionable unique | `undefined` is more semantically accurate than an empty header string. |

Result used in the report: **3 unique actionable PR-posted findings**. Manual semantic comparison against L1's four local findings found **0 shared findings**, union **7**, Jaccard **0/7**. The local source does not identify SHA/range/config, so this is a content overlap only, not an equal-input experiment.
