# P1 Renderer 真实 drawable implementation admission 下一边界决策

日期：2026-05-06

状态：docs-only next-boundary decision

## 决策结论

`CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 已足够作为当前 no-real-drawable-implementation endpoint。

当前 endpoint 只代表：

- real drawable implementation intent。
- drawable acquisition admission policy。
- drawable availability admission guard。
- drawable presentation admission policy。
- no-real-drawable-implementation readiness value facts。

它不是 drawable permission、`nextDrawable` permission、present permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

下一步推荐：

`P1 internal Renderer real drawable implementation admission manifest stabilization bundle implementation`

该下一步仍必须是 docs-only manifest stabilization：只固定 owner、truth、canonical endpoint、default draft、stop-line、Same-shape Boundary Brake 与下游 opening，不得获取 drawable，不得调用 `nextDrawable` / `present`，不得创建 command buffer，不得靠近 GPU submission、render execution 或 renderer state write。

## 证据读取

- [runtime_renderer_real_drawable_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj) 已存在 internal-only owner，并在文件头维护注释中说明 Owner / Truth / Stop-line / Same-shape Boundary Brake。
- [real drawable implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md) 已确认新增 owner 只消费 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`，canonical endpoint 是 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`。
- [real drawable implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md) 已限定下一刀只能是 value-only implementation admission facts，不是真实 drawable acquisition。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 提供上游 no-real-command-queue-implementation endpoint，并明确不授予 queue、command buffer、GPU submission、render 或 public API permission。
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 只作为 drawable vocabulary evidence；`CjguiInternalRendererNoRealDrawableReadiness` 不是本 admission owner 的 runtime input。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 已要求后续新增 `.cj` owner file 保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释；本轮 docs-only 不新增或修改 `.cj`。

## 当前 endpoint 足够性

当前 endpoint 已覆盖 no-real-drawable-implementation 所需的四类事实：

- `CjguiInternalRendererRealDrawableImplementationIntent` 固定未来 implementation intent 与上游 no-real-command-queue-implementation 关系。
- `CjguiInternalRendererRealDrawableAcquisitionAdmissionPolicy` 固定 drawable acquisition admission facts，并确认不获取 drawable、不执行 lookup call。
- `CjguiInternalRendererRealDrawableAvailabilityAdmissionGuard` 固定 drawable availability admission facts，并确认不查询真实 drawable pool、不持有 drawable token。
- `CjguiInternalRendererRealDrawablePresentationAdmissionPolicy` 固定 drawable presentation admission facts，并确认不展示 drawable、不创建或提交 command buffer。
- `CjguiInternalRendererNoRealDrawableImplementationReadiness` 作为 canonical endpoint，封住 no-real-drawable-implementation readiness value facts。

因此本轮不需要继续包一层 receipt、record、publication 或 permission wrapper；下一步应做 manifest stabilization，把 owner / truth / endpoint / stop-line 封账。

## 候选比较

### 候选 A：推荐 manifest stabilization

推荐。

目标 opening：

`P1 internal Renderer real drawable implementation admission manifest stabilization bundle implementation`

理由：当前 endpoint 已足够作为 no-real-drawable-implementation tail，最小风险下一步是 docs-only manifest stabilization，固定 owner 文件、canonical endpoint、default draft、current truth 与未来 stop-line。该路径不会新增 runtime owner，也不会靠近真实 drawable、command buffer 或 GPU work。

### 候选 B：暂缓 command buffer preflight

暂缓。command buffer implementation 必须晚于 real drawable implementation admission manifest stabilization；当前还不能把 no-real-drawable-implementation endpoint 解释成 command buffer permission。

### 候选 C：暂缓 acquisition hardening

暂缓。当前 `RealDrawableAcquisitionAdmissionPolicy` 已表达 acquisition admission、no lookup call 与 no borrowed drawable facts；只有未来 review 发现表达不足时才需要 hardening。

### 候选 D：暂缓 presentation hardening

暂缓。当前 `RealDrawablePresentationAdmissionPolicy` 已表达 display ordering、no command work 与 no drawable display call facts；只有未来 review 发现 presentation relation 表达不足时才需要 hardening。

### 候选 E：暂缓 starvation / failure policy preflight

暂缓。availability admission guard 已表达 unavailable facts 与 no drawable token facts；starvation / failure policy 未来若靠近 timeout、callback 或 state visibility，必须另开 docs-only preflight。

### 候选 F：暂缓 completion tracking preflight

暂缓。completion tracking 靠近 callback、telemetry、observer、frame state 与 renderer state visibility，当前过早。

### G 到 Q

以下方向拒绝：direct drawable acquisition implementation、direct `nextDrawable` call、direct drawable present implementation、direct command buffer creation / commit implementation、direct native handle / raw pointer implementation、direct C ABI / FFI declaration、direct Metal / AppKit / Objective-C implementation、GPU submission / render execution、renderer state write、public API / C ABI expansion、receipt / record / publication。

### 候选 R：仅限明确重复时 consolidation

仅在明确 duplicate / self-wrapping evidence 出现时选择。当前 evidence 显示新增 owner 提供了 acquisition admission / availability admission / presentation admission / no-real-drawable-implementation 语义，不是低价值重复层，因此不选择 consolidation。

## 同构边界刹车（Same-shape Boundary Brake）

`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不再继续包装成 tail wrapper。

明确拒绝：

- drawable-ready permission wrapper。
- `nextDrawable` permission wrapper。
- present permission wrapper。
- command-buffer permission wrapper。
- native-handle permission wrapper。
- C-ABI / FFI permission wrapper。
- backend implementation wrapper。
- GPU-submission wrapper。
- render-permission wrapper。
- renderer-state-write wrapper。
- receipt / record / publication。

当前 endpoint 只能作为 manifest stabilization 的对象，不能被解释成 drawable acquisition、present、command buffer、GPU submission、render、renderer state write 或 public API 的许可。

## 停止线

本决策不批准：

- 获取 drawable。
- 调用 `nextDrawable`。
- 调用 `present`。
- 创建 command buffer。
- 调用 `commit`。
- 创建 native handle / raw pointer。
- 新增 C ABI / FFI declaration。
- 调用 bridge / retain / release / destroy。
- 调用 Metal / AppKit / Objective-C / FFI。
- 提交 GPU work。
- 执行 render。
- 写 renderer state。
- 扩展 public API。

本轮 docs-only，也不修改任何 `.cj`。后续若新增任何 `.cj` owner file，仍必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释，且注释不得引入真实 implementation permission。

## 验证记录

本轮按 docs-only 要求未运行 `cjpm build`，未运行 smoke。

- `git diff --check`：通过。
- 新 decision no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：无 tracked `.cj` diff；protected paths 无 diff/status；`runtime_state.cj` 仍为 `10065` 行。
- public declaration scan：仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，tracked unstaged scope 报告 `changed_files: 8`、`risk_level: low`、`affected_count: 0`，未发现 affected processes。

## 唯一 next opening

`P1 internal Renderer real drawable implementation admission manifest stabilization bundle implementation`

## 下游 manifest 封账

本 decision 的下游 manifest stabilization 已记录在：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)
- [2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-real-drawable-implementation-admission-manifest-stabilization-closure-review.md)

该 manifest 固定 `runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj` owner、`CjguiInternalRendererNoRealDrawableImplementationReadiness` canonical endpoint 与 `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` default draft。current truth 仍只限 real drawable implementation intent / drawable acquisition admission policy / drawable availability admission guard / drawable presentation admission policy / no-real-drawable-implementation readiness value facts。

当前 downstream next opening：

`P1 internal Renderer real command buffer implementation preflight decision`
