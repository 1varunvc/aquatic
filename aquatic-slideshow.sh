#!/bin/bash
set -euo pipefail

###############################################################################
# Script Name : aquatic-slideshow.sh
# Description : Stitches images into a 1-FPS cinematic slideshow with 
#               timestamps, auto-wrapping captions, and progression counters.
#
# Author      : Varun Chawla
# Created On  : March 21, 2026
# Last Updated: March 21, 2026
# Version     : 3.1
# Usage       : cd "/path/to/folder"; chmod +x aquatic-slideshow.sh; ./aquatic slideshow [optional/path/to/folder]
# Requirements: ffmpeg, md5 (or md5sum)
###############################################################################

# ==========================================
# 1. USER CONFIGURATION
# ==========================================

# Path to your font
CUSTOM_FONT_PATH="/path/to/file"

# Font size
FONT_SIZE="25"

# Maximum characters per line for caption (Controls the width!)
# 60 is a good "narrow" width.
WRAP_WIDTH="60"

# Video Framerate & Duration per image
FPS="1"
IMAGE_DURATION="2"

# Debug mode
DEBUG_MODE="false"

# File containing captions (Filename | Caption)
CAPTION_FILE="captions.txt"

# ==========================================
# 2. SETUP & CAPTION LOADING
# ==========================================

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR" || { echo "[ERROR] Directory '$TARGET_DIR' not found."; exit 1; }

echo "Working directory set to: $(pwd)"

# Lists to store loaded captions
caption_files=()
caption_texts=()

