# P1 内部渲染器 native token table no-resource shell first implementation 预检

日期：2026-05-10

状态：preflight / choose classification shell first slice

## 本轮判断

可以打开 no-resource token table shell 的第一实现切片，但只能选择 classification shell 路线。

本轮选择：

`P1 internal Renderer native token table no-resource classification callable first implementation bundle`

选择理由：

- 上游 [native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md) 已固定 bridge-local table shell policy、no-pointer table entry policy、generation / slot / epoch policy 与 capacity / failure policy。
- 真正 issue / revoke 需要 native-side mutable table、generation / epoch 更新与 stale token 回收策略；这些会靠近第一份 mutable native table，不适合作为本轮 first slice。
- 只读 classification shell 可以提供 invalid / capacity / enabled / classify facts，同时保持 no mutation、no resource binding、no pointer、no public API。
- `runtime/cjgui/cjpm.toml` 仍不需要修改；当前继续依赖 isolated compile、symbol probe、package-adjacent probe 与 temporary `cjpm` package probe 验证。

## 允许写集

本轮允许：

- 修改 `runtime/cjgui/native/cjgui_native_bridge.h`，仅新增 no-resource token shell callable declaration 与 token classification enum。
- 修改 `runtime/cjgui/native/cjgui_native_bridge.m`，仅实现 no-resource deterministic token shell callable。
- 修改 native probe scripts 的 allowlist 与 temporary probe 调用。
- 新增 internal runtime owner `runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`。
- 新增本轮 closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与三个 topic manifest。

本轮不允许：

- 修改 `runtime/cjgui/cjpm.toml`。
- 修改 smoke native files。
- 新增 public API / diagnostics。
- 新增 resource callable。
- 创建或绑定 native object。
- 保存 raw pointer 或返回 pointer / handle。
- 实现 issue / revoke。
- 新增 global mutable native table。
- 写 renderer state 或触碰 `runtime_state.cj`。

## callable 形状

本轮只允许新增以下 no-resource callable：

- `cjgui_native_bridge_token_invalid(void)`：返回 `uint64_t` invalid token constant，固定为 `0`。
- `cjgui_native_bridge_token_table_capacity(void)`：返回 `uint32_t` capacity，first slice 固定为 `0`，表示 table shell disabled / no slot allocated。
- `cjgui_native_bridge_token_table_enabled(void)`：返回 `uint32_t` enabled flag，first slice 固定为 `0`。
- `cjgui_native_bridge_token_classify(uint64_t token)`：返回 `int32_t` classification；`0` 表示 invalid token，负值表示 unsupported / disabled shell。

本轮不新增 issue / revoke callable。任何需要 mutable table、slot allocation、generation update、token reuse 或 revocation state 的函数必须进入后续 preflight。

## runtime owner 形状

新增 owner：

`runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`

Endpoint：

`CjguiInternalRendererNoNativeTokenTableShellReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`

Runtime input：

`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`

owner 只调用 classification shell callable，并把返回值脱水成 internal facts：invalid token observed、zero capacity observed、table disabled observed、invalid classification observed、nonzero token fail-closed observed。它不得 public，不得写 state，不得调用 resource callable。

## GitNexus 预检

对上游入口运行 impact：

- `CjguiInternalRendererNoNativeTokenTableImplementationReadiness`：`UNKNOWN / not found`。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft`：`UNKNOWN / not found`。

按近期新增 owner 尚未索引处理；本轮继续用源码、probe、`cjpm build`、smoke 与 forbidden scan 兜底。未发现 HIGH / CRITICAL 风险。

## 验证策略

本轮采用小型 RED / GREEN：

- 先更新 symbol probe allowlist，运行 `verify_native_bridge_no_resource_symbols.sh`，预期在 native callable 尚未实现时失败。
- 再新增 native callable 与 runtime owner，使 symbol probe、skeleton compile、package link probe、no-resource call probe 与 `cjpm build --skip-script` 通过。

通过标准：

- 新增 token shell callable 出现在 object symbol probe 中。
- temporary package probe 能调用 token invalid / capacity / enabled / classify 并观察 expected facts。
- runtime owner build 通过。
- public declaration scan 不变。
- forbidden scan 确认 no issue / revoke、no resource table、no token-as-pointer、no native object、no Cocoa / Metal / QuartzCore、no `runtime_state.cj` touch。

## 同形边界刹车

不得把 token table shell、token classification、capacity facts、token ownership hardening 或 smoke evidence 包装成 resource table permission、native handle permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。Token table shell 只定义 bridge-local no-resource token mechanics，不证明 resource exists。

## 设计意图出口自检

- 本轮是否改变主题状态：是，打开 no-resource token table shell first implementation runway。
- 本轮是否改变 canonical tail / endpoint：预期是，若 implementation 成功将转为 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：预期是，新增 token table shell owner；truth 限于 invalid / capacity / enabled / classification facts；stop-line 继续禁止 issue / revoke、resource table、native object、pointer、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：预期是，成功后转为 `P1 internal Renderer native token table no-resource issue/revoke preflight decision`。
- 是否同步 topic manifest：是，本轮结束同步。
- 已同步哪些 topic manifest：待 closure / manifest 完成后同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
