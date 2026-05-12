import SwiftUI

enum DesignSystem {
    // 1. Primitive Tokens (Raw values)
    enum Primitive {
        static let white = Color.white
        static let black = Color.black
        static let gray50 = Color(white: 0.95)
        static let gray100 = Color(white: 0.9)
        static let gray800 = Color(white: 0.12)
        static let gray900 = Color(white: 0.08)
        
        static let brandPrimary = Color(hex: "FF8C00")
        static let brandSecondary = Color(hex: "FF4500")
        
        static let radiusS: CGFloat = 8
        static let radiusM: CGFloat = 14
        static let radiusL: CGFloat = 24
        
        static let spacingS: CGFloat = 8
        static let spacingM: CGFloat = 16
        static let spacingL: CGFloat = 28
    }
    
    // 2. Semantic Tokens (Meaningful names)
    enum Semantic {
        static let background = Primitive.gray900
        static let cardBackground = Color.white.opacity(0.05)
        static let textPrimary = Primitive.white
        static let textSecondary = Primitive.white.opacity(0.6)
        
        static let accent = Primitive.brandPrimary
        static let accentGradient = PremiumTheme.primaryGradient
        
        static let success = Color.green
        static let error = Color.red
        static let info = Color.blue
        
        static let cornerRadius = Primitive.radiusM
        static let padding = Primitive.spacingM
    }
    
    // 3. Component Tokens (Specific to UI elements)
    enum Components {
        static let windowWidth: CGFloat = 520
        static let windowHeight: CGFloat = 680
        
        static let cardShadowRadius: CGFloat = 20
        static let cardShadowOpacity: Double = 0.4
        
        enum Button {
            static let background = Semantic.accentGradient
            static let foreground = Primitive.white
        }
        
        enum Status {
            static let active = Semantic.success
            static let inactive = Semantic.error
        }
    }
    
    // Legacy Theme mapping for compatibility during transition
    enum Theme {
        static let background = Semantic.background
        static let cardBackground = Semantic.cardBackground
        static let accent = Semantic.accent
        static let success = Semantic.success
        static let error = Semantic.error
    }
}
