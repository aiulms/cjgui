# P1 内部渲染器 platform object native callable 复核

日期：2026-05-10

状态：closure review / value boundary

## 实施结果

已新增 `runtime/cjgui/src/runtime_renderer_platform_object_native_callable.cj`。

本轮选择 value boundary route，没有修改 production native `.h/.m`，没有新增 platform object native callable，也没有导入 Cocoa / AppKit / Metal / QuartzCore。

## Owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_native_callable.cj`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`

## Truth

该 owner 只固定：

- platform object native callable intent。
- no-object admission policy。
- main-thread prerequisite policy。
- token issue/revoke prerequisite policy。
- teardown policy prerequisite。
- no-token-return-before-object policy。
- no-platform-object-native-callable readiness facts。

这些 facts 不表示 platform object exists。

## GitNexus 结果

编辑 runtime symbol 前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`：`UNKNOWN / not found`，impactedCount 0。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableIssueRevokeDraft`：`UNKNOWN / not found`，impactedCount 0。

按近期新增 owner 未索引处理，并继续用源码、build、probe 与 forbidden scan 兜底；未出现 HIGH / CRITICAL 风险。

## 停止线

- 没有新增 native C ABI。
- 没有创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 没有创建 `MTLDevice` / `MTLCommandQueue`。
- 没有返回 token / native pointer / native handle。
- 没有绑定 token 到 native object。
- 没有调用 retain / release / destroy。
- 没有修改 `runtime/cjgui/cjpm.toml`。
- 没有新增 public API / diagnostics。
- 没有写 renderer state。

Same-shape Boundary Brake：platform object native callable admission 不得被包装成 platform object creation permission、native object permission、AppKit permission、Metal permission、backend-ready permission、public API permission、receipt / record / publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object native callable 进入 no-object admission value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner 与 no-object admission truth。
- 本轮是否改变唯一 next opening：是，转为 platform object native callable manifest stabilization。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
