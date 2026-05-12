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
            if char == "\"" {
                // Directional logic for double quotes
                let isOpening: Bool
                if i == 0 {
                    // Start of buffer - usually opening
                    isOpening = true
                } else if i == chars.count - 1 {
                    // End of buffer (usually a separator) - usually closing
                    isOpening = false
                } else {
                    let prevChar = chars[i-1]
                    let nextChar = chars[i+1]
                    
                    // If followed by a space or punctuation, it's likely closing
                    if nextChar.isWhitespace || ".,!?;:)].".contains(nextChar) {
                        isOpening = false
                    } else if prevChar.isWhitespace || "([{".contains(prevChar) {
                        isOpening = true
                    } else {
                        // Ambiguous case: if followed by alphanumeric, it's opening
                        isOpening = nextChar.isLetter || nextChar.isNumber
                    }
                }
                result += isOpening ? openQuote : closeQuote
            } else if char == "'" {
                // For UA, ' is used as an apostrophe and should be ’ (U+2019)
                // For EN, it can be a quote or apostrophe.
                if layout == .english {
                    let isOpening = (i == 0 || chars[i-1].isWhitespace || "([{".contains(chars[i-1]))
                    result += isOpening ? "‘" : "’"
                } else {
                    // RU/UA: mainly used as apostrophe
                    result += "’" 
                }
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    private func transformDashes(_ text: String) -> String {
        var result = text
        
        // 1. Handle "--" -> "—" (Em-dash)
        result = result.replacingOccurrences(of: "--", with: "—")
        
        // 2. Handle " - " or "- " at start -> " — " (Em-dash with spaces)
        // Note: we use regular spaces here, orphan control will handle NBSP if needed
        result = result.replacingOccurrences(of: " - ", with: " — ")
        if result.hasPrefix("- ") {
            result = "— " + result.dropFirst(2)
        }
        
        // 3. Handle "1-10" -> "1–10" (Numeric range / En-dash)
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
        
        // Prepositions and conjunctions that shouldn't stay at the end of a line (widows/orphans)
        let orphans = ["и", "в", "а", "о", "с", "у", "к", "я", "з", "та", "і", "на", "об", "от", "до", "по", "из", "за", "не", "же", "ли", "бы", "ль", "б"]
        
        var result = text
        for orphan in orphans {
            // Regex to match " orphan " or "^orphan " and replace the trailing space with NBSP
            // This is safer than simple string replacement as it respects word boundaries
            let pattern = "(^|\\s)(\(orphan)) "
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
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
