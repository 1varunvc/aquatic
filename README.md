# aquatic-cli

A macOS CLI toolkit for video processing, Git tagging, data parsing, and browser automation.

## Installation

### Prerequisites

Install the following via [Homebrew](https://brew.sh/):

```bash
brew install bash ffmpeg gh jq node
```

macOS built-ins used (no install needed): `sed`, `awk`, `pbcopy`, `md5`, `stat`.

### Setup

```bash
git clone https://github.com/varun-chawla/aquatic-cli.git
cd aquatic-cli
chmod +x aquatic aquatic-*.sh
```

Add to your PATH:

```bash
export PATH="/path/to/aquatic-cli:$PATH"
```

## Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `slideshow` | `[dir]` | Build a 1-FPS screenshot slideshow with captions |
| `compress` | `<dir> <file> [fps]` | Convert video to specific FPS (default 30) |
| `mute` | `<dir> <file> [fps]` | Strip audio from video (default 30fps) |
| `trim` | `<dir> <file> <start> <end> [fps]` | Cut out a middle section (default 7fps) |
| `flash` | `<dir> <file> <start> <end> [speed] [fps]` | Speed up a video section (default 20x, 30fps) |
| `tag` | `<owner> <repo> <ver> [branch]` | Create a GitHub release tag |
| `commit-history` | `[tags] [commits] [branch]` | Visualize Git commit history by tag |
| `net-surcharges` | `[dir]` | Parse CSVs and tally surcharge stats |
| `dev` | `<name> [args...]` | Dev-only snippets (requires `AQUATIC_DEV=1`) |

## Usage Examples

```bash
aquatic mute /path/to/dir video.mov 15
aquatic flash /path/to/dir recording.mov 00:00:22 00:01:14 20.0 30
aquatic tag my-org my-repo 1.70.0 develop
AQUATIC_DEV=1 aquatic dev mm-expand-module ui-expansion-icon
```

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Bash command | `aquatic-<name>.sh` | `aquatic-mute.sh` |
| Node.js command | `aquatic-<name>.js` | `aquatic-platform-mm-net-surcharges.js` |
| Dev snippet | `aquatic-dev-<name>.js` | `aquatic-dev-mm-expand-module.js` |
| Video output | `<base>_<suffix>.mov` | `input_mute.mov` |
| Git tag | `<version>_r<sha7>` | `1.70.0_rabc1234` |

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for development guidelines, templates, and coding standards.

## Security

See [SECURITY.md](docs/SECURITY.md) for the security policy and vulnerability reporting instructions.

## License

[AGPL-3.0](LICENSE) -- Attribution required. See LICENSE for details.
