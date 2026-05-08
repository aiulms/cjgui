# P1 Renderer 真实 command buffer implementation admission 后续边界决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 决策结论

确认 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandBufferAdmissionDraft()` 已足够作为当前 no-real-command-buffer-implementation endpoint。

当前 endpoint 只代表：

- real command buffer implementation intent。
- command buffer creation admission policy。
- single-use admission guard。
- command buffer failure policy。
- no-real-command-buffer-implementation readiness value facts。

它不是 command buffer permission、`commandBuffer` permission、`commit` permission、render pass permission、encoder permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下一步选择：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

下一步仍必须 docs-only，不修改 `.cj`。如后续再新增 `.cj` owner file，必须继续保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 已读取证据

- [runtime_renderer_real_command_buffer_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_buffer_admission.cj) 已固定 internal-only owner：唯一 runtime input 是 `CjguiInternalRendererNoRealDrawableImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealCommandBufferImplementationReadiness`。文件头维护注释覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- [real command buffer implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-value-boundary-closure-review.md) 已记录新增 owner、GitNexus impact 结果、build / smoke / scans 验证和 stop-line。
- [real command buffer implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-preflight-decision.md) 已将 output truth 限定为 real command buffer implementation intent / command buffer creation admission policy / single-use admission guard / command buffer failure policy / no-real-command-buffer-implementation readiness value facts。
- [real drawable implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md) 只作为上游 runtime input evidence；`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不是 command buffer permission。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 只作为 queue implementation admission evidence；`CjguiInternalRendererNoRealCommandQueueImplementationReadiness` 不是本轮 runtime input。
- [command buffer lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-command-buffer-lifecycle-manifest.md) 只作为 command buffer lifecycle vocabulary evidence；`CjguiInternalRendererNoCommandBufferReadiness` 不是本轮 runtime input。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 要求 Markdown 使用中文正文和中文标题，并要求后续 `.cj` owner file 保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## endpoint 足够性

当前 endpoint 已经足够作为 no-real-command-buffer-implementation tail，原因如下：

