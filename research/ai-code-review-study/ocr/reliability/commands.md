# Commands and reproduction

Run from repository root. All writes are restricted to `research/reviews/ocr/reliability`.

## Read-only discovery performed

```sh
find research/reviews/ocr -maxdepth 3 -type f -print | sort
find ~/.opencodereview -maxdepth 4 -type f -print | sort
find $TMPDIR $TMPDIR -maxdepth 3 -iname 'ocr*' -print | sort -u
find ~/.opencodereview/sessions -type f -name '*.jsonl' -exec stat ...
find $TMPDIR -maxdepth 1 -type f -iname 'ocr*' -exec stat ...
```

Targeted Python inspected JSON config provider/model/host fields with credential fields redacted, counted session files/bytes, and parsed execution status. Broad keyword matches were not used as failures because reviewed source code frequently contains terms such as “timeout” and “rate limit.”

## Dataset generation

The one-time extraction used targeted scripts created inside this directory. The final canonical `run-events.csv` folds same-stem JSON/log companions and excludes preview/PID/status/research artifacts. Temporary extraction helpers were removed after generation.

```sh
python3 research/reviews/ocr/reliability/generate-reliability-chart.py
python3 research/reviews/ocr/reliability/validation.py
```

The chart generator reads `run-events.csv` and writes `reliability-by-period.csv`, `chart-timeseries.csv`, `reliability-over-time.svg`, and `reliability-over-time.png`.

## Official source verification

Discovery used web search; every material source was then fetched directly:

```text
https://ollama.com/pricing
https://docs.ollama.com/cloud
https://docs.z.ai/devpack/overview
https://docs.z.ai/devpack/faq
https://docs.z.ai/devpack/usage-policy
https://platform.stepfun.com/docs/zh/step-plan/overview
https://platform.stepfun.com/docs/zh/guides/models/step-3.7-flash
https://platform.stepfun.com/docs/zh/step-plan/paid-service-agreement
```

## Prohibited application commands

No npm, lint, test, typecheck, build, Bun application run, or application verification command was executed. Validation is documentary/data-only.
