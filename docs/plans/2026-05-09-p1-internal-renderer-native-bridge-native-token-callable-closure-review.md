# P1 内部渲染器 native bridge native token callable 收口复核

日期：2026-05-09

状态：implementation closure / planning value boundary

## 实际写集

- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_token_callable.cj`
- 新增 `docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-preflight-decision.md`
- 新增本 closure

本轮没有修改 `runtime/cjgui/native/cjgui_native_bridge.h`，没有修改 `runtime/cjgui/native/cjgui_native_bridge.m`，没有新增 native callable，没有修改 probe scripts，没有修改 `runtime/cjgui/cjpm.toml`。

## implementation 结论

已新增 internal-only planning owner：

`runtime/cjgui/src/runtime_renderer_native_bridge_token_callable.cj`

canonical endpoint：

`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`

default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`

runtime input：

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`

## 固定语义

owner 只表达：

- native token callable intent。
- `UInt64` / `uint64_t` opaque token type policy。
- struct token forbidden policy。
- token-as-pointer forbidden policy。
- bridge-local identifier policy。
- token table mutability denial / fallback policy。
- issue / revoke implementation deferred facts。
- revoke-without-destroy policy。
- main-thread gate preserved facts。
- no-native-token-callable readiness facts。

## 为什么没有实现 native token callable

token issue / validate / revoke 的真实闭环需要 token table。没有 token table时，issue 出来的 token 无法安全 validate / revoke；新增 token table 则会引入 global mutable state 或 native mutable state，并触发本轮硬边界。

因此本轮选择 planning value boundary，而不是薄包装一个不可撤销 token，或把常量 token 误包装成 native handle readiness。

## 边界确认

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer。
- 未返回 native pointer。
- 未创建 token table。
- 未新增 module-level mutable `var`。
- 未修改 production native `.h` / `.m`。
- 未修改 smoke native files。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 retain / release / destroy。
- 未执行 render、GPU submission 或 renderer state write。
- 未创建 backend-ready truth。

## GitNexus 记录

编辑前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`
- `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft`

GitNexus 返回 `UNKNOWN / not found`，按近期新增 owner 未索引处理；本轮继续使用源码、build、probe 与扫描兜底。未收到 HIGH / CRITICAL 风险。

## 同形边界刹车

不得把本 owner 的 opaque-token policy、main-thread gate preservation、token table denial 或 revoke-without-destroy facts 包装成 native token implementation permission、native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready truth、public API、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token callable 已完成 planning value boundary implementation。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_token_callable.cj`；truth 限定为 opaque token planning / table mutability denial / revoke-without-destroy facts；stop-line 继续禁止 native object、pointer handle、public API、Metal / AppKit 与 backend-ready truth。
- 本轮是否改变唯一 next opening：待 next-boundary 决策固定。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：implementation closure 阶段尚未同步。
