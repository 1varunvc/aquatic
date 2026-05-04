#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-mute.sh
# Description : Strips audio from a video and sets frame rate.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 4, 2026
# Usage       : aquatic mute <file> [--fps <n>] [--debug]
# Requirements: ffmpeg, ffprobe, bc
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/aquatic-progress.sh"

FPS="30"
DEBUG_MODE="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fps) FPS="$2"; shift 2 ;;
        --debug) DEBUG_MODE="true"; shift ;;
        --help|-h)
            echo "Usage: aquatic mute <file> [--fps <n>] [--debug]"
            echo ""
            echo "Arguments:"
            echo "  <file>       Video file to process"
            echo ""
            echo "Options:"
            echo "  --fps <n>    Output frame rate (default: 30)"
            echo "  --debug      Show verbose debug output including ffmpeg logs"
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

debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then echo "[DEBUG] $1"; fi
}

BASE_NAME="${FILENAME%.*}"
OUTPUT="${BASE_NAME}_mute.mov"

echo "[INFO] Stripping audio from '$FILENAME' at $FPS FPS..."
debug_log "Input: $FILENAME"
debug_log "Output: $OUTPUT"

if _aquatic_run_ffmpeg_with_progress "Muting" "$FILENAME" -i "$FILENAME" -r "$FPS" -an "$OUTPUT"; then
    echo "[OK] Saved as $OUTPUT"
else
    echo "[ERROR] Mute operation failed."
    exit 1
fi
