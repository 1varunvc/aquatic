#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-xlr8.sh
# Description : Speeds up a section of a video with overlay text and concats
#               the pre/post sections at normal speed.
#
# Author      : Varun Chawla
# Created On  : April 24, 2026
# Last Updated: May 4, 2026
# Usage       : aquatic xlr8 <file> --start <time> --end <time> [--speed <n>] [--fps <n>] [--debug]
# Requirements: ffmpeg
###############################################################################

SPEED="20.0"
FPS="30"
START_TIME=""
END_TIME=""
DEBUG_MODE="false"
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --start) START_TIME="$2"; shift 2 ;;
        --end) END_TIME="$2"; shift 2 ;;
        --speed) SPEED="$2"; shift 2 ;;
        --fps) FPS="$2"; shift 2 ;;
        --debug) DEBUG_MODE="true"; shift ;;
        --help|-h)
            echo "Usage: aquatic xlr8 <file> --start <time> --end <time> [--speed <n>] [--fps <n>] [--debug]"
            echo ""
            echo "Arguments:"
            echo "  <file>           Video file to process"
            echo ""
            echo "Options:"
            echo "  --start <time>   Speedup start time (e.g., 00:00:22)"
            echo "  --end <time>     Speedup end time (e.g., 00:01:14)"
            echo "  --speed <n>      Speedup multiplier (default: 20.0)"
            echo "  --fps <n>        Output frame rate (default: 30)"
            echo "  --debug          Show verbose debug output including ffmpeg logs"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

FILENAME="${POSITIONAL[0]:-}"

if [ -z "$FILENAME" ] || [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
    echo "Usage: aquatic xlr8 <file> --start <time> --end <time> [--speed <n>] [--fps <n>]"
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
debug_log "Output: $OUTPUT"

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

debug_log "Filter graph: $FILTER"

echo "[INFO] Running ffmpeg..."
if run_ffmpeg "speed up ${SPEED}x (${START_TIME} to ${END_TIME})" \
    -i "$FILENAME" -filter_complex "$FILTER" -map "[outv]" -r "$FPS" "$OUTPUT"; then
    echo "-----------------------------------"
    echo "[OK] Saved as $OUTPUT"
else
    echo "-----------------------------------"
    echo "[ERROR] Speed-up processing failed."
    exit 1
fi
