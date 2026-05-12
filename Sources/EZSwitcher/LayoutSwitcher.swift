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
        let properties = [kTISPropertyInputSourceIsSelectCapable.takeUnretainedValue() as String: true] as CFDictionary
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
        for layout in layouts {
            if let languagesPtr = TISGetInputSourceProperty(layout, kTISPropertyInputSourceLanguages),
               let languages = Unmanaged<CFArray>.fromOpaque(languagesPtr).takeUnretainedValue() as? [String] {
                if languages.contains(where: { $0.hasPrefix(code) }) {
                    switchLayout(to: layout)
                    return true
                }
            }
        }
        return false
    }
}
