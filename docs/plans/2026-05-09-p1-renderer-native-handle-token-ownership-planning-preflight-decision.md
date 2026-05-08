# P1 渲染器 native handle token ownership planning preflight

日期：2026-05-09

状态：docs-only preflight / no native handle implementation

## 文件定位

本 preflight 承接 [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)，评估是否可以从 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 进入 native handle token ownership runway。

本轮不修改 native bridge，不新增 production `.h` / `.m`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer，不创建 backend ready truth，不写 renderer state，不发布 public diagnostics 或 public API。

## 预检结论

可以打开 native handle token ownership runway，但第一切片仍必须是 internal value boundary，而不是 handle implementation。

上游 `CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness` 足够作为 planning input，因为它已经固定 production bridge write-set policy、C ABI category admission policy 与 native status dehydration policy；但这些 facts 只允许继续规划 token ownership，不授予 native bridge implementation、C ABI implementation、FFI、native handle、raw pointer、Metal / AppKit resource、backend-ready truth、GPU submission、render 或 renderer state write permission。

## 第一切片形状

第一切片应新增 internal-only owner：

- owner candidate：`runtime/cjgui/src/runtime_renderer_native_handle_token.cj`
- runtime input：`CjguiInternalRendererNoNativeBridgeCAbiSurfaceReadiness`
- canonical endpoint candidate：`CjguiInternalRendererNoNativeHandleTokenReadiness`
- default draft candidate：`cjguiInternalExecuteDefaultRendererNativeHandleTokenDraft()`

该 owner 只能表达 native handle token ownership intent、opaque token admission policy、token ownership domain policy、token invalidation / revocation policy、double-release / dangling pointer denial policy 与 no-native-handle-token readiness facts。

## token 规划原则

future token 必须是不透明 token / dehydrated facts，而不是 raw native pointer。token 可以作为 future bridge-local identifier 的 planning vocabulary，但不得进入 public API，不得反向成为 native handle permission。

ownership 语义必须区分：

- token allocation admission。
- token ownership domain。
- token invalidation / revocation。
- double-release denial。
- dangling pointer denial。
- main-thread confinement。
- destroy contract compatibility。

这些语义本轮只以 Bool value facts 固定，不创建 token、不分配 native resource、不执行 retain / release / destroy、不调度 main-thread work。

## 候选取舍

A 推荐：`P1 internal Renderer native handle token ownership value boundary bundle implementation`

理由：handle/token identity、ownership confinement、invalidation、double-release / dangling pointer denial 与 destroy contract compatibility 需要先有 runtime-local value vocabulary。直接进入 native bridge implementation 或 C ABI / FFI 会绕过 token confinement。

B 暂缓：`P1 internal Renderer native bridge teardown implementation planning preflight decision`

C 暂缓：`P1 internal Renderer real Metal device-layer implementation write-set preflight`

D 拒绝：direct native bridge / Objective-C / Metal / AppKit modification

E 拒绝：direct production `.h` / `.m` creation

F 拒绝：direct C ABI / FFI implementation

G 拒绝：direct native handle / raw pointer creation or return

H 拒绝：direct backend-ready truth / renderer state write / public API

I 拒绝：receipt / record / publication wrapper

## 同形边界刹车

不得把 C ABI surface contract、real shell branch、smoke lab、Metal reference pack、native resource bridge manifest 或 token value facts 包成 native handle permission、native bridge implementation permission、C ABI implementation permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

若选择 A，新增 owner 必须提供 opaque token、ownership domain、invalidation / revocation、double-release denial、dangling pointer denial 等新语义，而不是薄包装。

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

- 本轮是否改变主题状态：是，从 C ABI surface contract manifest stabilization 进入 native handle token ownership preflight。
- 本轮是否改变 canonical tail / endpoint：否，本轮只是 preflight；候选 endpoint 为 `CjguiInternalRendererNoNativeHandleTokenReadiness`。
- 本轮是否改变 owner / truth / stop-line：否，本轮未新增 runtime owner；仅冻结下一刀候选 truth 与 stop-line。
- 本轮是否改变唯一 next opening：是，选择 `P1 internal Renderer native handle token ownership value boundary bundle implementation`。
- 是否同步 topic manifest：是。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native handle token ownership value boundary bundle implementation`
