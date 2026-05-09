# P1 渲染器 native bridge package config link implementation 预检结论

日期：2026-05-09

状态：docs-only preflight / script-managed route selected

## 目标定位

本轮判断 `runtime/cjgui` 主包是否可以把 no-resource native bridge C ABI 接入 package config / link 路线。

本轮不得把 package config link 解释成 runtime FFI call、public API、resource callable、native object、Metal / AppKit、backend-ready truth 或 renderer state write。

## 已有证据

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh` 已证明临时 `cjpm` package 可以通过 `compile-option` / `link-option` 链接 no-resource native bridge static archive。
- isolated FFI probe 已证明四个 no-resource C ABI 可由仓颉 `foreign func` 调用。
- runtime package link call support manifest 已确认主包内 actual runtime call 仍 blocked。
- `runtime/cjgui/cjpm.toml` 当前只有最小 static package 配置，没有 `[ffi.c]`、`compile-option`、`link-option` 或 native artifact 路径。
- 本地 `cjpm` 文档只给出 `[ffi.c]` 的 C 库目录与 package-level `compile-option` / `link-option` 能力；未给出 Objective-C `.m` 在 `--skip-script` 下自动生成 archive 的稳定主包方案。

## 路线判断

候选 A：package config link first implementation。

暂不选择。原因是 no-resource archive 仍需要脚本或外部产物生成；若直接在 `runtime/cjgui/cjpm.toml` 中写入 `link-option`，`cjpm build --skip-script` 会面对不可生成的 artifact 路径，不能形成可复核的主包配置。

候选 B：package config link blocker follow-up。

暂不选择。当前不是完全 blocker；临时 `cjpm` package link 和 runtime-adjacent call probe 已经提供了稳定的 script-managed route evidence。

候选 C：script-managed link route stabilization。

本轮选择 C。该路线不修改 `runtime/cjgui/cjpm.toml`，继续把 no-resource native object / static archive 生成、链接与调用观察限制在 probe 脚本和临时 package 中，并新增 internal value owner 固定 package config link blocker / fallback facts。

候选 D：runtime FFI call / public API / resource callable / native object / Metal / AppKit。

拒绝。

## 本轮允许写集

- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_package_config_link.cj`。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与 topic manifests。

本轮不修改 `runtime/cjgui/cjpm.toml`，不修改 production native C ABI 行为，不新增 runtime call owner。

## 停止线

- no package config mutation。
- no actual runtime FFI call。
- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object creation。
- no retain / release / destroy。
- no drawable / command buffer / `commit` / `present`。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## 同形边界刹车

不得把 package config link preflight、script-managed route、package call support facts、temporary package success 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，package config link implementation runway 进入 script-managed stabilization route。
- 本轮是否改变 canonical tail / endpoint：预期新增 `CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期新增 owner；truth 限定为 artifact policy、config blocker 与 script-managed fallback facts；stop-line 不放宽。
- 本轮是否改变唯一 next opening：预期由后续 next-boundary / manifest 固定。
- 是否同步 topic manifest：将同步。
- 已同步哪些 topic manifest：后续 closure / manifest 中记录。
