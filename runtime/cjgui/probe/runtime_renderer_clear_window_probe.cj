package cjgui

// runtime_renderer_clear_window_probe.cj
//
// R1 vertical-slice probe for the runtime-owned internal renderer.
//
// This probe is compiled in the SAME package (cjgui) as
// runtime_renderer_session.cj, so it can consume the internal wrapper symbols
// without any of them being promoted to public visibility. It is NOT part of
// the shipped library output (the runtime package is output-type = "static");
// it is built only by verify_internal_renderer_clear_window.sh into a
// standalone executable against a temporary package.
//
// Flow (Cangjie always retains control):
//   create(config)
//   presentClear twice (readback on frame 1)
//   bounded pump loop
//   requestClose
//   destroy
// It asserts: main thread admitted, session created, two frames submitted,
// readback completed + clear color matched, pump bounded, close + destroy
// succeeded, occupied session count back to 0.

main(): Int64 {
    println("cjgui: starting runtime-owned internal renderer probe")

    let config = CjguiInternalRendererConfig(
        windowWidth: 720u32,
        windowHeight: 420u32,
        clearColorRed: 0.08,
        clearColorGreen: 0.16,
        clearColorBlue: 0.20,
        clearColorAlpha: 1.0
    )

    // ---- create ----
    let createResult = internalRendererCreate(config)
    let token = createResult.token
    if (createResult.status != CJGUI_INTERNAL_RENDERER_OK) {
        println("cjgui probe: create failed status=${createResult.status}")
        return 1
    }
    if (token == CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        println("cjgui probe: create returned invalid token")
        return 1
    }
    println("cjgui probe: main thread admitted=true")
    println("cjgui probe: session created token=${token}")

    let baselineColor = CjguiInternalRendererClearColor(
        red: 0.08, green: 0.16, blue: 0.20, alpha: 1.0
    )

    // ---- frame 1 with readback ----
    let frame1 = internalRendererPresentClear(token, baselineColor)
    if (frame1.status != CJGUI_INTERNAL_RENDERER_OK) {
        println("cjgui probe: frame 1 failed status=${frame1.status}")
        let _ = internalRendererDestroy(token)
        return 1
    }
    println("cjgui probe: frame 1 submitted index=${frame1.frameIndex}")
    println("cjgui probe: frame 1 readback attempted=${frame1.readbackAttempted}")
    println("cjgui probe: frame 1 readback completed=${frame1.readbackCompleted}")
    println("cjgui probe: frame 1 readback color matched=${frame1.readbackColorMatched}")
    if (frame1.readbackAttempted == 0u8) {
        println("cjgui probe: frame 1 readback not attempted")
        let _ = internalRendererDestroy(token)
        return 1
    }
    if (frame1.readbackCompleted == 0u8) {
        println("cjgui probe: frame 1 readback command buffer not completed")
        let _ = internalRendererDestroy(token)
        return 1
    }
    if (frame1.readbackColorMatched == 0u8) {
        println("cjgui probe: frame 1 readback clear color mismatch")
        let _ = internalRendererDestroy(token)
        return 1
    }

    // ---- frame 2 (second clear) ----
    let frame2 = internalRendererPresentClear(token, baselineColor)
    if (frame2.status != CJGUI_INTERNAL_RENDERER_OK) {
        println("cjgui probe: frame 2 failed status=${frame2.status}")
        let _ = internalRendererDestroy(token)
        return 1
    }
    println("cjgui probe: frame 2 submitted index=${frame2.frameIndex}")

    // ---- bounded pump loop ----
    //
    // Cangjie drives the loop. Each pumpEvent is bounded to <= 16 ms on the C
    // side. We do a small fixed number of pumps to drain the run loop without
    // ever calling a blocking app_run.
    let maxObservedPumps = 8
    var lastEventKind: UInt32 = 0
    var pumpIteration = 0
    while (pumpIteration < maxObservedPumps) {
        let pumpResult = internalRendererPumpEvent(token, 4u32)
        if (pumpResult.status != CJGUI_INTERNAL_RENDERER_OK) {
            println("cjgui probe: pump failed status=${pumpResult.status} iter=${pumpIteration}")
            let _ = internalRendererDestroy(token)
            return 1
        }
        lastEventKind = pumpResult.eventKind
        pumpIteration++
    }
    println("cjgui probe: bounded pump completed iterations=${pumpIteration}")
    println("cjgui probe: last pump event kind=${lastEventKind}")

    // ---- close + destroy ----
    let closeStatus = internalRendererRequestClose(token)
    if (closeStatus != CJGUI_INTERNAL_RENDERER_OK) {
        println("cjgui probe: requestClose failed status=${closeStatus}")
        return 1
    }
    println("cjgui probe: close requested=true")

    let destroyStatus = internalRendererDestroy(token)
    if (destroyStatus != CJGUI_INTERNAL_RENDERER_OK) {
        println("cjgui probe: destroy failed status=${destroyStatus}")
        return 1
    }
    println("cjgui probe: destroyed=true")

    let occupied = internalRendererOccupiedSessionCount()
    println("cjgui probe: occupied session count=${occupied}")
    if (occupied != 0u32) {
        println("cjgui probe: occupied session count not zero")
        return 1
    }

    println("cjgui probe: exit=0")
    return 0
}
