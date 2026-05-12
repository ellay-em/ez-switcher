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
        guard typedWord.count >= 2 else { return nil }
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let translatedRu = typedWord.translating(from: currentLayout, to: .russian)
        let translatedUa = typedWord.translating(from: currentLayout, to: .ukrainian)
        let translatedEn = typedWord.translating(from: currentLayout, to: .english)
        
        // 1. Evaluate heuristics
        let hRu = evaluateHeuristic(text: translatedRu, expected: .russian)
        let hUa = evaluateHeuristic(text: translatedUa, expected: .ukrainian)
        let hEn = evaluateHeuristic(text: translatedEn, expected: .english)
        
        // 2. Evaluate with NaturalLanguage (if ambiguous or for verification)
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
        
        // Combine scores (Weighted average: 80% heuristic, 20% NL, 0% ML Mock)
        let ruScore = (hRu * 0.8) + (nlRu * 0.2) + (mlRu * 0.0)
        let uaScore = (hUa * 0.8) + (nlUa * 0.2) + (mlUa * 0.0)
        let enScore = (hEn * 0.8) + (nlEn * 0.2) + (mlEn * 0.0)
        
        let scores: [LanguageLayout: Double] = [
            .english: enScore,
            .russian: ruScore,
            .ukrainian: uaScore
        ]
        
        var bestDecision: LanguageLayout? = nil
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        let currentScore = scores[currentLayout] ?? 0
        
        // Pick the best match that is NOT the current layout
        var minThreshold = 0.70 
        var marginRequirement = 0.15 
        
        // Lower thresholds for short words to increase sensitivity
        if typedWord.count == 2 {
            minThreshold = 0.60
            marginRequirement = 0.10
        }
        
        if let best = scores.max(by: { $0.value < $1.value }), 
           best.value >= minThreshold,
           best.key != currentLayout,
           best.value > (currentScore + marginRequirement) {
            
            bestDecision = best.key
            print("🧠 Decision: Switch to \(best.key.rawValue) (Score: \(String(format: "%.2f", best.value)), Current Score: \(String(format: "%.2f", currentScore)), Margin OK)")
        } else if let best = scores.max(by: { $0.value < $1.value }) {
            if best.key == currentLayout {
                print("🧠 Decision: Stay on \(currentLayout.rawValue) (Score: \(String(format: "%.2f", best.value)))")
            } else {
                print("🧠 Decision: Ambiguous or low margin (Best: \(best.key.rawValue) \(String(format: "%.2f", best.value)), Current: \(String(format: "%.2f", currentScore)))")
            }
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
        let vowels = Set("aeiouy")
        let cyrVowels = Set("аеёиоуыэюяіїє")
        
        switch expected {
        case .english:
            let matchCount = chars.filter { enChars.contains($0) }.count
            let vowelCount = chars.filter { vowels.contains($0) }.count
            
            // Base score from character ratio (max 0.6)
            score = (Double(matchCount) / Double(chars.count)) * 0.6
            
            // Bonus for having vowels (0.1)
            if vowelCount > 0 {
                score += 0.1
            } else if chars.count >= 2 {
                score -= 0.3 // Penalty for no vowels in EN (except single letters)
            }
            
            // Common EN patterns/words (0.1)
            let enPatterns = ["th", "he", "in", "er", "an", "re", "nd", "at", "on", "nt", "ion", "tio", "google", "apple", "http", "www"]
            for pattern in enPatterns {
                if textLower == pattern || textLower.contains(pattern) { 
                    score += 0.1 
                    break 
                }
            }
            
        case .russian:
            let hasRuUnique = chars.contains { ruUniqueChars.contains($0) }
            let hasUaUnique = chars.contains { uaUniqueChars.contains($0) }
            
            if hasRuUnique { score += 0.3 }
            if hasUaUnique { return 0.0 }
            
            let matchCount = chars.filter { cyrChars.contains($0) }.count
            let vowelCount = chars.filter { cyrVowels.contains($0) }.count
            
            // Base score from Cyrillic character ratio (max 0.6)
            score += (Double(matchCount) / Double(chars.count)) * 0.6
            
            // Vowel check (0.1)
            if vowelCount > 0 {
                score += 0.1
            }
            
            // RU-specific patterns (short words and common prefixes/suffixes)
            let ruPatterns = ["тся", "ых", "ов ", "ич", "его", "раз", "под", "пред", "пр", "ст", "ко", "но", "про", "пере", "на", "за", "от", "до", "не", "ну", "да", "он", "мы", "вы", "ты", "то", "же", "ли", "бы", "по", "из", "об", "во", "со"]
            for pattern in ruPatterns {
                if textLower == pattern || textLower.contains(pattern) { 
                    score += 0.1 
                }
            }
            
            // Common RU words/endings
            if textLower.hasSuffix("ие") || textLower.hasSuffix("ия") || textLower.hasSuffix("ую") {
                score += 0.1
            }
            
        case .ukrainian:
            let hasUaUnique = chars.contains { uaUniqueChars.contains($0) }
            let hasRuUnique = chars.contains { ruUniqueChars.contains($0) }
            
            if hasUaUnique { score += 0.3 }
            if hasRuUnique { return 0.0 }
            
            let matchCount = chars.filter { cyrChars.contains($0) }.count
            let vowelCount = chars.filter { cyrVowels.contains($0) }.count
            
            // Base score (max 0.6)
            score += (Double(matchCount) / Double(chars.count)) * 0.6
            
            // Vowel check (0.1)
            if vowelCount > 0 {
                score += 0.1
            }
            
            // UA-specific patterns (short words and common prefixes/suffixes)
            let uaPatterns = ["ння", "цьк", "від", "для", "під", "перед", "всь", "емо", "та", "що", "як", "про", "при", "на", "за", "від", "не", "ну", "так", "він", "ми", "ви", "ти", "то", "же", "чи", "би", "по", "із", "об", "во", "зі"]
            for pattern in uaPatterns {
                if textLower == pattern || textLower.contains(pattern) {
                    score += 0.1
                }
            }
            
            if textLower.hasSuffix("ий") || textLower.hasSuffix("ому") || textLower.hasSuffix("ти") {
                score += 0.1
            }
        }
        
        let finalScore = max(0, min(score, 1.0))
        print("   - Heuristic for \(expected.rawValue): \(String(format: "%.2f", finalScore)) (Text: '\(text)')")
        return finalScore
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
