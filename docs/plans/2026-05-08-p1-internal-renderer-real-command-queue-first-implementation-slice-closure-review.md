# 渲染器真实 command queue 第一刀切片收口复核

日期：2026-05-08

状态：implementation slice closure / internal-only shell / no runtime truth

## 文件定位

本文件收口 `P1 internal Renderer real command queue first implementation slice bundle`。本轮新增一个极窄 internal-only owner shell：

- [runtime_renderer_command_queue_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_command_queue_real.cj)

该 owner 只表达 real command queue shell intent、queue creation admission shell、command queue ownership proof、command queue teardown proof、command queue failure classification 与 no-real-command-queue shell readiness facts。它不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，也不改变既有 command queue lifecycle owner 的含义。

## GitNexus 影响复核

本轮编辑 runtime symbol 前已对上游入口执行 GitNexus impact：

- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`：GitNexus 返回 `Target not found`，risk 为 `UNKNOWN`，impactedCount 为 `0`。
- `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft`：GitNexus 返回 `Target not found`，risk 为 `UNKNOWN`，impactedCount 为 `0`。

这通常说明最近新增的 symbols 尚未进入索引。未出现 HIGH / CRITICAL 风险，因此继续执行，但把该项记录为索引覆盖残留风险，并用源码范围、build、smoke、stop-line scan 与 GitNexus `detect_changes` 兜底。

## 落地内容

新增 owner file：

- `runtime/cjgui/src/runtime_renderer_command_queue_real.cj`

本轮新增 internal symbols：

- `CjguiInternalRendererRealCommandQueueShellIntent`
- `CjguiInternalRendererRealCommandQueueCreationAdmissionShell`
- `CjguiInternalRendererRealCommandQueueOwnershipProof`
- `CjguiInternalRendererRealCommandQueueTeardownProof`
- `CjguiInternalRendererRealCommandQueueFailureClassification`
- `CjguiInternalRendererNoRealCommandQueueShellReadiness`
- `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`

canonical endpoint 采用 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，而不是预检建议的 `CjguiInternalRendererNoRealCommandQueueReadiness`。原因是 `CjguiInternalRendererNoRealCommandQueueReadiness` 已由旧 lifecycle owner [runtime_renderer_real_command_queue.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_real_command_queue.cj) 拥有；本轮不能重复定义，也不能把旧 lifecycle endpoint 薄包装成新的 first-slice truth。

## 固定项

- Owner file：`runtime/cjgui/src/runtime_renderer_command_queue_real.cj`
- Canonical endpoint：`CjguiInternalRendererNoRealCommandQueueShellReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()`
- Runtime input：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- Current truth：real command queue shell intent / queue creation admission shell / command queue ownership proof / command queue teardown proof / command queue failure classification / no-real-command-queue shell readiness facts

本 owner 的唯一 runtime input 来自 `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。`CjguiInternalRendererNoRealMetalDeviceLayerReadiness` 仍只代表 real Metal device-layer shell / dehydrated native result facts，不是真实 `MTLDevice`、真实 `CAMetalLayer`、native handle、command queue、drawable、GPU submission、renderer state write、backend ready truth 或 public API permission。

## 边界事实

`RealCommandQueueShellIntent` 只表达后续 command queue shell 第一刀意图。它不是 queue-ready permission，也不是 backend-ready permission。

`RealCommandQueueCreationAdmissionShell` 只表达 queue creation admission shell facts。它不创建真实 `MTLCommandQueue`，不调用 `newCommandQueue`，不创建 command buffer，不调用 native bridge、Objective-C、Metal、AppKit、C ABI 或 FFI。

`RealCommandQueueOwnershipProof` 只表达 owner-local confinement 与 no resource export proof。它不保存 native handle，不创建 raw pointer，不暴露 foreign resource token。

`RealCommandQueueTeardownProof` 只表达 ordered / repeatable / failure-safe teardown proof。它不调用 retain / release / destroy，不执行真实 teardown，不写 renderer state。

`RealCommandQueueFailureClassification` 只表达 unavailable queue creation、wrong-thread、dangling resource 与 bridge optimism 的 fail-closed 分类。它不发布 failure event，不生成 public diagnostics。

