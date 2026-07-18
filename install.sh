#!/usr/bin/env bash

# mscans installer
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

INSTALL_DIR="/usr/local/lib/mscans"
BIN_LINK="/usr/local/bin/mscans"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "$SCRIPT_DIR/mscans" ]] || { echo "Run install.sh from the mscans source directory." >&2; exit 1; }

echo -e "${GREEN}Installing mscans...${NC}"
echo "Creating ${INSTALL_DIR}..."
sudo mkdir -p "$INSTALL_DIR/tools"

echo "Copying files..."
sudo cp "$SCRIPT_DIR/mscans" "$SCRIPT_DIR/config.sh" "$SCRIPT_DIR/utils.sh" "$SCRIPT_DIR/analyze.sh" "$INSTALL_DIR/"
sudo cp "$SCRIPT_DIR/tools/"*.sh "$INSTALL_DIR/tools/"
sudo chmod +x "$INSTALL_DIR/mscans" "$INSTALL_DIR/tools/"*.sh

echo "Creating symlink ${BIN_LINK}..."
sudo ln -sf "$INSTALL_DIR/mscans" "$BIN_LINK"

echo -e "${YELLOW}Installing missing dependencies...${NC}"
"$BIN_LINK" -i || echo "(some packages may not be available; see missing-tool commands above)"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  mscans installed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Usage: mscans [OPTIONS] <image>"
echo "       mscans -i   (install missing tools)"
echo ""
echo "Location: ${BIN_LINK}"
echo "Modules:  ${INSTALL_DIR}/"
