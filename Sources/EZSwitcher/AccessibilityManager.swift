import ApplicationServices
import Foundation

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    /// Checks if the application is trusted for accessibility.
    /// If `prompt` is true, it will prompt the user to grant permission if not already granted.
    func isTrusted(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Waits for the accessibility permission to be granted asynchronously.
    func waitForTrust(completion: @escaping (Bool) -> Void) {
        if isTrusted(prompt: true) {
            completion(true)
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if self.isTrusted(prompt: false) {
                timer.invalidate()
                completion(true)
            }
        }
    }
}
