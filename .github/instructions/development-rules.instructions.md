### Rules for Modifying or Adding Code in This Repository

1. Plan first, then implement. Understand every line before writing it.
2. Simple > clever. No abstract classes, no over-engineering, no showing off. Use parameters instead of overrides. Use concrete classes with shared helpers instead of abstract hooks.
3. Meet 100% of requirements. Don't deviate from architecture, formatting, logging, or error-handling patterns.
4. Minimal, review-friendly changes. Preserve existing functionality.
5. No redundant code. Reuse via inheritance, composition, and parameterized helpers — but keep it simple. If the "reuse" adds more complexity than duplication, just duplicate.
6. No unnecessary comments or emojis. Comments must earn their place.
7. Split test classes for parallel execution when 3+ independent flow types share the same scenario set and each takes >5s. Don't split for 1-2 types or sub-second tests.
8. When shared test logic exists, put it in a concrete common class with parameterized `run*()` methods. Subclasses pass their specific params — no abstract methods, no overrides. If a flow is fundamentally different (e.g., payment plan vs. payment session), it writes its own test methods using shared helpers.
9. Capture session knowledge in `TECHNICAL_NOTES.md` per `knowledge-accumulator.instructions.md`.
10. Append proven Tier 3 commands to **Verified Commands** below.
11. Changelog entries must start with a **"What's New"** section written for end users (plain language, what they'll notice), followed by a **"Technical Details"** section for developers (implementation specifics, file changes, internal mechanisms).
12. `RELEASES.md` entries are one-liners per version (`<version>|<user-facing summary>`). Write them as if telling a user what changed in one sentence. These are displayed on every CLI run when updates are available.
13. Version metadata lives only in `VERSION` (single source of truth) and the router header. Individual sub-scripts must not contain `# Version` lines.
14. At the end, appropriately update `README.md` with new user-facing commands, flags, and usage examples.
15. At the end, appropriately update `docs/RELEASE_NOTES.md` for changes made in the release, following the required format.

---

### Git Identity

16. All commits to `1varunvc/*` repositories must use `1varunvc@gmail.com` as the author email. Set repo-local config in every cloned repo: `git config user.email "1varunvc@gmail.com"`. Never rely on global config. Never commit with any other email address.

---

### Branching Policy

17. Never push directly to `main`. All changes go through a branch:
    - `feature/<name>` — new functionality
    - `maintenance/<name>` — refactors, docs, dependency updates
    - `bug/<name>` — fixes
    - `release/<version>` — release preparation snapshots
18. Commit and push to the branch. Do not create pull requests automatically — the repository owner handles PRs and merges manually.
19. Never delete `release/*` branches. They serve as historical snapshots of each release and must be preserved indefinitely on both local and remote.

---

### Rules for Commit Messages

20. **Never commit directly unless the user explicitly asks you to commit and push.** By default, only generate the commit message and description for the user to review and commit themselves. When the user explicitly says "commit and push" (or equivalent), proceed with `git add`, `git commit`, and `git push` directly.
21. When the user asks for a commit message on uncommitted/untracked changes, inspect the diff (`git diff`, `git diff --cached`, `git status`) to understand all changes.
22. Format:
    - **Subject line:** `<type>: <imperative summary>` max ~72 chars
    - **Type** (conventional commit): `fix`, `feat`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`
    - Example: `fix: null-safe status checks in surcharging polling`
    - **Body:** structured sections — **Issues**, **Changes**, **Impact** — each with concise bullet points explaining what was wrong, what was changed, and what would have happened without the fix.
23. Keep it human-reviewable: a developer unfamiliar with the PR should understand the *why* from the commit message alone.
24. Reference file names and method names where helpful for traceability.
25. Always append the `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer at the end of commit messages when the change was AI-assisted.

---

### Release Strategy

Aquatic follows a **release-when-ready** model. No version is ever published unless it is fully verified. There are no "fix-up" patch releases for broken tags — broken tags are yanked and re-done.

26. Always `git pull origin main` (or the target branch) before starting any release, merge, or tag operation. Never operate on stale local state.
27. A tagged release must be fully tested and verified working before it is published. Never tag a broken state.
28. Release workflow:
    - Develop on a branch. Test locally and in CI.
    - When ready: the owner merges to `main`, tags `vX.Y.Z` on `main`, and creates the GitHub Release.
    - The `update-tap.yml` Action auto-updates the Homebrew formula.
29. If a released version is found to be broken:
    - **Not yet distributed** (no users have upgraded): delete the release and tag, fix on a branch, re-release with the same version.
    - **Already distributed**: fix on a `bug/` branch, bump patch (e.g., `0.1.0` -> `0.1.1`), release the fix.
30. Never publish a release without running every command locally: `aquatic --version`, `aquatic mute`, `aquatic compress`, `aquatic trim`, `aquatic slideshow`, `aquatic tag`, `aquatic commit-history`, and `AQUATIC_DEV=1 aquatic dev mm-expand-module`.
31. Version numbers only increment when a release is actually published. Do not bump `VERSION` on a branch — bump it only on `main` immediately before tagging.

---

### Logging and Error Handling in Scripts

32. External tool output (e.g., `ffmpeg`) must never be shown to the user by default. Capture stderr; on failure, log a concise `[ERROR]` message with the relevant stderr excerpt. Only show full external output when `DEBUG_MODE` is enabled.
33. Every significant operation in a script must emit a `[DEBUG]` log (gated behind `DEBUG_MODE`) showing what is about to happen (input, parameters, output path). This makes failures instantly diagnosable.
34. Use `while IFS= read -r` loops instead of `IFS=... VAR=($(cmd))` to split command output into arrays. This avoids word-splitting bugs and satisfies ShellCheck. Do not use `mapfile`/`readarray` — macOS ships bash 3.2 which does not support them.
35. Internal shared libraries live in `scripts/lib/` and are sourced (not executed) by sub-scripts. They must not be invoked directly. File naming: `aquatic-<purpose>.sh`. They follow the same header convention but have no shebang usage line — the `# Usage` field documents how to source them.

---

### Automation and Tooling

36. Never use commands that require interactive user input (editors, prompts, confirmations) in automated workflows or agent-driven operations. Always pass non-interactive flags (e.g., `-m` for commit messages, `--no-edit`, `--yes`, `--delete-branch`). If a command would open a pager or editor, pipe through `cat` or disable with flags like `--no-pager`.
37. When a release needs to be yanked and re-done (per rule 29), the agent must first confirm with the user whether to (a) yank the latest tag and override it, or (b) create a new patch version. After confirmation, the agent handles the full workflow autonomously: delete release + tag, create bug branch, fix, commit, push, create PR, merge PR, delete branch, re-tag, and re-release. No further user input required after the initial decision.
38. After creating a GitHub Release, always compute the tarball SHA256 (`curl -sL <tarball-url> | shasum -a 256`) and update the Homebrew formula in `homebrew-aquatic/Formula/aquatic.rb` with the real hash. Never leave `PLACEHOLDER_SHA256` or any placeholder in a committed formula. Push the formula update immediately so `brew upgrade` works.