`NoRealCommandQueueShellReadiness` 只封住本轮 no-real-command-queue shell readiness facts。它不是 `MTLCommandQueue` permission、`newCommandQueue` permission、native handle permission、drawable permission、command buffer permission、GPU submission permission、render permission、renderer state write permission、backend ready truth、public diagnostics permission 或 public API permission。

## 同形边界刹车

本轮没有新增 receipt、record、publication、permission 字段或 public API，也没有把 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`、real command queue lifecycle manifest、real command queue implementation admission manifest、smoke evidence 或 topic manifest 包成 queue-ready、backend-ready、native-handle-ready、GPU-submission、render-permission 或 renderer-state-write wrapper。

`CjguiInternalRendererNoRealCommandQueueShellReadiness` 是新的 first-slice shell endpoint，用来表达 command queue shell / ownership / teardown / failure classification 语义。它不得在下一轮继续被薄包装成 queue-ready 或 backend-ready endpoint。

## 停止线

本轮继续禁止并已保持：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no real `MTLCommandQueue`。
- no `newCommandQueue`。
- no drawable。
- no command buffer。
- no `commit`。
- no `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no public diagnostics / API。
- no backend ready truth。

## 验证结果

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-renderer-real-command-queue-first-slice-target --skip-script`：通过；仅有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过；该 smoke 仍只作为 labs feasibility / teardown evidence，不升格 runtime truth。
- `git diff --check`：通过。
- 新 runtime / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，范围限定 project docs / README，并避开 `reference_repos/`。
- README / tracker / plans README / runtime README reachability：通过。
- 中文标题与正文抽查：通过。
- Protected path check：`runtime_state.cj` 仍为 `10065` 行，protected paths clean。
- Comment-aware public declaration scan：仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- New owner header / stop-line scan：通过，文件头包含 Owner / Truth / Stop-line / Same-shape Boundary Brake，code body 未出现真实 `MTLCommandQueue`、`newCommandQueue`、native handle、C ABI / FFI、Metal / AppKit 调用、commit / present / drawable / command buffer / GPU / public / module-level `var`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：risk 为 `low`，affected_count 为 `0`，affected_processes 为空；本次报告覆盖当前 unstaged 范围中的 36 个 changed symbols / 23 个 changed files。

## 下游同步

本 closure 同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real command queue first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-preflight-decision.md)
- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real command queue lifecycle manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-lifecycle-manifest.md)
- [real command queue implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-real-command-queue-implementation-admission-manifest.md)

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real command queue first implementation preflight completed 推进到 first implementation slice completed。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoRealCommandQueueShellReadiness` / `cjguiInternalExecuteDefaultRendererRealCommandQueueShellDraft()` 作为本 first-slice shell endpoint；`CjguiInternalRendererNoNativeResourceBridgeReadiness` tail 与旧 lifecycle endpoint `CjguiInternalRendererNoRealCommandQueueReadiness` 不变。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime/cjgui/src/runtime_renderer_command_queue_real.cj`，固定 command queue shell / ownership / teardown / failure classification truth，并保持 no-real-command-queue / no-native / no-GPU / no-state / no-public stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real command queue first implementation slice closure / next real command queue decision`

## 下游真实 command queue 封账与 drawable 第一刀

下游 real command queue first slice 已继续完成后续边界、manifest stabilization 与 branch closure：

- [real command queue first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-next-boundary-decision.md)
- [real command queue first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-first-implementation-slice-manifest.md)
- [real command queue first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-command-queue-first-implementation-slice-manifest-stabilization-closure-review.md)
- [real command queue branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-command-queue-branch-next-boundary-decision.md)

下游 real drawable first implementation preflight 与 first slice 已完成：

- [real drawable first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-preflight-decision.md)
- [real drawable first implementation slice closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-internal-renderer-real-drawable-first-implementation-slice-closure-review.md)
- [real drawable first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)

当前下游 endpoint 是 `CjguiInternalRendererNoRealDrawableShellReadiness` / `cjguiInternalExecuteDefaultRendererRealDrawableShellDraft()`。它只消费本 closure 固定的 `CjguiInternalRendererNoRealCommandQueueShellReadiness`，仍不获取 drawable，不调用 `nextDrawable` / `present`，不创建 command buffer，不提交 GPU work，不写 renderer state，不修改 native bridge / Objective-C / Metal / AppKit / FFI，不扩 C ABI / public API。

新的下游后续入口：

`P1 internal Renderer real drawable branch closure / next real drawable decision`
