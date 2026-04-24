#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-trim.sh
# Description : Compresses video to a specific FPS, cuts out a middle section,
#               and concats the remaining parts.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: March 21, 2026
# Version     : 1.0
# Usage       : cd "/path/to/folder"; chmod +x aquatic-trim.sh; ./aquatic trim "/path/to/dir" "video.mov" "00:00:58" "00:01:05" [fps]
# Requirements: ffmpeg
###############################################################################

TARGET_DIR="${1:-}"
FILENAME="${2:-}"
CUT_START="${3:-}"
CUT_END="${4:-}"
FPS="${5:-7}"

if [ -z "$CUT_END" ]; then
    echo "Usage: ./aquatic trim <dir> <filename> <cut_start> <cut_end> [fps]"
    echo "Example: ./aquatic trim /Users/varun/Screenshots input.mov 00:00:58 00:01:05 7"
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

BASE_NAME="${FILENAME%.*}"
COMPRESSED="${BASE_NAME}_${FPS}fps.mov"

echo "Step 1: Compressing to $FPS FPS..."
ffmpeg -i "$FILENAME" -r "$FPS" "$COMPRESSED"

echo "Step 2: Cutting Part 1 (Start to $CUT_START)..."
ffmpeg -ss 0 -to "$CUT_START" -i "$COMPRESSED" -c copy "${BASE_NAME}_part1.mov"

echo "Step 3: Cutting Part 2 ($CUT_END onward)..."
ffmpeg -ss "$CUT_END" -i "$COMPRESSED" -c:v libx264 -preset fast -crf 23 -c:a copy "${BASE_NAME}_part2.mov"

echo "Step 4: Concatenating..."
printf "file '%s_part1.mov'\nfile '%s_part2.mov'\n" "${BASE_NAME}" "${BASE_NAME}" > concat_list.txt
ffmpeg -f concat -safe 0 -i concat_list.txt -c copy "${BASE_NAME}_trimmed.mov"

echo "Cleaning up..."
rm "${BASE_NAME}_part1.mov" "${BASE_NAME}_part2.mov" concat_list.txt "$COMPRESSED"

echo "Done. Saved as ${BASE_NAME}_trimmed.mov"
