#!/usr/bin/env bash

# Phase 6: Flag Analysis & Auto-Decode

FLAG_PATTERN='FLAG\{[^}]*\}|CTF\{[^}]*\}|picoCTF\{[^}]*\}|key\{[^}]*\}|lykn\{[^}]*\}|interlock\{[^}]*\}|[[:alnum:]_]+\{[[:alnum:]_:-]{10,}\}'

log_matches() {
    local pattern="$1"
    local log
    while IFS= read -r -d '' log; do
        grep -aHnE -- "$pattern" "$log" || true
    done < <(text_logs)
}

log_candidates() {
    local pattern="$1"
    local log
    while IFS= read -r -d '' log; do
        grep -aohE -- "$pattern" "$log" || true
    done < <(text_logs)
}

decode_base64() {
    local b64 decoded
    while IFS= read -r b64; do
        decoded=$(printf '%s' "$b64" | base64 -d 2>/dev/null) || continue
        grep -aE -- "$FLAG_PATTERN" <<<"$decoded" || true
    done
}

decode_hex() {
    local hexdump decoded
    while IFS= read -r hexdump; do
        decoded=$(printf '%s' "$hexdump" | xxd -r -p 2>/dev/null) || continue
        grep -aE -- "$FLAG_PATTERN" <<<"$decoded" || true
    done
}

print_matches() {
    local title="$1"
    local matches="$2"
    local limit="${3:-50}"
    echo ""
    echo -e "${YELLOW}=== ${title} ===${NC}"
    if [[ -n "$matches" ]]; then
        head -n "$limit" <<<"$matches"
    else
        echo "(no matches)"
    fi
}

grep_for() {
    local pattern="$1"
    local matches
    matches=$(log_matches "$pattern")
    print_matches "Flag search: ${pattern}" "$matches"
}

search_prefixes() {
    local prefix_list="$1"
    local prefix matches
    IFS=',' read -r -a prefixes <<<"$prefix_list"
    for prefix in "${prefixes[@]}"; do
        [[ -z "$prefix" ]] && continue
        matches=$(log_matches "$(printf '%s' "$prefix{" | sed 's/[][\\.^$*+?(){}|]/\\&/g')[^}]*\\}")
        print_matches "Flag search (prefix): ${prefix}" "$matches" 20
    done
}

analyze_content() {
    local base64_found hex_found flags

    echo -e "${YELLOW}--- Phase 6: Flag Analysis & Auto-Decode ---${NC}"

    if [[ -n "${PREFIX:-}" ]]; then
        echo -e "${CYAN}[*]${NC} Contest prefix detection: ${PREFIX}"
        search_prefixes "$PREFIX"
    fi

    echo -e "${CYAN}[*]${NC} Base64 auto-decode..."
    base64_found=$(log_candidates '[A-Za-z0-9+/]{20,}={0,2}' | decode_base64)
    if [[ -n "$base64_found" ]]; then
        echo -e "${GREEN}Decoded Base64:${NC}"
        head -15 <<<"$base64_found"
        echo ""
    fi

    echo -e "${CYAN}[*]${NC} Hex auto-decode..."
    hex_found=$(log_candidates '[[:xdigit:]]{40,}' | decode_hex)
    if [[ -n "$hex_found" ]]; then
        echo -e "${GREEN}Decoded hex:${NC}"
        head -15 <<<"$hex_found"
        echo ""
    fi

    echo -e "${CYAN}[*]${NC} CTF flag patterns..."
    flags=$(log_matches "$FLAG_PATTERN")
    if [[ -n "$flags" ]]; then
        echo -e "${GREEN}Common flags:${NC}"
        head -15 <<<"$flags"
        echo ""
    fi

    echo -e "${CYAN}[*]${NC} Analysis complete."
}

search_flag() {
    grep_for "$1"
}
