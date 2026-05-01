#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-flash.sh
# Description : Speeds up a section of a video with overlay text and concats
#               the pre/post sections at normal speed.
#
# Author      : Varun Chawla
# Created On  : April 24, 2026
# Last Updated: May 1, 2026
# Usage       : aquatic flash <file> --start <time> --end <time> [--speed <n>] [--fps <n>]
# Requirements: ffmpeg
###############################################################################

SPEED="20.0"
FPS="30"
START_TIME=""
END_TIME=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start) START_TIME="$2"; shift 2 ;;
        --end) END_TIME="$2"; shift 2 ;;
        --speed) SPEED="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: aquatic flash <file> --start <time> --end <time> [--speed <n>] [--fps <n>]"
            echo ""
            echo "Arguments:"
            echo "  <file>           Video file to process"
            echo ""
            echo "Options:"
            echo "  --start <time>   Speedup start time (e.g., 00:00:22)"
            echo "  --end <time>     Speedup end time (e.g., 00:01:14)"
            echo "  --speed <n>      Speedup multiplier (default: 20.0)"
            echo "  --fps <n>        Output frame rate (default: 30)"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

FILENAME="${POSITIONAL[0]:-}"

if [ -z "$FILENAME" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
    echo "Usage: aquatic flash <file> --start <time> --end <time> [--speed <n>] [--fps <n>]"
    exit 1
fi

if [ ! -f "$FILENAME" ]; then
    echo "[ERROR] File '$FILENAME' not found."
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
echo "[OK] Saved as $OUTPUT"
