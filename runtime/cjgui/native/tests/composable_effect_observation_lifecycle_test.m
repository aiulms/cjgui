// Reuse the real renderer fixture and its Metal shared-event gate. The gate
// holds an actual submitted command buffer; no effect state is manufactured.
#define main cjgui_existing_effect_translation_fixture_main
#include "composable_effect_local_translation_production_test.m"
#undef main

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config = {.windowWidth = 420, .windowHeight = 320, .clearColorAlpha = 1};
        CjguiInternalRendererStatus status = CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
        uint64_t first = cjgui_internal_renderer_create(&config, &status);
        if (!first || status != CJGUI_INTERNAL_RENDERER_OK) return 2;
        uint64_t second = cjgui_internal_renderer_create(&config, &status);
        if (!second || status != CJGUI_INTERNAL_RENDERER_OK) return 2;
        CJGuiInternalSession *ctx = CjguiLookupSession(first);
        CJGuiInternalSession *other = CjguiLookupSession(second);
        BOOL failed = NO;
        uint64_t local[3] = {0}, otherLocal[3] = {0}, app[16] = {0};
        failed |= !localTranslationRequire(cjgui_internal_renderer_set_effect_observation(first, 1) == 0,
            "first_effect_observer_enabled");
        CJGuiEffectCompletionGateQueue *gate = [CJGuiEffectCompletionGateQueue new];
        gate.queue = ctx.view.commandQueue;
        gate.gate = [ctx.device newSharedEvent];
        failed |= !localTranslationRequire(gate.gate != nil, "real_gpu_gate_created");
        if (!gate.gate) { (void)cjgui_internal_renderer_destroy(first); (void)cjgui_internal_renderer_destroy(second); return 1; }
        ctx.view.commandQueue = (id<MTLCommandQueue>)gate;
        localTranslationProbeLayer = ctx.view.metalLayer;
        Method method = class_getInstanceMethod(CAMetalLayer.class, @selector(nextDrawable));
        localTranslationOriginalNextDrawable = method_setImplementation(method, (IMP)localTranslationCaptureNextDrawable);
        CJGuiEffectCompletionGateQueue *oldGate = [CJGuiEffectCompletionGateQueue new];
        oldGate.queue = other.view.commandQueue;
        oldGate.gate = [other.device newSharedEvent];
        failed |= !localTranslationRequire(oldGate.gate != nil, "pre_enable_gpu_gate_created");
        if (oldGate.gate) {
            other.view.commandQueue = (id<MTLCommandQueue>)oldGate;
            localTranslationProbeLayer = other.view.metalLayer;
            BOOL priorSubmitted = localHomeSubmit(second, 1, 0, 0, "Old", "10:40", "Pending", 6300,
                0.5f, 0.2f, NO, -1, NO);
            failed |= !localTranslationRequire(priorSubmitted &&
                cjgui_internal_renderer_set_effect_observation(second, 1) == 0, "enable_after_real_prior_submission");
            if (priorSubmitted) {
                failed |= !localTranslationRequire(cjgui_internal_renderer_effect_observation(second,
                    other.composableSceneVersion, other.view.frameIndex, otherLocal, 3) == 0 &&
                    otherLocal[0] == 0, "pre_enable_inflight_is_unavailable_not_zero");
            }
            oldGate.gate.signaledValue = oldGate.nextValue;
            NSDate *barrierDeadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
            do {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
                (void)cjgui_internal_renderer_effect_observation(second,
                    other.composableSceneVersion, other.view.frameIndex, otherLocal, 3);
            } while (!otherLocal[0] && [barrierDeadline timeIntervalSinceNow] > 0);
            failed |= !localTranslationRequire(otherLocal[0] == 1 && otherLocal[1] == 0 && otherLocal[2] == 0,
                "prior_real_completion_opens_barrier_without_claiming_old_pass");
        }
        localTranslationProbeLayer = ctx.view.metalLayer;
        BOOL submitted = localHomeSubmit(first, 1, 0, 0, "Notes", "10:42", "Content", 6200,
            0.5f, 0.2f, NO, -1, NO);
        failed |= !localTranslationRequire(submitted, "actual_effect_group_frame_submitted");
        if (submitted) {
            failed |= !localTranslationRequire(cjgui_internal_renderer_effect_observation(first,
                ctx.composableSceneVersion, ctx.view.frameIndex, local, 3) == 0 &&
                local[0] == 1 && local[1] > 0 && local[2] > 0, "own_frame_effect_is_in_flight_and_pass_committed");
            failed |= !localTranslationRequire(cjgui_internal_renderer_effect_observation(second,
                other.composableSceneVersion, other.view.frameIndex, otherLocal, 3) == 0 &&
                otherLocal[0] == 1 && otherLocal[1] == 0 && otherLocal[2] == 0, "other_window_has_no_foreign_pass_or_bytes");
            failed |= !localTranslationRequire(cjgui_internal_renderer_application_image_lifecycle_snapshot(app, 16) == 0 &&
                app[14] > 0 && app[15] == local[1], "global_weak_ledger_sees_exact_live_submission");
            failed |= !localTranslationRequire(cjgui_internal_renderer_destroy(first) == 0, "owner_window_closed");
            first = 0;
            failed |= !localTranslationRequire(cjgui_internal_renderer_application_image_lifecycle_snapshot(app, 16) == 0 &&
                app[14] > 0 && app[15] == local[1], "closed_owner_keeps_original_gpu_reference_visible");
        }
        // Release the already-submitted real command buffer, then observe its
        // actual completion; the diagnostic itself never waits on the GPU.
        gate.gate.signaledValue = gate.nextValue;
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.001]];
            (void)cjgui_internal_renderer_application_image_lifecycle_snapshot(app, 16);
        } while (app[14] != 0 && [deadline timeIntervalSinceNow] > 0);
        failed |= !localTranslationRequire(app[14] == 0 && app[15] == 0, "actual_completion_releases_closed_owner_targets");
        method_setImplementation(method, localTranslationOriginalNextDrawable);
        if (first) (void)cjgui_internal_renderer_destroy(first);
        (void)cjgui_internal_renderer_destroy(second);
        return failed ? 1 : 0;
    }
}
