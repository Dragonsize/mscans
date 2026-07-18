# Tool Chain Reference

Documentation of CTF image analysis tool chain order and dependencies.

## Why This Order Matters

CTF image challenges follow predictable patterns. The chain is ordered by:

1. **Low-hanging fruit first** — catch obvious flags fast
2. **Least destructive first** — don't modify image until needed
3. **Data flow** — each tool's output informs the next

---

## Phase 1: Basic Analysis

### Purpose
- Detect what you're dealing with
- Extract all visible metadata
- Identify format anomalies

### Tools

| Tool | Command | Output | Why First? |
|------|---------|--------|-----------|
| `file` | `file image.png` | File type, encoding | Identifies if file matches its extension |
| `exiftool` | `exiftool image.png` | EXIF, IPTC, XMP metadata | Non-destructive metadata extraction |
| `identify` | `identify -verbose image.png` | Dimensions, bit depth, color space | Image format details |
| `pngcheck` | `pngcheck -v image.png` | PNG integrity, chunk analysis | Catches corruption, invalid CRC |
| `xxd` | `xxd image.png \| head -500` | Hex dump | Visual pattern detection |

### Common Findings
- File type mismatches (PNG header but JPEG content)
- Hidden EXIF fields (GPS, camera, comments)
- Corrupted chunks or invalid CRC
- Hex patterns (magic numbers, embedded strings)

### Quick Mode
This phase is **always included** in `-q` mode.

---

## Phase 2: Content Discovery

### Purpose
- Extract all text/ASCII content from binary data
- Detect visible text needing OCR

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `strings` | `strings image.png` | ASCII strings (8+ chars) | Primary flag discovery method |
| `strings -el` | `strings -el image.png` | UTF-16 strings | Catches non-ASCII flags |
| `strings \| sort -u` | Unique strings | Deduplicated output | For flag scanning |
| `tesseract` | `tesseract image.png output` | OCR text | Extracts text written on image |

### Common Findings
- Flag patterns: `FLAG{...}`, `CTF{...}`, `LYKN{...}`
- Base64 encoded strings
- URLs, IPs, file paths
- Hidden comments or notes

### Why Before Stego?
Strings extraction catches **90%+ of flags** in simple challenges. Don't waste time on steganography until strings are reviewed.

### Quick Mode
`tesseract` is **only in full mode** (slow). Strings always included.

---

## Phase 3: Steganography

### Purpose
- Detect hidden data embedded in image pixels
- Extract embedded files
- Analyze LSB steganography

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `binwalk` | `binwalk image.png` | Embedded file signatures | Finds embedded archives, images |
| `binwalk -e` | `binwalk -e image.png` | Extracted files | Pulls out embedded content |
| `zsteg` | `zsteg image.png -a` | LSB steganography analysis | Detects hidden bits in pixels |
| `steghide` | `steghide info -p "" image.png` | Steghide metadata | Password-protected stego files |
| **`stegseek`** | `stegseek image.png --seed` | **Steghide password brute-force** | **Finds real passwords for steghide** |

### Why Stegseek Matters
Steghide is the most common CTF steganography format. Only tries empty password by default — misses most challenges. Stegseek performs intelligent password brute-forcing:

```bash
# With stegseek: finds password "ctf123"
stegseek image.png --seed
# Output: stegseek.txt shows discovered password

# Then use it:
steghide extract -p "ctf123" -f image.png
```

### Why After Content Discovery?
Steganography tools are:
- **Slower** (analysis takes time)
- **More false positives** (binwalk finds junk)
- **Destructive** (extracted files need management)

### Quick Mode
This phase is **only in full mode** (slow but comprehensive).

---

## Phase 4: QR/Barcodes

### Purpose
- Decode visual data (QR, barcodes)

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `zbarimg` | `zbarimg --raw image.png` | QR/barcode content | Visual encoding used for flags |

### Common Findings
- QR codes with base64 or flag data
- Barcodes encoding numbers/letters

---

## Phase 5: Forensic Extraction

