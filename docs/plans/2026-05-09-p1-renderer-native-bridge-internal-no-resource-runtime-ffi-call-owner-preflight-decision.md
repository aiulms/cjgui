# P1 内部渲染器 native bridge internal no-resource runtime FFI call owner 预检

日期：2026-05-09

状态：docs-only preflight / 允许极窄 owner first slice

## 本轮问题

本轮判断是否可以从 [package config link route reconciliation scan](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-package-config-link-route-reconciliation-scan.md) 进入 actual internal no-resource runtime FFI call owner。

上游 canonical endpoint 是 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft()`。它只证明 script-managed package config link route、package config still-deferred facts 与 no-resource callable evidence 已对账，不是 `runtime/cjgui/cjpm.toml` integration、public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

## 影响面记录

GitNexus impact 在编辑 runtime symbol 前已对上游入口运行：

- `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`：`UNKNOWN / not found`。
- `cjguiInternalExecuteDefaultRendererNativeBridgePackageConfigLinkDraft`：`UNKNOWN / not found`。

判定：按近期新增 owner 尚未被索引处理，不因 `UNKNOWN` 阻断本轮；继续用源码阅读、临时 build probe、no-resource call probe、`cjpm build` 与最终 scan 兜底。未收到 HIGH / CRITICAL risk。

## 证据

- `runtime/cjgui/src/runtime_renderer_native_bridge_runtime_ffi_declaration.cj` 已声明四个 internal-only no-resource `foreign func`。
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh` 已能通过临时 package 实际调用四个 no-resource C ABI。
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh` 已证明 script-managed temporary `cjpm` package link route 可用。
- 不改仓库的 `/tmp` 副本验证显示：在 `runtime/cjgui` 主包源码中加入 actual unsafe foreign call owner 后，`cjpm build --skip-script` 可通过；这只证明 static package compile 可承受 owner call，不证明 `runtime/cjgui/cjpm.toml` 已正式接入 native archive。
- `runtime/cjgui/cjpm.toml` 当前仍未修改，production `.m` 仍未接入主包。

## 选择

选择 A：

`P1 internal Renderer native bridge internal no-resource runtime FFI call owner first implementation bundle`

理由：

- build/link 风险已被窄化：主包 static build 可承受 owner call，实际 C ABI returned facts 仍由 script-managed probe 覆盖。
- owner 可以只消费 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`，不改 `cjpm.toml`。
- owner 可以 fail-closed：四个返回值任一不符合预期时只形成 blocked / no-readiness facts。
- owner 只产生 internal dehydrated facts，不扩 public API，不调用 resource callable，不创建 native object。

## 本轮允许写集

- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_no_resource_call.cj`。
- 可更新 `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`，只用于确认 owner 源码与 no-resource probe evidence。
- 新增 / 更新本轮 docs、README、tracker、topic manifests。

## 本轮停止线

- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 public API / public diagnostics。
- 不调用 resource callable。
- 不创建 native object、native handle、raw pointer 或 native pointer return。
- 不导入 Cocoa / Metal / QuartzCore。
- 不调用 retain / release / destroy。
- 不获取 drawable，不创建 command buffer，不调用 `commit` / `present`。
- 不提交 GPU work，不执行 render，不写 renderer state。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不修改 smoke native files。
- 不把 internal no-resource call 包装成 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，允许进入 actual internal no-resource runtime FFI call owner first slice。
- 本轮是否改变 canonical tail / endpoint：预期会改变，若实现成功将从 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness` 推进到 no-resource runtime call owner endpoint。
- 本轮是否改变 owner / truth / stop-line：预期会新增 owner；truth 仅限 no-resource runtime call observed facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预期会在 next-boundary decision 中更新。
- 是否同步 topic manifest：是，随实现 / manifest 一并同步。
- 已同步哪些 topic manifest：将在 closure / manifest 中记录。
