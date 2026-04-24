# Changelog

All notable changes to this project will be documented in this file.

## [3.0] - 2026-04-24

### Added
- `flash` command: speed up a section of video with drawtext overlay.
- `dev` command: replaces `snippet`, gated behind `AQUATIC_DEV=1`.
- `set -euo pipefail` to all Bash scripts for strict error handling.
- Input sanitization for `sed` placeholder injection in dev snippets.
- `LICENSE` (AGPL-3.0), `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md`.
- `.editorconfig` for consistent formatting.
- `.github/workflows/shellcheck.yml` for CI linting.

### Changed
- Renamed `aquatic-snippet-platform-*` files to `aquatic-dev-*`.
- Router `snippet)` case renamed to `dev)`.
- Docs restructured: `docs/agent/` flattened to `docs/` and root-level standard files.

### Removed
- `project_rules.md` (merged into `CONTRIBUTING.md` and `.github/copilot-instructions.md`).

## [2.2] - 2026-03-25

### Added
- Initial public commands: slideshow, compress, mute, trim, tag, commit-history, net-surcharges, snippet.

