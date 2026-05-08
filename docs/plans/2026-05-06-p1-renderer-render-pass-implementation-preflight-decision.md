# P1 Renderer render pass implementation preflight 决策

日期：2026-05-06

状态：docs-only preflight decision

## 决策结论

本轮允许打开 render pass implementation runway，但不批准真实 render pass descriptor、attachment object、texture、drawable、encoder、pipeline state、command buffer、`renderCommandEncoder` call、`commandBuffer` call、`commit`、`present`、`nextDrawable`、native handle、raw pointer、C ABI、FFI declaration、bridge call、Metal / AppKit / Objective-C / FFI call、GPU submission、render execution、renderer state write 或 public API expansion。

下一步选择：

`P1 internal Renderer render pass implementation admission value boundary bundle implementation`

该下一步仍必须是 internal value boundary / implementation admission facts，不是真实 render pass implementation。默认候选 owner 可以是 `runtime/cjgui/src/runtime_renderer_render_pass_admission.cj`；若未来新增该 `.cj` owner file，必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 证据读取

- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md) 已固定 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`，作为 no-real-command-buffer-implementation endpoint；它不是 render pass permission、encoder permission、GPU submission permission、render permission 或 public API permission。
- [render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md) 已提供 render pass lifecycle intent、attachment policy、load-store policy、clear-color policy 与 no-render-pass readiness vocabulary；它不是 implementation manifest，也不授予 render pass descriptor、attachment object、texture、encoder 或 render permission。
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md) 只作为 drawable relation evidence；`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不是下一步 runtime input。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 只作为 command queue relation evidence；`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` 不是下一步 runtime input。
- [command submission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-command-submission-manifest.md) 只作为 no-submit / failure vocabulary evidence；`CjguiInternalRendererNoGpuSubmissionReadiness` 不授予 `commit`、`present`、`nextDrawable`、GPU submission 或 render permission。
- [backend / Metal reference pack](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-backend-metal-reference-pack.md) 只作为 docs evidence：`MTLRenderPassDescriptor` 描述 attachments / destinations，`MTLRenderCommandEncoder` 由 command buffer 与 descriptor 创建，attachments 承载 load / store actions 与 target textures。该 reference pack 不能升格为 runtime truth。
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md) 要求 GPU / native object lifecycle 在实现前先明确 owner、teardown、failure、FFI 边界与验证策略。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner file 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 预检判断

证据足以打开 render pass implementation runway，但只能以 value-only implementation admission boundary 进入。

本轮不需要先拆成更窄的 attachment admission、load-store admission、clear-color / drawable-size admission 或 render target relation hardening，因为现有 evidence 已经冻结足够词汇：

- no-real-command-buffer-implementation endpoint 已封账，能作为下一步唯一 runtime input candidate。
- render pass lifecycle manifest 已提供 attachment role、target relation、load / store intent、clear-color facts、drawable-size / color-space / resize relation vocabulary。
- backend / Metal reference pack 已确认 render pass descriptor、attachments、encoder creation relation 与 target textures 的官方 evidence。
- real drawable implementation admission manifest 已提供 drawable relation evidence，但不授予 attachment / texture / render pass permission。
- command submission manifest 已封住 no-submit endpoint，避免把 render pass admission 误读成 `commit` 或 GPU submission permission。

下一步 value boundary 的唯一 runtime input 建议只消费：

- `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`

`CjguiInternalRendererNoRenderPassReadiness`、`CjguiInternalRendererNoRealDrawableImplementationReadiness`、`CjguiInternalRendererNoRealCommandQueueImplementationReadiness`、`CjguiInternalRendererNoGpuSubmissionReadiness`、render pass lifecycle facts、reference pack 与 risk ledger 只能作为 docs evidence，不能成为额外 runtime input。

下一步 output truth 必须限定为：

- render pass implementation intent。
- attachment admission policy。
- load-store admission guard。
- clear-color target admission policy。
- no-render-pass-implementation readiness value facts。

## 候选比较

### 候选 A：谨慎推荐 admission value boundary

推荐：

`P1 internal Renderer render pass implementation admission value boundary bundle implementation`

理由：这是下一刀最窄且有用的 implementation-admission 切口。它新增 render pass implementation intent、attachment admission、load-store admission、clear-color target admission 与 no-render-pass-implementation readiness 语义，但不创建 `MTLRenderPassDescriptor`，不创建 texture / attachment object，不调用 `renderCommandEncoder`，不创建 encoder / pipeline state / command buffer，不新增 native handle、FFI declaration 或 C ABI。

### 候选 B：备选 attachment admission preflight

暂不选择。Render pass lifecycle manifest 已有 attachment role / target relation vocabulary，real drawable implementation admission manifest 已有 drawable relation evidence，reference pack 已确认 attachments / destinations / target textures 的官方证据。下一步 value boundary 可以先表达 attachment admission policy，而不是另开更窄 preflight。

