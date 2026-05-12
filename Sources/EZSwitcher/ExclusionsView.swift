import SwiftUI

struct ExclusionsView: View {
    @ObservedObject var manager = ExclusionManager.shared
    @State private var searchText = ""
    @State private var newTitleKeyword = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("App Exclusions")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(DesignSystem.Semantic.textPrimary)
            
            Text("Excluded apps will not be processed by the language switching engine. Useful for code editors and terminal emulators.")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Semantic.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(spacing: 32) {
                    // Recent Apps Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Currently Running", icon: "app.badge.checkmark")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(manager.recentApps) { app in
                                    RecentAppCard(app: app)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    // Blacklist Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Blacklisted Apps", icon: "shield.slash.fill")
                        
                        if manager.excludedBundleIDs.isEmpty {
                            EmptyStateView(message: "No apps excluded yet")
                        } else {
                            VStack(spacing: 1) {
                                ForEach(Array(manager.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                                    ExcludedAppRow(bundleID: bundleID)
                                }
                            }
                            .background(PremiumTheme.cardGlass)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Window Titles Section
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Window Title Keywords", icon: "text.book.closed.fill")
                        
                        Text("Any window containing these words will be ignored (case-insensitive).")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Semantic.textSecondary)
                        
                        HStack {
                            TextField("Enter keyword (e.g. 'terminal')", text: $newTitleKeyword)
                                .textFieldStyle(.plain)
                                .padding(10)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            
                            Button(action: addTitleKeyword) {
                                Image(systemName: "plus")
                                    .padding(10)
                                    .background(DesignSystem.Semantic.accent)
                                    .foregroundColor(.black)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if manager.excludedWindowTitles.isEmpty {
                            EmptyStateView(message: "No keywords added yet")
                        } else {
                            FlowLayout(spacing: 8, data: manager.excludedWindowTitles) { title in
                                KeywordTag(title: title) {
                                    manager.excludedWindowTitles.removeAll(where: { $0 == title })
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(32)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(DesignSystem.Semantic.accent)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(DesignSystem.Semantic.textSecondary)
                .kerning(1.2)
        }
    }
}

struct RecentAppCard: View {
    let app: RunningAppInfo
    @ObservedObject var manager = ExclusionManager.shared
    
    var isExcluded: Bool {
        manager.excludedBundleIDs.contains(app.bundleID)
    }
    
    var body: some View {
        Button(action: { manager.toggleExclusion(for: app.bundleID) }) {
            VStack(spacing: 12) {
                Image(nsImage: app.icon)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .shadow(radius: 4)
                
                Text(app.name)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(isExcluded ? DesignSystem.Semantic.textSecondary : DesignSystem.Semantic.textPrimary)
                
                Image(systemName: isExcluded ? "minus.circle.fill" : "plus.circle.fill")
                    .foregroundColor(isExcluded ? .red : .green)
                    .font(.system(size: 16))
            }
            .frame(width: 100, height: 120)
            .background(isExcluded ? Color.white.opacity(0.03) : PremiumTheme.cardGlass)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isExcluded ? Color.red.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ExcludedAppRow: View {
    let bundleID: String
    @ObservedObject var manager = ExclusionManager.shared
    
    var body: some View {
        HStack {
            Text(bundleID)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(DesignSystem.Semantic.textPrimary)
            
            Spacer()
            
            Button(action: { manager.toggleExclusion(for: bundleID) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.02))
    }
}

struct EmptyStateView: View {
    var message: String = "No apps excluded yet"
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.Semantic.textSecondary.opacity(0.5))
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(DesignSystem.Semantic.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(PremiumTheme.cardGlass)
        .cornerRadius(16)
    }
}

struct KeywordTag: View {
    let title: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(DesignSystem.Semantic.accent.opacity(0.1))
        .foregroundColor(DesignSystem.Semantic.accent)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(DesignSystem.Semantic.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

// Simple FlowLayout for tags
struct FlowLayout: View {
    var spacing: CGFloat
    var children: [AnyView]
    
    init<Data: Collection, Content: View>(spacing: CGFloat, data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.spacing = spacing
        self.children = data.map { AnyView(content($0)) }
    }
    
    // Simple version for tags
    var body: some View {
        ZStack(alignment: .topLeading) {
            var width = CGFloat.zero
            var height = CGFloat.zero
            
            ForEach(0..<children.count, id: \.self) { index in
                children[index]
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > 300) { // Wrap threshold
                            width = 0
                            height -= d.height + spacing
                        }
                        let result = width
                        if index == children.count - 1 {
                            width = 0 // last item
                        } else {
                            width -= d.width + spacing
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if index == children.count - 1 {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
    }
}

extension ExclusionsView {
    private func addTitleKeyword() {
        let trimmed = newTitleKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !manager.excludedWindowTitles.contains(trimmed) {
            manager.excludedWindowTitles.append(trimmed)
            newTitleKeyword = ""
        }
    }
}
