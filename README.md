# mscans — CTF Image Analysis Wrapper

Bash wrapper for CTF image triage.

**File → Metadata → Strings → Stego → QR → Forensic extraction → Auto-decode → HTML report**

Missing tools skip cleanly. Every scan writes text logs plus `report.html`.

## Quick Start

```bash
./mscans -q image.png                 # metadata + strings
./mscans image.png                    # full scan
./mscans -f 'FLAG|CTF' image.png      # regex search
./mscans -g LYKNCTF,FTPCTF image.png  # literal contest prefixes
./mscans -i                           # install missing tools
./mscans -o ./results image.png       # custom output directory
```

## Options

| Flag | Description |
|------|-------------|
| `-o DIR` | Output directory (default: `./ctf-image`) |
| `-q` | Metadata and strings phases only |
| `-f REGEX` | Search generated text logs with extended regex |
| `-g PREFIX` | Find literal `PREFIX{...}` flags; comma-separate prefixes |
| `-i` | Install missing tools |
| `-h` | Show help |

## Tool Phases

### Phase 1 — Basic ID & Metadata (always)

| Tool | Purpose |
|------|---------|
| `file` | File type and encoding |
| `exiftool` | EXIF/IPTC/XMP metadata |
| `identify` | Dimensions, bit depth |
| `pngcheck` | PNG integrity and chunks |
| `xxd` | Hex dump |

### Phase 2 — Content Extraction (always)

| Tool | Purpose |
|------|---------|
| `strings` | ASCII and UTF-16 strings |
| `strings | sort -u` | Deduplicated strings for flag scanning |

### Phase 3 — Steganography (full mode)

`binwalk`, `binwalk -e`, `zsteg`, `steghide`, `stegseek`.

### Phase 4 — QR & Barcodes (full mode)

`zbarimg`.

### Phase 5 — Forensic Extraction (full mode)

`foremost`, ImageMagick channel split.

### Phase 6 — Flag Analysis & Auto-Decode (always)

Scans every generated `.txt` log recursively. It detects common CTF flags, searches literal `-g` prefixes, and checks long Base64 and hex candidates for decoded flag text.

## Report

Each scan writes `<outdir>/report.html`. Open it locally to review captured tool logs. In full scans, RGB channel previews appear when the channel split succeeds. The report is static, has no JavaScript or external assets, and HTML-escapes tool output.

## Installation

```bash
./mscans -i
```

`-i` uses your detected package manager and prints manual commands if unavailable. `install.sh` installs the wrapper under `/usr/local/lib/mscans`, links `mscans` into `/usr/local/bin`, then calls `mscans -i`; package inventory stays shared with normal scans.

## Supported OS

- Linux (apt, dnf, yum, pacman)
- macOS (Homebrew)
- Windows through WSL/Cygwin

## License

MIT — Copyright 2026 Dragonsize
