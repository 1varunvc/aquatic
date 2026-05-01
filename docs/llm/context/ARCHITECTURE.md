## ARCHITECTURE.md

```markdown
# ARCHITECTURE.md — Aquatic

## PROJECT IDENTITY

| Field | Value |
|---|---|
| Name | aquatic |
| Type | CLI toolkit (script collection) |
| Language | Bash, zsh, JavaScript (Node.js), JavaScript (dev browser snippets) |
| Framework | None |
| Build Tool | None (no package.json, no Makefile) |
| Dependencies | ffmpeg, gh (GitHub CLI), jq, node, pbcopy (macOS), md5 (macOS), stat (macOS) |
| Shell | Bash (POSIX-friendly where possible); `aquatic-commit-history.sh` uses zsh |

## DEPENDENCY TABLE

| Dependency | Used By | Purpose |
|---|---|---|
| ffmpeg | slideshow, compress, mute, trim, xlr8 | Video processing (FPS, mute, trim, concat, speed-up overlays) |
| gh (GitHub CLI) | tag, commit-history | GitHub API calls (tags, commits, branches) |
| jq | commit-history | JSON parsing of GitHub API responses |
| node | net-surcharges | Run Node.js data-processing scripts |
| pbcopy | dev (router) | Copy dev snippets to the macOS clipboard |
| sed | dev (router), slideshow | Placeholder injection, sanitization escaping, text escaping |
| md5 | slideshow | Generate safe filenames from image names |
| stat | slideshow | Extract file timestamps (macOS `-f` flag) |
| fs, path | aquatic-platform-mm-net-surcharges.js | Node.js built-in modules for file/CSV parsing |

## FILE MAP

```
aquatic/
├── aquatic                                        # Router (entry point)
├── aquatic-slideshow.sh                           # Bash video command
├── aquatic-compress.sh                            # Bash video command
├── aquatic-mute.sh                                # Bash video command
├── aquatic-trim.sh                                # Bash video command
├── aquatic-xlr8.sh                               # Bash video command
├── aquatic-platform-mm-tag.sh                     # Bash Git/GitHub command
├── aquatic-commit-history.sh                      # Zsh Git/GitHub command
├── aquatic-platform-mm-net-surcharges.js          # Node.js data command
├── aquatic-dev-mm-expand-module.js                # Dev snippet
├── aquatic-dev-mm-extract-csv.js                  # Dev snippet
├── aquatic-dev-mm-extract-module.js               # Dev snippet
├── captions.example.txt                           # Sample captions data
├── README.md                                      # User-facing overview and command table
├── docs/
│   ├── CHANGELOG.md                               # Release history
│   ├── CONTRIBUTING.md                            # Human contribution guide
│   ├── DOCS_PHILOSOPHY.md                         # Documentation audience split
│   ├── SECURITY.md                                # Security policy
│   └── llm/
│       ├── context/
│       │   ├── ARCHITECTURE.md                    # Structural reference for LLMs
│       │   ├── DEVELOPER_GUIDE.md                 # Templates and coding patterns
│       │   └── FRAMEWORK.md                       # Runtime and recipe reference
│       ├── prompts/
│       │   └── INITIAL_PROMPTS.md                 # Prompt guidance
│       └── agent/
│           └── KNOWLEDGE_ACCUMULATOR.md           # Session knowledge capture guidance
└── .github/
	└── copilot-instructions.md                   # Project instructions for AI code generation
