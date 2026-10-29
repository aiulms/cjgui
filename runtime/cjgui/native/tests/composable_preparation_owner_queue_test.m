// Reuse the real preparation fixture, including the production renderer. The
// held main queue is a deterministic queue-delay counterexample, not a normal
// consumer performance measurement or an artificial delay in product input.
#define main CjguiBatchPreparationPriorMain
#import "composable_preparation_batch_test.m"
#undef main

static CjguiPreparationAdvanceTicket queueTicket(uint64_t session, BOOL *scheduled) {
    pthread_mutex_lock(&gCjguiPreparationAdvanceLock);
    CjguiPreparationAdvanceSlot snapshot = gCjguiPreparationAdvanceSlots[session - 1];
    pthread_mutex_unlock(&gCjguiPreparationAdvanceLock);
    if (scheduled) *scheduled = snapshot.serviceScheduled;
    return snapshot.ticket;
}

static BOOL drainQueueService(uint64_t session) {
    NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:2.0];
    BOOL scheduled = NO;
    while ((queueTicket(session, &scheduled), scheduled) && limit.timeIntervalSinceNow > 0)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    return !scheduled;
}

static BOOL ownerAdvance(uint64_t session, uint64_t preparation, uint64_t deadline,
    CjguiInternalRendererStatus *outStatus, uint32_t *outReady) {
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    __block uint32_t ready = UINT32_MAX;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        status = cjgui_internal_renderer_advance_composable_preparation(session, preparation, deadline, &ready);
        dispatch_semaphore_signal(done);
    });
    if (dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 16000000)) != 0) return NO;
    if (outStatus) *outStatus = status;
    if (outReady) *outReady = ready;
    return YES;
}

