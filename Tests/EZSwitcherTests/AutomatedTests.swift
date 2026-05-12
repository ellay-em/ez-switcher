import XCTest
@testable import EZSwitcher

final class AutomatedTests: XCTestCase {
    
    func testIntegratedCorrectionFlow() {
        let engine = LayoutMonitoringEngine.shared
        let settings = SettingsManager.shared
        
        // 1. Setup settings
        settings.typographySettings.smartQuotesEnabled = true
        settings.typographySettings.smartDashesEnabled = true
        settings.typographySettings.ellipsisEnabled = true
        
        // 2. Mock a correction scenario
        // Since we can't easily mock the CGEventTap in a unit test, 
        // we test the transformation pipeline which is the core logic.
        
        let testCases: [(input: String, layout: LanguageLayout, expected: String)] = [
            ("Hello \"world\"", .english, "Hello “world”"),
            ("Привет \"мир\"", .russian, "Привет «мир»"),
            ("Wait...", .english, "Wait…"),
            ("Word - word", .english, "Word — word"),
            ("Я и ты", .russian, "Я и\u{00A0}ты")
        ]
        
        for testCase in testCases {
            let transformed = TextTransformationService.shared.transform(
                testCase.input, 
                layout: testCase.layout, 
                settings: settings.typographySettings
            )
            XCTAssertEqual(transformed, testCase.expected, "Failed for input: \(testCase.input)")
        }
    }
    
    func testExclusionLogic() {
        let manager = ExclusionManager.shared
        
        // Mock bundle ID exclusion
        manager.toggleExclusion(for: "com.apple.Numbers")
        XCTAssertTrue(manager.isExcluded(bundleID: "com.apple.Numbers"))
        
        // Mock window title exclusion
        manager.excludedWindowTitles.append("SensitiveData")
        XCTAssertTrue(manager.isExcluded(bundleID: "com.any.app", windowTitle: "My SensitiveData Window"))
        
        // Cleanup
        manager.toggleExclusion(for: "com.apple.Numbers")
        manager.excludedWindowTitles.removeAll(where: { $0 == "SensitiveData" })
    }
    
    func testLanguageDetectionHeuristics() {
        let detector = LanguageDetectionService.shared
        
        // RU unique char: ы
        let ruScore = detector.score(for: "рыба", layout: .russian)
        XCTAssertGreaterThan(ruScore, 0.5)
        
        // UA unique char: і
        let uaScore = detector.score(for: "привіт", layout: .ukrainian)
        XCTAssertGreaterThan(uaScore, 0.5)
    }
}
