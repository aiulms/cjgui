# P1 渲染器 native bridge callable C ABI planning 后续边界决议

日期：2026-05-09

状态：docs-only next-boundary decision / no callable implementation

## 文件定位

本决议确认 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()` 是否足够作为当前 no-callable-C-ABI endpoint，并决定是否进入 manifest stabilization。

## 端点判断

`CjguiInternalRendererNoCallableCAbiReadiness` 足够作为当前 no-callable-C-ABI endpoint。它只代表 callable `C ABI` planning intent、callable naming policy、status / capability callable admission policy、no-resource callable guard、runtime FFI separation policy 与 no-callable-C-ABI readiness facts。

该 endpoint 不是 callable `C ABI` implementation permission，不是 FFI permission，不是 native bridge implementation permission，不是 native handle / raw pointer permission，不是 AppKit / Metal permission，不是 backend-ready permission，不是 renderer state write permission，也不是 public API permission。

## 候选比较

- A 胜出：`P1 internal Renderer native bridge callable C ABI planning manifest stabilization bundle`。owner 已可编译，truth 与 stop-line 清晰，可以进入 manifest 封账。
- B 暂缓：callable `C ABI` first implementation preflight。必须先固定 planning owner / endpoint / default draft / runtime input / truth / stop-line。
- C 暂缓：native bridge production status taxonomy hardening。可在后续以 callable first implementation preflight 判断是否需要拆出。
- D 拒绝：直接修改 production `.h` / `.m`、实现 callable `C ABI` 或接 FFI。
- E 拒绝：直接创建 native object、native handle、raw pointer、AppKit / Metal object、GPU submission、renderer state write、public diagnostics 或 public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoCallableCAbiReadiness`、build boundary、skeleton compile、C ABI surface contract、token ownership、teardown planning 或 smoke evidence 包装成 callable implementation permission、FFI permission、native bridge implementation permission、native-handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

下一步只能做 manifest stabilization，固定当前 owner 与 stop-line，不得顺手进入 callable implementation。

## 停止线

- no production native `.h` / `.m` modification。
- no callable `C ABI` implementation。
- no runtime `.cj` FFI declaration。
- no build config modification。
- no smoke native modification。
- no native handle / raw pointer。
- no raw pointer return。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是。callable `C ABI` planning value boundary 从 closure 推进到 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：否，继续使用 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`。
- 本轮是否改变 owner / truth / stop-line：否，owner、truth 与 stop-line 仅被确认并准备封账。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI planning manifest stabilization bundle`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer native bridge callable C ABI planning manifest stabilization bundle`
