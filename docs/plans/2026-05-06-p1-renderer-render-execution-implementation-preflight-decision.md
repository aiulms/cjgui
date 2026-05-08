# P1 渲染器渲染执行实现预检决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 render execution implementation runway，但下一步仍只能是 internal value boundary / implementation admission facts，不是真实 render execution。

谨慎选择：

`P1 internal Renderer render execution implementation admission value boundary bundle implementation`

下一步若实施，仍必须只表达 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness facts。它不执行 render，不提交 GPU work，不调用 `commit` / `present` / `nextDrawable`，不创建或提交 command buffer，不创建 encoder，不调用 Metal / AppKit / Objective-C / FFI，不写 renderer state，不扩 public API。

后续若新增 runtime owner，owner 文件必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。注释只能解释维护边界，不能把 admission facts 写成真实 implementation permission。

## 证据读取

- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`。该 endpoint 只代表 draw call implementation intent / primitive command admission policy / geometry binding admission guard / draw ordering admission policy / no-draw-call-implementation readiness value facts，不批准 draw call、primitive command、resource binding、pipeline binding、encoder、command buffer、GPU submission、render、renderer state write 或 public API permission。
- [render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md) 已固定 `CjguiInternalRendererNoRenderExecutionReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionNoOpDraft()`，其 truth 只覆盖 render execution intent / execution ordering policy / no-submit guard / completion observation policy / no-render-execution readiness value facts。它是旧 no-op lifecycle evidence，不是本轮 implementation admission permission。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) 已固定 `CjguiInternalRendererNoGpuSubmissionReadiness` / `cjguiInternalExecuteDefaultRendererCommandSubmissionDraft()`，只表达 command submission intent / command buffer commit policy / drawable presentation gate / GPU submission failure policy / no-gpu-submission readiness value facts，不批准 `commit`、`present`、`nextDrawable`、GPU submission、render 或 renderer state write。
- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`，不创建 command buffer，不调用 `commandBuffer` 或 `commit`，不注册 completion callback，不观察真实 GPU completion。
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`，不获取 drawable，不调用 `nextDrawable` 或 `present`，不创建 command buffer，不提交 GPU work。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 evidence。它说明 command buffer、encoder、draw call、drawable presentation 和 completion observation 的真实 Metal 关系，但不能升格为 runtime truth、Metal permission、backend implementation permission 或 render execution permission。
- [GUI 风险账本](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 继续要求 GPU / FFI / 平台资源生命周期提前定义 owner，渲染结果不能自持 UI truth，后台或平台回调不得直接写 GUI 资源。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

允许打开 render execution implementation runway 的理由是：draw call implementation admission 已封账为 no-draw-call-implementation endpoint，且上游 command buffer / drawable / command submission / render execution no-op 证据已经把 `commit`、`present`、`nextDrawable`、command buffer、encoder、GPU submission、render、completion observation 与 rollback 关系全部限定为 value facts 或 reference evidence。

下一步仍不能直接执行 render。它也不能把 `CjguiInternalRendererNoDrawCallImplementationReadiness`、旧 `CjguiInternalRendererNoRenderExecutionReadiness`、`CjguiInternalRendererNoGpuSubmissionReadiness`、command buffer / drawable admission endpoint 或 reference evidence 包成 render-ready permission。唯一合理的下一刀是 internal value boundary：只消费 no-draw-call-implementation endpoint，输出 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness facts，并保持 fail-closed。

本轮没有发现必须先拆成 B / C / D 的证据缺口。Completion observation、command submission / commit / present relation、drawable presentation ownership 与 failure rollback 均已有 no-op / no-submit / admission manifest evidence；这些 evidence 足够支撑 value boundary，但仍不足以批准 callback、commit、present、GPU submission、render 或 renderer state write。

## 建议的下一步形状

若执行下一步，建议 runtime input candidate 只能是：

- `CjguiInternalRendererNoDrawCallImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`

建议 canonical endpoint 只能表达：

- render execution implementation intent
- execution admission policy
- completion observation admission guard
- rollback admission policy
- no-render-execution-implementation readiness facts

建议 owner candidate 可以在下一轮确定。无论文件名如何，新增 owner 必须有 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，并继续说明 admission facts 不是 render execution permission。

## 候选比较

### 候选 A：谨慎推荐

`P1 internal Renderer render execution implementation admission value boundary bundle implementation`

选择 A。它只允许表达 render execution implementation intent / execution admission policy / completion observation admission guard / rollback admission policy / no-render-execution-implementation readiness facts；不执行 render，不提交 GPU work，不调用 `commit` / `present` / `nextDrawable`，不创建或提交 command buffer，不创建 encoder，不调用 Metal / AppKit / Objective-C / FFI。

### 候选 B：暂不选择 render completion admission preflight

暂不选择。Completion observation / callback / failure facts 在 render execution no-op、command submission 与 real command buffer admission 中已有 no-callback / no-real-completion / failure policy evidence。若未来要靠近真实 completion callback、telemetry、event bus 或 renderer state visibility，必须另开 docs-only preflight。

### 候选 C：暂不选择 command submission admission hardening

暂不选择。Command submission manifest 已表达 no-commit / no-present / no-submit / failure policy facts，足以支撑下一步 value boundary。若未来发现 commit / present relation 表达不足，再单独 hardening。

### 候选 D：暂不选择 presentation admission hardening

暂不选择。Real drawable admission 与 command submission manifest 已固定 no `nextDrawable`、no `present`、no drawable token 与 no command buffer facts。真实 drawable ownership / presentation ownership 仍需后续 docs-only preflight 才能靠近。

### 候选 E 到 G：暂缓

Renderer state write implementation preflight、backend shell implementation hardening 与 frame pacing integration preflight 均暂缓。当前 runway 只收束 no-render-execution-implementation admission facts，不靠近 state mutation、backend object、frame scheduler、display link 或 render loop。

### 候选 H 到 O：拒绝

拒绝 direct render execution implementation、direct command buffer commit / GPU submission、direct drawable present / acquisition、direct encoder / draw call / resource binding implementation、direct Metal / AppKit / Objective-C / FFI implementation、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 P：仅限明确重复时 consolidation

仅在出现明确 duplicate / self-wrapping evidence 时选择 consolidation。当前 evidence 指向新增 render execution implementation admission 语义，而不是删除、合并或把既有 endpoint 改名包装。

## 同构边界刹车（Same-shape Boundary Brake）

本轮不得把 `CjguiInternalRendererNoDrawCallImplementationReadiness`、`CjguiInternalRendererNoRenderExecutionReadiness`、`CjguiInternalRendererNoGpuSubmissionReadiness`、command buffer / drawable admission endpoint 或 reference evidence 包成：

- render-execution implementation receipt / record / publication
- render-ready permission wrapper
- completion permission wrapper
- command-submission permission wrapper
- presentation permission wrapper
- GPU-submission wrapper
- renderer-state-write wrapper
- native-handle permission wrapper
- C-ABI / FFI permission wrapper
- public API wrapper

若下一步执行 A，新增语义必须明确是 execution admission / completion observation admission / rollback admission / no-render-execution-implementation readiness facts。它不能表达 render 可执行、command buffer 可提交、drawable 可 present、GPU work 可提交、renderer state 可写或 public API 可扩展。

## 停止线

下一步继续保持以下 stop-line：

- no render execution
- no GPU submission
- no `commit`
- no `present`
- no `nextDrawable`
- no command buffer creation / submission
- no encoder creation
- no `renderCommandEncoder`
- no `endEncoding`
- no draw call
- no `drawPrimitives`
- no `drawIndexedPrimitives`
- no pipeline / buffer / texture / sampler / resource binding
- no native handle
- no raw pointer
- no C ABI
- no FFI declaration
- no bridge call
- no retain / release / destroy
- no Metal / AppKit / Objective-C
- no renderer state write
- no public API

## 文档同步

本决策作为以下文档的 downstream：

- [draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [render execution no-op manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-render-execution-no-op-manifest.md)
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md)

同步入口：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

## 下游实现收口

本决策的 implementation admission value boundary 已完成：

- [render execution implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-value-boundary-closure-review.md)
- [runtime owner](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_execution_admission.cj)
- [render execution implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-next-boundary-decision.md)
- [render execution implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-admission-manifest.md)
- [render execution implementation admission manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-manifest-stabilization-closure-review.md)

该 closure 新增 `CjguiInternalRendererRenderExecutionImplementationIntent`、`CjguiInternalRendererExecutionAdmissionPolicy`、`CjguiInternalRendererCompletionObservationAdmissionGuard`、`CjguiInternalRendererRollbackAdmissionPolicy` 与 `CjguiInternalRendererNoRenderExecutionImplementationReadiness`。它只消费 `CjguiInternalRendererNoDrawCallImplementationReadiness` / `cjguiInternalExecuteDefaultRendererDrawCallAdmissionDraft()`，不执行 render，不提交 GPU work，不调用 `commit` / `present` / `nextDrawable`，不创建或提交 command buffer，不创建 encoder，不发出 draw call，不绑定 resource，不写 renderer state，不扩 public API。

下游 closure / next decision 已确认 `CjguiInternalRendererNoRenderExecutionImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderExecutionAdmissionDraft()` 足够作为当前 no-render-execution-implementation endpoint。当前唯一后续入口转为 docs-only manifest stabilization，只固定 owner / truth / canonical endpoint / stop-line，不继续包装成 render-ready、completion、command-submission、presentation、GPU-submission、renderer-state-write、public API wrapper 或 receipt / record / publication。

下游 manifest stabilization 已完成，固定 `runtime/cjgui/src/runtime_renderer_render_execution_admission.cj` 的 owner / truth / canonical endpoint / default draft / runtime input / stop-line。当前唯一后续入口转为 docs-only renderer state write implementation preflight；该后续入口仍不批准 renderer state write、completion callback、render、GPU submission、command submission、presentation 或 public API。

## 下游设计意图导航

本轮之后已建立 plans 设计意图导航：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [Renderer implementation admission chain topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)

该导航只用于定位历史设计意图，不改变本 decision 的技术结论或唯一后续入口。

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

`P1 internal Renderer renderer state write implementation preflight decision`
