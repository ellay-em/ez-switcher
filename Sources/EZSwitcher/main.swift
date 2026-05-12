import Cocoa
import SwiftUI

// No @main attribute here since this file is named main.swift
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
    var onboardingWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 EZ Switcher is launching...")
        setupStatusItem()
        
        let accGranted = AccessibilityManager.shared.isTrusted()
        let inputGranted = AccessibilityManager.shared.checkInputMonitoring()
        
        print("📊 Permission Status:")
        print("   - Accessibility: \(accGranted ? "✅ GRANTED" : "❌ DENIED")")
        print("   - Input Monitoring: \(inputGranted ? "✅ GRANTED" : "❌ DENIED")")
        
        if accGranted && inputGranted {
            startEngine()
        } else {
            print("👋 Showing Onboarding (Permissions missing)")
            showOnboarding()
        }
        
        // Hide from dock
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func setupStatusItem() {
        print("📦 Setting up Status Item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // Use a more robust symbol
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "EZ Switcher")
            } else {
                button.image = NSImage(named: "AppIcon")
            }
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
            
            button.action = #selector(statusItemClicked)
            button.target = self
            print("💎 Status Item Button created.")
        } else {
            print("❌ Failed to create Status Item Button.")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Fix Permissions...", action: #selector(fixPermissions), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Reset & Clear Permissions", action: #selector(resetPermissions), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func fixPermissions() {
        // First try to just open settings
        AccessibilityManager.shared.openPrivacySettings(for: .accessibility)
        
        // Show a small alert explaining the toggle
        let alert = NSAlert()
        alert.messageText = "Permission Refresh Required"
        alert.informativeText = "Due to the way macOS handles app updates, you must toggle EZ Switcher OFF and then ON in the list to refresh permissions.\n\nIf it still doesn't work, use 'Reset Permissions' from the menu."
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AccessibilityManager.shared.openPrivacySettings(for: .inputMonitoring)
        }
    }
    
    @objc func resetPermissions() {
        let alert = NSAlert()
        alert.messageText = "Reset All Permissions?"
        alert.informativeText = "This will clear the system's permission database for EZ Switcher and quit the app. You will need to re-grant permissions on next launch.\n\nUse this only if 'Fix Permissions' failed."
        alert.addButton(withTitle: "Reset and Quit")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            AccessibilityManager.shared.resetPermissions()
        }
    }
    
    func showOnboarding() {
        if onboardingWindow == nil {
            let contentView = OnboardingView { [weak self] in
                self?.onboardingWindow?.close()
                self?.onboardingWindow = nil
                self?.startEngine()
                
                // Show a small notification or just focus settings
                self?.showSettings()
            }
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 550, height: 650),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered, defer: false)
            window.center()
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: contentView)
            
            onboardingWindow = window
        }
        
        onboardingWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func startEngine() {
        print("⚙️ Starting Layout Monitoring Engine...")
        // Ensure we have permissions before starting
        guard AccessibilityManager.shared.hasAllPermissions() else {
            print("⚠️ Engine start aborted: Missing permissions.")
            showOnboarding()
            return
        }
        
        // Pre-initialize managers
        _ = SoundManager.shared
        _ = DebugOverlayManager.shared
        
        LayoutMonitoringEngine.shared.start()
        print("✅ Engine started successfully.")
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

EZSwitcherApp.main()
