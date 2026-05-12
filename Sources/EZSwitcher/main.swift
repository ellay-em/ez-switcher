import Cocoa
import SwiftUI

@main
struct EZSwitcherApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        startEngine()
        
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemName: "keyboard")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    private func startEngine() {
        AccessibilityManager.shared.waitForTrust { isTrusted in
            if isTrusted {
                // Pre-initialize managers
                _ = SoundManager.shared
                _ = DebugOverlayManager.shared
                
                LayoutMonitoringEngine.shared.start()
            }
        }
    }
    
    @objc func statusItemClicked() {
        // Handle left click if needed, or menu will show on right click/left click by default if menu is set
    }
    
    @objc func showSettings() {
        if settingsWindow == nil {
            let contentView = SidebarView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 850, height: 650),
                styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.contentView = NSHostingView(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
            settingsWindow = window
            
            // Bring to front
            NSApp.activate(ignoringOtherApps: true)
        } else {
            settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
