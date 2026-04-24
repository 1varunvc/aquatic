## ARCHITECTURE.md

```markdown
# ARCHITECTURE.md — Aquatic CLI

## PROJECT IDENTITY

| Field | Value |
|---|---|
| Name | aquatic-cli |
| Type | CLI toolkit (script collection) |
| Language | Bash, JavaScript (Node.js), JavaScript (browser snippets) |
| Framework | None |
| Build Tool | None (no package.json, no Makefile) |
| Dependencies | ffmpeg, gh (GitHub CLI), jq, node, pbcopy (macOS), md5 (macOS) |
| Shell | Bash (POSIX-friendly); `aquatic-commit-history.sh` uses zsh |

## DEPENDENCY TABLE

| Dependency | Used By | Purpose |
|---|---|---|
| ffmpeg | slideshow, compress, mute, trim | Video processing (FPS, mute, trim, concat) |
| gh (GitHub CLI) | tag, commit-history | GitHub API calls (tags, commits, branches) |
| jq | commit-history | JSON parsing of GitHub API responses |
| node | net-surcharges | Run Node.js data-processing scripts |
| pbcopy | snippet (router) | Copy browser snippets to macOS clipboard |
| sed | snippet (router), slideshow | Placeholder injection, text escaping |
| md5 | slideshow | Generate safe filenames from image names |
| stat | slideshow | Extract file timestamps (macOS `-f` flag) |
| fs, path | net-surcharges.js | Node.js built-in modules for file/CSV parsing |

## FILE MAP

```
aquatic-cli/
├── aquatic                                        # Router (entry point)
├── aquatic-slideshow.sh                           # Bash command
├── aquatic-compress.sh                            # Bash command
├── aquatic-mute.sh                                # Bash command
├── aquatic-trim.sh                                # Bash command
├── aquatic-platform-mm-tag.sh                     # Bash command
├── aquatic-commit-history.sh                      # Zsh command
├── aquatic-platform-mm-net-surcharges.js          # Node.js command
├── aquatic-snippet-platform-mm-expand-module.js   # Browser snippet
├── aquatic-snippet-platform-mm-extract-csv.js     # Browser snippet
├── aquatic-snippet-platform-mm-extract-module.js  # Browser snippet
├── captions.example.txt                           # Sample data
├── project_rules.md                               # Project spec
├── README.md                                      # (stub)
├── docs/
│   └── agent/
│       └── INITIAL_PROMPTS.md                     # Meta-prompts
└── .github/
└── copilot-instructions.md                    # AI coding instructions
```

## ROLE CLASSIFICATION TABLE

| File(s) | Role |
|---|---|
| `aquatic` | ENTRY_POINT |
| `aquatic-compress.sh`, `aquatic-mute.sh`, `aquatic-trim.sh` | COMMAND:VIDEO |
| `aquatic-slideshow.sh` | COMMAND:VIDEO (complex) |
| `aquatic-platform-mm-tag.sh` | COMMAND:GIT |
| `aquatic-commit-history.sh` | COMMAND:GIT (complex, zsh) |
| `aquatic-platform-mm-net-surcharges.js` | COMMAND:DATA |
| `aquatic-snippet-platform-mm-expand-module.js` | SNIPPET |
| `aquatic-snippet-platform-mm-extract-csv.js` | SNIPPET (complex) |
| `aquatic-snippet-platform-mm-extract-module.js` | SNIPPET |
| `captions.example.txt` | RESOURCE |
| `project_rules.md`, `.github/copilot-instructions.md` | DOCS |
| `README.md` | DOCS |

## PATTERN TABLE

| Role | Pattern | File:Line | Rule |
|---|---|---|---|
| ENTRY_POINT | Case-statement router; `$1` = command, `shift`, dispatch to sub-script | `aquatic:20-110` | Every command is a `case` entry calling `"$DIR/aquatic-<name>.<ext>" "$@"` |
| COMMAND:VIDEO | Validate args → `cd` with guard → `ffmpeg` pipeline → echo "Done" | `aquatic-mute.sh:19-28` | Args positional; optional with `${N:-default}`; output = `<base>_<suffix>.mov` |
| COMMAND:GIT | Validate args → `gh api` call → format/output | `aquatic-platform-mm-tag.sh:20-35` | Uses `gh api` + `jq`; no interactive prompts |
| COMMAND:DATA | `#!/usr/bin/env node`; built-in `fs`/`path` only; validate dir → process → `console.table` | `aquatic-platform-mm-net-surcharges.js:17-169` | No npm dependencies |
| SNIPPET | Header → JS code with `___PLACEHOLDER___` tokens; no `#!/` shebang | `aquatic-snippet-platform-mm-expand-module.js:1-12` | Placeholders = `___UPPER_SNAKE_CASE___`; router injects via `sed`, pipes to `pbcopy` |

