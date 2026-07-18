#!/usr/bin/env bash

# Configuration for CTF Image Analysis

declare -A PKG_MAP=(
    [exiftool]=libimage-exiftool-perl
    [identify]=imagemagick
    [convert]=imagemagick
    [pngcheck]=pngcheck
    [binwalk]=binwalk
    [zsteg]=ruby-zsteg
    [steghide]=steghide
    [stegseek]=stegseek
    [zbarimg]=zbar-tools
    [foremost]=foremost
    [xxd]=xxd
    [strings]=binutils
    [file]=file
)

package_for() {
    local tool="$1"
    case "$PKG_MGR" in
        apt) echo "${PKG_MAP[$tool]:-$tool}" ;;
        dnf|yum)
            case "$tool" in
                exiftool) echo exiftool ;;
                identify|convert) echo ImageMagick ;;
                zbarimg) echo zbar-tools ;;
                strings) echo binutils ;;
                *) echo "$tool" ;;
            esac
            ;;
        pacman)
            case "$tool" in
                exiftool) echo perl-image-exiftool ;;
                identify|convert) echo imagemagick ;;
                strings) echo binutils ;;
                *) echo "$tool" ;;
            esac
            ;;
        brew)
            case "$tool" in
                exiftool) echo exiftool ;;
                identify|convert) echo imagemagick ;;
                strings) echo binutils ;;
                *) echo "$tool" ;;
            esac
            ;;
        *) echo "$tool" ;;
    esac
}

install_cmd_for() {
    local tool="$1"
    local package
    package=$(package_for "$tool")
    case "$PKG_MGR" in
        apt) echo "sudo apt install -y $package" ;;
        dnf|yum) echo "sudo $PKG_MGR install -y $package" ;;
        pacman) echo "sudo pacman -S $package" ;;
        brew) echo "brew install $package" ;;
        *) echo "Install '$tool' via your package manager" ;;
    esac
}

run() {
    local label="$1"
    local cmd="$2"
    shift 2
    local outfile="$outdir/${label}.txt"

    echo -ne "${CYAN}[*]${NC} ${label}..."
    if ! has "$cmd"; then
        MISSING_TOOLS+=("$cmd")
        echo -e " ${YELLOW}SKIP${NC} (not installed)"
        return 0
    fi

    if "$@" > "$outfile" 2>&1; then
        echo -e " ${GREEN}OK${NC} ($(wc -c < "$outfile") bytes)"
    else
        echo -e " ${RED}FAIL${NC}"
    fi
}

run_binwalk_extract() {
    echo -ne "${CYAN}[*]${NC} binwalk (extract)..."
    if ! has binwalk; then
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
}

install_missing() {
    local -a missing=("$@")
    local -a uniq=() packages=()
    local tool package

    [[ ${#missing[@]} -eq 0 ]] && { echo "All tools already installed."; return 0; }
    readarray -t uniq < <(printf '%s\n' "${missing[@]}" | sort -u)

    case "$PKG_MGR" in
        apt|dnf|yum)
            for tool in "${uniq[@]}"; do
                packages+=("$(package_for "$tool")")
            done
            echo "Installing: ${packages[*]}"
            sudo "$PKG_MGR" install -y "${packages[@]}"
            ;;
        pacman)
            for tool in "${uniq[@]}"; do
                packages+=("$(package_for "$tool")")
            done
            echo "Installing: ${packages[*]}"
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        brew)
            for tool in "${uniq[@]}"; do
                packages+=("$(package_for "$tool")")
            done
            echo "Installing: ${packages[*]}"
            brew install "${packages[@]}"
            ;;
        *)
            echo "No package manager detected. Install manually:"
            for tool in "${uniq[@]}"; do
                echo "  $(install_cmd_for "$tool")"
            done
            return 1
            ;;
    esac
}

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
