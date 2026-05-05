# P1 Renderer real backend shell implementation preflight decision

日期：2026-05-05

状态：docs-only preflight decision

## Scope

本轮评估是否可以从 no-draw backend shell、Metal device-layer、backend platform object、real command queue、real drawable 与 command submission evidence 靠近 real backend shell implementation。

本轮 docs-only：不修改 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

本轮不创建 backend shell object、backend object、platform object、native handle、raw pointer、`MTLDevice`、`CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder 或 pipeline state；不调用 `commit`、`present` 或 `nextDrawable`；不调用 Metal / AppKit / Objective-C / FFI；不提交 GPU work，不执行 render，不写 renderer state，不扩 public API / C ABI。

## Inputs Read

- [Command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)
- [No-draw backend shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-no-draw-backend-shell-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)
- [Backend platform object owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-platform-object-owner-manifest.md)
- [Real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [Real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)
- [Backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)

## Preflight Decision

允许靠近 real backend shell implementation runway，但第一刀仍必须继续拆成更窄的 docs-only first implementation slice preflight。

本轮不批准 direct backend shell implementation。

理由：

- No-draw backend shell manifest 已固定 `CjguiInternalRendererNoBackendShellReadiness` / `cjguiInternalExecuteDefaultRendererNoDrawBackendShellDraft()`，并表达 shell lifecycle / no-draw execution gate / teardown value facts。
- Backend platform object owner manifest 已固定 native resource ownership vocabulary、teardown policy、confinement failure facts 与 no-platform-object stop-line。
- Metal device-layer owner manifest 已固定 device selection / layer binding / scale-color-space facts 与 no-metal-device-layer stop-line。
- Real command queue manifest 已固定 queue creation policy / ownership guard / teardown value facts 与 no-real-command-queue stop-line。
- Real drawable manifest 已固定 drawable availability / acquisition guard / presentation ownership facts 与 no-real-drawable stop-line。
- Command submission manifest 已固定 commit policy / presentation gate / GPU submission failure facts 与 no-gpu-submission stop-line。
- Backend / Metal reference pack 提供 official evidence：device、layer、queue、drawable、command buffer、completion and resource lifetime must stay backend-local and never enter core packet truth。
- GUI risk ledger reinforces GPU lifecycle, FFI ownership, main-thread / AppKit boundary, bridge thickness and foreign surface containment risks.

这些 evidence 足以提出 real backend shell implementation 的第一实现切口问题，但仍不足以直接创建 backend shell object、platform object、native handle、Metal object、command buffer、drawable or GPU work。

## First-slice Requirement

下一步必须选择：

- `P1 internal Renderer backend shell first implementation slice preflight decision`

该下一轮仍必须 docs-only。它要决定第一实现切口，例如：

- 是否先实现 no-object backend shell skeleton。
- 是否先冻结 backend shell owner file / internal construction shape。
- 是否只允许 backend shell lifecycle enum / value shell，而不接 platform object。
- 如何定义 create / active / degraded / teardown / failure / rollback / no-draw path。
- 如何证明 smoke / verification strategy 只验证 shell lifecycle，不验证 Metal work。
- 如何确保 command submission、drawable、queue、platform object、device / layer facts 仍只是 evidence，不被解释成 permission。

如果下一轮不能明确 owner、resource lifetime、failure rollback、teardown、confinement 与 stop-line，就不能进入 implementation。

## Evidence Boundary

### No-draw backend shell endpoint

`CjguiInternalRendererNoBackendShellReadiness` is only no-backend-shell readiness. It is not backend shell permission, backend implementation permission, backend object permission, platform object permission, GPU submission permission, render permission, renderer state write permission, public API permission or C ABI permission.

It is useful here only because it names shell lifecycle / no-draw execution gate / teardown vocabulary.

### Platform object endpoint

`CjguiInternalRendererNoPlatformObjectReadiness` is only no-platform-object readiness. It gives native resource ownership / teardown / confinement vocabulary, not platform object creation, native handle, raw pointer, FFI or bridge permission.

### Metal device-layer endpoint

`CjguiInternalRendererNoMetalDeviceLayerReadiness` is only no-metal-device-layer readiness. It gives future device selection / layer binding / scale-color-space vocabulary, not `MTLDevice`, `CAMetalLayer`, Metal API or command queue permission.

### Real command queue endpoint

`CjguiInternalRendererNoRealCommandQueueReadiness` is only no-real-command-queue readiness. It gives queue creation / ownership / teardown vocabulary, not `MTLCommandQueue`, command buffer, drawable, GPU submission or render permission.

### Real drawable endpoint

`CjguiInternalRendererNoRealDrawableReadiness` is only no-real-drawable readiness. It gives drawable availability / acquisition guard / presentation ownership vocabulary, not drawable acquisition, `nextDrawable`, drawable present, command buffer or GPU submission permission.

### Command submission endpoint

`CjguiInternalRendererNoGpuSubmissionReadiness` is only no-gpu-submission readiness. It gives command submission intent / commit policy / presentation gate / GPU submission failure vocabulary, not command buffer permission, drawable present permission, GPU submission permission, backend implementation permission or renderer state write permission.

## Smoke Evidence Boundary

`labs/macos_bridge_smoke` can only remain feasibility / teardown / smoke evidence.

It can inform future questions about:

- whether AppKit / Metal bridge reachability exists on this machine.
- whether teardown ordering needs explicit verification.
- whether auto-close or lifecycle smoke can guard the first implementation slice.
- whether manual visual confirmation should be treated as supplemental evidence only.

It cannot become:

- runtime truth.
- backend shell owner truth.
- backend object lifecycle truth.
- public ABI truth.
- multi-window or cross-platform truth.
- renderer state write truth.
- visual baseline truth.
- GPU submission or render correctness proof.

## Explicit Non-Permissions

Backend shell implementation does not equal GPU submission.

Backend shell implementation does not equal renderer state write.

Backend shell implementation does not equal public API permission.

Backend shell implementation does not equal backend-ready permission.

Backend shell implementation does not equal platform object permission.

Backend shell implementation does not equal native handle / raw pointer permission.

Backend shell implementation does not equal Metal / AppKit / Objective-C / FFI permission.

Backend shell implementation does not equal command buffer permission, drawable present permission, render pass permission, encoder permission or pipeline state permission.

Future real backend shell implementation, if ever approved, must keep CJGUI host / Action Router / semantic truth sovereignty. It must not introduce browser host, WebView host, browser kernel as primary renderer, foreign surface as main input owner, or external surface as semantic truth owner.

## Candidate Comparison

### A. P1 internal Renderer backend shell first implementation slice preflight decision

谨慎推荐。

This is the right next step because the current evidence chain is strong enough to ask where the first implementation slice should land, but not strong enough to write runtime implementation directly.

The next preflight must choose a first slice and stop-line before code:

- owner file / write set.
- shell construction boundary.
- resource lifetime boundary.
- teardown and rollback.
- failure / no-draw path.
- confinement of platform and Metal facts.
- smoke / verification strategy.
- public surface stop-line.

### B. P1 internal Renderer backend shell lifecycle hardening preflight decision

备选，仅在发现 shell lifecycle / teardown / confinement evidence 仍不足时选择。

Current no-draw backend shell manifest already has lifecycle, no-draw gate and teardown value facts. Hardening is not the best default unless future review finds concrete gaps in create / active / degraded / teardown / rollback vocabulary.

### C. P1 internal Renderer native resource bridge preflight decision

备选，仅在第一实现切口必须先冻结 native bridge / handle ownership 降落伞时选择。

This may become necessary if first-slice preflight finds that even a no-object backend shell needs a stricter bridge vocabulary. It is not selected now because current evidence says platform / native resources are still forbidden and should remain outside the first implementation choice until a narrower preflight proves otherwise.

### D. Render completion / frame completion tracking preflight

暂缓。

Completion tracking is too close to callback, telemetry, observer, GPU completion status and renderer state visibility. It should wait until backend shell first implementation slice and resource ownership rules are clearer.

### E. Real command buffer creation / commit preflight

暂缓。

Command submission manifest is a no-gpu-submission endpoint. It explicitly does not grant command buffer creation, `commit`, `present`, `nextDrawable`, GPU submission or render permission.

### F. Direct backend shell implementation

拒绝。

This preflight does not approve creating backend shell object, backend object, platform object or runtime owner.

### G. Direct platform object / native handle implementation

拒绝。

No platform object, native handle or raw pointer creation is approved.

### H. Direct Metal / AppKit / Objective-C / FFI implementation

拒绝。

No `MTLDevice`, `CAMetalLayer`, `MTLCommandQueue`, drawable, command buffer, Metal / AppKit / Objective-C / FFI API call or bridge modification is approved.

### I. GPU submission / render execution implementation

拒绝。

No `commit`, `present`, `nextDrawable`, GPU work, render pass, encoder, pipeline state, draw call or render execution is approved.

### J. Renderer state write

拒绝。

No renderer state mutation and no `runtime_state.cj` write are approved.

### K. Public API / C ABI expansion

拒绝。

The public declaration allowlist remains unchanged.

### L. Receipt / record / publication

拒绝。

Do not add real backend shell receipt / record / publication, backend-ready permission wrapper, platform-object permission wrapper, native-handle wrapper, GPU-submission wrapper or render-permission wrapper.

### M. Consolidation

仅在发现明确 duplicate / self-wrapping evidence 时选择。

Current evidence points to a new first-slice preflight, not deletion or consolidation.

## Same-shape Boundary Brake

This preflight must not wrap any existing endpoint into a new permission-shaped tail.

Forbidden wrappers:

- real backend shell receipt / record / publication.
- backend-ready permission wrapper.
- backend implementation permission wrapper.
- platform-object permission wrapper.
- native-handle wrapper.
- device-ready wrapper.
- layer-ready wrapper.
- queue-ready wrapper.
- drawable-ready wrapper.
- GPU-submission wrapper.
- command-buffer-ready wrapper.
- render-permission wrapper.
- renderer-state-write wrapper.
- public API / C ABI wrapper.

Do not treat these as implementation permission:

- `CjguiInternalRendererNoBackendShellReadiness`
- `CjguiInternalRendererNoMetalDeviceLayerReadiness`
- `CjguiInternalRendererNoPlatformObjectReadiness`
- `CjguiInternalRendererNoRealCommandQueueReadiness`
- `CjguiInternalRendererNoRealDrawableReadiness`
- `CjguiInternalRendererNoGpuSubmissionReadiness`
- backend-readiness branch milestone
- backend / Metal reference pack

If future work moves closer to implementation, it must first add owner / lifecycle / teardown / failure / rollback / smoke strategy evidence, not another no-backend-ready tail wrapper.

## Future Stop-line

The next first-slice preflight must still not:

- modify `.cj`.
- create runtime owner.
- run build or smoke.
- touch `runtime_state.cj`, `runtime/cjgui/cjpm.toml`, smoke, harness, native bridge, entry, AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER.
- create backend shell object.
- create backend object.
- create platform object.
- create native handle.
- create raw pointer.
- create `MTLDevice`.
- create `CAMetalLayer`.
- create `MTLCommandQueue`.
- acquire drawable.
- create command buffer.
- create render pass.
- create encoder.
- create pipeline state.
- call `commit`.
- call `present`.
- call `nextDrawable`.
- call Metal / AppKit / Objective-C / FFI.
- submit GPU work.
- execute render.
- write renderer state.
- expand public API / C ABI.
- add diagnostics output / telemetry / observer / event bus.
- introduce browser host, WebView host, browser kernel main renderer, foreign surface main input owner or external semantic truth owner.

## Validation Plan

This docs-only decision should be verified with:

- `git diff --check`
- new decision no-index whitespace check.
- Markdown absolute link missing target check, scoped to project docs and excluding `reference_repos/`.
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability.
- forbidden check: no tracked `.cj` diff, no protected path diff / status, `runtime_state.cj` line count remains `10065`.
- public declaration scan still finds only `cjguiExperimentalQueueSubmitShellReady(): Bool`.
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`.

