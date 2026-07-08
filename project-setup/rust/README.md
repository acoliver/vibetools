# Rust project setup

Canonical Rust **lint / complexity / formatting** config, coalesced from three
source projects and set to the **strictest** value wherever they disagreed.

## Files

| File | Purpose |
| --- | --- |
| `clippy.toml` | Clippy complexity thresholds (cognitive complexity, line count, args, bools, type complexity). |
| `.rustfmt.toml` | Formatting rules (max width 100, 4-space indent). |
| `.cargo/config.toml` | Disables incremental compilation (reproducible dev/test builds). |
| `lints.snippet.toml` | The `[lints.rust]` / `[lints.clippy]` sections to merge into `Cargo.toml`. Profile settings live in `.cargo/config.toml`. |
| `init.sh` | One-command installer — copies the configs above and merges lints into `Cargo.toml`. |

## Quick start

```sh
# From the root of your Rust project:
path/to/vibetools/project-setup/rust/init.sh .

# Or via the universal launcher:
path/to/vibetools/project-setup/setup.sh rust .
```

This copies `clippy.toml`, `.rustfmt.toml`, `.cargo/config.toml` into your
project and appends the `[lints]` + `[profile]` tables to `Cargo.toml`.

Then verify:

```sh
cargo fmt --check
cargo clippy --all-targets -- -D warnings
```

## Why each rule was chosen

This setup merges configs from **jefe**, **luther**, and **personal-agent**.
The policy is: **pick the strictest option; never loosen.**

### clippy.toml thresholds (lowest = strictest)

| Threshold | Value | Why |
| --- | --- | --- |
| `cognitive-complexity-threshold` | **15** | jefe=15 &lt; luther=20 &lt; personal-agent=45 |
| `too-many-lines-threshold` | **60** | jefe=60 &lt; personal-agent=100 |
| `too-many-arguments-threshold` | **6** | all three agree |
| `max-struct-bools` | **3** | all three agree |
| `type-complexity-threshold` | **250** | all three agree |

### Cargo.toml `[lints]` policy

| Lint | Level | Why |
| --- | --- | --- |
| `unsafe_code` | **forbid** | jefe forbids; luther/personal-agent only warn. |
| `all` | **deny** | jefe & personal-agent both deny. |
| `pedantic` | **warn** | jefe & personal-agent both warn. |
| `nursery` | **warn** | jefe & personal-agent both warn. |
| `cognitive_complexity` | **deny** | luther denies; personal-agent only warns. |
| `too_many_lines` | **deny** | luther denies. |
| `too_many_arguments` | **deny** | luther denies. |
| `type_complexity` | **deny** | luther denies. |
| `struct_excessive_bools` | **deny** | luther denies. |
| `unwrap_used` / `expect_used` | **warn** | jefe. |
| `print_stdout` / `print_stderr` | **warn** | jefe. |
| `todo` / `unimplemented` | **deny** | jefe. |

### Dropped loosenings

jefe temporarily relaxed several pedantic/nursery lints during a "stub phase"
(`needless_pass_by_value`, `redundant_clone`, `doc_markdown`,
`missing_const_for_fn`, `missing_errors_doc`, `option_if_let_else`). These
`allow` entries are **intentionally omitted** from the canonical config — those
lints stay at their group default (warn) instead of being suppressed.

## What is NOT here

- **Dependencies** — every project has different needs; add your own.
- **Build tooling** (xtask, cargo-deb, etc.) — project-specific.
- **CI workflow** — see this repo's planning docs for CI guidance.
