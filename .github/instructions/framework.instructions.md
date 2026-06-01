---

## framework.instructions.md

```markdown
# framework.instructions.md — Aquatic

## System Overview

Aquatic is a macOS CLI toolkit providing commands for video processing (`ffmpeg`), Git tagging (`gh` + `jq`), CSV data parsing (Node.js), and dev-only browser snippets copied to the clipboard. The `aquatic` Bash router in the repo root dispatches to sub-scripts in `scripts/` and `scripts/dev/`. Documentation lives under `docs/` and `.github/`. The toolkit includes version management via `VERSION` file and an update notification system reading from `RELEASES.md`.

## How It Works — Execution Flow

```
User runs: aquatic <command> [args...]
│
▼
aquatic (Bash router) ─── reads VERSION, runs _aquatic_update_notify()
│
├── --version|-v → print version and exit
│
├── $1 = COMMAND, shift
│
├── case: slideshow|compress|mute|trim|xlr8|tag|commit-history
│       → "$SCRIPT_DIR/aquatic-<command>.sh" "$@"
│
├── case: dev
│       → require `AQUATIC_DEV=1`
│       → $1 = dev snippet name
│       → locate file: aquatic-dev-<name>.js
│       → if mm-net-surcharges: run via `node` with remaining args
│       → else: sanitize_sed escapes injected values
│       → if/elif chain injects ___PLACEHOLDER___ values from $2, $3...
│       → pipe result to pbcopy
│       → echo "[OK] Snippet copied to clipboard!"
│
└── case: * (default)
        → print branded help/usage text with all commands
```

**Key file pointers:**
- Version and update notification: `aquatic:17-46`
- Top-level command routing: `aquatic:51-75`
- Dev snippet dispatch, gating, and placeholder injection: `aquatic:76-138`
- Help text: `aquatic:140-161`

## How To Add Anything — Recipes

### Recipe: New Bash Command (Video)

```
CREATE: scripts/aquatic-<name>.sh
- Use TEMPLATE from developer-guide.instructions.md S 2
- Header block with Script Name, Description, Usage, Requirements: ffmpeg
- Flag-based arg parsing: while/case loop with POSITIONAL array
- --help|-h handler
- Validate required args after loop, check file exists
- Run ffmpeg, log outcome
- Output file: <base>_<suffix>.mov

WIRE:
1. aquatic — add case entry before the `*)` block:
   <name>)
   "$SCRIPT_DIR/aquatic-<name>.sh" "$@"
   ;;
2. aquatic — add usage line in help text

MODEL: scripts/aquatic-mute.sh (simple) or scripts/aquatic-xlr8.sh (multi-stage)

VERIFY: chmod +x scripts/aquatic-<name>.sh && aquatic <name> <test-args>
```

### Recipe: New Bash Command (Git/API)

```
CREATE: scripts/aquatic-<name>.sh
- Header with Requirements: gh, jq
- Flag-based arg parsing with POSITIONAL array for owner, repo, etc.
- --help|-h handler
- Use gh api for GitHub calls, jq for parsing

WIRE: Same as above (case entry + help line in aquatic)

MODEL: scripts/aquatic-git-tag.sh

VERIFY: aquatic <name> <owner> <repo> <args>
```

### Recipe: New Node.js Command

```
CREATE: scripts/dev/aquatic-<name>.js
- Shebang: #!/usr/bin/env node
- JS header block (/** ... */)
- require('fs') and require('path') only — no npm deps
- process.argv[2] for first arg
- Validate with fs.existsSync, console.error + process.exit(1)

WIRE:
1. aquatic — add case entry:
   <name>)
   node "$DEV_DIR/aquatic-<name>.js" "$@"
   ;;
2. aquatic — add help line

MODEL: scripts/dev/aquatic-dev-mm-net-surcharges.js

VERIFY: aquatic <name> <test-args>
```

### Recipe: New Dev Snippet (No Placeholders)

```
CREATE: scripts/dev/aquatic-dev-<name>.js
- // header block (no shebang)
- Pure browser JS (document.querySelector, async clipboard helpers, etc.)

WIRE:
1. aquatic — add snippet name to the "Available:" error message in the existing `dev)` block
2. No elif needed — the `dev)` branch falls through to `cat "$DEV_FILE" | pbcopy`

MODEL: scripts/dev/aquatic-dev-mm-expand-module.js

VERIFY: AQUATIC_DEV=1 aquatic dev <name> → check clipboard with pbpaste
```

### Recipe: New Dev Snippet (With Placeholders)

```
CREATE: scripts/dev/aquatic-dev-<name>.js
- Use ___UPPER_SNAKE_CASE___ for each injectable value
- // header block

WIRE:
1. aquatic — add snippet name to the "Available:" error message in the existing `dev)` block
2. aquatic — add an `elif [ "$DEV_NAME" = "<name>" ]` block inside `dev)`
3. Sanitize every injected value with `sanitize_sed` before passing it to `sed`
4. Pipe the generated output to `pbcopy`