Build and smoke must not be run in this docs-only round.

## Unique Next Opening

`P1 internal Renderer backend shell first implementation slice preflight decision`

## Downstream Backend Shell First Implementation Slice Preflight

Renderer backend shell first implementation slice preflight 已完成：

- [2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-backend-shell-first-implementation-slice-preflight-decision.md)

该 decision 选择 A `backend shell skeleton / no-resource implementation slice`，而不是 native resource bridge preflight、platform object implementation preflight、Metal device-layer implementation preflight、command queue / drawable implementation preflight 或 direct backend implementation。

下一步只允许进入 `P1 internal Renderer backend shell skeleton no-resource value boundary bundle implementation`。推荐 owner candidate 是 `runtime/cjgui/src/runtime_renderer_backend_shell_skeleton.cj`，runtime input candidate 只消费 `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`。允许新增的 truth 仅限 backend shell skeleton intent / lifecycle envelope / no-resource guard / failure rollback / teardown confinement / no-resource readiness value facts。

Same-shape Boundary Brake 继续生效：不得把 `CjguiInternalRendererNoBackendShellReadiness`、`CjguiInternalRendererNoPlatformObjectReadiness`、`CjguiInternalRendererNoMetalDeviceLayerReadiness`、`CjguiInternalRendererNoRealCommandQueueReadiness`、`CjguiInternalRendererNoRealDrawableReadiness`、`CjguiInternalRendererNoGpuSubmissionReadiness` 或 smoke / milestone evidence 包成 backend-shell-ready permission wrapper、native-handle wrapper、platform-object wrapper、Metal-device wrapper、GPU-submission wrapper、render-permission wrapper、receipt / record / publication。
