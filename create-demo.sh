#!/usr/bin/env bash
# Create mscans demo fixtures. Run: bash create-demo.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEMO="$ROOT/demo"

need() {
    command -v "$1" >/dev/null || {
        echo "$1 required" >&2
        exit 1
    }
}

need python3
need steghide

if command -v qrencode >/dev/null; then
    QR_TOOL=qrencode
elif python3 -c 'import qrcode' >/dev/null 2>&1; then
    QR_TOOL=python-qrcode
else
    echo "qrencode or Python qrcode module required" >&2
    exit 1
fi

if command -v convert >/dev/null; then
    IMAGE_TOOL=convert
elif command -v magick >/dev/null; then
    IMAGE_TOOL=magick
else
    echo "ImageMagick (convert or magick) required" >&2
    exit 1
fi

mkdir -p "$DEMO"

python3 - "$DEMO" <<'PY'
import binascii
import struct
import sys
import zlib
import zipfile
from pathlib import Path

out = Path(sys.argv[1])

def chunk(kind, data):
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", binascii.crc32(kind + data) & 0xffffffff)
    )

def png(path, width, height, pixels, text=()):
    raw = b"".join(
        b"\x00" + pixels[row * width * 3:(row + 1) * width * 3]
        for row in range(height)
    )
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    for key, value in text:
        data += chunk(b"tEXt", key.encode("ascii") + b"\0" + value)
    data += chunk(b"IDAT", zlib.compress(raw, 9))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)

def rgb(width=64, height=64):
    return bytes(
        channel
        for y in range(height)
        for x in range(width)
        for channel in (x * 4 % 256, y * 4 % 256, (x + y) * 2 % 256)
    )

utf16 = "CTF{demo_utf16_strings}".encode("utf-16le")
b64 = b"Q1RGe2RlbW9fYmFzZTY0fQ=="  # CTF{demo_base64}
hexflag = b"4354467b64656d6f5f6865787d"  # CTF{demo_hex}
png(out / "basic-strings-rgb.png", 64, 64, rgb(), [
    ("Comment", b"mscans demo metadata"),
    ("RawFlag", b"CTF{demo_strings_raw}"),
    ("UTF16", utf16),
    ("Base64", b64),
    ("Hex", hexflag),
])

archive = out / "embedded-archive.png"
png(archive, 32, 32, rgb(32, 32), [("Comment", b"PNG with appended ZIP")])
zip_path = out / ".payload.zip"
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_STORED) as zf:
    info = zipfile.ZipInfo("flag.txt", (2026, 1, 1, 0, 0, 0))
    info.external_attr = 0o100644 << 16
    zf.writestr(info, "CTF{demo_embedded_archive}\n")
archive.write_bytes(archive.read_bytes() + zip_path.read_bytes())
zip_path.unlink()

# zsteg carrier: b1,r,lsb,xy starts with printable text and NUL terminator.
message = b"CTF{demo_zsteg_lsb}\0"
width = height = 64
pixels = bytearray(rgb(width, height))
bits = [(byte >> shift) & 1 for byte in message for shift in range(7, -1, -1)]
for index, bit in enumerate(bits):
    pixels[index * 3] = (pixels[index * 3] & 0xfe) | bit
png(out / "zsteg-lsb.png", width, height, bytes(pixels), [("Comment", b"LSB demo")])

(out / "stegseek-wordlist.txt").write_text(
    "wrong-password\ndemo-password\n", encoding="ascii"
)
PY

# Large high-detail carrier prevents steghide's "cover file too short" error.
"$IMAGE_TOOL" -size 1024x768 plasma:fractal -quality 92 "$DEMO/.carrier.jpg"
printf 'CTF{demo_steghide}\n' > "$DEMO/.steghide-flag.txt"
steghide embed \
    -cf "$DEMO/.carrier.jpg" \
    -ef "$DEMO/.steghide-flag.txt" \
    -sf "$DEMO/steghide-secret.jpg" \
    -p demo-password \
    -f
rm -f "$DEMO/.carrier.jpg" "$DEMO/.steghide-flag.txt"

if [[ "$QR_TOOL" == qrencode ]]; then
    qrencode -o "$DEMO/qr-message.png" -s 8 -m 4 -l L 'CTF{demo_qr_payload}'
else
    python3 - "$DEMO/qr-message.png" <<'PY'
import qrcode
import sys
qr = qrcode.QRCode(version=2, error_correction=qrcode.constants.ERROR_CORRECT_L, box_size=8, border=4)
qr.add_data("CTF{demo_qr_payload}")
qr.make(fit=False)
qr.make_image(fill_color="black", back_color="white").save(sys.argv[1])
PY
fi

cat > "$DEMO/README.md" <<'EOF'
# mscans Demo Fixtures

Run from repository root. Send scan output to `/tmp`.

```bash
./mscans -q -o /tmp/mscans-demo/basic demo/basic-strings-rgb.png
./mscans -o /tmp/mscans-demo/archive demo/embedded-archive.png
./mscans -o /tmp/mscans-demo/zsteg demo/zsteg-lsb.png
./mscans -o /tmp/mscans-demo/steghide demo/steghide-secret.jpg
./mscans -o /tmp/mscans-demo/qr demo/qr-message.png
stegseek demo/steghide-secret.jpg demo/stegseek-wordlist.txt
```

| Fixture | Covers | Expected marker |
| --- | --- | --- |
| `basic-strings-rgb.png` | file, metadata, strings, RGB channels, Base64/hex decode | `CTF{demo_strings_raw}`, `CTF{demo_utf16_strings}`, `CTF{demo_base64}`, `CTF{demo_hex}` |
| `embedded-archive.png` | binwalk extraction, foremost carving | `flag.txt`: `CTF{demo_embedded_archive}` |
| `zsteg-lsb.png` | zsteg `b1,r,lsb,xy` | `CTF{demo_zsteg_lsb}` |
| `steghide-secret.jpg` | steghide, stegseek | `CTF{demo_steghide}`; password `demo-password` |
| `qr-message.png` | zbarimg | `CTF{demo_qr_payload}` |

Full scans run every tool on every image. PNG-only tools can fail on JPEG; `steghide` does not support PNG. Tool output differs by version. Check logs and `report.html`, not exact text.
EOF

printf 'Demo fixtures created in %s\n' "$DEMO"
