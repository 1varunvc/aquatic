# Copilot Instructions for aquatic

## Project Overview

Aquatic is a unified macOS CLI toolkit for video processing, Git tagging, data parsing, and browser automation snippets.
It uses a router pattern: the `aquatic` Bash script receives a command and delegates to modular sub-scripts.

## Architecture

- **`aquatic`** — Main entry point. Routes commands via a `case` statement.
- **`aquatic-<command>.sh`** — Bash sub-scripts (e.g., `aquatic-trim.sh`, `aquatic-mute.sh`).
- **`aquatic-<command>.js`** — Node.js sub-scripts run directly via `node` (e.g., `aquatic-dev-mm-net-surcharges.js`).
- **`aquatic-dev-<name>.js`** — Dev-only browser-paste JS snippets.
    - Invoked through `aquatic dev <name> [args...]`
    - Requires `AQUATIC_DEV=1`
    - Router injects placeholder values using sanitized `sed` and pipes output to `pbcopy`

To add a new command: create the sub-script file, then add a matching `case` entry in `aquatic`.

## Naming Conventions

| Type | Pattern |
|---|---|
| Bash sub-script | `aquatic-<command-name>.sh` |
| Node.js sub-script | `aquatic-<command-name>.js` |
| Dev snippet | `aquatic-dev-<name>.js` |
| Snippet placeholders | `___UPPER_SNAKE_CASE___` |

## Mandatory File Header

Every file must begin with this exact header block (adapted for comment syntax).

**Bash:**
```bash
#!/bin/bash

###############################################################################
# Script Name : aquatic-script-name.sh
# Description : Brief description of what the script does.
#
# Author      : Varun Chawla
# Created On  : [Current Date]
# Last Updated: [Current Date]
# Version     : 1.0
# Usage       : aquatic command <arg1> [optional_arg]
# Requirements: [List dependencies like ffmpeg, gh, node, etc.]
###############################################################################
```

**JavaScript (Node.js or browser snippet):**
- Use `//` borders and `/** ... */` block comments.
- Keep the exact same textual field layout.

## Logging & Output Standards

Use clean, professional output with these prefixes:

```bash
echo "[OK] Operation successful."
echo "[INFO] Processing 15 files..."
echo "[ERROR] File not found."
echo "-----------------------------------"
```

Allowed levels for diagnostic logging:
- `[OK]`
- `[INFO]`
- `[DEBUG]`
- `[WARN]`
- `[ERROR]`

Logs should include useful context (operation, file/module, failure point) without redundant noise.

**No emojis** in any script output, log line, or comments.

## Error Handling & Validation

Always validate required inputs at the top, print usage, then `exit 1`:

```bash
if [ -z "$REQUIRED_ARG" ]; then
    echo "Usage: aquatic command <required_arg> [optional_arg]"
    exit 1
fi
```

Use parameter expansion for optional defaults:

```bash
FPS="${3:-30}"
```

Guard every `cd`:

```bash
cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }
```

For Bash/Zsh scripts, use strict mode immediately after shebang:

```bash
set -euo pipefail
```

## Technology Stack Rules

- **Shell:** Bash (POSIX-friendly where possible); `aquatic-commit-history.sh` uses zsh.
- **Video:** `ffmpeg`
    - Output patterns include `<base>_<fps>fps.mov`, `<base>_mute.mov`, `<base>_trimmed.mov`.
- **Git/GitHub:** `gh api` + `jq`
    - Tags follow `<version>_r<sha7>` (e.g., `1.70.0_rabc1234`).
- **Data:** Node.js (`#!/usr/bin/env node`) with built-in modules only (`fs`, `path`) unless explicitly approved.
- **macOS tools:** `sed`, `awk`, `pbcopy`, `md5`, `stat`.

## Project Rules

1. Understand every line you modify or add before implementing.
2. Prefer simple, reliable implementations you are certain you can complete.
3. Meet 100% of prompt requirements without deviating from architecture, formatting, logging, or error-handling rules.
4. Prioritize clean, maintainable code; do not cut corners.
5. Prefer minimal, review-friendly changes.
6. Write code for readability first.
7. Avoid unnecessary comments; if needed, keep comments concise and high-value.
8. Never use emojis in code, comments, or output.
9. Before finalizing, verify formatting consistency, logging quality, error handling, and architecture alignment.
10. Follow industry standards for naming, structure, and commit quality where they do not conflict with repo constraints.
11. Ensure existing functionality remains intact when introducing changes.
12. Write logs that are actionable for diagnosis and include relevant context. Allowed log levels are [OK], [INFO], [DEBUG], [WARN], [ERROR].
13. Handle edge cases deliberately; avoid happy-path-only implementations.
14. Snippet/dev output must go to clipboard via `pbcopy`; do not write generated snippet output to disk.
15. Dev snippets must be treated as dev-only functionality and remain gated behind `AQUATIC_DEV=1`.
