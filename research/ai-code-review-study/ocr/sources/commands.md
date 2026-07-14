# Reproduction commands

Run from the repository root. GitHub acquisition used **only `gh`**. Output was staged under `$TMPDIR`; the repository-safe extracts are generated into this directory.

## GitHub capture

```sh
for spec in llxprt-code:2462 llxprt-code:2547 llxprt-jefe:181 llxprt-jefe:275 llxprt-luther:110 llxprt-luther:133 llxprt-jefe:236; do
  repo=${spec%:*}
  pr=${spec#*:}
  out=$TMPDIR/ocr-research-${repo}-${pr}
  gh api repos/vybestack/$repo/pulls/$pr > ${out}-pr.json
  gh api --paginate repos/vybestack/$repo/issues/$pr/comments > ${out}-issue-comments.json
  gh api --paginate repos/vybestack/$repo/pulls/$pr/comments > ${out}-review-comments.json
  gh api --paginate repos/vybestack/$repo/pulls/$pr/reviews > ${out}-reviews.json
  gh api --paginate repos/vybestack/$repo/pulls/$pr/commits > ${out}-commits.json
done
```

Exact PR URLs:

- https://github.com/vybestack/llxprt-code/pull/2462
- https://github.com/vybestack/llxprt-code/pull/2547
- https://github.com/vybestack/llxprt-jefe/pull/181
- https://github.com/vybestack/llxprt-jefe/pull/275
- https://github.com/vybestack/llxprt-luther/pull/110
- https://github.com/vybestack/llxprt-luther/pull/133
- https://github.com/vybestack/llxprt-jefe/pull/236

## Local provenance

```sh
stat -f '%N %Sm %z' -t '%Y-%m-%dT%H:%M:%SZ' PATH
shasum -a 256 PATH
rg -l -F 'server name or URL contains a null character' "$HOME/.opencodereview/sessions"
rg -l -F "The removed 'Message Queuing' tests covered critical behavioral guarantees" "$HOME/.opencodereview/sessions"
rg -l -F 'After switching repositories, this test previously asserted' "$HOME/.opencodereview/sessions"
```

## Canonical datasets

The repository-safe CSVs are checked-in research artifacts. Their row-level evidence and classification rules are documented in [evidence-index.md](evidence-index.md); temporary extraction scripts are intentionally not retained as source material.

## Validation

```sh
python3 - <<'PY'
import csv
from pathlib import Path
base = Path('research/reviews/ocr/sources')
for name, expected in [('sampled-findings.csv', 36), ('local-findings.csv', 23)]:
    with (base / name).open(newline='') as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        assert reader.fieldnames and len(reader.fieldnames) == len(set(reader.fieldnames))
        assert len(rows) == expected, (name, len(rows))
        assert all(set(row) == set(reader.fieldnames) for row in rows)
print('CSV shape OK')
PY

find research/reviews/ocr -type f -print | sort
rg -o 'https://github.com/[^ )]+' research/reviews/ocr | sort -u
# Network-check exact GitHub links with gh, not curl/web fetch:
gh api repos/vybestack/llxprt-code/pulls/2462 --jq .html_url

git status --short -- research/reviews/ocr
git diff --check -- research/reviews/ocr
git diff --stat -- research/reviews/ocr
git status --short | awk '$2 !~ /^research\/reviews\/ocr\// {print}'
```

The full project test/lint/build suite is not relevant to a Markdown/CSV-only research artifact and was not run; the targeted validations above cover generated shape, links, inventory, whitespace, and scope.
