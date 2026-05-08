# P1 渲染器 native bridge teardown implementation planning 后续边界判断

日期：2026-05-09

状态：docs-only next-boundary / no teardown implementation

## 文件定位

本文件确认 [runtime_renderer_native_bridge_teardown_plan.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_teardown_plan.cj) 是否足够作为当前 no-native-bridge-teardown-implementation endpoint，并决定是否进入 manifest stabilization。

## 判断结论

`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()` 足够作为当前 no-native-bridge-teardown-implementation endpoint。

该 endpoint 只代表 native bridge teardown planning intent、destroy admission guard policy、token invalidation before destroy policy、double-destroy / dangling-token denial policy、main-thread destroy confinement policy、teardown failure classification 与 no-native-bridge-teardown-implementation readiness facts。

它不是 native bridge implementation permission、destroy permission、retain / release permission、native handle permission、raw pointer permission、native pointer return permission、C ABI implementation permission、FFI permission、Metal / AppKit / Objective-C permission、backend-ready permission、GPU-submission permission、render permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 候选比较

A 推荐：`P1 internal Renderer native bridge teardown implementation planning manifest stabilization bundle implementation`。理由是 value boundary 已足够，下一步只应固定 owner / truth / endpoint / stop-line。

B 暂缓：`P1 internal Renderer native bridge first production write-set preflight decision`。需等 manifest stabilization 封账后再进入。

C 暂缓：`P1 internal Renderer native bridge teardown implementation preflight decision`。需等 production write set 冻结后再评估。

D 拒绝：direct retain / release / destroy implementation。

E 拒绝：direct production `.h` / `.m`、C ABI / FFI、native bridge / Objective-C / Metal / AppKit modification。

F 拒绝：direct native handle / raw pointer / native pointer return。

G 拒绝：backend ready truth / renderer state write / GPU submission / public API。

## 同形边界刹车

`CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` 不得继续包装成 native bridge ready、destroy ready、native-handle ready、C-ABI-ready、Metal-ready、backend-ready、GPU-submission ready、render permission、state-write permission、public diagnostics、receipt、record 或 publication wrapper。

下一步若选择 A，只能做 manifest 封账，不新增 tail wrapper。

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

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 value boundary closure 推进到 next-boundary decision completed。
- 本轮是否改变 canonical tail / endpoint：否，继续使用 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，确认当前 owner / truth / stop-line 足够。
- 本轮是否改变唯一 next opening：是，选择 `P1 internal Renderer native bridge teardown implementation planning manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是，随本宏包同步。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge teardown implementation planning manifest stabilization bundle implementation`
