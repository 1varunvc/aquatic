#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-slideshow.sh
# Description : Stitches images into a 1-FPS cinematic slideshow with 
#               timestamps, auto-wrapping captions, and progression counters.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: May 4, 2026
# Usage       : aquatic slideshow [dir] [--no-timestamps] [--output <name>] [--debug]
# Requirements: ffmpeg (with drawtext/libfreetype), md5 (macOS)
###############################################################################

# ==========================================
# 1. USER CONFIGURATION
# ==========================================

CUSTOM_FONT_PATH="/path/to/file"
FONT_SIZE="25"
WRAP_WIDTH="60"
FPS="1"
IMAGE_DURATION="2"
DEBUG_MODE="false"
CAPTION_FILE="captions.txt"

# ==========================================
# 2. ARGUMENT PARSING
# ==========================================

DISABLE_TIMESTAMPS="false"
CUSTOM_OUTPUT_NAME=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-timestamps) DISABLE_TIMESTAMPS="true"; shift ;;
        --output|-o) CUSTOM_OUTPUT_NAME="$2"; shift 2 ;;
        --debug) DEBUG_MODE="true"; shift ;;
        --help|-h)
            echo "Usage: aquatic slideshow [dir] [--no-timestamps] [--output <name>] [--debug]"
            echo ""
            echo "Arguments:"
            echo "  [dir]              Directory containing images (default: .)"
            echo ""
            echo "Options:"
            echo "  --no-timestamps    Disable timestamp overlay on frames"
            echo "  --output <name>    Custom output filename (without extension)"
            echo "  --debug            Show verbose debug output including ffmpeg logs"
            exit 0
            ;;
        -*) echo "[ERROR] Unknown option: $1"; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done

TARGET_DIR="${POSITIONAL[0]:-.}"

# ==========================================
# 3. HELPER FUNCTIONS
# ==========================================

debug_log() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo "[DEBUG] $1"
    fi
}

run_ffmpeg() {
    local description="$1"
    shift
    local ffmpeg_err
    ffmpeg_err=$(mktemp)

    debug_log "ffmpeg: $description"

    if [ "$DEBUG_MODE" = "true" ]; then
        if ffmpeg "$@" 2>&1 | tee "$ffmpeg_err"; then
            rm -f "$ffmpeg_err"
            return 0
        else
            echo "[ERROR] ffmpeg failed: $description"
            rm -f "$ffmpeg_err"
            return 1
        fi
    else
        if ffmpeg "$@" > /dev/null 2>"$ffmpeg_err"; then
            rm -f "$ffmpeg_err"
            return 0
        else
            local err_summary
            err_summary=$(grep -i "error\|no such\|invalid\|not found\|filter" "$ffmpeg_err" | head -3)
            echo "[ERROR] ffmpeg failed: $description"
            if [ -n "$err_summary" ]; then
                echo "[ERROR] Detail: $err_summary"
            fi
            rm -f "$ffmpeg_err"
            return 1
        fi
    fi
}

# ==========================================
# 4. SETUP & CAPTION LOADING
# ==========================================

cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

echo "[INFO] Working directory: $(pwd)"

FFMPEG_FILTERS=$(ffmpeg -filters 2>/dev/null || true)
if ! echo "$FFMPEG_FILTERS" | grep -q "drawtext"; then
    echo "[ERROR] ffmpeg is missing the 'drawtext' filter (requires libfreetype)."
    echo "[INFO] Fix: brew uninstall ffmpeg && brew install homebrew-ffmpeg/ffmpeg/ffmpeg"
    exit 1
fi
debug_log "ffmpeg drawtext filter: available"

caption_files=()
caption_texts=()

