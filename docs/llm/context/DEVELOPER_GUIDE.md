## DEVELOPER_GUIDE.md

```markdown
# DEVELOPER_GUIDE.md — Aquatic

## Quick Reference Card

| I need to create a... | Pattern | Location | Name Pattern |
|---|---|---|---|
| New Bash command | Validate → `cd` → execute → log/save output | `aquatic-<name>.sh` (root) | `aquatic-<command-name>.sh` |
| New Node.js command | `#!/usr/bin/env node`, built-in modules, validate → process → output | `aquatic-<name>.js` (root) | `aquatic-<command-name>.js` |
| New dev snippet | JS with `___PLACEHOLDER___` tokens, no shebang | `aquatic-dev-<name>.js` (root) + existing `dev)` branch in `aquatic` | `aquatic-dev-<name>.js` |
| New router entry | `case` block in `aquatic` | `aquatic` | Match the command name string |

## 1. Project Structure Rules

- All runnable scripts live in the repository root. No subdirectories for commands.
- The router is `aquatic` (no extension). Bash/Zsh sub-scripts use `.sh`; Node.js commands and dev snippets use `.js`.
- Human-facing docs live in `docs/`. LLM reference docs live in `docs/llm/context/`. Prompt and agent workflow docs live in `docs/llm/prompts/` and `docs/llm/agent/`. AI instructions live in `.github/copilot-instructions.md`.
- No `node_modules/`, no `package.json`. Node.js scripts use only built-in modules (`fs`, `path`).

## 2. File Templates

### TEMPLATE: Bash Command
```bash
#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-<command>.sh
# Description : <One sentence>.
#
# Author      : Varun Chawla
# Created On  : <Date>
# Last Updated: <Date>
# Version     : 1.0
# Usage       : aquatic <command> <required_arg> [optional_arg]
# Requirements: <ffmpeg, gh, jq, etc.>
###############################################################################

TARGET_DIR="${1:-}"
REQUIRED_ARG="${2:-}"
OPTIONAL_ARG="${3:-default_value}"

if [ -z "$REQUIRED_ARG" ]; then
    echo "Usage: aquatic <command> <required_arg> [optional_arg]"
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

# --- MAIN LOGIC ---

echo "[OK] Done."
```
**MODEL:** `aquatic-mute.sh` or `aquatic-xlr8.sh`

### TEMPLATE: Node.js Command
```javascript
#!/usr/bin/env node

/**
 * ###############################################################################
 * Script Name : aquatic-<command>.js
 * Description : <One sentence>.
 *
 * Author      : Varun Chawla
 * Created On  : <Date>
 * Last Updated: <Date>
 * Version     : 1.0
 * Usage       : aquatic <command> [args]
 * Requirements: node
 * ###############################################################################
 */

const fs = require('fs');
const path = require('path');

const arg = process.argv[2] || '.';

if (!fs.existsSync(arg)) {
    console.error(`[ERROR] Path not found: ${arg}`);
    process.exit(1);
}

// --- MAIN LOGIC ---
```
**MODEL:** `aquatic-platform-mm-net-surcharges.js`

### TEMPLATE: Dev Snippet
```javascript
// ###############################################################################
// Script Name : mm-<name>
// Description : <One sentence>.
// Author      : Varun Chawla
// Created On  : <Date>
// Last Updated: <Date>
// Version     : 1.0
// Usage       : AQUATIC_DEV=1 aquatic dev mm-<name> [args]
// ###############################################################################

// Use ___UPPER_SNAKE_CASE___ for injectable placeholders.
```
**MODEL:** `aquatic-dev-mm-expand-module.js`

### TEMPLATE: Router Case Entry (Bash command)
```bash
    <command-name>)
        "$DIR/aquatic-<command-name>.sh" "$@"
        ;;
```

### TEMPLATE: Router Case Entry (Node.js command)
```bash
    <command-name>)
        node "$DIR/aquatic-<command-name>.js" "$@"
        ;;
```

**Dev snippets do not get their own top-level `case` entry.** They are routed through the existing `dev)` branch in `aquatic`.

### TEMPLATE: Router Case Entry (Dev snippet — with placeholders)
```bash
        elif [ "$DEV_NAME" = "mm-<name>" ]; then
            PARAM1=$(sanitize_sed "${2:-default}")
            sed "s~___PLACEHOLDER___~$PARAM1~g" "$DEV_FILE" | pbcopy
            echo "[OK] Snippet '$DEV_NAME' copied to clipboard!"
```
**MODEL:** `aquatic:65-69` (mm-expand-module block)

## 3. Naming Rules

