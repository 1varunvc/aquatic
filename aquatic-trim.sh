#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-trim.sh
# Description : Compresses video to a specific FPS, cuts out a middle section,
#               and concats the remaining parts.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 1, 2026
# Version     : 2.0
# Usage       : aquatic trim <file> --start <time> --end <time> [--fps <n>]
# Requirements: ffmpeg
###############################################################################

FPS="7"
CUT_START=""
CUT_END=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start) CUT_START="$2"; shift 2 ;;
        --end) CUT_END="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: aquatic trim <file> --start <time> --end <time> [--fps <n>]"
            echo ""
            echo "Arguments:"
            echo "  <file>           Video file to process"
            echo ""
            echo "Options:"
            echo "  --start <time>   Cut start time (e.g., 00:00:58)"
            echo "  --end <time>     Cut end time (e.g., 00:01:05)"
            echo "  --fps <n>        Output frame rate (default: 7)"
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

BASE_NAME="${FILENAME%.*}"
COMPRESSED="${BASE_NAME}_${FPS}fps.mov"

echo "[INFO] Step 1: Compressing to $FPS FPS..."
ffmpeg -i "$FILENAME" -r "$FPS" "$COMPRESSED"

echo "[INFO] Step 2: Cutting Part 1 (Start to $CUT_START)..."
ffmpeg -ss 0 -to "$CUT_START" -i "$COMPRESSED" -c copy "${BASE_NAME}_part1.mov"

echo "[INFO] Step 3: Cutting Part 2 ($CUT_END onward)..."
ffmpeg -ss "$CUT_END" -i "$COMPRESSED" -c:v libx264 -preset fast -crf 23 -c:a copy "${BASE_NAME}_part2.mov"

echo "[INFO] Step 4: Concatenating..."
printf "file '%s_part1.mov'\nfile '%s_part2.mov'\n" "${BASE_NAME}" "${BASE_NAME}" > concat_list.txt
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy "${BASE_NAME}_trimmed.mov"

echo "[INFO] Cleaning up..."
rm "${BASE_NAME}_part1.mov" "${BASE_NAME}_part2.mov" concat_list.txt "$COMPRESSED"

echo "[OK] Saved as ${BASE_NAME}_trimmed.mov"
