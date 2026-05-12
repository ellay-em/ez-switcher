import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isEnabled: Bool = UserDefaults.standard.bool(forKey: "isEnabled") {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var soundEnabled: Bool = UserDefaults.standard.bool(forKey: "soundEnabled") {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var isDebugEnabled: Bool = UserDefaults.standard.bool(forKey: "isDebugEnabled") {
        didSet { UserDefaults.standard.set(isDebugEnabled, forKey: "isDebugEnabled") }
    }
    
    @Published var correctionsCountEN: Int = UserDefaults.standard.integer(forKey: "stats_en")
    @Published var correctionsCountRU: Int = UserDefaults.standard.integer(forKey: "stats_ru")

    @Published var correctionsCountUA: Int = UserDefaults.standard.integer(forKey: "stats_ua")
    
    @Published var typographySettings: TypographySettings = {
        if let data = UserDefaults.standard.data(forKey: "typographySettings"),
           let settings = try? JSONDecoder().decode(TypographySettings.self, from: data) {
            return settings
        }
        return TypographySettings()
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(typographySettings) {
                UserDefaults.standard.set(data, forKey: "typographySettings")
            }
        }
    }

    
    private init() {
        // Set defaults if not set
        if UserDefaults.standard.object(forKey: "isEnabled") == nil { isEnabled = true }
        if UserDefaults.standard.object(forKey: "soundEnabled") == nil { soundEnabled = true }
    }
    
    func incrementCount(for layout: LanguageLayout) {
        DispatchQueue.main.async {
            switch layout {
            case .english:
                self.correctionsCountEN += 1
                UserDefaults.standard.set(self.correctionsCountEN, forKey: "stats_en")
            case .russian:
                self.correctionsCountRU += 1
                UserDefaults.standard.set(self.correctionsCountRU, forKey: "stats_ru")
            case .ukrainian:
                self.correctionsCountUA += 1
                UserDefaults.standard.set(self.correctionsCountUA, forKey: "stats_ua")
            }
        }
    }
    
    var stats: [Stat] {
        [
            Stat(label: "English", value: "\(correctionsCountEN)", icon: "abc", color: .blue),
            Stat(label: "Russian", value: "\(correctionsCountRU)", icon: "textformat", color: .red),
            Stat(label: "Ukrainian", value: "\(correctionsCountUA)", icon: "textformat.uk", color: .yellow)
        ]
    }
}
