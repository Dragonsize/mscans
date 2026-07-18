#!/usr/bin/env bash

# Common utilities for CTF Image Analysis

# Initialize global variables
MISSING_TOOLS=()
OUTDIR=""
QUICK=0
image=""
basename=""
PKG_MGR=""
install_cmd_for() {
    local tool="$1"
    local pkg="${PKG_MAP[$tool]:-$tool}"
    case "$PKG_MGR" in
        apt)    echo "sudo apt install -y $pkg" ;;
        dnf|yum) echo "sudo $PKG_MGR install -y $pkg" ;;
        pacman) echo "sudo pacman -S $pkg" ;;
        brew)   echo "brew install $tool" ;;
        *)      echo "Install '$tool' via your package manager" ;;
    esac
}

has() { command -v "$1" &>/dev/null; }

detect_pkg_mgr() {
    if has apt-get; then
        PKG_MGR="apt"
    elif has dnf; then
        PKG_MGR="dnf"
    elif has yum; then
        PKG_MGR="yum"
    elif has pacman; then
        PKG_MGR="pacman"
    elif has brew; then
        PKG_MGR="brew"
    else
        PKG_MGR=""
    fi
}

# Make sure package manager is detected
detect_pkg_mgr