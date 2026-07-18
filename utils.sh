#!/usr/bin/env bash

# Common utilities for CTF Image Analysis

MISSING_TOOLS=()
OUTDIR=""
QUICK=0
image=""
basename=""
PKG_MGR=""

has() { command -v "$1" &>/dev/null; }

text_logs() {
    find "$outdir" \
        \( -path "$outdir/binwalk_extract" -o -path "$outdir/binwalk_extract/*" \
        -o -path "$outdir/foremost_out" -o -path "$outdir/foremost_out/*" \) -prune -o \
        -type f -name '*.txt' -print0 2>/dev/null
}

html_escape() {
    sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

generate_report() {
    local report="$outdir/report.html"
    local log relative channel
    local -a channels=()

    {
        cat <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>mscans report</title>
<style>
body{max-width:1100px;margin:2rem auto;padding:0 1rem;background:#111827;color:#e5e7eb;font:15px/1.5 system-ui,sans-serif}h1,h2{color:#f9fafb}details{margin:1rem 0;border:1px solid #374151;border-radius:.4rem;background:#1f2937}summary{padding:.7rem;cursor:pointer;font-weight:600}pre{margin:0;padding:1rem;overflow:auto;white-space:pre-wrap;word-break:break-word;border-top:1px solid #374151}code{color:#a7f3d0}.channels{display:flex;flex-wrap:wrap;gap:1rem}.channels figure{margin:0;max-width:30%}.channels img{display:block;max-width:100%;height:auto;border:1px solid #374151}figcaption{margin-top:.3rem;color:#9ca3af}
</style>
</head>
<body>
EOF
        printf '<h1>mscans report: %s</h1>\n' "$(printf '%s' "$basename" | html_escape)"
        printf '<p>Generated output: <code>%s</code></p>\n' "$(printf '%s' "$(basename "$outdir")" | html_escape)"
        printf '<h2>Tool output</h2>\n'
        while IFS= read -r -d '' log; do
            relative="${log#"$outdir"/}"
            printf '<details><summary>%s</summary><pre>' "$(printf '%s' "$relative" | html_escape)"
            html_escape < "$log"
            printf '</pre></details>\n'
        done < <(text_logs)

        shopt -s nullglob
        channels=("$outdir"/channels/channel_*.png)
        shopt -u nullglob
        if [[ ${#channels[@]} -gt 0 ]]; then
            printf '<h2>RGB channels</h2><div class="channels">\n'
            for channel in "${channels[@]}"; do
                relative="channels/$(basename "$channel")"
                [[ "$relative" =~ ^channels/channel_[0-9]+\.png$ ]] || continue
                relative="$(printf '%s' "$relative" | html_escape)"
                printf '<figure><img src="%s" alt="%s"><figcaption>%s</figcaption></figure>\n' \
                    "$relative" "$relative" "$relative"
            done
            printf '</div>\n'
        fi

        printf '</body></html>\n'
    } > "$report"

    echo -e "${CYAN}[*]${NC} HTML report... ${GREEN}OK${NC} ($(wc -c < "$report") bytes)"
}

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

detect_pkg_mgr
