# Evidence index

**Cutoff/access date:** 2026-07-14. **GitHub acquisition:** authenticated `gh` only.

| ID | Evidence | Source/type | Principal use | Limitation |
|---|---|---|---|---|
| G1 | [repository-inventory.csv](repository-inventory.csv) | GitHub organization/repository APIs | three llxprt repositories; retained activity inventory | private/deleted repos not visible would be absent; activity snapshot predates late Jefe #304 |
| G2 | [rate-limit-events.csv](rate-limit-events.csv) | exact GitHub comment URLs | 256 union-snapshot explicit headings | mutable lower bound, not attempts |
| G3 | [review-events.csv](review-events.csv) | inline roots and explicit completion replies | 459 conservative completion signals | partial code coverage before 2026-05-08; not billing events |
| G4 | [pr-activity-by-week.csv](pr-activity-by-week.csv) | PR metadata and commit totals | creations, touched PRs, commits/update proxy | commits are not exact pushes |
| G5 | [review-response-updates.csv](review-response-updates.csv) | threads and commits | high/medium/temporal attribution | timing classes are not causality |
| G6 | [period-summary.csv](period-summary.csv) | derived G2–G5 | segmented demand/outcomes | periods are descriptive |
| G7 | [config-history.csv](config-history.csv) | GitHub commit history/diffs, advertised refs, and complete PR file lists | every found config/workflow add/modify event plus Jefe negative finding | organization/UI, unpushed, force-pushed-away, and unadvertised/deleted history unavailable |
| G8 | [github-extracts.md](github-extracts.md) | compact primary extracts | first use, message semantics, config snapshots, discrepancy resolution, spot-checks | edited bodies reflect latest state; nested Luther ingestion not proven |
| P1–P9 | [policy-extracts.md](policy-extracts.md) | official current/archived docs and blog | policy timeline, seats, plans, fair use | historical gaps remain |
| M1 | [methodology.md](methodology.md) | methods/definitions | reproducibility and denominator rules | analyst choices |
| C1 | [commands.md](commands.md) | commands | reproduction/validation | bulk commands can hit GitHub secondary limits |

## Exact GitHub API and repository source families

- Organization repositories: `gh api graphql` organization repository connection.
- PR population: repository `pullRequests` GraphQL connection and `gh api search/issues` cross-check.
- PR comments: `repos/vybestack/{repo}/issues/comments`.
- Inline review threads: `repos/vybestack/{repo}/pulls/comments`.
- Default-path config history: `repos/vybestack/{repo}/commits?path={candidate}` and exact commit endpoints.
- All-ref history: gh-cloned mirrors, `git rev-list --objects --all`, `git log --all --name-status`, delete/rename scans, branch tree scans, and YAML `-G` content searches.
- Complete PR diffs: paginated GraphQL `pullRequests` and nested `files` connections for 974 code, 126 Jefe, and 67 Luther PRs; all 32,253 file records were followed.
- Commit/PR association: `repos/vybestack/{repo}/commits/{sha}/pulls` plus PR head/base/state from GraphQL.
- Plan/search terms: `gh search issues` and `gh search commits` for CodeRabbit + plan/upgrade/subscription/seats/free tier/quota/rate limit/review limit.

## Policy URLs

- Current plans: <https://docs.coderabbit.ai/management/plans>
- Current auto-review: <https://docs.coderabbit.ai/configuration/auto-review>
- Seats: <https://docs.coderabbit.ai/management/seat-assignment>
- Usage add-on: <https://docs.coderabbit.ai/management/usage-based-addon>
- Pricing: <https://www.coderabbit.ai/pricing>
- Changelog: <https://docs.coderabbit.ai/changelog>
- 2023 engineering policy: <https://www.coderabbit.ai/blog/how-we-built-cost-effective-generative-ai-application>
- Archived plans: [2026-05-02](https://web.archive.org/web/20260502104924id_/https://docs.coderabbit.ai/management/plans), [2026-06-13](https://web.archive.org/web/20260613223630id_/https://docs.coderabbit.ai/management/plans), [2026-06-24](https://web.archive.org/web/20260624211719id_/https://docs.coderabbit.ai/management/plans), [2026-06-28](https://web.archive.org/web/20260628195617id_/https://docs.coderabbit.ai/management/plans)
- Archived pricing: [2025-11-05](https://web.archive.org/web/20251105200221id_/https://www.coderabbit.ai/pricing), [2026-04-28](https://web.archive.org/web/20260428154602id_/https://www.coderabbit.ai/pricing), [2026-07-11](https://web.archive.org/web/20260711131840id_/https://www.coderabbit.ai/pricing)

## Related prior research

- Earlier CodeRabbit quality/rate audit: [`../report.md`](../report.md)
- Matched exact-head OCR–CodeRabbit report: [`../../comparison/report.md`](../../comparison/report.md)

This report independently re-ran GitHub collection and preserves discrepancies rather than overwriting the prior evidence.
