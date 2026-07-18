#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_contains() { grep -Fq -- "$2" "$1" || fail "missing '$2' in $1"; }

for option in -o -f -g; do
    if "$ROOT/mscans" "$option" >/dev/null 2>&1; then
        fail "$option accepted missing value"
    fi
done
"$ROOT/mscans" -h >/dev/null

mkdir -p "$TMP/bin"
cat > "$TMP/bin/strings" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '<script>alert(1)</script>' \
  'RkxBR3tiNjRfd29ya3NfMTIzNDU2Nzg5fQ==' \
  'Q1RGe2I2NF9zZWNvbmRfMTIzNDU2Nzg5fQ==' \
  '464c41477b6865785f776f726b735f3132333435363738397d' \
  '4354467b6865785f7365636f6e645f3132333435363738397d' \
  'LYKNCTF{literal_prefix}'
EOF
chmod +x "$TMP/bin/strings"

printf '\211PNG\r\n\032\n' > "$TMP/image.png"
PATH="$TMP/bin:$PATH" "$ROOT/mscans" -q -g LYKNCTF -o "$TMP/out" "$TMP/image.png" > "$TMP/run.txt" 2>&1

[[ ! -e "$TMP/out/ocr-output" && ! -e "$TMP/out/ocr-output.txt" ]] || fail "OCR artifact exists"
[[ -f "$TMP/out/report.html" ]] || fail "report missing"
assert_contains "$TMP/run.txt" 'FLAG{b64_works_123456789}'
assert_contains "$TMP/run.txt" 'CTF{b64_second_123456789}'
assert_contains "$TMP/run.txt" 'FLAG{hex_works_123456789}'
assert_contains "$TMP/run.txt" 'CTF{hex_second_123456789}'
assert_contains "$TMP/run.txt" 'LYKNCTF{literal_prefix}'
assert_contains "$TMP/out/report.html" '&lt;script&gt;alert(1)&lt;/script&gt;'
if grep -Fq '<script>alert(1)</script>' "$TMP/out/report.html"; then
    fail "report contains executable log markup"
fi

mkdir -p "$TMP/out/nested" "$TMP/out/channels"
printf 'CTF{nested_log}\nA.B{literal_prefix}\n' > "$TMP/out/nested/finding.txt"
printf 'png' > "$TMP/out/channels/channel_0.png"
source "$ROOT/utils.sh"
source "$ROOT/config.sh"
source "$ROOT/analyze.sh"
outdir="$TMP/out"
basename='report-test'
generate_report >/dev/null
grep_for 'nested_log' > "$TMP/regex.txt"
search_prefixes 'A.B' > "$TMP/prefix.txt"
assert_contains "$TMP/regex.txt" 'nested/finding.txt'
assert_contains "$TMP/prefix.txt" 'A.B{literal_prefix}'
assert_contains "$TMP/out/report.html" 'nested/finding.txt'
assert_contains "$TMP/out/report.html" 'channels/channel_0.png'

bash -n "$ROOT/mscans" "$ROOT/utils.sh" "$ROOT/config.sh" "$ROOT/analyze.sh" "$ROOT/install.sh" "$ROOT/tools/"*.sh
echo "tests passed"
