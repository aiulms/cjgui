# P1 Renderer render pass implementation admission manifest 稳定化收束复核

日期：2026-05-06

状态：docs-only manifest stabilization closure review

## 收束结论

本轮新增 manifest：

- [2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-pass-implementation-admission-manifest.md)

该 manifest 固定 owner file、canonical endpoint、default draft、current truth 与 stop-line：

- Owner file：[runtime_renderer_render_pass_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_render_pass_admission.cj)
- Canonical endpoint：`CjguiInternalRendererNoRenderPassImplementationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()`
- Current truth：render pass implementation intent / attachment admission policy / load-store admission guard / clear-color target admission policy / no-render-pass-implementation readiness value facts

本轮 docs-only，不修改任何 `.cj`，不运行 `cjpm build` / smoke，不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

## 固定事实

`runtime_renderer_render_pass_admission.cj` 已保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。后续若再新增 `.cj` owner，仍必须保留同类文件头维护注释；注释不得引入真实 implementation permission。

`cjguiInternalExecuteDefaultRendererRenderPassAdmissionDraft()` 的唯一 runtime input 来自 `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()`，即 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`。

Canonical value chain 固定为：

1. `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`
2. `CjguiInternalRendererRenderPassImplementationIntent`
3. `CjguiInternalRendererRenderPassAttachmentAdmissionPolicy`
4. `CjguiInternalRendererRenderPassLoadStoreAdmissionGuard`
5. `CjguiInternalRendererRenderPassClearColorTargetAdmissionPolicy`
6. `CjguiInternalRendererNoRenderPassImplementationReadiness`

## 边界确认

`CjguiInternalRendererRenderPassAttachmentAdmissionPolicy` 不创建 render pass descriptor、attachment object、texture 或 drawable，不接外部 surface，不持有 platform resource token。

`CjguiInternalRendererRenderPassLoadStoreAdmissionGuard` 不执行 load / store，不绑定 attachment，不构造 stage entry，不表达 render permission。

`CjguiInternalRendererRenderPassClearColorTargetAdmissionPolicy` 不查询真实 screen / layer / color space，不创建 target texture。

`CjguiInternalRendererNoRenderPassImplementationReadiness` 不是 render pass descriptor permission、attachment permission、texture permission、encoder permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

## 同构边界刹车

本轮是 manifest 封账，不新增 wrapper、不新增 runtime behavior，也不把 `CjguiInternalRendererNoRenderPassImplementationReadiness` 继续包装成 tail wrapper。

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

未来靠近 encoder implementation、pipeline implementation、render pass attachment admission hardening、load-store admission hardening、render target size-color admission、真实 render pass descriptor / encoder、GPU submission 或 renderer state write，必须先通过 docs-only preflight。

## 候选结论

选择 A：

`P1 internal Renderer encoder implementation preflight decision`

暂缓 B / C / D / E：

- pipeline implementation preflight。
- render pass attachment admission hardening。
- render pass load-store admission hardening。
- render target size-color admission hardening。

拒绝 F 到 R：

- direct render pass descriptor implementation。
- direct attachment / texture implementation。
- direct `renderCommandEncoder` call。
- direct encoder / pipeline implementation。
- direct command buffer / commit implementation。
- direct drawable acquisition / present implementation。
- direct native handle / raw pointer implementation。
- direct C ABI / FFI declaration。
- direct Metal / AppKit / Objective-C implementation。
- GPU submission / render execution。
- renderer state write。
- public API / C ABI expansion。
- receipt / record / publication。

S consolidation 仅在出现明确 duplicate / self-wrapping evidence 时选择；当前没有这类 evidence。

## 停止线

本轮没有执行、也不批准：

- 修改任何 `.cj`。
- 运行 `cjpm build` 或 smoke。
- 触碰 `runtime_state.cj`。
- 触碰 `runtime/cjgui/cjpm.toml`。
- 触碰 smoke / harness / native bridge / entry。
- 触碰 AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
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
- 新 manifest / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：通过；无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan：通过；仍只允许 `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，`changed_count: 33`、`changed_files: 10`、`risk_level: low`、`affected_count: 0`、`affected_processes: []`。

## 唯一后续入口

`P1 internal Renderer encoder implementation preflight decision`
