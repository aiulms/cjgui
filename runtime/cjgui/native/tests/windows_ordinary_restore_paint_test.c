/* Actual Windows restore dispatcher and accepted-fragment batch functions.
 * Win32 session/accepted scene are explicit fixtures; no transfer completion or
 * source-install receipt is fabricated. This does not claim product latency. */
#include "windows_ordinary_restore_dispatch_fixture.h"
#include "cjgui_windows_renderer.c"
static int failures;
static void check(const char *name, int pass) {
    printf("RESTORE_PAINT_NATIVE %s pass=%d\n", name, !!pass);
    if (!pass) ++failures;
}
#define CJGUI_DISPATCH_FIXTURE_CASES
#include "windows_ordinary_restore_dispatch_fixture.h"

typedef struct QueuedRestoreProbe {
    CjguiWindowsRendererSession *session;
    int status;
    uint64_t facts[10];
} QueuedRestoreProbe;
static DWORD WINAPI queued_restore_probe(void *raw) {
    QueuedRestoreProbe *probe = raw;
    CjguiWindowsRendererSession *s = probe->session;
    probe->status = cjgui_internal_renderer_restore_composable_selection_paint_result(s->token,
        1001, s->focusedResourceId, s->focusedNodeKind, 7, (const char *)s->proxyValueUtf8, 1, 4, 4, 13, probe->facts);
    return 0;
}
static LONG CALLBACK report_test_fault(EXCEPTION_POINTERS *e) {
    printf("NATIVE_TEST_FAULT code=%lx rip=%llx image=%llx\n",(unsigned long)e->ExceptionRecord->ExceptionCode,
        (unsigned long long)e->ContextRecord->Rip,(unsigned long long)(uintptr_t)GetModuleHandleW(NULL));
    printf("FAULT_REG rcx=%llx rdx=%llx rsp=%llx bad=%llx\n",(unsigned long long)e->ContextRecord->Rcx,
        (unsigned long long)e->ContextRecord->Rdx,(unsigned long long)e->ContextRecord->Rsp,
        (unsigned long long)e->ExceptionRecord->ExceptionInformation[1]);
    void *frames[24];USHORT n=CaptureStackBackTrace(0,24,frames,NULL);
    for(USHORT i=0;i<n;++i)printf("FAULT_FRAME %u %llx\n",i,(unsigned long long)(uintptr_t)frames[i]);
    return EXCEPTION_CONTINUE_SEARCH;
}
int main(void) {
    setvbuf(stdout,NULL,_IONBF,0);
    puts("RESTORE_PAINT_NATIVE_START");
    AddVectoredExceptionHandler(1,report_test_fault);
    ensure_session_lock();
    CjguiWindowsRendererSession *s = &g_sessions[0];
    memset(s, 0, sizeof(*s));
    s->token = 9876; s->occupied = 1; s->pumpThreadId = GetCurrentThreadId();
    s->sessionGeneration = 71; s->sceneVersion = 7; s->dpi = 96;
    s->ownedTextSessionBindingEpoch = 4; s->cmdNextId = 80;
    const char *body = "A\xe4\xb8\xad\xf0\x9f\x98\x80" "B";
    CjguiWindowsSceneNode nodes[2] = {0};
    for (int i = 0; i < 2; ++i) {
        nodes[i].hasNode = nodes[i].hasGeometry = 1;
        nodes[i].node.nodeId = 1001 + i; nodes[i].node.resourceId = 8 + i;
        nodes[i].node.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
        nodes[i].node.projectionVersion = 7; nodes[i].value = (char *)body;
        // These functions use the immutable lease identity, not the COM object.
        // No draw/HitTest is claimed here; the normal app supplies real layouts.
        nodes[i].textLayout = (IDWriteTextLayout *)(uintptr_t)(i + 1);
        nodes[i].layoutLease = 20 + i; nodes[i].textLayoutInputKey = 30 + i;
        nodes[i].textDpi = 96;
    }
    s->acceptedScene.nodes = nodes; s->acceptedScene.count = 2;
    s->acceptedScene.configured = 1; s->acceptedScene.version = 7;
    s->focusedNodeId = 1001; s->focusedResourceId = 8;
    s->focusedNodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    s->proxyValueUtf8 = (uint8_t *)body;
    uint64_t facts[10] = {0};
    int st = cjgui_internal_renderer_restore_composable_selection_paint_result(s->token,
        1001, 8, s->focusedNodeKind, 7, body, 1, 4, 4, 9, facts);
    check("exact_actual_command_result", st == 0 && facts[0] == 9 && facts[1] == 81 &&
        facts[2] == 71 && facts[3] == 4 && facts[4] == 7 && facts[5] == 1001 &&
        facts[6] == 8 && facts[7] == s->focusedNodeKind && facts[8] == 1 && facts[9] == 4);
    check("unicode_ordered_range", s->selectionStart16 == 1 && s->selectionEnd16 == 4);
    uint64_t command = s->cmdNextId;
    for (int mode = 0; mode < 4; ++mode) {
        memset(facts, 0xff, sizeof(facts));
        st = cjgui_internal_renderer_restore_composable_selection_paint_result(s->token,
            1001, 8, s->focusedNodeKind, mode == 0 ? 6 : 7,
            mode == 1 ? "different" : body, mode == 3 ? 3 : 1, 4, mode == 2 ? 3 : 4, 10, facts);
        check(mode == 0 ? "old_scene_refused" : mode == 1 ? "old_body_refused" :
            mode == 2 ? "old_binding_refused" : "surrogate_interior_refused",
            st != 0 && facts[0] == 0 && facts[1] == 0 && s->selectionStart16 == 1 &&
            s->selectionEnd16 == 4 && s->cmdNextId == command);
    }
    // Final native binding comes from the real owned declaration, separate
    // from the restore result's pre-publication binding.
    const int64_t signedResources[] = {-1, INT64_MIN};
    const uint64_t signedBits[] = {UINT64_MAX, UINT64_C(0x8000000000000000)};
    for (int i = 0; i < 2; ++i) {
        nodes[0].node.resourceId = s->focusedResourceId = signedResources[i];
        st = cjgui_internal_renderer_restore_composable_selection_paint_result(s->token,
            1001, signedResources[i], s->focusedNodeKind, 7, body, 1, 4, 4, 11 + i, facts);
        check(i ? "int64_min_resource_bits_preserved" : "minus_one_resource_bits_preserved",
            st == 0 && facts[6] == signedBits[i] && facts[8] == 1 && facts[9] == 4);
    }
    nodes[0].node.resourceId = s->focusedResourceId = 8;
    // The normal application calls from the Cangjie owner thread. It takes the
    // queued dispatcher branch; an inline-only fixture cannot cover its result.
    InitializeCriticalSection(&s->cmdLock);
    s->cmdWakeEvent = CreateEventW(NULL, FALSE, FALSE, NULL);
    s->pumpThreadRunning = 1;
    nodes[0].node.resourceId = s->focusedResourceId = -1;
    QueuedRestoreProbe queued = {0}; queued.session = s;
    uint64_t beforeQueued = s->cmdNextId;
    HANDLE owner = CreateThread(NULL, 0, queued_restore_probe, &queued, 0, NULL);
    check("queued_owner_thread_created", owner != NULL && s->cmdWakeEvent != NULL);
    if (owner) {
        DWORD woke = WaitForSingleObject(s->cmdWakeEvent, 5000);
        check("queued_real_command_received", woke == WAIT_OBJECT_0);
        if (woke == WAIT_OBJECT_0) drain_dispatcher_commands(s, 0);
        DWORD joined = WaitForSingleObject(owner, 35000);
        check("queued_owner_joined", joined == WAIT_OBJECT_0);
        printf("QUEUED_RESTORE_FACT status=%d actual_counter=%llu returned_command=%llu request=%llu generation=%llu\n",
            queued.status, (unsigned long long)s->cmdNextId,
            (unsigned long long)queued.facts[1], (unsigned long long)queued.facts[0],
            (unsigned long long)queued.facts[2]);
        check("queued_success_returns_actual_same_command", queued.status == 0 &&
            queued.facts[0] == 13 && queued.facts[1] == beforeQueued + 1 &&
            queued.facts[2] == 71 && queued.facts[6] == UINT64_MAX &&
            queued.facts[8] == 1 && queued.facts[9] == 4);
        check("queued_responsibility_settled_once", s->cmdWaiters == 0 &&
            s->orphanedCommands == 0 && s->cmdHead == s->cmdTail);
        CloseHandle(owner);
    }
    CloseHandle(s->cmdWakeEvent); s->cmdWakeEvent = NULL;
    DeleteCriticalSection(&s->cmdLock); s->pumpThreadRunning = 0;
    nodes[0].node.resourceId = s->focusedResourceId = 8;
    s->ownedTextSessionBindingEpoch = 5;
    CjguiWindowsPreviewDecorationCtx c = {0};
    c.publicationId = 1; c.rendererGeneration = 71; c.bindingEpoch = 5;
    c.ownerVersion = 1; c.ownerRevision = 2; c.projectionId = 9; c.sceneVersion = 7;
    c.red = .4f; c.green = .6f; c.blue = .9f; c.alpha = .5f;
    c.rows = "1001:1:4;1002:0:1";
    st = windows_stage_preview_decoration_proc(s, &c);
    check("cross_fragment_text_not_input", st == 0 && s->previewPaintBatch.count == 2 &&
        s->previewPaintBatch.fragments[1].start16 == 0 && s->previewPaintBatch.fragments[1].end16 == 1);
    uint64_t key = s->previewPaintBatch.key;
    s->previewPaintDrawnKey = key; s->previewPaintDrawnScene = 7; s->previewPaintDrawnVisible = 1;
    check("stage_not_presented", !s->previewPaintHasPresentation);
    windows_settle_preview_paint_presentation(s);
    check("only_actual_draw_settles", s->previewPaintHasPresentation && s->previewPaintPresentedKey == key);
    s->previewPaintHasPresentation = 0; s->previewPaintDrawnKey = 0;
    windows_settle_preview_paint_presentation(s);
    check("ordinary_scene_cannot_clear_obligation", !s->previewPaintHasPresentation);
    c.rendererGeneration = 70;
    check("old_generation_refused", windows_stage_preview_decoration_proc(s, &c) != 0);
    c.rendererGeneration = 71; c.bindingEpoch = 4;
    check("pre_publication_binding_refused", windows_stage_preview_decoration_proc(s, &c) != 0);
    c.bindingEpoch = 5;
    windows_clear_preview_decoration_proc(s, NULL);
    check("clear_reuses_bounded_batch", s->previewPaintBatch.active &&
        s->previewPaintBatch.fragments[0].start16 == 0 && s->previewPaintBatch.fragments[0].end16 == 0 &&
        s->previewPaintBatch.fragments[1].end16 == 0 && !s->previewPaintHasPresentation);
    nodes[1].layoutLease += 1;
    check("changed_layout_disables_native_batch", !windows_revalidate_preview_batch(s) && !s->previewPaintBatch.active);
    memset(s, 0, sizeof(*s));
    run_dispatcher_completion_cases();
    DeleteCriticalSection(&g_sessionLock);
    printf("RESTORE_PAINT_NATIVE_RESULT failures=%d\n", failures);
    return failures ? 1 : 0;
}
