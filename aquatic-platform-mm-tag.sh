#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-platform-mm-tag.sh
# Description : Creates a GitHub release tag appending a short SHA.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: March 25, 2026
# Version     : 1.0
# Usage       : aquatic tag "my-org" "my-repo" "1.70.0" "develop"
# Requirements: gh
###############################################################################

OWNER="${1:-}"
REPO="${2:-}"
VERSION="${3:-}"
TARGET="${4:-develop}"

if [ -z "$VERSION" ]; then
    echo "Usage: aquatic tag <owner> <repo> <version> [branch_or_sha]"
    exit 1
fi

if [ ${#TARGET} -eq 40 ] || [[ "$TARGET" =~ ^[0-9a-f]{7,40}$ ]]; then
    SHA="$TARGET"
else
    echo "Fetching SHA for branch: $TARGET..."
    SHA=$(gh api "repos/$OWNER/$REPO/commits/$TARGET" -q .sha)
fi

TAG_NAME="${VERSION}_r${SHA:0:7}"

echo "Creating tag $TAG_NAME pointing to $SHA in $OWNER/$REPO..."
gh api repos/$OWNER/$REPO/git/refs -f ref="refs/tags/$TAG_NAME" -f sha="$SHA"
