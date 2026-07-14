# Evidence index

**Retrieval date:** 2026-07-14
**Acquisition:** authenticated GitHub CLI (`gh`) only
**Scope:** PR-only CodeRabbit evidence from `vybestack/llxprt-code`, `vybestack/llxprt-jefe`, and `vybestack/llxprt-luther`

No credentials, organization IDs, unrelated issue data, OCR findings, or bulk raw API snapshots are retained in the final evidence set.

## Source records

### S1 — GitHub PR population and sampled PR metadata

- Organization/author: GitHub and repository maintainers
- Source type: primary API metadata
- Retrieval date: 2026-07-14
- Search API endpoint: <https://api.github.com/search/issues>
- Query URLs:
  - <https://api.github.com/search/issues?q=repo%3Avybestack%2Fllxprt-code%20is%3Apr%20commenter%3Acoderabbitai%5Bbot%5D&sort=created&order=asc&per_page=1>
  - <https://api.github.com/search/issues?q=repo%3Avybestack%2Fllxprt-jefe%20is%3Apr%20commenter%3Acoderabbitai%5Bbot%5D&sort=created&order=asc&per_page=1>
  - <https://api.github.com/search/issues?q=repo%3Avybestack%2Fllxprt-luther%20is%3Apr%20commenter%3Acoderabbitai%5Bbot%5D&sort=created&order=asc&per_page=1>
- Key results: 834, 122, and 67 CodeRabbit-touched PRs; each response had `incomplete_results=false`.
- Sample PR URLs: exact 16-PR inventory is in `report.md`.
- Limitations: GitHub search indexing may lag; “commenter” means at least one indexed CodeRabbit comment, not necessarily a completed inline review.

### S2 — Explicit rate-limit events

- File: [`rate-limit-events.csv`](rate-limit-events.csv)
- Author/organization: `coderabbitai[bot]` comments hosted by GitHub
- Source type: primary PR conversation comments
- Retrieval date: 2026-07-14
- API endpoints:
  - <https://api.github.com/repos/vybestack/llxprt-code/issues/comments?per_page=100>
  - <https://api.github.com/repos/vybestack/llxprt-jefe/issues/comments?per_page=100>
  - <https://api.github.com/repos/vybestack/llxprt-luther/issues/comments?per_page=100>
- Inclusion predicate: bot login exactly `coderabbitai[bot]`, URL contains `/pull/`, and body contains exact heading `## Review limit reached`.
- Key results: 255 retained explicit events/affected PRs: code 114, jefe 88, luther 53. Ninety-two affected PRs also had a completed root inline finding.
- Limitations: current comment bodies only; historic text edited away cannot be recovered, so this is a retained-message count.

### S3 — Blocked-iteration exclusion ledger

- File: [`excluded-rate-limited-reviews.csv`](excluded-rate-limited-reviews.csv)
- Source type: derived ledger from S2 plus root inline review-comment presence
- Retrieval date: 2026-07-14
- Review-comment endpoints:
  - <https://api.github.com/repos/vybestack/llxprt-code/pulls/comments?per_page=100>
  - <https://api.github.com/repos/vybestack/llxprt-jefe/pulls/comments?per_page=100>
  - <https://api.github.com/repos/vybestack/llxprt-luther/pulls/comments?per_page=100>
- Rule: exclude only `blocked_iteration_only`; preserve completed reviews on the same PR.
- Limitation: root inline findings are a conservative completion signal; a completed no-actionable review may have no inline finding.

### S4 — Classified finding sample

- File: [`sampled-findings.csv`](sampled-findings.csv)
- Source type: analyst classification of primary CodeRabbit threads
- Retrieval date: 2026-07-14
- Coverage: 36 root findings, 12 per repository, from 9 PRs with findings inside the 16-PR inventory.
- Fields preserve exact finding URL, path, severity, category, summary, disposition, LLM action, usefulness, and an action/adjudication URL.
- Classification rule: `validated` requires explicit acceptance/fix/deferral evidence; `invalid` requires technical rejection with CodeRabbit withdrawal/acceptance; missing linked action is `no-adjudication`.
- Limitation: purposive sample; no probability-sample inference.

### S5 — Compact thread extracts

- File: [`sampled-thread-extracts.md`](sampled-thread-extracts.md)
- Source type: sanitized excerpts from primary PR threads
- Retrieval date: 2026-07-14
- Coverage: accepted fixes, deferrals, false positives, platform-safety challenge, and two rate-limit cases.
- Sanitization: HTML/detail boilerplate, generated learning payloads, hidden workflow markers, and organization identifiers omitted; substantive wording and exact URLs retained.

### S6 — File inventory

- File: [`file-inventory.txt`](file-inventory.txt)
- Source type: local validation artifact
- Retrieval date: 2026-07-14
- Purpose: proves the final package is compact and contains no raw snapshot directory.

### S7 — Reproduction and validation commands

- File: [`commands.md`](commands.md)
- Source type: reproducibility record
- Retrieval date: 2026-07-14
- Purpose: records the `gh` predicates and local validation commands without credentials.

## Evidence boundaries

- Included: CodeRabbit PR conversation comments, CodeRabbit root inline findings, direct replies/adjudications to those findings, PR metadata, and GitHub Search counts.
- Excluded: repository issues (except API endpoint records whose filtered rows are PR URLs), OCR output, unrelated reviewer comments, credentials, hidden account identifiers, and bulk raw responses.
- LLM attribution: all human-looking remediation comments are treated as LLM-authored, per the task rule.
