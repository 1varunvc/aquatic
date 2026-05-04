# Homebrew Distribution Setup

This document records the complete setup for distributing `aquatic` via Homebrew, including the tap repository, formula, CI validation, and automated release workflow.

---

## Overview

| Component | Repository | Purpose |
|---|---|---|
| Source | `1varunvc/aquatic` | The CLI toolkit source code |
| Tap | `1varunvc/homebrew-aquatic` | Homebrew formula that tells `brew` how to install `aquatic` |

Users install with:

```bash
brew tap 1varunvc/aquatic
brew install aquatic
```

---

## Prerequisites

| Tool | Required Scope | Purpose |
|---|---|---|
| `gh` (GitHub CLI) | `repo`, `workflow` | Create repos, releases, secrets, push |

No other CLI logins are required.

---

## Architecture

```
aquatic (source repo)
├── .github/workflows/update-tap.yml   # On release: auto-updates the tap formula
├── aquatic                            # Router binary (installed to bin/)
├── scripts/                           # Sub-scripts (installed to libexec/)
├── VERSION                            # Installed to libexec/
└── RELEASES.md                        # Installed to libexec/

homebrew-aquatic (tap repo)
├── Formula/aquatic.rb                 # Homebrew formula
└── .github/workflows/audit.yml        # CI: audit + test-install on every push
```

When Homebrew installs `aquatic`:
- The `aquatic` router binary goes to `/opt/homebrew/bin/aquatic`
- All scripts, `VERSION`, and `RELEASES.md` go to `/opt/homebrew/Cellar/aquatic/<ver>/libexec/`
- The formula patches `SCRIPT_DIR`, `DEV_DIR`, `VERSION`, and `RELEASES.md` paths in the router to point to `libexec/`

---

## Setup Steps (Performed May 4, 2026)

### 1. Made Source Repo Public

```bash
gh repo edit 1varunvc/aquatic --visibility public --accept-visibility-change-consequences
```

Homebrew requires public access to download release tarballs.

### 2. Tagged v0.1.0 and Created GitHub Release

```bash
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0" --notes "Initial release."
```

### 3. Computed Tarball SHA256

```bash
curl -sL https://github.com/1varunvc/aquatic/archive/refs/tags/v0.1.0.tar.gz | shasum -a 256
```

Result: `85e741dcc366761f99d3b7e0fb20fc48b576c56ac194e77a895fdf4b25885ab3`

### 4. Created the Tap Repository

```bash
gh repo create 1varunvc/homebrew-aquatic --public --description "Homebrew tap for the aquatic CLI toolkit" --clone
```

### 5. Wrote the Formula (`Formula/aquatic.rb`)

The formula:
- Downloads the tagged source tarball
- Installs the router to `bin/`
- Installs scripts and metadata to `libexec/`
- Patches the router's path variables to resolve from `libexec/`
- Declares dependencies: `bash`, `ffmpeg`, `gh`, `jq`, `node`

### 6. Added CI Audit Workflow to Tap (`.github/workflows/audit.yml`)

Runs `brew audit --strict` and a test install on every push to the tap repo.

### 7. Created Auto-Update Workflow in Source Repo (`.github/workflows/update-tap.yml`)

Triggers on every GitHub Release publish. Computes the new SHA256, clones the tap repo, updates the formula, and pushes.

### 8. Configured the `HOMEBREW_TAP_TOKEN` Secret

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo 1varunvc/aquatic
```

This secret allows the source repo's GitHub Action to push to `homebrew-aquatic`.

---

## Releasing a New Version

```bash
# 1. Update VERSION file
# 2. Commit and tag
git add -A && git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags

# 3. Create the release (triggers auto-update)
gh release create vX.Y.Z --title "vX.Y.Z" --notes "Description of changes."
```

The GitHub Action will automatically update the tap formula. Users receive the update via:

```bash
brew upgrade aquatic
```

---

## Token Maintenance

The `HOMEBREW_TAP_TOKEN` secret must be a valid token with `repo` scope that can push to `1varunvc/homebrew-aquatic`.

To create a long-lived token:
1. Go to https://github.com/settings/tokens
2. Create a classic PAT with `repo` scope
3. Update the secret:

```bash
echo "<new-token>" | gh secret set HOMEBREW_TAP_TOKEN --repo 1varunvc/aquatic
```

---

## Uninstalling

```bash
brew uninstall aquatic
brew untap 1varunvc/aquatic
```

---

## Verification Commands

```bash
brew tap 1varunvc/aquatic
brew install aquatic
aquatic --version
aquatic mute
aquatic compress
AQUATIC_DEV=1 aquatic dev mm-expand-module
```

