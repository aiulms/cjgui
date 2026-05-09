# P1 渲染器 native bridge cjpm package link implementation 预检结论

日期：2026-05-09

状态：docs-only preflight / 选择 script-managed cjpm package link route

## 文件定位

本文件记录从 native bridge package-adjacent link probe 进入 `cjpm` package link implementation stage 前的判断。它只定义本轮允许写集、实际路线和停止线，不批准 runtime FFI call、public API、resource callable、native object、Metal / AppKit 或 backend-ready truth。

## 上游证据

- 设计意图入口、topic manifest 与出口协议已读取。
- 上游 manifest 固定 `CjguiInternalRendererNoNativeBridgePackageLinkReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgePackageLinkDraft()`，并确认 package-adjacent probe 已通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh` 已证明 production no-resource native bridge object / static archive 可由 direct `cjc` link 调用。
- 仓颉 `cjpm` 文档说明 `compile-option` 与 `link-option` 可传递编译 / 链接选项，`[ffi.c]` 面向预编译 C 库路径；但尚未证明直接修改 `runtime/cjgui/cjpm.toml` 对 static package、macOS-only gating、non-macOS fallback 和 `--skip-script` 的组合足够稳。
- 本轮临时验证确认，临时仓颉 package 可通过 `compile-option = "--sysroot ..."` 与 `link-option = "-L ... -l..."` 链接 no-resource static archive 并运行四个 callable；该证据适合落为 script-managed `cjpm` package link probe，而不是直接把 `runtime/cjgui/cjpm.toml` 改成 runtime truth。

## 预检判断

package-adjacent link probe 足以进入 `cjpm` package link route 的验证阶段，但不足以直接修改 `runtime/cjgui/cjpm.toml`。原因是当前 `runtime/cjgui` 是 `output-type = "static"`，本阶段仍不允许 runtime FFI call；如果直接写入 package config，`cjpm build --skip-script` 未必能证明 native object 真实参与可调用路径，反而会制造 package-ready permission 的误读。

本轮选择 C：`P1 internal Renderer native bridge package link script-managed implementation manifest`。实际实现为新增 script-managed `cjpm` 临时 package link probe，并新增 runtime planning owner 记录该路线。`runtime/cjgui/cjpm.toml` 保持未修改。

## 允许写集

- 新增 `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`。
- 新增 `runtime/cjgui/src/runtime_renderer_native_bridge_cjpm_package_link.cj`。
- 新增本轮 closure、stage next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引和 topic manifests。

## 禁止写集

- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 production no-resource callable behavior。
- 不修改 smoke native files。
- 不新增 runtime FFI call 或 runtime `.cj` FFI declaration。
- 不新增 public API / diagnostics。
- 不创建 native object、native handle、raw pointer 或 native pointer return。
- 不导入 Cocoa / Metal / QuartzCore。
- 不触碰 `runtime/cjgui/src/runtime_state.cj`。

## 同形边界刹车

不得把 package-adjacent probe、临时 `cjpm` package link probe、direct `cjc` probe、FFI syntax evidence 或 no-resource callable 包装成 runtime FFI call permission、public API permission、resource callable permission、native object permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

Package link 只证明 no-resource native bridge linkage path 可复核，不证明 GUI backend ready。

## 后续入口

若 script-managed `cjpm` package link probe、runtime owner build 与扫描通过，本阶段继续进入 closure、stage next-boundary 与 manifest stabilization。预计唯一 next opening 可进入 `P1 internal Renderer native bridge runtime internal FFI declaration first implementation bundle`，但该后续仍必须保持 internal-only，并继续禁止 public API、resource callable、native object 与 Metal / AppKit。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native bridge package link 从 package-adjacent probe 推进到 script-managed `cjpm` package link implementation stage。
- 本轮是否改变 canonical tail / endpoint：预检允许新增 `CjguiInternalRendererNoNativeBridgeCjpmPackageLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：预检允许新增 owner；truth 仅限 script-managed `cjpm` package link route、macOS-only gate、runtime package config fallback 与 no-resource link policy；stop-line 继续禁止 runtime FFI call、public API、native object 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，本轮预期完成后转向 runtime internal FFI declaration first implementation bundle。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：将在本阶段 closure / manifest 中同步 `docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
