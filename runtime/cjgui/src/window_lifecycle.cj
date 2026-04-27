package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// Date: 2026-04-26
//
// This file is intentionally comment-only.
// It does not define a stable public API.
// It does not implement window lifecycle behavior.
// It does not create, close, or destroy a platform window.
// It does not expose native handles or platform objects.
//
// Future window lifecycle owner:
// - belongs to the formal runtime core window lifecycle module.
// - owns dehydrated window lifecycle state.
// - owns window-target lifecycle facts such as create requested, close requested, closing,
//   destroyed, release completed, and stale window message classification.
// - does not own app-level run, quit, shutdown, or queue acceptance policy.
// - delegates all platform object work to a platform adapter.
// - must not own Renderer, Scene, Widget, Layout, Text, Input, IME, Accessibility,
//   semantic tree, Action Router, or render scheduling state.
//
// App lifecycle relation:
// - app lifecycle is the conceptual owner of app-level state, queue acceptance,
//   shutdown policy, and future main-thread queue / drain policy.
// - window lifecycle owns window-target state transitions after an accepted
//   window-targeted lifecycle request reaches the window layer.
// - request close should eventually flow through app lifecycle queue acceptance
//   and platform-adapter main-thread drain before window state advances.
// - this file does not implement app lifecycle, event loop, queue, drain, run,
//   request quit, or shutdown behavior.
//
// Platform adapter relation:
// - platform adapter owns platform runloop callbacks, platform close events,
//   platform object creation, and platform object release.
// - core window lifecycle receives only dehydrated lifecycle facts.
// - AppKit, Metal, Objective-C, NSWindow, NSView, CAMetalLayer, MTLDevice,
//   CAMetalDrawable, CGImageRef, Objective-C id, native handles, and raw pointers
//   are platform-adapter internal concerns only.
// - those names may appear here only as forbidden platform truth, not as API,
//   fields, parameters, return values, or implementation.
//
// Future slots, not implemented here:
// - create window:
//   - records a future creation request and binds dehydrated window state.
//   - platform adapter may later create platform objects on the platform main thread.
//   - core should only observe created / failed facts.
//   - must not expose native handles, create renderers, create scenes, create widgets,
//     or implicitly start app run.
// - request close:
//   - records a future idempotent close request for the target window.
//   - should unify auto-close, manual close, and future async close into one close path.
//   - must not directly release platform objects or bypass app lifecycle queue / drain.
// - destroy / release:
//   - destroy is a future terminal transition candidate for dehydrated window state.
//   - release is a future platform-adapter completion fact after platform cleanup.
//   - core must not directly release AppKit, Metal, or Objective-C objects.
// - stale message / destroyed window handling:
//   - destroyed window state must be terminal.
//   - stale close and stale message must not resurrect a window.
//   - stale operations must be safely discarded or classified by future structured errors.
// - single-window first slice:
//   - the first real implementation may remain single-window to keep the lifecycle
//     surface narrow.
//   - single-window is not a long-term runtime limit.
//
// Handle table / generation future trigger:
// - not implemented in this first skeleton.
// - must remain closed while there is no public window handle, multi-window,
//   target update, async UI message targeting, destroyed-target identity reuse,
//   or cross-thread target validation.
// - when any of those appear, open a separate handle table / generation preflight
//   or execution card before implementation.
//
// Error strategy relation:
// - window lifecycle can identify future error / diagnostics cases such as duplicate
//   close, close after destroyed, destroy before create, platform create failure,
//   platform release failure, stale message, wrong thread, invalid target identity,
//   or future generation mismatch.
// - concrete error types belong to future error strategy work.
// - smoke last_error must not migrate directly into the formal runtime.
// - future errors must be call-associated, structured, non-global, and concurrency-safe.
//
// Stop-line:
// - no real window create / close / destroy.
// - no handle table / generation implementation.
// - no multi-window, target update, or async UI message targeting.
// - no public runtime API.
// - no Renderer / Scene / Widget / Layout / DSL.
// - no Dirty Rect, global tick, blind redraw, or frame scheduler.
// - no Text / Input / IME / Accessibility.
// - no semantic tree / Action Router.
// - no command-list hash, pixel diff, baseline, or offscreen renderer.
