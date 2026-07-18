#!/usr/bin/env bash

# Phase 4: QR/Barcodes

phase4_qr_barcodes() {
    echo -e "${YELLOW}--- Phase 4: QR/Barcodes ---${NC}"
    run "zbarimg" zbarimg zbarimg --raw "$image"
}