## CROSS-CUTTING CONCERNS TABLE

| Concern | Mechanism | Key File(s) |
|---|---|---|
| Routing/dispatch | Bash `case` statement; `$1` = command, `shift` passes remaining args | `aquatic:15-110` |
| File header | Mandatory block: Script Name, Description, Author, dates, Version, Usage, Requirements | All files (see `aquatic-mute.sh:3-13` for Bash, `aquatic-platform-mm-net-surcharges.js:3-15` for JS) |
| Arg validation | `if [ -z "$VAR" ]; then echo "Usage: ..."; exit 1; fi` at top of every script | `aquatic-mute.sh:19-23`, `aquatic-trim.sh:22-26` |
| Optional arg defaults | Bash parameter expansion `${N:-default}` | `aquatic-mute.sh:17`, `aquatic-trim.sh:20` |
| Directory guard | `cd "$DIR" \|\| { echo "[ERROR] ..."; exit 1; }` | `aquatic-mute.sh:25`, `aquatic-slideshow.sh:45` |
| Logging format | `[OK]`, `[INFO]`, `[ERROR]` prefixes; `---` separators; no emojis | All scripts |
| Snippet injection | `sed "s~___PLACEHOLDER___~$VALUE~g"` piped to `pbcopy` | `aquatic:52-91` |
| Output naming (video) | `<base>_<suffix>.mov` (`_mute`, `_trimmed`, `_<fps>fps`, `_01fps`) | `aquatic-mute.sh:27`, `aquatic-trim.sh:31` |

## PRIORITIZED FILE LIST

### ENTRY_POINT
- **MUST-READ:** `aquatic` — defines routing pattern, snippet injection, all available commands
- **SKIP:** None (single file)

### COMMAND (Bash — simple)
- **MUST-READ:** `aquatic-mute.sh` — canonical simple command (29 lines: header, validate, cd, ffmpeg, done)
- **NICE-TO-READ:** `aquatic-trim.sh` — shows multi-step ffmpeg pipeline with cleanup
- **SKIP:** `aquatic-compress.sh` — identical pattern to mute

### COMMAND (Bash — complex)
- **MUST-READ:** `aquatic-slideshow.sh` — most complex Bash script (config section, caption loading, loop, ffmpeg filter chains)
- **NICE-TO-READ:** `aquatic-commit-history.sh` — zsh, GraphQL via `gh api`, column formatting

### COMMAND (Git)
- **MUST-READ:** `aquatic-platform-mm-tag.sh` — canonical `gh api` usage, tag format `<ver>_r<sha7>`

### COMMAND (Node.js)
- **MUST-READ:** `aquatic-platform-mm-net-surcharges.js` — canonical Node.js command (built-in modules only, CSV parsing, `console.table`)

### SNIPPET
- **MUST-READ:** `aquatic-snippet-platform-mm-expand-module.js` — simplest snippet (1 line of JS + placeholders)
- **NICE-TO-READ:** `aquatic-snippet-platform-mm-extract-csv.js` — complex async snippet with multiple placeholders
- **SKIP:** `aquatic-snippet-platform-mm-extract-module.js` — follows same pattern
``