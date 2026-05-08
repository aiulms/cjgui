# P1 内部 Renderer 真实 drawable implementation admission manifest 稳定化收束评审

日期：2026-05-06

状态：docs-only manifest stabilization closure

## 范围结论

本轮完成 docs-only manifest stabilization，新增：

- [2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)

本轮没有修改任何 `.cj`，没有运行 `cjpm build` / smoke，没有触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。

Manifest 固定：

- Owner file：`runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj`。
- Canonical endpoint：`CjguiInternalRendererNoRealDrawableImplementationReadiness`。
- Default draft：`cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()`。
- Current truth：real drawable implementation intent / drawable acquisition admission policy / drawable availability admission guard / drawable presentation admission policy / no-real-drawable-implementation readiness value facts。

## 证据链

- [runtime_renderer_real_drawable_admission.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_drawable_admission.cj) 已保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释；本轮只读取，不修改。
- [real drawable implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md) 已确认 `CjguiInternalRendererNoRealDrawableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableAdmissionDraft()` 足够作为当前 no-real-drawable-implementation endpoint。
- [real drawable implementation admission value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-internal-renderer-real-drawable-implementation-admission-value-boundary-closure-review.md) 已记录 owner 只消费 `CjguiInternalRendererNoRealCommandQueueImplementationReadiness`，并通过 source + build + smoke + scans 兜底。
- [real drawable implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md) 已限定下一刀只能表达 value-only implementation admission facts。
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md) 提供唯一 runtime input endpoint，但不授予 drawable、command buffer、GPU submission、render 或 public API permission。
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md) 只作为 drawable lifecycle vocabulary evidence，不升格为 runtime input。
- [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md) 继续要求新增 / 修改 Markdown 使用中文正文和中文标题；后续新增 `.cj` owner file 必须保留 Owner / Truth / Stop-line / Same-shape Boundary Brake 文件头维护注释。

## 边界确认

`RealDrawableAcquisitionAdmissionPolicy` 不获取 drawable，不调用 `nextDrawable`。

`RealDrawableAvailabilityAdmissionGuard` 不查询真实 drawable pool，不持有 drawable token。

`RealDrawablePresentationAdmissionPolicy` 不调用 `present`，不创建或提交 command buffer。

`NoRealDrawableImplementationReadiness` 不是 drawable permission、`nextDrawable` permission、present permission、command buffer permission、native handle permission、C ABI permission、FFI permission、GPU submission permission、render permission、renderer state write permission 或 public API permission。

本轮没有获取 drawable，没有调用 `nextDrawable` / `present` / `commit`，没有创建 command buffer、native handle、raw pointer、C ABI、FFI declaration，没有调用 bridge / retain / release / destroy、Metal / AppKit / Objective-C / FFI，没有提交 GPU work，没有执行 render，没有写 renderer state，没有扩 public API。

## 同构边界刹车（Same-shape Boundary Brake）

本轮是 manifest 封账，明确拒绝 drawable-ready permission wrapper、`nextDrawable` permission wrapper、present permission wrapper、command-buffer permission wrapper、native-handle permission wrapper、C-ABI / FFI permission wrapper、backend implementation wrapper、GPU-submission wrapper、render-permission wrapper、renderer-state-write wrapper、receipt / record / publication。

`CjguiInternalRendererNoRealDrawableImplementationReadiness` 不再继续包装成 tail wrapper。未来靠近 real command buffer implementation、drawable acquisition hardening、drawable presentation hardening、drawable starvation / failure policy、render completion / frame completion tracking、真实 `nextDrawable` / `present` / GPU submission 或 renderer state write，必须先 docs-only preflight。

## 同步更新

本轮同步更新：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [real drawable implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-implementation-preflight-decision.md)
- [real drawable implementation admission next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-next-boundary-decision.md)
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)
- [real drawable lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-drawable-lifecycle-manifest.md)

## 验证记录

本轮按 docs-only 要求未运行 `cjpm build`，未运行 smoke。

- `git diff --check`：通过。
- 新 manifest no-index whitespace check：通过。
- 新 closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability：通过。
- Markdown 中文标题与中文正文抽查：通过；新增 manifest / closure 标题均由中文承载，正文使用中文，英文仅保留代码符号、路径、API 名称、工具命令和固定治理术语。
- forbidden check：无 tracked `.cj` diff；protected paths 无 diff/status；`runtime_state.cj` 仍为 `10065` 行。
- public declaration scan：仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：完成，tracked unstaged scope 报告 `changed_files: 8`、`risk_level: low`、`affected_count: 0`，未发现 affected processes。

## 下游 opening

唯一 next opening：

`P1 internal Renderer real command buffer implementation preflight decision`
