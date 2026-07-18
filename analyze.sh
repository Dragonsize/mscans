#!/usr/bin/env bash

# Phase 6: Flag Analysis & Auto-Decode

decode_base64() {
    local input="$1"
    echo "$input" | grep -a -o '([A-Za-z0-9+/]{20,}=*)' | tr -d '\n' | while read -r b64; do
        echo "$b64" | base64 -d 2>/dev/null || echo ""
    done | grep -E 'FLAG{.*}|CTF{.*}|picoCTF{.*}|key{.*}|lykn{.*}|interlock{.*}|.*\{[0-9a-zA-Z]{10,}\}'
}

decode_hex() {
    local input="$1"
    echo "$input" | grep -o '\(hex[\: ]*[0-9a-fA-F]{20,}\|[0-9a-fA-F]{40,}\)' | tr '[:upper:]' '[:lower:]' | while read -r hexdump; do
        local hex="${hex#hex[ ]*}"
        hex="${hex#hex:*}"
        echo "$hexdump" | xxd -r -p 2>/dev/null || echo ""
    done | grep -E 'FLAG{.*}|CTF{.*}|picoCTF{.*}|key{.*}|lykn{.*}|interlock{.*}|.*\{[0-9a-zA-Z]{10,}\}'
}

grep_for() {
    local pattern="$1"
    echo ""
    echo -e "${YELLOW}=== Flag search (prefix): ${pattern} ===${NC}"
    grep -rniE "$pattern{.*}" "$outdir/" 2>/dev/null | head -50 || echo "(no matches)"
}

analyze_content() {
    echo -e "${YELLOW}--- Phase 6: Flag Analysis & Auto-Decode ---${NC}"

    # Priority 1: Contest prefix detection (from -g)
    if [[ -n "${PREFIX:-}" ]]; then
        echo -e "${CYAN}[*]${NC} Contest prefix detection: ${PREFIX}"
        local prefix_list="$PREFIX"
        local contest_flags=""
        for p in $(echo "$prefix_list" | tr ',' ' '); do
            local escaped=$(sed 's/[\[\]/\\&/g' <<<"$p")
            contest_flags+="${contest_flags:+ }\\(\\b${escaped}{[0-9a-zA-Z\\s\\f\\r\\t:\\/\\.\\\\$\\?\\*\\[\\]\\(\\)\\{\\\\|\\}\\\\*\\|\\'\\\"\\\*),.{1,}\\\)"
        done
        local raw_flags=$(grep -hE "${contest_flags## }" "$outdir/"/*.txt 2>/dev/null | grep -v "^====")
        if [[ -n "$raw_flags" ]]; then
            echo -e "${GREEN}Flags matching prefixes:${NC}"
            echo "$raw_flags" | head -20
            echo ""
        fi
    fi

    # Priority 2: Decode Base64
    echo -e "${CYAN}[*]${NC} Base64 auto-decode..."
    local all_strings=$(cat "$outdir/"/*.txt 2>/dev/null | tr '\n' ' ' | tr '\r' ' ')
    local base64_found=$(echo "$all_strings" | grep -aE '[A-Za-z0-9+/]{20,}=*?' | head -20)
    if [[ -n "$base64_found" ]]; then
        echo -e "${GREEN}Decoded Base64:${NC}"
        echo "$base64_found" | decode_base64 | head -15
        echo ""
    fi

    # Priority 3: Hex decoding
    echo -e "${CYAN}[*]${NC} Hex auto-decode..."
    local hex_found=$(echo "$all_strings" | grep -aE '[0-9a-fA-F]{40,}')
    if [[ -n "$hex_found" ]]; then
        echo -e "${GREEN}Decoded hex:${NC}"
        echo "$hex_found" | decode_hex | head -15
        echo ""
    fi

    # Priority 4: Common CTF patterns (as fallback)
    echo -e "${CYAN}[*]${NC} CTF flag patterns..."
    local flag_patterns='FLAG{.*}|CTF{.*}|picoCTF{.*}|key{.*}|lykn{.*}|interlock{.*}'
    local flags=$(grep -hE -n "$flag_patterns" "$outdir/"/*.txt 2>/dev/null || true)
    if [[ -n "$flags" ]]; then
        echo -e "${GREEN}Common flags:${NC}"
        echo "$flags" | grep -v "^===" | head -15
        echo ""
    fi

    # Summary
    echo -e "${CYAN}[*]${NC} Analysis complete."
    return 0
}

search_flag() {
    local pattern="$1"
    echo ""
    echo -e "${YELLOW}=== Flag search: ${pattern} ===${NC}"
    grep -rniE "$pattern" "$outdir/" 2>/dev/null | head -50 || echo "(no matches)"
}