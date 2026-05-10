# P1 内部渲染器 platform object native callable 清单稳定化复核

日期：2026-05-10

状态：manifest closure / value boundary

## 封账结果

[platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md) 已封账。

当前 fixed point：

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_native_callable.cj`
- Runtime input：`CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`
- Native callable list：无新增
- Truth：platform object native callable intent、no-object admission policy、main-thread prerequisite、token issue/revoke prerequisite、teardown policy prerequisite、no-token-return-before-object policy 与 no-public-surface facts。

## 稳定化边界

本轮没有修改 production native `.h/.m`、probe scripts、`runtime/cjgui/cjpm.toml` 或 smoke native files。当前 endpoint 不表示 platform object exists，不允许创建 `NSWindow` / `NSView` / `CAMetalLayer`，不允许导入 Cocoa / AppKit / Metal / QuartzCore，不允许返回 native pointer / handle / platform token。

Same-shape Boundary Brake：platform object native callable admission 不得被包装成 platform object creation permission、native object permission、native handle permission、AppKit permission、Metal permission、backend-ready permission、public API permission、receipt / record / publication。

## 后续入口

唯一后续入口为：

`P1 internal Renderer native bridge teardown callable implementation preflight decision`

该入口只能评估 teardown callable implementation 的必要性、write set、token revoke ordering、destroy denial / implementation split 与 stop-line。

下游 [native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md) 与 [manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-implementation-manifest-stabilization-closure-review.md) 已完成。全局唯一后续入口已经转为 `P1 internal Renderer platform object AppKit import preflight decision`；该入口仍不批准 platform object creation、native object、resource callable、public API、renderer state write 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object native callable stage 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 固定为 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_native_callable.cj`；truth 固定为 no-object admission facts；stop-line 固定为 no platform object / no public API / no renderer state write。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge teardown callable implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
