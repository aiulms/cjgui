# P1 渲染器 native bridge runtime internal FFI declaration 第一实现预检

日期：2026-05-09

状态：preflight / internal-only declaration runway

## 文件定位

本预检判断是否可以把已经由 isolated probe、symbol probe、package-adjacent probe 与 script-managed `cjpm` package link probe 验证过的 no-resource `C ABI`，以 internal-only 的 `foreign func` declaration 形式引入 `runtime/cjgui`。

本预检不批准 public API，不批准 runtime FFI call，不批准 resource callable，不批准 native object，不批准 Metal / AppKit，不批准 backend-ready truth。

## 上游证据

- no-resource callable `C ABI` 已由 callable first implementation manifest 固定，允许清单只有 `cjgui_native_bridge_surface_version`、`cjgui_native_bridge_surface_capabilities`、`cjgui_native_bridge_status_ok` 与 `cjgui_native_bridge_no_resource_admission`。
- isolated FFI probe 已证明仓颉侧可用 `foreign func` 声明四个 no-resource callable，并通过 direct `cjc` link 调用。
- package-adjacent probe 已证明 production no-resource native bridge object / static archive 可在 `runtime/cjgui` 语境旁路 direct `cjc` link 调用。
- script-managed `cjpm` package link probe 已证明临时仓颉 package 可通过 `compile-option` / `link-option` 链接并调用四个 no-resource callable。
- `runtime/cjgui/cjpm.toml` 仍未修改，production `.m` 仍未接入 `runtime/cjgui` 主包，这是当前预期边界。

## 判断

可以打开 runtime internal FFI declaration 第一实现 runway，但第一刀只能是 internal declaration owner 与 no-runtime-call readiness facts。

真实 runtime FFI call 暂缓。原因是主包 package config 仍未接入 production native bridge object / static archive；本阶段若调用 `foreign func`，会把 declaration 路线误读成 runtime package link 已完成。

声明位置不复用旧 `runtime_renderer_native_bridge_ffi_declaration.cj`。旧 owner 的 truth 是 no-actual-FFI-declaration planning facts，若直接翻转该 endpoint，会造成 planning endpoint 与 implementation endpoint 自包裹。第一实现选择新增更窄 owner：`runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`，唯一 runtime input 使用 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。

## 允许第一刀

- 新增 internal owner `runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj`。
- 在该 owner 内声明四个 internal `foreign func`：
  - `cjgui_native_bridge_surface_version`
  - `cjgui_native_bridge_surface_capabilities`
  - `cjgui_native_bridge_status_ok`
  - `cjgui_native_bridge_no_resource_admission`
- 新增 endpoint `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` 与 default draft `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft()`。
- 只表达 internal-only declaration、allowlist、package link requirement、no-runtime-call、no-public-surface facts。

## 仍然禁止

- 不调用 `foreign func`。
- 不新增 runtime FFI call verification owner。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 production native `.h` / `.m` 行为。
- 不新增 public API 或 diagnostics。
- 不调用 resource callable。
- 不创建 native object、native handle、raw pointer 或 pointer return。
- 不导入或调用 Cocoa / Metal / QuartzCore。
- 不写 renderer state，不触碰 `runtime_state.cj`。

## 候选结论

- A 推荐：`P1 internal Renderer runtime internal FFI declaration no-resource first slice`。选择本项，只声明 internal no-resource `foreign func`，不调用。
- B 暂缓：`P1 internal Renderer runtime internal no-resource FFI call verification first slice`。主包 link route 尚未接入，不应本轮调用。
- C fallback：`P1 internal Renderer runtime FFI declaration blocker follow-up`。仅当 `foreign func` declaration 本身导致主包 build 失败时选择。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

本轮选择 A。

## 同形边界刹车

不得把 internal FFI declaration、package link probe、no-resource `C ABI`、direct probe 或 internal readiness facts 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Internal declaration 只证明 runtime 内部能看见 no-resource C ABI 符号名与声明形状，不证明 GUI backend ready。

## 设计意图出口自检

- 本轮是否改变主题状态：是，打开 runtime internal FFI declaration 第一实现 runway。
- 本轮是否改变 canonical tail / endpoint：预期会新增更窄 endpoint `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 owner；truth 限于 internal declaration 与 no-runtime-call facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预期转为 manifest stabilization 或 internal no-resource FFI call verification bundle。
- 是否同步 topic manifest：是，本阶段完成后同步。
- 已同步哪些 topic manifest：待 closure / manifest 完成后同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
