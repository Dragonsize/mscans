# IMGscans — CTF Image Analysis Wrapper

Bash wrapper chaining forensic tools for CTF image analysis in optimal order.

**File → Metadata → Strings → Binwalk → LSB Stego → Steghide/Stegseek → QR → Foremost → Channel Split → Auto-Decode**

Skips missing tools gracefully with install commands. Quick mode for fast initial triage.

## Quick Start

```bash
# Quick mode — fast tools only (~10s)
./IMGscans -q image.png

# Full analysis — all tools (~1-3 min)
./IMGscans image.png

# Flag search
./IMGscans -f 'FLAG' image.png

# Contest prefix search
./IMGscans -g LYKNCTF,FTPCTF image.png

# Install all missing tools (no image needed)
./IMGscans -i

# Custom output directory
./IMGscans -o ./results image.png
```

## Options

| Flag | Description |
|------|-------------|
| `-o DIR` | Output directory (default: ./ctf-image) |
| `-q` | Quick mode (skip OCR, stego, forensic) |
| `-f REGEX` | Search all outputs for flag pattern |
| `-g PREFIX` | Auto-detect flags per contest prefix (e.g. LYKNCTF,FTPCTF) |
| `-i` | Install all missing tools |
| `-h` | Show help |

## Tool Phases

### Phase 1 — Basic ID & Metadata (always)
| Tool | Purpose |
|------|---------|
| `file` | Detect file type & encoding |
| `exiftool` | EXIF/IPTC/XMP metadata |
| `identify` | Image dimensions, bit depth |
| `pngcheck` | PNG integrity & chunk analysis |
| `xxd` | Hex dump (first 500B) |

### Phase 2 — Content Extraction (always)
| Tool | Purpose |
|------|---------|
| `strings` | ASCII & UTF-16 strings |
| `strings -sort -u` | Deduped strings for flag scanning |
| `tesseract` | OCR visible/recovered text |

### Phase 3 — Steganography (full mode)
| Tool | Purpose |
|------|---------|
| `binwalk` | Find embedded files & signatures |
| `binwalk -e` | Extract embedded files |
| `zsteg` | LSB steganography detection |
| `steghide` | Steghide metadata (empty pass) |
| `stegseek` | **Steghide password brute-force** |

### Phase 4 — QR & Barcodes (full mode)
| Tool | Purpose |
|------|---------|
| `zbarimg` | QR/barcode decoding |

### Phase 5 — Forensic Extraction (full mode)
| Tool | Purpose |
|------|---------|
| `foremost` | File carving from image containers |
| `convert` | RGB channel separation |

### Phase 6 — Flag Analysis & Auto-Decode (always)
Runs after all tool phases. Automatically:

1. **Detects contest-specific flags** via `-g PREFIX` → finds `PREFIX{...}` patterns
2. **Decodes Base64** → finds `[A-Za-z0-9+/]{20,}` strings, decodes, checks for flags
3. **Decodes hex** → finds `[0-9a-fA-F]{40,}` strings, decodes, checks for flags
4. **Detects common CTF patterns** → FLAG{}, CTF{}, picoCTF{}, key{}, lykn{}, interlock{}

## Examples

### Contest-Specific
```bash
./IMGscans -g LYKNCTF image.png
```

### Full Workflow
```bash
# Quick triage
./IMGscans -q challenge.png
grep -n "flag\|CTF\|LYKN" ./ctf-challenge/strings-unique.txt

# Deep analysis if nothing found
./IMGscans -g LYKNCTF challenge.png

# Check stego
cat ./ctf-challenge/stegseek.txt
ls -la ./ctf-challenge/binwalk_extract/
```

## Installation Commands

### Debian/Ubuntu
```bash
# Full toolset (all 12 tools)
sudo apt install -y libimage-exiftool-perl imagemagick pngcheck \
  binwalk ruby-zsteg steghide stegseek tesseract-ocr zbar-tools foremost

# Or use auto-install
./IMGscans -i
```

### RHEL/CentOS
```bash
sudo yum install -y exiftool ImageMagick pngcheck binwalk zsteg steghide tesseract zbar-tools foremost
```

### Fedora
```bash
sudo dnf install -y exiftool ImageMagick pngcheck binwalk zsteg steghide tesseract zbar-tools foremost
```

### macOS
```bash
brew install file exiftool imagemagick binwalk ruby-zsteg steghide tesseract zbar-tools foremost
```

## Supported OS
- **Linux** (Debian/Ubuntu/RHEL/CentOS/Arch)
- **macOS** (brew install)
- **Windows** (WSL/Cygwin)

## License

MIT — Copyright 2026 Dragonsize

## Author
- `nv` <nv@ctf-tools.dev>
