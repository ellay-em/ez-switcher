import Foundation
import AppKit

class SoundManager {
    static let shared = SoundManager()
    
    private let switchSound = NSSound(named: "Pop")
    private let errorSound = NSSound(named: "Basso")
    private let enableSound = NSSound(named: "Hero")
    private let disableSound = NSSound(named: "Bottle")
    
    func playSwitch() {
        switchSound?.play()
    }
    
    func playCorrection() {
        switchSound?.play()
    }
    
    func playExclusionToggled(isExcluded: Bool) {
        if isExcluded {
            disableSound?.play()
        } else {
            enableSound?.play()
        }
    }
    
    func playError() {
        errorSound?.play()
    }
}
