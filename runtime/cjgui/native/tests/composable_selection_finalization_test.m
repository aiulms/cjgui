// Production-path counterexample: a decision cannot commit before exact B proof.
#define CJGUI_SELECTION_TRANSFER_NO_MAIN 1
#import "composable_selection_transfer_input_test.m"

static void CommitRequiresInstalledProof(id<MTLDevice> device) {
    SourceInstallOverlay *overlay = InstalledRangeCreateActivatedFixtureAt(
        device, @"abcde", 81, 1301, 9101, 0, @"FGHIJ");
    CHECK(overlay != nil, "finalization_actual_A_installed");
    if (!overlay) return;
    uint64_t token=overlay.session.rendererSessionToken;
    NSData *a=[@"abcde" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *b=[@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate candidate={0};
    CHECK(SelectionTransferFillSourceReceipt(token,1301,&candidate), "finalization_A_receipt");
    candidate.sourceProjectionVersion=1;
    candidate.sourceNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    candidate.sourceBodyUtf8=a.bytes; candidate.sourceBodyUtf8Length=(uint32_t)a.length;
    candidate.targetNodeId=402; candidate.targetProjectionVersion=1;
    candidate.targetResourceId=1; candidate.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    candidate.targetSceneVersion=1; candidate.targetAnchor16=0; candidate.targetFocus16=2;
    candidate.targetBodyUtf8=b.bytes; candidate.targetBodyUtf8Length=(uint32_t)b.length;
    uint64_t transfer=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&transfer)==0, "finalization_create");
    candidate.transferId=transfer;
    CHECK(cjgui_internal_renderer_selection_transfer_capture_a(token,&candidate)==0, "finalization_capture");
    CHECK(cjgui_internal_renderer_selection_transfer_publish_pending(token,transfer)==0, "finalization_pending");
    CHECK(cjgui_internal_renderer_selection_transfer_begin_finalizing(token,transfer)==0, "finalization_begin");
    CHECK(cjgui_internal_renderer_selection_transfer_commit(token,transfer)!=0,
        "finalization_uninstalled_B_cannot_commit");
    uint32_t state=0,refs=0; uint8_t cancelled=0;
    cjgui_internal_renderer_selection_transfer_state(token,transfer,&state,&cancelled,&refs);
    CHECK(state==CJGUI_SELECTION_TRANSFER_FINALIZING, "finalization_remains_exclusive_until_proof_or_restore");
    cjgui_internal_renderer_destroy(token);
}

