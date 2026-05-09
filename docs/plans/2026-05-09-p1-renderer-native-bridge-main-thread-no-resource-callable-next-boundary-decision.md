# P1 内部渲染器 native bridge main-thread no-resource callable 后续收口

日期：2026-05-09

状态：next-boundary / choose manifest stabilization

## 当前 endpoint 充足性

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()` 足够作为当前 main-thread no-resource callable endpoint。

它只代表：

- main-thread no-resource callable intent。
- pthread-based current-thread classification。
- main-thread query observed facts。
- current-thread-is-main observed facts。
- no Foundation / Cocoa / Metal / QuartzCore import facts。
- no-public-surface / no-resource-callable / no-native-object facts。

它不是：

- AppKit permission。
- Metal permission。
- native object permission。
- native handle / pointer permission。
- resource callable permission。
- public API permission。
- renderer state write permission。
- backend-ready truth。

## 候选比较

选择 A：

`P1 internal Renderer native bridge main-thread no-resource callable manifest stabilization bundle`

理由：

- pthread route 已由 native compile、isolated FFI probe、package-adjacent link probe 与 `cjpm build` 初步验证。
- callable 返回 int32 dehydrated fact，不创建资源，不返回 pointer。
- runtime owner 已只消费 no-resource runtime FFI call endpoint，未扩大 public surface。
- 继续推进到 native token callable 前，应先封账当前 callable / owner / probes。

暂缓 C：

`P1 internal Renderer native bridge native token callable preflight decision`

理由：该入口只有在 manifest stabilization 完成后才能打开；它仍不得创建 native handle 或返回 pointer。

拒绝 D：

public API / resource callable / native object / Metal / AppKit。

## 停止线

- no public API / diagnostics。
- no resource callable。
- no native object / handle / pointer。
- no native pointer return。
- no Foundation / Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission / render。
- no renderer state write。
- no `runtime_state.cj` modification。
- no backend-ready truth。

## 后续入口

`P1 internal Renderer native bridge main-thread no-resource callable manifest stabilization bundle`

## 设计意图出口自检

- 本轮是否改变主题状态：是，选择 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定到 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_main_thread_call.cj`；truth 为 current-thread classification facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 manifest stabilization。
- 是否同步 topic manifest：待 manifest 阶段同步。
- 已同步哪些 topic manifest：待同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
