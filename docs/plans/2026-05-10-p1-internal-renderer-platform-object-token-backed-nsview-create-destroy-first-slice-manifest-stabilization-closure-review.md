# P1 内部渲染器 platform object token-backed NSView create destroy 首片清单稳定收口

日期：2026-05-10

状态：manifest stabilization closure

## 稳定结论

本轮 manifest 已固定 token-backed `NSView` create / destroy first slice 的实际事实、owner、C ABI、probe 证据、link 兼容修复与 stop-line。当前 canonical tail 是 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`。

该稳定收口不改变 `runtime/cjgui/cjpm.toml`，不触碰 smoke native files，不修改 `runtime_state.cj`，不新增 public API，不返回 pointer / handle / `id` / `Class`。

## 固定事实

- Production native bridge 允许固定容量 `4` 的 `NSView` table first slice。
- `NSView` create / destroy 只允许 main thread。
- token 通过 `uint64_t* out_token` 输出，且不编码 pointer。
- classify / stale / invalid / double-destroy 均 fail-closed。
- Runtime owner 只把结果脱水为 internal facts，不公开 token，不写 renderer state。
- package-adjacent 与 `cjpm` package link probes 已实际调用新增 C ABI。
- `-fno-objc-msgsend-selector-stubs` 与 `-lobjc` 只属于 probe/link-script 兼容修复，不进入 `runtime/cjgui/cjpm.toml`。

## 仍然禁止

- `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- Metal / QuartzCore。
- pointer / handle / `id` / `Class` return。
- layer binding / drawable / command buffer / GPU submission。
- renderer state write。
- public API / public diagnostics。
- backend-ready / render-ready truth。

## 唯一后续入口

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

下一轮必须先预检 runtime owner 的 internal call shape 与 package link 关系，不得直接进入 backend ready、renderer state write、Metal layer 或 public API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，create / destroy first slice 从 closure 固定到 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定为 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner、truth 与 stop-line 已由 manifest 固定。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
