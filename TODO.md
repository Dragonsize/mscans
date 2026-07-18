# TODO

## Features
- [ ] Batch processing — run on `*.png` or entire folder
- [ ] Entropy analysis — `binwalk -E` for encrypted regions
- [ ] Nested analysis — auto-re-analyze extracted files
- [ ] stegsolve integration — Java visual stego analysis
- [ ] Animated GIF support
- [ ] PDF embedded image extraction
- [ ] JSON output (`--json`)

## Improvements
- [ ] Cross-tool correlation (binwalk finds ZIP → check steghide)
- [ ] Color channel visualization (HTML/SVG)
- [ ] Confidence scoring per finding
- [ ] Magic byte validation (file header vs extension)
- [ ] Non-image support (PDF, DOCX, APK)

## Docs
- [ ] Real CTF example walkthrough
- [ ] Troubleshooting guide per tool
- [ ] Contribution guidelines

## Packaging
- [ ] GitHub release with assets
- [ ] Homebrew tap for macOS
- [ ] `.deb` / `.rpm` packages
