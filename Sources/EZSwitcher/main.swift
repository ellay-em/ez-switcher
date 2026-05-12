import Cocoa
import SwiftUI

// This file is the entry point for the EZSwitcher application.

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Starting EZ Switcher...")
        
        AccessibilityManager.shared.waitForTrust { isTrusted in
            if isTrusted {
                print("Accessibility permissions granted.")
                LayoutMonitoringEngine.shared.start()
            } else {
                print("Failed to get accessibility permissions.")
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        LayoutMonitoringEngine.shared.stop()
    }
}

// Ensure the app runs as an agent (no dock icon initially)
// In a real app this is typically done in Info.plist via LSUIElement.
// Since we're running from SPM executable, we set the activation policy directly.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
