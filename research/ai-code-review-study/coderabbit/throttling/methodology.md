# Methodology

## Question and cutoff

This audit asks how CodeRabbit review demand, retained successful-review signals, and explicit throttling evolved across the VybeStack organization from the first retained activity through **2026-07-14 23:59:59 UTC**, with detailed analysis of `llxprt-code`, `llxprt-jefe`, and `llxprt-luther`.

## Acquisition

- All GitHub evidence was retrieved with authenticated `gh` only.
- External CodeRabbit policy was discovered through search, verified by direct retrieval, and historically checked through Wayback captures.
- The repository inventory is restricted to `llxprt-code`, `llxprt-jefe`, and `llxprt-luther`.
- No billing dashboard, private CodeRabbit account API, or deleted GitHub history was available.
- The original activity ledgers are a frozen same-day snapshot. A discrepancy follow-up later on July 14 found Jefe #304, created at 18:38:40 UTC after that extraction. It raised the live PR population by one but did not change the frozen CodeRabbit outcome population; the report does not mix a partial activity refresh into the original denominators.

## Config-discrepancy procedure

The initial audit queried the conventional root path on default branches. The follow-up broadened this to repository-wide and PR-wide history:

1. `gh repo clone ... -- --mirror` captured advertised branch, tag, and PR refs for all three repositories. Local git was used only against those gh-acquired mirrors.
2. `git rev-list --objects --all` enumerated every historical path reachable from those refs. Candidate matching included `.coderabbit.yaml`, `.coderabbit.yml`, unprefixed and `.github` alternatives, nested matches, and case-insensitive CodeRabbit names.
3. `git log --all --name-status`, `--diff-filter=DR --find-renames`, branch tree enumeration, and `-G` YAML searches identified add/modify/delete/rename events and workflows embedding CodeRabbit settings or request triggers.
4. A separate GraphQL crawl paged all open, merged, and closed-unmerged PRs and every nested `files` connection: 974/126/67 PRs and 28,608/2,726/919 file records for code/Jefe/Luther. Exact commit-to-PR association came from the commit-pulls REST endpoint.
5. Default-branch candidate path queries and exact commit endpoints cross-checked the mirror results. Commit reachability distinguished default-branch events, PR-head-only precursor events, and direct-to-default commits.

Negative findings mean “not found in reachable advertised refs or complete current PR diffs,” not “could never have existed.” Organization/UI settings, unpushed local files, inaccessible deleted repositories, and commits removed by force-push before acquisition remain outside git-verifiable evidence. Luther's nested file is proven to exist on `main`; repository evidence alone does not prove vendor ingestion of that nested path.

## Units

1. **Touched PR:** a PR with a retained CodeRabbit PR-conversation comment or inline review comment. GitHub Search (`commenter:coderabbitai[bot]`) independently returned the same 834/123/67 focus-repository counts.
2. **Explicit blocked comment:** current or same-day previously captured PR comment containing exact `Free tier rate limit reached` or `Review limit reached`. One mutable comment is not assumed to equal every attempted iteration.
3. **Completed-review signal:** either (a) one or more root CodeRabbit inline findings grouped by PR and original reviewed SHA, or (b) an explicit `Review finished`/`Full review finished` reply when no nearby finding group exists. This is conservative and not a vendor billing event count.
4. **Commit/update proxy:** GitHub PR commit count; `max(commits-1,0)` estimates follow-up updates. It is not an exact push-event count because one push can contain multiple commits and force-pushes are not fully represented.
5. **Observed-outcome block rate:** blocked comments / (blocked comments + conservative completed-review signals). It is not the probability that a request was blocked; mutable states, no-finding reviews, retries, and silent skips remain censored.

## Response-attribution hierarchy

- **High confidence:** LLM-authored thread reply says fixed/addressed/etc. and cites a commit; or the commit message explicitly references CodeRabbit/review feedback.
- **Medium confidence:** commit occurs after a retained CodeRabbit finding within 24 hours, without explicit causal wording.
- **Temporal only:** commit follows a finding after more than 24 hours without explicit causal language.
- Rows are update actions, not unique findings. A commit may address several findings. All human-looking replies are treated as LLM-authored actions per instruction.
- We do not label all post-review pushes as caused by CodeRabbit.

## Periodization

- **P0:** first retained activity to first retained limit (2025-11-12–2026-06-09 20:36 UTC).
- **P1:** initial blocked-message era to 2026-06-25 (`couldn't start` wording was observed in retained snapshots, while current comments are mutable).
- **P2:** disclosed/adaptive-policy era before repository config (2026-06-25–2026-07-04 20:40).
- **P3:** `auto_incremental_review: false` (2026-07-04 20:40–2026-07-06 19:33).
- **P4:** incremental review restored with cap 3 (2026-07-06 19:33–cutoff).

These boundaries are code-root-config boundaries. Luther's nested config was added July 13 after Luther's final PR in the retained window, so it does not supply a post-config outcome segment. These boundaries support segmented description, not causal identification.

## Source weighting

| Evidence | Authority | Directness | Rigor | Recency | Independence | Relevance | Use |
|---|---:|---:|---:|---:|---:|---:|---|
| GitHub comments/commits/config via `gh` | 5 | 5 | 4 | 3 | 3 | 5 | Primary observed behavior |
| Archived official CodeRabbit docs | 5 | 5 | 4 | 3 | 2 | 5 | Historical stated policy |
| Current official docs/pricing | 5 | 5 | 4 | 3 | 2 | 5 | Cutoff policy, not back-projected |
| Official engineering blog | 5 | 4 | 4 | 1 | 2 | 4 | Historical mechanism/context |
| Analyst timing/classification | 2 | 3 | 3 | 3 | 1 | 5 | Transparent inference only |

## Mutability and survivorship

GitHub's issue-comment API returns current bodies. A walkthrough/rate-limit comment can be edited repeatedly. On 2026-07-14, the earlier report had 255 exact headings; later retrieval also had 255, but one code comment had lost its heading and a new Jefe comment had appeared. The union is 256 distinct URLs. Therefore:

- retained exact comments are a lower bound on blocked iterations;
- message wording and plan fields in current bodies may reflect the latest edit, not creation-time state;
- no repeated blocked attempts are inferred from one comment's multiple updates;
- exact-message, unique-comment, unique-PR, and blocked-iteration counts must remain separate.

## Confounders

Repository launch dates, one dominant author, parallel agents/worktrees, bursty issue execution, PR size, commit batching, manual retries, bot-side wording changes, policy changes, organization UI settings, mutable comments, and missing billing data all prevent causal certainty.
