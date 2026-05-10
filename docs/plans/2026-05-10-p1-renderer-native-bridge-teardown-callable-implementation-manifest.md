# P1 内部渲染器 native bridge teardown callable implementation 清单

日期：2026-05-10

状态：manifest stabilization / no-resource callable implementation

## 清单结论

teardown callable implementation stage 已封账，actual route 是 no-resource teardown admission callable first implementation。production native bridge 新增 teardown admission / not-supported / revoke-before-destroy-required / double-destroy classification callable，并由 internal runtime owner 脱水为 facts。

该清单不批准真实 destroy，不批准 retain / release，不批准 native object / handle / pointer，不批准 public API，不批准 AppKit / Metal，不批准 backend-ready truth。

## Native callable list

- `cjgui_native_bridge_teardown_admission(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_destroy_not_supported(void)` -> `int32_t`
- `cjgui_native_bridge_revoke_before_destroy_required(void)` -> `int32_t`
- `cjgui_native_bridge_double_destroy_classify(uint64_t token)` -> `int32_t`

Return contract：

- `-10`：destroy not supported。
- `-11`：revoke before destroy required。
- `-12`：double destroy denied。
- `-13`：dangling / invalid token denied。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- Endpoint：`CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Actual route：internal no-resource FFI call owner
- Observed facts：destroy-not-supported、revoke-before-destroy-required、invalid-token fail-closed、valid-token admission denied until revoke, revoke observed, double-destroy denied, dangling-token denied。

## Probe scripts

- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

这些 scripts 只验证 no-resource callable presence / link / call / classification，不修改 source，不修改 package config，不执行 native lifecycle。

## Actual write set

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- Native probe allowlist scripts
- README / tracker / plans README / runtime README / design intent index / topic manifests
- 本阶段 preflight、closure、next-boundary、manifest 与 manifest closure

`runtime/cjgui/cjpm.toml` 未修改。

## 固定边界

- no actual destroy。
- no retain / release。
- no native object creation。
- no token-to-resource binding。
- no raw pointer storage。
- no native pointer / handle return。
- no `NSWindow` / `NSView` / `CAMetalLayer`。
- no `MTLDevice` / `MTLCommandQueue`。
- no Cocoa / Metal / QuartzCore import。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## 文档链

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-bridge-teardown-callable-implementation-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-next-boundary-decision.md)
- [platform object native callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-native-callable-manifest.md)
- [platform object AppKit import manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-appkit-import-manifest.md)
- [native token table issue/revoke manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [native bridge teardown callable planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md)

## 后续入口

本 manifest 原始唯一后续入口已由 AppKit import / class availability / main-thread admission 与 token-backed creation planning stage 接续：

`P1 internal Renderer platform object no-object AppKit class availability preflight decision`

当前 canonical tail 以 [CAMetalLayer attachment planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-cametallayer-attachment-planning-manifest.md) 为准，唯一后续入口转为 `P1 internal Renderer CAMetalLayer no-attach class/runtime FFI call owner preflight decision`。该入口只能先评估 no-attach class availability / runtime internal call owner；不得创建 `NSWindow` / `CAMetalLayer` / `CALayer`，不得设置 `NSView.layer` / `wantsLayer`，不得创建 `MTLDevice` / `MTLCommandQueue`，不得返回 native pointer / handle，不得新增 public API，不得写 renderer state，不得创建 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable implementation 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_admission_call.cj`；truth 固定为 no-resource teardown admission classification facts；stop-line 固定为 no actual destroy / retain / release / native object / public API。
- 本轮是否改变唯一 next opening：是，该入口已由 AppKit import / class availability / main-thread admission、token-backed creation planning stage、no-object creation callable stage 与 real `NSView` allocation feasibility stage 接续，当前为 `P1 internal Renderer platform object token-backed NSView object table preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
