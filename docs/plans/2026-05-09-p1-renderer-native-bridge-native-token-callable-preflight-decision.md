# P1 内部渲染器 native bridge native token callable 预检

日期：2026-05-09

状态：docs-only preflight / 选择 planning value boundary

## 本轮目标

本轮从 [main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 进入 native token callable runway。目标不是创建 token table，也不是实现 native handle；目标是判断 token callable 能否保持 no-resource、opaque、no-pointer 与 internal-only。

## 证据读取

- `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` 已能表达 current-thread classification facts。
- `runtime/cjgui/src/runtime_renderer_native_handle_token.cj` 早前已固定 opaque token ownership、ownership domain、invalidation / revocation、double-release denial 与 dangling pointer denial policy。
- no-resource runtime FFI call owner 只证明 side-effect-free native callable 可被 internal owner 脱水。
- production native bridge 当前只允许 no-resource status / capability / main-thread query callable。

这些证据只允许打开 token callable planning，不允许创建 native token table、native handle、raw pointer、native object、resource callable 或 public API。

## token 形状判断

token 未来若进入 callable implementation，只能采用 `uint64_t` / `UInt64` 一类 opaque integer token。struct token、native pointer token、`uintptr_t` token、Objective-C object identity token 和 raw handle token 都必须继续禁止。

token 不得编码 native pointer，不得把 pointer cast 成整数，不得把 Objective-C / Metal 对象地址作为 token truth。token 只能是 future bridge-local identifier。

## issue / classify / revoke 判断

本轮不实现真实 issue / revoke：

- 没有 token table 时，issue 出来的 token 无法被安全 validate / revoke。
- 若为了 validate / revoke 新增 token table，会引入全局可变状态或 native mutable state。
- 当前全局硬边界禁止新增 module-level mutable runtime state，也禁止 native handle / raw pointer / native object。

因此本轮选择先固定 token table mutability denial / fallback policy。真正 issue / classify / revoke 必须等 `P1 internal Renderer native token table ownership hardening preflight decision` 重新评估所有权、表生命周期、main-thread gate、fail-closed 与 teardown compatibility。

## main-thread gate

main-thread query 只能作为 future token mutation 的前置 guard evidence。它不等于允许创建 token table，不等于允许创建 native object，不等于允许 destroy / retain / release。

本轮 owner 可以消费 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`，但只能脱水 token callable planning facts，不能发布 token，也不能公开 token。

## 候选比较

- A 推荐：`P1 internal Renderer native bridge token callable planning value boundary bundle`。选择该项，因为 issue/revoke 若无 table 不可验证，若有 table 会触发 mutable state 风险。
- B 暂缓：`P1 internal Renderer native bridge no-resource token callable first implementation bundle`。当前没有安全 token table ownership 证据，不选。
- C 后续：`P1 internal Renderer native token table ownership hardening preflight decision`。作为唯一下一步入口。
- D 拒绝：native object / pointer handle / public API / Metal / AppKit。

## 本轮结论

选择 A，继续新增 internal runtime owner：

`runtime/cjgui/src/runtime_renderer_native_bridge_token_callable.cj`

建议 endpoint：

`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`

建议 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()`

唯一 runtime input：

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`

该 owner 只表达 native token callable intent、opaque token type policy、no-pointer token policy、token table mutability denial / fallback policy、revoke-without-destroy policy 与 no-native-token-callable readiness facts。

## 停止线

- 不新增 native callable。
- 不修改 production native `.h` / `.m`。
- 不新增 token issue / validate / revoke C ABI。
- 不创建 token table。
- 不新增 module-level mutable `var`。
- 不创建 native object、native handle、raw pointer。
- 不返回 native pointer。
- token 不得编码 native pointer。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不修改 smoke native files。
- 不新增 public API / diagnostics。
- 不调用 retain / release / destroy。
- 不导入 Cocoa / Metal / QuartzCore。
- 不执行 render、GPU submission 或 renderer state write。
- 不创建 backend-ready truth。

## 同形边界刹车

不得把 token callable planning、main-thread query、no-resource FFI call、token ownership manifest 或 smoke evidence 包装成 native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：预检选择 token callable planning value boundary runway。
- 本轮是否改变 canonical tail / endpoint：预检阶段尚未改变；implementation 若成功将转为 `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检建议新增 `runtime_renderer_native_bridge_token_callable.cj`；truth 限定为 opaque token planning facts；stop-line 不变。
- 本轮是否改变唯一 next opening：预检阶段建议实施后转 manifest stabilization，再转 `P1 internal Renderer native token table ownership hardening preflight decision`。
- 是否同步 topic manifest：待 implementation / manifest 后同步。
- 已同步哪些 topic manifest：预检阶段尚未同步。