| Thing | Convention | Example |
|---|---|---|
| Bash sub-script file | `aquatic-<command-name>.sh` | `aquatic-mute.sh` |
| Node.js sub-script file | `aquatic-<command-name>.js` | `aquatic-platform-mm-net-surcharges.js` |
| Dev snippet file | `aquatic-dev-<name>.js` | `aquatic-dev-mm-expand-module.js` |
| Snippet placeholders | `___UPPER_SNAKE_CASE___` | `___EXPANSION_ICON___` |
| Bash variables | `UPPER_SNAKE_CASE` | `TARGET_DIR`, `FPS`, `BASE_NAME` |
| JS variables | `camelCase` | `targetDir`, `brandStats` |
| Video output files | `<base>_<suffix>.mov` | `input_mute.mov`, `input_7fps.mov`, `input_trimmed.mov` |
| xlr8 output files | `<base>_<speed>x_<fps>fps.mov` | `input_20x_30fps.mov` |
| Git tag format | `<version>_r<sha7>` | `1.70.0_rabc1234` |
| Router command name | lowercase, hyphenated | `commit-history`, `net-surcharges` |

## 4. Error Handling Rules

**RULE:** Every script MUST validate required args at the top, before any logic.

```bash
if [ -z "$REQUIRED" ]; then
    echo "Usage: aquatic <command> <required> [optional]"
    exit 1
fi
```

```javascript
if (!fs.existsSync(directoryPath)) {
    console.error(`[ERROR] Directory not found: ${directoryPath}`);
    process.exit(1);
}
```

**RULE:** Bash/Zsh scripts use strict mode immediately after the shebang.
```bash
set -euo pipefail
```

**RULE:** Optional args use parameter expansion with defaults.
```bash
FPS="${3:-30}"
```

**RULE:** Always guard `cd`.
```bash
cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }
```

**RULE:** Sanitize every user-provided dev snippet replacement value before passing it to `sed`.
```bash
PARAM=$(sanitize_sed "${2:-default}")
sed "s~___PLACEHOLDER___~$PARAM~g" "$DEV_FILE" | pbcopy
```

## 5. Output & Logging Rules

| Prefix | When | Example |
|---|---|---|
| `[OK]` | Operation completed successfully | `echo "[OK] Snippet 'mm-expand-module' copied to clipboard!"` |
| `[INFO]` | Progress or informational | `echo "[INFO] Processed 15 CSV files."` |
| `[DEBUG]` | Low-level diagnostic detail | `echo "[DEBUG] Using selector: $SELECTOR"` |
| `[WARN]` | Recoverable issue or fallback | `echo "[WARN] Optional file missing. Using defaults."` |
| `[ERROR]` | Something failed | `echo "[ERROR] Directory '/tmp' not found."` |
| `---` separator | Between processing phases | `echo "-----------------------------------"` |

**RULE:** Logs should include useful operation context without redundant noise.

**RULE:** No emojis in any output, log, or comment. Ever.

## 6. Dependencies & Imports

**RULE:** No `package.json`. No npm dependencies. Node.js scripts use ONLY `fs` and `path` unless explicitly approved.

**RULE:** Prefer standard macOS tools: `sed`, `awk`, `stat`, `md5`, `pbcopy`.

**RULE:** External tools allowed: `ffmpeg` (video), `gh` (GitHub), `jq` (JSON), `node` (data processing).

## 7. Adding a New Command — Checklist

1. **CREATE** the sub-script file in the repo root following the appropriate template above.
2. **ADD** a `case` entry in `aquatic` for Bash/Node.js commands.
3. **ADD** a usage line in the help text block in `aquatic`.
4. **UPDATE** `README.md` if the command is user-facing.
5. **CHMOD** the file: `chmod +x aquatic-<name>.sh` (Bash scripts only).
6. **FOR DEV SNIPPETS:**
   - Add the snippet name to the `Available:` list inside the existing `dev)` block.
   - Add an `elif` block only if placeholders need injection.
   - Sanitize every injected value with `sanitize_sed`.
   - Keep the snippet behind `AQUATIC_DEV=1`.

## 8. Things to Never Do

| # | Rule |
|---|---|
| 1 | No emojis in output, logs, or comments |
| 2 | No npm dependencies — Node.js built-ins only |
| 3 | No interactive prompts (stdin) — all input via positional args |
| 4 | No hardcoded absolute paths to user directories (use `$1` or `$DIR`) |
| 5 | No writing dev snippet output to files — always pipe to `pbcopy` |
| 6 | No bypassing `sanitize_sed` when injecting user input into dev snippets |
| 7 | No bypassing the `AQUATIC_DEV=1` gate for dev snippets |
| 8 | No `cd` without an error guard |
| 9 | No missing file header block |
| 10 | No skipping argument validation at the top of a script |
```
