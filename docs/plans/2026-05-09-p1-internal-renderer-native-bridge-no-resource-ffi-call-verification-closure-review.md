# P1 内部渲染器 native bridge no-resource FFI call verification 收口复核

日期：2026-05-09

状态：runtime-adjacent probe implemented / no runtime owner call

## 本轮实际完成

新增 [verify_native_bridge_no_resource_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh)。

该 probe 做三件事：

- 检查 `runtime_renderer_native_bridge_runtime_ffi_declaration.cj` 中四个 internal-only `foreign func` declaration 是否存在。
- 调用 `verify_native_bridge_cjpm_package_link_probe.sh`，在临时 package 中链接 production no-resource static archive 并调用四个 C ABI。
- 解析并输出四个 dehydrated observed facts：surface version、capabilities、status ok、no-resource admission。

本轮未新增 runtime verification owner，因为 `runtime/cjgui` 主包仍未接入 production native static archive，直接把 call 写入主包 owner 会扩大 package link 证据。

## 观察事实

允许观察的 callable 仍只有：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

probe 输出的事实只允许解释为：

- runtime declaration owner 可被 source-level 检查到。
- runtime-adjacent temporary package 可调用四个 no-resource C ABI。
- 四个 callable 的返回值可脱水成 observed=true facts。

这些事实不表示 `runtime/cjgui` 主包已经拥有 runtime FFI call support。

## GitNexus 记录

按要求对上游入口运行 impact：

- `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness`：GitNexus 返回 UNKNOWN / not found。
- `cjguiInternalExecuteDefaultRendererNativeBridgeRuntimeFfiDeclarationDraft`：GitNexus 返回 UNKNOWN / not found。

本轮没有编辑 runtime symbol；新增的是 runtime-adjacent probe script 与 docs。近期新增 owner 未索引的风险继续由源码、probe、build、smoke 与 forbidden scans 兜底。

## 固定边界

- 未新增 public API。
- 未新增 public diagnostics。
- 未新增 runtime FFI call owner。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 production native C ABI 行为。
- 未修改 smoke native files。
- 未创建 native object、native handle、raw pointer。
- 未导入 Cocoa / Metal / QuartzCore。
- 未写 renderer state，未触碰 `runtime_state.cj`。

## 同形边界刹车

不得把本 probe、runtime declaration owner、package link probe success 或 observed facts 包装成 runtime package call support、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge no-resource FFI call verification next-boundary decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，internal no-resource FFI call verification 从 preflight 进入 runtime-adjacent probe implementation。
- 本轮是否改变 canonical tail / endpoint：否，本轮没有新增 runtime endpoint；仍以 `CjguiInternalRendererNoNativeBridgeRuntimeFfiCallReadiness` 作为 declaration endpoint。
- 本轮是否改变 owner / truth / stop-line：是，新增 probe script；truth 增加 runtime-adjacent observed call facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 verification next-boundary decision。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：本 closure 尚未同步，后续 manifest 同步三个 Renderer / smoke topic manifest。
