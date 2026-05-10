# P1 内部渲染器 native token table implementation 清单

日期：2026-05-10

状态：manifest stabilization / value boundary

## 固定对象

- Owner：`runtime/cjgui/src/runtime_renderer_native_token_table_implementation.cj`
- Endpoint：`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`
- Runtime input：`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`
- Actual route：value boundary
- Native token table：无实现
- Native token C ABI：无新增

## table shell policy

future token table shell 若进入 implementation runway，只能作为 production native bridge 私有、bridge-local、opaque-token table shell。

它不得成为 renderer truth source，不得成为 Objective-C truth source，不得暴露到 public API，也不得绕过 resource creation admission、main-thread gate、teardown callable boundary 或 package link boundary。

## no-pointer policy

table entry 只能保存 dehydrated token facts。它不得保存：

- raw pointer。
- native handle。
- Objective-C object identity。
- Metal object identity。
- AppKit object identity。
- renderer state reference。

token ID 不得编码 native pointer，也不得通过 slot / generation / epoch 泄露 pointer-like identity。

## generation / slot / epoch policy

future table shell 必须先定义：

- generation facts。
- slot index facts without pointer leakage。
- epoch invalidation facts。
- stale token fail-closed。
- dangling token fail-closed。
- reuse 前 invalidation。

这些 facts 当前只是 policy，不是 table implementation。

## capacity / failure policy

future table shell 必须先定义 capacity limit 与 allocation failure classification：

- capacity exhausted 必须 fail-closed。
- table disabled 必须输出 dehydrated disabled facts。
- allocation failure 不得转成 public diagnostics。
- wrong-thread mutation 不得被隐式允许。
- main-thread confinement / lock / atomic strategy 必须由后续 preflight 选择。

## runtime facts

Default draft 产出：

- `didConfirmNativeTokenTableImplementationIntent`
- `didConfirmBridgeLocalTableShellPolicy`
- `didConfirmNoPointerTableEntryPolicy`
- `didConfirmGenerationSlotEpochPolicy`
- `didConfirmCapacityAllocationFailureClassification`
- `didConfirmNoActualTokenTableImplementation`
- `didConfirmNoNativeTokenCAbi`
- `didConfirmNoResourceObjectTable`
- `didConfirmNoNativeObjectBinding`
- `didConfirmNoRawPointerStorageOrReturn`
- `didConfirmNoPublicSurface`
- `didConfirmNoResourceCallable`
- `didConfirmNoMetalOrAppKitUsage`
- `didConfirmNoRendererStateWrite`
- `didConfirmNoBackendReadyTruth`

这些 facts 只说明 token table implementation boundary 已固定，不说明 token table exists。

## package / native 状态

- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.h` 未修改。
- `runtime/cjgui/native/cjgui_native_bridge.m` 未修改。
- probe scripts 未修改。
- smoke native files 未修改。
- production `.m` 仍未正式接入主包 package config。

## 停止线

- no native token C ABI。
- no token table implementation。
- no global mutable native table。
- no module-level mutable runtime state。
- no resource object table。
- no native object binding。
- no raw pointer storage。
- no native pointer return。
- no token-as-pointer。
- no native handle。
- no retain / release / destroy。
- no public API / diagnostics。
- no resource callable。
- no production native `.h` / `.m` modification。
- no smoke native edits。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 证据链

- [native token table implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-preflight-decision.md)
- [native token table implementation value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-internal-renderer-native-token-table-implementation-closure-review.md)
- [native token table implementation next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-next-boundary-decision.md)
- [native bridge resource creation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-resource-creation-admission-manifest.md)
- [native token table ownership hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-token-table-ownership-hardening-manifest.md)
- [native bridge native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md)
- [native bridge teardown callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-manifest.md)
- [no-resource runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-no-resource-runtime-ffi-call-owner-manifest.md)

## 后续入口

原定后续入口：

`P1 internal Renderer native token table no-resource shell first implementation preflight decision`

该入口已由 [native token table no-resource shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer native token table no-resource issue/revoke preflight decision`

该入口只能评估 no-resource issue / revoke shell 是否可在 fixed capacity、generation / epoch、main-thread confinement、fail-closed classification、no resource binding、no pointer 与 no public surface 下实现；不得直接创建 resource object table、native object、native handle、raw pointer、AppKit / Metal resource、public API 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table implementation 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_implementation.cj`；truth 固定为 token table implementation intent、bridge-local table shell policy、no-pointer entry policy、generation / slot / epoch policy 与 capacity / failure policy；stop-line 继续禁止 actual table、native object、pointer、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource shell first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
