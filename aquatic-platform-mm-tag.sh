#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-platform-mm-tag.sh
# Description : Creates a GitHub release tag appending a short SHA.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 1, 2026
# Usage       : aquatic tag <owner> <repo> <version> [--branch <b>]
# Requirements: gh
###############################################################################

BRANCH="develop"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --branch|-b) BRANCH="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: aquatic tag <owner> <repo> <version> [--branch <b>]"
            echo ""
            echo "Arguments:"
            echo "  <owner>      GitHub org/user"
            echo "  <repo>       Repository name"
            echo "  <version>    Version string (e.g., 1.70.0)"
            echo ""
            echo "Options:"
            echo "  --branch <b> Branch or SHA to tag (default: develop)"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

OWNER="${POSITIONAL[0]:-}"
REPO="${POSITIONAL[1]:-}"
VERSION="${POSITIONAL[2]:-}"

if [ -z "$VERSION" ]; then
    echo "Usage: aquatic tag <owner> <repo> <version> [--branch <b>]"
    exit 1
fi

TARGET="$BRANCH"

if [ ${#TARGET} -eq 40 ] || [[ "$TARGET" =~ ^[0-9a-f]{7,40}$ ]]; then
    SHA="$TARGET"
else
    echo "[INFO] Fetching SHA for branch: $TARGET..."
    SHA=$(gh api "repos/$OWNER/$REPO/commits/$TARGET" -q .sha)
fi

TAG_NAME="${VERSION}_r${SHA:0:7}"

echo "[INFO] Creating tag $TAG_NAME pointing to $SHA in $OWNER/$REPO..."
gh api repos/$OWNER/$REPO/git/refs -f ref="refs/tags/$TAG_NAME" -f sha="$SHA"
echo "[OK] Tag $TAG_NAME created."
