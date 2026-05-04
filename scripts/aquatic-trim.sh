#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-trim.sh
# Description : Compresses video to a specific FPS, cuts out a middle section,
#               and concats the remaining parts.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 4, 2026
# Usage       : aquatic trim <file> --start <time> --end <time> [--fps <n>] [--debug]
# Requirements: ffmpeg, ffprobe, bc
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/aquatic-progress.sh"

FPS="7"
CUT_START=""
CUT_END=""
DEBUG_MODE="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start) CUT_START="$2"; shift 2 ;;
        --end) CUT_END="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        --debug) DEBUG_MODE="true"; shift ;;
        --help|-h)
            echo "Usage: aquatic trim <file> --start <time> --end <time> [--fps <n>] [--debug]"
            echo ""
            echo "Arguments:"
            echo "  <file>           Video file to process"
            echo ""
            echo "Options:"
            echo "  --start <time>   Cut start time (e.g., 00:00:58)"
            echo "  --end <time>     Cut end time (e.g., 00:01:05)"
            echo "  --fps <n>        Output frame rate (default: 7)"
            echo "  --debug          Show verbose debug output including ffmpeg logs"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

FILENAME="${POSITIONAL[0]:-}"

if [ -z "$FILENAME" ] || [ -z "$CUT_START" ] || [ -z "$CUT_END" ]; then
    echo "Usage: aquatic trim <file> --start <time> --end <time> [--fps <n>]"
    exit 1
fi

if [ ! -f "$FILENAME" ]; then
    echo "[ERROR] File '$FILENAME' not found."
    exit 1
fi

debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then echo "[DEBUG] $1"; fi
}

cleanup_trim() {
    rm -f "${BASE_NAME}_part1.mov" "${BASE_NAME}_part2.mov" concat_list.txt "$COMPRESSED" 2>/dev/null
}

BASE_NAME="${FILENAME%.*}"
COMPRESSED="${BASE_NAME}_${FPS}fps.mov"
OUTPUT="${BASE_NAME}_trimmed.mov"

echo "[INFO] Trimming '$FILENAME' (cut ${CUT_START} to ${CUT_END}) at $FPS FPS..."
debug_log "Input: $FILENAME"
debug_log "Cut range: $CUT_START to $CUT_END"
debug_log "Output: $OUTPUT"

echo "[INFO] Step 1/4: Compressing to $FPS FPS..."
if ! _aquatic_run_ffmpeg_with_progress "Step 1/4" "$FILENAME" -i "$FILENAME" -r "$FPS" "$COMPRESSED"; then
    echo "[ERROR] Compression step failed."
    exit 1
fi

echo "[INFO] Step 2/4: Cutting Part 1 (start to $CUT_START)..."
if ! _aquatic_run_ffmpeg_with_progress "Step 2/4" "$COMPRESSED" -ss 0 -to "$CUT_START" -i "$COMPRESSED" -c copy "${BASE_NAME}_part1.mov"; then
    echo "[ERROR] Part 1 cut failed."
    cleanup_trim; exit 1
fi

echo "[INFO] Step 3/4: Cutting Part 2 ($CUT_END onward)..."
if ! _aquatic_run_ffmpeg_with_progress "Step 3/4" "$COMPRESSED" -ss "$CUT_END" -i "$COMPRESSED" -c:v libx264 -preset fast -crf 23 -c:a copy "${BASE_NAME}_part2.mov"; then
    echo "[ERROR] Part 2 cut failed."
    cleanup_trim; exit 1
fi

echo "[INFO] Step 4/4: Concatenating..."
printf "file '%s_part1.mov'\nfile '%s_part2.mov'\n" "${BASE_NAME}" "${BASE_NAME}" > concat_list.txt
if ! _aquatic_run_ffmpeg_with_progress "Step 4/4" "${BASE_NAME}_part1.mov" -f concat -safe 0 -i concat_list.txt -c copy "$OUTPUT"; then
    echo "[ERROR] Concatenation failed."
    cleanup_trim; exit 1
fi

echo "[INFO] Cleaning up temporary files..."
cleanup_trim

echo "[OK] Saved as $OUTPUT"
