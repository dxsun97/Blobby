<p align="center">
  <img src="Blobby/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png" width="128" height="128" alt="Blobby icon">
</p>

<h1 align="center">Blobby</h1>

<p align="center">
  A small macOS menu bar app that draws an animated blob around your cursor.
</p>

<p align="center">
  <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="macOS 14+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

---

Blobby adds a blob overlay that follows the real macOS cursor. It does not hide or replace the native cursor. When the system cursor is hidden by the active app, such as in fullscreen video or text input, the blob hides too.

## Features

- Animated blob overlay following the system cursor
- Keeps the native cursor visible
- Hides with the real cursor when apps hide it
- Spring follow modes: Normal, Slow, Bouncy
- Speed-based blob stretching
- Click squish animation
- Optional dot at the exact cursor position
- Multi-display support
- Menu bar settings
- GitHub Releases update check

## Install

### Homebrew

```bash
brew install --cask --no-quarantine dxsun97/tap/blobby
```

Update:

```bash
brew upgrade blobby
```

### Manual

1. Download the latest DMG from [Releases](../../releases/latest).
2. Drag **Blobby.app** to **Applications**.
3. Open Blobby and grant Accessibility permission.

If macOS blocks the app on first launch, right-click **Blobby.app** and choose **Open**.

## Permissions

Blobby needs Accessibility permission to read the global cursor position and mouse button state.

It does not click, type, read windows, or collect data.

Grant permission in:

**System Settings > Privacy & Security > Accessibility**

## Usage

Click the menu bar icon to open settings.

| Setting | Default | Description |
|---------|---------|-------------|
| Color | Light gray | Blob color |
| Size | 40 px | Blob diameter |
| Opacity | 50% | Blob opacity |
| Spring | Normal | Follow behavior |
| Dot cursor | Off | Show a precise dot at the cursor position |
| Dot color | White | Dot color |
| Dot size | 8 px | Dot diameter |

Settings update immediately and are saved automatically.

## Build

Requirements:

- macOS 14+
- Xcode Command Line Tools

```bash
git clone https://github.com/dxsun97/Blobby.git
cd Blobby
bash bundle.sh
open .build/Blobby.app
```

Build a DMG:

```bash
bash create-dmg.sh
open Blobby-*.dmg
```

## Dev Build

For local testing, it helps to use a separate bundle id so macOS Accessibility permissions do not collide with the installed app:

```bash
BLOBBY_DISPLAY_NAME="Blobby Dev" \
BLOBBY_BUNDLE_ID="com.blobby.dev" \
BLOBBY_CODE_SIGN_IDENTITY="Blobby Dev Code Signing" \
bash bundle.sh

open ".build/Blobby Dev.app"
```

`BLOBBY_CODE_SIGN_IDENTITY` is optional. Without it, the app is ad-hoc signed. A stable local signing identity makes Accessibility permission testing less annoying.

## Release

Push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions builds the DMG, updates the cask, and publishes the release.

GitHub Actions publishes an ad-hoc signed release. Accessibility permission is tied to the app's code identity, so users may need to reset Accessibility permission after reinstalling.

## Notes

- Accessibility permission is required.
- If Accessibility shows Blobby as enabled but the app cannot track the cursor after reinstalling an unsigned/ad-hoc build, remove Blobby from Accessibility, quit Blobby, add the newly installed app again, then relaunch.
- Secure input can limit cursor event visibility.
- The app is not sandboxed, so it is not suitable for the Mac App Store as-is.
- Space/fullscreen transitions are controlled by macOS and can occasionally affect overlay timing.

## Acknowledgments

Inspired by [Blobity](https://github.com/gmrchk/blobity). Blobby is a separate macOS implementation and does not use Blobity code or assets.

## License

[MIT](LICENSE)