### 候选 C：备选 load-store admission preflight

暂不选择。Render pass lifecycle manifest 已有 load / store intent vocabulary，reference pack 已确认 attachments carry load / store actions。下一步 value boundary 可以表达 load-store admission guard，但不得设置 platform descriptor、不得 encode、不得 present。

### 候选 D：备选 target size-color admission preflight

暂不选择。Drawable size / Retina scale / color-space relation 已在 render pass lifecycle manifest、real drawable implementation admission manifest 与 reference pack 中作为 dehydrated facts 出现；下一步可以表达 clear-color target admission policy，但不得查询真实 screen / layer / color space，也不得创建 texture / drawable。

### 候选 E：暂缓 encoder implementation preflight

暂缓。Encoder implementation 更靠近 `renderCommandEncoder`、pipeline binding、resource binding 与 draw calls，必须晚于 render pass implementation admission manifest。

### 候选 F：暂缓 pipeline implementation preflight

暂缓。Pipeline implementation 更靠近 shader function、pipeline descriptor、pipeline state creation 与 encoder binding，当前过早。

### 候选 G：暂缓 command buffer creation / commit hardening

暂缓。No-real-command-buffer-implementation endpoint 已封账；当前更窄的下一步是 render pass implementation admission，不是 command buffer creation 或 commit hardening。

### 候选 H 到 T：拒绝直接实现或发布

拒绝 direct render pass descriptor implementation、direct attachment / texture implementation、direct `renderCommandEncoder` call、direct encoder / pipeline implementation、direct command buffer / commit implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 U：仅限明确重复时 consolidation

只有出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 显示下一步会新增 attachment admission / load-store admission / clear-color target admission / no-render-pass-implementation 语义，不是低价值重复层。

## 同构边界刹车（Same-shape Boundary Brake）

下一步不得把 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`、`CjguiInternalRendererNoRenderPassReadiness`、`CjguiInternalRendererNoRealDrawableImplementationReadiness` 或 reference evidence 包成：

- render pass implementation receipt / record / publication。
- render-pass-ready permission wrapper。
- attachment permission wrapper。
- texture permission wrapper。
- encoder permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。

若下一步推进 value boundary，必须新增的是 attachment admission、load-store admission、clear-color target admission 与 no-render-pass-implementation readiness 语义，而不是 no-real-command-buffer-implementation tail wrapper。

## 停止线

本决策不批准：

- render pass descriptor。
- attachment object。
- texture。
- encoder。
- `renderCommandEncoder`。
- command buffer。
- `commandBuffer`。
- `commit`。
- drawable acquisition。
- `nextDrawable`。
- `present`。
- native handle。
- raw pointer。
- C ABI。
- FFI declaration。
- bridge call。
- retain / release / destroy。
- Metal / AppKit / Objective-C。
- GPU submission。
- render。
- renderer state write。
- public API。

本轮 docs-only，也不修改任何 `.cj`。后续若新增 `runtime/cjgui/src/runtime_renderer_render_pass_admission.cj` 或等价 owner，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 验证记录

本轮按 docs-only 要求未运行 `cjpm build`，未运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过；新增 / 修改 Markdown 使用中文正文和中文章节标题，英文仅保留代码符号、文件路径、API 名称、工具命令和固定治理术语。
- forbidden check：通过；无 tracked `.cj` diff，protected paths 无 diff/status，`runtime_state.cj` 仍为 `10065` 行。
- public declaration scan：通过；仍只允许 `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，`changed_count: 28`、`changed_files: 10`、`risk_level: low`、`affected_count: 0`、`affected_processes: []`。

## 唯一 opening

`P1 internal Renderer encoder implementation preflight decision`

## 下游 value boundary closure

Render pass implementation admission value boundary 已记录在：

- [2026-05-06-p1-internal-renderer-render-pass-implementation-admission-value-boundary-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-value-boundary-closure-review.md)

该 closure 新增 internal-only [runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj)，只消费 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`，canonical endpoint 是 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`。Output truth 仅限 render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts；仍不批准 render pass descriptor、attachment object、texture、encoder、`renderCommandEncoder`、command buffer、`commit`、drawable acquisition、GPU submission、render execution、renderer state write 或 public API permission。

## 下游下一边界决策

Render pass implementation admission next-boundary decision 已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 足够作为当前 no-render-pass-implementation endpoint。下一步只允许 docs-only manifest stabilization，固定 owner / canonical endpoint / default draft / current truth / stop-line；仍不批准 render pass descriptor、attachment、texture、encoder、command buffer、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

## 下游 manifest 封账

Render pass implementation admission manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_render_pass_admission.cj` 的 owner / canonical endpoint / default draft / current truth / stop-line。下一步进入 docs-only `P1 internal Renderer encoder implementation preflight decision`；仍不批准 render pass descriptor、attachment、texture、encoder、`renderCommandEncoder`、command buffer、GPU submission、render、renderer state write 或 public API permission。
