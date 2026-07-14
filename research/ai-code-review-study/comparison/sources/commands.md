# Reproduction and validation commands

Run from the repository root. Retrieval date: 2026-07-14. GitHub access used `gh` only; no token values or headers are retained.

## PR metadata

```sh
for spec in \
  'vybestack/llxprt-code 2462' \
  'vybestack/llxprt-code 2547' \
  'vybestack/llxprt-jefe 181' \
  'vybestack/llxprt-jefe 288' \
  'vybestack/llxprt-luther 110' \
  'vybestack/llxprt-luther 133'
do
  set -- $spec
  gh pr view "$2" --repo "$1" \
    --json number,title,state,headRefOid,baseRefOid,additions,deletions,changedFiles,commits,createdAt,mergedAt,url
 done
```

## Identify reviewer roots and original reviewed SHA

```sh
repo=vybestack/llxprt-code
pr=2462
gh api --paginate "repos/$repo/pulls/$pr/comments?per_page=100" |
  jq -s 'add |
    map(select(.in_reply_to_id == null and
      (.user.login == "coderabbitai[bot]" or
       .user.login == "github-actions[bot]"))) |
    group_by(.user.login) |
    map({author: .[0].user.login,
         by_original_commit:
           (group_by(.original_commit_id) |
            map({sha: .[0].original_commit_id,
                 n: length,
                 first: (map(.created_at) | min),
                 last: (map(.created_at) | max)}))})'
```

Repeat for each cohort PR. `original_commit_id`, not mutable `commit_id`, controls match quality.

## Extract one selected exact-head iteration

```sh
repo=vybestack/llxprt-jefe
pr=288
sha=4e4a43c08bef2d9f55e50b48d18145cf001b75d9
gh api --paginate "repos/$repo/pulls/$pr/comments?per_page=100" |
  jq -rs --arg sha "$sha" 'add |
    map(select(.in_reply_to_id == null and
      .original_commit_id == $sha and
      (.user.login == "coderabbitai[bot]" or
       .user.login == "github-actions[bot]"))) |
    sort_by(.user.login,.id)[] |
    [.id,.user.login,.created_at,.path,
     (.line // .original_line // 0),.html_url,.body] | @tsv'
```

## Extract replies to selected roots

```sh
gh api --paginate "repos/$repo/pulls/$pr/comments?per_page=100" |
  jq -rs --arg sha "$sha" 'add as $all |
    ($all | map(select(.in_reply_to_id == null and
      .original_commit_id == $sha and
      (.user.login == "coderabbitai[bot]" or
       .user.login == "github-actions[bot]"))))[] as $root |
    {root: $root.html_url,
     replies: ($all | map(select(.in_reply_to_id == $root.id)) |
       map({author: .user.login, url: .html_url, body: .body}))}'
```

## Inspect explicit CodeRabbit states

```sh
gh api --paginate "repos/$repo/issues/$pr/comments?per_page=100" |
  jq -s 'add[] |
    select(.user.login == "coderabbitai[bot]") |
    {id,html_url,created_at,updated_at,
     review_limit: (.body | contains("## Review limit reached")),
     review_skipped: (.body | contains("## Review skipped")),
     reviews_paused: (.body | contains("## Reviews paused"))}'
```

Explicit blocked states enter `excluded-review-iterations.csv`; completed root findings on the same PR remain eligible.

## CSV shape and aggregate validation

```sh
python3 - <<'PY'
import collections
import csv
from pathlib import Path

base = Path('research/reviews/comparison/sources')
expected_columns = {
    'matched-prs.csv': 22,
    'matched-findings.csv': 19,
    'semantic-overlap.csv': 12,
    'excluded-review-iterations.csv': 12,
}
for name, width in expected_columns.items():
    with (base / name).open(newline='') as f:
        rows = list(csv.reader(f))
    assert rows and len(rows[0]) == width, (name, len(rows[0]))
    assert all(len(row) == width for row in rows), name

with (base / 'matched-findings.csv').open(newline='') as f:
    findings = list(csv.DictReader(f))
assert len(findings) == 56
assert collections.Counter(r['reviewer'] for r in findings) == {
    'OCR': 33, 'CodeRabbit': 23
}
assert collections.Counter(r['validity'] for r in findings if r['reviewer'] == 'OCR') == {
    'valid': 11, 'partial': 2, 'invalid': 3, 'unadjudicated': 17
}
assert collections.Counter(r['validity'] for r in findings if r['reviewer'] == 'CodeRabbit') == {
    'valid': 8, 'partial': 2, 'invalid': 2, 'unadjudicated': 11
}
assert sum(bool(r['overlap_group']) for r in findings) == 20

with (base / 'matched-prs.csv').open(newline='') as f:
    prs = list(csv.DictReader(f))
assert len(prs) == 6
assert {r['match_quality'] for r in prs} == {'exact-head'}
assert sum(int(r['ocr_raw_findings']) for r in prs) == 85
assert sum(int(r['ocr_normalized_findings']) for r in prs) == 74
assert sum(int(r['coderabbit_raw_findings']) for r in prs) == 32
assert sum(int(r['coderabbit_normalized_findings']) for r in prs) == 31
print('CSV and aggregate checks passed')
PY
```

## Exact GitHub object-link validation

```sh
python3 - <<'PY'
import csv
import re
import subprocess
from pathlib import Path

base = Path('research/reviews/comparison/sources')
urls = set()
for name in ('matched-prs.csv', 'matched-findings.csv',
             'semantic-overlap.csv', 'excluded-review-iterations.csv'):
    with (base / name).open(newline='') as f:
        for row in csv.DictReader(f):
            for value in row.values():
                if value and value.startswith('https://github.com/'):
                    urls.add(value)
for url in sorted(urls):
    m = re.fullmatch(r'https://github.com/([^/]+/[^/]+)/pull/(\d+)#discussion_r(\d+)', url)
    if m:
        repo, _, comment_id = m.groups()
        subprocess.run(['gh', 'api', f'repos/{repo}/pulls/comments/{comment_id}', '--silent'], check=True)
        continue
    m = re.fullmatch(r'https://github.com/([^/]+/[^/]+)/pull/(\d+)#issuecomment-(\d+)', url)
    if m:
        repo, _, comment_id = m.groups()
        subprocess.run(['gh', 'api', f'repos/{repo}/issues/comments/{comment_id}', '--silent'], check=True)
        continue
    m = re.fullmatch(r'https://github.com/([^/]+/[^/]+)/pull/(\d+)', url)
    if m:
        repo, pr = m.groups()
        subprocess.run(['gh', 'api', f'repos/{repo}/pulls/{pr}', '--silent'], check=True)
        continue
    raise AssertionError(url)
print(f'validated {len(urls)} unique GitHub object links')
PY
```

## Relative links and compact inventory

```sh
python3 - <<'PY'
import re
from pathlib import Path

root = Path('research/reviews/comparison')
for md in root.rglob('*.md'):
    text = md.read_text()
    for target in re.findall(r'\[[^]]*\]\(([^)]+)\)', text):
        if '://' in target or target.startswith('#'):
            continue
        assert (md.parent / target).resolve().exists(), (md, target)
print('relative Markdown links passed')
PY

find research/reviews/comparison -type f -print | sort
```

Application tests are intentionally not run for this documentary research task.
