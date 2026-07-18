#!/usr/bin/env bash

# Configuration for CTF Image Analysis

declare -A PKG_MAP
# Default: apt names
PKG_MAP=(
    [exiftool]=libimage-exiftool-perl
    [identify]=imagemagick
    [convert]=imagemagick
    [pngcheck]=pngcheck
    [binwalk]=binwalk
    [zsteg]=ruby-zsteg
    [steghide]=steghide
    [stegseek]=stegseek
    [tesseract]=tesseract-ocr
    [zbarimg]=zbar-tools
    [foremost]=foremost
    [xxd]=xxd
    [strings]=binutils
    [file]=file
)

# Phase definitions
# Quick mode includes
QUICK_PHASES=(
    "file"
    "exiftool"
    "strings"
    "pngcheck"
    "binwalk"
    "xxd"
    "identify"
)

# Full mode phases
FULL_PHASES=(
    "file"
    "exiftool"
    "identify"
    "strings"
    "tesseract"
    "binwalk"
    "zsteg"
    "steghide"
    "stegseek"
    "zbarimg"
    "foremost"
    "convert"
)

# Tool functions for execution
run() {
    local label="$1"
    local cmd="$2"
    shift 2
    local outfile="$outdir/${label}.txt"

    echo -ne "${CYAN}[*]${NC} ${label}..."
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_TOOLS+=("$cmd")
        echo -e " ${YELLOW}SKIP${NC} (not installed)"
        return 0
    fi

    if "$@" > "$outfile" 2>&1; then
        echo -e " ${GREEN}OK${NC} ($(wc -c < "$outfile") bytes)"
    else
        echo -e " ${RED}FAIL${NC}"
    fi
    return 0
}

run_binwalk_extract() {
    echo -ne "${CYAN}[*]${NC} binwalk (extract)..."
    if ! command -v binwalk &>/dev/null; then
        MISSING_TOOLS+=("binwalk")
        echo -e " ${YELLOW}SKIP${NC} (not installed)"
        return 0
    fi
    mkdir -p "$outdir/binwalk_extract"
    if binwalk -e -C "$outdir/binwalk_extract" -- "$image" > "$outdir/binwalk-extract.txt" 2>&1; then
        echo -e " ${GREEN}OK${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
    fi
    return 0
}

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

install_missing() {
    local missing=("$@")
    [[ ${#missing[@]} -eq 0 ]] && { echo "All tools already installed."; return 0; }

    # dedup
    readarray -t uniq < <(printf '%s\n' "${missing[@]}" | sort -u)

    case "$PKG_MGR" in
        apt)
            local pkgs=""
            for t in "${uniq[@]}"; do pkgs+=" ${PKG_MAP[$t]:-$t}"; done
            echo "Installing:${pkgs}"
            sudo apt install -y $pkgs
            ;;
        dnf)
            local pkgs=""
            for t in "${uniq[@]}"; do pkgs+=" ${PKG_MAP[$t]:-$t}"; done
            echo "Installing:${pkgs}"
            sudo dnf install -y $pkgs
            ;;
        yum)
            local pkgs=""
            for t in "${uniq[@]}"; do pkgs+=" ${PKG_MAP[$t]:-$t}"; done
            echo "Installing:${pkgs}"
            sudo yum install -y $pkgs
            ;;
        pacman)
            for t in "${uniq[@]}"; do
                local pkg="${PKG_MAP[$t]:-$t}"
                echo "Installing: ${pkg}"
                sudo pacman -S --noconfirm "$pkg"
            done
            ;;
        brew)
            for t in "${uniq[@]}"; do
                echo "Installing: ${t}"
                brew install "$t"
            done
            ;;
        *)
            echo "No package manager detected. Install manually:"
            for t in "${uniq[@]}"; do
                echo "  $(install_cmd_for "$t")"
            done
            return 1
            ;;
    esac
}

# Color definitions (for imported modules)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'