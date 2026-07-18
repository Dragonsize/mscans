#!/usr/bin/env bash

# Phase 2: Content Extraction

phase2_content_extraction() {
    echo -e "${YELLOW}--- Phase 2: Content Extraction ---${NC}"
    run "strings-8" strings strings "$image"
    run "strings-16" strings strings -el "$image"
    strings "$image" | sort -u > "$outdir/strings-unique.txt" 2>/dev/null || true
}
