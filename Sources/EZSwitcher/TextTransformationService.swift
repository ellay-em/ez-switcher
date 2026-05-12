import Foundation

class TextTransformationService {
    static let shared = TextTransformationService()
    
    private init() {}
    
    func transform(_ text: String, layout: LanguageLayout, settings: TypographySettings) -> String {
        var result = text
        
        if settings.doubleSpaceFixEnabled {
            result = collapseDoubleSpaces(result)
        }
        
        if settings.ellipsisEnabled {
            result = transformEllipsis(result)
        }
        
        if settings.smartDashesEnabled {
            result = transformDashes(result)
        }
        
        if settings.smartQuotesEnabled {
            result = transformQuotes(result, layout: layout)
        }
        
        if settings.orphanControlEnabled {
            result = applyOrphanControl(result, layout: layout)
        }
        
        return result
    }
    
    private func transformQuotes(_ text: String, layout: LanguageLayout) -> String {
        var result = ""
        let chars = Array(text)
        
        let openQuote: String
        let closeQuote: String
        
        switch layout {
        case .english:
            openQuote = "“"
            closeQuote = "”"
        case .russian, .ukrainian:
            openQuote = "«"
            closeQuote = "»"
        }
        
        for i in 0..<chars.count {
            let char = chars[i]
            if char == "\"" || char == "'" {
                // Directional logic
                let isOpening: Bool
                if i == 0 {
                    isOpening = true
                } else {
                    let prevChar = chars[i-1]
                    isOpening = prevChar.isWhitespace || prevChar == "(" || prevChar == "[" || prevChar == "{"
                }
                result += isOpening ? openQuote : closeQuote
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    private func transformDashes(_ text: String) -> String {
        var result = text
        // " - " -> " — "
        result = result.replacingOccurrences(of: " - ", with: " — ")
        
        // "1-10" -> "1–10" (numeric range)
        let pattern = "(\\d)-(\\d)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1–$2")
        }
        
        return result
    }
    
    private func transformEllipsis(_ text: String) -> String {
        return text.replacingOccurrences(of: "...", with: "…")
    }
    
    private func applyOrphanControl(_ text: String, layout: LanguageLayout) -> String {
        guard layout == .russian || layout == .ukrainian else { return text }
        
        // Prepositions and conjunctions that shouldn't stay at the end of a line
        let orphans = ["и", "в", "а", "о", "с", "у", "к", "я", "з", "та", "і"]
        var result = text
        
        for orphan in orphans {
            // Regex to match orphan word preceded by space or start of string
            // and followed by a regular space. Replace that space with non-breaking space (U+00A0)
            let pattern = "(^|\\s)(\(orphan)) "
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(result.startIndex..., in: result)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "$1$2\u{00A0}")
            }
        }
        
        return result
    }
    
    private func collapseDoubleSpaces(_ text: String) -> String {
        var result = text
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return result
    }
}
