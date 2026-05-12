import Foundation
import NaturalLanguage

class LanguageDetector {
    static let shared = LanguageDetector()
    private let recognizer = NLLanguageRecognizer()
    
    private init() {}
    
    /// Analyzes the input string and suggests a layout change if it strongly matches another language.
    /// Returns the suggested target layout, or nil if no change is needed.
    func suggestLayoutChange(for typedWord: String, currentLayout: LanguageLayout) -> LanguageLayout? {
        // Only evaluate words with at least 3 characters
        guard typedWord.count >= 3 else { return nil }
        
        let translatedRu = typedWord.translating(from: currentLayout, to: .russian)
        let translatedUa = typedWord.translating(from: currentLayout, to: .ukrainian)
        let translatedEn = typedWord.translating(from: currentLayout, to: .english) // In case current is RU/UA
        
        var scores: [LanguageLayout: Double] = [:]
        
        scores[currentLayout] = evaluateLanguage(text: typedWord, expected: currentLayout)
        
        if currentLayout == .english {
            scores[.russian] = evaluateLanguage(text: translatedRu, expected: .russian)
            scores[.ukrainian] = evaluateLanguage(text: translatedUa, expected: .ukrainian)
        } else {
            scores[.english] = evaluateLanguage(text: translatedEn, expected: .english)
            if currentLayout == .russian {
                scores[.ukrainian] = evaluateLanguage(text: translatedUa, expected: .ukrainian)
            } else {
                scores[.russian] = evaluateLanguage(text: translatedRu, expected: .russian)
            }
        }
        
        // Find the layout with the maximum score
        if let bestMatch = scores.max(by: { $0.value < $1.value }),
           bestMatch.value > 0.6, // Confidence threshold
           bestMatch.key != currentLayout {
            
            // Special rule for Russian vs Ukrainian:
            // Since they share many characters, prefer Ukrainian if specific characters (ї, є, і, ґ) are present in the translated text.
            if bestMatch.key == .russian || bestMatch.key == .ukrainian {
                let textToCheck = bestMatch.key == .russian ? translatedRu : translatedUa
                if textToCheck.contains(where: { "їєіґЇЄІҐ".contains($0) }) {
                    return .ukrainian
                }
            }
            
            return bestMatch.key
        }
        
        return nil
    }
    
    private func evaluateLanguage(text: String, expected: LanguageLayout) -> Double {
        recognizer.reset()
        recognizer.processString(text)
        
        let nlLanguage: NLLanguage
        switch expected {
        case .english: nlLanguage = .english
        case .russian: nlLanguage = .russian
        case .ukrainian: nlLanguage = .ukrainian
        }
        
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        return hypotheses[nlLanguage] ?? 0.0
    }
}
