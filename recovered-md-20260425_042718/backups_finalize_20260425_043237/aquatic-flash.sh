#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-flash.sh
# Description : Speeds up a section of a video with overlay text and concats
#               the pre/post sections at normal speed.
#
# Author      : Varun Chawla
# Created On  : April 24, 2026
# Last Updated: April 24, 2026
# Version     : 1.0
# Usage       : aquatic flash <dir> <file> <start> <end> [speed] [fps]
# Requirements: ffmpeg
###############################################################################

TARGET_DIR="${1:-}"
FILENAME="${2:-}"
START_TIME="${3:-}"
END_TIME="${4:-}"
SPEED="${5:-20.0}"
FPS="${6:-30}"

if [ -z "$END_TIME" ]; then
    echo "Usage: aquatic flash <dir> <file> <start_time> <end_time> [speed] [fps]"
    echo "Example: aquatic flash /path/to/dir video.mov 00:00:22 00:01:14 20.0 30"
    exit 1
fi

cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

if [ ! -f "$FILENAME" ]; then
    echo "[ERROR] File '$FILENAME' not found in '$TARGET_DIR'."
    exit 1
fi

BASE_NAME="${FILENAME%.*}"
OUTPUT="${BASE_NAME}_${SPEED}x_${FPS}fps.mov"

FONT="Monaco"
FONT_SIZE=25
TEXT_COLOR="white"
BOX_COLOR="black@0.6"
BORDER_W=10

to_seconds() {
    IFS=: read -r h m s <<< "$1"
    echo $(( 10#$h * 3600 + 10#$m * 60 + 10#$s ))
}

S_SEC=$(to_seconds "$START_TIME")
E_SEC=$(to_seconds "$END_TIME")

if [ "$S_SEC" -ge "$E_SEC" ]; then
    echo "[ERROR] Start time ($START_TIME) must be before end time ($END_TIME)."
    exit 1
fi

echo "[INFO] File: $FILENAME"
echo "[INFO] Speedup range: ${START_TIME} (${S_SEC}s) to ${END_TIME} (${E_SEC}s)"
echo "[INFO] Speed: ${SPEED}x | FPS: ${FPS}"
echo "-----------------------------------"

FILTER=""

FILTER+="[0:v]trim=start=0:end=${S_SEC},setpts=PTS-STARTPTS[v1];"

FILTER+="[0:v]trim=start=${S_SEC}:end=${E_SEC},setpts=PTS-STARTPTS,setpts=PTS/${SPEED},"
FILTER+="drawtext=text='Playback Speed\: ${SPEED}x':font='${FONT}':fontsize=${FONT_SIZE}:"
FILTER+="fontcolor=${TEXT_COLOR}:shadowcolor=black:shadowx=2:shadowy=2:"
FILTER+="box=1:boxcolor=${BOX_COLOR}:boxborderw=${BORDER_W}:"
FILTER+="x=(w-tw)/2:y=h-th-100:enable='lt(mod(t,1),0.5)'[v2];"

FILTER+="[0:v]trim=start=${E_SEC},setpts=PTS-STARTPTS,"
FILTER+="drawtext=text='Playback speed reverted to 1x.':font='${FONT}':fontsize=${FONT_SIZE}:"
FILTER+="fontcolor=${TEXT_COLOR}:shadowcolor=black:shadowx=2:shadowy=2:"
FILTER+="box=1:boxcolor=${BOX_COLOR}:boxborderw=${BORDER_W}:"
FILTER+="x=(w-tw)/2:y=h-th-100:enable='between(t,0,5)'[v3];"

FILTER+="[v1][v2][v3]concat=n=3:v=1:a=0[outv]"

echo "[INFO] Running ffmpeg..."
ffmpeg -i "$FILENAME" -filter_complex "$FILTER" -map "[outv]" -r "$FPS" "$OUTPUT"

echo "-----------------------------------"
echo "[OK] Done. Saved as $OUTPUT"


