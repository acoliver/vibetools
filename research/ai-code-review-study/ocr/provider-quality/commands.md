# Commands and reproducibility

Run from the repository root. All writes are restricted to `research/reviews/ocr/provider-quality`. No application tests, lint, typecheck, build, package install, or Bun application run was executed.

## Read-only discovery

Representative commands used to locate evidence:

```sh
find ~/.opencodereview/sessions -maxdepth 2 -type f -print
find $TMPDIR $TMPDIR -maxdepth 3 -iname '*ocr*' -print
rg -i 'step-3.7|stepfun|glm-5.2|api.z.ai|ollama' \
  ~/.opencodereview/sessions $TMPDIR $TMPDIR
python3 -c '... read research/reviews/ocr/reliability/run-events.csv ...'
```

Candidate reruns were inspected with targeted `head`, `tail`, `rg`, `stat`, and `shasum -a 256`. The exact session IDs in OCR JSON were located under `~/.opencodereview/sessions`.

## Redacted configuration extraction

Only provider, endpoint host, protocol, model, and timestamp were retained. Credential fields were recursively omitted. A safe equivalent is:

```sh
python3 -c '
import json, sys
SENSITIVE = ("key", "token", "secret", "password", "credential")
def redact(v):
    if isinstance(v, dict):
        return {k: ("<redacted>" if any(x in k.lower() for x in SENSITIVE) else redact(x))
                for k, x in v.items()}
    if isinstance(v, list): return [redact(x) for x in v]
    return v
print(json.dumps(redact(json.load(open(sys.argv[1]))), indent=2))
' ~/.opencodereview/config.json.stepfun-bak-20260713
```

Raw configs and full session payloads were never copied into this directory.

## Matched commit and action evidence

Read-only Git commands were run against the existing branch-5 worktree:

```sh
git -C $HOME/projects/llxprt/branch-5/llxprt-code \
  show -s --format='%H %P %ci %s' b8ee089626e88952161a17191e213e33048d5e5c
git -C $HOME/projects/llxprt/branch-5/llxprt-code \
  show --stat e8a4ad1d554f8c3bfed11d5697cc8c01aed74acf
git -C $HOME/projects/llxprt/branch-5/llxprt-code \
  diff --name-status b8ee089626e88952161a17191e213e33048d5e5c..e8a4ad1d5
```

The branch-5 worktree was not modified. Its pre-existing `.llxprt`, `.jefe`, source, and test changes were read-only context and were not included as this task's writes.

## Dataset build

```sh
python3 research/reviews/ocr/provider-quality/build_dataset.py
```

The builder:

1. verifies source formats and expected finding counts;
2. parses six retained OCR outputs;
3. writes `provider-runs.csv` and `provider-findings.csv`;
4. applies explicit, auditable matched-pair adjudication/duplicate/overlap/action maps;
5. writes `matched-reruns.csv`, `quality-summary.csv`, and the SVG chart.

## Documentary validation

```sh
python3 research/reviews/ocr/provider-quality/validation.py
```

Validation checks required artifacts, source hashes, row counts, aggregate identities, exact expected matched metrics, Markdown links, cited finding hashes, credential patterns, inventory hashes, and repository write scope. It does not execute application code.

## Inventory generation

After validation and final report edits:

```sh
python3 -c '... SHA-256 each target artifact except file-inventory.txt ...'
```

`file-inventory.txt` is excluded from its own hash to avoid recursion.
