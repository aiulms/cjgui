# P1 内部渲染器 native bridge teardown callable implementation 清单稳定化复核

日期：2026-05-10

状态：manifest closure / stop after manifest

## 封账结论

[native bridge teardown callable implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md) 已封账。

当前 fixed point：

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Endpoint：`CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`
- Native callable list：`cjgui_native_bridge_teardown_admission`、`cjgui_native_bridge_destroy_not_supported`、`cjgui_native_bridge_revoke_before_destroy_required`、`cjgui_native_bridge_double_destroy_classify`
- Truth：no-resource teardown admission / destroy-not-supported / revoke-before-destroy-required / double-destroy / dangling-token classification facts。

## 稳定化边界

本轮实现没有执行真实 destroy，没有调用 retain / release，没有绑定 token 到 native object，没有返回 native pointer / handle，没有新增 public API / diagnostics，没有写 renderer state，没有触碰 `runtime_state.cj`，没有修改 smoke native files，没有导入 Cocoa / Metal / QuartzCore，没有创建 AppKit / Metal object。

Same-shape Boundary Brake：teardown admission callable 不得被包装成 actual destroy permission、native object permission、resource creation permission、native handle permission、AppKit / Metal permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 验证口径

Manifest closure 采用以下证据口径：

- Native teardown admission probe 必须观察 destroy-not-supported、revoke-before-destroy-required、invalid token fail-closed、valid token admission denied、revoke observed、double-destroy denied、dangling token denied。
- Runtime-adjacent no-resource call probe 必须观察 teardown admission owner source 与 package link probe facts。
- `cjpm build --skip-script` 必须通过，且不要求 `runtime/cjgui/cjpm.toml` 接入 production `.m`。
- Forbidden scan 必须继续拒绝 smoke native edits、public API、actual destroy / retain / release、resource callable creating object、token-as-pointer、native object、Cocoa / Metal / QuartzCore、`runtime_state.cj` touch。

## 后续入口

唯一后续入口：

`P1 internal Renderer platform object no-object AppKit class availability preflight decision`

该入口已由 AppKit import stage 接续。下一轮必须先做 docs-only preflight，评估是否允许 no-object AppKit class availability query。该入口不继承本轮为 resource creation permission；不得直接创建 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer`、`MTLDevice` / `MTLCommandQueue`，不得返回 native pointer / handle，不得新增 public API，不得执行 render / GPU submission，不得写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge teardown callable implementation 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_admission_call.cj`；truth 固定为 no-resource teardown classification facts；stop-line 固定为 no actual destroy / no native object / no public API / no renderer state write。
- 本轮是否改变唯一 next opening：是，该入口已由 AppKit import stage 接续，当前为 `P1 internal Renderer platform object no-object AppKit class availability preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
