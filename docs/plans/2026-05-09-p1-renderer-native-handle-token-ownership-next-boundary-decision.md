# P1 渲染器 native handle token ownership 后续边界裁定

日期：2026-05-09

状态：docs-only next-boundary / no native handle implementation

## 文件定位

本 decision 承接 [native handle token ownership value boundary closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-handle-token-ownership-value-boundary-closure-review.md)，确认当前 no-native-handle-token endpoint 是否足够作为阶段性 shell endpoint。

## 裁定结论

`CjguiInternalRendererNoNativeHandleTokenReadiness` / `cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()` 足够作为当前 no-native-handle-token endpoint。

该 endpoint 只代表 native handle token ownership intent、opaque token admission policy、token ownership domain policy、token invalidation / revocation policy、double-release / dangling pointer denial policy 与 no-native-handle-token readiness facts。它不是 native handle permission、raw pointer permission、native bridge implementation permission、C ABI implementation permission、FFI permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、public diagnostics permission 或 public API permission。

## 候选取舍

A 推荐：`P1 internal Renderer native handle token ownership manifest stabilization bundle implementation`

理由：owner、runtime input、endpoint、default draft、truth 与 stop-line 已经由 value boundary 固定，下一步应先 manifest 封账，而不是直接进入 native bridge teardown implementation planning 或 production native write set。

B 暂缓：`P1 internal Renderer native bridge teardown implementation planning preflight decision`

C 暂缓：`P1 internal Renderer native bridge implementation write-set preflight decision`

D 拒绝：direct native handle / raw pointer creation

E 拒绝：direct C ABI / FFI implementation

F 拒绝：direct native bridge / Objective-C / Metal / AppKit modification

G 拒绝：direct backend-ready truth / renderer state write / public API

H 拒绝：receipt / record / publication wrapper

## 同形边界刹车

`CjguiInternalRendererNoNativeHandleTokenReadiness` 不得继续包装成 token-ready、native-handle-ready、bridge-ready、C-ABI-ready、Metal-ready、backend-ready、GPU-submission-ready、render-ready、public diagnostics、receipt、record 或 publication。

下一步若选择 A，只能固定 owner / truth / endpoint / stop-line，不得新增 tail wrapper。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no backend ready truth。
- no backend object。
- no `MTLDevice` / `CAMetalLayer` / `MTLCommandQueue`。
- no drawable / `nextDrawable`。
- no command buffer / `commandBuffer`。
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

- 本轮是否改变主题状态：是，从 value boundary closure 推进到 next-boundary completed。
- 本轮是否改变 canonical tail / endpoint：否，仍为 `CjguiInternalRendererNoNativeHandleTokenReadiness` / `cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，本轮只裁定下一步 manifest stabilization。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native handle token ownership manifest stabilization bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native handle token ownership manifest stabilization bundle implementation`
