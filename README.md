# EZ Switcher

<div align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-blue?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" />
</div>

<br/>

**EZ Switcher** is a high-performance macOS menu bar utility that automatically detects and corrects mistyped text when your keyboard layout is wrong — before you even notice.

Inspired by **Punto Switcher** and **Mahou**, rebuilt from scratch for modern macOS (Ventura 13+) with SwiftUI and a native design system.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🌐 **Auto Layout Detection** | Heuristic character frequency analysis for EN / RU / UA |
| ↩️ **Word Correction** | Delete → Retype mismatched characters in real-time |
| ⌨️ **Manual Hotkey** | `Cmd+Alt+L` — manually trigger word conversion |
| 🔒 **Password Safety** | Auto-disabled in secure text fields via AX API |
| 🔇 **App Exclusions** | Blacklist apps + window title keyword matching |
| ⌨️ **Quick Exclusion** | `Cmd+Alt+X` — instantly exclude the current app |
| 📝 **Typographic Engine** | Smart quotes « », em-dashes —, ellipsis …, orphan control |
| 🔊 **Sound Cues** | Subtle audio feedback on layout switch |
| 🎨 **Native Design** | Bento Grid settings UI with 3-tier token system |

---

## 📥 Installation

### Option 1: Download DMG (Recommended)

1. Download `EZSwitcher-1.0.0.dmg` from [Releases](../../releases)
2. Open the DMG and drag **EZ Switcher.app** to `/Applications`
3. Launch **EZ Switcher** from Applications
4. Grant permissions when prompted:
   - **System Settings → Privacy & Security → Accessibility** → Enable EZ Switcher
   - **System Settings → Privacy & Security → Input Monitoring** → Enable EZ Switcher

### Option 2: Build from Source

**Requirements:** macOS 13+, Xcode Command Line Tools

```bash
git clone https://github.com/YOUR_USERNAME/ez-switcher.git
cd ez-switcher
chmod +x package_app.sh
./package_app.sh
# Output: build/EZ Switcher.app + build/EZSwitcher-1.0.0.dmg
```

---

## 🚀 Usage

1. EZ Switcher lives in the **menu bar** (keyboard icon ⌨️)
2. Start typing — it auto-detects if you used the wrong layout
3. After a word is detected as mistyped, it corrects it automatically
4. Open **Settings** from the menu bar icon to configure

### Hotkeys

| Hotkey | Action |
|---|---|
| `Cmd+Alt+L` | Manually convert the last typed word |
| `Cmd+Alt+X` | Toggle exclusion for the current app |

---

## 🏗 Project Structure

```
Sources/EZSwitcher/
├── main.swift                    # App entry + NSStatusItem
├── LayoutMonitoringEngine.swift  # CGEvent tap + word buffer
├── LanguageDetectionService.swift# Heuristic RU/UA/EN detection
├── TextTransformationService.swift# Typographic engine (quotes, dashes)
├── ExclusionManager.swift        # App + window title blacklisting
├── PasswordDetector.swift        # AX API secure field detection
├── LayoutSwitcher.swift          # Carbon API layout switching
├── SoundManager.swift            # Audio feedback
├── AccessibilityManager.swift    # Permission management
├── DesignSystem.swift            # 3-tier token system
├── SidebarView.swift             # Main settings navigation
├── SettingsView.swift            # General settings
├── ExclusionsView.swift          # Exclusion manager UI
├── DebugOverlay.swift            # Score visualization overlay
├── FigmaExportService.swift      # Design token export
└── Models.swift                  # Shared types

Tests/EZSwitcherTests/
├── AutomatedTests.swift          # Integration test suite
└── TypographyTests.swift         # Typographic engine tests
```

---

## 🔐 Privacy

EZ Switcher **does not**:
- Send data to any server
- Store your typed text permanently
- Access the internet

It **does** require:
- **Accessibility** — to read focused element type (password vs text)
- **Input Monitoring** — to intercept key events globally

---

## 🧪 Running Tests

```bash
chmod +x build_manual.sh
./build_manual.sh
./EZSwitcher_Tests
```

---

## 📄 License

MIT © 2026 EZ Switcher
