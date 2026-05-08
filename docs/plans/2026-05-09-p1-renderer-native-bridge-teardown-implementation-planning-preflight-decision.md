# P1 渲染器 native bridge teardown implementation planning 预检

日期：2026-05-09

状态：docs-only preflight / no teardown implementation

## 文件定位

本文件评估是否可以从 [native handle token ownership manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-handle-token-ownership-manifest.md) 进入 native bridge teardown implementation planning runway。

本轮不是 destroy / release implementation，不新增 production `.h` / `.m`，不修改 `labs/macos_bridge_smoke/native/*`，不实现 C ABI / FFI，不创建 native handle / raw pointer，不返回 native pointer，不调用 retain / release / destroy，不实现 destroy callback，不写 renderer state，不发布 public diagnostics 或 public API。

## 上游判断

`CjguiInternalRendererNoNativeHandleTokenReadiness` 足够作为 teardown implementation planning 的上游 endpoint，因为它已经固定 opaque token admission、token ownership domain、token invalidation / revocation、double-release / dangling pointer denial 与 no-native-handle-token readiness facts。

该 endpoint 仍不是 native handle permission、raw pointer permission、native pointer return permission、native bridge implementation permission、C ABI implementation permission、FFI permission、retain / release / destroy permission、backend-ready permission、GPU-submission permission、render permission、renderer state write permission、public diagnostics permission 或 public API permission。

## 第一切片判断

第一切片仍必须是 internal value boundary，而不是 destroy / release implementation。它只能记录 teardown planning intent、destroy admission guard、token invalidation before destroy、double-destroy / dangling-token denial、main-thread destroy confinement、failure classification 与 no-native-bridge-teardown-implementation readiness facts。

未来 production write set 需要单独 preflight 固定，且不得直接复用 `labs/macos_bridge_smoke/native/*`。本轮只记录 future allowed write set 需要覆盖哪些契约，不允许创建 native `.h` / `.m` 文件。

## smoke 证据可借鉴项

`labs/macos_bridge_smoke/native/cjgui_macos.m` 中的 `invalidateBridgeResources`、`invalidated` guard、`window will close`、`main-thread drain` 与 `destroy complete` 日志，可以作为 teardown ordering、idempotent invalidation、main-thread lifecycle drain 与 destroy completion 的 feasibility evidence。

这些证据不能直接进入 production bridge：不得把 `NSView render` 直连渲染、global mutable last error、Objective-C truth source、`nextDrawable` / `commandBuffer` / `commit` / `present`、readback-only defaults 或 native pointer / handle 泄露搬入 runtime。

## 候选比较

A 推荐：`P1 internal Renderer native bridge teardown implementation planning value boundary bundle implementation`。理由是 token ownership endpoint 已足够作为 planning input，但任何真实 destroy / release 之前仍必须先形成 runtime-local planning value boundary。

B 暂缓：`P1 internal Renderer native bridge first production write-set preflight decision`。仅在 teardown planning value facts 封账后再打开。

C 暂缓：`P1 internal Renderer native bridge teardown implementation preflight decision`。真实 implementation preflight 需要先有本轮 planning manifest。

D 拒绝：direct retain / release / destroy implementation。

E 拒绝：direct native bridge / Objective-C / Metal / AppKit modification。

F 拒绝：direct C ABI / FFI implementation。

G 拒绝：direct native handle / raw pointer creation。

H 拒绝：backend ready truth / renderer state write / public diagnostics / public API。

## 同形边界刹车

本轮不得把 token ownership、C ABI surface contract、smoke lab、Metal reference pack、native teardown hardening manifest 或 teardown planning evidence 包装成 native bridge implementation permission、destroy permission、native-handle permission、C ABI implementation permission、Metal permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

若选择 A，下一轮新增 runtime owner 必须提供新的 destroy admission、token invalidation、double-destroy denial、dangling-token denial、main-thread destroy confinement 与 failure classification 语义，而不是薄包装。

## 停止线

- no `labs/macos_bridge_smoke/native/*` modification。
- no production `.h` / `.m`。
- no C ABI implementation。
- no FFI declaration。
- no native handle / raw pointer。
- no native pointer return。
- no retain / release / destroy。
- no destroy callback implementation。
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
- no module-level mutable `var`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 native handle token ownership manifest stabilization 推进到 native bridge teardown implementation planning preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，预检阶段不新增 runtime endpoint；上游仍是 `CjguiInternalRendererNoNativeHandleTokenReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，选择下一步 owner candidate、truth candidate 与 teardown planning stop-line。
- 本轮是否改变唯一 next opening：是，选择 `P1 internal Renderer native bridge teardown implementation planning value boundary bundle implementation`。
- 是否同步 topic manifest：是，随本宏包同步。
- 已同步 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md` 与 `docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge teardown implementation planning value boundary bundle implementation`
