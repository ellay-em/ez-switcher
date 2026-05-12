import Foundation
import SwiftUI


enum LanguageLayout: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    case ukrainian = "uk"
}


struct Stat: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let icon: String
    let color: Color
}

struct TypographySettings: Codable {
    var smartQuotesEnabled: Bool = true
    var smartDashesEnabled: Bool = true
    var ellipsisEnabled: Bool = true
    var orphanControlEnabled: Bool = true
    var doubleSpaceFixEnabled: Bool = true
}