- `CjguiInternalRendererRealCommandBufferImplementationIntent` 明确了未来 implementation intent，但没有授予真实实现入口。
- `CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy` 明确 creation admission facts，同时保持 no command buffer object、no factory call。
- `CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard` 明确 single-use admission facts，同时不保存 token，不表达 post-submit reusable permission。
- `CjguiInternalRendererRealCommandBufferFailurePolicy` 明确 failure policy facts，同时不注册 completion callback，不观察真实 GPU completion。
- `CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 已封住 no-real-command-buffer-implementation readiness facts，并保留 no submit、no render、no renderer state mutation、no external surface、no resource / pointer facts。

因此，继续包装新的 tail readiness 没有新增 owner truth，反而会触发 Same-shape Boundary Brake。

## 候选比较

### 候选 A：推荐 manifest stabilization

推荐：

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

理由：当前 owner、canonical endpoint、default draft、truth、stop-line 与同构边界刹车已经明确，下一刀应做 docs-only manifest 封账，而不是新增 runtime wrapper。该 manifest 应固定 owner file、canonical endpoint、default draft、current truth、non-permission 与 future stop-line。

### 候选 B：暂缓 render pass implementation preflight

暂缓。Render pass implementation 更靠近 render pass / encoder / attachment / pipeline runway，应晚于 no-real-command-buffer-implementation endpoint 的 manifest stabilization。

### 候选 C：暂缓 encoder implementation preflight

暂缓。Encoder implementation 更靠近 encoding scope、pipeline binding 与 draw command，不应越过 command buffer implementation admission manifest。

### 候选 D：暂缓 command buffer creation admission hardening

暂缓。`CjguiInternalRendererRealCommandBufferCreationAdmissionPolicy` 已表达 creation admission、no object creation 和 no factory call facts。只有未来 review 证明 device / queue relation 或 creation admission 表达不足时再做 hardening。

### 候选 E：暂缓 command buffer single-use token preflight

暂缓。`CjguiInternalRendererRealCommandBufferSingleUseAdmissionGuard` 已表达 single-use admission、no token held 与 no post-submit reusable permission facts。当前不需要引入 token owner。

### 候选 F：暂缓 command buffer completion / failure policy preflight

暂缓。`CjguiInternalRendererRealCommandBufferFailurePolicy` 已表达 failure policy、no completion callback、no real GPU completion observation facts。只有未来靠近 callback、state visibility 或 telemetry 时才需要更窄 preflight。

### 候选 G：暂缓 command submission / GPU submission hardening

暂缓。Command submission / GPU submission hardening 应晚于 command buffer implementation admission manifest，并且不得把 no-real-command-buffer endpoint 当成 submit permission。

### 候选 H 到 S：拒绝直接实现或发布

拒绝 direct command buffer creation implementation、direct `commandBuffer` call、direct `commit` implementation、direct render pass / encoder / pipeline implementation、direct drawable acquisition / present implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 T：仅限明确重复时 consolidation

仅当出现明确 duplicate / self-wrapping evidence 时才选择 consolidation。当前 evidence 指向 manifest stabilization，而不是删除 owner 或新增 wrapper。

## 同构边界刹车（Same-shape Boundary Brake）

`CjguiInternalRendererNoRealCommandBufferImplementationReadiness` 不再继续包装成 tail wrapper。

明确拒绝：

- command-buffer-ready permission wrapper。
- `commandBuffer` permission wrapper。
- `commit` permission wrapper。
- render-pass permission wrapper。
- encoder permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

后续如果靠近 render pass implementation、encoder implementation、command buffer creation hardening、single-use token、completion / failure policy、command submission / GPU submission 或真实 platform resource，必须先通过新的 docs-only preflight。

## 停止线

本轮 docs-only，不修改任何 `.cj`，不运行 `cjpm build` / smoke。

继续禁止：

- command buffer creation。
- 调用 `commandBuffer`。
- 调用 `commit`。
- 创建 render pass / encoder / pipeline state。
- drawable acquisition。
- 调用 `nextDrawable`。
- 调用 `present`。
- native handle / raw pointer。
- C ABI / FFI declaration。
- bridge / retain / release / destroy。
- Metal / AppKit / Objective-C / FFI call。
- GPU submission。
- render execution。
- renderer state write。
- public API / C ABI expansion。
- 修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS、CLAUDE 或 `CANGJIE_ISSUE_LEDGER`。

## 验证记录

本轮按 docs-only 要求未运行 `cjpm build`，未运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过；新增 / 修改 Markdown 使用中文正文和中文标题，英文仅保留代码符号、文件路径、API 名称、工具命令和固定治理术语。
- forbidden check：无 tracked `.cj` diff；protected paths 无 diff/status；`runtime_state.cj` 仍为 `10065` 行。
- public declaration scan：仍只允许 `runtime/cjgui/src/runtime_queue_public_submit.cj:781:public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，`changed_count: 28`、`changed_files: 9`、`risk_level: low`、`affected_count: 0`、`affected_processes: []`。

## 唯一 opening

`P1 internal Renderer real command buffer implementation admission manifest stabilization bundle implementation`

## 下游 manifest 封账

下游 manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-command-buffer-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-command-buffer-implementation-admission-manifest-stabilization-closure-review.md)

该下游固定 owner file、canonical endpoint、default draft、current truth 与 stop-line；没有新增 runtime wrapper，没有修改 `.cj`，没有运行 build / smoke。

Manifest 继续确认 `NoRealCommandBufferImplementationReadiness` 不是 command buffer、`commandBuffer`、`commit`、render pass、encoder、native handle、C ABI、FFI、GPU submission、render、renderer state write 或 public API permission。

新的唯一 opening：

`P1 internal Renderer render pass implementation preflight decision`
