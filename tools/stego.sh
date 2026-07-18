#!/usr/bin/env bash

# Phase 3: Steganography

phase3_steganography() {
    echo -e "${YELLOW}--- Phase 3: Steganography ---${NC}"
    run "binwalk"   binwalk  binwalk "$image"
    run_binwalk_extract
    run "zsteg"     zsteg    zsteg "$image" -a
    run "steghide-info" steghide steghide info -p "" "$image"

    # --- Stegseek (steghide password brute-force) ---
    if has stegseek; then
        echo -ne "${CYAN}[*]${NC} stegseek..."
        stegseek "$image" --seed 2>/dev/null > "$outdir/stegseek.txt" 2>&1
        echo -e " ${GREEN}OK${NC} ($(wc -c < "$outdir/stegseek.txt") bytes)"
    else
        MISSING_TOOLS+=("stegseek")
        echo -ne "${CYAN}[*]${NC} stegseek..."; echo -e " ${YELLOW}SKIP${NC} (not installed)"
    fi
}