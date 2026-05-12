# EZ Switcher

A high-performance macOS layout switcher for English, Russian, and Ukrainian.

Inspired by Mahou logic and Punto Switcher functionality.

## Features
- 🌐 Automatic layout detection and correction (EN/RU/UA)
- 🔑 Global hotkey for manual word conversion
- 🔒 Password field detection — auto-disables switching in secure inputs
- 🔇 "Quick Exclusion" — instant app blacklisting
- 🔊 Smart Sound — subtle audio cues on layout switch

## Requirements
- macOS 13+
- Xcode or Swift Command Line Tools 6.0+

## Permissions Required
- **Accessibility** (System Settings → Privacy & Security → Accessibility)
- **Input Monitoring** (System Settings → Privacy & Security → Input Monitoring)

## Project Structure
```
Sources/EZSwitcher/
├── main.swift                  # App entry point & delegate
├── AccessibilityManager.swift  # Permission handling
├── LayoutSwitcher.swift        # Carbon API layout switching
├── LayoutMonitoringEngine.swift# CGEvent global key hooks
├── LanguageDetector.swift      # NLLanguageRecognizer, N-gram detection
├── PasswordDetector.swift      # Secure field detection via AX API
└── String+Translation.swift    # EN ↔ RU ↔ UA keyboard mapping
```

## Implementation Status
- [x] Phase 1: Layout Monitoring Engine
- [ ] Phase 2: Core ML & Language Detection integration
- [ ] Phase 3: SwiftUI Settings Dashboard

## Build
```bash
swift build
```
