
---

## FRAMEWORK.md

```markdown
# FRAMEWORK.md — Aquatic CLI

## System Overview

Aquatic is a macOS CLI toolkit providing commands for video processing (ffmpeg), Git tagging (gh + jq), CSV data parsing (Node.js), and browser automation snippets (clipboard injection via sed + pbcopy). The `aquatic` Bash script routes commands to modular sub-scripts. All files live in a flat directory with no build system or package manager.

## How It Works — Execution Flow

```
User runs: aquatic <command> [args...]
│
▼
aquatic (Bash router) ─── $1 = COMMAND, shift
│
├── case: slideshow|compress|mute|trim|tag|commit-history
│       → "$DIR/aquatic-<command>.sh" "$@"
│
├── case: net-surcharges
│       → node "$DIR/aquatic-platform-mm-net-surcharges.js" "$@"
│
├── case: snippet
│       → $1 = snippet name
│       → locate file: aquatic-snippet-platform-<name>.js
│       → if/elif chain per snippet:
│           sed injects ___PLACEHOLDER___ values from $2, $3...
│           pipes to pbcopy
│       → echo "[OK] Snippet copied to clipboard!"
│
└── case: * (default)
→ print help/usage text
```

**Key file pointers:**
- Routing logic: `aquatic:20-92`
- Snippet dispatch with placeholder injection: `aquatic:42-91`
- Help text: `aquatic:93-109`

## How To Add Anything — Recipes

### Recipe: New Bash Command (Video)

```
CREATE: aquatic-<name>.sh in repo root
- Use TEMPLATE from DEVELOPER_GUIDE.md § 2
- Header block with Script Name, Description, Usage, Requirements: ffmpeg
- Positional args: $1 = dir, $2 = file, optional with ${N:-default}
- Validate required args, guard cd, run ffmpeg, echo Done
- Output file: <base>_<suffix>.mov

WIRE:
1. aquatic — add case entry before *) block (~line 92):
   <name>)
   "$DIR/aquatic-<name>.sh" "$@"
   ;;
2. aquatic — add usage line in help text (~line 107):
   echo "  <name>         <args>                     - Description"

MODEL: aquatic-mute.sh (simple) or aquatic-trim.sh (multi-step)

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

### Recipe: New Browser Snippet (No Placeholders)

```
CREATE: aquatic-snippet-platform-<name>.js in repo root
- // header block (no shebang)
- Pure browser JS (document.querySelector, etc.)

WIRE:
1. aquatic:48 — add snippet name to "Available:" error message
2. No elif needed — falls through to the else/cat block at aquatic:89

MODEL: aquatic-snippet-platform-mm-expand-module.js

VERIFY: aquatic snippet <name> → check clipboard with pbpaste
```

### Recipe: New Browser Snippet (With Placeholders)

```
CREATE: aquatic-snippet-platform-<name>.js in repo root
- Use ___UPPER_SNAKE_CASE___ for each injectable value
- // header block

WIRE:
1. aquatic — add elif block inside the snippet) case (~line 70-91):
   elif [ "$SNIPPET_NAME" = "<name>" ]; then
   PARAM="${2:-default}"
   sed "s~___PLACEHOLDER___~$PARAM~g" "$SNIPPET_FILE" | pbcopy
   echo "[OK] Snippet '$SNIPPET_NAME' copied to clipboard!"
2. aquatic:48 — add to "Available:" list

MODEL: aquatic:52-56 (mm-expand-module, single placeholder)
aquatic:58-68 (mm-extract-csv, multiple placeholders with -e chaining)

VERIFY: aquatic snippet <name> [args] → pbpaste to inspect output
```

## Component Reference

### Router (`aquatic`)
| Aspect | Detail |
|---|---|
| Purpose | Dispatch commands to sub-scripts |
| Mechanism | Bash `case` on `$1`, `shift`, pass `"$@"` |
| Bash commands | Direct execution: `"$DIR/aquatic-<name>.sh" "$@"` |
| Node.js commands | `node "$DIR/aquatic-<name>.js" "$@"` |
| Snippets | `sed` placeholder injection → `pbcopy` |
| Script dir resolution | `DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` — line 18 |

### Video Commands
| Command | Script | What it does | Output |
|---|---|---|---|
| compress | aquatic-compress.sh | Re-encode at target FPS | `<base>_<fps>fps.mov` |
| mute | aquatic-mute.sh | Strip audio + set FPS | `<base>_mute.mov` |
| trim | aquatic-trim.sh | Compress + cut middle section + concat | `<base>_trimmed.mov` |
| slideshow | aquatic-slideshow.sh | Stitch images into captioned video | `<firstimg>_01fps.mov` |

### Git Commands
| Command | Script | What it does |
|---|---|---|
| tag | aquatic-platform-mm-tag.sh | Create GitHub tag `<ver>_r<sha7>` via `gh api` |
| commit-history | aquatic-commit-history.sh | Visualize recent commits per tag (zsh, GraphQL) |

### Data Commands
| Command | Script | What it does |
|---|---|---|
| net-surcharges | aquatic-platform-mm-net-surcharges.js | Parse CSVs, tally surcharges, `console.table` output |

### Snippet System

**Decision: Which snippet pattern?**
```
Does the snippet need injected values?
├─ NO  → Plain JS file. Falls through to cat|pbcopy (aquatic:89).
└─ YES → Use ___PLACEHOLDER___ tokens.
├─ Single placeholder → single sed "s~...~...~g" (see aquatic:54)
└─ Multiple placeholders → chained sed -e (see aquatic:63-66)
```

## Configuration Reference

There is no config file system. All configuration is via:

| Method | Where | Example |
|---|---|---|
| Positional CLI args | Every script | `aquatic mute /path video.mov 15` |
| Parameter expansion defaults | Each script's arg section | `FPS="${3:-30}"` in `aquatic-mute.sh:17` |
| Hardcoded constants | Script header sections | `OWNER="owner"` in `aquatic-commit-history.sh:20` |
| User configuration block | `aquatic-slideshow.sh:17-38` | `FONT_SIZE`, `WRAP_WIDTH`, `FPS`, `DEBUG_MODE` |
| Captions data file | `captions.txt` (user-created) | `Filename | Caption text` format, see `captions.example.txt` |

## Key Files Quick Lookup

| When you need to... | Read this file |
|---|---|
| Understand how commands are routed | `aquatic` |
| See how snippets are injected and dispatched | `aquatic:42-91` |
| Write a simple Bash video command | `aquatic-mute.sh` |
| Write a multi-step Bash video command | `aquatic-trim.sh` |
| Write the most complex Bash command | `aquatic-slideshow.sh` |
| Write a Git/GitHub command | `aquatic-platform-mm-tag.sh` |
| Write a zsh command with GraphQL | `aquatic-commit-history.sh` |
| Write a Node.js data command | `aquatic-platform-mm-net-surcharges.js` |
| Write the simplest browser snippet | `aquatic-snippet-platform-mm-expand-module.js` |
| Write a complex async browser snippet | `aquatic-snippet-platform-mm-extract-csv.js` |
| Understand the header format (Bash) | `aquatic-mute.sh:3-13` |
| Understand the header format (JS) | `aquatic-platform-mm-net-surcharges.js:3-15` |
| Understand the header format (snippet) | `aquatic-snippet-platform-mm-expand-module.js:1-9` |
| See coding standards and rules | `project_rules.md` |
| See AI/Copilot instructions | `.github/copilot-instructions.md` |
| See captions data format | `captions.example.txt` |
```