MODEL: `aquatic:99-134` and `scripts/dev/aquatic-dev-mm-extract-csv.js`

VERIFY: AQUATIC_DEV=1 aquatic dev <name> [args] → pbpaste to inspect output
```

## Component Reference

### Router (`aquatic`)
| Aspect | Detail |
|---|---|
| Purpose | Dispatch commands to sub-scripts and dev snippets; version display; update notification |
| Mechanism | Bash `case` on `$1`, `shift`, pass `"$@"` |
| Shell safety | `set -euo pipefail` at the top of the router |
| Version | Reads `VERSION` file; supports `--version`/`-v` flag |
| Update check | `_aquatic_update_notify()` reads `RELEASES.md` and shows versions newer than current |
| Bash commands | Direct execution: `"$SCRIPT_DIR/aquatic-<name>.sh" "$@"` |
| Node.js commands | `node "$DEV_DIR/aquatic-<name>.js" "$@"` |
| Dev snippets | `AQUATIC_DEV=1` gate + sanitized `sed` injection → `pbcopy` |
| Script dir resolution | `DIR` → repo root; `SCRIPT_DIR="$DIR/scripts"`; `DEV_DIR="$DIR/scripts/dev"` |

### Video Commands
| Command | Script | What it does | Output |
|---|---|---|---|
| compress | `scripts/aquatic-compress.sh` | Re-encode at target FPS | `<base>_<fps>fps.mov` |
| mute | `scripts/aquatic-mute.sh` | Strip audio + set FPS | `<base>_mute.mov` |
| trim | `scripts/aquatic-trim.sh` | Compress + cut middle section + concat | `<base>_trimmed.mov` |
| xlr8 | `scripts/aquatic-xlr8.sh` | Speed up a middle section and overlay status text | `<base>_<speed>x_<fps>fps.mov` |
| slideshow | `scripts/aquatic-slideshow.sh` | Stitch images into captioned video | `<firstimg\|output-name>_01fps.mov` |

### Git Commands
| Command | Script | What it does |
|---|---|---|
| tag | `scripts/aquatic-git-tag.sh` | Create GitHub tag `<ver>_r<sha7>` via `gh api` |
| commit-history | `scripts/aquatic-commit-history.sh` | Visualize recent commits per tag (zsh, GraphQL) |

### Dev Commands
| Command | Script | What it does |
|---|---|---|
| dev mm-net-surcharges | `scripts/dev/aquatic-dev-mm-net-surcharges.js` | Parse CSVs, tally surcharges, `console.table` output |
| dev <name> | `scripts/dev/aquatic-dev-<name>.js` | Copy a dev-only browser JS snippet to the clipboard, optionally injecting sanitized placeholder values |

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
| Positional CLI args | Every script (collected via POSITIONAL array) | `aquatic mute video.mov --fps 15` |
| Flag-based options | Every script (parsed via while/case loop) | `aquatic trim file.mov --start 00:00:58 --end 00:01:05` |
| Environment variables | Router / dev snippets | `AQUATIC_DEV=1 aquatic dev mm-expand-module` |
| Hardcoded defaults | Each script before parsing loop | `FPS="30"` in `aquatic-mute.sh` |
| User configuration block | `aquatic-slideshow.sh` | `FONT_SIZE`, `WRAP_WIDTH`, `FPS`, `DEBUG_MODE` |
| Captions data file | `captions.txt` (user-created) | `Filename | Caption text` format, see `scripts/captions.example.txt` |
| Version file | `VERSION` in repo root | Single-line version string |
| Release log | `RELEASES.md` in repo root | `version|summary` lines for update notifications |

## Key Files Quick Lookup

| When you need to... | Read this file |
|---|---|
| Understand how commands are routed | `aquatic` |
| See how dev snippets are gated and injected | `aquatic:76-138` |
| See version and update notification logic | `aquatic:17-46` |
| Write a simple Bash video command | `scripts/aquatic-mute.sh` |
| Write a multi-stage Bash video command | `scripts/aquatic-xlr8.sh` |
| Write the most complex Bash command | `scripts/aquatic-slideshow.sh` |
| Write a Git/GitHub command | `scripts/aquatic-git-tag.sh` |
| Write a zsh command with GraphQL | `scripts/aquatic-commit-history.sh` |
| Write a Node.js data command | `scripts/dev/aquatic-dev-mm-net-surcharges.js` |
| Write the simplest dev snippet | `scripts/dev/aquatic-dev-mm-expand-module.js` |
| Write a complex async dev snippet | `scripts/dev/aquatic-dev-mm-extract-csv.js` |
| Understand the header format | `.github/copilot-instructions.md` |
| See coding standards and rules | `.github/copilot-instructions.md` |
| See captions data format | `scripts/captions.example.txt` |
```