#ifndef CJGUI_PREPARATION_OWNER_QUEUE_HELPERS_ONLY
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
    CJGuiInternalSession *ctx = nil; uint64_t token = 0;
    if (!makeSession(&ctx, &token)) return 2;
    gCjguiMainThreadDispatchEnabled = YES;
    NSArray *accepted = ctx.composableNodes;
    uint64_t acceptedVersion = ctx.composableSceneVersion;
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 10, 1, 2, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 10, 2, 8) == CJGUI_INTERNAL_RENDERER_OK,
        "real_private_B_filled_against_original_A");
    dispatch_semaphore_t entered = dispatch_semaphore_create(0);
    dispatch_semaphore_t returned = dispatch_semaphore_create(0);
    __block uint64_t duration = 0;
    __block uint32_t ready = UINT32_MAX;
    __block CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        uint64_t started = nowNs();
        dispatch_semaphore_signal(entered);
        status = cjgui_internal_renderer_advance_composable_preparation(token, 10,
            started + 16000000u, &ready);
        duration = nowNs() - started;
        dispatch_semaphore_signal(returned);
    });
    CHECK(dispatch_semaphore_wait(entered, dispatch_time(DISPATCH_TIME_NOW, 1000000000)) == 0,
        "original_owner_advance_started");
    // AppKit cannot service its queued callback until this original 16ms
    // allowance has elapsed. The owner must be able to continue meanwhile.
    BOOL returnedBeforeMainService = dispatch_semaphore_wait(returned,
        dispatch_time(DISPATCH_TIME_NOW, 16000000)) == 0;
    CHECK(returnedBeforeMainService, "original_owner_does_not_wait_for_main_queue");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion &&
        ctx.composablePreparation.nodeCursor == 0 && !ctx.composablePreparation.ready,
        "pending_keeps_original_A_and_unadvanced_private_B");
    if (getenv("CJGUI_PREPARATION_QUEUE_FIRST_ONLY")) {
        NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:1.0];
        if (!returnedBeforeMainService) {
            while (dispatch_semaphore_wait(returned, DISPATCH_TIME_NOW) != 0 && limit.timeIntervalSinceNow > 0)
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
        }
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ready == 0,
            "original_queue_counterexample_keeps_no_ready_without_main_service");
        fprintf(stderr,"PREPARATION_OWNER_QUEUE_FIRST call_ns=%llu returned_before_main=%u\n",
            (unsigned long long)duration,returnedBeforeMainService);
        (void)cjgui_internal_renderer_cancel_composable_preparation(token, 10);
        (void)cjgui_internal_renderer_destroy(token);
        return failures ? 1 : 0;
    }
    CjguiPreparationAdvanceTicket original = queueTicket(token, NULL);
    if (returnedBeforeMainService) {
        CHECK(original.state == 1 && original.deadlineNs > 0 && original.ready == 0,
            "pending_ticket_keeps_original_absolute_deadline");
        for (NSUInteger i = 0; i < 8; i++) {
            CjguiInternalRendererStatus pollStatus = -1; uint32_t pollReady = UINT32_MAX;
            CHECK(ownerAdvance(token, 10, nowNs() + 16000000u, &pollStatus, &pollReady) &&
                pollStatus == CJGUI_INTERNAL_RENDERER_OK && pollReady == 0 &&
                queueTicket(token, NULL).nonce == original.nonce &&
                queueTicket(token, NULL).deadlineNs == original.deadlineNs,
                "finite_pending_observations_do_not_renew_or_resubmit_original_ticket");
        }
        // Keep AppKit held past that same deadline, then service the actual
        // queued callback. No owner input or production timing is changed.
        if (nowNs() < original.deadlineNs) usleep((useconds_t)((original.deadlineNs - nowNs()) / 1000 + 1));
        CHECK(drainQueueService(token), "original_queued_service_converges");
        CjguiPreparationAdvanceTicket completion = queueTicket(token, NULL);
        CHECK(completion.state == 2 && completion.nonce == original.nonce &&
            completion.deadlineNs == original.deadlineNs && completion.ready == 0 &&
            ctx.composablePreparation.nodeCursor == 0,
            "real_main_service_observes_original_expiry_without_advancing_B");
        CHECK(ownerAdvance(token, 10, nowNs() + 16000000u, &status, &ready) &&
            status == CJGUI_INTERNAL_RENDERER_OK && ready == 0 && queueTicket(token, NULL).state == 0,
            "owner_consumes_original_completion_once");
    }
    if (!returnedBeforeMainService) {
        // Drain only the already submitted call. Never resubmit the advance.
        NSDate *limit = [NSDate dateWithTimeIntervalSinceNow:1.0];
        while (dispatch_semaphore_wait(returned, DISPATCH_TIME_NOW) != 0 && limit.timeIntervalSinceNow > 0)
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
    CHECK(status == CJGUI_INTERNAL_RENDERER_OK && ready == 0,
        "expired_original_deadline_does_not_advance_or_report_ready");
    fprintf(stderr, "PREPARATION_OWNER_QUEUE original_deadline_ns=16000000 returned_before_main=%u "
        "call_ns=%llu ready=%u status=%d accepted_version=%llu private_cursor=%lu\n",
        returnedBeforeMainService, (unsigned long long)duration, ready, status,
        (unsigned long long)ctx.composableSceneVersion, (unsigned long)ctx.composablePreparation.nodeCursor);
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 10);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 11, 1, 3, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 11, 3, 8) == CJGUI_INTERNAL_RENDERER_OK,
        "new_private_candidate_uses_same_existing_source_gate");
    CHECK(ownerAdvance(token, 11, nowNs() + 16000000u, &status, &ready), "new_candidate_owner_request_is_nonblocking");
    CjguiPreparationAdvanceTicket cancelled = queueTicket(token, NULL);
    CHECK(cjgui_internal_renderer_cancel_composable_preparation(token, 11) == CJGUI_INTERNAL_RENDERER_OK,
        "cancel_original_candidate");
    BOOL scheduled = NO;
    CHECK(queueTicket(token, &scheduled).state == 0 && scheduled,
        "cancel_retires_result_but_preserves_single_already_queued_wake");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 12, 1, 4, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 12, 4, 8) == CJGUI_INTERNAL_RENDERER_OK,
        "replacement_private_candidate_frozen_separately");
    CHECK(ownerAdvance(token, 12, nowNs() + 16000000u, &status, &ready), "replacement_owner_request_is_nonblocking");
    CjguiPreparationAdvanceTicket replacement = queueTicket(token, &scheduled);
    CHECK(replacement.nonce != cancelled.nonce && replacement.preparationId == 12 && scheduled,
        "replacement_is_new_ticket_on_single_wake_not_old_completion");
    CHECK(drainQueueService(token), "replacement_actual_service_converges");
    CHECK(queueTicket(token, NULL).preparationId == 12 && queueTicket(token, NULL).nonce == replacement.nonce,
        "late_service_cannot_publish_cancelled_ticket_into_replacement");
    CHECK(ctx.composableNodes == accepted && ctx.composableSceneVersion == acceptedVersion,
        "private_actual_progress_never_installs_or_presents_B");
    (void)cjgui_internal_renderer_cancel_composable_preparation(token, 12);
    CHECK(cjgui_internal_renderer_begin_composable_preparation(token, 13, 1, 5, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(token, 13, 5, 8) == CJGUI_INTERNAL_RENDERER_OK &&
        ownerAdvance(token, 13, nowNs() + 16000000u, &status, &ready),
        "queued_work_before_actual_close");
    CjguiPreparationAdvanceTicket beforeClose = queueTicket(token, NULL);
    (void)cjgui_internal_renderer_destroy(token);
    CHECK(queueTicket(token, NULL).state == 0, "close_retires_original_queued_result");
    CJGuiInternalSession *reopened = nil; uint64_t reusedToken = 0;
    CHECK(makeSession(&reopened, &reusedToken) && reusedToken == token &&
        reopened.sessionGeneration != beforeClose.generation,
        "actual_same_slot_new_session_generation");
    CHECK(cjgui_internal_renderer_begin_composable_preparation(reusedToken, 13, 1, 2, 8) ==
        CJGUI_INTERNAL_RENDERER_OK && fillButtons(reusedToken, 13, 2, 8) == CJGUI_INTERNAL_RENDERER_OK &&
        ownerAdvance(reusedToken, 13, nowNs() + 16000000u, &status, &ready),
        "same_numeric_preparation_is_new_admission_on_reopened_session");
    CjguiPreparationAdvanceTicket afterClose = queueTicket(reusedToken, NULL);
    CHECK(afterClose.nonce != beforeClose.nonce && afterClose.generation == reopened.sessionGeneration &&
        drainQueueService(reusedToken) && queueTicket(reusedToken, NULL).generation == reopened.sessionGeneration,
        "old_queued_wake_cannot_publish_old_generation_into_new_session");
    (void)cjgui_internal_renderer_cancel_composable_preparation(reusedToken, 13);
    (void)cjgui_internal_renderer_destroy(reusedToken);
    CHECK(queueTicket(reusedToken, NULL).state == 0 && drainQueueService(reusedToken),
        "final_close_leaves_no_live_result_or_queued_service");
    return failures ? 1 : 0;
} }

#endif
