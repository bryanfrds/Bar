import ServiceManagement
import AppKit

/// Launch-at-login via SMAppService. Registration is keyed to the app bundle's
/// path + signature, so re-signing or moving Nook can require a re-toggle.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    /// Returns nil on success, or a human-readable reason on failure.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> String? {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch let error as NSError {
            // Most common: the bundle lives somewhere launchd won't accept, or
            // the user disabled it in System Settings (requiresApproval).
            if SMAppService.mainApp.status == .requiresApproval {
                return "macOS needs approval — enable Nook in System Settings › General › Login Items."
            }
            return error.localizedDescription
        }
    }
}
