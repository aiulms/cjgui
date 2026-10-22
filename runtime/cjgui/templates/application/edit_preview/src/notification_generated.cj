package cjgui_notification_threshold_window_app

import cjgui.*
import cjgui_notification_threshold_application.*

// The standard form vocabulary now has a public owner. Keep this application
// seam compatible with its existing consumer tests and accepted source archive.
func notificationGeneratedCatalog(domain: CjguiNotificationThresholdDomain, binding: CjguiGeneratedUiFormBinding): CjguiGeneratedUiCapabilityCatalog {
    let _ = domain
    return binding.capabilityCatalog()
}
