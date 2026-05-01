# aquatic

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
git clone https://github.com/varun-chawla/aquatic.git
cd aquatic
chmod +x aquatic aquatic-*.sh
```

Add to your PATH:

```bash
export PATH="/path/to/aquatic:$PATH"
```

## Usage

Every command supports `--help` for full details. Flags can appear in any order.

### Video Commands

```bash
# Strip audio, output at 15 FPS
aquatic mute recording.mov --fps 15

# Compress video to 7 FPS
aquatic compress recording.mov --fps 7

# Cut out a section (00:00:58 to 00:01:05), compress to 7 FPS
aquatic trim recording.mov --start 00:00:58 --end 00:01:05 --fps 7

# Speed up a section 20x, output at 30 FPS
aquatic xlr8 recording.mov --start 00:00:22 --end 00:01:14 --speed 20.0 --fps 30

# Build slideshow from images, no timestamps, custom output name
aquatic slideshow /path/to/images --no-timestamps --output my-slideshow
```

| Flag | Used By | Description |
|------|---------|-------------|
| `--fps <n>` | mute, compress, trim, xlr8 | Output frame rate |
| `--start <time>` | trim, xlr8 | Start time of the section (HH:MM:SS) |
| `--end <time>` | trim, xlr8 | End time of the section (HH:MM:SS) |
| `--speed <n>` | xlr8 | Speedup multiplier (default: 20.0) |
| `--no-timestamps` | slideshow | Disable timestamp overlay |
| `--output <name>` | slideshow | Custom output filename (without .mov extension) |

### Git Commands

```bash
# Create a tag on the develop branch
aquatic tag my-org my-repo 1.70.0 --branch develop

# Show last 3 tags with 5 commits each
aquatic commit-history --tags 3 --commits 5 --branch main
```

| Flag | Used By | Description |
|------|---------|-------------|
| `--branch <b>` | tag, commit-history | Target branch (default: develop) |
| `--tags <n>` | commit-history | Number of tags to display (default: 2) |
| `--commits <n>` | commit-history | Commits shown per tag (default: 10) |

### Dev Commands

Dev commands require `AQUATIC_DEV=1` set **every time** you run them.

```bash
# Parse CSVs in current directory
AQUATIC_DEV=1 aquatic dev mm-net-surcharges .

# Expand module snippet with custom icon
AQUATIC_DEV=1 aquatic dev mm-expand-module ui-expansion-icon

# Extract CSV snippet with custom XPath
AQUATIC_DEV=1 aquatic dev mm-extract-csv "//tbody/tr/td[11]/a[2]"

# Extract module snippet (uses defaults)
AQUATIC_DEV=1 aquatic dev mm-extract-module
```

Available dev snippets: `mm-expand-module`, `mm-extract-csv`, `mm-extract-module`, `mm-net-surcharges`

### Global Options

```bash
aquatic --version    # Show current version
aquatic --help       # Show command list
```

## Update Notifications

When newer versions exist in `RELEASES.md`, aquatic shows a log on every run:

```
[INFO] Updates available:
  0.2.0 — Added batch processing for video commands.
  0.3.0 — Tab completion support for zsh and bash.
```

Each line is a version you haven't updated to yet, with a one-sentence summary. This is sourced from `RELEASES.md` in the repo (updated with each release via `git pull` or `brew upgrade`).

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Bash command | `aquatic-<name>.sh` | `aquatic-mute.sh` |
| Node.js command | `aquatic-<name>.js` | — |
| Dev snippet | `aquatic-dev-<name>.js` | `aquatic-dev-mm-net-surcharges.js` |
| Video output | `<base>_<suffix>.mov` | `input_mute.mov` |
| Git tag | `<version>_r<sha7>` | `1.70.0_rabc1234` |

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for development guidelines, templates, and coding standards.

## Security

See [SECURITY.md](docs/SECURITY.md) for the security policy and vulnerability reporting instructions.

## License

TBA: [LICENSE](LICENSE)
