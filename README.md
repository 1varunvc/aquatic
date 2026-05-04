# aquatic

A modular, extensible macOS CLI toolkit for automating everyday tasks.

Aquatic uses a simple router pattern: one entry point delegates to self-contained sub-scripts. It ships with commands for video processing, Git tagging, and commit visualization — but the real idea is that anyone can drop in a new script for whatever repetitive task they need to automate.

## Requirements

- macOS
- Bash (or Zsh for `commit-history`)
- [ffmpeg](https://ffmpeg.org/) — video commands
- [gh](https://cli.github.com/) (GitHub CLI) + `jq` — Git commands

## Installation

```bash
# Clone the repo
git clone https://github.com/varun-chawla/aquatic-cli.git
cd aquatic-cli

# Make the router executable and add it to your PATH
chmod +x aquatic
export PATH="$PWD:$PATH"
```

## Usage

```bash
aquatic <command> [options]
```

Every command supports `--help` for inline documentation.

## Commands

### Video

| Command | Description |
|---------|-------------|
| `aquatic mute <file> [--fps <n>]` | Strip audio from a video |
| `aquatic compress <file> [--fps <n>]` | Re-encode a video at a target frame rate |
| `aquatic trim <file> --start <t> --end <t> [--fps <n>]` | Cut out a section and concat the rest |
| `aquatic xlr8 <file> --start <t> --end <t> [--speed <n>] [--fps <n>]` | Speed up a section with overlay text |
| `aquatic slideshow [dir] [--no-timestamps] [--output <name>]` | Build a 1-FPS screenshot slideshow |

### Git

| Command | Description |
|---------|-------------|
| `aquatic tag <owner> <repo> <version> [--branch <b>]` | Create a GitHub tag with short SHA suffix |
| `aquatic commit-history [--tags <n>] [--commits <n>] [--branch <b>]` | Visualize recent commits by tag |

## Adding a New Command

1. Create `scripts/aquatic-<command>.sh` (or `.js` for Node scripts) inside the `scripts/` directory.
2. Add a matching `case` entry in the `aquatic` router, pointing to the new script path.
3. Follow the standard file header and error-handling conventions (see `docs/CONTRIBUTING.md`).

> All sub-scripts live under the `scripts/` directory. The `aquatic` router in the project root dispatches to them.

## Project Structure

```
aquatic          — CLI router (entry point)
scripts/          — Sub-scripts (Bash and Node.js)
  dev/           — Dev-only browser-paste snippets
docs/            — Documentation
VERSION          — Current version
RELEASES.md      — One-line-per-version changelog
```

## License

Private — all rights reserved.
