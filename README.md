# Offline Cards

Store your discount and loyalty cards offline on your iPhone.

## Why This Exists

I vibe-coded this app in 3 hours while watching TV series because I was tired of using badly working, data-stealing apps just to store my loyalty cards.

## Disclaimer

**I take no responsibility for anything.** Not for the code quality which is probably bad, not for the app, not for any of it. The app does the job for me and this is what I care about. If you decide to use it, you do so entirely at your own risk. I accept no responsibility for any consequences whatsoever.

## Features

- Barcode and QR code display with automatic brightness boost
- Photo storage for physical cards
- Color-coded cards for quick identification
- Search by store name
- Export/import as JSON backup
- Works completely offline
- No data collection, no tracking, no internet required

## Installation (AltStore PAL)

For iPhone users in the EU:

1. Install [AltStore PAL](https://altstore.io) on your iPhone
2. Open AltStore PAL → Sources → Add Source
3. Enter: `https://raw.githubusercontent.com/romcheg/offline-cards/master/altstore/source.json`
4. Find "Offline Cards" and tap Install

## Building from Source

Requires macOS with Xcode 15+ and iOS 17+.

```bash
# Install dependencies
brew install xcodegen swiftlint

# Generate Xcode project
make generate

# Build and run in simulator
make run

# Build and run on connected iPhone
make run-iphone
```

### Make Targets

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make generate` | Generate Xcode project |
| `make build` | Build the app |
| `make run` | Build and run in simulator |
| `make run-iphone` | Build and run on iPhone |
| `make test` | Run all tests |
| `make lint` | Run SwiftLint |
| `make verify` | Run lint + all tests |
| `make release` | Build IPA for AltStore distribution |

## Requirements

- iOS 17.0+
- iPhone

## License

This project is licensed under the **Offline Cards Restricted License (OCRL) v1.0**.

**Important restrictions:**
- Commercial use prohibited without separate license from the author
- Usage is prohibited for citizens or residents of Russia, Belarus, Iran, North Korea, and any country sanctioned by the EU, Ukraine, or Poland
- Usage within the territory of sanctioned countries is prohibited
- All forks and derivative works must use this same license with the same restrictions
- No warranty, no liability, use at your own risk

See [LICENSE](LICENSE) for full terms.

Copyright (c) 2026 Roman Prykhodchenko
