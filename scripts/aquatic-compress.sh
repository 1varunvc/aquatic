#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-compress.sh
# Description : Compresses a video to a specific FPS.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 4, 2026
# Usage       : aquatic compress <file> [--fps <n>] [--debug]
# Requirements: ffmpeg
###############################################################################

FPS="30"
DEBUG_MODE="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fps) FPS="$2"; shift 2 ;;
        --debug) DEBUG_MODE="true"; shift ;;
        --help|-h)
            echo "Usage: aquatic compress <file> [--fps <n>] [--debug]"
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
    echo "Usage: aquatic compress <file> [--fps <n>]"
    exit 1
fi

if [ ! -f "$FILENAME" ]; then
    echo "[ERROR] File '$FILENAME' not found."
    exit 1
fi

debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then echo "[DEBUG] $1"; fi
}

run_ffmpeg() {
    local description="$1"; shift
    local ffmpeg_err; ffmpeg_err=$(mktemp)
    debug_log "ffmpeg: $description"
    if [ "$DEBUG_MODE" = "true" ]; then
        if ffmpeg "$@" 2>&1 | tee "$ffmpeg_err"; then rm -f "$ffmpeg_err"; return 0
        else echo "[ERROR] ffmpeg failed: $description"; rm -f "$ffmpeg_err"; return 1; fi
    else
        if ffmpeg "$@" > /dev/null 2>"$ffmpeg_err"; then rm -f "$ffmpeg_err"; return 0
        else
            local err_summary; err_summary=$(grep -i "error\|no such\|invalid\|not found" "$ffmpeg_err" | head -3)
            echo "[ERROR] ffmpeg failed: $description"
            [ -n "$err_summary" ] && echo "[ERROR] Detail: $err_summary"
            rm -f "$ffmpeg_err"; return 1
        fi
    fi
}

BASE_NAME="${FILENAME%.*}"
OUTPUT="${BASE_NAME}_${FPS}fps.mov"

echo "[INFO] Compressing '$FILENAME' to $FPS FPS..."
debug_log "Input: $FILENAME"
debug_log "Output: $OUTPUT"

if run_ffmpeg "compress to ${FPS}fps" -i "$FILENAME" -r "$FPS" "$OUTPUT"; then
    echo "[OK] Saved as $OUTPUT"
else
    echo "[ERROR] Compression failed."
    exit 1
fi
