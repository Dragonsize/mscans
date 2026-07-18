#!/usr/bin/env bash

# Phase 1: Basic ID & Metadata

phase1_id_metadata() {
    echo -e "${YELLOW}--- Phase 1: Basic ID & Metadata ---${NC}"
    run "file"      file      file "$image"
    run "exiftool"  exiftool  exiftool "$image"
    run "identify"  identify  identify -verbose "$image"
    run "pngcheck"  pngcheck  pngcheck -v "$image"
    if has xxd; then
        echo -ne "${CYAN}[*]${NC} xxd..."
        xxd "$image" | head -500 > "$outdir/xxd-hex.txt"
        echo -e " ${GREEN}OK${NC}"
    else
        MISSING_TOOLS+=("xxd")
        echo -ne "${CYAN}[*]${NC} xxd..."; echo -e " ${YELLOW}SKIP${NC} (not installed)"
    fi
}