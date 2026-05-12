import Carbon
import Foundation

class LayoutSwitcher {
    static let shared = LayoutSwitcher()
    
    private init() {}
    
    /// Returns the currently active input source (keyboard layout)
    func currentLayout() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }
    
    /// Returns a list of all available and switchable keyboard layouts
    func availableLayouts() -> [TISInputSource] {
        let properties = [kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
        let sources = TISCreateInputSourceList(properties, false).takeRetainedValue() as? [TISInputSource]
        return sources ?? []
    }
    
    /// Switches to the specified input source
    func switchLayout(to source: TISInputSource) {
        TISSelectInputSource(source)
    }
    
    /// Switches layout based on language code (e.g., "en", "ru", "uk")
    func switchLayout(toLanguageCode code: String) -> Bool {
        let layouts = availableLayouts()
        print("⌨️ Attempting switch to: \(code). Available layouts: \(layouts.count)")
        for layout in layouts {
            if let languagesPtr = TISGetInputSourceProperty(layout, kTISPropertyInputSourceLanguages),
               let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String] {
                if languages.contains(where: { $0.hasPrefix(code) }) {
                    print("✅ Found matching layout for \(code). Switching...")
                    switchLayout(to: layout)
                    return true
                }
            }
        }
        print("❌ Could not find layout for \(code)")
        return false
    }
    
    func currentLanguageLayout() -> LanguageLayout {
        guard let source = currentLayout(),
              let languagesPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
              let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String] else {
            return .english
        }
        
        if languages.contains(where: { $0.hasPrefix("ru") }) { return .russian }
        if languages.contains(where: { $0.hasPrefix("uk") }) { return .ukrainian }
        return .english
    }
}
