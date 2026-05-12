import XCTest
@testable import EZSwitcher

final class TypographyTests: XCTestCase {
    
    func testSmartQuotes() {
        let service = TextTransformationService.shared
        let settings = TypographySettings(smartQuotesEnabled: true)
        
        let enResult = service.transform("Hello \"world\"", layout: .english, settings: settings)
        XCTAssertTrue(enResult.contains("“") || enResult.contains("”"))
        
        let ruResult = service.transform("Привет \"мир\"", layout: .russian, settings: settings)
        XCTAssertTrue(ruResult.contains("«") || ruResult.contains("»"))
    }
    
    func testSmartDashes() {
        let service = TextTransformationService.shared
        let settings = TypographySettings(smartDashesEnabled: true)
        
        let emDashResult = service.transform("Word - word", layout: .english, settings: settings)
        XCTAssertEqual(emDashResult, "Word — word")
        
        let enDashResult = service.transform("1-10", layout: .english, settings: settings)
        XCTAssertEqual(enDashResult, "1–10")
    }
    
    func testEllipsis() {
        let service = TextTransformationService.shared
        let settings = TypographySettings(ellipsisEnabled: true)
        
        let result = service.transform("Wait...", layout: .english, settings: settings)
        XCTAssertEqual(result, "Wait…")
    }
    
    func testOrphanControl() {
        let service = TextTransformationService.shared
        let settings = TypographySettings(orphanControlEnabled: true)
        
        // Russian preposition 'и'
        let ruResult = service.transform("Я и ты", layout: .russian, settings: settings)
        XCTAssertEqual(ruResult, "Я и\u{00A0}ты")
        
        // Ukrainian preposition 'та'
        let uaResult = service.transform("Ми та ви", layout: .ukrainian, settings: settings)
        XCTAssertEqual(uaResult, "Ми та\u{00A0}ви")
    }
    
    func testDoubleSpaceFix() {
        let service = TextTransformationService.shared
        let settings = TypographySettings(doubleSpaceFixEnabled: true)
        
        let result = service.transform("Too  many   spaces", layout: .english, settings: settings)
        XCTAssertEqual(result, "Too many spaces")
    }
}
