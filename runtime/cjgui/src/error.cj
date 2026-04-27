package cjgui

// P1 minimal app/window lifecycle runtime skeleton.
// Date: 2026-04-26
//
// This file contains one default-internal compile sanity marker, one
// default-internal error facts boundary type, and documentation comments.
// It does not define a stable error API.
// It does not implement runtime errors.
// It does not define an error enum, Result type, or exception-like mechanism.
// It does not migrate smoke last_error.
//
// Internal compile sanity marker:
// - this ordinary top-level struct uses default internal visibility.
// - it only verifies that package cjgui can carry a non-public symbol.
// - it is not an error type, lifecycle type, handle type, runtime API,
//   public C ABI, or behavior surface.

struct CjguiInternalCompileSanityMarker {}

// Internal error facts boundary type:
// - this ordinary top-level struct uses default internal visibility.
// - it is the first minimal semantic runtime type in this package.
// - it only marks a future internal error facts boundary.
// - it carries one dehydrated Bool fact: no native payload is present.
// - it is not an error strategy implementation.
// - it is not an error enum, Result type, exception-like mechanism,
//   public runtime API, public C ABI, handle type, platform object wrapper,
//   or behavior surface.

struct CjguiInternalErrorFact {
    let hasNativePayload: Bool = false
}

// Internal error taxonomy marker:
// - this ordinary top-level struct uses default internal visibility.
// - it only marks that the taxonomy boundary exists.
// - it also marks that taxonomy is not yet defined.
// - it has no fields, functions, methods, explicit init, imports, or behavior.
// - it is not an error enum, Result type, exception-like mechanism,
//   public runtime API, public C ABI, diagnostics truth system, or smoke
//   last_error migration.

struct CjguiInternalErrorTaxonomyMarker {}

//
// Error strategy owner:
// - future ownership belongs to the runtime/cjgui error strategy module.
// - the owner classifies failures and degraded diagnostics.
// - the owner must not become app state, window state, or platform truth.
//
// App lifecycle relation:
// - app lifecycle owns app-level policy such as run, quit, shutdown, and
//   main-thread queue acceptance.
// - error strategy may classify app-level fatal, recoverable, or degraded
//   outcomes after app lifecycle reports them.
// - error strategy must not implement run, shutdown, request quit, queue, or
//   drain behavior.
//
// Window lifecycle relation:
// - window lifecycle owns target state such as created, closing, destroyed,
//   stale target, and future window identity.
// - error strategy may classify create, request-close, destroy, release,
//   stale handle, and stale message failures after window lifecycle reports
//   them.
// - error strategy must not implement window create, request close, destroy,
//   release, handle table, generation, or multi-window targeting.
//
// Platform adapter relation:
// - platform adapter owns native failure details and platform capability facts.
// - core error strategy may only receive dehydrated failure summaries.
// - platform object pointers, raw events, native handles, callback ownership,
//   and runloop truth must not become error API surface.
//
// Smoke last_error non-migration:
// - smoke last_error is experimental evidence only.
// - it must not be expanded into a long-term concurrent error system.
// - future runtime errors must be call-associated, structured, non-global,
//   and concurrency-safe.
//
// Future minimum classification vocabulary:
// - fatal: the current lifecycle path cannot safely continue.
// - recoverable: the caller or lifecycle owner may retry or choose an
//   alternate path after receiving a structured failure.
// - degraded: the system continues with explicitly recorded reduced evidence
//   or capability.
// - invalid usage / contract violation: the caller broke a frozen contract.
// - platform capability missing: the platform adapter reports that a required
//   capability is unavailable or denied.
// - stale handle / stale message: the target was destroyed, superseded, or no
//   longer accepts the message.
//
// Fail-closed policy:
// - unknown ownership, stale target, invalid lifecycle ordering, denied
//   capability, and ambiguous native failure should fail closed.
// - a failure must not be silently swallowed unless it is explicitly classified
//   as degraded diagnostics.
// - diagnostics may support evidence and closure review, but diagnostics are
//   not a second state truth source.
//
// Public surface stop-line:
// - no public runtime API.
// - no public C ABI.
// - no error enum.
// - no Result type.
// - no exception-like mechanism.
// - no stable function signature.
// - no package or build entry.
// - no smoke C ABI reuse.
// - no platform object exposure.
// - no Renderer / Scene / Widget / Layout / DSL.
// - no global tick, Dirty Rect, frame scheduler, Text / Input / IME /
//   Accessibility, semantic tree, Action Router, command-list hash, pixel
//   diff, baseline, or offscreen renderer.
