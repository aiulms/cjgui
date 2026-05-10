# P1 内部渲染器 platform object token-backed NSView create destroy 首片收口复核

日期：2026-05-10

状态：closure review / first slice 完成

## 收口结论

本轮按 preflight 选择 production first slice。Production native bridge 现在可以在固定容量、main-thread confined 的 `NSView` table 内创建并持有极窄 `NSView`，并只通过 opaque `uint64_t` token 表示对象身份；仓颉层不接收 pointer / handle / `id` / `Class`。

该阶段只证明 token-backed `NSView` create / classify / destroy 首片可以 fail-closed 运行。它不批准 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`，不批准 Metal / QuartzCore，不批准 renderer state write，不批准 backend-ready truth，不批准 public API。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_create_destroy.sh`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- package link / cjpm package link / no-resource call / symbol / skeleton probe 维护
- 本阶段 preflight、closure、next-boundary、manifest、manifest closure
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / 三个 topic manifest
- NSView object table、feasibility、no-object creation、token issue/revoke 与 teardown admission 相关文档 downstream 指向

未修改：

- `runtime/cjgui/cjpm.toml`
- smoke native files
- `runtime/cjgui/src/runtime_state.cj`

## Native callable

- `cjgui_native_bridge_nsview_create(uint64_t* out_token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_occupied_count(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread(void)` -> `int32_t`

返回与分类：

- `0`：create / destroy 成功。
- `40`：token 当前绑定 `NSView`。
- `-40`：create 需要 main thread。
- `-41`：destroy 需要 main thread。
- `-42`：invalid token fail-closed。
- `-43`：destroyed / stale token fail-closed。
- `-44`：token 未绑定 `NSView`。
- `-45`：固定容量耗尽。
- `-46`：double destroy denied。
- `-47`：allocation failed。
- `-48`：`out_token` 缺失。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`
- Truth：只表达 main-thread create / classify / destroy / stale / double-destroy / invalid-token / occupied-count facts，不写 renderer state，不公开 token，不返回 native identity。

## Probe 证据

- 新 probe：`runtime/cjgui/native/scripts/verify_native_bridge_nsview_create_destroy.sh`
- 输出目录：`/tmp/cjgui-native-bridge-nsview-create-destroy-*`
- 已观察：`main_thread_create_observed=true`、`token_classify_valid_observed=true`、`occupied_count_observed=true`、`background_destroy_denied_observed=true`、`destroy_observed=true`、`destroyed_stale_observed=true`、`double_destroy_fail_closed_observed=true`、`invalid_token_fail_closed_observed=true`、`background_create_denied_observed=true`、`destroy_requires_main_thread_observed=true`、`token_not_pointer_observed=true`。
- 已确认：`window_created=false`、`application_created=false`、`layer_created=false`、`metal_quartzcore_imported=false`、`pointer_returned=false`、`native_handle_returned=false`。
- 结果：`success=true reason=none`。

## Link 与构建补账

- package-adjacent link probe 与 `cjpm` package link probe 已补充实际调用 `NSView` create / classify / destroy C ABI，并观察 `nsview_create_observed=true`、`nsview_token_valid_observed=true`、`nsview_destroy_observed=true`、`nsview_destroyed_stale_observed=true`、`nsview_double_destroy_observed=true`、`nsview_invalid_destroy_observed=true`、`nsview_destroy_requires_main_thread_observed=true`、`nsview_occupied_count_observed=true`。
- ObjC selector stub 兼容：probe 编译增加 `-fno-objc-msgsend-selector-stubs`，Cangjie link flags 增加 `-lobjc`；这是脚本级 link 兼容修复，不修改 `runtime/cjgui/cjpm.toml`。
- `cjpm build --skip-script` 通过，说明新增 runtime owner 可编译；既有 unused warnings 不构成失败。

## 停止线

- no pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- no Metal / QuartzCore import。
- no `wantsLayer` / layer binding。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public API / diagnostics。
- no smoke native edits。
- no backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，token-backed `NSView` 从 table shell 推进到 create / destroy first slice。
- 本轮是否改变 canonical tail / endpoint：是，新增并固定为 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_platform_object_nsview_create_destroy.cj`；truth 只限 token-backed `NSView` lifecycle facts；stop-line 继续禁止 pointer / public / window / layer / Metal / renderer state / backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游接续

下游 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md) 已完成，并把 canonical tail 推进为 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`。该下游只复用既有 internal `foreign func` declarations，不新增 public API，不返回 pointer / handle / `Class` / `id`，不创建 window / layer / Metal，也不写 renderer state。
