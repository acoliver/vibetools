# Reproduction commands

Run from repository root. GitHub commands use `gh` only; access/cutoff date is 2026-07-14.

## Inventory and population

```sh
gh api graphql -f query='query { organization(login:"vybestack") { repositories(first:100) { nodes { name url isPrivate createdAt updatedAt } } } }'

for repo in llxprt-code llxprt-jefe llxprt-luther; do
  gh api --method GET search/issues \
    -f q="repo:vybestack/$repo is:pr commenter:coderabbitai[bot] created:<=2026-07-14" \
    -f per_page=1 --jq '[.total_count,.incomplete_results]'
done
```

## Comments and exact headings

```sh
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  gh api --paginate "repos/vybestack/$repo/issues/comments?per_page=100" \
    --jq '.[] | select(.user.login=="coderabbitai[bot]")
      | select(.html_url|contains("/pull/"))
      | select((.body|contains("Free tier rate limit reached")) or
               (.body|contains("Review limit reached")))
      | {id,html_url,created_at,updated_at,body}'
done
```

## PR metadata and review threads

```sh
# All PR metadata and commit totals are paged through repository.pullRequests.
gh api graphql -f query='query { repository(owner:"vybestack",name:"llxprt-code") { pullRequests(last:100) { pageInfo { hasPreviousPage startCursor } nodes { number url createdAt author { login } commits { totalCount } } } } }'

# Inline thread family used for completion/response coding.
gh api --paginate 'repos/vybestack/llxprt-code/pulls/comments?per_page=100&sort=created&direction=asc&since=2026-06-01T00%3A00%3A00Z'
gh api --paginate 'repos/vybestack/llxprt-jefe/pulls/comments?per_page=100&sort=created&direction=asc'
gh api --paginate 'repos/vybestack/llxprt-luther/pulls/comments?per_page=100&sort=created&direction=asc'
```

The code endpoint's `since` filter operates on updated time; retained CodeRabbit rows covered 2026-05-08 through the cutoff. Jefe and Luther were collected from inception.

## Exhaustive config and workflow history

```sh
# Default-branch histories for conventional and alternate paths.
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  for path in .coderabbit.yaml .coderabbit.yml coderabbit.yaml coderabbit.yml \
              .github/coderabbit.yaml .github/coderabbit.yml; do
    gh api --paginate --method GET "repos/vybestack/$repo/commits" \
      -f path="$path" -f per_page=100
  done
done

# Acquire all GitHub refs through gh; inspect only the local mirrors afterward.
gh repo clone vybestack/llxprt-code $TMPDIR/coderabbit-audit-code.git -- --mirror
gh repo clone vybestack/llxprt-jefe $TMPDIR/coderabbit-audit-jefe.git -- --mirror
gh repo clone vybestack/llxprt-luther $TMPDIR/coderabbit-audit-luther.git -- --mirror

for mirror in $TMPDIR/coderabbit-audit-code.git \
              $TMPDIR/coderabbit-audit-jefe.git \
              $TMPDIR/coderabbit-audit-luther.git; do
  # Every candidate historical path reachable from advertised refs.
  git -C "$mirror" rev-list --objects --all \
    | cut -d' ' -f2- \
    | grep -Ei '(^|/)(\.?(code)?rabbit[^/]*\.(ya?ml|json|toml)|\.coderabbit[^/]*)$|coderabbit'

  # Adds/modifies plus explicit deleted/renamed search.
  git -C "$mirror" log --all --name-status -- \
    .coderabbit.yaml .coderabbit.yml coderabbit.yaml coderabbit.yml \
    '*/.coderabbit.yaml' '*/.coderabbit.yml' \
    '.github/*coderabbit*.yaml' '.github/*coderabbit*.yml'
  git -C "$mirror" log --all --diff-filter=DR --summary --find-renames

  # Workflow/config YAML whose content changed a CodeRabbit setting or trigger.
  git -C "$mirror" log --all -i \
    -G 'coderabbit|auto_incremental_review|auto_pause_after_reviewed_commits' \
    --name-status -- '*.yaml' '*.yml'
done

# Associate each candidate commit to a PR. An empty array means direct commit or
# no retained association; verify default-branch ancestry in the mirror.
gh api -H 'Accept: application/vnd.github+json' \
  repos/vybestack/llxprt-luther/commits/259fa5d4919abe33265db93a29f99e18a88088f8/pulls
```

## Complete open/merged/closed PR file scan

Use the repository `pullRequests(first:100,after:$cursor)` GraphQL connection with these fields, then page each nested `files(first:100,after:$fileCursor)` connection until `hasNextPage` is false:

```graphql
number
state
mergedAt
closedAt
headRefName
headRefOid
baseRefName
changedFiles
files(first: 100, after: $fileCursor) {
  pageInfo { hasNextPage endCursor }
  nodes { path additions deletions }
}
```

The completed crawl covered 974/126/67 PRs and 28,608/2,726/919 changed-file records for code/Jefe/Luther. Scan paths case-insensitively for CodeRabbit and every config-name variant. State totals at collection were code 6 open/921 merged/47 closed-unmerged, Jefe 6/119/1, and Luther 0/66/1.

## Text and plan search

```sh
gh search issues 'CodeRabbit upgrade' --owner vybestack --include-prs --limit 100
gh search issues 'CodeRabbit subscription' --owner vybestack --include-prs --limit 100
gh search issues 'CodeRabbit seats' --owner vybestack --include-prs --limit 100
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  gh search commits coderabbit --repo "vybestack/$repo" --limit 100 \
    --json repository,sha,commit,url
done
```

## External policy discovery and archives

Directly retrieve the URLs listed in `policy-extracts.md`. Wayback discovery URLs:

```text
https://web.archive.org/cdx/search/cdx?url=docs.coderabbit.ai/management/plans&output=json&filter=statuscode:200&fl=timestamp,original,statuscode,digest&collapse=digest
https://web.archive.org/cdx/search/cdx?url=coderabbit.ai/pricing&output=json&filter=statuscode:200&fl=timestamp,original,statuscode,digest&collapse=digest
```

## Derivation and validation

```sh
python3 research/reviews/coderabbit/throttling/validation.py
npm run format
npm run lint
npm run typecheck
npm run test
npm run build
bun scripts/start.ts --profile-load ollamakimi "write me a haiku and nothing else"
```

GraphQL pagination cursors must be followed until `hasNextPage` is false. `methodology.md` specifies the deterministic grouping and attribution rules used to derive the canonical CSVs. Temporary compact extracts and gh-cloned mirrors are outside the repository and are not evidence artifacts.
