#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-mute.sh
# Description : Strips audio from a video and sets frame rate.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 1, 2026
# Version     : 2.0
# Usage       : aquatic mute <file> [--fps <n>]
# Requirements: ffmpeg
###############################################################################

FPS="30"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fps) FPS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: aquatic mute <file> [--fps <n>]"
            echo ""
            echo "Arguments:"
            echo "  <file>       Video file to process"
            echo ""
            echo "Options:"
            echo "  --fps <n>    Output frame rate (default: 30)"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

FILENAME="${POSITIONAL[0]:-}"

if [ -z "$FILENAME" ]; then
    echo "Usage: aquatic mute <file> [--fps <n>]"
    exit 1
fi

if [ ! -f "$FILENAME" ]; then
    echo "[ERROR] File '$FILENAME' not found."
    exit 1
fi

BASE_NAME="${FILENAME%.*}"

ffmpeg -i "$FILENAME" -r "$FPS" -an "${BASE_NAME}_mute.mov"
echo "[OK] Saved as ${BASE_NAME}_mute.mov"
