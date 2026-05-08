# P1 渲染器绘制调用实现 preflight 决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 draw call implementation runway，但下一步仍只能是 internal value boundary / implementation admission facts，不是真实 draw call implementation。

谨慎选择：

`P1 internal Renderer draw call implementation admission value boundary bundle implementation`

该下一步若实施，仍必须只新增 internal-only value facts，不能发出 draw call，不能调用 `drawPrimitives` / `drawIndexedPrimitives`，不能绑定 vertex / index buffer、texture、sampler、resource 或 pipeline，不能创建 encoder / command buffer，也不能触发 Metal / AppKit / Objective-C / FFI、GPU submission、render、renderer state write 或 public API expansion。

后续若新增 runtime owner，owner 文件必须保留文件头维护注释，并覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。注释只能解释维护边界，不能把 admission facts 写成真实 implementation permission。

## 证据读取

- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`。该 endpoint 只代表 pipeline state implementation intent / shader function admission policy / pipeline descriptor admission policy / pipeline compatibility admission guard / no-pipeline-state-implementation readiness value facts，不批准 pipeline state、shader、pipeline descriptor、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md) 已固定 `CjguiInternalRendererNoDrawCallReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallLifecycleDraft()`，其 truth 只覆盖 draw call lifecycle intent / draw command shape policy / geometry source policy / draw sequencing guard / no-draw-call readiness value facts。该 lifecycle endpoint 是历史 vocabulary evidence，不是本轮下一步的 runtime input permission。
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoEncoderImplementationReadiness` / `cjguiInternalExecuteDefaultRendererEncoderAdmissionDraft()`，并明确不创建 encoder，不调用 `renderCommandEncoder` / `endEncoding`，不绑定 pipeline / buffer / texture / resource，不执行 render / draw call。
- [render pass implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md) 已固定 render pass admission endpoint，并明确不创建 render pass descriptor、attachment、texture、drawable、encoder、pipeline 或 command buffer。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 evidence。它说明 draw calls 通过 render command encoder 发出，且 pipeline state / resources / fixed-function state 在 draw call 前绑定；这只能支撑问题清单和 stop-line，不能升格为 runtime truth、Metal permission 或 implementation permission。
- [GUI 风险账本](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 继续要求渲染结果不能自持 UI truth，GPU / FFI / 平台资源生命周期必须提前定义 owner 和释放路径，不能让 renderer state、platform handle 或 public surface 被 draw path 反向污染。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

允许打开 draw call implementation runway 的理由是：上游 pipeline state implementation admission 已经把 pipeline state、shader、descriptor、pipeline binding 和 compatibility 语义固定为 no-resource / no-binding admission facts；encoder admission 与 render pass admission 也已分别固定不创建真实 encoder、render pass descriptor 或 command buffer。因此 draw call implementation runway 可以继续向“primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation readiness facts”靠近。

但下一步不能直接实现 draw call，也不能把 `CjguiInternalRendererNoPipelineStateImplementationReadiness` 当成 draw-ready permission。唯一合理的下一刀是 internal value boundary：只消费 no-pipeline-state-implementation endpoint，输出 no-draw-call-implementation admission facts，并保持 fail-closed。

本轮没有发现必须先拆成 B / C / D 的证据缺口。primitive kind、vertex count、instance count、geometry source、draw order relation 与 material grouping 已在 lifecycle manifest 中作为 dehydrated evidence 出现；pipeline state admission manifest 也已经将 draw-call compatibility 保持为 guard facts。因此 A 足够窄，且比直接进入 primitive / geometry / ordering 单独 preflight 更能保持当前链路连续。

## 建议的下一步形状

若执行下一步，建议 runtime input candidate 只能是：

- `CjguiInternalRendererNoPipelineStateImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`

建议 canonical endpoint 只能表达：

- draw call implementation intent
- primitive command admission policy
- geometry binding admission guard
- draw ordering admission policy
- no-draw-call-implementation readiness value facts

建议 owner candidate 可以在下一轮确定，名称应保持 internal-only。无论文件名如何，新增 owner 必须有 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，并继续说明 admission facts 不是 draw call permission。

## 候选比较

### 候选 A：谨慎推荐

`P1 internal Renderer draw call implementation admission value boundary bundle implementation`

选择 A。它只允许表达 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness facts；不发出 draw call，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不绑定 vertex / index buffer、texture、sampler、resource 或 pipeline，不调用 Metal / AppKit / Objective-C / FFI。

### 候选 B：暂不选择 primitive command admission preflight

暂不选择。当前 lifecycle evidence 已有 primitive kind、vertex / index source、instance count 与 no-draw fallback 的 dehydrated facts，足以支撑下一步 value boundary；若未来发现 primitive kind / vertex count / instance count 表达不足，再单独 hardening。

### 候选 C：暂不选择 geometry binding admission preflight

暂不选择。当前只能表达 geometry binding admission guard，仍不允许真实 geometry buffer、index source、vertex layout 或 resource binding。若后续需要真实 buffer / layout relation，必须另开 docs-only preflight。

### 候选 D：暂不选择 draw ordering admission preflight

暂不选择。当前 draw sequencing 只能作为 ordering admission policy，不排序、不分组、不做 material batching、不提交 GPU work。若 material grouping 或 state dependency 需要更强表达，再另开 docs-only hardening。

### 候选 E 到 G：暂缓

Resource binding admission preflight、pipeline state admission hardening 与 encoder admission hardening 均暂缓。当前 runway 只需要先固定 no-draw-call-implementation admission facts，不需要靠近真实 resource binding、pipeline binding 或 encoder lifecycle hardening。

### 候选 H 到 R：拒绝

拒绝 direct draw call implementation、direct `drawPrimitives` / `drawIndexedPrimitives`、direct vertex / index buffer binding、direct texture / sampler / resource binding、direct pipeline binding、direct encoder / command buffer implementation、direct Metal / AppKit / Objective-C / FFI implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion，以及 receipt / record / publication。

### 候选 S：仅限明确重复时 consolidation

仅在出现明确 duplicate / self-wrapping evidence 时选择 consolidation。当前 evidence 指向新增 draw call implementation admission 语义，而不是删除、合并或把既有 endpoint 改名包装。

## 同构边界刹车（Same-shape Boundary Brake）

本轮不得把 `CjguiInternalRendererNoPipelineStateImplementationReadiness`、`CjguiInternalRendererNoDrawCallReadiness`、encoder admission endpoint 或 reference evidence 包成：

- draw-call implementation receipt / record / publication
- draw-ready permission wrapper
- primitive-command permission wrapper
- geometry-binding permission wrapper
- resource-binding permission wrapper
- pipeline-binding permission wrapper
- encoder permission wrapper
- native-handle permission wrapper
- C-ABI / FFI permission wrapper
- GPU-submission wrapper
- render-permission wrapper

若下一步执行 A，新增语义必须明确是 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation readiness facts。它不能表达 draw call 可执行、encoder 可调用、pipeline / resource 可绑定、GPU work 可提交、render 可执行、renderer state 可写或 public API 可扩展。

## 停止线

下一步继续保持以下 stop-line：

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

本决策作为以下文档的 downstream：

- [pipeline state implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-pipeline-state-implementation-admission-manifest.md)
- [draw call lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-draw-call-lifecycle-manifest.md)
- [encoder implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-encoder-implementation-admission-manifest.md)

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

## 唯一后续入口

`P1 internal Renderer render execution implementation preflight decision`

## 下游 value boundary closure

Renderer draw call implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj)，只消费 `CjguiInternalRendererNoPipelineStateImplementationReadiness` / `cjguiInternalExecuteDefaultRendererPipelineStateAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。

新增语义是 primitive command admission / geometry binding admission / draw ordering admission / no-draw-call-implementation readiness facts，不是 draw-call implementation receipt / record / publication、draw-ready permission wrapper、primitive-command permission wrapper、geometry-binding permission wrapper、resource-binding permission wrapper、pipeline-binding permission wrapper、GPU-submission wrapper 或 render-permission wrapper。

## 下游 next-boundary decision

Renderer draw call implementation admission next-boundary decision 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 足够作为当前 no-draw-call-implementation endpoint，并选择下一步 docs-only manifest stabilization。

它不把该 endpoint 继续包装成 receipt / record / publication、draw-ready permission wrapper、primitive-command permission wrapper、geometry-binding permission wrapper、resource-binding permission wrapper、pipeline-binding permission wrapper、GPU-submission wrapper、render-permission wrapper 或 renderer-state-write wrapper。下一步只能固定 owner / truth / canonical endpoint / default draft / runtime input / stop-line。

## 下游 manifest stabilization

Renderer draw call implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-draw-call-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 [runtime_renderer_draw_call_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_draw_call_admission.cj) owner / truth / canonical endpoint / default draft / runtime input / stop-line。`CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 仍只代表 no-draw-call-implementation readiness value facts，不是 draw call、primitive command、geometry / resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。

新的唯一后续入口是 docs-only `P1 internal Renderer render execution implementation preflight decision`。下一步只能评估 render execution implementation runway，不批准真实 draw call、resource binding、pipeline binding、GPU submission、render 或 renderer state write。
