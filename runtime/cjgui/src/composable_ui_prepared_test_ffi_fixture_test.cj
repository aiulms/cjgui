package cjgui

// Shared testing-only renderer declarations for the prepared-scene fixtures.
foreign {
    func cjgui_internal_renderer_test_capture_composable_accessibility_action_for_node(
        session: UInt64, nodeId: UInt64): Int32
    func cjgui_internal_renderer_test_invoke_captured_composable_accessibility_action(session: UInt64): Int32
    func cjgui_internal_renderer_test_set_composable_present_failures(
        session: UInt64, failureCount: UInt32): Int32
}
