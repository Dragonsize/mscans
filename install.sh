#!/usr/bin/env bash

# mscans installer
# Installs mscans to /usr/local/bin like nmap

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

INSTALL_DIR="/usr/local/bin/mscans"
BIN_LINK="/usr/local/bin/mscans"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}Installing mscans...${NC}"

# Create install directory
echo "Creating ${INSTALL_DIR}..."
sudo mkdir -p "$INSTALL_DIR/tools"

# Copy files
echo "Copying files..."
sudo cp "$SCRIPT_DIR/mscans" "$INSTALL_DIR/mscans"
sudo cp "$SCRIPT_DIR/config.sh" "$INSTALL_DIR/config.sh"
sudo cp "$SCRIPT_DIR/utils.sh" "$INSTALL_DIR/utils.sh"
sudo cp "$SCRIPT_DIR/analyze.sh" "$INSTALL_DIR/analyze.sh"
sudo cp "$SCRIPT_DIR/tools/"*.sh "$INSTALL_DIR/tools/"

# Make executable
sudo chmod +x "$INSTALL_DIR/mscans"
sudo chmod +x "$INSTALL_DIR/tools/"*.sh

# Create symlink
echo "Creating symlink ${BIN_LINK}..."
sudo ln -sf "$INSTALL_DIR/mscans" "$BIN_LINK"

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
if command -v apt-get &>/dev/null; then
    sudo apt-get install -y file strings xxd binwalk stegseek steghide zsteg tesseract-ocr zbar-tools foremost imagemagick libimage-exiftool-perl pngcheck ruby-zsteg 2>/dev/null || echo "(some packages may not be available)"
elif command -v dnf &>/dev/null; then
    sudo dnf install -y file binutils xxd binwalk steghide tesseract zbar-tools foremost ImageMagick exiftool pngcheck 2>/dev/null || echo "(some packages may not be available)"
elif command -v yum &>/dev/null; then
    sudo yum install -y file binutils xxd binwalk steghide tesseract zbar-tools foremost ImageMagick exiftool pngcheck 2>/dev/null || echo "(some packages may not be available)"
elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm file binutils xxd binwalk steghide tesseract zbar-tools foremost imagemagick perl-image-exiftool pngcheck 2>/dev/null || echo "(some packages may not be available)"
elif command -v brew &>/dev/null; then
    brew install file binutils xxd binwalk steghide tesseract zbar-tools foremost imagemagick exiftool pngcheck 2>/dev/null || echo "(some packages may not be available)"
else
    echo "No package manager found. Install manually."
fi

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