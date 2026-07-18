# Tool Chain Reference

Complete documentation of the CTF image analysis tool chain order and dependencies.

## Why This Order Matters

CTF image challenges often follow predictable patterns. The tool chain is ordered by:

1. **Low-hanging fruit first** - Get the most likely flags quickly
2. **Least destructive first** - Don't modify the image until needed
3. **Data flow** - Each tool's output informs the next

---

## Phase 1: Basic Analysis

### Purpose
- Detect what you're dealing with
- Extract all visible metadata
- Identify potential issues

### Tools

| Tool | Command | Output | Why First? |
|------|---------|--------|-----------|
| `file` | `file image.png` | File type, encoding | Identifies if file is what it claims to be |
| `exiftool` | `exiftool image.png` | EXIF, IPTC, XMP metadata | Non-destructive metadata extraction |
| `identify` | `identify -verbose image.png` | Dimensions, bit depth, color space | Image format details |
| `pngcheck` | `pngcheck -v image.png` | PNG integrity, chunk analysis | Catches corruption, anomalies |
| `xxd` | `xxd image.png \| head -500` | Hex dump | Visual pattern detection |

### Common Findings
- File type mismatches (e.g., PNG header but JPEG content)
- Hidden EXIF fields (GPS, camera, comments)
- Corrupted chunks or invalid CRC
- Hex patterns (magic numbers, embedded strings)

### Quick Mode
This phase is **always included** in `-q` mode.

---

## Phase 2: Content Discovery

### Purpose
- Extract all text/ASCII content from binary data
- Detect visible text that needs OCR

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `strings` | `strings image.png` | ASCII strings (8+ chars) | Primary flag discovery method |
| `strings-16` | `strings -el image.png` | UTF-16 strings | Catches non-ASCII flags |
| `strings-unique` | `strings image.png \| sort -u` | Unique strings | Deduped for flag scanning |
| `tesseract` | `tesseract image.png output` | OCR text | Extracts text written on image |

### Common Findings
- Flag patterns: `FLAG{...}`, `CTF{...}`, `{...}`
- Base64 encoded strings
- URLs, IPs, file paths
- Hidden comments or notes
- Handwritten text requiring OCR

### Why Before Stego?
Strings extraction catches **90%+ of flags** in simple challenges. Don't waste time on steganography until you've checked the obvious.

