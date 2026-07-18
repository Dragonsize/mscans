# IMGscans — CTF Image Analysis Wrapper

A robust bash wrapper that chains all essential forensic tools for CTF image analysis in the optimal order.

## Overview

This tool automates the recommended forensic workflow for analyzing images in Capture The Flag (CTF) challenges. It runs a complete suite of analysis tools in the order they should be used for maximum flag discovery:

```
File analysis → Metadata extraction → Content discovery → Steganography
→ QR/Barcodes → Forensic extraction
```

The script intelligently handles missing tools by providing installation commands and skips unnecessary checks in quick mode for faster results.

## Features

- **Full toolset**: 12 specialized tools including file analysis, steganography detection, OCR, forensic extraction
- **Quick mode**: Skip expensive OCR and forensic extraction for rapid initial analysis
- **Install instructions**: Automatic detection of your package manager with precise install commands for missing tools
- **Flag search**: Built-in regex search across all extracted content
- **Structured output**: Organized directory structure for clean result management
- **Production ready**: Comprehensive error handling, logging, and user-friendly interfaces

## Installation

The script is ready to use. It includes intelligent install commands for missing dependencies.

## Quick Start

### Fast Analysis
```bash
# Quick mode - basic tools only (~10 seconds)
./ctf-image.sh -q image.png

# Full analysis - all tools (~3-5 minutes)
./ctf-image.sh image.png
```

### Search for Flags
```bash
# Auto-search for flag patterns in extracted content
./ctf-image.sh -f 'FLAG|flag|ctf|FLAG{' image.png
```

### Custom Output
```bash
# Specify output directory
./ctf-image.sh -o ./results image.png
```

## Tool Chain

### Phase 1: Basic Analysis (`-q` includes)
- `file` - Detect file type and encoding
- `exiftool` - Extract EXIF/IPTC/XMP metadata
- `identify` - Get image dimensions and properties
- `pngcheck` - Verify PNG integrity
- `xxd` - Initial hex dump (first 500 bytes)

### Phase 2: Content Discovery (always)
- `strings` - Extract ASCII/UTF-16 content
- `strings-unique` - Sorted unique strings for flag patterns
- `tesseract` - OCR for visible/recovered text

### Phase 3: Advanced (full mode only)
- `binwalk` - Find embedded files and headers
- `binwalk-extract` - Extract embedded files
- `zsteg` - LSB steganography detection
- `steghide` - Steganography file analysis
- `zbarimg` - QR code and barcode decoding
- `foremost` - Forensic file extraction
- `convert` - Channel separation (if available)

### Tool Status Handling

Missing tools are automatically detected and noted:

```
=== Missing Tools — Install for Full Coverage ===
  exiftool     sudo apt install -y libimage-exiftool-perl
  identify     sudo apt install -y imagemagick
  tesseract    sudo apt install -y tesseract-ocr
```

Click the install command for your specific package manager (apt/dnf/yum/pacman/brew).

### Optimization Recommendations

1. **Start with Quick Mode**: Always begin with `-q` to get basic metadata and strings quickly
2. **Flag Search First**: Focus on `strings-unique.txt` for obvious flag patterns
3. **Steganography Priority**: Run full mode if quick mode doesn't yield results
4. **Check Binwalk**: `binwalk -e` is often the richest source of embedded data
5. **Regex Search**: Use `-f 'FLAG|flag|ctf|FLAG{'` to auto-search across all outputs

## Example CTF Analysis Workflow

### Step 1: Initial Investigation
```bash
# Fast initial scan
./ctf-image.sh -q mystery.png > mystery_scan.log 2>&1

# Look for obvious flags
head -100 ./ctf-mystery/strings-unique.txt
```

### Step 2: Deep Analysis
```bash
# Full forensic analysis if quick didn't find anything
./ctf-image.sh -f 'FLAG|flag|ctf' mystery.png > mystery_deep.log 2>&1

# Review binwalk results
ls -la ./ctf-mystery/binwalk_extract/
if [ -d ./ctf-mystery/binwalk_extract ]; then
    tar -czf embedded_files.tar.gz ./ctf-mystery/binwalk_extract/*
fi
```

### Step 3: Targeted Extraction
```bash
# Extract channels if ImageMagick available
if [ -f ./ctf-mystery/channels/channel_0.png ]; then
    identify ./ctf-mystery/channels/channel_0.png
    strings ./ctf-mystery/channels/channel_0.png
fi
```

## Troubleshooting

### Common Issues

**Install Commands Not Working**
- Your package manager might use different package names
- Try installing the tool directly: `sudo apt install exiftool` (or `apt-get install exiftool`)

**Image Format Issues**
- Works best with PNG, JPEG, GIF, BMP, TIFF
- Some tools may fail on corrupted files - try different tools

**Missing Dependencies**
- Install recommended tool sets: `sudo apt install libimage-exiftool-perl imagemagick binwalk`

**Performance Issues**
- Large images: Use `-q` first
- Long analysis: Let it run in background

## Supported OS

- **Linux** (Debian/Ubuntu/RHEL/CentOS/Arch)
- **macOS** (brew install)
- **Windows** (WSL/Cygwin/equivalent)

## Installation Commands (Quick Reference)

```bash
# Debian/Ubuntu
# Basic: sudo apt install libimage-exiftool-perl imagemagick file binwalk
# Full: sudo apt install libimage-exiftool-perl imagemagick pngcheck binwalk ruby-zsteg steghide tesseract-ocr zbar-tools foremost

# RHEL/CentOS
# Basic: sudo yum install exiftool ImageMagick file binwalk
# Full: sudo yum install exiftool ImageMagick pngcheck binwalk zsteg steghide tesseract zbar-tools foremost

# Fedora
# Basic: sudo dnf install exiftool ImageMagick file binwalk
# Full: sudo dnf install exiftool ImageMagick pngcheck binwalk zsteg steghide tesseract zbar-tools foremost

# macOS
# Basic: brew install file exiftool imagemagick binwalk
# Full: brew install exiftool imagemagick pngcheck binwalk zsteg steghide tesseract zbar-tools foremost
```

## Contribute

### Enhancements
- Add new CTF tool support (`grep -r "stego" | head -20`)
- Support more regex patterns for flag detection
- Add automated correlation between tools

### Bug Reports
- Check that all tools are in PATH: `type -a exiftool identify file`
- Test with known-good images: `wget -q -O sample.png "https://example.com/sample.png"`

## License

```
MIT License

Copyright (c) $(date +%Y) nv

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Author

- `nv` <nv@ctf-tools.dev>
- Claude Fable 5 <noreply@anthropic.com>

Last updated: $(date +%Y-%m-%d)