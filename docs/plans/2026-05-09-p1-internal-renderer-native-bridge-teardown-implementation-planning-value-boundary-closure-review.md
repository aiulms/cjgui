# P1 渲染器 native bridge teardown implementation planning value boundary closure

日期：2026-05-09

状态：完成 / internal value boundary / no teardown implementation

## 文件定位

本 closure 收束 `P1 internal Renderer native bridge teardown implementation planning value boundary bundle implementation`。

本轮新增 [runtime_renderer_native_bridge_teardown_plan.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj)，但不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer，不调用 retain / release / destroy，不实现 destroy callback，不写 renderer state，不发布 public diagnostics 或 public API。

## 落地内容

新增 runtime owner：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj`。

唯一 runtime input：`CjguiInternalRendererNoNativeHandleTokenReadiness`。

Canonical endpoint：`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`。

Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。

新增 internal facts：

- `CjguiInternalRendererNativeBridgeTeardownPlanningIntent`
- `CjguiInternalRendererDestroyAdmissionGuardPolicy`
- `CjguiInternalRendererTokenInvalidationBeforeDestroyPolicy`
- `CjguiInternalRendererNativeBridgeTeardownSafetyDenialPolicy`
- `CjguiInternalRendererMainThreadDestroyConfinementPolicy`
- `CjguiInternalRendererNativeBridgeTeardownFailureClassification`
- `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness`

## 封闭语义

该 owner 只表达 native bridge teardown planning intent、destroy admission guard policy、token invalidation before destroy policy、double-destroy / dangling-token denial policy、main-thread destroy confinement policy、teardown failure classification 与 no-native-bridge-teardown-implementation readiness facts。

open path 只能形成 dehydrated planning facts；defer-only 保持 defer；blocked / inconsistent fail-closed。

## GitNexus 影响

编辑前已对上游入口执行 GitNexus impact：

- `CjguiInternalRendererNoNativeHandleTokenReadiness`：UNKNOWN / not found，impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft`：UNKNOWN / not found，impactedCount `0`。

判断：这符合近期新增 owner 尚未索引的情况，无 HIGH / CRITICAL 告警；本轮继续用源码、build、smoke 与扫描兜底。

## 同形边界刹车

本轮没有把 token ownership、C ABI surface contract、smoke lab、Metal reference pack、native teardown hardening manifest 或 teardown planning value facts 包成 native bridge implementation permission、destroy permission、native-handle permission、C ABI implementation permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no retain / release / destroy。
- no destroy callback implementation。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no module-level mutable `var`。

## 验证记录

最终 build、smoke、文档链接、protected path、public declaration、owner header / stop-line、native file forbidden 与 GitNexus detect_changes 结果由 manifest stabilization closure 汇总。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 preflight completed 推进到 value boundary implemented。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner file、runtime input、current truth 与 no-teardown-implementation stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge teardown implementation planning closure / next teardown planning decision`。
- 是否同步 topic manifest：是，随本宏包同步。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge teardown implementation planning closure / next teardown planning decision`
