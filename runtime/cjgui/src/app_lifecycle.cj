package cjgui

// P1 app lifecycle surface comment-only refinement.
// Date: 2026-04-26
//
// This file contains one default-internal app lifecycle state marker with one
// minimal dehydrated Bool shape field and documentation comments.
// It does not define a public runtime API.
// It does not implement app lifecycle behavior.
// It does not call smoke C ABI.
// It does not create or drive an event loop.
// It does not create package or build entry semantics.
//
// Internal app lifecycle state marker:
// - this ordinary top-level struct uses default internal visibility.
// - it only marks that the app lifecycle state boundary exists.
// - it also marks that the lifecycle state machine is not yet defined.
// - it has one immutable Bool field, isStateMachineActive, initialized to false.
// - that field does not define a state machine.
// - it has no functions, methods, explicit init, imports, or behavior.
// - it is not run, shutdown, request quit, queue, drain, public runtime API,
//   public C ABI, platform callback binding, window lifecycle behavior, or
//   error strategy behavior.

struct CjguiInternalAppLifecycleState {
    let isStateMachineActive: Bool = false
}

//
// Future app lifecycle owner:
// - belongs to the formal runtime/cjgui core app lifecycle module.
// - does not belong to labs/macos_bridge_smoke.
// - owns dehydrated app lifecycle state and app-level policy notes.
// - does not own platform objects, native handles, or platform callbacks.
//
// Platform adapter relation:
// - platform adapter owns platform runloop, callback, and main-thread facts.
// - platform adapter may drive core with dehydrated lifecycle facts.
// - core app lifecycle consumes platform_ready, quit_requested,
//   queue_drain_requested, queue_drain_completed, and shutdown facts only
//   after those facts are explicitly designed in a future card.
// - core app lifecycle must not hold NSRunLoop, NSEvent, dispatch_main,
//   Objective-C callback truth, AppKit delegate identity, or native handle
//   truth. These terms appear here only as forbidden platform truth.
//
// Future run slot:
// - run is a future slot, not an API and not an implementation.
// - run is not an alias for an AppKit runloop.
// - run is not a render loop, frame loop, or default global tick.
// - run must not implicitly create a window.
// - blocking, pump, step, or adapter-driven semantics remain unresolved.
//
// Future shutdown slot:
// - shutdown is a future terminal transition slot.
// - shutdown must eventually define idempotence and late-message policy.
// - shutdown must not directly release platform objects from core.
// - shutdown behavior is not implemented in this file.
//
// Future request quit slot:
// - request quit is a future app-level request slot.
// - manual quit, future async quit, and platform close-all requests should
//   eventually converge into one app lifecycle path.
// - request quit is not immediate destroy.
// - request quit behavior is not implemented in this file.
//
// Main-thread queue / drain conceptual owner:
// - app lifecycle is the future policy owner for accepting or rejecting
//   app-level queue messages.
// - platform adapter remains the execution owner for running drain on the
//   platform main thread.
// - queue payloads must be dehydrated and must not carry platform objects.
// - drain must not run on a background thread.
// - queue and drain are not implemented in this file.
//
// No default global tick / blind redraw:
// - app lifecycle must not introduce a default global tick.
// - app lifecycle must not introduce blind redraw or a frame scheduler.
// - redraw, invalidation, dirty rect, and animation scheduling require
//   separate future preflight before any implementation.
//
// Error strategy relation:
// - app lifecycle may produce future diagnostics for wrong thread,
//   platform readiness failure, repeated run, late message, invalid state,
//   queue drain failure, or shutdown transition failure.
// - concrete error types are not part of this slice.
// - smoke last_error cannot migrate directly into runtime error strategy.
//
// Window lifecycle boundary relation:
// - app lifecycle owns app-level state and queue acceptance policy.
// - window lifecycle owns window target state, create, request close,
//   destroy / release, and stale target classification.
// - handle table and generation are future window lifecycle slots, not app
//   lifecycle slots.
// - destroyed window messages must not revive a window, but the target
//   validation owner is future window lifecycle / handle table.
//
// Stop-line:
// - no real runtime implementation.
// - no stable function signatures.
// - no public C ABI or public runtime API.
// - no package or build config.
// - no app run, event loop, queue, drain, shutdown, or request quit behavior.
// - no window create / close / destroy behavior.
// - no handle table / generation.
// - no platform object exposure or raw pointer public surface.
// - no Renderer / Scene / Widget / Layout / DSL.
// - no Dirty Rect / global tick / frame scheduler.
// - no Text / Input / IME / Accessibility.
// - no semantic tree / Action Router.
// - no command-list hash / pixel diff / baseline / offscreen renderer.
