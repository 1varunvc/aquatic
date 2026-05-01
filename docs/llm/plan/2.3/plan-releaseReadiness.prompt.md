# Plan: Aquatic — Speedup Command, Snippet Rename, Docs Restructure, and Release Readiness

This plan covers seven areas: (1) adding a new `speedup` video command, (2) renaming snippet files to use a `dev` mode flag instead of separate naming, (3) code style consistency enforcement, (4) Homebrew packaging dependencies, (5) docs restructuring to professional standards, (6) security hardening for enterprise use, and (7) CodeGuard/Cisco considerations.

---

## 1. New Command: `aquatic-xlr8.sh`

Create `aquatic-xlr8.sh` modeled after `aquatic-trim.sh`:

- **Args:** `$1` = directory, `$2` = filename, `$3` = start time (HH:MM:SS), `$4` = end time (HH:MM:SS), `$5` = speed (default `20.0`), `$6` = FPS (default `30`)
- **Output naming:** `<base>_<speed>x_<fps>fps.mov` (fixes the original — uses both speed and FPS variables dynamically)
- **Logic:** `to_seconds()` helper, 3-part `filter_complex` (pre-speedup, speedup with drawtext overlay, post-speedup with revert text), concat, single ffmpeg call
- **Wire into** `aquatic`: add `speedup)` case entry (~line 35) and help text (~line 103)

## 2. Rename Snippets to Dev-Mode Commands

Instead of a separate `snippet` naming convention, introduce a `--dev` flag on the router. This keeps one namespace while gating personal-use commands:

- **Rename files:** `aquatic-snippet-platform-mm-*.js` → `aquatic-dev-mm-*.js` (e.g., `aquatic-dev-mm-expand-module.js`)
- **Router change:** Replace the `snippet)` case block in `aquatic` with individual commands (`dev-mm-expand-module)`, `dev-mm-extract-csv)`, etc.) that each check for a `--dev` guard or an environment variable `AQUATIC_DEV=1`
- **Alternative (simpler, recommended):** Keep the `snippet` subcommand but add a top-level guard: `if [ "$AQUATIC_DEV" != "1" ]; then echo "[ERROR] Dev-only command. Set AQUATIC_DEV=1 to enable."; exit 1; fi`. File names stay as-is. This is minimal-change and consistent.
- **Command name:** `aquatic dev <snippet-name> [args]` — rename the case from `snippet)` to `dev)`. Files become `aquatic-dev-<name>.js`.

## 3. Code Style & Naming Consistency

- Add a `.editorconfig` file enforcing: `indent_style = space`, `indent_size = 4` for `.sh`, `indent_size = 2` for `.js`, `end_of_line = lf`, `insert_final_newline = true`
- Add a `.github/workflows/shellcheck.yml` GitHub Actions workflow running `shellcheck` on all `.sh` files
- Document naming conventions in the README rather than only in agent docs

## 4. Homebrew Dependencies & Installation

For a Homebrew formula, declare these dependencies:

- **Required:** `bash` (>=4.0), `ffmpeg`, `gh` (GitHub CLI), `jq`, `node`
- **macOS built-ins (no formula needed):** `sed`, `awk`, `pbcopy`, `md5`, `stat`
- **Install step:** Symlink `aquatic` to `bin/`, copy all `aquatic-*` scripts alongside it
- Create a `Formula/aquatic.rb` or a tap repo `homebrew-aquatic`

## 5. Docs Restructuring (Professional Standard)

The `docs/agent/` directory is for **AI/LLM reference only** (FRAMEWORK, ARCHITECTURE, DEVELOPER_GUIDE). User-facing documentation and project rules live at the root or in `.github/`.

- **Keep in `docs/agent/` (AI reference):**
  - `docs/agent/ARCHITECTURE.md` — system topology, components, execution flow
  - `docs/agent/FRAMEWORK.md` — how to add anything, recipes, configuration
  - `docs/agent/DEVELOPER_GUIDE.md` — templates, naming rules, error handling
  - `docs/agent/INITIAL_PROMPTS.md` — meta-prompts for generating new docs
- **Keep at root (for humans):**
  - `CONTRIBUTING.md` — how to contribute (newbies friendly, practical)
  - `README.md` — installation, usage, command reference (for users)
  - `project_rules.md` — specification and AI coding rules (for LLMs)
- **Keep in `.github/`:**
  - `copilot-instructions.md` — AI-specific coding guidelines
  - `.github/prompts/INITIAL_PROMPTS.md` — moved from docs/agent/
