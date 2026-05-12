import CoreGraphics
import Foundation

class LayoutMonitoringEngine {
    static let shared = LayoutMonitoringEngine()
    
    private var eventPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    var onKeyDown: ((CGEvent) -> Unmanaged<CGEvent>?)?
    
    private init() {}
    
    func start() {
        guard eventPort == nil else { return }
        
        // We need to intercept key down events globally
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Untained<CGEvent>.passUnretained(event) }
            let engine = Unmanaged<LayoutMonitoringEngine>.fromOpaque(refcon).takeUnretainedValue()
            
            if type == .keyDown || type == .flagsChanged {
                if let processedEvent = engine.onKeyDown?(event) {
                    return processedEvent
                }
            }
            
            return Unmanaged.passUnretained(event)
        }
        
        eventPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventPort = eventPort else {
            print("Failed to create event tap. Ensure Accessibility permissions are granted.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventPort, enable: true)
        print("Layout Monitoring Engine started.")
    }
    
    func stop() {
        guard let eventPort = eventPort, let runLoopSource = runLoopSource else { return }
        CGEvent.tapEnable(tap: eventPort, enable: false)
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        self.eventPort = nil
        self.runLoopSource = nil
        print("Layout Monitoring Engine stopped.")
    }
}
