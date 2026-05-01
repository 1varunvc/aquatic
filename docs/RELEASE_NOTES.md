# Release Notes

All notable changes to this project are documented in this file.

---

## [0.1.0] - 2026-05-01

### What's New

- You can now use flags like `--fps`, `--start`, `--end`, `--speed` instead of remembering argument positions.
- Every command supports `--help` to see available options.
- Run `aquatic --version` to check your installed version.
- When newer versions are available, you'll see a summary on each run.
- Slideshow supports `--no-timestamps` to hide date overlays and `--output` for custom filenames.

### Technical Details

- Migrated all sub-scripts from positional-only args to flag-based parsing (`while/case` loop).
- Removed per-script `# Version` headers; version is now single-sourced from `VERSION` file.
- Added `RELEASES.md` as the local update log (one-liner per version, displayed on every run).
- Added `VERSION` file (semver, single source of truth).
- Added `LICENSE` (MIT) for Homebrew compliance.
- Router reads `RELEASES.md` and prints all entries newer than the installed version.

---

## [Pre-release] - 2026-04-24

### What's New

- Added `flash` command for speeding up video sections with an overlay indicator.
- Dev snippets now require `AQUATIC_DEV=1` (safer default).
- Strict error handling across all scripts prevents silent failures.

### Technical Details

- `flash` command: multi-stage ffmpeg filter graph with speed overlay and concat.
- `dev` command replaces `snippet`; gated behind `AQUATIC_DEV=1`.
- `set -euo pipefail` added to all Bash scripts.
- Input sanitization for `sed` placeholder injection in dev snippets.
- Added `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`.
- `.github/workflows/shellcheck.yml` for CI linting.
- Renamed `aquatic-snippet-platform-*` to `aquatic-dev-*`.

---

## [0.0.1-pre] - 2026-03-25

### What's New

- Initial release with commands for video processing (slideshow, compress, mute, trim), Git tagging, commit history visualization, surcharge parsing, and browser dev snippets.

### Technical Details

- Initial public commands: slideshow, compress, mute, trim, tag, commit-history, net-surcharges, snippet.
