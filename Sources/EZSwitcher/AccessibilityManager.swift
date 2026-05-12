import ApplicationServices
import Foundation
import AppKit
import IOKit

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    /// Checks if the application is trusted for accessibility.
    func isTrusted(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Checks if all required permissions (Accessibility + Input Monitoring) are granted.
    func hasAllPermissions() -> Bool {
        return isTrusted() && checkInputMonitoring()
    }
    
    /// Checks if the application has Input Monitoring permissions.
    func checkInputMonitoring() -> Bool {
        if #available(macOS 10.15, *) {
            let status = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
            if status == kIOHIDAccessTypeGranted {
                return true
            }
            
            // Fallback: If IOHIDCheckAccess is being unreliable (common in ad-hoc builds),
            // try to actually create a tap. If it succeeds, we have permission.
            let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
                eventsOfInterest: CGEventMask(eventMask),
                callback: { _, _, _, _ in nil },
                userInfo: nil
            )
            
            return port != nil
        }
        return isTrusted()
    }
    
    /// Requests Input Monitoring permission by attempting to create a dummy event tap.
    /// This is the most reliable way to trigger the system prompt.
    func requestInputMonitoring() {
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, _, _ in nil },
            userInfo: nil
        )
        // We don't need the port, just the side effect of triggering the prompt
    }
    
    /// Opens the System Settings to the specific privacy panel
    func openPrivacySettings(for panel: PrivacyPanel) {
        let urlStrings: [String]
        
        if #available(macOS 13.0, *) {
            // Modern System Settings URLs
            switch panel {
            case .accessibility:
                urlStrings = [
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                    "x-apple.systempreferences:com.apple.Settings.extension.privacy.Accessibility",
                    "x-apple.systempreferences:com.apple.Accessibility-Settings.extension"
                ]
            case .inputMonitoring:
                urlStrings = [
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
                    "x-apple.systempreferences:com.apple.Settings.extension.privacy.InputMonitoring",
                    "x-apple.systempreferences:com.apple.preference.security?Privacy_InputMonitoring"
                ]
            }
        } else {
            // Legacy System Preferences URLs
            switch panel {
            case .accessibility:
                urlStrings = ["x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]
            case .inputMonitoring:
                urlStrings = ["x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"]
            }
        }
        
        // Try each URL until one works
        for urlString in urlStrings {
            if let url = URL(string: urlString) {
                if NSWorkspace.shared.open(url) {
                    print("✅ Opened privacy panel: \(urlString)")
                    return
                }
            }
        }
    }
    
    enum PrivacyPanel {
        case accessibility
        case inputMonitoring
    }
    
    /// Resets TCC permissions for the app. This can help if permissions are stuck.
    /// Note: This will cause the app to quit or be killed by the OS.
    func resetPermissions() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.ezswitcher.app"
        let script = "tccutil reset Accessibility \(bundleID); tccutil reset InputMonitoring \(bundleID)"
        
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["sh", "-c", script]
        try? process.run()
        
        // The app should probably exit after this to allow the user to restart and re-grant
        NSApp.terminate(nil)
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