```

## ROLE CLASSIFICATION TABLE

| File(s) | Role |
|---|---|
| `aquatic` | ENTRY_POINT |
| `aquatic-compress.sh`, `aquatic-mute.sh`, `aquatic-trim.sh` | COMMAND:VIDEO |
| `aquatic-xlr8.sh`, `aquatic-slideshow.sh` | COMMAND:VIDEO (complex) |
| `aquatic-platform-mm-tag.sh` | COMMAND:GIT |
| `aquatic-commit-history.sh` | COMMAND:GIT (complex, zsh) |
| `aquatic-platform-mm-net-surcharges.js` | COMMAND:DATA |
| `aquatic-dev-mm-expand-module.js` | DEV_SNIPPET |
| `aquatic-dev-mm-extract-csv.js` | DEV_SNIPPET (complex) |
| `aquatic-dev-mm-extract-module.js` | DEV_SNIPPET |
| `captions.example.txt` | RESOURCE |
| `docs/llm/context/*.md`, `.github/copilot-instructions.md` | DOCS:LLM |
| `README.md`, `docs/CHANGELOG.md`, `docs/CONTRIBUTING.md`, `docs/DOCS_PHILOSOPHY.md`, `docs/SECURITY.md` | DOCS:HUMAN |

## PATTERN TABLE

| Role | Pattern | File:Line | Rule |
|---|---|---|---|
| ENTRY_POINT | Case-statement router; `$1` = command, `shift`, dispatch to sub-script or `dev)` branch | `aquatic:21-122` | Every top-level command is a `case` entry; dev snippets are routed through the single `dev)` branch |
| COMMAND:VIDEO | Validate args → `cd` with guard → `ffmpeg` pipeline → log/save output | `aquatic-mute.sh:16-29` | Args are positional; optional values use `${N:-default}`; output names follow the video naming rules |
| COMMAND:VIDEO (complex) | Multi-stage `ffmpeg` filter graph with validation and contextual logging | `aquatic-xlr8.sh:17-86` | Use for advanced video transforms such as speed changes and overlays |
| COMMAND:GIT | Validate args → `gh api` call → format/output | `aquatic-platform-mm-tag.sh:20-35` | Uses `gh api` + `jq`; no interactive prompts |
| COMMAND:DATA | `#!/usr/bin/env node`; built-in `fs`/`path` only; validate dir → process → `console.table` | `aquatic-platform-mm-net-surcharges.js:17-169` | No npm dependencies |
| DEV_SNIPPET | Header → JS code with `___PLACEHOLDER___` tokens; no `#!/` shebang | `aquatic-dev-mm-expand-module.js:1-11` | Placeholders = `___UPPER_SNAKE_CASE___`; router injects via sanitized `sed`, then pipes to `pbcopy` |

## CROSS-CUTTING CONCERNS TABLE

| Concern | Mechanism | Key File(s) |
|---|---|---|
| Routing/dispatch | Bash `case` statement; `$1` = command, `shift` passes remaining args | `aquatic:21-122` |
| Strict shell mode | `set -euo pipefail` at the top of Bash/Zsh scripts | `aquatic:1-2`, `aquatic-xlr8.sh:1-2` |
| File header | Mandatory block: Script Name, Description, Author, dates, Version, Usage, Requirements | See `.github/copilot-instructions.md` |
| Arg validation | `if [ -z "$VAR" ]; then echo "Usage: ..."; exit 1; fi` at the top of scripts | `aquatic-xlr8.sh:24-27`, `aquatic-mute.sh:20-23` |
| Optional arg defaults | Bash parameter expansion `${N:-default}` | `aquatic-xlr8.sh:18-22`, `aquatic-mute.sh:16-18` |
| Directory guard | `cd "$DIR" || { echo "[ERROR] ..."; exit 1; }` | `aquatic-xlr8.sh:30`, `aquatic-mute.sh:26` |
| Dev gate | `if [ "${AQUATIC_DEV:-0}" != "1" ]; then ...` before dev snippet execution | `aquatic:46-50` |
| Placeholder sanitization | `sanitize_sed()` escapes user-provided replacement values before `sed` injection | `aquatic:61-63` |
| Clipboard output | Generated dev snippet output is always piped to `pbcopy` | `aquatic:67-103` |
| Logging format | `[OK]`, `[INFO]`, `[DEBUG]`, `[WARN]`, `[ERROR]`; no emojis | See `.github/copilot-instructions.md` |
| Output naming (video) | `<base>_<suffix>.mov` (`_mute`, `_trimmed`, `_<fps>fps`, `_<speed>x_<fps>fps`, `_01fps`) | `aquatic-mute.sh:28-29`, `aquatic-xlr8.sh:37-38` |

## PRIORITIZED FILE LIST

### ENTRY_POINT
- **MUST-READ:** `aquatic` — defines routing, strict mode, dev gating, placeholder injection, and help text
- **SKIP:** None (single file)

### COMMAND (Bash — simple)
- **MUST-READ:** `aquatic-mute.sh` — canonical small Bash command (header, args, `cd`, `ffmpeg`)
- **NICE-TO-READ:** `aquatic-trim.sh` — shows multi-step ffmpeg pipeline with cleanup
- **SKIP:** `aquatic-compress.sh` — similar to mute with FPS-focused output naming

### COMMAND (Bash — complex)
- **MUST-READ:** `aquatic-xlr8.sh` — advanced ffmpeg filter graph, validation, and contextual logging
- **NICE-TO-READ:** `aquatic-slideshow.sh` — most complex Bash script (config section, caption loading, loop, ffmpeg filter chains)

### COMMAND (Git)
- **MUST-READ:** `aquatic-platform-mm-tag.sh` — canonical `gh api` usage, tag format `<ver>_r<sha7>`
- **NICE-TO-READ:** `aquatic-commit-history.sh` — zsh arrays, GraphQL via `gh api`, column formatting

### COMMAND (Node.js)
- **MUST-READ:** `aquatic-platform-mm-net-surcharges.js` — canonical Node.js command (built-in modules only, CSV parsing, `console.table`)

### DEV SNIPPET
- **MUST-READ:** `aquatic-dev-mm-expand-module.js` — simplest dev snippet (single placeholder)
- **NICE-TO-READ:** `aquatic-dev-mm-extract-csv.js` — complex async dev snippet with multiple placeholders
- **SKIP:** `aquatic-dev-mm-extract-module.js` — follows the same router pattern as the other dev snippets
```
