# EZ Switcher Project Progress

## Current Phase: Stage 1 & 2 (System Engine & Heuristic Brain)

### [x] Stage 1: System Engine Optimization
- [x] Finalize Accessibility + Carbon hooks (LayoutMonitoringEngine)
- [x] Robust Word Conversion logic (Delete -> Insert pattern)
- [x] Support for Manual Correction hotkey (Cmd+Alt+L)
- [x] Support for App Exclusion hotkey (Cmd+Alt+X)

### [x] Stage 2: Heuristic Language Detection
- [x] Refined LanguageDetectionService heuristics (RU/UA exclusive characters)
- [x] Implemented Word Conversion logic (Delete -> Insert)
- [x] Added unique character scoring and exclusion rules

### [x] Stage 2.5: Typographic Engine
- [x] Implementation of `TextTransformationService`
- [x] Directional Smart Quotes (« » for RU/UA, “ ” for EN)
- [x] Smart Dashes and Ellipsis logic
- [x] Orphan Control (Non-breaking spaces after single-letter prepositions)
- [x] Intelligent exclusion for Code Apps (VS Code, Xcode, etc.)
- [x] Live Preview in Settings UI

### [x] Stage 3: Native UI & Design System
- [x] 3-Tier Token System implementation
- [x] Polished Bento Grid Settings UI
- [x] Typography Settings Section with Live Preview
- [x] Debug Overlay for score visualization

### [x] Stage 4: Testing & Documentation
- [x] Unit tests for Typographic Engine (`TypographyTests.swift`)
- [x] Refined Heuristic tests for RU/UA detection accuracy
- [x] Documentation for hotkeys and configuration

### [x] Stage 5: Refinements & Ecosystem
- [x] Deep integration of `ExclusionManager` into Engine
- [x] Enhanced `SoundManager` with contextual audio cues
- [x] Intelligent window title matching for auto-exclusion
- [x] Figma design token export logic (ready for handoff)
- [x] Automated test suite for Exclusion logic

### [x] Stage 6: Distribution & Final Handoff
- [x] Robust `package_app.sh` script with ZIP fallback
- [x] Successfully compiled `.app` bundle for macOS 13+
- [x] Ad-hoc code signing and bundle verification
- [x] Comprehensive `walkthrough.md` created

### [x] Stage 7: Stabilization & Correction Accuracy
- [x] Implemented CGEvent swallowing to prevent character duplication
- [x] Increased correction delays (10ms backspace, 50ms stabilization, 5ms typing)
- [x] Tuned detection thresholds (0.80 min confidence, 0.25 margin)
- [x] Increased real-time buffer requirement to 6 characters

### [x] Stage 8: System Stability & Mouse Fix
- [x] Moved Event Tap to a high-priority background thread
- [x] Removed mouse events from Tap Mask to prevent system-wide hijacking
- [x] Implemented asynchronous focus/exclusion state caching
- [x] Added hard-coded exclusion for System Settings to prevent security deadlocks

---
*Last Updated: 2026-05-12*
