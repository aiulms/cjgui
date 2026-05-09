# P1 渲染器 native bridge callable C ABI 第一实现后续边界判断

日期：2026-05-09

状态：next-boundary decision / no-resource callable only

## 文件定位

本文件判断第一批 no-resource callable `C ABI` 是否足够作为当前 production native callable surface endpoint，并选择下一步是否进入 manifest stabilization。

它不批准 runtime FFI declaration，不批准 native object creation，不批准 AppKit / Metal，不批准 public API，也不把 callable surface 解释为 runtime bridge ready。

## 当前确认

当前 production native skeleton 已允许并实现四个 no-resource callable：

- `cjgui_native_bridge_surface_version(void)`
- `cjgui_native_bridge_surface_capabilities(void)`
- `cjgui_native_bridge_status_ok(void)`
- `cjgui_native_bridge_no_resource_admission(void)`

probe 脚本已更新 allowlist，确认只有上述 callable 可以出现；仍扫描 forbidden smoke names、Cocoa / Metal / QuartzCore import、AppKit / Metal object token、drawable / command buffer / commit / present 等禁止项。

## 候选比较

- A 推荐：`P1 internal Renderer native bridge callable C ABI first implementation manifest stabilization bundle`。选择该项，因为第一批 callable 已足够封账，且下一步应固定 allowed callable list、probe scripts 与 no-FFI stop-line。
- B 暂缓：runtime FFI declaration preflight。暂缓到 manifest 封账后。
- C 暂缓：main-thread callable implementation preflight。暂缓，因为本轮未引入平台线程依赖。
- D 暂缓：native handle token callable preflight。暂缓，因为当前 callable 不返回 token / handle / pointer。
- E 拒绝：direct AppKit / Metal object creation。
- F 拒绝：public API / renderer state write。

## 结论

选择 A：`P1 internal Renderer native bridge callable C ABI first implementation manifest stabilization bundle`。

本结论只允许进入 docs-only manifest stabilization，不允许直接接 runtime FFI，不允许新增 `.cj` FFI declaration，不允许创建 native object，不允许返回 pointer，不允许修改 build config，不允许暴露 public runtime API。

## 同形边界刹车

不得把 no-resource callable `C ABI` 包装成 FFI permission、runtime callable permission、native bridge implementation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，callable `C ABI` first implementation 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，runtime planning endpoint 不变；production native callable list 成为当前 artifact endpoint。
- 本轮是否改变 owner / truth / stop-line：是，truth 固定为 no-resource callable surface；stop-line 继续禁止 FFI、native object、pointer return、AppKit / Metal、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI first implementation manifest stabilization bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 后续入口

`P1 internal Renderer native bridge callable C ABI first implementation manifest stabilization bundle`
