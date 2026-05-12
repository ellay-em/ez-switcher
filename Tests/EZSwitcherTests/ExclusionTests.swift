import XCTest
@testable import EZSwitcher

final class ExclusionTests: XCTestCase {
    var manager: ExclusionManager!
    
    override func setUp() {
        super.setUp()
        manager = ExclusionManager.shared
        // Reset to defaults
        UserDefaults.standard.removeObject(forKey: "excludedBundleIDs")
        UserDefaults.standard.removeObject(forKey: "excludedWindowTitles")
    }
    
    func testDefaultExclusions() {
        XCTAssertTrue(manager.isExcluded(bundleID: "com.apple.Terminal"))
        XCTAssertTrue(manager.isExcluded(bundleID: "com.microsoft.VSCode"))
        XCTAssertFalse(manager.isExcluded(bundleID: "com.apple.Safari"))
    }
    
    func testWindowTitleExclusion() {
        XCTAssertTrue(manager.isExcluded(bundleID: "com.test.app", windowTitle: "My Terminal Window"))
        XCTAssertTrue(manager.isExcluded(bundleID: nil, windowTitle: "Xcode Debug Console"))
        XCTAssertFalse(manager.isExcluded(bundleID: nil, windowTitle: "Google Search"))
    }
    
    func testToggleExclusion() {
        let bundleID = "com.apple.Safari"
        XCTAssertFalse(manager.isExcluded(bundleID: bundleID))
        
        manager.toggleExclusion(for: bundleID)
        XCTAssertTrue(manager.isExcluded(bundleID: bundleID))
        
        manager.toggleExclusion(for: bundleID)
        XCTAssertFalse(manager.isExcluded(bundleID: bundleID))
    }
}
