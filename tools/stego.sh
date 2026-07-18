#!/usr/bin/env bash

# Phase 3: Steganography

phase3_steganography() {
    echo -e "${YELLOW}--- Phase 3: Steganography ---${NC}"
    run "binwalk"   binwalk  binwalk "$image"
    run_binwalk_extract
    run "zsteg"     zsteg    zsteg "$image" -a
    run "steghide-info" steghide steghide info -p "" "$image"

    run "stegseek" stegseek stegseek "$image" --seed
}