# Tool Chain Reference

`mscans` runs low-cost, non-destructive checks first, then optional stego and forensic tools.

## Phase 1: Basic Analysis

| Tool | Command | Output |
|------|---------|--------|
| `file` | `file image.png` | File type and encoding |
| `exiftool` | `exiftool image.png` | Metadata |
| `identify` | `identify -verbose image.png` | Dimensions and color space |
| `pngcheck` | `pngcheck -v image.png` | PNG chunk/integrity data |
| `xxd` | `xxd image.png | head -500` | Hex dump |

Always included, including quick mode.

## Phase 2: Content Discovery

| Tool | Command | Output |
|------|---------|--------|
| `strings` | `strings image.png` | ASCII strings |
| `strings -el` | `strings -el image.png` | UTF-16 strings |
| `strings | sort -u` | `strings-unique.txt` | Deduplicated strings |

Always included, including quick mode. OCR is intentionally excluded; inspect visible image text directly.

## Phase 3: Steganography

Full mode only:

- `binwalk` and `binwalk -e` for embedded content
- `zsteg` for PNG LSB checks
- `steghide` metadata
- `stegseek` for steghide passwords

## Phase 4: QR and Barcodes

Full mode only: `zbarimg --raw image.png`.

## Phase 5: Forensic Extraction

Full mode only:

- `foremost` for file carving
- ImageMagick `convert` for RGB-channel separation

## Phase 6: Flag Analysis

Always runs after tool phases. It recursively scans generated text logs, not arbitrary extracted binaries.

1. `-g PREFIX1,PREFIX2` searches literal `PREFIX{...}` patterns. Prefixes are not regex.
2. Long Base64 candidates are decoded individually and checked for standard flag patterns.
3. Long hex candidates are decoded individually and checked for standard flag patterns.
4. Standard patterns include `FLAG{}`, `CTF{}`, `picoCTF{}`, `key{}`, `lykn{}`, and `interlock{}`.
5. `-f REGEX` remains an extended-regex search over generated text logs.

## HTML Report

Every scan generates `<outdir>/report.html` after analysis. It contains collapsible, HTML-escaped text logs. When full-mode RGB splitting succeeds, it includes relative previews for `channels/channel_*.png`. It has no JavaScript, external assets, or previews for arbitrary extracted files.

## Quick Mode

`-q` runs phases 1, 2, and 6 only. Full mode also runs phases 3–5.

## Dependencies

`mscans -i` checks `file`, `exiftool`, ImageMagick (`identify`, `convert`), `pngcheck`, `binwalk`, `zsteg`, `steghide`, `stegseek`, `zbarimg`, `foremost`, `xxd`, and `strings`. Package names vary by platform; use `-i` for mapped install commands.

## Troubleshooting

| Tool | Common issue | Solution |
|------|--------------|----------|
| `zsteg` | JPEG input | Primarily supports PNG |
| `steghide` | Empty password fails | Try `stegseek` |
| `stegseek` | Package unavailable | Install from supported repo or build upstream |
| `zbarimg` | Code too small | Try a larger source image |

*Last updated: July 18, 2026*
