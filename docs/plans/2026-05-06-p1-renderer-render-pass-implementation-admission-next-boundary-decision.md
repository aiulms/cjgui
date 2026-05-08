# P1 Renderer render pass implementation admission 下一边界决策

日期：2026-05-06
状态：docs-only next-boundary decision

## 决策结论

`CjguiInternalRendererNoRenderPassImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 已足够作为当前 no-render-pass-implementation endpoint。

当前 endpoint 只代表 render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts。它不是 render pass descriptor permission、attachment permission、texture permission、encoder permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下一步选择：

`P1 internal Renderer render pass implementation admission manifest stabilization bundle implementation`

该下一步仍必须 docs-only，不修改任何 `.cj`，不运行 `cjpm build` 或 smoke。若后续再新增 `.cj` owner，必须继续保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释；注释只能维护 value facts 与 stop-line，不能引入真实 implementation permission。

## 已读取证据

- [runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj)：确认 owner file 已存在，唯一 runtime input 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRenderPassImplementationReadiness`。
- [render pass implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-value-boundary-closure-review.md)：确认 build / smoke 证据属于上一轮 value boundary closure；本轮 docs-only 不复跑。
- [render pass implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-preflight-decision.md)：确认 runway 已允许打开，但下一步只能是 internal value boundary / admission facts。
- [real command buffer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)：确认 upstream no-real-command-buffer-implementation endpoint 只作为 input evidence，不授予 render pass 或 command buffer permission。
- [render pass lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-render-pass-lifecycle-manifest.md)：确认旧 no-render-pass lifecycle facts 只能作为 vocabulary evidence，不能升格为 runtime input 或 render-pass-ready permission。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：确认新增 / 修改 Markdown 使用中文正文和中文章节标题；后续新增 `.cj` owner 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 端点确认

当前 no-render-pass-implementation endpoint 已覆盖本阶段需要封账的四类事实：

- render pass implementation intent。
- attachment admission policy。
- load-store admission guard。
- clear-color target admission policy。

这些事实足以作为当前 render pass implementation admission 的 closure tail。继续在它之后新增 receipt / record / publication 或 permission wrapper，只会把同一组 facts 再包装一层，违反 Same-shape Boundary Brake。

## 非授权说明

`CjguiInternalRendererNoRenderPassImplementationReadiness` 不授权：

- render pass descriptor creation。
- attachment object creation。
- texture creation。
- drawable acquisition。
- encoder creation。
- `renderCommandEncoder` call。
- command buffer creation。
- `commandBuffer` call。
- `commit` / `present` / `nextDrawable`。
- native handle / raw pointer。
- C ABI / FFI declaration。
- bridge call / retain / release / destroy。
- Metal / AppKit / Objective-C / FFI call。
- GPU submission。
- render execution。
- renderer state write。
- public API expansion。

## 候选比较

### 候选 A：推荐 manifest stabilization

推荐选择：

`P1 internal Renderer render pass implementation admission manifest stabilization bundle implementation`

理由：value boundary 已经落地，当前最小有价值下一步是固定 owner file、canonical endpoint、default draft、current truth 与 stop-line。该选择不新增 runtime 行为，也不引入 render pass descriptor、attachment、texture、encoder、command buffer 或 GPU submission。

### 候选 B：暂缓 encoder implementation preflight

暂缓。Encoder implementation 更靠近 `renderCommandEncoder`、resource binding、pipeline binding 与 draw call，必须晚于 render pass implementation admission manifest。

### 候选 C：暂缓 pipeline implementation preflight

暂缓。Pipeline implementation 依赖 encoder / shader / pipeline state admission 证据；当前 render pass implementation admission 尚未 manifest 封账。

### 候选 D：暂缓 render pass attachment admission hardening

暂缓。`RenderPassAttachmentAdmissionPolicy` 已表达 no render pass descriptor、no attachment object、no texture、no drawable facts；只有后续 review 证明 attachment / drawable relation 表达不足时才打开 hardening。

### 候选 E：暂缓 render pass load-store admission hardening

暂缓。`RenderPassLoadStoreAdmissionGuard` 已表达 no load / store execution 与 no attachment binding facts；当前不需要新增 hardening owner。

### 候选 F：暂缓 render target size-color admission hardening

暂缓。`RenderPassClearColorTargetAdmissionPolicy` 已表达 no screen / layer / color space query 与 no target texture facts；只有 size / Retina scale / color-space evidence 不足时才另开 docs-only preflight。

### 候选 G 到 S：拒绝直接实现或发布

拒绝 direct render pass descriptor implementation、direct attachment / texture implementation、direct `renderCommandEncoder` call、direct encoder / pipeline implementation、direct command buffer / commit implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 T：仅限明确重复时 consolidation

仅在出现明确 duplicate / self-wrapping evidence 时选择 consolidation。当前 evidence 显示应先 manifest 封账，而不是合并或删除 render pass implementation admission endpoint。

## 同构边界刹车

`CjguiInternalRendererNoRenderPassImplementationReadiness` 不再继续包装成 tail wrapper。

明确拒绝：

- render-pass-ready permission wrapper。
- attachment permission wrapper。
- texture permission wrapper。
- encoder permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

当前 endpoint 只停在 no-render-pass-implementation readiness value facts；它不能被解释成任何真实 render pass、attachment、texture、encoder、command buffer、GPU submission、render 或 renderer state write 的 permission。

## 停止线

本轮和下一轮 manifest stabilization 均不得：

- 修改任何 `.cj`。
- 运行 `cjpm build` 或 smoke。
- 触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 创建 render pass descriptor。
- 创建 attachment object / texture / drawable。
- 创建 encoder / pipeline state / command buffer。
- 调用 `renderCommandEncoder`、`commandBuffer`、`commit`、`present` 或 `nextDrawable`。
- 创建 native handle / raw pointer。
- 新增 C ABI / FFI declaration。
- 调用 bridge / retain / release / destroy。
- 调用 Metal / AppKit / Objective-C / FFI。
- 提交 GPU work。
- 执行 render。
- 写 renderer state。
- 扩 public API。

## 验证记录

本轮按 docs-only 要求只执行文档与仓库状态验证；不运行 `cjpm build`，不运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：通过；无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan：通过；仍只允许 `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，`changed_count: 33`、`changed_files: 10`、`risk_level: low`、`affected_count: 0`、`affected_processes: []`。

## 唯一后续入口

`P1 internal Renderer encoder implementation preflight decision`

## 下游 manifest 封账

Render pass implementation admission manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-pass-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 已固定 `runtime/cjgui/src/runtime_renderer_render_pass_admission.cj` 的 owner file、canonical endpoint、default draft、current truth 与 stop-line。下一步进入 docs-only `P1 internal Renderer encoder implementation preflight decision`，不创建 encoder，不调用 `renderCommandEncoder`，不创建 pipeline state、command buffer 或 GPU work。
