# P1 渲染器 native bridge C ABI surface contract 后续边界决策

日期：2026-05-09

状态：完成 / docs-only next-boundary decision / no C ABI implementation

## 文件定位

本文件收束 `P1 internal Renderer native bridge C ABI surface contract next-boundary decision`。本轮确认 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()` 是否足够作为当前 no-native-bridge-C-ABI-surface endpoint。

本轮不修改 `.cj`，不新增 runtime owner，不新增 production `.h` / `.m`，不修改 smoke native 文件，不实现 C ABI / FFI，不创建 native handle、Metal resource、backend ready truth、GPU submission、render、renderer state write 或 public API。

## 当前 endpoint 判断

`CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()` 足够作为当前 no-native-bridge-C-ABI-surface endpoint。

该 endpoint 只代表：

- native bridge C ABI surface intent。
- production bridge write-set policy。
- C ABI category admission policy。
- native status dehydration policy。
- no-native-bridge-C-ABI-surface readiness facts。

它不是 native bridge implementation permission、C ABI implementation permission、native-handle permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 后续选择

候选 A 胜出：`P1 internal Renderer native bridge C ABI surface contract manifest stabilization bundle implementation`。

选择 A 的原因是新增 owner 已经通过 build 与 smoke 兜底，且当前需要先固定 owner / runtime input / endpoint / default draft / truth / stop-line。下一步仍是 docs-only manifest stabilization，不新增第二个 runtime owner，不靠近 native bridge implementation。

候选 B 暂缓：native handle token ownership planning preflight。它是 manifest 后的合理下一阶段，但不能跳过本 owner manifest 封账。

候选 C 暂缓：native bridge teardown / destroy implementation preflight。它仍依赖 surface contract 与 handle token ownership 先固定。

候选 D 拒绝：直接进入 production `.h` / `.m`、C ABI / FFI、Objective-C / Metal / AppKit implementation。

候选 E 拒绝：继续把 no-native-bridge-C-ABI-surface endpoint 包装成 receipt / record / publication 或 permission wrapper。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 包装成 native bridge ready、C ABI ready、native-handle ready、Metal ready、backend-ready、GPU-submission ready、render permission、public API permission、receipt、record 或 publication。

下一步只能固定 owner / truth / canonical endpoint / stop-line，不新增 tail wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
- no render pass / encoder / pipeline / draw call。
- no `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API / C ABI expansion。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no retain / release / destroy。
- no module-level mutable `var`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 value boundary landed 推进到 next-boundary completed。
- 本轮是否改变 canonical tail / endpoint：否，确认 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeCAbiSurfaceDraft()` 足够作为当前 endpoint。
- 本轮是否改变 owner / truth / stop-line：否，owner / truth / stop-line 仍由 value boundary closure 固定。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge C ABI surface contract manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge C ABI surface contract manifest stabilization bundle implementation`

## 下游 native handle token ownership 封账

下游 native handle token ownership macro 已完成，确认 C ABI surface endpoint 足以作为 token ownership value boundary 的上游 input，但不把它升格为 C ABI implementation、native bridge implementation、native handle permission、raw pointer permission、Metal permission、backend-ready permission、GPU submission、render、renderer state write 或 public API permission。

新的下游后续入口：

`P1 internal Renderer native bridge teardown implementation planning preflight decision`
