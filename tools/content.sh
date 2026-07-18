#!/usr/bin/env bash

# Phase 2: Content Extraction

phase2_content_extraction() {
    echo -e "${YELLOW}--- Phase 2: Content Extraction ---${NC}"
    run "strings-8"   strings   strings "$image"
    run "strings-16"  strings   strings -el "$image"
    strings "$image" | sort -u > "$outdir/strings-unique.txt" 2>/dev/null || true
    if has tesseract; then
        echo -ne "${CYAN}[*]${NC} tesseract..."
        mkdir -p "$outdir/ocr-output"
        if tesseract "$image" "$outdir/ocr-output" --quiet; then
            echo -e " ${GREEN}OK${NC}"
        else
            echo -e " ${RED}FAIL${NC}"
        fi
    else
        MISSING_TOOLS+=("tesseract")
        echo -ne "${CYAN}[*]${NC} tesseract..."; echo -e " ${YELLOW}SKIP${NC} (not installed)"
    fi
}