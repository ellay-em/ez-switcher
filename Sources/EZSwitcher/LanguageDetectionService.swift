import Foundation
import Combine
import NaturalLanguage

class LanguageDetectionService: ObservableObject {
    static let shared = LanguageDetectionService()
    
    // Unique characters for Ukrainian and Russian
    private let uaUniqueChars = Set("ґєіїҐЄІЇ")
    private let ruUniqueChars = Set("ыэъёЫЭЪЁ")
    
    // Common letters to help distinguish between EN and CYR if no unique chars found
    private let enChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private let cyrChars = Set("абвгдежзийклмнопрстуфхцчшщьюяАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЮЯ")
    
    private let recognizer = NLLanguageRecognizer()
    
    struct DetectionResult {
        let text: String
        let scores: [LanguageLayout: Double]
        let decision: LanguageLayout?
        let duration: Double
    }
    
    @Published var lastResult: DetectionResult?
    
    private init() {}
    
    func suggestLayoutChange(for typedWord: String, currentLayout: LanguageLayout) -> LanguageLayout? {
        guard typedWord.count >= 3 else { return nil }
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let translatedRu = typedWord.translating(from: currentLayout, to: .russian)
        let translatedUa = typedWord.translating(from: currentLayout, to: .ukrainian)
        let translatedEn = typedWord.translating(from: currentLayout, to: .english)
        
        // 1. Evaluate heuristics
        let hRu = evaluateHeuristic(text: translatedRu, expected: .russian)
        let hUa = evaluateHeuristic(text: translatedUa, expected: .ukrainian)
        let hEn = evaluateHeuristic(text: translatedEn, expected: .english)
        
        // 2. Evaluate with NaturalLanguage (if ambiguous or for verification)
        var nlScores: [LanguageLayout: Double] = [:]
        
        // Process EN
        recognizer.reset()
        recognizer.processString(translatedEn)
        let nlEn = recognizer.languageHypotheses(withMaximum: 3)[.english] ?? 0
        
        // Process RU
        recognizer.reset()
        recognizer.processString(translatedRu)
        let nlRu = recognizer.languageHypotheses(withMaximum: 3)[.russian] ?? 0
        
        // Process UA
        recognizer.reset()
        recognizer.processString(translatedUa)
        let nlUa = recognizer.languageHypotheses(withMaximum: 3)[.ukrainian] ?? 0
        
        // 3. Evaluate with CoreML Mock
        let mlScores = CoreMLDetectionProvider.shared.predict(text: typedWord)
        let mlRu = mlScores[.russian] ?? 0
        let mlUa = mlScores[.ukrainian] ?? 0
        let mlEn = mlScores[.english] ?? 0
        
        // Combine scores (Weighted average: 60% heuristic, 30% NL, 10% ML Mock)
        let ruScore = (hRu * 0.6) + (nlRu * 0.3) + (mlRu * 0.1)
        let uaScore = (hUa * 0.6) + (nlUa * 0.3) + (mlUa * 0.1)
        let enScore = (hEn * 0.6) + (nlEn * 0.3) + (mlEn * 0.1)
        
        let scores: [LanguageLayout: Double] = [
            .english: enScore,
            .russian: ruScore,
            .ukrainian: uaScore
        ]
        
        var bestDecision: LanguageLayout? = nil
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        // Pick the best match that is NOT the current layout
        if let best = scores.max(by: { $0.value < $1.value }), best.value > 0.65, best.key != currentLayout {
            bestDecision = best.key
        }
        
        DispatchQueue.main.async {
            self.lastResult = DetectionResult(
                text: typedWord,
                scores: scores,
                decision: bestDecision,
                duration: duration
            )
        }
        
        return bestDecision
    }
    
    private func evaluateHeuristic(text: String, expected: LanguageLayout) -> Double {
        guard !text.isEmpty else { return 0 }
        
        var score = 0.0
        let textLower = text.lowercased()
        let chars = Array(textLower)
        
        switch expected {
        case .english:
            let matchCount = chars.filter { enChars.contains($0) }.count
            score = Double(matchCount) / Double(chars.count)
            
            // Common EN patterns
            let enPatterns = ["th", "he", "in", "er", "an", "re", "nd", "at", "on", "nt", "ion", "tio"]
            for pattern in enPatterns {
                if textLower.contains(pattern) { score += 0.05 }
            }
            
        case .russian:
            let hasRuUnique = chars.contains { ruUniqueChars.contains($0) }
            let hasUaUnique = chars.contains { uaUniqueChars.contains($0) }
            
            if hasRuUnique { score += 0.6 }
            if hasUaUnique { return 0.0 }
            
            let matchCount = chars.filter { cyrChars.contains($0) }.count
            score += (Double(matchCount) / Double(chars.count)) * 0.3
            
            // RU-specific patterns (absent or rare in UA)
            let ruPatterns = ["тся", "ых", "ов ", "ич", "его", "раз", "под", "пред"]
            for pattern in ruPatterns {
                if textLower.contains(pattern) { score += 0.15 }
            }
            
        case .ukrainian:
            let hasUaUnique = chars.contains { uaUniqueChars.contains($0) }
            let hasRuUnique = chars.contains { ruUniqueChars.contains($0) }
            
            if hasUaUnique { score += 0.6 }
            if hasRuUnique { return 0.0 }
            
            let matchCount = chars.filter { cyrChars.contains($0) }.count
            score += (Double(matchCount) / Double(chars.count)) * 0.3
            
            // UA-specific patterns (absent or rare in RU)
            let uaPatterns = ["ння", "цьк", "від", "для", "під", "перед", "всь", "емо"]
            for pattern in uaPatterns {
                if textLower.contains(pattern) { score += 0.15 }
            }
        }
        
        return min(score, 1.0)
    }
.contains(digram) { score += 0.05 }
                }
            }
        }
        
        return min(score, 1.0)
    }
    
    func detectLanguage(for text: String) -> LanguageLayout? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Use the same logic as suggestLayoutChange but without translation (assuming text is already in the layout to check)
        let hRu = evaluateHeuristic(text: text, expected: .russian)
        let hUa = evaluateHeuristic(text: text, expected: .ukrainian)
        let hEn = evaluateHeuristic(text: text, expected: .english)
        
        recognizer.reset()
        recognizer.processString(text)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 3)
        let nlEn = hypotheses[.english] ?? 0
        let nlRu = hypotheses[.russian] ?? 0
        let nlUa = hypotheses[.ukrainian] ?? 0
        
        let ruScore = (hRu * 0.7) + (nlRu * 0.3)
        let uaScore = (hUa * 0.7) + (nlUa * 0.3)
        let enScore = (hEn * 0.7) + (nlEn * 0.3)
        
        let scores: [LanguageLayout: Double] = [.english: enScore, .russian: ruScore, .ukrainian: uaScore]
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        DispatchQueue.main.async {
            self.lastResult = DetectionResult(
                text: text,
                scores: scores,
                decision: nil,
                duration: duration
            )
        }
        
        if let best = scores.max(by: { $0.value < $1.value }), best.value > 0.6 {
            return best.key
        }
        
        return nil
    }
}
