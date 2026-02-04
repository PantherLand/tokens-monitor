# OpenRouter Monitor

<p align="center">
  <img src="assets/icon.png" alt="OpenRouter Monitor" width="128"/>
</p>

<p align="center">
  🔄 A lightweight macOS menubar app for monitoring OpenRouter API token usage in real-time
</p>

<p align="center">
  <a href="https://github.com/PantherLand/tokens-monitor/releases"><img src="https://img.shields.io/github/v/release/PantherLand/tokens-monitor?include_prereleases" alt="Release"></a>
  <a href="https://github.com/PantherLand/tokens-monitor/blob/main/LICENSE"><img src="https://img.shields.io/github/license/PantherLand/tokens-monitor" alt="License"></a>
  <a href="https://github.com/PantherLand/tokens-monitor/stargazers"><img src="https://img.shields.io/github/stars/PantherLand/tokens-monitor" alt="Stars"></a>
</p>

## ✨ Features

- 🔄 Real-time token usage display
- 📊 Multi-model usage statistics
- 💰 Cost tracking and remaining credits
- ⚙️ Clean, native macOS menubar experience (ClashX-style)
- 🔐 Secure API key storage with macOS Keychain
- 🎨 Native design with dark mode support

## 📸 Screenshots

<img src="assets/screenshot.png" alt="Screenshot" width="400"/>

## 🚀 Quick Start

### Installation

**Option 1: Download Pre-built Binary**
1. Go to [Releases](https://github.com/PantherLand/tokens-monitor/releases)
2. Download the latest `.dmg` file
3. Open DMG and drag the app to Applications folder
4. Right-click the app and select "Open" (first launch only)

**Option 2: Build from Source**
```bash
# Clone the repository
git clone https://github.com/PantherLand/tokens-monitor.git
cd tokens-monitor

# Run the app
make run

# Or build for release
make build
```

### First-time Setup

1. Launch the app - you'll see a 📊 icon in your menubar
2. Click the icon → "Settings..."
3. Paste your OpenRouter API Key
4. Set refresh interval (default: 5 minutes)
5. Click "Save"

### Get Your OpenRouter API Key

1. Visit [OpenRouter](https://openrouter.ai/)
2. Sign in to your account
3. Go to [API Keys](https://openrouter.ai/keys)
4. Create a new API Key
5. Copy and paste it into the app settings

## 🛠️ Development

### Prerequisites

- macOS 10.15 (Catalina) or later
- Xcode 13.0+
- Swift 5.0+

### Build Commands

```bash
# Install dependencies (if any)
make install

# Run in development mode
make run

# Build for release
make build

# Run tests
make test

# Clean build artifacts
make clean

# Format code
make format

# Show help
make help
```

### Project Structure

```
tokens-monitor/
├── OpenRouterMonitor/
│   ├── Sources/
│   │   ├── OpenRouterMonitorApp.swift    # Main app entry
│   │   ├── OpenRouterAPIManager.swift    # API client & Keychain
│   │   └── SettingsView.swift            # Settings UI
│   ├── Resources/                        # Assets & icons
│   └── Info.plist
├── Makefile                              # Build automation
├── Package.swift                         # SPM configuration
└── docs/                                 # Documentation
```

## 📖 Documentation

- 🚀 [Quick Start Guide](QUICKSTART.md)
- 🔧 [Build Instructions](BUILD.md)
- 💻 [Development Guide](DEVELOPMENT.md)
- 🗺️ [Roadmap](ROADMAP.md)
- 🤝 [Contributing](CONTRIBUTING.md)

## 🔒 Security

- API keys are stored securely in macOS Keychain
- All data is processed locally
- No telemetry or third-party data collection
- Open source - audit the code yourself

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### How to Contribute

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 Changelog

See [Releases](https://github.com/PantherLand/tokens-monitor/releases) for version history.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by [ClashX](https://github.com/yichengchen/clashX)
- Built with Swift and SwiftUI
- Powered by [OpenRouter](https://openrouter.ai/)

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=PantherLand/tokens-monitor&type=Date)](https://star-history.com/#PantherLand/tokens-monitor&Date)

---

<p align="center">Made with ❤️ for the OpenRouter community</p>
