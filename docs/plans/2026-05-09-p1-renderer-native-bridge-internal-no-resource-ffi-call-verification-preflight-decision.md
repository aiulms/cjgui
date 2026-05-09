# P1 渲染器 native bridge internal no-resource FFI call verification 预检结论

日期：2026-05-09

状态：docs-only preflight / fallback probe route selected

## 预检问题

本轮判断是否可以从 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` 进入 internal no-resource FFI call verification。

当前上游已经完成：

- production native skeleton 提供四个 no-resource callable。
- isolated FFI probe 已证明 `foreign func` 语法与 direct `cjc` link 可调用四个 callable。
- script-managed `cjpm` package link probe 已证明临时 package 可通过 `compile-option` / `link-option` 链接 static archive 并调用四个 callable。
- runtime internal declaration owner 已声明四个 internal-only `foreign func`。

当前仍未完成：

- `runtime/cjgui/cjpm.toml` 未接入 production `.m` 或 static archive。
- `runtime/cjgui` 主包仍是 `output-type = "static"`，没有主包内可执行 call path。
- 当前主包 build 只证明 declarations 可编译，不证明 runtime owner 能在主包内执行 call。

## 候选比较

- A 暂缓：新增 internal runtime owner 并在主包内调用四个 no-resource C ABI。原因是主包 package link 仍未接入，直接新增 call 会把 declaration / probe evidence 包装成 runtime package call permission。
- B 选择：新增 runtime-adjacent probe。该 probe 先确认 runtime declaration owner 已声明四个 `foreign func`，再调用 script-managed `cjpm` package link probe 并解析四个 observed facts。它能验证 no-resource call result，但不进入主包 owner call。
- C 暂缓：package link / runtime call blocker follow-up。当前 package-adjacent probe 可运行，尚不需要 blocker。
- D 拒绝：public API / resource callable / native object / Metal / AppKit。

## 选择结果

选择 B：`P1 internal Renderer native bridge no-resource FFI call runtime-adjacent probe bundle`。

理由：

- 该路线实际调用 `cjgui_native_bridge_surface_version`、`cjgui_native_bridge_surface_capabilities`、`cjgui_native_bridge_status_ok` 与 `cjgui_native_bridge_no_resource_admission`。
- 该路线不修改 `runtime/cjgui/cjpm.toml`，不把 production `.m` 接入主包。
- 该路线不新增 public API，不新增 resource callable，不创建 native object，不写 renderer state。
- 该路线清楚地区分 runtime declaration owner 与 runtime-adjacent executable probe，避免 same-shape permission wrapper。

## 固定边界

- 本轮不新增 runtime FFI call owner。
- 本轮不修改 `runtime/cjgui/cjpm.toml`。
- 本轮不修改 production native C ABI 行为。
- 本轮不修改 smoke native files。
- 本轮只允许新增 runtime-adjacent probe script 与 docs。
- no-resource call observed facts 只能作为 internal verification evidence，不是 backend-ready truth。

## 同形边界刹车

不得把 runtime declaration、runtime-adjacent probe、package link probe、isolated FFI probe 或 no-resource observed facts 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

No-resource call 只证明 side-effect-free interop evidence，不证明 GUI backend ready。

## 后续入口

`P1 internal Renderer native bridge no-resource FFI call runtime-adjacent probe bundle`

## 设计意图出口自检

- 本轮是否改变主题状态：是，进入 internal no-resource FFI call verification preflight，并选择 runtime-adjacent probe fallback。
- 本轮是否改变 canonical tail / endpoint：否，当前 runtime declaration endpoint 仍是 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`；本轮不新增 runtime endpoint。
- 本轮是否改变 owner / truth / stop-line：是，truth 从 declaration-only 进入 runtime-adjacent observed call evidence；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 runtime-adjacent no-resource call probe。
- 是否同步 topic manifest：待本阶段 closure / manifest 完成后同步。
- 已同步哪些 topic manifest：预检阶段尚未同步，后续 manifest stabilization 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
