// Production ABI: creating a selection is allowed; a split Finalizing lease is not.
// AppKit preparation and callback-free terminal publication are one install operation.
#import "../cjgui_internal_renderer.m"

static int failures = 0;
#define CHECK(condition, label) do { \
    BOOL passed = (condition); \
    fprintf(stderr, "selection_transfer_create_production case=%s result=%s\n", \
        label, passed ? "PASS" : "FAIL"); \
    if (!passed) ++failures; \
} while (0)

int main(void) {
    @autoreleasepool {
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.ownedTextSessionNodeId = 77;
        session.ownedTextSessionResourceId = 901;
        session.ownedTextSessionBindingEpoch = 12;
        CjguiInstalledRangeState *sourceA = [CjguiInstalledRangeState new];
        CjguiInternalInstalledRangeCandidate sourceCandidate = {0};
        sourceCandidate.nonce = 0xabc;
        sourceCandidate.windowInstanceToken = 0x1234;
        sourceCandidate.bindingEpoch = 12;
        sourceCandidate.nodeId = 77;
        sourceCandidate.resourceId = 901;
        sourceA.candidate = sourceCandidate;
        sourceA.proxyGeneration = 55;
        sourceA.selectionRevision = 8;
        sourceA.actualSelectionStart16 = 2;
        sourceA.actualSelectionEnd16 = 4;
        sourceA.sourceUtf8 = [@"source-A" dataUsingEncoding:NSUTF8StringEncoding];
        sourceA.hasReceipt = YES;
        sourceA.active = YES;
        session.installedRangeBasis = sourceA;
        uint64_t token = CjguiAllocateSession(session);
        CHECK(token != CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN, "fixture_valid_session");
        if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) return 2;

        NSUInteger slot = (NSUInteger)(token - 1);
        CjguiSelectionTransferCell *cell = &gCjguiSelectionTransferCells[slot];
        uint64_t generationBefore = cell->sessionGeneration;
        uint64_t idBefore = cell->transferId;
        uint32_t refsBefore = cell->references;
        uint64_t decisionBefore = atomic_load_explicit(&cell->decision, memory_order_acquire);
        uint64_t sourceNodeBefore = session.ownedTextSessionNodeId;
        uint64_t sourceResourceBefore = session.ownedTextSessionResourceId;
        uint64_t sourceBindingBefore = session.ownedTextSessionBindingEpoch;
        CjguiInstalledRangeState *sourceABefore = session.installedRangeBasis;

        uint64_t transferId = UINT64_MAX;
        CjguiInternalRendererStatus status = cjgui_internal_renderer_selection_transfer_create(
            token, &transferId);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && transferId != 0,
            "production_create_admits_selection");
        CHECK(cell->sessionGeneration == generationBefore && cell->transferId == transferId &&
            cell->references == 2 &&
            CjguiSelectionTransferStateOf(atomic_load_explicit(&cell->decision, memory_order_acquire)) ==
                CJGUI_SELECTION_TRANSFER_PREPARING,
            "create_only_prepares_no_input_graph_published");
#ifndef CJGUI_INTERNAL_TESTING
        CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transferId)==0,
            "production_pending_is_cancellable");
        CHECK(cjgui_internal_renderer_selection_transfer_begin_finalizing(token,transferId)!=0 &&
            CjguiSelectionTransferStateOf(atomic_load_explicit(&cell->decision,memory_order_acquire))==
                CJGUI_SELECTION_TRANSFER_PENDING,
            "production_cannot_leave_split_finalizing_lease_in_event_loop");
#endif
        CHECK(session.ownedTextSessionNodeId == sourceNodeBefore &&
            session.ownedTextSessionResourceId == sourceResourceBefore &&
            session.ownedTextSessionBindingEpoch == sourceBindingBefore,
            "production_create_preserves_source_identity");
        CHECK(session.installedRangeBasis == sourceABefore && sourceABefore.active &&
            sourceABefore.hasReceipt && sourceABefore.candidate.nonce == 0xabc &&
            sourceABefore.candidate.windowInstanceToken == 0x1234 &&
            sourceABefore.candidate.bindingEpoch == 12 && sourceABefore.candidate.nodeId == 77 &&
            sourceABefore.candidate.resourceId == 901 && sourceABefore.proxyGeneration == 55 &&
            sourceABefore.selectionRevision == 8 && sourceABefore.actualSelectionStart16 == 2 &&
            sourceABefore.actualSelectionEnd16 == 4 &&
            [sourceABefore.sourceUtf8 isEqualToData:[@"source-A" dataUsingEncoding:NSUTF8StringEncoding]],
            "production_create_preserves_installed_A_receipt_and_range");

        CjguiReleaseSession(token);
        fprintf(stderr, "selection_transfer_create_production failures=%d\n", failures);
        return failures ? 1 : 0;
    }
}
