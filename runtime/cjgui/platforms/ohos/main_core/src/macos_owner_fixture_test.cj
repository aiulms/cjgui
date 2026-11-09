package cjgui

import std.sync.*
import std.time.*

foreign {
    func cjgui_internal_renderer_test_owner_fixture_begin(): UInt64
    func cjgui_internal_renderer_test_owner_fixture_loop_ready(serial: UInt64): UInt32
    func cjgui_internal_renderer_test_owner_fixture_complete(serial: UInt64): Unit
    func cjgui_internal_renderer_test_owner_fixture_run(serial: UInt64): Unit
}

// Shared test fixture, also installed in a normal consumer's isolated test
// package by verify_cjpm_mac_testing_link.py --consumer. The standard test
// runner owns process lifetime; the existing AppKit/main dispatch serves a
// managed owner body and remains alive until its finally has completed.
@When[os == "macOS"]
func cjguiMacosOwnerTest(body: () -> Unit): Unit {
    let serial = unsafe { cjgui_internal_renderer_test_owner_fixture_begin() }
    if (serial == 0u64) { throw IllegalStateException("macos_owner_test_requires_main_thread") }
    let finished = spawn {
        // A Cangjie task can run before the creating task enters foreign code.
        // Yield cooperatively (zero duration) until main is inside its loop;
        // then this body cannot accidentally execute on the AppKit thread.
        while (unsafe { cjgui_internal_renderer_test_owner_fixture_loop_ready(serial) } == 0u32) {
            sleep(Duration.Zero)
        }
        try { body() } finally { unsafe { cjgui_internal_renderer_test_owner_fixture_complete(serial) } }
    }
    unsafe { cjgui_internal_renderer_test_owner_fixture_run(serial) }
    // Propagate the original assertion/exception to the standard runner only
    // after both owner cleanup and main-loop servicing have actually finished.
    finished.get()
}
