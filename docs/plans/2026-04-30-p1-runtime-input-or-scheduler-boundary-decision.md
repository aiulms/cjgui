# P1 Runtime Input-Or-Scheduler Boundary Decision

Date: 2026-04-30

## Current Landed Facts

- Runtime internal tail milestone is closed; default tail reaches `CjguiInternalRuntimeExecutionStateLoopClosure`.
- Runtime state store transition is stabilized with value-style version / snapshot / transition and derived open/defer/blocked helpers.
- The state store transition does not create global mutable state, does not publish state, does not write process-wide runtime state, and does not add public API / C ABI.
- No event loop, queue, scheduler, platform callback, or native handle has been opened.
- The project can now choose a new internal ingress boundary instead of continuing tail or store stabilization.

## Candidate Comparison

- A. `P1 internal input intent boundary bundle implementation`: closest to real GUI interaction and a natural predecessor to future event loop / platform input. It can remain fully dehydrated and internal-only if type count and sanity scope are constrained.
- B. `P1 internal scheduler tick intent boundary bundle implementation`: useful later for pacing, but more abstract now and more likely to become empty scheduler-shaped wrapper work.
- C. `P1 platform adapter input fact boundary bundle implementation`: important later, but too close to native/platform truth before a dehydrated input model exists.
- D. `P1 runtime state store transition second stabilization / cleanup`: lowest risk, but the store transition already has a manifest and helper baseline; staying here would slow entry into the next real ingress boundary.

## Decision

Choose A: `P1 internal input intent boundary bundle implementation`.

State truth is now stable enough to open the next ingress boundary. Input intent is the right next slice because it is nearer to user-visible GUI interaction than scheduler tick, and safer than platform adapter input facts because it can be modeled as dehydrated internal values without native event objects, queues, or callbacks.

Scheduler tick is deferred because it is more abstract and should follow a clearer input model. Platform input facts are deferred because they should not be opened until core can receive dehydrated input intent without leaking platform truth. A second state-store stabilization is not needed unless the next implementation finds a concrete owner issue.

## Approved Next Opening

`P1 internal input intent boundary bundle implementation`

## Guardrails For Next Implementation

- Input intent must be dehydrated and internal-only.
- Do not connect platform events.
- Do not connect AppKit, Metal, Objective-C, native handles, raw pointers, or platform callback identity.
- Do not write queue, event loop, scheduler, drain, or loop semantics.
- Do not execute runtime cycle or runtime step.
- Do not write global state or create a global mutable singleton.
- Do not add public runtime API or public C ABI.
- Do not add a Request + Report double layer.
- Do not add a five-piece sanity helper bundle.
- Allowed scope is a small input intent / input source / input admission value model if it avoids wrapper-chain rebound.

## Verification Note

This round is docs-only. Build and smoke guard were not run. Verification is limited to `git diff --check`, link check, and forbidden-file check.
