import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var hoverEffect: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Primitive.spacingL) {
                header
                
                // Bento Grid Layout for Dashboard
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: DesignSystem.Semantic.padding),
                    GridItem(.flexible(), spacing: DesignSystem.Semantic.padding)
                ], spacing: DesignSystem.Semantic.padding) {
                    
                    // Main Status Card
                    StatusCard()
                        .gridCellColumns(2)
                    
                    // Stats Cards
                    ForEach(settings.stats) { stat in
                        StatCard(stat: stat)
                    }
                }
                
                footer
            }
            .padding(DesignSystem.Semantic.padding * 2)
        }
    }
    
    var header: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(PremiumTheme.primaryGradient.opacity(0.1))
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(PremiumTheme.primaryGradient, lineWidth: 2)
                    .frame(width: 72, height: 72)
                
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(PremiumTheme.primaryGradient)
            }
            .shadow(color: Color(hex: "FF8C00").opacity(0.3), radius: 10, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("EZ Switcher")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(DesignSystem.Semantic.textPrimary)
                
                HStack(spacing: 8) {
                    Text("PROTOTYPE")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Semantic.accent.opacity(0.2))
                        .foregroundColor(DesignSystem.Semantic.accent)
                        .cornerRadius(4)
                    
                    Text("v1.0.0")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(DesignSystem.Semantic.textSecondary)
                }
            }
            Spacer()
        }
    }
    
    var footer: some View {
        VStack(spacing: 12) {
            Divider().background(Color.white.opacity(0.1))
            HStack {
                Label("Engine v1.0", systemImage: "cpu")
                Spacer()
                Text("© 2026 EZ Team • Built for macOS")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(DesignSystem.Semantic.textSecondary)
        }
        .padding(.top, 24)
    }
}

// MARK: - Components

struct StatusCard: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("SYSTEM ENGINE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
                    .kerning(1.2)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(settings.isEnabled ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .shadow(color: (settings.isEnabled ? Color.green : Color.red).opacity(0.5), radius: 4)
                    
                    Text(settings.isEnabled ? "ACTIVE" : "PAUSED")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(DesignSystem.Semantic.textPrimary)
                }
            }
            Spacer()
            
            Toggle("", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
                .scaleEffect(1.3)
                .tint(DesignSystem.Semantic.accent)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PremiumTheme.cardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct StatCard: View {
    let stat: Stat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(stat.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: stat.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(stat.color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stat.value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Semantic.textPrimary)
                
                Text(stat.label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
                    .kerning(0.5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PremiumTheme.cardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.Semantic.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(PremiumTheme.cardGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct TypographySection: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var previewText: String = "Type \"- \" or \"...\" or \"и \" here to see magic"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TYPOGRAPHY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(DesignSystem.Semantic.textSecondary)
                .kerning(1.2)
            
            VStack(spacing: 1) {
                TypographyToggle(title: "Smart Quotes", icon: "quote.opening", isOn: $settings.typographySettings.smartQuotesEnabled)
                TypographyToggle(title: "Smart Dashes", icon: "minus", isOn: $settings.typographySettings.smartDashesEnabled)
                TypographyToggle(title: "Ellipsis", icon: "ellipsis", isOn: $settings.typographySettings.ellipsisEnabled)
                TypographyToggle(title: "Orphan Control", icon: "text.alignleft", isOn: $settings.typographySettings.orphanControlEnabled)
                TypographyToggle(title: "Double Space Fix", icon: "space", isOn: $settings.typographySettings.doubleSpaceFixEnabled)
            }
            .background(PremiumTheme.cardGlass)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Live Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("LIVE PREVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
                
                TextField("Try it out...", text: $previewText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .onChange(of: previewText) { _, newValue in
                        let layout = LayoutSwitcher.shared.currentLanguageLayout()
                        let transformed = TextTransformationService.shared.transform(newValue, layout: layout, settings: settings.typographySettings)
                        if transformed != newValue {
                            previewText = transformed
                        }
                    }
            }
            .padding(.top, 8)
        }
    }
}

struct TypographyToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Semantic.accent)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DesignSystem.Semantic.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .scaleEffect(0.8)
                .tint(DesignSystem.Semantic.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.02))
    }
}
