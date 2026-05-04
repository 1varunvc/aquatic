#!/bin/bash

###############################################################################
# Script Name : aquatic-progress.sh
# Description : Shared progress bar and ffmpeg runner with visual feedback.
#               Sourced by video processing sub-scripts.
#
# Author      : Varun Chawla
# Created On  : May 4, 2026
# Last Updated: May 4, 2026
# Usage       : source "$SCRIPT_DIR/aquatic-progress.sh"
# Requirements: ffmpeg, ffprobe, bc
###############################################################################

_aquatic_get_duration_us() {
    local file="$1"
    local duration_s
    duration_s=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null || echo "")
    if [ -n "$duration_s" ] && [ "$duration_s" != "N/A" ]; then
        printf '%.0f' "$(echo "$duration_s * 1000000" | bc)" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

_aquatic_draw_progress() {
    local percent="$1"
    local label="${2:-Processing}"
    local width=40
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    local bar=""
    local i
    for ((i = 0; i < filled; i++)); do bar+="#"; done
    for ((i = 0; i < empty; i++)); do bar+="-"; done
    printf "\r[INFO] %s: [%s] %3d%%" "$label" "$bar" "$percent"
}

_aquatic_run_ffmpeg_with_progress() {
    local description="$1"
    local input_file="$2"
    shift 2

    local ffmpeg_err; ffmpeg_err=$(mktemp)
    local progress_file; progress_file=$(mktemp)

    if [ "${DEBUG_MODE:-false}" = "true" ]; then
        debug_log "ffmpeg: $description"
        if ffmpeg "$@" 2>&1 | tee "$ffmpeg_err"; then
            rm -f "$ffmpeg_err" "$progress_file"; return 0
        else
            echo "[ERROR] ffmpeg failed: $description"
            rm -f "$ffmpeg_err" "$progress_file"; return 1
        fi
    fi

    local total_duration_us
    total_duration_us=$(_aquatic_get_duration_us "$input_file")

    ffmpeg "$@" -progress "$progress_file" -nostats > /dev/null 2>"$ffmpeg_err" &
    local ffmpeg_pid=$!

    if [ "$total_duration_us" -gt 0 ]; then
        while kill -0 "$ffmpeg_pid" 2>/dev/null; do
            if [ -f "$progress_file" ]; then
                local out_time_us
                out_time_us=$(grep -o 'out_time_us=[0-9]*' "$progress_file" 2>/dev/null | tail -1 | cut -d= -f2)
                if [ -n "$out_time_us" ] && [ "$out_time_us" -gt 0 ]; then
                    local pct=$((out_time_us * 100 / total_duration_us))
                    [ "$pct" -gt 100 ] && pct=100
                    _aquatic_draw_progress "$pct" "$description"
                fi
            fi
            sleep 0.3
        done
    fi

    local exit_code=0
    wait "$ffmpeg_pid" || exit_code=$?

    if [ "$total_duration_us" -gt 0 ]; then
        _aquatic_draw_progress 100 "$description"
        echo ""
    fi

    rm -f "$progress_file"

    if [ $exit_code -eq 0 ]; then
        rm -f "$ffmpeg_err"; return 0
    else
        local err_summary; err_summary=$(grep -i "error\|no such\|invalid\|not found" "$ffmpeg_err" | head -3)
        echo "[ERROR] ffmpeg failed: $description"
        [ -n "$err_summary" ] && echo "[ERROR] Detail: $err_summary"
        rm -f "$ffmpeg_err"; return 1
    fi
}

