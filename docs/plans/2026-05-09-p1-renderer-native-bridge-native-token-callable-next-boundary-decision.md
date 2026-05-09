# P1 内部渲染器 native bridge native token callable 后续收口

日期：2026-05-09

状态：next-boundary decision / 选择 manifest stabilization

## endpoint 评估

`CjguiInternalRendererNoNativeBridgeTokenCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTokenCallableDraft()` 足够作为当前 no-native-token-callable endpoint。

该 endpoint 只代表 opaque token callable planning、no-pointer token policy、token table mutability denial、issue / revoke implementation deferred、revoke-without-destroy policy、main-thread gate preserved 与 no-native-token-callable readiness facts。

它不是 token implementation、native handle permission、native object permission、resource callable permission、destroy permission、Metal / AppKit permission、backend-ready truth、public API 或 renderer state write permission。

## 候选比较

- A 选择：`P1 internal Renderer native bridge native token callable manifest stabilization bundle`。当前 owner 已能封账，先固定 manifest。
- B 后续：`P1 internal Renderer native token table ownership hardening preflight decision`。manifest 后作为唯一 next opening。
- C 暂缓：`P1 internal Renderer native bridge no-resource token callable first implementation preflight decision`。必须等 token table ownership / mutability / fail-closed 策略更硬。
- D 暂缓：`P1 internal Renderer native bridge teardown callable preflight decision`。尚未允许 token table 或 destroy callback。
- E 拒绝：native object / pointer handle / public API / Metal / AppKit。

## 本轮选择

选择 A，继续 manifest stabilization。

## 停止线

- 不新增 native token callable。
- 不创建 token table。
- 不创建 native object、native handle、raw pointer。
- 不返回 native pointer。
- token 不得编码 native pointer。
- 不修改 production native `.h` / `.m`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 `runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不调用 resource callable。
- 不调用 retain / release / destroy。
- 不导入 Cocoa / Metal / QuartzCore。
- 不执行 GPU / render / renderer state write。
- 不创建 backend-ready truth。

## 同形边界刹车

不得把 token callable planning owner、main-thread query、no-resource runtime FFI call、native handle token ownership manifest 或 smoke evidence 包装成 native handle permission、native object permission、destroy permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，选择 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，tail 固定到 `CjguiInternalRendererNoNativeBridgeTokenCallableReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_token_callable.cj`；truth 为 opaque token planning facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，manifest 后建议 `P1 internal Renderer native token table ownership hardening preflight decision`。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：next-boundary 阶段尚未同步。
