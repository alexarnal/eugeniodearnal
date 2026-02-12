#!/bin/bash

# Image Optimization Script
# Creates optimized versions of images for web use
# Uses macOS built-in 'sips' tool

# Configuration
SOURCE_DIR="images"
OUTPUT_DIR="images-optimized"
THUMB_DIR="${OUTPUT_DIR}/thumbnails"
FULL_DIR="${OUTPUT_DIR}/full"

# Target dimensions (max width/height while maintaining aspect ratio)
THUMB_SIZE=800
FULL_SIZE=1400

# JPEG quality (85 is a good balance - visually identical but much smaller)
QUALITY=85

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Image Optimization Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create output directories
echo -e "${YELLOW}Creating output directories...${NC}"
mkdir -p "$THUMB_DIR"
mkdir -p "$FULL_DIR"

# Count total images
TOTAL_IMAGES=$(find "$SOURCE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | wc -l | tr -d ' ')
echo -e "${GREEN}Found $TOTAL_IMAGES images to process${NC}"
echo ""

# Track sizes
ORIGINAL_SIZE=0
OPTIMIZED_SIZE=0
COUNTER=0

# Process each image
find "$SOURCE_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | while read -r img; do
    COUNTER=$((COUNTER + 1))
    filename=$(basename "$img")

    echo -e "${BLUE}[$COUNTER/$TOTAL_IMAGES] Processing: $filename${NC}"

    # Get original dimensions
    WIDTH=$(sips -g pixelWidth "$img" | tail -1 | awk '{print $2}')
    HEIGHT=$(sips -g pixelHeight "$img" | tail -1 | awk '{print $2}')
    ORIG_SIZE=$(stat -f%z "$img")

    echo "  Original: ${WIDTH}x${HEIGHT} ($(numfmt --to=iec-i --suffix=B $ORIG_SIZE 2>/dev/null || echo "$ORIG_SIZE bytes"))"

    # Create thumbnail (800px max dimension)
    THUMB_OUTPUT="${THUMB_DIR}/${filename}"
    if [ $WIDTH -gt $THUMB_SIZE ] || [ $HEIGHT -gt $THUMB_SIZE ]; then
        sips -Z "$THUMB_SIZE" --setProperty formatOptions "$QUALITY" "$img" --out "$THUMB_OUTPUT" >/dev/null 2>&1
    else
        # Image is already small enough, just copy and optimize quality
        sips --setProperty formatOptions "$QUALITY" "$img" --out "$THUMB_OUTPUT" >/dev/null 2>&1
    fi
    THUMB_SIZE_BYTES=$(stat -f%z "$THUMB_OUTPUT")
    echo -e "  ${GREEN}✓${NC} Thumbnail created ($(numfmt --to=iec-i --suffix=B $THUMB_SIZE_BYTES 2>/dev/null || echo "$THUMB_SIZE_BYTES bytes"))"

    # Create full-size optimized version (1400px max dimension)
    FULL_OUTPUT="${FULL_DIR}/${filename}"
    if [ $WIDTH -gt $FULL_SIZE ] || [ $HEIGHT -gt $FULL_SIZE ]; then
        sips -Z "$FULL_SIZE" --setProperty formatOptions "$QUALITY" "$img" --out "$FULL_OUTPUT" >/dev/null 2>&1
    else
        # Image is already smaller than full size, just optimize quality
        sips --setProperty formatOptions "$QUALITY" "$img" --out "$FULL_OUTPUT" >/dev/null 2>&1
    fi
    FULL_SIZE_BYTES=$(stat -f%z "$FULL_OUTPUT")
    echo -e "  ${GREEN}✓${NC} Full-size created ($(numfmt --to=iec-i --suffix=B $FULL_SIZE_BYTES 2>/dev/null || echo "$FULL_SIZE_BYTES bytes"))"

    echo ""
done

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Optimization Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Show directory sizes
echo "Output directories:"
echo "  Thumbnails: $(du -sh "$THUMB_DIR" | awk '{print $1}')"
echo "  Full-size:  $(du -sh "$FULL_DIR" | awk '{print $1}')"
echo ""
echo "Original images: $(du -sh "$SOURCE_DIR" | awk '{print $1}')"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the optimized images in: $OUTPUT_DIR"
echo "2. Update your HTML to use the optimized images"
echo "3. Keep the original 'images/' folder as a backup"
