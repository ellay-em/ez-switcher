import CoreGraphics
import Foundation
import Carbon
import Combine
import AppKit

class LayoutMonitoringEngine {
    static let shared = LayoutMonitoringEngine()
    
    private let settings = SettingsManager.shared
    private let correctionQueue = DispatchQueue(label: "com.ezswitcher.correction", qos: .userInitiated)
    
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var tapThread: Thread?
    private var tapRunLoop: CFRunLoop?

    // Caching state for high-performance access from the tap
    private let stateLock = NSLock()
    private var _isCurrentlyExcluded: Bool = false
    private var _isCurrentlySecure: Bool = false
    
    private var isCurrentlyExcluded: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _isCurrentlyExcluded
    }
    
    private var isCurrentlySecure: Bool {
        stateLock.lock(); defer { stateLock.unlock() }
        return _isCurrentlySecure
    }
    
    // Internal state
    private var wordBuffer: String = ""
    private var isProcessing: Bool = false
    private let processingLock = NSLock()
    
    // Custom event source to tag our own events
    private let eventSource = CGEventSource(stateID: .combinedSessionState)
    private let magicTag: Int64 = 0x455A5357 // "EZSW" in hex
    
    private var cancellables = Set<AnyCancellable>()
    private var mouseMonitor: Any?
    
    private init() {
        settings.$isEnabled
            .sink { [weak self] enabled in
                self?.updateTapState(enabled: enabled)
            }
            .store(in: &cancellables)
    }
    
    private func updateTapState(enabled: Bool) {
        processingLock.lock()
        isProcessing = false
        processingLock.unlock()
        
        guard let eventPort = eventPort else { return }
        CGEvent.tapEnable(tap: eventPort, enable: enabled)
        if !enabled {
            wordBuffer = ""
        }
        
        if enabled {
            setupMouseMonitor()
        } else {
            removeMouseMonitor()
        }
    }
    
    private func setupMouseMonitor() {
        guard mouseMonitor == nil else { return }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            // Async reset of the buffer on mouse click is much safer than an event tap
            self?.wordBuffer = ""
        }
    }
    
    private func removeMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
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
        
        // Start state observers for caching
        setupStateObservers()
        setupMouseMonitor()

        // We ONLY intercept key down. Mouse events are handled via async monitor.
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<LayoutMonitoringEngine>.fromOpaque(refcon).takeUnretainedValue()
            
            // 1. IGNORE EVENTS FROM OURSELVES (Infinite loop protection)
            if event.getIntegerValueField(.eventSourceUserData) == engine.magicTag {
                return Unmanaged.passUnretained(event)
            }
            
            // 2. CHECK IF ENABLED OR ALREADY PROCESSING
            engine.processingLock.lock()
            let shouldSkip = !engine.settings.isEnabled || engine.isProcessing
            engine.processingLock.unlock()
            
            if shouldSkip {
                return Unmanaged.passUnretained(event)
            }
            
            if type == .keyDown {
                return engine.handleKeyDown(proxy: proxy, event: event)
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        print("🛠 Creating Event Tap on Background Thread...")
        
        tapThread = Thread { [weak self] in
            guard let self = self else { return }
            
            self.tapRunLoop = CFRunLoopGetCurrent()
            
            self.eventPort = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
            
            guard let eventPort = self.eventPort else {
                print("❌ CRITICAL: Failed to create event tap.")
                return
            }
            
            self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventPort, 0)
            CFRunLoopAddSource(self.tapRunLoop, self.runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventPort, enable: true)
            
            print("✅ EZ Switcher Engine: Background thread active.")
            CFRunLoopRun()
        }
        
        tapThread?.qualityOfService = .userInteractive
        tapThread?.name = "com.ezswitcher.eventtap"
        tapThread?.start()
    }
    
    private func setupStateObservers() {
        // Observe app changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCachedState()
        }
        
        // Initial state
        refreshCachedState()
        
        // Periodically refresh state in case AX notifications are missed
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.refreshCachedState()
        }
    }
    
    private func refreshCachedState() {
        // Perform heavy AX and Workspace calls on main thread and update cache
        let isExcluded = self.isCurrentAppExcluded()
        let isSecure = PasswordDetector.shared.isFocusedElementSecure()
        
        stateLock.lock()
        let previousExcluded = self._isCurrentlyExcluded
        self._isCurrentlyExcluded = isExcluded
        self._isCurrentlySecure = isSecure
        stateLock.unlock()
        
        // Proactively disable/enable tap if exclusion state changed
        if isExcluded != previousExcluded {
            if let port = eventPort {
                // If the app is excluded (e.g. System Settings), we COMPLETELY disable the tap
                // to avoid any potential mouse hijacking or security throttling from macOS.
                CGEvent.tapEnable(tap: port, enable: !isExcluded && settings.isEnabled)
                print("🕹 Tap state updated: \(isExcluded ? "PAUSED (Excluded App)" : "ACTIVE")")
            }
        }
    }
    
    func stop() {
        DistributedNotificationCenter.default().removeObserver(self)
        removeMouseMonitor()
        
        if let runLoop = tapRunLoop, let source = runLoopSource {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
            CFRunLoopStop(runLoop)
        }
        
        if let eventPort = eventPort {
            CGEvent.tapEnable(tap: eventPort, enable: false)
        }
        
        self.eventPort = nil
        self.runLoopSource = nil
        self.tapRunLoop = nil
        self.tapThread = nil
        
        print("EZ Switcher Engine: Stopped")
    }
    
    private func handleKeyDown(proxy: CGEventTapProxy, event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // Handle Quick Exclusion Hotkey: Cmd + Alt + X
        if keyCode == 7 && flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
            ExclusionManager.shared.toggleActiveApp()
            return nil
        }
        
        // Handle Manual Correction Hotkey: Cmd + Alt + L
        if keyCode == 37 && flags.contains(.maskCommand) && flags.contains(.maskAlternate) {
            manualCorrectLastWord()
            return nil
        }

        // Use cached state for instant response in the event tap
        if isCurrentlyExcluded || isCurrentlySecure {
            wordBuffer = ""
            return Unmanaged.passUnretained(event)
        }
        
        // Handle Backspace
        if keyCode == 51 {
            if !wordBuffer.isEmpty {
                wordBuffer.removeLast()
            }
            return Unmanaged.passUnretained(event)
        }
        
        // Get character representation
        guard let chars = event.getUnicodeString() else {
            let isModifier = [54, 55, 56, 57, 58, 59, 60, 61, 62].contains(keyCode)
            if !isModifier {
                wordBuffer = ""
            }
            return Unmanaged.passUnretained(event)
        }
        
        // Check for word separators
        if keyCode == 49 || keyCode == 36 || (isPunctuation(chars) && !isBufferablePunctuation(chars)) {
            let bufferToProcess = wordBuffer
            wordBuffer = ""
            
            // Capture the actual separator char (space, newline, or punctuation)
            let separator = chars
            
            // Background process word end to unblock the main thread
            correctionQueue.async {
                self.processWordEndAsync(buffer: bufferToProcess, separator: separator)
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        // Append to buffer
        wordBuffer += chars
        
        // Real-time check for layout switching (min 6 chars)
        if wordBuffer.count >= 6 {
            let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
            if let suggestedLayout = LanguageDetectionService.shared.suggestLayoutChange(for: wordBuffer, currentLayout: currentLayout) {
                let bufferToCorrect = wordBuffer
                wordBuffer = ""
                
                // Background correction to avoid blocking the main thread during typing simulation
                correctionQueue.async {
                    self.performCorrection(originalWord: bufferToCorrect, to: suggestedLayout)
                }
                return nil // Swallow the key that triggered correction
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func processWordEndAsync(buffer: String, separator: String) {
        let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
        let suggestedLayout = LanguageDetectionService.shared.suggestLayoutChange(for: buffer, currentLayout: currentLayout)
        
        if let layout = suggestedLayout {
            performCorrection(originalWord: buffer, to: layout, separator: separator)
        } else {
            // Apply typography even if no layout switch is needed
            applyTypographyOnly(word: buffer, layout: currentLayout, separator: separator)
        }
    }
    
    private func applyTypographyOnly(word: String, layout: LanguageLayout, separator: String) {
        // We trigger if word is not empty OR if the separator itself is something we can transform (like - or ...)
        guard !word.isEmpty || isBufferablePunctuation(separator) else { return }
        
        let textToTransform = word + separator
        let transformed = TextTransformationService.shared.transform(textToTransform, layout: layout, settings: settings.typographySettings)
        
        if transformed != textToTransform {
            print("🖋 Typography: '\(textToTransform)' -> '\(transformed)'")
            
            processingLock.lock()
            isProcessing = true
            processingLock.unlock()
            
            defer {
                processingLock.lock()
                isProcessing = false
                processingLock.unlock()
            }
            
            // Delete the original word and separator
            let backspaceCount = word.count + separator.count
            
            print("  [Typo] Deleting \(backspaceCount) chars ('\(word)\(separator)')")
            for _ in 0..<backspaceCount {
                sendKey(keyCode: 51) // Backspace
                usleep(8000)
            }
            
            // Stabilization delay
            usleep(20000)
            
            // Type the corrected text (already includes the transformed separator if applicable)
            print("  [Typo] Typing '\(transformed)'")
            typeString(transformed)
        }
    }
    
    private func isCurrentAppExcluded() -> Bool {
        guard let activeApp = NSWorkspace.shared.frontmostApplication else { return false }
        let bundleID = activeApp.bundleIdentifier
        if let id = bundleID {
            print("🔍 Checking exclusion for: \(id)")
        }
        // We could also get window title here if we had more AX permissions
        return ExclusionManager.shared.isExcluded(bundleID: bundleID)
    }
    
    private func isPunctuation(_ chars: String) -> Bool {
        let set = CharacterSet.punctuationCharacters
        return chars.rangeOfCharacter(from: set) != nil
    }
    
    private func isBufferablePunctuation(_ chars: String) -> Bool {
        // These characters stay in the buffer to allow for context-aware typography
        let bufferable = "\".-'" // Double quote, Dot, Hyphen, Single quote/Apostrophe
        return chars.count == 1 && bufferable.contains(chars)
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
    
    @discardableResult
    private func performCorrection(originalWord: String, to layout: LanguageLayout, separator: String? = nil) {
        processingLock.lock()
        isProcessing = true
        processingLock.unlock()
        
        defer {
            processingLock.lock()
            isProcessing = false
            processingLock.unlock()
        }
        
        let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
        let translatedWord = originalWord.translating(from: currentLayout, to: layout)
        
        // Combine with separator for full typography context (e.g. dash + space)
        let sep = separator ?? ""
        let combinedTranslated = translatedWord + sep
        
        // Apply Typography transformations on the whole sequence
        let correctedText = TextTransformationService.shared.transform(combinedTranslated, layout: layout, settings: settings.typographySettings)
        
        print("✨ Correcting: '\(originalWord)\(sep)' -> '\(correctedText)' using layout \(layout.rawValue)")
        
        // 1. Switch layout
        _ = LayoutSwitcher.shared.switchLayout(toLanguageCode: layout.rawValue)
        
        // 2. Calculate how many characters to delete
        let backspaceCount: Int
        if let sep = separator {
            // Word-end correction: everything is in the app
            backspaceCount = originalWord.count + sep.count
        } else {
            // Real-time correction: the trigger char was swallowed, so WordCount-1 in app
            backspaceCount = originalWord.count - 1
        }
        
        print("  [Correction] Deleting \(backspaceCount) chars")
        for _ in 0..<backspaceCount {
            sendKey(keyCode: 51) // Backspace
            usleep(8000)
        }
        
        // Stabilization delay
        usleep(20000) 
        
        // 3. Type the corrected text (includes transformed separator)
        print("  [Correction] Typing '\(correctedText)'")
        typeString(correctedText)
        
        // 4. Play feedback sound
        if settings.soundEnabled {
            SoundManager.shared.playCorrection()
        }
        
        // 5. Update statistics
        settings.incrementCount(for: layout)
        
        isProcessing = false
    }
    
    private func manualCorrectLastWord() {
        guard !wordBuffer.isEmpty else { return }
        
        let original = wordBuffer
        wordBuffer = ""
        
        let currentLayout = LayoutSwitcher.shared.currentLanguageLayout()
        let suggestedLayout: LanguageLayout = (currentLayout == .english) ? .russian : .english // Toggle
        
        correctionQueue.async {
            self.performCorrection(originalWord: original, to: suggestedLayout)
        }
    }
    
    
    private func sendKey(keyCode: CGKeyCode) {
        let source = self.eventSource
        let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        
        // Explicitly tag the event just in case the source identity isn't enough
        down?.setIntegerValueField(.eventSourceUserData, value: magicTag)
        up?.setIntegerValueField(.eventSourceUserData, value: magicTag)
        
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
    
    private func typeString(_ string: String) {
        let source = self.eventSource
        for char in string {
            let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            var utf16 = Array(String(char).utf16)
            event?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: &utf16)
            
            // Tag it
            event?.setIntegerValueField(.eventSourceUserData, value: magicTag)
            event?.post(tap: .cgAnnotatedSessionEventTap)
            
            let upEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            upEvent?.setIntegerValueField(.eventSourceUserData, value: magicTag)
            upEvent?.post(tap: .cgAnnotatedSessionEventTap)
            usleep(8000) // 8ms between characters for better target app compatibility
        }
    }
}

extension CGEvent {
    func getUnicodeString() -> String? {
        var length = 0
        self.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        if length > 0 {
            var characters = [UniChar](repeating: 0, count: length)
            self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &characters)
            return String(utf16CodeUnits: characters, count: length)
        }
        return nil
    }
}
