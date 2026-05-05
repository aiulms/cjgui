# P1 Renderer command queue / drawable real lifecycle preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估是否允许打开 command queue / drawable real lifecycle runway，并判断下一刀应先拆 real command queue lifecycle，还是 real drawable lifecycle，或是否可以合并 owner。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER，不创建 command queue、drawable、command buffer、render pass、encoder、pipeline state，不创建 `MTLDevice` / `CAMetalLayer`，不创建 backend shell object、backend object、platform object、native handle、raw pointer，不调用 FFI / Objective-C / Metal / AppKit API，不 commit / present / submit GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [No-draw backend shell manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-no-draw-backend-shell-manifest-stabilization-closure-review.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-manifest.md)
- [Drawable acquisition lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Decision

允许打开 command queue / drawable real lifecycle runway，但本轮不批准 combined value boundary，不批准真实 `MTLCommandQueue` / drawable creation，也不批准直接进入 command buffer commit / GPU submission。

下一步选择：

`P1 internal Renderer real command queue lifecycle preflight decision`

理由：command queue ownership / creation / lifetime 是 drawable acquisition 与 command buffer creation 的更早硬前置。Apple command structure evidence 表明 command queue 组织 command buffer creation and execution ordering；drawable evidence 表明 drawable belongs to layer pool and should be requested late. 因此 real drawable lifecycle 应晚于 real command queue lifecycle owner vocabulary，除非后续 preflight 证明 drawable path 可独立更窄地切开。

## Split Decision

Command queue real lifecycle 与 drawable real lifecycle 应拆成两个 owner / runway。

Recommended split:

- First owner question：`runtime/cjgui/src/runtime_renderer_real_command_queue.cj`
- Later owner question：`runtime/cjgui/src/runtime_renderer_real_drawable_lifecycle.cj`

Why split:

- Command queue is long-lived backend-local infrastructure; drawable is per-frame / late-bound / availability-sensitive resource.
- Command queue lifecycle needs owner identity, creation policy, lifetime / teardown, failure / no-queue fallback and no-submit relation.
- Drawable lifecycle needs layer-backed availability, late acquisition, resize / scale / color relation, presentation ownership and no-draw fallback.
- Combining both would couple long-lived queue ownership with transient drawable borrowing and make teardown / failure semantics too broad.
- A combined owner would invite a thin wrapper over `CjguiInternalRendererNoBackendShellReadiness` rather than adding focused real-resource lifecycle semantics.

## Proposed Runtime Input

Future runtime value boundary, if later approved by its own preflight, should only consume:

- `CjguiInternalRendererNoBackendShellReadiness`
- `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`

Docs evidence may cite command queue lifecycle manifest, drawable acquisition lifecycle manifest, backend / Metal reference pack, Metal device-layer owner manifest, backend platform object owner manifest and GUI risk ledger. These must remain evidence only and must not become additional runtime inputs.

## Future Truth Shape

For the recommended next real command queue lifecycle runway, output truth should be limited to value facts such as:

- real command queue lifecycle intent.
- command queue owner identity / backend confinement policy.
- command queue creation policy.
- command queue lifetime / teardown / rollback policy.
- command queue availability / failure / no-real-command-queue readiness facts.

It must not create `MTLCommandQueue`, must not create command buffer, must not submit GPU work, must not retain native handle / raw pointer, and must not grant queue-ready permission.

For the later drawable lifecycle runway, output truth should be limited to value facts such as:

- real drawable lifecycle intent.
- drawable availability and acquisition timing policy.
- drawable borrowing / presentation ownership policy.
- resize / scale / color-space relation facts.
- drawable failure / no-draw / no-real-drawable readiness facts.

It must not acquire drawable, must not expose drawable texture, must not create `CAMetalDrawable` / `MTLDrawable`, and must not grant drawable-ready or render permission.

## Reference Evidence

Evidence supports choosing A rather than a combined boundary:

- No-draw backend shell manifest has sealed `CjguiInternalRendererNoBackendShellReadiness` as current endpoint and explicitly denies command queue / drawable / command buffer / render permission.
- Metal device-layer owner manifest fixed device selection, layer binding and scale-color-space facts, but denies `MTLDevice`, `CAMetalLayer`, command queue, drawable and native handle creation.
- Backend platform object owner manifest fixed native resource ownership vocabulary, but denies platform object, native handle, raw pointer and Metal object creation.
- Existing command queue lifecycle manifest already separates command queue lifecycle intent, creation guard, lifetime / shutdown / rollback policy and no-command-queue readiness. It is strong evidence for a real command queue preflight, but it remains no-resource value facts.
- Existing drawable acquisition lifecycle manifest already separates drawable availability, acquisition timing, presentation ownership and no-drawable readiness. It is strong evidence for a later drawable preflight, but it remains no-drawable value facts.
- Backend / Metal reference pack states that `MTLDevice` creates command queues, command queues create command buffers and order execution, while `CAMetalLayer` owns a limited drawable pool and drawable acquisition should be late and failure-aware.
- GUI risk ledger flags GPU resource lifecycle, FFI ownership, main-thread / platform exclusivity and automatic verification gaps as long-term risks; this argues for narrower preflights instead of combined implementation-like owners.

Evidence is not enough to implement:

- no runtime real command queue owner exists.
- no runtime real drawable owner exists.
- no runtime platform object / native handle representation is approved.
- no bridge ownership ABI, handle table, generation table or teardown implementation is approved.
- no command buffer commit / GPU submission gate is approved.
- no renderer state write or completion observation implementation is approved.
- lab smoke evidence remains lab-only and cannot become runtime truth.

## Candidate Comparison

### A. P1 internal Renderer real command queue lifecycle preflight decision

推荐。

Command queue ownership / creation / lifetime is the smallest next owner question that can safely承接 current no-backend-shell evidence. 下一轮仍必须 docs-only，评估 real command queue owner、creation policy、lifetime / teardown、failure / no-queue fallback、backend confinement and no-submit relation；不得创建 `MTLCommandQueue`。

### B. P1 internal Renderer real drawable lifecycle preflight decision

暂缓。

Drawable lifecycle should usually be later than real command queue lifecycle because drawable acquisition feeds command buffer / render pass / presentation, while queue ownership defines the backend-local submission infrastructure. 只有后续 evidence 证明 drawable 更窄且不依赖 queue owner，才可提前选择。

### C. P1 internal Renderer command queue / drawable combined value boundary

暂缓并通常拒绝。

Combined owner mixes long-lived command queue ownership with transient drawable borrowing / availability. It is likely too broad and risks becoming a no-backend-shell tail wrapper.

### D. Command buffer commit / GPU submission preflight

暂缓。

Current evidence explicitly stops at no-submit / no-render. Command buffer commit requires real command queue, drawable / presentation relation, resource lifetime and failure semantics that are not approved yet.

### E. Real backend shell implementation preflight

暂缓。

No-draw backend shell manifest is still value facts only. Real backend shell implementation should wait until real command queue and drawable owner preflights clarify resource boundaries.

### F. Direct `MTLCommandQueue` / drawable implementation

拒绝。

This would create platform / GPU resources without an approved owner or teardown path.

### G. Command buffer / render pass / encoder implementation

拒绝。

Command buffer, render pass and encoder materialization remain downstream of queue / drawable real lifecycle decisions.

### H. GPU submission / render execution

拒绝。

No-submit / no-render remains active.

### I. Renderer state write

拒绝。

No renderer state mutation is approved.

### J. Public API / C ABI expansion

拒绝。

Public allowlist remains unchanged.

### K. Receipt / record / publication / backend-ready permission wrapper

拒绝。

These would repackage `CjguiInternalRendererNoBackendShellReadiness` without adding real command queue lifecycle or real drawable lifecycle semantics.

### L. Consolidation

暂缓。

Only choose consolidation if explicit duplicate / low-value / self-wrapping evidence appears. Current evidence points to a narrower docs-only real command queue lifecycle preflight.

## Same-shape Boundary Brake

Do not wrap `CjguiInternalRendererNoBackendShellReadiness` into:

- command queue / drawable receipt.
- command queue / drawable record.
- command queue / drawable publication.
- queue-ready permission wrapper.
- drawable-ready permission wrapper.
- backend-ready permission wrapper.
- GPU-submission wrapper.
- render-permission wrapper.
- public API / C ABI wrapper.

The next step must add real command queue lifecycle owner / creation policy / lifetime / teardown / failure / no-real-resource readiness semantics. It must not be a no-backend-shell tail wrapper.

## Stop-line

This preflight does not approve:

- `MTLCommandQueue` creation.
- drawable acquisition.
- `CAMetalDrawable` / `MTLDrawable` creation or borrowing.
- command buffer creation.
- command buffer commit.
- render pass creation.
- encoder creation.
- pipeline state creation.
- `MTLDevice` creation.
- `CAMetalLayer` creation.
- backend shell object creation.
- backend object creation.
- platform object creation.
- native handle.
- raw pointer.
- FFI / Objective-C / Metal / AppKit API call.
- bridge / smoke / harness / native entry modification.
- drawable present.
- GPU submission.
- render execution.
- renderer state write.
- diagnostics / event bus / observer / telemetry.
- public API / public C ABI expansion.

## Validation Plan

This docs-only round must validate:

- `git diff --check`
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability for this preflight and the next opening
- forbidden check confirming no tracked `.cj` diff, no protected path diff/status and `runtime_state.cj` remains `10065` lines
- public declaration scan confirming only `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

Build / smoke must not run in this round.

## Unique Next Opening

`P1 internal Renderer real command queue lifecycle preflight decision`

下一轮仍必须 docs-only。它只能评估 real command queue owner、creation policy、lifetime / teardown、failure / no-queue fallback、backend confinement and no-submit relation；不得创建 `MTLCommandQueue`、command buffer、drawable、render pass、encoder、pipeline state、`MTLDevice`、`CAMetalLayer`、backend shell object、backend object、platform object、native handle or raw pointer，不得调用 FFI / Objective-C / Metal / AppKit API，不得 commit / present / submit GPU work，不得执行 render，不得写 renderer state，不得扩 public API / C ABI。

## Downstream Real Command Queue Lifecycle Preflight

Renderer real command queue lifecycle preflight 已完成：

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-preflight-decision.md)

该 preflight 允许打开 real command queue lifecycle runway，并选择 `P1 internal Renderer real command queue lifecycle value boundary bundle implementation` 作为下一步。下一步仍只是 internal value facts，不是真实 `MTLCommandQueue` creation。

Default owner candidate 是 `runtime/cjgui/src/runtime_renderer_real_command_queue.cj`；runtime input 只建议消费 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`。Output truth 仅限 real command queue lifecycle intent / queue creation policy / queue ownership guard / queue teardown policy / no-real-command-queue-readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 no-backend-shell endpoint 包成 real command queue receipt / record / publication、queue-ready permission wrapper、backend implementation wrapper、GPU-submission wrapper 或 command-buffer-ready wrapper。

Current downstream next opening:

`P1 internal Renderer real command queue lifecycle value boundary bundle implementation`

## Downstream Real Command Queue Manifest And Real Drawable Preflight

Real command queue lifecycle manifest stabilization is now recorded in:

- [2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-command-queue-lifecycle-manifest-stabilization-closure-review.md)

Real drawable lifecycle preflight is now recorded in:

- [2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-preflight-decision.md)

The real drawable preflight keeps `CjguiInternalRendererNoRealCommandQueueReadiness` as the only runtime input candidate, proves drawable availability / acquisition guard / presentation ownership / no-real-drawable-readiness semantics, and chooses value boundary next. It does not approve drawable acquisition, `nextDrawable`, command buffer creation, present / commit / GPU submission, render execution or renderer state write.

Current downstream next opening:

`P1 internal Renderer real drawable lifecycle value boundary bundle implementation`
