# P1 内部渲染器 native bridge resource creation admission 预检结论

日期：2026-05-10

状态：docs-only preflight / choose value boundary

## 预检问题

本轮从 [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md) 出发，评估是否可以打开 resource creation admission runway。

当前上游事实已经具备：

- no-resource callable C ABI 与 internal no-resource FFI call facts。
- main-thread no-resource callable 与 current-thread classification facts。
- native token callable planning facts。
- native token table ownership hardening facts。
- teardown callable planning facts。

这些事实足够进入 resource creation admission 的 value boundary，但不足以实现 native resource callable，也不足以创建 native object。

## 路线判断

本轮选择 A：

`P1 internal Renderer native bridge resource creation admission value boundary bundle`

理由：

- resource creation admission 只定义 future resource creation 的前置条件，不等于 resource creation permission。
- token table 仍未实现，因此不能安全 issue / validate / revoke future resource token。
- teardown callable 仍未实现，因此不能保证 future resource lifecycle 有实际 destroy / revoke 闭环。
- 当前只允许记录 main-thread gate、token table prerequisite、teardown callable prerequisite 与 token-return-only future policy。
- 若直接实现 platform object / Metal device-layer / command queue / window / view callable，会突破本轮 stop-line。

## future resource 分类

future resource creation 的候选顺序应保持 admission-first：

- platform object admission。
- Metal device-layer admission。
- command queue admission。
- window / view admission。

本轮不选择任何一类 resource 的 implementation。它们都必须等待独立 preflight，并且不得绕过 token table、teardown callable 与 main-thread gate。

## 前置条件

后续若要靠近 resource creation callable，至少需要：

- main-thread gate observed facts 继续可用。
- token table implementation 或等价 fail-closed token lifecycle 方案完成 preflight。
- teardown callable implementation 或等价 no-destroy blocker 完成 preflight。
- future callable 只能返回 opaque token / dehydrated status，不得返回 pointer。
- package / link / FFI 路线仍保持 internal-only，不扩 public API。

## 当前停止线

- no native resource C ABI。
- no native resource callable。
- no native object。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no native handle / raw pointer。
- no native pointer return。
- no token table implementation。
- no retain / release / destroy。
- no public API / diagnostics。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 拒绝项

- B 暂缓：`P1 internal Renderer native token table implementation preflight decision`。它很可能是后续硬前置，但本轮先封 resource creation admission boundary。
- C 暂缓：`P1 internal Renderer native bridge teardown callable implementation preflight decision`。teardown implementation 仍不能在本轮打开。
- D 暂缓：`P1 internal Renderer platform object native callable preflight decision`。只有 token/table/teardown/resource admission 链稳定后才可评估。
- E 拒绝：direct native object creation / AppKit / Metal / public API。

## GitNexus impact

编辑 runtime owner 前，对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`：GitNexus 返回 UNKNOWN / not found，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft`：GitNexus 返回 UNKNOWN / not found，`impactedCount=0`。

按近期新增 owner 尚未被索引记录，继续用源码、build、probe 与 forbidden scan 兜底；未出现 HIGH / CRITICAL 风险。

## 设计意图出口自检

- 本轮是否改变主题状态：是，resource creation admission runway 进入 value boundary。
- 本轮是否改变 canonical tail / endpoint：预期改变为 `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 `runtime_renderer_native_resource_creation_admission.cj`，truth 限于 admission prerequisite facts，stop-line 继续禁止 resource creation。
- 本轮是否改变唯一 next opening：预期转为 `P1 internal Renderer native token table implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：执行后同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