### Quick Mode
`tesseract` is **only in full mode** (it's slow). Strings are always included.

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

### Common Findings
- Embedded ZIP/TAR archives
- Secondary images hidden in pixels
- LSB-encoded messages
- Steghide password-protected files

### Why After Content Discovery?
Steganography tools are:
- **Slower** (analysis takes time)
- **More false positives** (binwalk finds junk)
- **Destructive** (extracted files need management)

### Quick Mode
This phase is **only in full mode** (slow but comprehensive).

---

## Phase 4: Specialized Extraction

### Purpose
- Decode visual data (QR, barcodes)
- Extract files from image containers
- Split color channels for analysis

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `zbarimg` | `zbarimg --raw image.png` | QR/barcode content | Visual encoding often used for flags |
| `foremost` | `foremost -i image.png -o out -t all` | Carved files | File carving for deleted content |
| `convert` | `convert image.png -ch RGB ...` | Channel separation | Isolate red/green/blue channels |

### Common Findings
- QR codes with base64 or flag data
- Deleted file remnants
- Channel-specific hidden patterns
- File fragments (JPG, ZIP, etc.)

### Why Last?
These are:
- **Most resource intensive**
- **Lowest hit rate** for typical CTFs
- **Highly dependent** on earlier findings

### Quick Mode
This phase is **only in full mode**.

---

## Phase 5: Integration & Analysis

### Purpose
- Cross-reference all outputs
- Search for flag patterns
- Generate actionable intelligence

### Tools

| Tool | Command | Output | Why Here? |
|------|---------|--------|-----------|
| `grep -rniE` | `grep -rniE 'FLAG\|flag\|ctf' ./outdir/` | Flag matches | Automated flag detection |
| Manual review | `cat ./outdir/strings-unique.txt` | Visual scanning | Human verification |

### Why Separate from Tools?
This is **human-in-the-loop analysis**:
- Automated search catches obvious patterns
- Manual review catches subtle/obfuscated flags
- Cross-referencing finds relationships between tools

### Best Practices
1. **Always start with `strings-unique.txt`**
2. **Check `binwalk_extract/` before stego results**
3. **Use regex patterns** (`-f` flag) for automated search
4. **Compare multiple tools** - one tool may miss what another catches

---

## Complete Workflow Example

```
# Quick initial scan
./ctf-image.sh -q mystery.png

# Review strings-unique.txt
grep -n "flag\|FLAG\|ctf" ./ctf-mystery/strings-unique.txt

# If no obvious flags, full analysis
./ctf-image.sh -f 'FLAG|flag|ctf' mystery.png

# Check binwalk output
head -20 ./ctf-mystery/binwalk.txt

# Review extracted files
ls -la ./ctf-mystery/binwalk_extract/
```

---

## Tool Dependency Map

```
file (standalone)
exiftool (standalone)
identify (standalone)
strings (standalone)
binwalk → binwalk-extract
zsteg (standalone)
steghide (standalone)
tesseract (standalone)
zbarimg (standalone)
foremost (standalone)
xxd (standalone)
convert (standalone)
```

No tool depends on another's output. Each runs independently.

---

## Performance Notes

| Phase | Typical Time | Speed Factor |
|-------|-------------|--------------|
| Phase 1 | < 1 second | Very fast |
| Phase 2 | 1-3 seconds | Fast (tesseract: 5-10s) |
| Phase 3 | 5-30 seconds | Medium (binwalk: varies) |
| Phase 4 | 3-10 seconds | Medium (foremost: varies) |
| Phase 5 | < 1 second | Very fast |

**Total**: Quick mode ~5-15 seconds, Full mode ~15-60 seconds.

---

## Optimization Tips

### For Speed
- Use `-q` for initial investigation
- Run in background: `./ctf-image.sh -q file.png &`
- Focus on strings output first

### For Accuracy
- Run full mode when quick mode fails
- Use `-f` to search for specific patterns
- Cross-reference multiple tool outputs

### For Large Files
- Quick mode essential for large images
- Consider resizing: `convert image.png -resize 800x600 small.png`
- Run in background and check later

### For Steganography
- Focus on `binwalk -e` and `zsteg` first
- Check all extracted files in `binwalk_extract/`
- Try `steghide` with common passwords

---

## Troubleshooting Tools

### `exiftool` fails
- Image may be corrupted
- Try: `identify image.png` to verify format

### `zsteg` fails
- Not all images support LSB stego
- PNGs are primary target, JPEGs limited

### `binwalk` finds nothing
- Nothing embedded in this image
- Move to stego tools

### `steghide` fails
- Try different passwords: `steghide extract -p "password" -f image.png`
- Check if file is actually steghide-protected

### `tesseract` fails
- Language pack missing: `sudo apt install tesseract-ocr-eng`
- Poor OCR quality - try manual reading

### `zbarimg` fails
- QR code too small or damaged
- Try: `zbarimg image.png --raw` to force

### `foremost` fails
- File not in carving database
- Try: `foremost -i image.png -o out -t all` to scan all types

---

## Advanced Usage

### Custom Tool Order
Modify the script to skip phases:
```bash
# Phase 1 only (metadata)
./ctf-image.sh -q -o metadata image.png

# Skip steganography
./ctf-image.sh -f 'FLAG|flag' image.png
```

### Parallel Analysis
```bash
# Quick analysis while you review
./ctf-image.sh -q image.png & QUICK_PID=$!

# Full analysis runs in background
./ctf-image.sh image.png & FULL_PID=$!

# Kill full if quick finds flag
if wait $QUICK_PID; then
    echo "Flag found, stopping full analysis"
    kill $FULL_PID 2>/dev/null
fi
```

### Custom Regex Patterns
```bash
# Search for base64
./ctf-image.sh -f '[A-Za-z0-9+/]{40,}' image.png

# Search for IP addresses
./ctf-image.sh -f '\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\b' image.png
```

---

## Future Enhancements

### Planned Features
- [ ] Add `stegsolve` support (Java-based visual analysis)
- [ ] Integrate `zsteg` channel visualization
- [ ] Support for animated GIF analysis
- [ ] PDF embedded image extraction
- [ ] Automated correlation between tools

### Known Limitations
- JPEG steganography support limited
- Password-protected stego requires guessing
- Large files cause slow performance
- No automated channel visualization

---

*Last updated: $(date +%Y-%m-%d)*
