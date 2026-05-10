# P1 内部渲染器 platform object token-backed NSView create destroy 首片预检

日期：2026-05-10

状态：preflight decision / 选择极窄 first slice

## 预检结论

本轮选择 `P1 internal Renderer platform object token-backed NSView create/destroy first slice bundle`。允许在 production native bridge 内实现固定容量、main-thread confined 的 `NSView` create / destroy 首片，但只允许用 opaque token 表示对象身份，不向仓颉层返回 pointer / handle / `id` / `Class`。

该选择建立在上游已经封账的证据链之上：AppKit import 可编译、`NSView` class availability 可观察、AppKit platform object main-thread admission 可观察、isolated `NSView` allocation feasibility 通过、no-allocation `NSView` table shell 通过、token issue/revoke 有 generation / stale fail-closed 机制、teardown admission 已有 revoke-before-destroy 与 double-destroy fail-closed classification。

如果实现或 probe 发现 destroy / ownership / stale-token / main-thread 语义不稳，必须回退为 planning/value boundary，不得伪造 manifest 封账。

## 判断记录

- 是否允许 production native 创建并持有 `NSView`：允许极窄首片，且只在固定容量 table 内保存 `NSView*`，不返回对象身份。
- capacity 是否固定且很小：沿用 `CJGUI_NATIVE_BRIDGE_NSVIEW_TABLE_CAPACITY = 4u`。
- token 是否仍是不透明整数：是，token 继续来自 bridge-local token table 的 slot + generation，不编码 pointer bits。
- create 是否必须 main-thread：是，非主线程 fail-closed。
- destroy 是否必须 main-thread：是，非主线程 fail-closed。
- double-destroy / stale-token / invalid-token 如何 fail-closed：invalid token 返回 invalid/dangling classification；destroy 后 token 先从 `NSView` table 解绑并 revoke，旧 token 进入 stale；double destroy classification 返回 double-destroy denied。
- revoke-before-destroy 与 destroy-before-revoke 的顺序如何分类：`NSView` destroy 首片执行 destroy-before-revoke，先释放/清空 `NSView` table entry，再 revoke token；teardown admission 仍保留 revoke-before-destroy-required 作为 broader resource path 的 fail-closed policy，不被解释成真实通用 destroy。
- 是否需要 autorelease pool：create / destroy probe 和 native implementation 均可使用 `@autoreleasepool` 包住 `NSView` allocation / cleanup，避免临时对象逃逸。
- 是否会触碰 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer` / Metal / QuartzCore：不会；禁止 import Metal / QuartzCore，禁止创建 window / application / layer。

## 允许写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_create_destroy.sh`
- 必要的 native probe allowlist / symbol / package link / no-resource call script 维护
- 本阶段 closure、next-boundary、manifest、manifest closure 与索引同步文档

默认仍不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不触碰 `runtime_state.cj`。

## Native C ABI 首片

允许新增：

- `cjgui_native_bridge_nsview_create(uint64_t* out_token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_token_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_table_occupied_count(void)` -> `uint32_t`
- `cjgui_native_bridge_nsview_double_destroy_classify(uint64_t token)` -> `int32_t`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread(void)` -> `int32_t`

返回值只允许是 `int32_t` / `uint32_t` status 或 classification。`uint64_t* out_token` 只用于输出 opaque token；不得返回 pointer / handle / `id` / `Class`。

## Runtime owner 首片

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness`

Owner 只允许调用 create / classify / destroy / classify / double-destroy classification / occupied-count callable，并把结果脱水成 internal facts。不得 public，不得写 state。

## GitNexus 预检

- `CjguiInternalRendererNoPlatformObjectNsViewObjectTableReadiness` impact：UNKNOWN / not found，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewObjectTableDraft` impact：UNKNOWN / not found，`impactedCount=0`。
- `cjgui_native_bridge_surface_capabilities` impact：UNKNOWN / not found，`impactedCount=0`。

这些 owner / native symbols 属近期新增链路，GitNexus 未索引；本轮用源码、构建、probe、forbidden scan 与 `detect_changes(scope=unstaged)` 兜底。若 detect_changes 出现 HIGH / CRITICAL，停止。

## 停止线

- 不返回 native pointer / handle / `id` / `Class`。
- token 不得编码 pointer。
- 不创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 不 import Metal / QuartzCore。
- 不设置 layer / `wantsLayer`。
- 不接 renderer state。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不触碰 `runtime_state.cj`。
- 不把 `NSView` token 解释成 backend-ready truth、render permission、renderer state write permission 或 Metal layer permission。

## 设计意图出口自检

- 本轮是否改变主题状态：预期是，进入 token-backed `NSView` create / destroy first slice。
- 本轮是否改变 canonical tail / endpoint：预期是，若实现成功固定 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期是，新增 create / destroy owner；truth 只限 token-backed `NSView` create / destroy facts；stop-line 继续禁止 pointer / public / window / layer / Metal / renderer state。
- 本轮是否改变唯一 next opening：预期是，若成功转为 `P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：将在 closure / manifest 同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
