# Compact GitHub evidence extracts

**Retrieved:** 2026-07-14 with authenticated `gh` only.

## First retained activity

- `llxprt-code`: PR [#559](https://github.com/vybestack/llxprt-code/pull/559), opened 2025-11-12 06:49 UTC; first retained CodeRabbit walkthrough [comment](https://github.com/vybestack/llxprt-code/pull/559#issuecomment-3524081185) at 21:55 UTC.
- `llxprt-jefe`: PR [#10](https://github.com/vybestack/llxprt-jefe/pull/10), opened 2026-03-27 16:07 UTC.
- `llxprt-luther`: PR [#27](https://github.com/vybestack/llxprt-luther/pull/27), opened 2026-06-05 23:19 UTC.

## First retained blocks and wording

- First organization event: code [#1979](https://github.com/vybestack/llxprt-code/pull/1979#issuecomment-4663789403), 2026-06-09 20:36 UTC.
- Early explicit form, e.g. Jefe [#61](https://github.com/vybestack/llxprt-jefe/pull/61#issuecomment-4694060956): “we couldn't start this review because you've reached your PR review rate limit.”
- Later/current form, e.g. code [#2568](https://github.com/vybestack/llxprt-code/pull/2568#issuecomment-4970269958): “temporary PR review limit under our Fair Usage Limits Policy” and “adaptive limits are currently applied.”
- Latest retained event in the original activity snapshot: Jefe [#303](https://github.com/vybestack/llxprt-jefe/pull/303#issuecomment-4972172300), 2026-07-14 17:37 UTC. Its retained body says `Plan: Pro Plus`, `Next review available in: 8 minutes`, “per-developer PR review limits for each organization,” and offers `$0.25/file` usage-based review.
- Exact phrase `Free tier rate limit reached`: **0 retained comments**. Exact heading `Review limit reached`: **256 union-snapshot comments**.

## Snapshot discrepancy proving mutability

Earlier same-day artifact: 255 URLs (114 code, 88 Jefe, 53 Luther). Later retrieval: 255 current URLs (113 code, 89 Jefe, 53 Luther).

- Edited away after the prior capture: code [#2567 comment](https://github.com/vybestack/llxprt-code/pull/2567#issuecomment-4970341889).
- Added later on cutoff day: Jefe [#303 comment](https://github.com/vybestack/llxprt-jefe/pull/303#issuecomment-4972172300).
- Union: 256 distinct comments/PRs. There are zero retained duplicate PRs, but this does not prove one blocked attempt per PR.

## Configuration discrepancy investigation

### Coverage and classifications

The follow-up searched all three GitHub repositories rather than only the root default-branch path:

- gh-cloned mirrors contained every advertised branch and PR head: code 826 branch refs/975 PR-head refs, Jefe 112/126, and Luther 28/67.
- `git rev-list --objects --all`, all-ref path logs, rename/delete scans, and YAML content-diff searches covered standard and alternate names (`.coderabbit.yaml`, `.coderabbit.yml`, `coderabbit.yaml`, `coderabbit.yml`, `.github/coderabbit.*`, and nested matches).
- A separately paginated GraphQL scan covered all 1,167 current PRs (974 code, 126 Jefe, 67 Luther), including open, merged, and closed-unmerged PRs, and all 32,253 changed-file records (28,608/2,726/919). It found config diffs only in merged code PRs [#2363](https://github.com/vybestack/llxprt-code/pull/2363), [#2396](https://github.com/vybestack/llxprt-code/pull/2396), and [#2400](https://github.com/vybestack/llxprt-code/pull/2400).
- No config path had an add-then-delete, delete, or rename event. No unmerged PR diff introduced a config. A force-pushed-away commit, unpushed local file, or organization/UI setting is not recoverable from this repository evidence.

### Resolution of the user's recollection

**Proven:** a CodeRabbit YAML landed on the default branch in code at root and in Luther at the exact nested path `workflow/.coderabbit.yaml`. **Not proven:** no CodeRabbit YAML/config event, attempted PR diff, deleted/renamed path, alternate filename, or embedded YAML setting was found anywhere in Jefe's advertised refs or complete PR population. The recollection is therefore repository-verifiable for two of three repositories, not all three. A Jefe UI change, local-only edit, or force-pushed-away commit remains possible but unverified.

The Luther file's existence and settings are direct git evidence. Its nested placement is not evidence that CodeRabbit actually ingested it; no account/UI audit log or immutable vendor run log was available.

## Code root config history

### PR-branch precursors

- PR [#2363](https://github.com/vybestack/llxprt-code/pull/2363), branch `add-coderabbit-config`, **merged**: [36588012](https://github.com/vybestack/llxprt-code/commit/365880126cbbe64eb9af682815bea049d305fa85) added the 36-line config at 2026-07-03 21:22:34 UTC; [05b69fea](https://github.com/vybestack/llxprt-code/commit/05b69fea25ca939c4004fcb43d2f1157b9cd69f1) changed only quote/comment formatting at 2026-07-04 19:46:34 UTC.
- PR [#2396](https://github.com/vybestack/llxprt-code/pull/2396), branch `coderabbit-incremental-pause`, **merged**: [691d08e9](https://github.com/vybestack/llxprt-code/commit/691d08e9d1665ac8b9a557749aa26b5967d9deee) restored incrementals and added the cap at 2026-07-06 18:48:39 UTC.
- PR [#2400](https://github.com/vybestack/llxprt-code/pull/2400), branch `fix/coderabbit-disable-issue-autolabel`, **merged**: [7a53edcc](https://github.com/vybestack/llxprt-code/commit/7a53edcc332ad6ebe540979e565a69c2de37f37a) disabled issue labels at 2026-07-06 21:47:03 UTC.

These branch commits were not abandoned experiments: each was squash-merged, producing the three default-branch commits below.

### 2026-07-04 — root config on default branch

[Commit f78597dd](https://github.com/vybestack/llxprt-code/commit/f78597dd098b8519af34659db080262dacb63e5e), +36 lines:

```yaml
reviews:
  profile: chill
  sequence_diagrams: false
  path_filters:
    - '!project-plans/**'
    - '!dev-docs/**'
    - '!**/*.lock'
    - '!package-lock.json'
    - '!scripts/tmux-script.*.json'
    - '!junit-integration.xml'
    - '!**/__snapshots__/**'
  auto_review:
    enabled: true
    drafts: false
    auto_incremental_review: false
```

Commit message: “reduce review rate-limit hits”; switch incremental reviews to on-demand so multi-commit PRs consume one automatic review.

### 2026-07-06 — capped incremental reviews

[Commit 6acf50fa](https://github.com/vybestack/llxprt-code/commit/6acf50fa7dcb34ddfde8ddcba5437717d7e78e95):

```diff
- auto_incremental_review: false
+ auto_incremental_review: true
+ auto_pause_after_reviewed_commits: 3
```

The commit states disabling incrementals stopped some limit hits but left follow-up pushes unreviewed, citing PRs #2394 and #2384.

### 2026-07-06 — issue labels only

[Commit 8833ddcb](https://github.com/vybestack/llxprt-code/commit/8833ddcb9c4c359152c3cc1d94c7d72dd6567bc9) added `issue_enrichment.labeling.auto_apply_labels: false`; no expected PR-review quota effect.

## Luther nested default-branch config

[Commit 259fa5d4](https://github.com/vybestack/llxprt-luther/commit/259fa5d4919abe33265db93a29f99e18a88088f8) directly added `workflow/.coderabbit.yaml` to `main` at 2026-07-13 15:31:16 UTC. It was not associated with a PR. There was no root `.coderabbit.yaml` history.

```yaml
reviews:
  profile: assertive
  auto_review:
    enabled: true
    drafts: false
    base_branches:
      - main
    auto_incremental_review: true
    auto_pause_after_reviewed_commits: 3
  tools:
    clippy:
      enabled: true
issue_enrichment:
  planning:
    enabled: true
  labeling:
    auto_apply_labels: false
```

The omitted middle block supplies Rust-specific correctness, durable-state, security, contract, maintainability, test, and lint instructions. The cap and labeling controls are materially equivalent to code's July 6 settings, but the profile, language-specific instructions, tools, and path differ. Luther's last PR in the report window was merged before this commit, so the report has no post-config Luther review outcome from which to estimate an effect.

## Workflow automation distinct from repository config

Code's default-branch `.github/workflows/luther.yml` embeds a manual-review trigger; Jefe and Luther had no comparable GitHub workflow that posted a manual CodeRabbit request:

- [cf3ecbe1](https://github.com/vybestack/llxprt-code/commit/cf3ecbe180077eb308621888a34ec1044edb4fb0), 2025-11-21 20:07:03 UTC: add a post-push `@coderabbit review` comment.
- [fe548e6c](https://github.com/vybestack/llxprt-code/commit/fe548e6c52d5643facb264571cd2eb0193f975ee), 2025-11-21 21:08:58 UTC: carry and target the exact PR number.
- [abae6d67](https://github.com/vybestack/llxprt-code/commit/abae6d678f378dbccce28d75fac03d146d780803), 2025-11-22 20:43:09 UTC: use the personal token identity by unsetting `GITHUB_TOKEN`.
- [4924877a](https://github.com/vybestack/llxprt-code/commit/4924877a72a39810d100a602a19159c936c67fcf), 2025-11-22 22:22:35 UTC: replace the unset with an empty job-level override.

All four were direct default-branch commits with no associated PR. They automate a manual request and authentication; they are not CodeRabbit review-policy settings.

## Inventory and plan-transition spot-checks

- Authenticated organization GraphQL still returned exactly seven repositories with the same visibility classification. No inventory classification error was found.
- The original frozen activity population was 974/125/67 PRs (1,166 total). A later live check found Jefe [#304](https://github.com/vybestack/llxprt-jefe/pull/304), created at 2026-07-14 18:38:40 UTC after the original extraction, raising the live population to 974/126/67 (1,167). It had no CodeRabbit config path. The activity ledgers were not partially refreshed, so report outcome denominators remain snapshot-consistent.
- Recalculation from `rate-limit-events.csv` reproduced 22 `Pro`, 233 `Pro Plus`, one unstated, last Pro at 2026-06-12 21:07:23 UTC, and first Pro Plus at 2026-06-15 14:07:50 UTC. Direct retrieval of selected comments still showed those plan labels, and organization-wide searches still found no explicit upgrade/subscription/seat announcement. No obvious plan-transition classification error was found; body mutability still limits the inference.

## Explicit plan/upgrade search

Organization-wide `gh search issues` for `CodeRabbit upgrade`, `CodeRabbit subscription`, and `CodeRabbit seats` produced no relevant explicit announcement. `gh search commits coderabbit` found config commits and many direct remediation commits, but no billing/upgrade commit. The bot's current mutable limit bodies state Pro/Pro Plus; that is operational plan evidence at latest edit, not purchase-date evidence.

## Direct remediation commit examples

- code [97a7132](https://github.com/vybestack/llxprt-code/commit/97a71324535061372d844bd817d65117b2ab65da), “Address remaining CodeRabbit feedback.”
- code [d0a210f](https://github.com/vybestack/llxprt-code/commit/d0a210fa0663923e4563771b55fca722ddf9f8cc), “Address CodeRabbit regex review feedback.”
- Jefe [5fe2669](https://github.com/vybestack/llxprt-jefe/commit/5fe26696e15e193898b07e0b6624ba13b165a527), “Address CodeRabbit follow-ups...”
- Luther [f3d682d](https://github.com/vybestack/llxprt-luther/commit/f3d682d6c4f7fa5f45c558d06037308c9779deed), “Downrank speculative CodeRabbit nits...”

The matched OCR–CodeRabbit quality study remains in [the comparison report](../../comparison/report.md); this audit does not duplicate its six exact-head finding comparison.
