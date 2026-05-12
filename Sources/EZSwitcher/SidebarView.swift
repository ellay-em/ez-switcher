import SwiftUI

struct SidebarView: View {
    @State private var selectedSection: SidebarSection? = .dashboard
    
    enum SidebarSection: Hashable, CaseIterable {
        case dashboard
        case typography
        case exclusions
        case settings
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .typography: return "Typography"
            case .exclusions: return "Exclusions"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "gauge.medium"
            case .typography: return "textformat"
            case .exclusions: return "shield.slash"
            case .settings: return "gearshape"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, id: \.self, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.icon)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .navigationTitle("EZ Switcher")
            .listStyle(.sidebar)
            .frame(minWidth: 200)
            .background(DesignSystem.Semantic.background.opacity(0.5))
        } detail: {
            if let section = selectedSection {
                detailView(for: section)
            } else {
                Text("Select a section")
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    @ViewBuilder
    private func detailView(for section: SidebarSection) -> some View {
        ZStack {
            DesignSystem.Semantic.background.ignoresSafeArea()
            
            // Decorative background (shared)
            Circle()
                .fill(PremiumTheme.primaryGradient.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -200, y: -250)
            
            switch section {
            case .dashboard:
                SettingsView() // Existing dashboard logic
            case .typography:
                TypographyDetailView()
            case .exclusions:
                ExclusionsView()
            case .settings:
                AdvancedSettingsView()
            }
        }
    }
}

struct TypographyDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Typography Engine")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(DesignSystem.Semantic.textPrimary)
                
                Text("Enhance your typing experience with smart corrections and formatting.")
                    .font(.system(size: 16))
                    .foregroundColor(DesignSystem.Semantic.textSecondary)
                
                TypographySection() // Reusing existing component
            }
            .padding(40)
        }
    }
}

struct AdvancedSettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("System Settings")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(DesignSystem.Semantic.textPrimary)
                
                VStack(spacing: 20) {
                    ToggleCard(
                        title: "Smart Sound",
                        subtitle: "Audio feedback on switch",
                        icon: settings.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                        color: Color(hex: "8E2DE2"),
                        isOn: $settings.soundEnabled
                    )
                    
                    ToggleCard(
                        title: "AI Debugger",
                        subtitle: "Visualize detection scores",
                        icon: settings.isDebugEnabled ? "ant.fill" : "ant",
                        color: Color(hex: "F2994A"),
                        isOn: $settings.isDebugEnabled
                    )
                    
                    // Reset Stats Button
                    Button(action: { settings.resetStats() }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Statistics")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                }
            }
            .padding(40)
        }
    }
}
