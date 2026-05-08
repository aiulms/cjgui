# P1 渲染器绘制调用实现准入后续边界决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 决策结论

确认 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 足够作为当前 no-draw-call-implementation endpoint。

该 endpoint 只代表 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts。它不是 draw call permission、`drawPrimitives` / `drawIndexedPrimitives` permission、geometry / resource binding permission、pipeline binding permission、encoder permission、command buffer permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮选择下一步：

`P1 internal Renderer draw call implementation admission manifest stabilization bundle implementation`

下一步仍必须 docs-only，只能固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line，不得继续新增 tail wrapper，不得靠近真实 draw call、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API。

## 读取依据

- [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj) 已形成完整 value chain：`CjguiInternalRendererNoPipelineStateImplementationReadiness` -> `CjguiInternalRendererDrawCallImplementationIntent` -> `CjguiInternalRendererPrimitiveCommandAdmissionPolicy` -> `CjguiInternalRendererGeometryBindingAdmissionGuard` -> `CjguiInternalRendererDrawOrderingAdmissionPolicy` -> `CjguiInternalRendererNoDrawCallImplementationReadiness`。
- [draw call implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md) 已记录新增 owner、GitNexus impact、build / smoke 证据、stop-line scan、文件头维护注释与 forbidden checks。
- [draw call implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md) 已选择 value boundary implementation，并明确下一刀只允许 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation facts。
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md) 固定上游 no-pipeline-state-implementation endpoint；它不是 draw-ready permission，也不批准 pipeline state、shader、descriptor、pipeline binding、encoder、command buffer、GPU submission、render 或 renderer state write。
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md) 只提供 draw command shape / geometry source / sequencing vocabulary evidence。`CjguiInternalRendererNoDrawCallReadiness` 不是本 endpoint 的 runtime input，也不是 draw call implementation permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续要求 Markdown 中文正文和中文标题；后续新增 runtime owner 文件仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## endpoint 充分性判断

`cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 的 runtime input 只来自 `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`，没有读取 renderer state、platform object、native handle、bridge、Metal / AppKit / Objective-C / FFI 或外部资源。

Open path 已能形成 dehydrated admission facts：implementation intent、primitive command admission、geometry binding admission、draw ordering admission 与 no-draw-call-implementation readiness。Defer-only path 保持 defer；blocked / inconsistent path fail-closed，并保留 no draw command、no primitive invocation、no geometry resource、no pipeline use、no encoder object、no command buffer object、no GPU work、no render execution 与 no renderer state mutation facts。

因此当前 endpoint 已足够进入 manifest stabilization。继续包装成 draw-ready、primitive-command、geometry-binding、resource-binding、pipeline-binding、GPU-submission、render-permission 或 receipt / record / publication wrapper 会重复同一 tail，没有新增 owner truth。

## 候选比较

### 候选 A：推荐 manifest stabilization

选择 `P1 internal Renderer draw call implementation admission manifest stabilization bundle implementation`。

理由：当前 owner、truth、runtime input、canonical endpoint、default draft、fail-closed 行为、defer-only 行为与 stop-line 已经清楚。下一步只需要 docs-only 固定，不需要再新增 runtime owner 或 value wrapper。

### 候选 B：暂缓 resource binding admission preflight

暂缓。当前 `GeometryBindingAdmissionGuard` 只表达 geometry / resource placeholder admission facts，不保存 resource token，不批准 vertex / index buffer、texture、sampler 或 resource binding。真实 resource binding 需要另行 docs-only preflight。

### 候选 C：暂缓 draw ordering admission hardening

暂缓。当前 ordering admission 已表达 draw order、material grouping 与 state dependency facts，但不排序、不 batching、不提交 GPU work。只有发现 ordering 表达不足时才进入 hardening。

### 候选 D：暂缓 geometry binding admission hardening

暂缓。当前 geometry binding admission guard 已足够支撑 no-draw-call-implementation endpoint。真实 geometry buffer、index source 或 vertex layout relation 仍需另开 docs-only preflight。

### 候选 E：暂缓 pipeline state admission hardening

暂缓。Pipeline state implementation admission manifest 已固定 no-pipeline-state-implementation facts；本轮不回头硬化 pipeline state admission。

### 候选 F 到 U：拒绝

拒绝 draw-call receipt / record / publication、draw-ready permission wrapper、primitive-command permission wrapper、geometry-binding permission wrapper、resource-binding permission wrapper、pipeline-binding permission wrapper、encoder / command-buffer permission wrapper、GPU-submission wrapper、render-permission wrapper、direct draw call implementation、direct `drawPrimitives` / `drawIndexedPrimitives`、direct vertex / index buffer binding、direct texture / sampler / resource binding、direct Metal / AppKit / Objective-C / FFI implementation、renderer state write、public API / C ABI expansion。

### 候选 V：仅限明确重复时 consolidation

当前没有 duplicate / self-wrapping evidence。若未来发现重复 owner 或 tail wrapper，再单独 docs-only consolidation。

## 同构边界刹车（Same-shape Boundary Brake）

`CjguiInternalRendererNoDrawCallImplementationReadiness` 不得继续包装成：

- receipt / record / publication
- draw-ready permission wrapper
- primitive-command permission wrapper
- geometry-binding permission wrapper
- resource-binding permission wrapper
- pipeline-binding permission wrapper
- encoder permission wrapper
- command-buffer permission wrapper
- native-handle permission wrapper
- C-ABI / FFI permission wrapper
- GPU-submission wrapper
- render-permission wrapper
- renderer-state-write wrapper

下一步若选择 manifest stabilization，只能固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line。不得新增 backend permission、resource permission、render permission 或 public surface。

## 停止线

下一步继续保持：

- no draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no vertex / index buffer binding
- no texture / sampler / resource binding
- no pipeline binding
- no pipeline state / shader / descriptor creation
- no encoder creation
- no `renderCommandEncoder`
- no `endEncoding`
- no command buffer
- no `commandBuffer`
- no `commit`
- no drawable acquisition
- no `nextDrawable`
- no `present`
- no native handle
- no raw pointer
- no C ABI
- no FFI declaration
- no bridge call
- no retain / release / destroy
- no Metal / AppKit / Objective-C
- no GPU submission
- no render
- no renderer state write
- no public API

## 文档同步

本 decision 作为以下文档的 downstream：

- [draw call implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-preflight-decision.md)
- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

## 验证记录

本轮必须验证：

- `git diff --check`
- 新 decision no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与中文正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

本轮 docs-only，不运行 `cjpm build` / smoke，不修改 `.cj`。

## 唯一后续入口

`P1 internal Renderer render execution implementation preflight decision`

## 下游 manifest stabilization

Renderer draw call implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 只固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line，不新增 tail wrapper。它继续确认 `CjguiInternalRendererNoDrawCallImplementationReadiness` 不是 draw-ready、primitive-command、geometry-binding、resource-binding、pipeline-binding、GPU-submission、render-permission、renderer-state-write wrapper 或 receipt / record / publication。
