package cjgui_generated_collection

import cjgui.*

// Public value contracts only. The normal window chain verifies the actual
// overlay gate, read-only owner and panel lifecycle; no native TESTING library.
func checkInspector(): Int64 {
    let pinned = CjguiComposableUiDiagnosticOverlayOptions(true, selectedIdentityKey: "semantic:field",
        expectedSessionIdentity: "window-A", expectedAcceptedSceneVersion: 12, ownerKey: "inspector-A")
    if (!pinned.matchesAccepted("window-A", 12) || pinned.matchesAccepted("window-A", 13) || pinned.matchesAccepted(
        "window-B", 12)) {
        return 31
    }
    if (!CjguiComposableUiDiagnosticOverlayOptions(true).matchesAccepted("any-session", 99)) {
        return 32
    }
    if (CjguiComposableUiInspectorPanel.metric(-1, unit: " ns") != "unavailable" ||
        CjguiComposableUiInspectorPanel.metric(0, unit: " ns") != "0 ns" ||
        CjguiComposableUiInspectorPanel.metric(37, unit: " μs") != "37 μs") {
        return 33
    }
    println("INSPECTOR_CHECKS_OK pinned_session_scene_gate legacy_unpinned_compatible unavailable_is_not_zero")
    return 0
}