if [ -f "$CAPTION_FILE" ]; then
    echo "[INFO] Found caption file. Loading..."
    while IFS='|' read -r fname fcap; do
        fname=$(echo "$fname" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        fcap=$(echo "$fcap" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$fname" ] && continue
        caption_files+=("$fname")
        caption_texts+=("$fcap")
    done < "$CAPTION_FILE"
    debug_log "Loaded ${#caption_files[@]} caption entries"
else
    echo "[INFO] No '$CAPTION_FILE' found. Proceeding without captions."
fi

if [ -f "$CUSTOM_FONT_PATH" ]; then
    echo "[INFO] Using custom font: $CUSTOM_FONT_PATH"
    FONT_PATH="$CUSTOM_FONT_PATH"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then FONT_PATH="/System/Library/Fonts/Menlo.ttc"; 
    else FONT_PATH="/c/Windows/Fonts/consola.ttf"; fi
fi
debug_log "Font: $FONT_PATH"

# ==========================================
# 5. VIDEO PROCESSING
# ==========================================

if ! ffmpeg -filters 2>/dev/null | grep -q "drawtext"; then
    echo "[ERROR] ffmpeg was built without the 'drawtext' filter (requires libfreetype)."
    echo "[INFO] Fix: brew uninstall ffmpeg && brew install homebrew-ffmpeg/ffmpeg/ffmpeg"
    exit 1
fi

rm -rf temp_parts temp_list.txt
mkdir -p temp_parts

echo "[INFO] Starting processing..."
echo "-----------------------------------"

IMAGE_FILES=()
for f in *.jpg *.jpeg *.png *.JPG *.JPEG *.PNG; do
    [ -f "$f" ] && IMAGE_FILES+=("$f")
done

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
    echo "[ERROR] No image files found in '$(pwd)'."
    rm -rf temp_parts
    exit 1
fi

debug_log "Unsorted image count: ${#IMAGE_FILES[@]}"

SORTED_OUTPUT=$(for f in "${IMAGE_FILES[@]}"; do
    printf '%s\t%s\n' "$(stat -f '%B' "$f")" "$f"
done | sort -n | cut -f2)

IMAGE_FILES=()
while IFS= read -r line; do
    IMAGE_FILES+=("$line")
done <<< "$SORTED_OUTPUT"

TOTAL_IMGS=${#IMAGE_FILES[@]}
CURRENT_COUNT=1
FAILED_COUNT=0

echo "[INFO] Total images to process: $TOTAL_IMGS"
debug_log "Timestamps: $([ "$DISABLE_TIMESTAMPS" = "true" ] && echo "disabled" || echo "enabled")"

for img in "${IMAGE_FILES[@]}"; do

    debug_log "Processing [$CURRENT_COUNT/$TOTAL_IMGS]: $img"

    RAW_DATE=$(stat -f "%SB" -t "%B %d, %Y at %I:%M:%S %p (%Z)" "$img")
    ESCAPED_DATE=$(echo "$RAW_DATE" | sed -e 's/:/\\:/g' -e 's/,/\\,/g')
    debug_log "Timestamp: $RAW_DATE"

    COUNTER_TEXT="$CURRENT_COUNT/$TOTAL_IMGS"
    
    CAPTION_TEXT=""
    IMG_FINGERPRINT=$(echo "$img" | sed 's/[^[:alnum:]]//g') 
    
    count=${#caption_files[@]}

    for (( i=0; i<count; i++ )); do
        CFG_NAME="${caption_files[$i]}"
        KEY_FINGERPRINT=$(echo "$CFG_NAME" | sed 's/[^[:alnum:]]//g')
        
        if [[ "$IMG_FINGERPRINT" == "$KEY_FINGERPRINT" ]]; then
            CAPTION_TEXT="${caption_texts[$i]}"
            break
        fi
    done
    
    VF_CHAIN="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
    
    if [ "$DISABLE_TIMESTAMPS" != "true" ]; then
        VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$ESCAPED_DATE':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:x=60:y=h-th-30"
    fi

    VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$COUNTER_TEXT':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:x=w-tw-60:y=h-th-30"

    if [ -n "$CAPTION_TEXT" ]; then
        WRAPPED_TEXT=$(echo "$CAPTION_TEXT" | fold -s -w "$WRAP_WIDTH")
        ESCAPED_CAPTION=$(echo "$WRAPPED_TEXT" | sed -e 's/:/\\:/g' -e 's/,/\\,/g' -e 's/%/\\\\%/g')
        VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$ESCAPED_CAPTION':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:line_spacing=10:x=(w-text_w)/2:y=h-th-100"
        echo "   + Caption added: $img"
    fi

    SAFE_NAME=$(md5 -q -s "$img")
    OUTPUT_PART="temp_parts/${SAFE_NAME}.mp4"
    debug_log "Output part: $OUTPUT_PART"

    if run_ffmpeg "encode frame $CURRENT_COUNT/$TOTAL_IMGS ($img)" \
        -y -nostdin -framerate "$FPS" -loop 1 -i "$img" -t "$IMAGE_DURATION" \
        -vf "$VF_CHAIN" \
        -c:v libx264 -crf 0 -preset veryslow -pix_fmt yuv444p -r "$FPS" \
        "$OUTPUT_PART"; then
        echo "file '$OUTPUT_PART'" >> temp_list.txt
        echo "[INFO] Processed [$CURRENT_COUNT/$TOTAL_IMGS]: $img"
    else
        echo "[WARN] Skipped [$CURRENT_COUNT/$TOTAL_IMGS]: $img"
        ((FAILED_COUNT++))
    fi
    
    ((CURRENT_COUNT++))
done

echo "-----------------------------------"

if [ "$FAILED_COUNT" -gt 0 ]; then
    echo "[WARN] $FAILED_COUNT of $TOTAL_IMGS images failed to process."
fi

FIRST_IMG="${IMAGE_FILES[0]:-}"
FIRST_IMG="${FIRST_IMG%.*}"

if [ -n "$CUSTOM_OUTPUT_NAME" ]; then
    OUTPUT_NAME="$CUSTOM_OUTPUT_NAME"
else
    OUTPUT_NAME="${FIRST_IMG}_01fps"
fi

if [ -f "temp_list.txt" ]; then
    echo "[INFO] Combining lossless video..."
    if ! run_ffmpeg "concat lossless parts" \
        -y -nostdin -f concat -safe 0 -i temp_list.txt -c copy "${FIRST_IMG}.mp4"; then
        echo "[ERROR] Failed to combine video parts."
        rm -rf temp_parts temp_list.txt
        exit 1
    fi

    echo "[INFO] Applying final compression pass (${FPS} FPS .mov)..."
    if ! run_ffmpeg "final compression to ${OUTPUT_NAME}.mov" \
        -y -nostdin -i "${FIRST_IMG}.mp4" -r "$FPS" "${OUTPUT_NAME}.mov"; then
        echo "[ERROR] Failed final compression pass."
        rm -rf temp_parts temp_list.txt "${FIRST_IMG}.mp4"
        exit 1
    fi

    rm -rf temp_parts temp_list.txt "${FIRST_IMG}.mp4"
    
    echo "[OK] Final video saved as: ${OUTPUT_NAME}.mov"
else
    echo "[ERROR] No images were processed successfully."
    rm -rf temp_parts
    exit 1
fi
