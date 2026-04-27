package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// Date: 2026-04-26
//
// This file is intentionally comment-only.
// It is not a platform adapter implementation.
// It is not a public runtime API.
// It is not a public C ABI.
// It does not bind AppKit, Metal, CoreGraphics, Objective-C callbacks, or any native framework.
// It does not migrate smoke code or reuse the smoke C ABI.
// It does not expose platform objects, native handles, raw pointers, or platform ownership to core.
//
// Platform adapter owner:
// - Future owner belongs to the runtime/cjgui platform adapter module.
// - The adapter owns platform event loop facts, callback facts, platform readiness, platform failure,
//   and platform object lifetime inside the adapter boundary only.
// - The adapter may eventually hold AppKit / Metal / Objective-C objects internally, but those
//   objects must never become core runtime truth or public surface.
//
// App lifecycle relation:
// - App lifecycle owns app-level state, quit policy, and the conceptual main-thread queue / drain
//   contract after those surfaces are approved by separate cards.
// - Platform adapter may drive app lifecycle by sending dehydrated app facts, such as platform ready,
//   platform failed, queue drain requested, quit requested, and shutdown observed.
// - Platform adapter must not force core app lifecycle to encode NSRunLoop, NSEvent, dispatch_main,
//   Objective-C delegate, or callback ownership as core facts.
//
// Window lifecycle relation:
// - Window lifecycle owns dehydrated window state and classification after those surfaces are approved.
// - Platform adapter may send facts such as window create observed, close requested, visible / hidden,
//   destroyed, release completed, stale target observed, or platform-window failure.
// - Platform adapter must not send native window objects, native view objects, Metal layer objects,
//   drawables, command queues, image handles, or Objective-C object identity to core.
//
// Platform object ownership stays internal:
// - AppKit / Metal / CoreGraphics / Objective-C object ownership is adapter-internal only.
// - Core modules may receive opaque dehydrated booleans, enums, ids from future runtime-owned tables,
//   and structured summaries after those policies exist.
// - Core modules must not own platform pointers, retain / release platform objects, or depend on
//   platform callback identity.
//
// Dehydrated facts to core:
// - lifecycle facts: platform ready, platform failed, app quit requested, app shutdown observed.
// - queue facts: main-thread drain requested, drain completed, stale drain ignored.
// - window facts: create requested / observed, close requested, closing, destroyed, release completed,
//   stale window message, visibility summary, display / scale summary.
// - future input facts: only dehydrated input summaries after Text / Input / IME boundaries are opened.
// - future frame facts: only invalidation / redraw summaries after render scheduling boundaries are opened.
//
// Forbidden facts to core:
// - platform object pointers or native handles.
// - AppKit / Metal / CoreGraphics object ownership.
// - raw platform event objects.
// - NSRunLoop, NSEvent, dispatch_main, or Objective-C callback truth.
// - callback ownership, delegate identity, runloop mode, or native thread-affinity details as API.
// - smoke C ABI names, smoke global state, or smoke last_error semantics.
//
// Main-thread ownership boundary:
// - macOS UI work must remain main-thread owned by the platform adapter / platform bridge.
// - Core app lifecycle may own the future queue / drain policy conceptually, but core must only see
//   dehydrated queue facts and cannot directly operate a platform runloop.
// - Background or async UI requests must eventually enter core as queued intent and return to the
//   platform adapter as main-thread work only through an approved bridge boundary.
//
// Smoke bridge relation:
// - labs/macos_bridge_smoke remains smoke / lab evidence, not runtime source.
// - Smoke bridge lessons may inform constraints: main-thread ownership, controlled lifecycle, platform
//   object hiding, and narrow diagnostics.
// - Smoke directory layout, smoke build scripts, smoke C ABI shape, single-instance globals, auto-close
//   behavior, clear-color render path, screenshot / frame hash diagnostics, and global last_error
//   semantics do not migrate into this module.
//
// Error boundary / last_error non-migration:
// - Smoke last_error was useful evidence, but it must not become the future runtime error system.
// - Future adapter errors must be call-associated, structured, non-global, concurrency-safe, and
//   separable from app lifecycle and window lifecycle failures.
// - Platform adapter may report dehydrated readiness / failure summaries, but must not leak native
//   error objects or platform callback state to core public surface.
//
// No platform runloop truth in core:
// - NSRunLoop, NSEvent, dispatch_main, AppKit delegate truth, Objective-C callback truth, and native
//   runloop modes are adapter-internal implementation details only.
// - Core runtime must not model those terms as owner, field, stable API, public enum, or behavior.
//
// No default frame scheduler / global tick:
// - Platform adapter boundary does not imply a default global tick, blind redraw, frame scheduler,
//   Dirty Rect system, Display List, Command Buffer API, command-list hash, pixel diff, baseline,
//   offscreen renderer, Renderer, Scene, Widget, Layout, Text, Input, IME, Accessibility, semantic tree,
//   or Action Router.
// - Future frame / redraw facts, if approved, must be invalidation-driven and separately bounded.
//
// Current stop-line:
// - no platform adapter implementation.
// - no event loop binding.
// - no callback binding.
// - no package / build config.
// - no public runtime API or public C ABI.
// - no smoke migration.
// - no platform object exposure.
