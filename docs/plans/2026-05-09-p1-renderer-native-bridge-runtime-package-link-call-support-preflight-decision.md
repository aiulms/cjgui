# P1 渲染器 native bridge runtime package link call support 预检结论

日期：2026-05-09

状态：docs-only preflight / value boundary selected

## 目标定位

本轮判断是否可以从 runtime-adjacent no-resource call probe 进入 `runtime/cjgui` 主包 package link call support runway。

结论：可以打开 call support planning runway，但第一刀必须是 internal value boundary。当前证据足以记录 package call support 条件与阻塞点，不足以把 no-resource FFI call 写入 runtime owner，也不足以修改 `runtime/cjgui/cjpm.toml`。

## 证据读取

已读取并采用以下事实：

- `runtime_renderer_native_bridge_runtime_ffi_declaration.cj` 已声明四个 internal-only no-resource `foreign func`。
- `verify_native_bridge_no_resource_call_probe.sh` 已通过 runtime-adjacent temporary `cjpm` package 调用四个 no-resource C ABI，并输出 observed facts。
- `verify_native_bridge_cjpm_package_link_probe.sh` 已证明 script-managed temporary package link 路线可行。
- `runtime/cjgui/cjpm.toml` 仍未接入 production native static archive。
- `runtime/cjgui` 主包仍没有 runtime owner call support。

## 阻塞点判断

当前主包内 call 的阻塞点不是 C ABI 函数本身，也不是 isolated `foreign func` 语法，而是 `runtime/cjgui` package link 尚未把 production no-resource native bridge object / archive 接入主包。

因此本轮不修改 `runtime/cjgui/cjpm.toml`，不新增 package-call-support probe；先新增 internal owner 固定 call support / blocker facts。

## 候选比较

- A 选择：`P1 internal Renderer native bridge runtime package link call support value boundary bundle`。新增 internal owner，固定 package call support intent、dylib / object path evidence policy、macOS-only gate、runtime-adjacent probe evidence policy 与 no-runtime-package-call-support facts；不做 runtime call。
- B 暂缓：`P1 internal Renderer native bridge runtime package call support probe bundle`。现有 no-resource call probe、package link probe 与 `cjpm` package link probe 已足够支撑 value boundary；暂不新增同类 probe。
- C 暂缓：`P1 internal Renderer native bridge package config link implementation preflight decision`。这是本阶段封账后的唯一合理下一步，因为 package config 是主包 call support 的剩余阻塞点。
- D 暂缓：internal runtime no-resource FFI call owner。主包 package link support 未固定前不进入。
- E 拒绝：public API / resource callable / native object / Metal / AppKit。

## 选择结果

选择 A，进入 `P1 internal Renderer native bridge runtime package link call support value boundary bundle`。

## 停止线

- 不做 actual runtime FFI call。
- 不新增 public API / diagnostics。
- 不调用 resource callable。
- 不创建 native object、native handle、raw pointer。
- 不返回 native pointer。
- 不导入 Cocoa / Metal / QuartzCore。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 `runtime_state.cj`。
- 不写 renderer state。
- 不提交 GPU work，不执行 render。
- 不把 call support facts 解释成 backend-ready truth。

## 同形边界刹车

不得把 runtime-adjacent call probe、package call support facts、FFI declaration、package link evidence 或 smoke evidence 包装成 public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Call support 只证明通路条件与阻塞分类，不证明 runtime GUI backend ready。

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime package link call support runway 打开，但只选择 value boundary。
- 本轮是否改变 canonical tail / endpoint：预检本身不改变，后续 owner 会新增 `CjguiInternalRendererNoNativeBridgePackageCallSupportReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检确认将新增 owner；truth 只限 package call support / blocker facts；stop-line 继续禁止 runtime call、public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：预检阶段暂定 value boundary，manifest 后转向 package config link implementation preflight。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：本 decision 尚未同步，后续 manifest 同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