# Load captions if file exists
if [ -f "$CAPTION_FILE" ]; then
    echo "Found caption file. Loading..."
    while IFS='|' read -r fname fcap; do
        # Trim leading/trailing whitespace
        fname=$(echo "$fname" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        fcap=$(echo "$fcap" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        
        # Skip empty lines
        [ -z "$fname" ] && continue
        
        caption_files+=("$fname")
        caption_texts+=("$fcap")
    done < "$CAPTION_FILE"
else
    echo "No '$CAPTION_FILE' found. Proceeding without captions."
fi

# Font Selection Logic
if [ -f "$CUSTOM_FONT_PATH" ]; then
    echo "Using custom font: $CUSTOM_FONT_PATH"
    FONT_PATH="$CUSTOM_FONT_PATH"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then FONT_PATH="/System/Library/Fonts/Menlo.ttc"; 
    else FONT_PATH="/c/Windows/Fonts/consola.ttf"; fi
fi

# ==========================================
# 3. VIDEO PROCESSING
# ==========================================

rm -rf temp_parts temp_list.txt
mkdir -p temp_parts

echo "Starting processing..."
echo "-----------------------------------"

if [ "$DEBUG_MODE" = "true" ]; then LOG_OUTPUT="/dev/stdout"; else LOG_OUTPUT="/dev/null"; fi

# Detect Array Start Index
if [ -n "${caption_files[0]}" ]; then IDX_START=0; else IDX_START=1; fi

# --- CALCULATE TOTAL IMAGES FOR COUNTER ---
TOTAL_IMGS=$(ls -rtU | grep -iE '\.(jpg|jpeg|png)$' | wc -l | xargs)
CURRENT_COUNT=1

echo "Total images to process: $TOTAL_IMGS"

# Loop through images
ls -rtU | grep -iE '\.(jpg|jpeg|png)$' | while IFS= read -r img; do
    
    [ -f "$img" ] || continue

    # --- TIMESTAMP ---
    RAW_DATE=$(stat -f "%SB" -t "%B %d, %Y at %I:%M:%S %p (%Z)" "$img")
    ESCAPED_DATE=$(echo "$RAW_DATE" | sed -e 's/:/\\:/g' -e 's/,/\\,/g')
    
    # --- COUNTER TEXT ---
    COUNTER_TEXT="$CURRENT_COUNT/$TOTAL_IMGS"
    
    # --- CAPTION MATCHING ---
    CAPTION_TEXT=""
    IMG_FINGERPRINT=$(echo "$img" | sed 's/[^[:alnum:]]//g') 
    
    count=${#caption_files[@]}
    IDX_END=$((IDX_START + count))

    for (( i=IDX_START; i<IDX_END; i++ )); do
        CFG_NAME="${caption_files[$i]}"
        KEY_FINGERPRINT=$(echo "$CFG_NAME" | sed 's/[^[:alnum:]]//g')
        
        if [[ "$IMG_FINGERPRINT" == "$KEY_FINGERPRINT" ]]; then
            CAPTION_TEXT="${caption_texts[$i]}"
            break
        fi
    done
    
    # Base Chain (Scale + Pad only - No exposure/sharpness changes)
    VF_CHAIN="scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2"
    
    # 1. Add Timestamp (Bottom Left)
    VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$ESCAPED_DATE':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:x=60:y=h-th-30"

    # 2. Add Counter (Bottom Right)
    VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$COUNTER_TEXT':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:x=w-tw-60:y=h-th-30"

    # 3. Add Caption (Bottom Center, Wrapped)
    if [ -n "$CAPTION_TEXT" ]; then
        
        # --- AUTO WRAPPER ---
        WRAPPED_TEXT=$(echo "$CAPTION_TEXT" | fold -s -w "$WRAP_WIDTH")
        ESCAPED_CAPTION=$(echo "$WRAPPED_TEXT" | sed -e 's/:/\\:/g' -e 's/,/\\,/g' -e 's/%/\\\\%/g')
        
        # Add filter (floats above timestamp)
        VF_CHAIN="$VF_CHAIN,drawtext=fontsize=$FONT_SIZE:fontfile='$FONT_PATH':text='$ESCAPED_CAPTION':fontcolor=white:shadowcolor=black:shadowx=2:shadowy=2:box=1:boxborderw=10:boxcolor=black@0.6:line_spacing=10:x=(w-text_w)/2:y=h-th-100"
        
        echo "   + Caption added: $img"
    fi

    SAFE_NAME=$(md5 -q -s "$img")
    
    # Lossless loop generation
    ffmpeg -y -nostdin -framerate "$FPS" -loop 1 -i "$img" -t "$IMAGE_DURATION" \
    -vf "$VF_CHAIN" \
    -c:v libx264 -crf 0 -preset veryslow -pix_fmt yuv444p -r "$FPS" \
    "temp_parts/${SAFE_NAME}.mp4" > "$LOG_OUTPUT" 2>&1

    if [ -f "temp_parts/${SAFE_NAME}.mp4" ]; then
        echo "file 'temp_parts/${SAFE_NAME}.mp4'" >> temp_list.txt
        echo "Processed [$CURRENT_COUNT/$TOTAL_IMGS]: $img"
    else
        echo "Failed to process: $img"
    fi
    
    # Increment Counter
    ((CURRENT_COUNT++))
done

echo "-----------------------------------"

FIRST_IMG=$(ls -rtU | grep -iE '\.(jpg|jpeg|png)$' | head -n 1 | sed 's/\.[^.]*$//')

if [ -f "temp_list.txt" ]; then
    echo "Combining lossless video..."
    ffmpeg -y -nostdin -f concat -safe 0 -i temp_list.txt -c copy "${FIRST_IMG}.mp4" > "$LOG_OUTPUT" 2>&1
    
    echo "Applying final compression pass (${FPS} FPS .mov)..."
    ffmpeg -y -nostdin -i "${FIRST_IMG}.mp4" -r "$FPS" "${FIRST_IMG}_01fps.mov" > "$LOG_OUTPUT" 2>&1
    
    # Cleanup intermediate files
    rm -rf temp_parts temp_list.txt "${FIRST_IMG}.mp4"
    
    echo "Done! Final video saved as: ${FIRST_IMG}_01fps.mov"
else
    echo "Error: No images were processed."
fi
