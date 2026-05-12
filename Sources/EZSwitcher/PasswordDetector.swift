import ApplicationServices
import Foundation

class PasswordDetector {
    static let shared = PasswordDetector()
    
    private init() {}
    
    /// Checks if the currently focused UI element is a password field.
    func isFocusedElementSecure() -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        
        var focusedElementRaw: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRaw)
        
        guard error == .success, let focusedElement = focusedElementRaw else {
            return false
        }
        
        let axElement = focusedElement as! AXUIElement
        
        var roleRaw: CFTypeRef?
        var subroleRaw: CFTypeRef?
        
        AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleRaw)
        AXUIElementCopyAttributeValue(axElement, kAXSubroleAttribute as CFString, &subroleRaw)
        
        let role = (roleRaw as? String) ?? ""
        let subrole = (subroleRaw as? String) ?? ""
        
        // Check standard secure text field subrole
        if subrole == "AXSecureTextField" {
            return true
        }
        
        // Sometimes web browsers expose passwords differently, let's check for standard descriptions
        var descriptionRaw: CFTypeRef?
        AXUIElementCopyAttributeValue(axElement, kAXDescriptionAttribute as CFString, &descriptionRaw)
        let description = ((descriptionRaw as? String) ?? "").lowercased()
        
        if description.contains("password") || description.contains("пароль") {
            return true
        }
        
        return false
    }
}
