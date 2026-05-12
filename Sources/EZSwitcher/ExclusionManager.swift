import Cocoa
import SwiftUI

class ExclusionManager: ObservableObject {
    static let shared = ExclusionManager()
    
    @Published var excludedBundleIDs: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedBundleIDs), forKey: "excludedBundleIDs")
        }
    }
    
    @Published var excludedWindowTitles: [String] {
        didSet {
            UserDefaults.standard.set(excludedWindowTitles, forKey: "excludedWindowTitles")
        }
    }
    
    @Published var recentApps: [RunningAppInfo] = []
    
    private let defaultExclusions = [
        "com.googlecode.iterm2",
        "com.apple.systemsettings",
        "com.apple.systempreferences",
        "com.apple.SecurityAgent",
        "com.apple.loginwindow",
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "md.obsidian",
        "com.sublimetext.4",
        "com.unity3d.UnityEditor5.x",
        "com.epicgames.launcher"
    ]
    
    private init() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: "excludedBundleIDs") ?? defaultExclusions
        self.excludedBundleIDs = Set(savedIDs)
        
        self.excludedWindowTitles = UserDefaults.standard.stringArray(forKey: "excludedWindowTitles") ?? [
            "debug", "xcode", "code"
        ]
        
        setupNotification()
        refreshRecentApps()
    }
    
    private func setupNotification() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func appDidActivate(_ notification: Notification) {
        refreshRecentApps()
    }
    
    func refreshRecentApps() {
        let running = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .prefix(15)
            .map { RunningAppInfo(app: $0) }
        
        DispatchQueue.main.async {
            self.recentApps = Array(running)
        }
    }
    
    func toggleExclusion(for bundleID: String) {
        if excludedBundleIDs.contains(bundleID) {
            excludedBundleIDs.remove(bundleID)
        } else {
            excludedBundleIDs.insert(bundleID)
        }
    }
    
    func isExcluded(bundleID: String?, windowTitle: String? = nil) -> Bool {
        if let id = bundleID, excludedBundleIDs.contains(id) {
            return true
        }
        
        let titleToMatch: String?
        if let providedTitle = windowTitle {
            titleToMatch = providedTitle
        } else {
            titleToMatch = getActiveWindowTitle()
        }
        
        if let title = titleToMatch?.lowercased() {
            for pattern in excludedWindowTitles {
                if title.contains(pattern.lowercased()) {
                    print("🚫 App excluded by window title: '\(title)' matches '\(pattern)'")
                    return true
                }
            }
        }
        
        return false
    }
    
    private func getActiveWindowTitle() -> String? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        
        guard result == .success, let appElement = focusedApp as! AXUIElement? else { return nil }
        
        var focusedWindow: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard windowResult == .success, let windowElement = focusedWindow as! AXUIElement? else { return nil }
        
        var title: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title)
        
        guard titleResult == .success, let titleString = title as? String else { return nil }
        
        return titleString
    }
    
    func toggleActiveApp() {
        if let activeApp = NSWorkspace.shared.frontmostApplication,
           let bundleID = activeApp.bundleIdentifier {
            toggleExclusion(for: bundleID)
            
            let isExcluded = excludedBundleIDs.contains(bundleID)
            SoundManager.shared.playExclusionToggled(isExcluded: isExcluded)
            
            print("App \(bundleID) \(isExcluded ? "blacklisted" : "whitelisted")")
        }
    }
}

struct RunningAppInfo: Identifiable {
    let id: String
    let name: String
    let icon: NSImage
    let bundleID: String
    
    init(app: NSRunningApplication) {
        self.id = app.bundleIdentifier ?? UUID().uuidString
        self.name = app.localizedName ?? "Unknown"
        self.icon = app.icon ?? NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns")
        self.bundleID = app.bundleIdentifier ?? ""
    }
}
