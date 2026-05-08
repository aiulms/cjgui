# P1 Renderer 真实 command buffer implementation preflight 决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 real command buffer implementation runway，但不批准真实 command buffer creation、`commandBuffer` call、`commit`、render pass / encoder / pipeline state、drawable acquisition / present、native handle、C ABI、FFI declaration、bridge call、Metal / AppKit / Objective-C / FFI call、GPU submission、render execution、renderer state write 或 public API expansion。

下一步选择：

`P1 internal Renderer real command buffer implementation admission value boundary bundle implementation`

该下一步仍必须是 internal value boundary / implementation admission facts，不是真实 command buffer implementation。默认候选 owner 可以是 `runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj`；若未来新增该 `.cj` owner file，必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 证据读取

- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`，作为 no-real-drawable-implementation endpoint；它不是 command buffer permission、`nextDrawable` permission、present permission、GPU submission permission、render permission 或 public API permission。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 已固定 no-real-command-queue-implementation endpoint，并明确不授予 command buffer、GPU submission、render 或 public API permission。
- [command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 已提供 command buffer lifecycle intent、creation policy、commit timing guard、single-use policy 与 no-command-buffer readiness 词汇；它不是 implementation manifest，也不授予 command buffer creation 或 commit permission。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) 已提供 command buffer commit policy、drawable presentation gate、GPU submission failure policy 与 no-gpu-submission vocabulary，但它仍是 no-submit endpoint，不批准 `commit`、`present`、`nextDrawable`、GPU submission 或 render。
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 只作为 drawable lifecycle vocabulary evidence；`CjguiInternalRendererNoRealDrawableReadiness` 不是下一步 runtime input。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 docs evidence：command buffer 由 command queue 创建、承载 encoded commands、commit 后不可复用，completion / failure 与 resource retention policy 属于 future backend owner。该 reference pack 不能升格为 runtime truth。
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 要求任何手动 GPU / native object 在实现前先明确 ownership、teardown、failure、FFI 边界与自动化验证策略。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner file 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

证据足以打开 real command buffer implementation runway，但只能以 value-only implementation admission boundary 进入。

本轮不需要先拆成更窄的 command buffer creation admission、single-use token、commit admission、completion / failure policy 或 drawable relation hardening，因为现有 evidence 已经冻结足够词汇：

- real drawable implementation admission manifest 已提供上游 no-real-drawable-implementation endpoint，并明确不授予 command buffer permission。
- command buffer lifecycle manifest 已提供 creation policy、commit timing guard、single-use policy 和 no-command-buffer readiness vocabulary。
- command submission manifest 已提供 commit ordering、presentation gate、failure policy 与 no-submit vocabulary，但不授权真实提交。
- Metal reference pack 已确认 command buffer lifecycle、commit 后不可复用、completion / failure 与 resource retention concerns 是 future backend owner 的前置问题。
- risk ledger 已要求 GPU / native object lifecycle 在实现前先完成 ownership / teardown / failure / FFI 边界登记。

下一步 value boundary 的唯一 runtime input 建议只消费：

- `CjguiInternalRendererNoRealDrawableImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`

`CjguiInternalRendererNoRealCommandQueueImplementationReadiness`、`CjguiInternalRendererNoCommandBufferReadiness`、command submission facts、real drawable lifecycle facts、reference pack 与 risk ledger 只能作为 docs evidence，不能成为额外 runtime input。

下一步 output truth 必须限定为：

- real command buffer implementation intent。
- command buffer creation admission policy。
- single-use admission guard。
- command buffer failure policy。
- no-real-command-buffer-implementation readiness value facts。

## 候选比较

### 候选 A：谨慎推荐 admission value boundary

推荐：

`P1 internal Renderer real command buffer implementation admission value boundary bundle implementation`

理由：这是下一刀最窄且有用的 implementation-admission 切口。它新增 command buffer creation admission、single-use admission、failure policy 与 no-real-command-buffer-implementation readiness 语义，但不创建 command buffer，不调用 `commandBuffer`，不调用 `commit`，不创建 render pass / encoder / pipeline state，不获取 drawable，不调用 `nextDrawable` / `present`，不新增 native handle、FFI declaration 或 C ABI。

### 候选 B：备选 creation admission preflight

暂不选择。Command queue relation / creation owner evidence 已足够支撑 value-only admission boundary；real command queue implementation admission manifest 已提供 no-real-command-queue-implementation endpoint，Metal reference pack 已确认 command buffer creation 属于 future backend owner，不是当前 runtime truth。

### 候选 C：备选 single-use token preflight

暂不选择。Command buffer lifecycle manifest 已记录 single-use / post-commit invalidation vocabulary，Metal reference pack 已确认 command buffer commit 后不可复用；下一步 value boundary 可以先表达 single-use admission guard，而不是引入真实 token 或 resource identity。

### 候选 D：备选 completion failure preflight

暂不选择。Command submission manifest 和 Metal reference pack 已提供 completion / failure / rollback vocabulary；下一步 value boundary 可以表达 command buffer failure policy，但不得注册 completion callback、不得观察真实 GPU completion、不得写 renderer state。

### 候选 E：暂缓 render pass implementation preflight

暂缓。Render pass implementation 必须晚于 real command buffer implementation admission manifest；当前 no-real-command-buffer-implementation endpoint 尚未建立。

### 候选 F：暂缓 encoder implementation preflight

暂缓。Encoder implementation 更靠近 command encoding、pipeline binding 与 draw calls，必须晚于 command buffer implementation admission 和 render pass implementation admission。

### 候选 G：暂缓 command submission / GPU submission hardening

暂缓。Command submission manifest 已封住 no-gpu-submission endpoint；当前更窄的前置风险是 command buffer implementation admission，不是提交硬化。

### 候选 H 到 S：拒绝直接实现或发布

拒绝 direct command buffer creation implementation、direct `commandBuffer` call、direct `commit` implementation、direct render pass / encoder / pipeline implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 T：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 显示下一步会新增 command buffer creation admission / single-use admission / failure policy / no-real-command-buffer-implementation 语义，不是低价值重复层。

## 同构边界刹车（Same-shape Boundary Brake）

下一步不得把 `CjguiInternalRendererNoRealDrawableImplementationReadiness`、`CjguiInternalRendererNoRealCommandQueueImplementationReadiness`、`CjguiInternalRendererNoCommandBufferReadiness` 或 reference evidence 包成：

- real command buffer implementation receipt / record / publication。
- command-buffer-ready permission wrapper。
- `commandBuffer` permission wrapper。
- `commit` permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一步推进 value boundary，必须新增的是 command buffer creation admission、single-use admission、failure policy 与 no-real-command-buffer-implementation readiness 语义，而不是 no-real-drawable-implementation tail wrapper。

## 停止线

本决策不批准：

- command buffer creation。
- 调用 `commandBuffer`。
- 调用 `commit`。
- 创建 render pass / encoder / pipeline state。
- drawable acquisition。
- 调用 `nextDrawable`。
- 调用 `present`。
- 创建 native handle。
- 创建 raw pointer。
- 新增 C ABI。
- 新增 FFI declaration。
- 调用 bridge。
- 调用 retain / release / destroy。
- 调用 Metal / AppKit / Objective-C / FFI。
- GPU submission。
- render execution。
- renderer state write。
- public API expansion。

本轮 docs-only，也不修改任何 `.cj`。后续若新增 `runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj` 或等价 owner，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 验证记录

本轮按 docs-only 要求未运行 `cjpm build`，未运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过；新增 decision 标题均由中文承载，正文使用中文，英文仅保留代码符号、路径、API 名称、工具命令和固定治理术语。
- forbidden check：无 tracked `.cj` diff；protected paths 无 diff/status；`runtime_state.cj` 仍为 `10065` 行。
- public declaration scan：仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，tracked unstaged scope 报告 `changed_files: 9`、`risk_level: low`、`affected_count: 0`，未发现 affected processes。

## 唯一 opening

`P1 internal Renderer real command buffer implementation admission value boundary bundle implementation`

## 下游落地记录

本轮下游 value boundary 已落地：

- [2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-value-boundary-closure-review.md)
- [runtime_renderer_real_command_buffer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj)

该下游只消费 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`。Current truth 仅限 real command buffer implementation intent / command buffer creation admission policy / single-use admission guard / command buffer failure policy / no-real-command-buffer-implementation readiness value facts。

新的唯一 opening：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 next-boundary 决策

本轮下游 next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 已足够作为当前 no-real-command-buffer-implementation endpoint，不需要继续包装 tail wrapper。下一步只允许 docs-only manifest stabilization，固定 owner / truth / canonical endpoint / default draft / stop-line / Same-shape Boundary Brake。

当前唯一 opening：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 manifest 封账

下游 real command buffer implementation admission manifest stabilization 已完成：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj` owner / truth / canonical endpoint / default draft / stop-line / Same-shape Boundary Brake。`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 仍只代表 real command buffer implementation intent / command buffer creation admission policy / single-use admission guard / command buffer failure policy / no-real-command-buffer-implementation readiness value facts。

新的唯一 opening：

`P1 internal Renderer render pass implementation preflight decision`