- **New files at root:**
  - `LICENSE` (AGPL-3.0)
  - `SECURITY.md`
  - `CHANGELOG.md`

## 6. Security Hardening for Enterprise Use

Current gaps and required fixes:

1. **Input sanitization:** All `sed` placeholder injections in the snippet system pass user args directly — vulnerable to sed injection. Sanitize inputs by escaping `~`, `/`, `&`, and newlines before substitution.
2. **`eval`/injection risk:** No `eval` is used (good), but `"$@"` passing is safe. Verify no unquoted expansions exist.
3. **File permissions:** Add a `Makefile` or install script that sets `chmod 755` on executables only, `644` on docs.
4. **No secrets in code:** Audit for any hardcoded tokens, API keys, or org-specific values (e.g., `OWNER` in `commit-history.sh`). Parameterize them.
5. **Add `set -euo pipefail`** to all Bash scripts for strict error handling (currently missing from all scripts).
6. **Add a `LICENSE` file** (e.g., MIT) — required for open-source enterprise adoption.
7. **Add a `SECURITY.md`** with vulnerability reporting instructions (GitHub standard).
8. **Supply chain:** No npm dependencies (good). No build artifacts. Minimal attack surface.

## 7. Cisco CodeGuard / Static Analysis

- **CodeGuard** (Cisco's code scanning tool) performs SAST on repositories. It would flag: unquoted variables, missing `set -e`, potential injection in `sed` substitutions, and missing license.
- **Recommendation:** You don't strictly need CodeGuard to fix these — the issues are identifiable now. However, integrating it as a GitHub Action (if available) would provide continuous scanning.
- **Alternative:** Use `shellcheck` (free, open-source) for Bash linting and `semgrep` for JS snippet analysis. These cover the same ground for this project's scope.

---

## Implementation Steps (Ordered)

1. **Add `set -euo pipefail`** after the shebang in all `.sh` files and `aquatic`.
2. **Create** `aquatic-xlr8.sh` and wire it into the router + help text.
3. **Rename** `snippet)` to `dev)` in the router, rename snippet files from `aquatic-snippet-platform-*` to `aquatic-dev-*`, update all references.
4. **Sanitize** sed inputs in the `dev)` block with an escape function.
5. **Restructure docs:** flatten `docs/agent/` → `docs/ARCHITECTURE.md`, create root `CONTRIBUTING.md`, `LICENSE`, `SECURITY.md`, `CHANGELOG.md`, expand `README.md`.
6. **Add** `.editorconfig` and `.github/workflows/shellcheck.yml`.

---

## Resolved Decisions

1. **Dev-mode approach:** Files renamed to `aquatic-dev-*.js`, router uses `dev)` case gated by `AQUATIC_DEV=1` env var. Usage: `AQUATIC_DEV=1 aquatic dev mm-expand-module`.
2. **Homebrew distribution:** Standalone formula tap (`homebrew-aquatic`). Not yet created.
3. **License:** AGPL-3.0 — requires attribution, source disclosure, prevents proprietary use without sharing back.

---

## Documentation Structure (Corrected)

**Insight:** Documentation was split wrongly. Different audiences need different styles:

- **Users read:** `README.md`, `SECURITY.md`, `CHANGELOG.md` (prose, quick answers)
- **Contributors read:** `CONTRIBUTING.md` (step-by-step, no jargon)
- **LLMs read:** `docs/agent/*.md`, `project_rules.md`, `.github/copilot-instructions.md` (dense tables, pointers, templates)

**File Locations (Final):**

| What | Where | Who |
|------|-------|-----|
| Installation + commands | `README.md` | Users |
| Contribution workflow | `CONTRIBUTING.md` | Contributors |
| Security policy | `SECURITY.md` | Users/Maintainers |
| What's new | `CHANGELOG.md` | Users |
| System design | `docs/agent/ARCHITECTURE.md` | LLMs |
| How to add features | `docs/agent/FRAMEWORK.md` | LLMs |
| Templates + standards | `docs/agent/DEVELOPER_GUIDE.md` | LLMs |
| Project spec | `project_rules.md` | LLMs |
| AI coding rules | `.github/copilot-instructions.md` | LLMs |
| Docs philosophy | `DOCS_PHILOSOPHY.md` | Maintainers |
| Legal | `LICENSE` | Everyone |

**Key principle:** Never merge human-readable and machine-readable docs. Keep them separate. See `DOCS_PHILOSOPHY.md` for rationale.

