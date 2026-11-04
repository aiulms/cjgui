package cjgui

// Shared declarations for existing ordinary native test hooks. Kept apart
// from their larger regression files so focused host tests do not need those
// files' unrelated fixtures.
foreign {
    func cjgui_internal_renderer_test_insert_composable_text(
        session: UInt64, nodeIndex: UInt32, text: CString): Int32
    func cjgui_internal_renderer_test_composable_interaction_trace(session: UInt64,
        pending: CPointer<UInt32>, enqueuedKind: CPointer<UInt32>, enqueuedNode: CPointer<UInt64>,
        enqueuedProjection: CPointer<UInt64>, pumpedKind: CPointer<UInt32>, pumpedNode: CPointer<UInt64>,
        pumpedProjection: CPointer<UInt64>): Int32
    func cjgui_internal_renderer_test_arm_exit_close_reentry(first: UInt64, sibling: UInt64,
        siblingNodeIndex: UInt32): Int32
    func cjgui_internal_renderer_test_read_exit_close_reentry(observed: CPointer<UInt32>,
        allTerminal: CPointer<UInt32>, accepted: CPointer<UInt32>): Int32
}
