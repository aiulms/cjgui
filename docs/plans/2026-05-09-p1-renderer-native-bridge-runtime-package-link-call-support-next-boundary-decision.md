# P1 渲染器 native bridge runtime package link call support 后续走向结论

日期：2026-05-09

状态：docs-only next-boundary / manifest stabilization selected

## 当前端点判断

`CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageCallSupportDraft()` 足够作为当前 no-runtime-package-call-support endpoint。

它只代表 runtime package call support intent、package link call support policy、dylib / object path evidence policy、macOS-only gate、runtime-adjacent probe evidence policy 与 no-runtime-package-call-support readiness facts。

它不是 actual runtime FFI call、runtime callable permission、public API、resource callable、native object、Metal / AppKit、renderer state write 或 backend-ready truth。

## 候选比较

- A 暂缓：`P1 internal Renderer native bridge package config link implementation preflight decision`。这是 manifest 后的唯一后续入口，但当前 value boundary 应先封账。
- B 暂缓：`P1 internal Renderer native bridge internal no-resource runtime FFI call owner preflight decision`。主包 package link support 仍未接入，不应越过 package config gate。
- C 选择：`P1 internal Renderer native bridge runtime package link call support manifest stabilization bundle`。当前 endpoint 足够封账。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

## 选择结果

选择 C，进入 manifest stabilization。

完成 manifest 后的唯一后续入口建议为：

`P1 internal Renderer native bridge package config link implementation preflight decision`

## 同形边界刹车

不得把 package call support endpoint、runtime-adjacent call probe、package link facts、FFI declaration 或 package call support value facts 包装成 actual runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime package link call support 进入 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，确认 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness` 为当前 endpoint。
- 本轮是否改变 owner / truth / stop-line：是，owner / truth / stop-line 由 value boundary 固定。
- 本轮是否改变唯一 next opening：是，manifest 后转为 `P1 internal Renderer native bridge package config link implementation preflight decision`。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：本 decision 尚未同步，后续 manifest 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
