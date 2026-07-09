# Agent Skills

Portable LLxprt Code / Gemini CLI skills that codify review and quality
workflows. Each skill is a directory containing a `SKILL.md` file with YAML
frontmatter (`name`, `description`) and a markdown body with the workflow
instructions.

## Available skills

| Skill | What it does |
| --- | --- |
| `open-code-review` | Runs OpenCodeReview (ocr) in the background, classifies findings by severity (High/Medium/Low), and applies fixes. |
| `coderabbit-review` | Runs the CodeRabbit CLI locally, classifies findings by severity (High/Medium/Low), and applies fixes. Supports autonomous implement-review-fix cycles. |

## Skill format

Each skill lives in its own directory under `skills/`:

```text
skills/
  <skill-name>/
    SKILL.md
```

The `SKILL.md` file uses YAML frontmatter:

```yaml
---
name: my-skill
description: Use this skill when ...
---

# My Skill

Workflow instructions...
```

The `name` and `description` fields are required. The body is the instruction
set the agent receives when the skill is activated.

## Installation

### Option A — Convenience installer

Install all skills into the platform-specific user skills directory:

```sh
skills/install.sh
```

Install into a specific project (`.llxprt/skills/`):

```sh
skills/install.sh /path/to/project
```

### Option B — Manual copy

Copy a skill directory into the appropriate skills location:

```sh
# User-global (platform-specific config dir):
#   macOS:   ~/Library/Preferences/llxprt-code/skills/
#   Linux:   ~/.config/llxprt-code/skills/
#   Windows: %APPDATA%\llxprt-code\Config\skills\
cp -r skills/open-code-review ~/Library/Preferences/llxprt-code/skills/  # macOS

# Project-local (shared via version control):
cp -r skills/open-code-review your-project/.llxprt/skills/
```

### Discovery paths

LLxprt Code discovers skills from these locations (lowest to highest
precedence):

1. Built-in skills (shipped with the CLI)
2. Extension skills (bundled in extensions)
3. User skills: platform config dir (e.g. `~/Library/Preferences/llxprt-code/skills/`
   on macOS). Override with `$LLXPRT_CONFIG_HOME`. The legacy `~/.llxprt/skills/`
   path is deprecated but still works as a fallback. Also: `~/.agents/skills/`
   alias (pending [vybestack/llxprt-code#2455](https://github.com/vybestack/llxprt-code/issues/2455)).
4. Workspace skills: `.llxprt/skills/` (or `.agents/skills/` alias).

Within the same tier, `.agents/skills/` takes precedence over `.llxprt/skills/`.

## Related

- `review-configs/ocr/` — OCR configuration templates (rule.json, CI workflow,
  review prompt) that the `open-code-review` skill references as prerequisites.
- `review-configs/coderabbit/` — CodeRabbit configuration templates.
