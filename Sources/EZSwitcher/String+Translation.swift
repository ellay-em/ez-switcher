import Foundation

extension String {
    static let enToRuMap: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ъ",
        "a": "ф", "s": "ы", "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д", ";": "ж", "'": "э",
        "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т", "m": "ь", ",": "б", ".": "ю", "/": "."
    ]
    
    static let enToUaMap: [Character: Character] = [
        "q": "й", "w": "ц", "e": "у", "r": "к", "t": "е", "y": "н", "u": "г", "i": "ш", "o": "щ", "p": "з", "[": "х", "]": "ї",
        "a": "ф", "s": "і", "d": "в", "f": "а", "g": "п", "h": "р", "j": "о", "k": "л", "l": "д", ";": "ж", "'": "є",
        "z": "я", "x": "ч", "c": "с", "v": "м", "b": "и", "n": "т", "m": "ь", ",": "б", ".": "ю", "/": "."
    ]
    
    // We can dynamically build reverse maps or combine them
    static var ruToEnMap: [Character: Character] {
        var map = [Character: Character]()
        for (key, value) in enToRuMap { map[value] = key }
        return map
    }
    
    static var uaToEnMap: [Character: Character] {
        var map = [Character: Character]()
        for (key, value) in enToUaMap { map[value] = key }
        return map
    }
    
    func translating(from: LanguageLayout, to: LanguageLayout) -> String {
        // Implement full logic to translate string from one layout to another
        var result = ""
        
        let map: [Character: Character]
        if from == .english && to == .russian { map = String.enToRuMap }
        else if from == .english && to == .ukrainian { map = String.enToUaMap }
        else if from == .russian && to == .english { map = String.ruToEnMap }
        else if from == .ukrainian && to == .english { map = String.uaToEnMap }
        else { return self }
        
        for char in self {
            let lowerChar = Character(char.lowercased())
            let isUpper = char.isUppercase
            
            if let mappedChar = map[lowerChar] {
                result.append(isUpper ? Character(mappedChar.uppercased()) : mappedChar)
            } else {
                result.append(char)
            }
        }
        return result
    }
}

enum LanguageLayout: String {
    case english = "en"
    case russian = "ru"
    case ukrainian = "uk"
}
