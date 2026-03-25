#!/bin/bash

###############################################################################
# Script Name : aquatic-mute.sh
# Description : Strips audio from a video and sets frame rate.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: March 21, 2026
# Version     : 1.0
# Usage       : cd "/path/to/folder"; chmod +x aquatic-mute.sh; ./aquatic mute "/path/to/dir" "video.mov" [fps]
# Requirements: ffmpeg
###############################################################################

TARGET_DIR="$1"
FILENAME="$2"
FPS="${3:-30}"

if [ -z "$FILENAME" ]; then
    echo "Usage: ./aquatic mute <dir> <filename> [fps]"
    echo "Default FPS is 30 if not provided."
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

ffmpeg -i "$FILENAME" -r "$FPS" -an "${FILENAME%.*}_mute.mov"
echo "Done. Saved as ${FILENAME%.*}_mute.mov"
