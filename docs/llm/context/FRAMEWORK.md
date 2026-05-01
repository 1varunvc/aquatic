---

## FRAMEWORK.md

```markdown
# FRAMEWORK.md — Aquatic

## System Overview

Aquatic is a macOS CLI toolkit providing commands for video processing (`ffmpeg`), Git tagging (`gh` + `jq`), CSV data parsing (Node.js), and dev-only browser snippets copied to the clipboard. Runtime scripts live in the repository root; documentation lives under `docs/` and `.github/`. The `aquatic` Bash router dispatches to Bash scripts, Node.js scripts, and the gated `dev` snippet flow.

## How It Works — Execution Flow

```
User runs: aquatic <command> [args...]
│
▼
aquatic (Bash router) ─── $1 = COMMAND, shift
│
├── case: slideshow|compress|mute|trim|xlr8|tag|commit-history
│       → "$DIR/aquatic-<command>.sh" "$@"
│
├── case: net-surcharges
│       → node "$DIR/aquatic-platform-mm-net-surcharges.js" "$@"
│
├── case: dev
│       → require `AQUATIC_DEV=1`
│       → $1 = dev snippet name
│       → locate file: aquatic-dev-<name>.js
│       → sanitize_sed escapes injected values
│       → if/elif chain injects ___PLACEHOLDER___ values from $2, $3...
│       → pipe result to pbcopy
│       → echo "[OK] Snippet copied to clipboard!"
│
└── case: * (default)
        → print help/usage text
```

**Key file pointers:**
- Top-level command routing: `aquatic:21-45`
- Dev snippet dispatch, gating, and placeholder injection: `aquatic:46-105`
- Help text: `aquatic:106-122`

## How To Add Anything — Recipes

### Recipe: New Bash Command (Video)

```
CREATE: aquatic-<name>.sh in repo root
- Use TEMPLATE from DEVELOPER_GUIDE.md § 2
- Header block with Script Name, Description, Usage, Requirements: ffmpeg
- Positional args: $1 = dir, $2 = file, optional with ${N:-default}
- Validate required args, guard cd, use `set -euo pipefail`, run ffmpeg, log outcome
- Output file: <base>_<suffix>.mov

WIRE:
1. aquatic — add case entry before the `*)` block:
   <name>)
   "$DIR/aquatic-<name>.sh" "$@"
   ;;
2. aquatic — add usage line in help text

MODEL: aquatic-mute.sh (simple) or aquatic-xlr8.sh (multi-stage)

VERIFY: chmod +x aquatic-<name>.sh && aquatic <name> <test-args>
```

### Recipe: New Bash Command (Git/API)

```
CREATE: aquatic-<name>.sh in repo root
- Header with Requirements: gh, jq
- Positional args for owner, repo, etc.
- Use gh api for GitHub calls, jq for parsing

WIRE: Same as above (case entry + help line in aquatic)

MODEL: aquatic-platform-mm-tag.sh

VERIFY: aquatic <name> <owner> <repo> <args>
```

### Recipe: New Node.js Command

```
CREATE: aquatic-<name>.js in repo root
- Shebang: #!/usr/bin/env node
- JS header block (/** ... */)
- require('fs') and require('path') only — no npm deps
- process.argv[2] for first arg
- Validate with fs.existsSync, console.error + process.exit(1)

WIRE:
1. aquatic — add case entry:
   <name>)
   node "$DIR/aquatic-<name>.js" "$@"
   ;;
2. aquatic — add help line

MODEL: aquatic-platform-mm-net-surcharges.js

VERIFY: aquatic <name> <test-args>
```

### Recipe: New Dev Snippet (No Placeholders)

```
CREATE: aquatic-dev-<name>.js in repo root
- // header block (no shebang)
- Pure browser JS (document.querySelector, async clipboard helpers, etc.)

WIRE:
1. aquatic — add snippet name to the "Available:" error message in the existing `dev)` block
2. No elif needed — the `dev)` branch falls through to `cat "$DEV_FILE" | pbcopy`

MODEL: aquatic-dev-mm-expand-module.js

VERIFY: AQUATIC_DEV=1 aquatic dev <name> → check clipboard with pbpaste
```

### Recipe: New Dev Snippet (With Placeholders)

```
CREATE: aquatic-dev-<name>.js in repo root
- Use ___UPPER_SNAKE_CASE___ for each injectable value
- // header block

WIRE:
1. aquatic — add snippet name to the "Available:" error message in the existing `dev)` block
2. aquatic — add an `elif [ "$DEV_NAME" = "<name>" ]` block inside `dev)`
3. Sanitize every injected value with `sanitize_sed` before passing it to `sed`
4. Pipe the generated output to `pbcopy`

