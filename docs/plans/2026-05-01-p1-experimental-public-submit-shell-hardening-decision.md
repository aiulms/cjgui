# P1 experimental public submit shell hardening decision

## Current Facts

- Previous opening landed `P1 internal Queue experimental public submit shell boundary bundle implementation`.
- Owner file: `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`
- Current endpoint: `CjguiInternalQueueExperimentalSubmitResult`
- Current public shell allowlist:
  - `cjguiExperimentalQueueSubmitShellReady(): Bool`
- The shell is experimental, Bool-only, and does not expose internal owner types.
- Cangjie visibility rules have been checked: top-level declarations default to `internal`; `public` top-level declarations are globally visible; a `public` signature cannot expose internal types, while the function body may use internal declarations.
- Current state is still not stable public API, not public C ABI, not real enqueue, not process-wide queue storage write, not queue drain, not scheduler / event loop, and not runtime cycle.
- `runtime_state.cj` remains a 10065-line critical warning file and must not be touched.

## Candidate Comparison

### A. public shell hardening / visibility manifest stabilization

- Pros: fixes the first public symbol as experimental, Bool-only, no-stable-compatibility, not enqueue, not C ABI, and not a real side effect.
- Pros: establishes a public symbol allowlist before future models casually add more `public` declarations.
- Risk: does not expand user-facing capability, but that is intentional because the first public shell just appeared.
- Decision: choose.

### B. public submit result shape hardening boundary

- Pros: could add internal hardening facts around submit result shape.
- Risk: may become same-owner thin wrapper if it only rephrases `CjguiInternalQueueExperimentalSubmitResult`.
- Decision: defer. If selected later, it must be a W2 / W3 bundle and must not add more public symbols.

### C. second public symbol

- Risk: too soon after the first public shell; expands visibility before allowlist / manifest hardening exists.
- Decision: reject for now.

### D. richer public API with structured return

- Risk: expands compatibility surface and would start shaping public return contracts before hardening.
- Decision: reject.

### E. public C ABI

- Risk: needs stable handle, lifecycle, ABI error model, and compatibility policy.
- Decision: reject.

### F. real enqueue implementation

- Risk: public submit shell facts are not queue mutation permission.
- Decision: reject.

### G. drain / scheduler / event loop

- Risk: too close to runtime cycle and scheduling behavior.
- Decision: reject.

### H. runtime state integration

- Risk: would approach critical `runtime_state.cj` and global runtime state.
- Decision: reject.

### I. rollback / disable public shell

- Use only if build, visibility, or compatibility checks fail.
- Current evidence: build passed, signature is Bool-only, and no internal type is exposed.
- Decision: not needed.

## Decision

Choose A:

`P1 internal Queue experimental public submit shell hardening / visibility manifest bundle implementation`

The next opening should harden the public shell boundary before any public surface expansion. It should record the current public symbol allowlist, make the no-stable-compatibility and no-`enqueue` naming rule explicit, and keep public C ABI / real enqueue / scheduler / drain / runtime cycle closed.

## Next Opening

`P1 internal Queue experimental public submit shell hardening / visibility manifest bundle implementation`

Suggested scope:

- Default docs + manifest hardening.
- If source changes are needed, restrict them to `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_queue_public_submit.cj`.
- Do not add a second public symbol.
- Do not expose internal owner types.
- Do not use `enqueue` naming.
- Do not promise stable public API compatibility.
- Do not implement public C ABI, real enqueue, process-wide queue storage write, global mutable queue, drain, scheduler, event loop, runtime cycle, or runtime global state write.
- Do not touch `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj`.

## Public Symbol Allowlist

- Allowed now:
  - `cjguiExperimentalQueueSubmitShellReady(): Bool`
- Not allowed next:
  - any second public symbol
  - structured public return value
  - public C ABI entry
  - public symbol using enqueue terminology
  - any public signature exposing internal queue owner types

## Verification Guidance

- Run `git diff --check`.
- Ensure `/Users/jiangxuanyang/Desktop/cangjie/README.md`, `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`, and `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md` link this decision and the next opening.
- Run Markdown absolute-link missing target check.
- Run forbidden scope checks for `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke tracked source, harness, native bridge, entry files, `AGENTS.md`, `CLAUDE.md`, and `CANGJIE_ISSUE_LEDGER.md`.
- Scan public symbols with `rg -n "\\bpublic\\b" runtime/cjgui/src`; current allowed declaration-level symbol is only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- Do not run build / smoke for docs-only rounds unless runtime code changes.
