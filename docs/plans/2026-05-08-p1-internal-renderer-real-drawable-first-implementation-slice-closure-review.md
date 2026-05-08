# 渲染器真实 drawable 第一刀切片收口复核

日期：2026-05-08

状态：implementation slice closure / internal-only shell / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real drawable first implementation slice bundle`。本轮新增一个极窄 internal-only owner shell：

- [runtime_renderer_drawable_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_real.cj)

该 owner 只表达 real drawable shell intent、drawable availability admission shell、drawable acquisition denial proof、presentation denial proof、drawable teardown / failure classification 与 no-real-drawable-shell readiness facts。它不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不改变既有 drawable lifecycle owner 或 implementation admission owner 的含义。

## GitNexus 影响复核

本轮编辑 runtime symbol 前已对上游入口执行 GitNexus impact：

- `CjguiInternalRendererNoRealCommandQueueShellReadiness`：GitNexus 返回 `Target not found`，risk 为 `UNKNOWN`，impactedCount 为 `0`。
- `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft`：GitNexus 返回 `Target not found`，risk 为 `UNKNOWN`，impactedCount 为 `0`。

这说明近期新增 symbols 尚未进入索引。未出现 HIGH / CRITICAL 风险，因此继续执行，并用源码范围、build、smoke、stop-line scan 与 GitNexus `detect_changes` 兜底。

## 落地内容

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_drawable_real.cj`

本轮新增 internal symbols：

- `CjguiInternalRendererRealDrawableShellIntent`
- `CjguiInternalRendererRealDrawableAvailabilityAdmissionShell`
- `CjguiInternalRendererDrawableAcquisitionDenialProof`
- `CjguiInternalRendererDrawablePresentationDenialProof`
- `CjguiInternalRendererDrawableTeardownFailureClassification`
- `CjguiInternalRendererNoRealDrawableShellReadiness`
- `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`

## 固定项

- Owner file：`runtime/cjgui/src/runtime_renderer_drawable_real.cj`
- Canonical endpoint：`CjguiInternalRendererNoRealDrawableShellReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`
- Runtime input：`CjguiInternalRendererNoRealCommandQueueShellReadiness`
- Current truth：real drawable shell intent / drawable availability admission shell / drawable acquisition denial proof / presentation denial proof / drawable teardown / failure classification / no-real-drawable-shell readiness facts

本 owner 的唯一 runtime input 来自 `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`。`CjguiInternalRendererNoRealCommandQueueShellReadiness` 仍不是真实 command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API permission。

## 边界事实

`RealDrawableShellIntent` 只表达 future drawable shell 第一刀意图。

`RealDrawableAvailabilityAdmissionShell` 不查询真实 drawable pool，不保存 drawable token，不创建 native resource surface。

`DrawableAcquisitionDenialProof` 不获取 drawable，不暴露 drawable texture，不执行 blocking foreign call。

`DrawablePresentationDenialProof` 不调用 presentation，不创建 command buffer relation，不提交 work。

`DrawableTeardownFailureClassification` 只表达 unavailable drawable、wrong-thread、stale drawable 与 bridge optimism 的 fail-closed 分类，不发布 failure event 或 public diagnostics。

`NoRealDrawableShellReadiness` 不是真实 drawable permission、`nextDrawable` permission、present permission、command buffer permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics permission 或 public API permission。

## 同形边界刹车

本轮没有新增 receipt、record、publication、permission 字段或 public API，也没有把 command queue shell endpoint、real drawable lifecycle manifest、implementation admission manifest、smoke evidence 或 topic manifest 包成 drawable-ready、queue-ready、backend-ready、native-handle-ready、GPU-submission、render-permission 或 renderer-state-write wrapper。

## 停止线

- no drawable acquisition。
- no `nextDrawable`。
- no `present`。
- no command buffer / `commandBuffer`。
- no `commit`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 验证结果

- `cjpm build --target-dir /tmp/cjgui-renderer-real-drawable-first-slice-macro-target --skip-script`：通过；仍有既有 unused warnings，未出现 error。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过；该 smoke 仍只作为 labs feasibility / teardown evidence，不升格 runtime truth。
- `git diff --check`：通过。
- 新 runtime / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，范围限定 project docs / README，并避开 `reference_repos/`。
- README / tracker / plans README / runtime README reachability：通过。
- 中文标题与正文抽查：通过。
- Protected path check：`runtime_state.cj` 仍为 `10065` 行，protected paths clean。
- Comment-aware public declaration scan：仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- New owner header / stop-line scan：通过，文件头包含 Owner / Truth / Stop-line / Same-shape Boundary Brake；code body 未出现真实 drawable acquisition、`nextDrawable` call、`present` call、command buffer、GPU submission、native handle、C ABI / FFI、Metal / AppKit 调用、renderer state write、public API 或 module-level mutable `var`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk 为 `low`，affected_count 为 `0`，affected_processes 为空；本次报告覆盖当前 unstaged 范围中的 36 个 changed symbols / 23 个 changed files。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real drawable first implementation preflight completed 推进到 first implementation slice completed。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()` 作为本 first-slice shell endpoint。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime/cjgui/src/runtime_renderer_drawable_real.cj`，固定 drawable shell / acquisition denial / presentation denial / teardown failure truth，并保持 no-real-drawable / no-native / no-GPU / no-state / no-public stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real drawable first implementation slice closure / next real drawable decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real drawable first implementation slice closure / next real drawable decision`