### Purpose
- Extract files from image containers
- Split color channels for analysis

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `foremost` | `foremost -i image.png -o out -t all` | Carved files | File carving for deleted content |
| `convert` | `convert image.png -channel RGB -separate channels_%d.png` | Channel separation | Isolate red/green/blue channels |

### Common Findings
- Deleted file remnants
- Channel-specific hidden patterns
- File fragments (JPG, ZIP, etc.)

---

## Phase 6: Flag Analysis & Auto-Decode

### Purpose
- Intelligently detect and decode hidden flag content
- Automatically decode common encodings
- Find contest-specific flags

### Priority 1: Contest Prefix Detection (`-g`)

When using `-g PREFIX1,PREFIX2`:

```bash
./mscans -g LYKNCTF,FTPCTF image.png
```

The script searches all extracted strings for `PREFIX{...}` patterns — far more precise than generic regex.

### Priority 2: Base64 Decoding

Scans all outputs for long base64 strings (20+ chars), decodes them, and checks for flags:

```bash
# Finds: SGVsbG8gd29ybGQ=
# Decodes to: Hello world
# Checks decoded text for flags
```

### Priority 3: Hex Decoding

Finds hex strings (40+ hex chars), converts to text/bytes, checks for flags:

```bash
# Finds: 48454c4c4f20464c4147
# Decodes to: HELLO FLAG
# Checks for flag patterns
```

### Priority 4: Common CTF Patterns

Falls back to searching for standard CTF formats:
- `FLAG{...}` — most common format
- `CTF{...}` — contest-specific
- `picoCTF{...}` — picoCTF platform
- `key{...}` — key discovery format
- `lykn{...}`, `interlock{...}` — contest-specific

---

## Performance Notes

| Phase | Typical Time | Speed Factor |
|-------|-------------|--------------|
| Phase 1 | < 1 second | Very fast |
| Phase 2 | 1-3 seconds | Fast (tesseract: 5-10s) |
| Phase 3 | 5-30 seconds | Medium (stegseek: moderate) |
| Phase 4 | 1-3 seconds | Fast |
| Phase 5 | 3-10 seconds | Medium (foremost varies) |
| **Phase 6** | **< 1 second** | **Very fast (string search + decode)** |

**Total**: Quick ~5-15s, Full ~15-60s, plus Phase 6 (~1s)

---

## Optimization Tips

### For Speed
- Use `-q` for initial investigation
- Run in background: `./mscans -q file.png &`
- Focus on strings-unique.txt first
- Check stegseek.txt for found passwords

### For Accuracy
- Use `-g` with your contest prefix(s)
- Always check Phase 6 output for auto-decoded flags
- Review binwalk_extract/ before stego tools
- Cross-reference multiple tools' outputs

### For Large Files
- Quick mode essential for large images
- Consider resizing: `convert image.png -resize 800x600 small.png`
- Run in background and check later

### For Steganography
- Focus on `binwalk -e` and `zsteg` first
- Check all extracted files in `binwalk_extract/`
- Use `stegseek` for password-protected steghide files
- Review `stegseek.txt` for discovered passwords

---

## Tool Dependency Map

```
file          (standalone)
exiftool      (standalone)
identify      (standalone)
strings       (standalone)
binwalk       → binwalk-extract
zsteg         (standalone)
steghide      (standalone)
stegseek      (standalone — brute-forces steghide passwords)
tesseract     (standalone)
zbarimg       (standalone)
foremost      (standalone)
convert       (standalone)
```

No tool depends on another's output. Each runs independently.

---

## Troubleshooting

| Tool | Common Issue | Solution |
|------|-------------|----------|
| `exiftool` | Fails on corrupted image | Try `identify image.png` first |
| `zsteg` | Fails on JPEG | Limited to PNG primarily |
| `steghide` | Tries empty password only | Install `stegseek` for brute-force |
| `stegseek` | Not in standard repos | Install: `sudo apt install stegseek` or build from source |
| `tesseract` | Language pack missing | `sudo apt install tesseract-ocr-eng` |
| `zbarimg` | QR code too small | Try: `zbarimg image.png --raw --set '*.enable=1'` |

---

*Last updated: July 18, 2026*