static uint64_t PrepareActualChoice(SourceInstallOverlay *overlay,uint32_t anchor,uint32_t focus,
    CjguiInternalSelectionTransferCandidate *snapshot) {
    uint64_t token=overlay.session.rendererSessionToken,id=0;
    NSData *b=[@"FGHIJ" dataUsingEncoding:NSUTF8StringEncoding];
    CjguiInternalSelectionTransferCandidate wanted={0};
    wanted.sourceWindowInstanceToken=9101; wanted.sourceOwnerVersion=10;
    wanted.sourceContextEpoch=4; wanted.sourceMirrorRevision=2;
    wanted.targetNodeId=402; wanted.targetProjectionVersion=1; wanted.targetResourceId=1;
    wanted.targetNodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    wanted.targetSceneVersion=1; wanted.targetAnchor16=anchor; wanted.targetFocus16=focus;
    wanted.targetBodyUtf8=b.bytes; wanted.targetBodyUtf8Length=(uint32_t)b.length;
    uint8_t actual[65536]={0};
    if (cjgui_internal_renderer_selection_transfer_create(token,&id)) return 0;
    wanted.transferId=id;
    if (cjgui_internal_renderer_selection_transfer_capture_current(token,&wanted,actual,sizeof(actual))) return 0;
    CHECK(wanted.sourceBodyUtf8Length==5 && memcmp(actual,"abcde",5)==0,"finalization_actual_A_bytes_not_mirror");
    if(cjgui_internal_renderer_selection_transfer_publish_pending(token,id))return 0;
    *snapshot=wanted; return id;
}
static void ActualInstallCommitsOneDecision(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixtureAt(device,@"abcde",81,1302,9101,0,@"FGHIJ");
    CHECK(o!=nil,"common_decision_fixture");if(!o)return;
    CjguiInternalSelectionTransferCandidate a={0};uint64_t id=PrepareActualChoice(o,4,1,&a);
    CHECK(id!=0,"common_decision_prepare");
    uint64_t token=o.session.rendererSessionToken;
    CjguiInternalSelectionTransferReceipt b={0};
    CHECK(cjgui_internal_renderer_selection_transfer_install_b(token,id,&b)==0,"common_decision_atomic_install");
    uint32_t state=0,refs=0;uint8_t cancel=0;
    cjgui_internal_renderer_selection_transfer_state(token,id,&state,&cancel,&refs);
    CHECK(state==CJGUI_SELECTION_TRANSFER_COMMITTED && b.proxyGeneration!=0 && b.selectionStart16==1 &&
        b.selectionEnd16==4 && b.bindingEpoch==82,"common_decision_committed_exact_B_identity");
    CHECK(cjgui_internal_renderer_selection_transfer_request_cancel(token,id)!=0,"common_decision_late_cancel_cannot_reject");
    CHECK(cjgui_internal_renderer_selection_transfer_discard_capsule(token,id)==0,"common_decision_retire_native");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token,id)==0,"common_decision_retire_owner");
    [o.inputProxy insertText:@"Z" replacementRange:NSMakeRange(NSNotFound,0)];
    CHECK([o.inputProxy.string isEqualToString:@"FZJ"],"common_decision_typing_real_proxy_local_evidence");
    CjguiInternalRendererEvent event={0};
    CjguiInternalInstalledRangeIntent input={0};
    CHECK(cjgui_internal_renderer_pump_event(token,0,&event)==0 && event.kind==51,
        "common_decision_actual_FIFO_range");
    CHECK(cjgui_internal_renderer_claim_last_pumped_range(token,402,1,82,1,&input)==0 &&
        input.flags==2 && input.nonce==id && input.rangeStart16==1 && input.rangeLength16==3,
        "common_decision_local_range_requires_owner_authority");
    cjgui_internal_renderer_destroy(token);
}
static void PendingWriterWinsAndInstallRestores(id<MTLDevice> device) {
    for(NSUInteger failure=0;failure<2;++failure){
        SourceInstallOverlay *o=InstalledRangeCreateActivatedFixtureAt(device,@"abcde",81,1310+failure,9101,0,@"FGHIJ");
        CHECK(o!=nil,"abort_fixture");if(!o)continue;
        CjguiInternalSelectionTransferCandidate a={0};uint64_t id=PrepareActualChoice(o,0,2,&a);
        uint64_t token=o.session.rendererSessionToken;
        NSUInteger responderCalls=o.testWindow.responderCalls;
        if(failure==0){uint32_t admission=99;cjgui_internal_renderer_selection_transfer_admit_input(token,id,&admission);
            CHECK(admission==CJGUI_SELECTION_INPUT_ALLOW,"pending_writer_admitted");}
        else {
            // Fault the actual verify_b input after B selection installation,
            // so this fixture proves the rollback path rather than a TextKit
            // getter call that may be consumed during proxy attachment.
            setenv("CJGUI_TEST_SELECTION_TRANSFER_CORRUPT_B_BEFORE_VERIFY", "1", 1);
        }
        CjguiInternalSelectionTransferReceipt b={0};
        CjguiInternalRendererStatus installStatus=cjgui_internal_renderer_selection_transfer_install_b(token,id,&b);
        CHECK(installStatus!=0,"aborted_choice_never_installs_B");
        uint32_t state=0,refs=0;uint8_t cancel=0;cjgui_internal_renderer_selection_transfer_state(token,id,&state,&cancel,&refs);
        CHECK(state==CJGUI_SELECTION_TRANSFER_ABORTED,"abort_terminal_after_restore");
        CHECK([o.inputProxy.string isEqualToString:@"abcde"] && o.activeNodeId==401,
            "abort_restores_complete_A_before_admission");
        CHECK(o.testWindow.responderCalls==responderCalls,
            "selection_transfer_A_to_B_and_rollback_keep_existing_proxy_responder_without_fallible_switch");
        cjgui_internal_renderer_destroy(token);
    }
}
static void PendingAbortRetiresAfterAcceptedInput(id<MTLDevice> device) {
    SourceInstallOverlay *o=InstalledRangeCreateActivatedFixtureAt(device,@"abcde",81,1320,9101,0,@"FGHIJ");
    CHECK(o!=nil,"abort_new_input_fixture");if(!o)return;
    CjguiInternalSelectionTransferCandidate a={0}; uint64_t id=PrepareActualChoice(o,0,2,&a);
    uint64_t token=o.session.rendererSessionToken;
    [o.inputProxy insertText:@"X" replacementRange:NSMakeRange(NSNotFound,0)];
    NSString *accepted=[o.inputProxy.string copy];
    CHECK(![accepted isEqualToString:@"abcde"],"pending_input_legally_changes_A");
    CHECK(cjgui_internal_renderer_selection_transfer_replay_input(token,id)==0 &&
        [accepted isEqualToString:o.inputProxy.string],"empty_aborted_capsule_preserves_newer_A_input");
    CHECK(cjgui_internal_renderer_selection_transfer_release(token,id)==0,"empty_aborted_owner_retires");
    uint64_t next=0;
    CHECK(cjgui_internal_renderer_selection_transfer_create(token,&next)==0 && next!=id,
        "empty_aborted_capsule_does_not_wedge_next_decision");
    cjgui_internal_renderer_destroy(token);
}

int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        if (!device) return 2;
        CommitRequiresInstalledProof(device);
        ActualInstallCommitsOneDecision(device);
        PendingWriterWinsAndInstallRestores(device);
        PendingAbortRetiresAfterAcceptedInput(device);
        SelectionTransferInputGateFixture(device);
        SelectionTransferRetainedInputCapacityOverflowFixture(device);
        SelectionTransferRetainedInputByteOverflowFixture(device);
        fprintf(stderr,"selection_finalization failures=%d\n",failures);
        return failures ? 1 : 0;
    }
}
