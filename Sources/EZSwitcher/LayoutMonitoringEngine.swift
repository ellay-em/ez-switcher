import CoreGraphics
import Foundation
import Carbon
import Combine

class LayoutMonitoringEngine {
    static let shared = LayoutMonitoringEngine()
    
    private let settings = SettingsManager.shared
    private var eventPort: CFMachPort?

    private var runLoopSource: CFRunLoopSource?
    
    // Internal state
    private var wordBuffer: String = ""
    private var isProcessing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        settings.$isEnabled
            .sink { [weak self] enabled in
                self?.updateTapState(enabled: enabled)
            }
            .store(in: &cancellables)
    }
    
    private func updateTapState(enabled: Bool) {
        guard let eventPort = eventPort else { return }
        CGEvent.tapEnable(tap: eventPort, enable: enabled)
        if !enabled {
            wordBuffer = ""
        }
    }
    
    func start() {
        guard eventPort == nil else { return }
        
        // Listen for manual layout changes
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { _ in
            print("Layout changed manually - resetting buffer")
            LayoutMonitoringEngine.shared.wordBuffer = ""
        }

        // We intercept key down and mouse down (to reset buffer on click)
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.leftMouseDown.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<LayoutMonitoringEngine>.fromOpaque(refcon).takeUnretainedValue()
            
            if !engine.settings.isEnabled || engine.isProcessing {
                return Unmanaged.passUnretained(event)
            }
            
            if type == .leftMouseDown {
                engine.wordBuffer = ""
                return Unmanaged.passUnretained(event)
            }
            
            if type == .keyDown {
                return engine.handleKeyDown(proxy: proxy, event: event)
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        eventPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventPort = eventPort else {
            print("Failed to create event tap. Ensure Accessibility permissions are granted.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventPort, enable: true)
        print("EZ Switcher Engine: Active")
    }
    
    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
        guard let eventPort = eventPort, let runLoopSource = runLoopSource else { return }
        CGEvent.tapEnable(tap: eventPort, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.eventPort = nil
        self.runLoopSource = nil
        print("EZ Switcher Engine: Stopped")
    }
    
    private func handleKeyDown(proxy: CGEventTapProxy, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Handle Quick Exclusion Hotkey: Cmd + Alt + X
        if keyCode == 7 && flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
            ExclusionManager.shared.toggleActiveApp()
            return nil // Swallow the hotkey
        }
        
        // Handle Manual Correction Hotkey: Cmd + Alt + L (37)
        if keyCode == 37 && flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
            manualCorrectLastWord()
            return nil
        }

        // Check if current app is excluded
        if isCurrentAppExcluded() {
            wordBuffer = ""
            return Unmanaged.passUnretained(event)
        }
        
        // Skip if it's a password field
        if PasswordDetector.shared.isFocusedElementSecure() {
            wordBuffer = ""
            return Unmanaged.passUnretained(event)
        }
        
        // Handle Backspace
        if keyCode == 51 { // Delete key
            if !wordBuffer.isEmpty {
                wordBuffer.removeLast()
            }
            return Unmanaged.passUnretained(event)
        }
        
        // Get character representation
        guard let chars = event.getUnicodeString() else {
            wordBuffer = "" // Reset on non-character keys (Esc, Cmd, etc.)
            return Unmanaged.passUnretained(event)
        }
        
        // Check for word separators (Space: 49, Enter: 36, Punctuation)
        if keyCode == 49 || keyCode == 36 || isPunctuation(chars) {
            let wasSpace = (keyCode == 49)
            processWordEnd(wasSpace: wasSpace)
            
            if wasSpace {
                wordBuffer = ""
                return Unmanaged.passUnretained(event)
            }
        }
        
        // Append to buffer
        wordBuffer += chars
        
        // Real-time check for layout switching
        if wordBuffer.count >= 4 {
            let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
            if let suggestedLayout = LanguageDetectionService.shared.suggestLayoutChange(for: wordBuffer, currentLayout: currentLayout) {
                performCorrection(to: suggestedLayout)
            }
        }
        
        // Real-time check for typography
        if !isCurrentAppExcluded() {
            applyRealTimeTypography()
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func processWordEnd(wasSpace: Bool) {
        if wordBuffer.count >= 3 {
            let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
            if let suggestedLayout = LanguageDetectionService.shared.suggestLayoutChange(for: wordBuffer, currentLayout: currentLayout) {
                performCorrection(to: suggestedLayout)
                return
            }
        }
    }
    
    private func isCurrentAppExcluded() -> Bool {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return false }
        let bundleID = activeApp.bundleIdentifier
        // We could also get window title here if we had more AX permissions
        return ExclusionManager.shared.isExcluded(bundleID: bundleID)
    }
    
    private func isPunctuation(_ chars: String) -> Bool {
        let set = CharacterSet.punctuationCharacters
        return chars.rangeOfCharacter(from: set) != nil
    }
    
    private func applyRealTimeTypography() {
        // Handle immediate replacements that don't need word completion logic
        // Most of these are now handled via TextTransformationService in performCorrection,
        // but we can keep basic ones like double space fix for immediate feedback.
        let currentText = wordBuffer
        
        if settings.typographySettings.doubleSpaceFixEnabled && currentText.hasSuffix("  ") {
            sendKey(keyCode: 51) // Backspace
            wordBuffer = String(wordBuffer.dropLast(1))
        }
    }
    
    private func performCorrection(to layout: LanguageLayout) {
        isProcessing = true
        defer { isProcessing = false }
        
        let originalWord = wordBuffer
        let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
        let translatedWord = originalWord.translating(from: currentLayout, to: layout)
        
        // Apply Typography transformations
        let correctedWord = TextTransformationService.shared.transform(translatedWord, layout: layout, settings: settings.typographySettings)
        
        print("Correcting: '\(originalWord)' -> '\(correctedWord)' using layout \(layout.rawValue)")
        
        // 1. Switch layout
        _ = LayoutSwitcher.shared.switchLayout(toLanguageCode: layout.rawValue)
        
        // 2. Delete the original word
        // We need to send as many backspaces as characters in the buffer
        for _ in 0..<originalWord.count {
            sendKey(keyCode: 51) // Backspace
        }
        
        // 3. Type the corrected word
        typeString(correctedWord)
        
        // 4. Play feedback sound
        if settings.soundEnabled {
            SoundManager.shared.playCorrection()
        }
        
        // 5. Update statistics
        settings.incrementCount(for: layout)
        
        wordBuffer = ""
    }
    
    private func manualCorrectLastWord() {
        // If buffer is empty, we can't correct. 
        // In a more advanced version, we could try to read the selection or use AX to get the last word.
        // For now, we rely on the buffer.
        guard !wordBuffer.isEmpty else { 
            print("Manual correction: Buffer is empty")
            return 
        }
        
        let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
        let suggestedLayout: LanguageLayout = (currentLayout == .english) ? .russian : .english // Toggle
        
        performCorrection(to: suggestedLayout)
    }
    
    
    private func sendKey(keyCode: CGKeyCode) {
        let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    private func typeString(_ string: String) {
        for char in string {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
            var utf16 = Array(String(char).utf16)
            event?.keyboardEventSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            event?.post(tap: .cgAnnotatedSessionEventTap)
            
            let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
            upEvent?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}

extension CGEvent {
    func getUnicodeString() -> String? {
        var length = 0
        keyboardEventGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        if length > 0 {
            var characters = [UniChar](repeating: 0, count: length)
            keyboardEventGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &characters)
            return String(utf16CodeUnits: characters, count: length)
        }
        return nil
    }
}
