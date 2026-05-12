import SwiftUI

struct OnboardingView: View {
    @State private var isAccessibilityGranted = false
    @State private var isInputMonitoringGranted = false
    @State private var timer: Timer?
    
    @State private var showingResetAlert = false
    
    var onCompletion: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Theme.accent)
                    .padding(.bottom, 10)
                
                Text("Permissions Required")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("EZ Switcher needs these permissions to monitor your keyboard and automatically switch layouts.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Permission Cards
            VStack(spacing: 16) {
                PermissionCard(
                    title: "Accessibility",
                    description: "Allows detecting active apps and secure fields.",
                    isGranted: isAccessibilityGranted,
                    icon: "accessibility",
                    action: {
                        _ = AccessibilityManager.shared.isTrusted(prompt: true)
                        AccessibilityManager.shared.openPrivacySettings(for: .accessibility)
                    }
                )
                
                PermissionCard(
                    title: "Input Monitoring",
                    description: "Allows the engine to intercept keyboard events.",
                    isGranted: isInputMonitoringGranted,
                    icon: "keyboard",
                    action: {
                        AccessibilityManager.shared.requestInputMonitoring()
                        AccessibilityManager.shared.openPrivacySettings(for: .inputMonitoring)
                    }
                )
            }
            .padding(.horizontal, 40)
            
            // Footer
            VStack(spacing: 16) {
                if isAccessibilityGranted && isInputMonitoringGranted {
                    Button(action: onCompletion) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 44)
                            .background(DesignSystem.Theme.accent)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Please grant both permissions to continue.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        Button("I've granted permissions") {
                            checkPermissions()
                        }
                        .buttonStyle(.link)
                        
                        Button("Reset Permissions...") {
                            showingResetAlert = true
                        }
                        .buttonStyle(.link)
                        .foregroundColor(.red)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 500, height: 620)
        .background(Color(NSColor.windowBackgroundColor))
        .alert(isPresented: $showingResetAlert) {
            Alert(
                title: Text("Reset Permissions?"),
                message: Text("This will clear all EZ Switcher permissions from System Settings. The app will quit, and you will need to start it again to re-grant permissions. This is useful if permissions seem 'stuck'."),
                primaryButton: .destructive(Text("Reset and Quit")) {
                    AccessibilityManager.shared.resetPermissions()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            checkPermissions()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func checkPermissions() {
        isAccessibilityGranted = AccessibilityManager.shared.isTrusted()
        isInputMonitoringGranted = AccessibilityManager.shared.checkInputMonitoring()
        
        if isAccessibilityGranted && isInputMonitoringGranted {
            // Auto-complete after a short delay if both are granted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onCompletion()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermissions()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct PermissionCard: View {
    let title: String
    let description: String
    let isGranted: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: isGranted ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 20))
                    .foregroundColor(isGranted ? .green : .blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isGranted {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            } else {
                Text("Enabled")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
