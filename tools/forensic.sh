#!/usr/bin/env bash

# Phase 5: Forensic Extraction

phase5_forensic_extraction() {
    echo -e "${YELLOW}--- Phase 5: Forensic Extract ---${NC}"
    run "foremost" foremost foremost -i "$image" -o "$outdir/foremost_out" -t all
    if has convert; then
        echo -ne "${CYAN}[*]${NC} channel-split..."
        mkdir -p "$outdir/channels"
        if convert "$image" -channel RGB -separate "$outdir/channels/channel_%d.png" 2>/dev/null; then
            echo -e " ${GREEN}OK${NC}"
        else
            echo -e " ${RED}FAIL${NC}"
        fi
    else
        MISSING_TOOLS+=("convert")
        echo -ne "${CYAN}[*]${NC} channel-split..."; echo -e " ${YELLOW}SKIP${NC} (not installed)"
    fi
}