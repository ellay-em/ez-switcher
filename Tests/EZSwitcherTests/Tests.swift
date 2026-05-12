import Foundation

@main
struct DetectionTests {
    static func main() {
        print("🚀 Running Language Detection Heuristic Tests...")
        
        let service = LanguageDetectionService.shared
        
        let testCases: [(text: String, expected: LanguageLayout)] = [
            ("hello", .english),
            ("world", .english),
            ("привет", .russian),
            ("привіт", .ukrainian),
            ("їжа", .ukrainian),
            ("объявление", .russian),
            ("єдиний", .ukrainian),
            ("экран", .russian),
            ("keyboard", .english),
            ("layouts", .english)
        ]
        
        var passed = 0
        for test in testCases {
            let result = service.detectLanguage(for: test.text)
            if result == test.expected {
                print("✅ [PASS] '\(test.text)' -> \(result?.rawValue ?? "nil")")
                passed += 1
            } else {
                print("❌ [FAIL] '\(test.text)' -> \(result?.rawValue ?? "nil") (Expected: \(test.expected.rawValue))")
            }
        }
        
        let accuracy = Double(passed) / Double(testCases.count) * 100
        print("\n📊 Final Accuracy: \(accuracy)%")
        
        if accuracy >= 95 {
            print("🏆 Goal Achieved!")
        } else {
            print("⚠️ Needs Tuning.")
        }
    }
}
