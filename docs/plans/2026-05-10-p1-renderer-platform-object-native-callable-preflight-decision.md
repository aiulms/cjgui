# P1 内部渲染器 platform object native callable 预检

日期：2026-05-10

状态：preflight / docs-only / no runtime truth

## 预检结论

选择 A：`P1 internal Renderer platform object native callable admission value boundary bundle`。

当前可以打开 platform object native callable runway，但第一阶段只能是 no-object admission value boundary，不应修改 production native `.h/.m`，不应新增 no-object native callable，更不能创建 `NSWindow` / `NSView` / `CAMetalLayer`。

## 判断

- platform object native callable runway 可以打开，但只能先固定 callable 前置边界。
- 第一阶段只能是 no-object admission callable policy，而不是 AppKit object creation。
- 暂不新增 `cjgui_native_bridge_platform_object_create_admission`、`cjgui_native_bridge_platform_object_create_not_supported` 或 `cjgui_native_bridge_platform_object_requires_main_thread`；避免把 no-object status callable 误读成 resource creation permission。
- 必须继续禁止 `NSWindow` / `NSView` / `CAMetalLayer` creation。
- 当前不需要 AppKit / Cocoa import；如果 future object creation 需要 AppKit，必须单独进入 AppKit import preflight。
- no-object admission 可以先行；真实 teardown callable implementation 仍是 platform object creation 的硬前置之一。
- 不允许 issue token 表示 platform object，因为 token 尚未绑定 object，返回 token 会误导为 resource token。
- 当前只允许 status / classification policy，不返回 token。
- runtime input 选择 `CjguiInternalRendererNoNativeTokenTableIssueRevokeReadiness`，因为它已经固定 main-thread gated token issue/revoke 与 no-resource-binding facts。

## 本轮允许事项

- 新增 `runtime/cjgui/src/runtime_renderer_platform_object_native_callable.cj`。
- 新增 platform object native callable admission value facts。
- 新增 docs / closure / manifest。
- 同步 README、tracker、plans README、runtime README、设计意图索引与 topic manifests。

## 本轮禁止事项

- 不修改 production native `.h/.m`。
- 不新增 platform object native callable。
- 不导入 Cocoa / AppKit / Metal / QuartzCore。
- 不创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不返回 native pointer / handle / object identity。
- 不返回 platform object token。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 public API / diagnostics。
- 不写 renderer state，不触碰 `runtime_state.cj`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，platform object native callable runway 进入 no-object admission value boundary。
- 本轮是否改变 canonical tail / endpoint：是，预期新增 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，预期 owner 为 `runtime_renderer_platform_object_native_callable.cj`；truth 仅限 no-object admission facts；stop-line 继续禁止 platform object creation。
- 本轮是否改变唯一 next opening：是，若 value boundary 通过，转入 manifest stabilization。
- 是否同步 topic manifest：是，随 closure / manifest 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
