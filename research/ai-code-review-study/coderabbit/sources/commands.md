# Reproduction commands

Run from the repository root. Retrieval date for this report: **2026-07-14**. GitHub data acquisition uses `gh` only. Commands emit compact selected fields; do not retain full API responses.

## Authentication check

```sh
gh auth status
```

Do not copy tokens from the output into evidence files.

## Population frame

Use the bot-qualified search term; `commenter:coderabbitai` without `[bot]` returned zero in this environment.

```sh
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  encoded=$(printf 'repo:vybestack/%s is:pr commenter:coderabbitai[bot]' "$repo" | jq -sRr @uri)
  gh api --method GET "search/issues?q=$encoded&sort=created&order=asc&per_page=1" \
    --jq '{total_count,incomplete_results,earliest:(.items[0]|{html_url,created_at})}'
done
```

Exact endpoint URLs are listed in `evidence-index.md`.

## Explicit rate-limit events

Only an explicit CodeRabbit `## Review limit reached` PR comment counts. This deliberately excludes successful command replies that say “Full review finished” while mentioning a future limit.

```sh
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  gh api --paginate "repos/vybestack/$repo/issues/comments?per_page=100" \
    --jq '.[]
      | select(.user.login == "coderabbitai[bot]")
      | select(.html_url | contains("/pull/"))
      | select(.body | contains("## Review limit reached"))
      | {id,html_url,issue_url,created_at,updated_at}'
done
```

Count by repository:

```sh
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  printf '%s\t' "$repo"
  gh api --paginate "repos/vybestack/$repo/issues/comments?per_page=100" \
    --jq '[.[]
      | select(.user.login == "coderabbitai[bot]")
      | select(.html_url | contains("/pull/"))
      | select(.body | contains("## Review limit reached"))] | length' \
    | awk '{n += $1} END {print n + 0}'
done
```

Expected at the evidence cutoff: `llxprt-code 114`, `llxprt-jefe 88`, `llxprt-luther 53`.

## Completed root inline findings

```sh
for repo in llxprt-code llxprt-jefe llxprt-luther; do
  gh api --paginate "repos/vybestack/$repo/pulls/comments?per_page=100" \
    --jq '.[]
      | select(.user.login == "coderabbitai[bot]")
      | select(.in_reply_to_id == null)
      | {id,html_url,pull_request_url,path,line,original_line,created_at,body}'
done
```

The report uses root inline finding presence only to preserve completed review evidence on rate-limited PRs. A blocked iteration is excluded; a completed review on the same PR is not.

## Sample PR metadata and threads

```sh
gh pr view PR_NUMBER -R vybestack/REPO \
  --json number,title,url,state,createdAt,mergedAt,files,commits,author

gh api --paginate "repos/vybestack/REPO/pulls/PR_NUMBER/comments?per_page=100" \
  --jq '.[] | {id,in_reply_to_id,user:.user.login,html_url,path,line,created_at,body}'

gh api --paginate "repos/vybestack/REPO/issues/PR_NUMBER/comments?per_page=100" \
  --jq '.[] | {id,user:.user.login,html_url,created_at,updated_at,body}'
```

The sampled PR numbers are listed in `report.md`; finding and response URLs are listed in `sampled-findings.csv`.

## Compact extraction and sanitization rules

1. Keep exact GitHub URLs, timestamps, bot login, paths, severity, and substantive claim/action text.
2. Remove generated HTML/detail sections, learning payloads, hidden workflow markers, account/organization identifiers, and unrelated comments.
3. Never persist authentication output or full bulk payloads.
4. Do not include OCR findings.

## Validation

```sh
python3 - <<'PY'
import csv
from pathlib import Path
base = Path('research/reviews/coderabbit/sources')
expected = {
    'sampled-findings.csv': 36,
    'rate-limit-events.csv': 255,
    'excluded-rate-limited-reviews.csv': 255,
}
for name, count in expected.items():
    with (base / name).open(newline='') as f:
        rows = list(csv.DictReader(f))
    assert len(rows) == count, (name, len(rows), count)
    assert rows and all(rows), name
print('CSV validation passed')
PY

# Ensure every retained GitHub URL has the expected exact host/path form.
python3 -c "import csv,re,pathlib; files=pathlib.Path('research/reviews/coderabbit/sources').glob('*.csv'); urls=[]; [urls.extend(v for row in csv.DictReader(open(f)) for v in row.values() if v.startswith('https://')) for f in files]; assert all(re.fullmatch(r'https://github\\.com/vybestack/llxprt-(?:code|jefe|luther)/pull/\\d+(?:#(?:discussion_r|issuecomment-)\\d+)?',u) for u in urls); print(len(urls),'CSV URLs valid')"

# Optional online URL verification through gh only (one API call per unique URL).
python3 -c "import csv,pathlib,re; urls=sorted({v for f in pathlib.Path('research/reviews/coderabbit/sources').glob('*.csv') for row in csv.DictReader(open(f)) for v in row.values() if v.startswith('https://github.com/')}); print('\\n'.join(urls))" \
  | while read -r url; do
      repo=$(printf '%s' "$url" | cut -d/ -f5)
      pr=$(printf '%s' "$url" | cut -d/ -f7 | cut -d# -f1)
      gh api "repos/vybestack/$repo/pulls/$pr" --silent
    done

find research/reviews/coderabbit -type f -print | sort
find research/reviews/coderabbit -type d -empty -print
```

Application tests, lint, typecheck, formatting, build, and runtime smoke tests are intentionally not run for this research-only artifact.
