# P1 Renderer backend / Metal reference pack

日期：2026-05-03

状态：reference pack bundle

## Purpose

本 reference pack 为 future renderer backend-readiness preflight 提供小而硬的官方依据和问题清单。

它只服务 future backend-readiness preflight，不批准 backend implementation，不创建 runtime owner，不写 `.cj`，不接 Metal / AppKit / CAMetalLayer / command buffer / render execution / renderer state write。

Current renderer packet truth 仍停在：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

该 packet truth 是 backend-agnostic value facts，不是 backend packet、command buffer、render permission 或 renderer state write permission。

## Source Policy

Primary sources 仅采用 Apple 官方资料：

- [Setting up a command structure](https://developer.apple.com/documentation/Metal/setting-up-a-command-structure)
- [MTLCommandBuffer.present(_:)](https://developer.apple.com/documentation/metal/mtlcommandbuffer/present%28_%3A%29)
- [MTLCommandBuffer.addCompletedHandler(_:)](https://developer.apple.com/documentation/metal/mtlcommandbuffer/addcompletedhandler%28_%3A%29)
- [MTLCommandQueue.commandBufferWithUnretainedReferences](https://developer.apple.com/documentation/metal/mtlcommandqueue/makecommandbufferwithunretainedreferences%28%29)
- [Metal Programming Guide: Command Organization and Execution Model](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Cmd-Submiss/Cmd-Submiss.html)
- [Metal Programming Guide: Render Command Encoder](https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Render-Ctx/Render-Ctx.html)
- [Onscreen presentation](https://developer.apple.com/documentation/metal/onscreen_presentation)
- [CAMetalLayer.nextDrawable()](https://developer.apple.com/documentation/quartzcore/cametallayer/nextdrawable%28%29)
- [CAMetalLayer](https://developer.apple.com/documentation/quartzcore/cametallayer)
- [CAMetalDrawable](https://developer.apple.com/documentation/quartzcore/cametaldrawable)
- [MTLDrawable](https://developer.apple.com/documentation/metal/mtldrawable)
- [Using Metal to draw a view's contents](https://developer.apple.com/documentation/Metal/using-metal-to-draw-a-view%27s-contents)
- [MTKView](https://developer.apple.com/documentation/metalkit/mtkview)
- [NSView.wantsLayer](https://developer.apple.com/documentation/appkit/nsview/wantslayer)
- [NSView.convertToBacking(_:)](https://developer.apple.com/documentation/appkit/nsview/converttobacking%28_%3A%29-3zors)
- [NSWindow.convertToBacking(_:)](https://developer.apple.com/documentation/appkit/nswindow/converttobacking%28_%3A%29)
- [NSScreen.backingScaleFactor](https://developer.apple.com/documentation/appkit/nsscreen/backingscalefactor)
- [NSWindow.displayLink(target:selector:)](https://developer.apple.com/documentation/appkit/nswindow/displaylink%28target%3Aselector%3A%29)
- [CADisplayLink](https://developer.apple.com/documentation/quartzcore/cadisplaylink)
- [CVDisplayLink](https://developer.apple.com/documentation/corevideo/cvdisplaylink-k0k)

Secondary context 只作为架构参照：

- [Flutter Impeller rendering engine](https://docs.flutter.dev/perf/impeller)
- [Flutter Impeller DisplayList interop source](https://api.flutter.dev/impeller/dl_8h_source.html)
- [Chromium How cc Works](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/how_cc_works.md)
- [Zed GPUI README](https://github.com/zed-industries/zed/blob/main/crates/gpui/README.md)
- [Zed GPUI rendering blog](https://zed.dev/blog/videogame)

Secondary context 不能替代 Apple 官方资料，不能作为 backend implementation permission。

## Official Evidence Notes

### Metal command structure

Apple 的 command structure 资料固定以下 evidence：

- `MTLDevice` 是 GPU interface，也是创建 command queue、buffers、textures 等 device-specific objects 的根。
- `MTLCommandQueue` 创建 command buffers，并组织 command buffers 的执行顺序。
- `MTLCommandBuffer` 承载 encoded commands，最终被 commit 到 GPU。
- command encoder 将 render / compute / blit commands 追加进 command buffer。
- commit 不表示立即执行；Metal 会按 command queue 中 prior buffers 等待关系调度。
- command buffer commit 后不可复用。

Future CJGUI implication：

- `MTLDevice`、`MTLCommandQueue`、`MTLCommandBuffer` 只能属于 future backend owner，不得进入 core packet truth。
- Renderer packet 必须保持可丢弃、可重建、无 side effect。
- Backend-readiness preflight 必须说明 command queue / command buffer lifecycle 如何不反向污染 Scene / RenderCommand / normalization / ordering facts。

### Command buffer presentation / completion

Apple 的 command buffer docs 固定以下 evidence：

- presentation can be registered on a command buffer before commit。
- completion handlers must be added before commit。
- completion handlers are a place to observe completion status / errors after GPU work finishes。
- command buffers can be configured not to retain resources; if so, app code is responsible for retaining resources until GPU execution completes。

Future CJGUI implication：

- failure / rollback / no-draw path 不能靠 core packet callback 表达。
- Any future backend owner must own completion status, completion callback, and resource retention policy.
- Core packet owner 不得持有 drawable、command buffer、completion callback、native handle 或 raw pointer。

### Render command encoder / render pass lifecycle

Apple render command encoder docs 固定以下 evidence：

- `MTLRenderPassDescriptor` describes render pass attachments / destinations。
- `MTLRenderCommandEncoder` is created from a command buffer with a render pass descriptor。
- render pass attachments carry load / store actions and target textures。
- render pipeline state / resources / fixed-function state are bound before draw calls。
- draw calls are issued through the render command encoder。

Future CJGUI implication：

- `CjguiInternalRendererPacketOrderingHardeningResult` is not a render pass descriptor.
- Material grouping hints are not render pipeline state.
- Ordering basis is not render encoder ordering or draw-call execution.
- Backend-readiness preflight must define where render pass descriptors are created and why they remain backend-local.

### CAMetalLayer / drawable lifecycle

Apple `CAMetalLayer` / `CAMetalDrawable` docs固定以下 evidence：

- `CAMetalLayer` owns a limited drawable pool managed by Core Animation。
- `nextDrawable()` returns an available drawable, can wait for availability, and can return `nil` when layer properties are invalid or timeout applies。
- A drawable exposes a texture used as render pass output。
- A drawable is associated with its owning layer; app code should not implement `CAMetalDrawable` itself。
- A drawable should be requested late and released quickly to avoid stalls.
- `CAMetalLayer` configures device, pixel format, color space, framebuffer-only behavior, drawable size, presentation behavior, and display sync.

Future CJGUI implication：

- Drawable acquisition must be future backend-local and late-bound.
- Core packet cannot contain `CAMetalLayer`, `CAMetalDrawable`, drawable texture, native handle, raw pointer, or platform object.
- A no-draw path must exist when drawable acquisition fails, blocks, or returns `nil`.
- Resize / scale / color-space facts may become dehydrated input facts, but not platform object ownership.

### MTKView as official convenience layer

Apple `MTKView` docs固定以下 evidence：

- `MTKView` is a Metal-aware view backed by `CAMetalLayer`.
- It can provide a `currentRenderPassDescriptor` and `currentDrawable` for the current frame.
- It supports timed updates, draw notifications, and explicit drawing.
- `preferredFramesPerSecond`, `isPaused`, `enableSetNeedsDisplay`, `drawableSize`, `autoResizeDrawable`, color pixel format, and color space shape frame / drawable behavior.
- Apple guidance prefers obtaining drawable/render-pass info late and holding related drawable references for as little time as possible.

Future CJGUI implication：

- If CJGUI eventually uses `MTKView` or a custom `CAMetalLayer`, this decision belongs to backend/platform owner, not core renderer packet owners.
- Frame pacing policy cannot be inferred from packet readiness.
- Resize / drawable size / color space must be dehydrated facts before crossing into core packet vocabulary.

### AppKit view / layer / resize / backing scale

Apple AppKit docs固定以下 evidence：

- `NSView.wantsLayer` can make a layer-backed view; AppKit may create and manage the backing layer.
- A layer-hosting view is different: assigning a layer directly makes the app responsible for layer tree management, while the view still handles mouse / keyboard events.
- `convertToBacking(_:)` converts view/window coordinates into pixel-aligned backing store coordinates.
- `backingScaleFactor` represents the screen backing pixel scale, but Apple recommends using view conversion methods where possible.
- Window backing-property notifications and display-link APIs exist around display / scale / refresh changes.

Future CJGUI implication：

- AppKit `NSView` / layer-backed / layer-hosting policy must stay in platform owner.
- Resize / scale changes can become dehydrated facts, but cannot leak `NSView`, `CALayer`, or `CAMetalLayer` into command packet truth.
- Backend-readiness preflight must define how backing scale / drawable size / color space facts enter future backend owner without mutating renderer packet.

### Frame pacing / display refresh

Apple frame pacing references固定以下 evidence：

- `MTKView` can run timed updates, draw notifications, or explicit drawing.
- `NSWindow.displayLink(target:selector:)` creates a display link synchronized to the display a window is on.
- `CADisplayLink` exposes frame timing concepts such as `timestamp`, `targetTimestamp`, and preferred frame rate range.
- `CVDisplayLink` is a high-priority callback mechanism tied to display refresh, but it is a platform-level mechanism and not core renderer packet vocabulary.

Future CJGUI implication：

- Frame pacing owner must be separate from packet normalization / ordering truth.
- Packet readiness cannot imply frame callback readiness.
- Future backend-readiness preflight must decide whether frame pacing lives with platform adapter, backend owner, scheduler, or a separate pacing owner.

## Resource Ownership Sketch

Current reference pack owner sketch for future preflight only：

- `MTLDevice`：future backend/platform owner long-lived resource; never core packet。
- `MTLCommandQueue`：future backend owner long-lived queue; never Action / Queue / Runtime lower-level mutable facts。
- `MTLCommandBuffer`：future per-frame / per-submit backend object; never core packet; not reusable after commit。
- `MTLRenderPassDescriptor`：future per-frame backend descriptor or backend-local reusable descriptor; never renderer packet truth。
- `MTLRenderCommandEncoder`：future render pass encoding object; exists only during backend encoding。
- `CAMetalLayer`：future platform layer owner; never core packet。
- `CAMetalDrawable`：Core Animation owned, temporarily borrowed by backend; request late and release quickly。
- drawable texture：temporary render target borrowed through drawable; never stable renderer packet state。
- `NSView` / layer-hosting / layer-backed state：future AppKit platform owner; only dehydrated size / scale / color facts may cross boundaries.

This ownership sketch is not an implementation plan. It is a checklist for future preflight.

## Secondary Architecture Context

Secondary context only helps shape questions:

- Flutter / Impeller shows value in separating rendering intent / display-list style data from backend-specific shader / pipeline / resource work. It also emphasizes ahead-of-time pipeline / shader preparation and explicit resource labeling.
- Chromium cc / Skia shows a split between paint records / compositor scheduling / render passes / backend rasterization, and makes scheduling / damage / begin-frame policies explicit rather than treating paint records as backend execution permission.
- Zed / GPUI shows a custom UI renderer can keep app/UI concepts above a GPU-oriented rendering route, but it also highlights how quickly text, glyph atlases, primitive-specific shaders, and platform integration become backend/UI-system concerns.

These references are not permission to import their architectures, implement their renderer, or open Text / IME / Accessibility / Widget / Layout.

## Future Backend Preflight Questions

Future `P1 internal Renderer backend-readiness preflight decision` must answer:

- Backend owner 是谁？
- Backend owner 是否独占 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer？
- Platform resources 能否限制在 backend owner 内，不进入 core packet？
- Command queue / command buffer 生命周期如何不反向污染 Scene / RenderCommand / validation / normalization / ordering facts？
- Drawable acquisition 在何处发生，是否 late-bound，失败 / timeout / unavailable 如何表达？
- Resize / backing scale / drawable size / color space 如何进入 dehydrated facts？
- Frame pacing 由谁控制：AppKit display link、MTKView draw loop、scheduler owner、backend owner，还是独立 pacing owner？
- Render packet 如何保持可丢弃、可重建、无 side effect？
- Material grouping hints 如何保持 hints，而不变成 pipeline state / draw-call merge / GPU batching？
- Failure / rollback / no-draw path 如何表达，是否需要 backend-local no-draw result facts？
- Completion / scheduled / presented callbacks 是否只允许 backend-local diagnostic facts？
- Resource lifetime / retention policy 如何避免 command buffer completion 前释放 drawable / texture / buffer？
- Public allowlist 如何保持不变？

## Stop-line

本 reference pack 继续禁止：

- no runtime code。
- no `.cj` modifications。
- no owner file / readiness / receipt / record / publication。
- no backend-readiness wrapper。
- no `MTLDevice` / `CAMetalLayer` / native handle / raw pointer in core packet。
- no backend object creation。
- no command queue creation。
- no command buffer creation。
- no command buffer submission。
- no render pass creation。
- no render encoder creation。
- no draw call。
- no render execution。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no renderer state write。
- no dirty-region / diff / patch / incremental render。
- no Text / IME / Accessibility。
- no Widget / Layout / ECS。
- no public surface expansion。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本 reference pack 生效：

- 本轮不是 runtime boundary。
- 本轮不是 backend-readiness wrapper。
- 本轮不新增 owner file、readiness、receipt、record 或 publication。
- Reference pack 只保存 future backend-readiness preflight evidence。

后续若要进入 backend-readiness，必须另开 docs-only preflight，并引用本 reference pack 的具体 evidence。不得直接实现 backend / Metal / AppKit / CAMetalLayer / command buffer / render execution / renderer state write。

## Downstream Platform Resource Owner Manifest

Reference pack 已被 platform resource owner preflight 与 manifest stabilization 使用：

- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)
- [2026-05-03-p1-renderer-platform-resource-owner-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-manifest.md)
- [2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-manifest-stabilization-closure-review.md)

Downstream 结论仍保持 no-platform-resource：future resources 只能作为 policy targets 命名；allowed dehydrated facts 只限 resize / scale / color / frame pacing hints；`MTLDevice` / `CAMetalLayer` / native handle / raw pointer / drawable / command buffer / render pass / encoder 不得进入 core packet。下一步只允许 docs-only command queue lifecycle preflight。

## Downstream Command Queue Lifecycle Preflight

Reference pack 已支撑 command queue lifecycle preflight：

- [2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-queue-lifecycle-preflight-decision.md)

Command queue preflight 引用的 evidence 仍只证明 owner / ownership / creation guard / lifetime / no-command-queue 语义，不批准 `MTLCommandQueue` creation、command buffer creation / submission、drawable acquisition、render pass / encoder creation、backend implementation、render execution 或 renderer state write。

## Downstream Encoder Lifecycle Preflight

Reference pack 已支撑 renderer encoder lifecycle preflight：

- [2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-encoder-lifecycle-preflight-decision.md)

Encoder preflight 引用的 evidence 仍只证明 encoding scope / pipeline binding guard / end-encoding / no-encoder 语义，不批准 `MTLRenderCommandEncoder` creation、pipeline state binding、resource binding、draw calls、backend implementation、render execution 或 renderer state write。下一步若进入 runtime owner，也只能是 internal value facts，不是真实 backend / Metal implementation。

## Downstream Draw Call Lifecycle Preflight

Reference pack 已支撑 renderer draw call lifecycle preflight：

- [2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-draw-call-lifecycle-preflight-decision.md)

Draw call preflight 引用的 evidence 仍只证明 draw command shape / geometry source / draw sequencing / no-draw-call 语义，不批准 render command encoder calls、pipeline state binding、vertex / index buffer binding、texture binding、draw calls、backend implementation、GPU submission、render execution 或 renderer state write。下一步若进入 runtime owner，也只能是 internal value facts，不是真实 backend / Metal implementation。

## Downstream Pipeline State Lifecycle Preflight

Reference pack 已支撑 renderer pipeline state lifecycle preflight：

- [2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-pipeline-state-lifecycle-preflight-decision.md)

Pipeline state preflight 引用的 evidence 仍只证明 shader role / descriptor policy / compatibility guard / no-pipeline-state 语义，不批准 `MTLRenderPipelineState` / `MTLRenderPipelineDescriptor` creation、shader library / function resolution、pipeline compilation、pipeline cache mutation、encoder binding、buffer / texture binding、draw calls、backend implementation、GPU submission、render execution 或 renderer state write。下一步若进入 runtime owner，也只能是 internal value facts，不是真实 backend / Metal implementation。

## Next Stage Candidate Comparison

### A. P1 internal Renderer backend-readiness preflight decision

选择为下一阶段 opening。

Reference pack 已补齐 future backend-readiness preflight 的官方资料起点。下一轮应仅做 docs-only preflight，评估是否具备 backend owner / resource owner / lifecycle / no-render gate evidence，不得实现 backend。

### B. Platform resource owner preflight

暂缓。

Platform resource owner 应等 backend-readiness preflight 判断 owner / gate 后再拆。

### C. Command buffer lifecycle preflight

暂缓。

Command buffer lifecycle 太靠近真实 backend execution，应等 backend-readiness preflight 后再拆。

### D. Backend / Metal implementation

拒绝。

本 reference pack 不批准 backend implementation。

### E. Command buffer / render execution / renderer state write

拒绝。

这些仍是 stop-line。

### F. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

本 reference pack 只服务 renderer backend readiness，不打开 UI system / text / accessibility / dirty-region。

### G. Public surface expansion

拒绝。

public allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### H. Consolidation

暂缓。

仅在发现明确 duplicate / low-value helper / self-wrapping evidence 时选择。

## Decision

最终 next opening：

`P1 internal Renderer backend-readiness preflight decision`

下一轮仍必须 docs-only。它只能评估 backend-readiness owner / consumer / gate evidence，不能实现 backend、Metal / AppKit、CAMetalLayer、command buffer、render execution、renderer state write、platform resource owner 或 public surface expansion。

## Downstream Backend-readiness Preflight

Renderer backend-readiness preflight 已完成：

- [2026-05-03-p1-renderer-backend-readiness-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-readiness-preflight-decision.md)

该 preflight 判定 reference pack 已足以证明 backend-readiness 有新增 owner / policy / resource ownership 语义空间，但 platform resource owner truth 仍不足。因此当前不批准 `runtime_renderer_backend_readiness.cj`、backend-readiness wrapper、command buffer readiness 或 backend implementation。

下一步转向 docs-only `P1 internal Renderer platform resource owner preflight decision`，先评估 `MTLDevice` / `CAMetalLayer` / command queue / drawable / command buffer 的 owner / confinement / lifecycle / no-draw path evidence。

## Downstream Platform Resource Owner Preflight

Renderer platform resource owner preflight 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-preflight-decision.md)

该 preflight 使用本 reference pack 的 Metal command buffer / render pass lifecycle、`CAMetalLayer` drawable lifecycle、AppKit layer-backed / resize lifecycle、frame pacing、Retina scale / color space 与 resource ownership evidence，判定下一步可以进入 internal-only platform resource owner value boundary。

Reference pack 仍只是 docs evidence，不是 runtime input，不批准 backend implementation、platform resource creation、command queue、drawable、command buffer、render pass、render encoder、renderer state write 或 render execution。

## Downstream Platform Resource Owner Value Boundary

Renderer platform resource owner value boundary 已完成：

- [2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-platform-resource-owner-value-boundary-closure-review.md)

新增 owner 只消费 `CjguiInternalRendererPacketOrderingHardeningResult`，并输出 `CjguiInternalRendererNoPlatformResourceReadiness` / `cjguiInternalExecuteDefaultRendererPlatformResourceOwnerDraft()`。Reference pack 仍只作为 docs evidence；该 boundary 未创建 platform resource，未引入 backend implementation，未提交 command buffer，未触发 render execution。

## Downstream Platform Resource Owner Next-boundary Decision

Renderer platform resource owner next-boundary decision 已完成：

- [2026-05-03-p1-renderer-platform-resource-owner-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-platform-resource-owner-next-boundary-decision.md)

该 decision 判定 `CjguiInternalRendererNoPlatformResourceReadiness` 足够作为当前 no-platform-resource endpoint。Reference pack 继续作为 future lifecycle preflight evidence，不批准 command queue creation、drawable acquisition、command buffer、render execution 或 renderer state write。

## Downstream Drawable Acquisition Lifecycle Preflight

Renderer drawable acquisition lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-drawable-acquisition-lifecycle-preflight-decision.md)

该 preflight 引用本 reference pack 中的 `CAMetalLayer` drawable pool、`nextDrawable()` availability / failure、late-bound acquisition、AppKit resize / backing scale / color 与 frame pacing evidence，判定下一步可以进入 internal-only drawable acquisition lifecycle value boundary。Reference pack 仍只是 docs evidence，不是 runtime input，不批准真实 drawable acquisition、`CAMetalLayer` / drawable object creation、command buffer、render pass、encoder、backend implementation、render execution 或 renderer state write。

## Downstream Command Buffer Lifecycle Preflight

Renderer command buffer lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-preflight-decision.md)

该 preflight 引用本 reference pack 中的 command buffer creation / encoding / commit / completion-failure phase、commit 后不可复用、presentation / completion relation 与 resource retention evidence，判定下一步可以进入 internal-only command buffer lifecycle value boundary。Reference pack 仍只是 docs evidence，不是 runtime input，不批准 `MTLCommandBuffer` creation / commit、command queue creation、drawable acquisition、render pass / encoder creation、backend implementation、render execution 或 renderer state write。

## Downstream Command Buffer Lifecycle Manifest

Renderer command buffer lifecycle manifest stabilization 已完成：

- [2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md)
- [2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-command-buffer-lifecycle-manifest-stabilization-closure-review.md)

该 manifest 只使用本 reference pack 的 command buffer lifecycle evidence 来固定 no-command-buffer value endpoint；reference pack 仍不是 runtime input，不批准 render pass / encoder creation、backend implementation、render execution 或 renderer state write。下一步若进入 render pass lifecycle，只能先做 docs-only preflight。

## Downstream Render Pass Lifecycle Preflight

Renderer render pass lifecycle preflight 已完成：

- [2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-preflight-decision.md)

该 preflight 引用本 reference pack 中的 render pass descriptor / attachment / load-store / target texture evidence，以及 command buffer、drawable、AppKit resize / scale / color-space evidence，判定下一步可以进入 internal-only render pass lifecycle value boundary。

Reference pack 仍只是 docs evidence，不是 runtime input，不批准 `MTLRenderPassDescriptor` creation、render encoder creation、attachment object ownership、drawable texture exposure、backend implementation、render execution、draw call 或 renderer state write。

## Downstream Render Execution Preflight

Renderer render execution preflight 已完成：

- [2026-05-04-p1-renderer-render-execution-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-preflight-decision.md)

该 preflight 使用本 reference pack 中的 command buffer commit / completion evidence、render pass / encoder lifecycle evidence、draw call / pipeline relation evidence、frame pacing evidence 与 resource ownership evidence，判定下一步可以进入 internal-only render execution no-op value boundary。Reference pack 仍只是 docs evidence，不是 runtime input，不批准真实 render execution、command buffer commit、GPU submission、encoder calls、draw calls、pipeline binding、backend implementation、callback registration、telemetry、event bus、logging 或 renderer state write。

## Downstream Backend-readiness Revisit Preflight

Renderer backend-readiness revisit preflight 已完成：

- [2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-revisit-preflight-decision.md)

该 preflight 引用本 reference pack 的 Metal / AppKit lifecycle evidence，并结合 platform resource owner、command queue、drawable acquisition、command buffer、render pass、encoder、draw call、pipeline state 与 render execution no-op manifests 重新评估 backend-readiness。

结论：reference pack 已足以支撑 future backend-readiness 问题清单，但当前仍不批准 backend-readiness value boundary 或 backend implementation；主要缺口转为 backend object owner / lifecycle / acceptance gate truth。下一步只允许 docs-only `P1 internal Renderer backend object owner preflight decision`，不得创建 backend object、platform resource、command buffer、drawable、render pass、encoder、pipeline state、native handle 或 raw pointer，不得 GPU submission、render execution 或 renderer state write。

## Downstream Backend Object Owner Preflight

Renderer backend object owner preflight 已完成：

- [2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-object-owner-preflight-decision.md)

该 preflight 使用本 reference pack 的 resource ownership、command queue / command buffer lifecycle、drawable acquisition、render pass / encoder relation、pipeline / draw-call relation、frame pacing 与 no-draw / rollback evidence，判定下一步可以进入 internal-only backend object owner value boundary。

## Downstream Frame Pacing Owner Preflight

Renderer frame pacing owner preflight 已完成：

- [2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-frame-pacing-owner-preflight-decision.md)

该 preflight 使用本 reference pack 的 display refresh、drawable acquisition timing、AppKit resize / backing scale、frame pacing 与 backend object lifecycle evidence，判定下一步可以进入 internal-only frame pacing owner value boundary。Reference pack 仍只是 docs evidence，不是 runtime input；`CVDisplayLink`、`MTKView` draw loop、run loop 与 timer 只能作为 future reference concept，不批准 frame scheduler、display link、render loop、timer、backend / Metal / AppKit implementation、platform object creation、command buffer commit、GPU submission、render execution 或 renderer state write。

Reference pack 仍只是 docs evidence，不是 runtime input，不批准 backend object creation、`MTLDevice` / `CAMetalLayer` creation、command queue、drawable、command buffer、render pass descriptor、encoder、pipeline state、native handle、raw pointer、command buffer commit、GPU submission、render execution、renderer state write 或 public surface expansion。

## 下游 native bridge 写集规划重置

下游 [native bridge write-set planning reset decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-native-bridge-write-set-planning-reset-decision.md) 已完成。该 decision 只把本 reference pack 中的 Metal / AppKit resource order、command queue / drawable / command buffer lifecycle、main-thread / layer evidence 与 failure rollback evidence 作为正式 bridge surface contract 的规划输入。

该 downstream decision 不把 reference pack 升格为 `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue` permission、native bridge permission、C ABI / FFI permission、native handle permission、GPU submission permission、render permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge C ABI surface contract preflight decision`

## 下游 C ABI surface contract 封账

下游 [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-c-abi-surface-contract-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把本 reference pack 中的 resource order、main-thread / layer evidence、failure rollback 与 smoke feasibility 作为 C ABI surface contract evidence，不把 reference pack 升格为 C ABI implementation permission、native bridge implementation permission、native handle permission、`MTLDevice` / `CAMetalLayer` / `MTLCommandQueue` permission、GPU submission permission、render permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native handle token ownership planning preflight decision`

## 下游 native handle token ownership 封账

下游 [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-manifest-stabilization-closure-review.md) 已完成。该 downstream 只把本 reference pack 中的 resource order、main-thread / layer evidence、failure rollback 与 smoke feasibility 作为 token ownership planning evidence，不把 reference pack 升格为 native handle permission、raw pointer permission、native pointer return permission、C ABI implementation permission、FFI permission、native bridge implementation permission、`MTLDevice` / `CAMetalLayer` / `MTLCommandQueue` permission、GPU submission permission、render permission、renderer state write permission、backend-ready permission 或 public API permission。

新的 downstream 后续入口：

`P1 internal Renderer native bridge teardown implementation planning preflight decision`
