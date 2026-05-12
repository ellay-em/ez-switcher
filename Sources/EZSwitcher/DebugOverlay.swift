import SwiftUI
import AppKit
import Combine

class DebugOverlayManager: ObservableObject {
    static let shared = DebugOverlayManager()
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        SettingsManager.shared.$isDebugEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.show()
                } else {
                    self?.hide()
                }
            }
            .store(in: &cancellables)
    }
    
    func show() {
        if window == nil {
            let contentView = DebugOverlayView()
                .environmentObject(LanguageDetectionService.shared)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 250, height: 180),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.hasShadow = true
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            // Position bottom-right
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: screenRect.maxX - 270, y: screenRect.minY + 20))
            }
            
            window.contentView = NSHostingView(rootView: contentView)
            self.window = window
        }
        window?.orderFrontRegardless()
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}

struct DebugOverlayView: View {
    @EnvironmentObject var detectionService: LanguageDetectionService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "ai.bolt")
                    .foregroundColor(.orange)
                Text("AI Debugger")
                    .font(.caption.bold())
                Spacer()
                if let result = detectionService.lastResult, result.duration > 0 {
                    Text("\(String(format: "%.1f", result.duration))ms")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            if let result = detectionService.lastResult {
                VStack(alignment: .leading, spacing: 4) {
                    Text("'\(result.text)'")
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .foregroundColor(.white)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    scoreRow(label: "EN", score: result.scores[.english] ?? 0, color: .blue)
                    scoreRow(label: "RU", score: result.scores[.russian] ?? 0, color: .red)
                    scoreRow(label: "UK", score: result.scores[.ukrainian] ?? 0, color: .yellow)
                    
                    if let decision = result.decision {
                        HStack {
                            Text("Decision:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(decision.rawValue.uppercased())
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        .padding(.top, 4)
                    }
                }
            } else {
                Text("Start typing...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(12)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .frame(width: 250)
    }
    
    func scoreRow(label: String, score: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 20, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            
            Text(String(format: "%.2f", score))
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 35, alignment: .trailing)
        }
        .foregroundColor(.white)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
