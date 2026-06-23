<p align="center">
  <img src="Blobby/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Blobby icon">
</p>

<h1 align="center">Blobby</h1>

<p align="center">
  A macOS app that adds an animated, morphing blob cursor overlay.<br>
  Smooth spring physics. Comet-like kinetic distortion. System-wide.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

---

## Features

- **Animated blob cursor** — overlays an animated blob that follows your cursor system-wide
- **Kinetic morphing** — the blob stretches into a comet shape when moving, proportional to speed
- **Spring physics** — three modes (Normal, Slow, Bouncy) with fluid follow behavior
- **Click animation** — blob squishes on mouse down
- **Dot cursor** — optional precise dot at the exact cursor position
- **Multi-display** — works seamlessly across multiple screens
- **Menu bar app** — lives in the menu bar, no dock icon
- **Customizable** — color, size, opacity, spring mode, dot cursor settings
- **Persistent settings** — your preferences are saved across launches

## Install

### Homebrew

```bash
brew install --cask --no-quarantine dxsun97/tap/blobby
```

> First install auto-taps from the Blobby repo. Future updates: `brew upgrade blobby`

### Download

1. Go to [Releases](../../releases/latest)
2. Download `Blobby-x.x.x-universal.dmg`
3. Open the DMG and drag **Blobby** to **Applications**
4. Launch Blobby — grant Accessibility permission when prompted

> On first launch, macOS may show "unidentified developer" warning. Right-click the app → **Open** → **Open** to bypass.

### Build from source

Requires **macOS 14+** and **Xcode Command Line Tools**.

```bash
git clone https://github.com/dxsun97/Blobby.git
cd Blobby
bash create-dmg.sh
open Blobby-*.dmg
```

On first launch, macOS will ask for **Accessibility permission** (needed for global cursor tracking). Grant it in **System Settings > Privacy & Security > Accessibility**.

## Usage

Click the blob icon in the menu bar to open settings:

| Setting | Default | Description |
|---------|---------|-------------|
| Color | Light gray | Blob fill color |
| Size | 40px | Blob diameter |
| Opacity | 50% | Blob transparency |
| Spring | Normal | Follow behavior (Normal / Slow / Bouncy) |
| Dot cursor | Off | Show a small dot at the exact cursor position |
| Dot color | White | Dot fill color |
| Dot size | 8px | Dot diameter |

All settings update in real-time and persist across launches.

## Known limitations

- Requires Accessibility permission for global cursor tracking
- Cannot hide cursor during secure input (password fields) — blob freezes at last position
- Not App Store compatible (requires sandbox disabled) — distribute via DMG or Homebrew
- Overlay may briefly flicker during Space transitions

## Release

To create a new release, push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build the DMG and publish it to [Releases](../../releases).

## Acknowledgments

Inspired by [Blobity](https://github.com/gmrchk/blobity), a web-based custom cursor library by Georgy Marchuk. Blobby is an independent, from-scratch implementation for macOS — no code or assets are derived from Blobity.

## License

MIT
