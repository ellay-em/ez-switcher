import XCTest
@testable import EZSwitcher

final class HeuristicTests: XCTestCase {
    let service = LanguageDetectionService.shared
    
    func testRussianDetection() {
        let samples = [
            "привет",
            "хорошо",
            "компьютер",
            "программирование",
            "работает",
            "быстро", // contains 'ы' (RU unique)
            "это",    // contains 'э' (RU unique)
            "объект"  // contains 'ъ' (RU unique)
        ]
        
        for sample in samples {
            let result = service.detectLanguage(for: sample)
            XCTAssertEqual(result, .russian, "Failed to detect Russian for: \(sample)")
        }
    }
    
    func testUkrainianDetection() {
        let samples = [
            "привіт",  // contains 'і' (UA unique)
            "добре",
            "комп'ютер",
            "програмування", // contains 'нн' (common UA)
            "працює",  // contains 'є' (UA unique)
            "швидко",
            "це",
            "об'єкт",
            "ґанок"    // contains 'ґ' (UA unique)
        ]
        
        for sample in samples {
            let result = service.detectLanguage(for: sample)
            XCTAssertEqual(result, .ukrainian, "Failed to detect Ukrainian for: \(sample)")
        }
    }
    
    func testEnglishDetection() {
        let samples = [
            "hello",
            "world",
            "computer",
            "programming",
            "works",
            "fast",
            "this",
            "object"
        ]
        
        for sample in samples {
            let result = service.detectLanguage(for: sample)
            XCTAssertEqual(result, .english, "Failed to detect English for: \(sample)")
        }
    }
}
