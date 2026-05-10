# P1 内部渲染器 platform object token-backed NSView create destroy 首片下一段入口

日期：2026-05-10

状态：next boundary / first slice 完成

## 结论

本轮完成 token-backed `NSView` create / destroy first slice。Production native bridge 只在 main thread 创建和销毁固定容量 table 内的 `NSView`，并通过 opaque token 与 fail-closed classification 暴露内部事实。

唯一下一段入口：

`P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`

## 选择理由

- `NSView` create / classify / destroy 已由 production native probe 覆盖，并由 package-adjacent / `cjpm` package link probe 通过 Cangjie FFI 实际调用。
- Runtime owner 已存在并可由 `cjpm build --skip-script` 编译。
- token 仍是不透明整数，且 probe 观察到 token 非 pointer-like。
- destroy / stale / double-destroy / invalid-token 均 fail-closed。
- 下一步应只评估 runtime package 内是否要暴露更窄的 internal call owner facts，不应直接进入 window、layer、Metal 或 renderer state。

## 拒绝项

- 拒绝返回 pointer / handle / `id` / `Class`。
- 拒绝创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 拒绝 Metal / QuartzCore。
- 拒绝 layer binding / drawable / command buffer / GPU submission。
- 拒绝 public API / public diagnostics。
- 拒绝 renderer state write / backend-ready truth。
- 拒绝把 `NSView` token 当作 render-ready 或 platform backend ready。

## 设计意图出口自检

- 本轮是否改变主题状态：是，create / destroy 首片完成 next-boundary。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 token-backed `NSView` create / destroy facts；stop-line 禁止 pointer / public / window / layer / Metal / state / backend-ready。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer platform object NSView runtime FFI call owner preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 下游接续

该入口已由 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md) 接续并封账。当前唯一后续入口转为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
