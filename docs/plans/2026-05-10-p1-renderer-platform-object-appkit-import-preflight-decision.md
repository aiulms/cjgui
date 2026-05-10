# P1 内部渲染器 platform object AppKit import 预检

日期：2026-05-10

状态：implementation preflight / AppKit import boundary

## 预检结论

可以打开 production native bridge 的 AppKit import boundary runway，选择：

`P1 internal Renderer platform object AppKit import boundary bundle`

本轮只允许把 AppKit 作为 compile/import boundary 纳入 production bridge，并新增 no-object capability / admission callable。该路线不创建窗口、视图、layer、Metal device、command queue 或任何 native object，不返回 pointer / handle，不新增 public runtime API，不写 renderer state。

## 证据输入

- 最新 teardown admission endpoint 是 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。
- teardown admission callable 已固定 destroy-not-supported、revoke-before-destroy-required、invalid / dangling token fail-closed 与 double-destroy denied facts。
- platform object native callable 仍停在 no-object admission boundary，没有新增 platform object creation callable。
- main-thread query 已通过 `pthread_main_np()` 只提供 current-thread classification facts。
- token issue / revoke 只生成 bridge-local opaque token，不绑定 native object，不保存 pointer。
- smoke native files 只能作为参考，不复制实现，不成为 production runtime truth。

## AppKit import 路线

本轮允许在 production bridge `.m` 中直接 `#import <AppKit/AppKit.h>`，理由如下：

- 当前目标是验证 AppKit header import / Objective-C compile feasibility，不调用 AppKit class 或 function。
- production bridge 仍不创建 AppKit object，因此不需要对象 lifecycle、retain / release 或 destroy path。
- 现有 isolated compile、package-adjacent link 与 temporary `cjpm` package probe 都可验证 import 后的 object / static archive link 结果。
- `runtime/cjgui/cjpm.toml` 仍不修改，production `.m` 仍不接入主包 package config。

本轮不选择 isolated AppKit import probe 作为唯一路线，因为 existing production bridge 已经具备 isolated skeleton compile、object-level symbol probe、direct `cjc` link probe 与 temporary `cjpm` package link probe；只要新增 forbidden scan 保持 no-object，就能复核 import boundary。

## 允许的 no-object callable

本轮允许新增以下 no-object callable：

- `cjgui_native_bridge_appkit_import_available(void)`：只返回 AppKit import boundary availability fact。
- `cjgui_native_bridge_appkit_no_object_admission(void)`：只返回 no-object admission fact。
- `cjgui_native_bridge_platform_object_create_still_blocked(void)`：只返回 platform object creation still blocked classification。

这些 callable 只返回整数，不返回 token、pointer、handle 或 object identity。

## 仍然禁止

- 禁止创建 `NSWindow` / `NSView` / `CAMetalLayer` / `CALayer`。
- 禁止创建 `MTLDevice` / `MTLCommandQueue`。
- 禁止导入或使用 Metal / QuartzCore。
- 禁止调用 resource creation callable。
- 禁止返回 native pointer / handle。
- 禁止 token 绑定 native object。
- 禁止 retain / release / destroy。
- 禁止 drawable / command buffer / `commit` / `present`。
- 禁止 GPU submission / render execution。
- 禁止 public API / diagnostics。
- 禁止 `runtime_state.cj` 修改。
- 禁止 smoke native file 修改。
- 禁止 backend-ready truth。

## Runtime owner 授权

若 native import 与 callable probe 通过，本轮允许新增：

- `runtime/cjgui/src/runtime_renderer_platform_object_appkit_import.cj`

建议 endpoint：

- `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`

建议 default draft：

- `cjguiInternalExecuteDefaultRendererPlatformObjectAppKitImportDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`

该 owner 只允许调用 no-object AppKit import callable 并脱水为 internal facts；不得 public，不得写 state，不得创建 object。

## Probe 更新策略

需要新增或更新：

- AppKit import / no-object probe，验证 import available、no-object admission 与 platform object still blocked。
- skeleton compile / symbol probe allowlist。
- package-adjacent link probe 与 temporary `cjpm` package link probe observed facts。
- no-resource call probe 的 owner/source check 与 observed facts。

Forbidden scan 需要改为：允许 direct AppKit import，但继续禁止 Cocoa、Metal、QuartzCore、window/view/layer object token、Metal device / queue、pointer / handle、retain / release / destroy 与 resource creation behavior。

## GitNexus 预检

编辑 runtime symbol 前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。
- `cjgui_native_bridge_surface_capabilities`：GitNexus 返回 not found / UNKNOWN，`impactedCount=0`。

这些符号属于近期新增 runtime / native surface，当前索引未收录。未出现 HIGH / CRITICAL；本轮继续使用源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object AppKit import runway 从 preflight 进入 import boundary implementation。
- 本轮是否改变 canonical tail / endpoint：预检阶段暂未改变，若实现成功将新增 `CjguiInternalRendererNoPlatformObjectAppKitImportReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检阶段暂未改变 owner，truth 选择 AppKit import / no-object callable facts；stop-line 继续禁止 AppKit object、Metal / QuartzCore、pointer / handle、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：预检阶段暂未最终改变，若实现通过将转为 manifest stabilization。
- 是否同步 topic manifest：将在 closure 与 manifest 阶段同步。
- 已同步哪些 topic manifest：预检阶段待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
