# P1 渲染器渲染执行实现准入 manifest 封账

日期：2026-05-06

状态：docs-only manifest stabilization

## 封账结论

本 manifest 固定 [runtime_renderer_render_execution_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj) 的 owner、truth、canonical endpoint、default draft、runtime input、stop-line 与 Same-shape Boundary Brake。

本轮只做文档封账：不修改任何 `.cj`，不新建 runtime owner，不运行 `cjpm build` / smoke，不触碰 protected paths。

本 manifest 不批准执行 render，不批准提交 GPU work，不批准调用 `commit`、`present` 或 `nextDrawable`，不批准创建或提交 command buffer，不批准创建 encoder，不批准调用 `renderCommandEncoder` 或 `endEncoding`，不批准发出 draw call，不批准绑定 pipeline / buffer / texture / sampler / resource，不批准创建 native handle / raw pointer，不批准 C ABI / FFI declaration，不批准 bridge call、retain / release / destroy，不批准 Metal / AppKit / Objective-C / FFI，不批准 renderer state write，也不批准 public API expansion。

## 固定 owner

Owner 文件：

- [runtime_renderer_render_execution_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj)

Runtime input 固定为：

- 输入类型：`CjguiInternalRendererNoDrawCallImplementationReadiness`
- 输入 draft：`cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`

Canonical endpoint 固定为：

- endpoint 类型：`CjguiInternalRendererNoRenderExecutionImplementationReadiness`
- endpoint draft：`cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`

Default draft 固定为：

- `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()`

Default draft 只从 `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()` 获取 `CjguiInternalRendererNoDrawCallImplementationReadiness`，再构造 render execution implementation intent、execution admission policy、completion observation admission guard、rollback admission policy 与 no-render-execution-implementation readiness value facts。它不执行 render，不提交 GPU work，不创建或提交 command buffer，不创建 encoder，不发出 draw call，不绑定 resource，不写 renderer state。

## 当前 truth

Current truth 仅限：

- 记录 render execution implementation intent value facts。
- 记录 execution admission policy value facts。
- 记录 completion observation admission guard value facts。
- 记录 rollback admission policy value facts。
- 记录 no-render-execution-implementation readiness value facts。

Canonical value chain 固定为：

1. 上游输入：`CjguiInternalRendererNoDrawCallImplementationReadiness`
2. 意图事实：`CjguiInternalRendererRenderExecutionImplementationIntent`
3. execution 准入事实：`CjguiInternalRendererExecutionAdmissionPolicy`
4. completion observation 准入事实：`CjguiInternalRendererCompletionObservationAdmissionGuard`
5. rollback 准入事实：`CjguiInternalRendererRollbackAdmissionPolicy`
6. 封账 endpoint：`CjguiInternalRendererNoRenderExecutionImplementationReadiness`

Open path 只能形成 dehydrated admission facts；defer-only 保持 defer；blocked / inconsistent path 必须 fail-closed，并保留 no render execution、no GPU work、no command object work、no encoder object、no draw command、no pipeline use、no resource binding、no foreign declaration / invocation、no external handle、no pointer resource、no render state mutation 与 no publication facts。

## 值语义

`CjguiInternalRendererRenderExecutionImplementationIntent` 只记录未来 render execution implementation intent，以及 execution admission、completion observation admission 与 rollback admission 的需要。它不是 render-ready permission、command submission permission、GPU submission permission、renderer state write permission 或 public API permission。

`CjguiInternalRendererExecutionAdmissionPolicy` 只记录 execution admission value facts。`ExecutionAdmissionPolicy` 不执行 render，不提交 GPU work，不创建或提交 command buffer。

`CjguiInternalRendererCompletionObservationAdmissionGuard` 只记录 completion / failure observation admission facts。`CompletionObservationAdmissionGuard` 不注册 callback，不观察真实 GPU completion，不发布 telemetry、diagnostics 或 external artifact。

`CjguiInternalRendererRollbackAdmissionPolicy` 只记录 rollback admission、failure containment 与 no-draw fallback value facts。`RollbackAdmissionPolicy` 不写 renderer state，不发布 external artifact，不执行 rollback callback。

`CjguiInternalRendererNoRenderExecutionImplementationReadiness` 是当前 no-render-execution-implementation endpoint。`NoRenderExecutionImplementationReadiness` 不是 render permission、GPU submission permission、command submission permission、presentation permission、completion callback permission、renderer state write permission 或 public API permission。

## 关系事实

Render execution implementation admission facts 只把上游 no-draw-call-implementation endpoint 作为 runtime input：

- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md) 固定 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`，但不授予 render、GPU submission、command submission、presentation、completion callback、renderer state write 或 public API permission。
- [render execution implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-preflight-decision.md) 已把 runway 限定为 admission value boundary，不是真实 render execution。
- [render execution implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-value-boundary-closure-review.md) 已记录 owner、新增 internal symbols、GitNexus impact、build / smoke 兜底与 stop-line scan。
- [render execution implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 足够作为当前 endpoint，不需要继续包装 tail wrapper。
- [render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 只提供 no-render-execution lifecycle evidence；`CjguiInternalRendererNoRenderExecutionReadiness` 不是本 owner 的 runtime input，也不是 implementation permission。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) 只提供 no-gpu-submission evidence；`CjguiInternalRendererNoGpuSubmissionReadiness` 不是本 owner 的 runtime input，也不是 `commit`、`present`、GPU submission 或 render permission。
- 后续 real command buffer first-slice macro 已新增 `CjguiInternalRendererNoRealCommandBufferShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferShellDraft()`，但它只表达 shell / denial / teardown / failure classification facts，不改变本 render execution implementation admission endpoint，也不授权 command buffer creation、`commandBuffer`、`commit`、render pass、encoder、GPU submission、render execution、renderer state write 或 public API。
- 后续 real render pass first-slice macro 已新增 `CjguiInternalRendererNoRealRenderPassShellReadiness` / `cjguiInternalExecuteDefaultRendererRealRenderPassShellDraft()`，但它只表达 render pass shell / descriptor admission shell / attachment denial / encoder denial / teardown failure classification facts，不改变本 render execution implementation admission endpoint，也不授权 render pass descriptor creation、attachment / texture view、`renderCommandEncoder`、`endEncoding`、encoder、GPU submission、render execution、renderer state write 或 public API。

## 明确的非 truth

`CjguiInternalRendererNoRenderExecutionImplementationReadiness` 不是：

- 不是 render permission。
- 不是 render execution permission。
- 不是 GPU submission permission。
- 不是 command submission permission。
- 不是 command buffer creation permission。
- 不是 command buffer submission permission。
- 不是 `commit` permission。
- 不是 presentation permission。
- 不是 `present` permission。
- 不是 drawable acquisition permission。
- 不是 `nextDrawable` permission。
- 不是 completion callback permission。
- 不是 completion observation implementation permission。
- 不是 encoder permission。
- 不是 `renderCommandEncoder` permission。
- 不是 `endEncoding` permission。
- 不是 draw call permission。
- 不是 pipeline binding permission。
- 不是 buffer / texture / sampler / resource binding permission。
- 不是 native handle permission。
- 不是 raw pointer permission。
- 不是 C ABI permission。
- 不是 FFI permission。
- 不是 bridge call permission。
- 不是 Metal / AppKit / Objective-C permission。
- 不是 renderer state write permission。
- 不是 public API permission。

当前 truth 没有 render work，没有 GPU work，没有 command buffer object，没有 command submission，没有 drawable acquisition 或 presentation，没有 encoder，没有 draw command，没有 pipeline use，没有 resource binding，没有 completion callback，没有 rollback callback，没有 renderer state mutation，没有 native handle / raw pointer，没有 C ABI / FFI declaration，没有 bridge call，也没有外部 publication。

## 同构边界刹车

本轮只做 manifest 封账，不新增 tail wrapper。明确拒绝：

- 拒绝 render-execution implementation receipt / record / publication。
- 拒绝 render-ready permission wrapper。
- 拒绝 completion permission wrapper。
- 拒绝 command-submission permission wrapper。
- 拒绝 presentation permission wrapper。
- 拒绝 GPU-submission wrapper。
- 拒绝 renderer-state-write wrapper。
- 拒绝 native-handle permission wrapper。
- 拒绝 C-ABI / FFI permission wrapper。
- 拒绝 public API wrapper。

`CjguiInternalRendererNoRenderExecutionImplementationReadiness` 不得继续包装成新的 tail wrapper。未来靠近 renderer state write implementation、completion observation hardening、command submission / presentation hardening、真实 render execution、command buffer commit、GPU submission、drawable present / acquisition、encoder / draw call / resource binding、Metal / AppKit / Objective-C / FFI 或 public API / C ABI expansion，必须先通过 docs-only preflight。

## 停止线

在后续 docs-only preflight 明确打开更窄 runway 前：

- 不修改 `.cj`。
- 不新建 runtime owner。
- 不运行 `cjpm build` / smoke。
- 不触碰 protected paths。
- 不执行 render。
- 不提交 GPU work。
- 不调用 `commit`。
- 不调用 `present`。
- 不调用 `nextDrawable`。
- 不创建或提交 command buffer。
- 不创建 encoder。
- 不调用 `renderCommandEncoder`。
- 不调用 `endEncoding`。
- 不发出 draw call。
- 不调用 `drawPrimitives`。
- 不调用 `drawIndexedPrimitives`。
- 不绑定 pipeline。
- 不绑定 buffer。
- 不绑定 texture。
- 不绑定 sampler。
- 不绑定 resource。
- 不创建 native handle。
- 不创建 raw pointer。
- 不新增 C ABI。
- 不新增 FFI declaration。
- 不调用 bridge。
- 不调用 retain / release / destroy。
- 不调用 Metal / AppKit / Objective-C / FFI。
- 不写 renderer state。
- 不扩 public API。

## 公共 surface

Public declaration allowlist 仍保持：

- `cjguiExperimentalQueueSubmitShellReady(): Bool`

本 manifest 不批准第二个 public symbol，不修改 Bool-only signature，不新增 public C ABI，不接 diagnostics / event bus / observer / telemetry 或 public API。

## 下一阶段候选

### 候选 A：推荐

`P1 internal Renderer renderer state write implementation preflight decision`

推荐 A。理由是 render execution implementation admission 已封账为 no-render-execution-implementation endpoint，下一刀可以 docs-only 评估 renderer state write implementation runway，但仍不得写 renderer state，不得记录 frame completion，不得发布 diagnostics，不得绑定 callback，也不得把 render execution admission endpoint 解释成 state mutation permission。

### 候选 B 到 D：暂缓

completion observation hardening、command submission / presentation hardening、render execution admission hardening 均暂缓。当前 manifest 已固定 no callback、no command submission、no presentation、no render execution、no GPU work 与 no state mutation facts；只有未来 review 发现表达不足时才选择 hardening。

### 候选 E 到 K：拒绝

拒绝 direct render execution implementation、direct command buffer commit / GPU submission、direct drawable present / acquisition、direct encoder / draw call / resource binding、direct Metal / AppKit / Objective-C / FFI implementation、public API / C ABI expansion、receipt / record / publication。

### 候选 L：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向下一步 renderer state write implementation preflight，而不是删除、合并或继续包装当前 endpoint。

## 下游设计意图导航

plans 设计意图导航已同步，后续追踪 render execution 到 renderer state write 的 implementation admission 链时，可先读取：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)

该导航只追加历史设计意图入口，不改变本 manifest 的 owner / truth / stop-line 或当前后续入口。

## 下游 state write implementation 预检

Renderer state write implementation preflight 已完成：

- [2026-05-06-p1-renderer-state-write-implementation-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-preflight-decision.md)

该 downstream 只把本 manifest 固定的 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 作为下一步 value boundary 的 runtime input candidate。它不改变本 manifest 的 no-render-execution-implementation endpoint，不批准 render、GPU submission、command submission、presentation、completion callback、renderer state write、public diagnostics 或 public API。

## 下游 state write implementation 取值边界

Renderer state write implementation admission value boundary 已完成：

- [2026-05-06-p1-internal-renderer-state-write-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-state-write-implementation-admission-value-boundary-closure-review.md)

该 downstream 只把本 manifest 固定的 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 作为 runtime input，新增 no-renderer-state-write-implementation admission facts。它不改变本 manifest 的 no-render-execution-implementation endpoint，不批准 render、GPU submission、command submission、presentation、completion callback、renderer state write、public diagnostics 或 public API。

## 下游 state write implementation 后续决策

Renderer state write implementation admission closure / next decision 已完成：

- [2026-05-06-p1-renderer-state-write-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-next-boundary-decision.md)

该 downstream 只确认 state write admission endpoint 足够封账，并把下一步指向 manifest stabilization。它不改变本 manifest 的 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 结论，不批准 render、GPU submission、command submission、presentation、completion callback、renderer state write、public diagnostics 或 public API。

## 下游 state write implementation manifest 封账

Renderer state write implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-state-write-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-state-write-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-state-write-implementation-admission-manifest-stabilization-closure-review.md)

该 downstream 只把本 manifest 固定的 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 作为 runtime input evidence，并固定 no-renderer-state-write-implementation endpoint。它不改变本 manifest 的 no-render-execution-implementation 结论，不批准 render、GPU submission、command submission、presentation、completion callback、renderer state write、public diagnostics 或 public API。

## 验证记录

本轮 docs-only 封账必须验证：

- `git diff --check`
- 新 manifest / closure no-index whitespace check
- Markdown absolute link missing target check，限定 project docs scope，避开 `reference_repos/`
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability
- Markdown 中文标题与正文抽查
- forbidden check：确认无 tracked `.cj` diff、无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`
- comment-aware public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`

## 唯一后续入口

`P1 internal Renderer renderer state write implementation preflight decision`