MODEL: `aquatic:65-99` and `aquatic-dev-mm-extract-csv.js`

VERIFY: AQUATIC_DEV=1 aquatic dev <name> [args] → pbpaste to inspect output
```

## Component Reference

### Router (`aquatic`)
| Aspect | Detail |
|---|---|
| Purpose | Dispatch commands to sub-scripts and dev snippets |
| Mechanism | Bash `case` on `$1`, `shift`, pass `"$@"` |
| Shell safety | `set -euo pipefail` at the top of the router |
| Bash commands | Direct execution: `"$DIR/aquatic-<name>.sh" "$@"` |
| Node.js commands | `node "$DIR/aquatic-<name>.js" "$@"` |
| Dev snippets | `AQUATIC_DEV=1` gate + sanitized `sed` injection → `pbcopy` |
| Script dir resolution | `DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` |

### Video Commands
| Command | Script | What it does | Output |
|---|---|---|---|
| compress | `aquatic-compress.sh` | Re-encode at target FPS | `<base>_<fps>fps.mov` |
| mute | `aquatic-mute.sh` | Strip audio + set FPS | `<base>_mute.mov` |
| trim | `aquatic-trim.sh` | Compress + cut middle section + concat | `<base>_trimmed.mov` |
| xlr8 | `aquatic-xlr8.sh` | Speed up a middle section and overlay status text | `<base>_<speed>x_<fps>fps.mov` |
| slideshow | `aquatic-slideshow.sh` | Stitch images into captioned video | `<firstimg>_01fps.mov` |

### Git Commands
| Command | Script | What it does |
|---|---|---|
| tag | `aquatic-platform-mm-tag.sh` | Create GitHub tag `<ver>_r<sha7>` via `gh api` |
| commit-history | `aquatic-commit-history.sh` | Visualize recent commits per tag (zsh, GraphQL) |

### Data Commands
| Command | Script | What it does |
|---|---|---|
| net-surcharges | `aquatic-platform-mm-net-surcharges.js` | Parse CSVs, tally surcharges, `console.table` output |

### Dev Snippets
| Command | File Pattern | What it does |
|---|---|---|
| dev | `aquatic-dev-<name>.js` | Copy a dev-only browser JS snippet to the clipboard, optionally injecting sanitized placeholder values |

### Dev Snippet System

**Decision: Which dev snippet pattern?**
```
Does the dev snippet need injected values?
├─ NO  → Plain JS file. Falls through to cat|pbcopy in `aquatic`.
└─ YES → Use ___PLACEHOLDER___ tokens.
         Sanitize each user value with sanitize_sed first.
         ├─ Single placeholder → single sed "s~...~...~g"
         └─ Multiple placeholders → chained sed -e replacements
```

## Configuration Reference

There is no config file system. All configuration is via:

| Method | Where | Example |
|---|---|---|
| Positional CLI args | Every script | `aquatic mute /path video.mov 15` |
| Environment variables | Router / dev snippets | `AQUATIC_DEV=1 aquatic dev mm-expand-module` |
| Parameter expansion defaults | Each script's arg section | `FPS="${3:-30}"` |
| Hardcoded constants | Script-local config | `FONT="Monaco"` in `aquatic-xlr8.sh` |
| User configuration block | `aquatic-slideshow.sh` | `FONT_SIZE`, `WRAP_WIDTH`, `FPS`, `DEBUG_MODE` |
| Captions data file | `captions.txt` (user-created) | `Filename | Caption text` format, see `captions.example.txt` |

## Key Files Quick Lookup

| When you need to... | Read this file |
|---|---|
| Understand how commands are routed | `aquatic` |
| See how dev snippets are gated and injected | `aquatic:46-105` |
| Write a simple Bash video command | `aquatic-mute.sh` |
| Write a multi-stage Bash video command | `aquatic-xlr8.sh` |
| Write the most complex Bash command | `aquatic-slideshow.sh` |
| Write a Git/GitHub command | `aquatic-platform-mm-tag.sh` |
| Write a zsh command with GraphQL | `aquatic-commit-history.sh` |
| Write a Node.js data command | `aquatic-platform-mm-net-surcharges.js` |
| Write the simplest dev snippet | `aquatic-dev-mm-expand-module.js` |
| Write a complex async dev snippet | `aquatic-dev-mm-extract-csv.js` |
| Understand the header format (Bash) | `.github/copilot-instructions.md` |
| Understand the header format (JS) | `.github/copilot-instructions.md` |
| Understand the header format (dev snippet) | `.github/copilot-instructions.md` |
| See coding standards and rules | `.github/copilot-instructions.md` |
| See AI/Copilot instructions | `.github/copilot-instructions.md` |
| See captions data format | `captions.example.txt` |
```