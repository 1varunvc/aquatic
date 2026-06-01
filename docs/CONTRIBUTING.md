# Contributing to Aquatic

Thank you for your interest in contributing! This guide will help you get started.

## Quick Start

1. **Fork & clone** the repository:
   ```bash
   git clone https://github.com/your-username/aquatic.git
   cd aquatic
   ```

2. **Install dependencies** (macOS):
   ```bash
   brew install bash ffmpeg gh jq node
   ```

3. **Run a command** to verify setup:
   ```bash
   chmod +x aquatic
   ./aquatic
   ```

4. **Make your changes** and test locally before submitting a pull request.

## What Kind of Contributions Are Welcome?

- **Bug fixes** — Found a crash or unexpected behavior? We want to know.
- **New video/data commands** — Have a useful workflow? Consider adding a command.
- **Documentation improvements** — Spotted typos, unclear examples, or missing docs? Fix them.
- **Performance improvements** — Optimizations that don't sacrifice readability.
- **Security fixes** — Found a vulnerability? See [SECURITY.md](SECURITY.md).

## What We *Don't* Accept

- Large external dependencies (npm packages, Python libraries, etc.)
- Commands that require software we can't assume macOS has
- Personal snippets that aren't generalizable
- Breaking changes to existing commands

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/my-cool-feature
# or
git checkout -b fix/issue-name
```

### 2. Make Your Changes

- **For a new command:** Start by copying the pattern from `aquatic-mute.sh` or `aquatic-trim.sh`.
- **For fixes:** Follow the existing code style (see [Code Style](#code-style) below).
- **Test locally:** Run your command and verify it works.

### 3. Test Your Changes

Run your script with various inputs:

```bash
chmod +x aquatic-my-command.sh
./aquatic my-command /test/dir file.mov

# Test error cases (missing args, bad paths):
./aquatic my-command
./aquatic my-command /nonexistent
```

### 4. Update Documentation

If you added a command:
- Add a brief description to the help text in the `aquatic` router (~line 120)
- Add an entry to the commands table in `README.md`

### 5. Commit & Push

```bash
git add .
git commit -m "feat: add xlr8 command for video speedup"
git push origin feature/my-cool-feature
```

### 6. Open a Pull Request

Describe what your change does and why. Link any related issues. We'll review and merge!

## Code Style

### Bash Scripts

- **Start every script** with the header block (see `aquatic-mute.sh` for the template).
- **Always use `set -euo pipefail`** after the shebang.
- **Validate inputs** at the top before doing any work.
- **Use `"${VAR:-default}"` syntax** for optional args with defaults.
- **Guard all `cd` commands** with error handling: `cd "$DIR" || { echo "[ERROR] ..."; exit 1; }`
- **No emojis** — keep output clean and professional.

Example:
```bash
#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-compress.sh
# Description : Compresses a video to a specific FPS.
# ...
###############################################################################

TARGET_DIR="${1:-}"
FILENAME="${2:-}"
FPS="${3:-30}"

if [ -z "$FILENAME" ]; then
    echo "Usage: aquatic compress <dir> <filename> [fps]"
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Directory not found."; exit 1; }

# Do work...
```

### Node.js Scripts

- Use the same header format as Bash (adapted for `//` comments).
- No external npm dependencies — use only `fs` and `path`.
- Validate file existence before processing.

### Logging

All output should use these prefixes:
- `[OK]` — success
- `[INFO]` — progress/info
- `[ERROR]` — failure
- `---` — visual separator

Example:
```bash
echo "[INFO] Processing 15 files..."
echo "[ERROR] File not found."
echo "[OK] Done. Saved as output.mov"
```

## Common Pitfalls

1. **Forgetting `set -euo pipefail`** — Your script will silently ignore errors.
2. **Not validating directory existence** — `cd` will fail silently without the guard.
3. **Using unquoted variables** — `$VAR` without quotes can cause word splitting and glob expansion.
4. **Hardcoding paths** — Use positional args (`$1`, `$2`) instead of `/Users/username/...`.
5. **Emojis in output** — Breaks machines parsing the output and looks unprofessional.

## Questions?

- **How do I add a new command?** See [developer-guide.instructions.md](../.github/instructions/developer-guide.instructions.md) (for LLMs) or copy an existing command.
- **Where's the architecture?** See [architecture.instructions.md](../.github/instructions/architecture.instructions.md).
- **How do dev snippets work?** Run `AQUATIC_DEV=1 aquatic dev` and see available snippets.

## Testing Before You Submit

Before opening a PR, run:

```bash
# Syntax check all Bash scripts
bash -n aquatic aquatic-*.sh

# Test your new command with missing args
./aquatic my-command

# Test with invalid paths
./aquatic my-command /nonexistent file.mov
```

## Code of Conduct

Be respectful, inclusive, and constructive. We're here to help each other build something useful.

---

**Thank you for contributing!**

