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
