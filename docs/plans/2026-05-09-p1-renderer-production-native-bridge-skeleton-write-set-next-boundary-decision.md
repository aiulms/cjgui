# P1 渲染器 production native bridge skeleton 写集后续边界判断

日期：2026-05-09

状态：docs-only next-boundary / no callable C ABI

## 文件定位

本 decision 在 production native bridge skeleton 写集落地后，判断下一步应进入 build system integration preflight，还是先完成 skeleton manifest stabilization。

本轮不修改 `.cj`，不新增 runtime owner，不实现 callable C ABI / FFI，不修改 build config，不修改 smoke lab，不创建 native object、native handle、Metal / AppKit resource、backend ready truth、GPU work、renderer state write 或 public API。

## 当前判断

[production native bridge skeleton write-set closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-production-native-bridge-skeleton-write-set-contract-closure-review.md) 已确认允许写集内的两个 skeleton 文件存在：

- [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)

当前 skeleton 只包含 contract comments 与 status taxonomy enum，不包含 callable C ABI function，不接 FFI，不导入 Cocoa / Metal / QuartzCore，不创建 native object，也不复用 smoke lab callable surface 名称。

因此 skeleton 文件足够进入 manifest stabilization，先固定 allowed write set、forbidden write set、no build integration 与 stop-line。build system integration 风险需要下一阶段单独 preflight，而不是在本轮跳过 manifest。

## 候选比较

A 推荐但后置：`P1 internal Renderer native bridge build system integration preflight decision`。

后置原因：production `.m` 是否进入 `cjpm` build 仍需规划，但当前 skeleton 未修改 build config，也未要求编译进包；先封账 skeleton manifest 更稳。

B 本轮选择：`P1 internal Renderer production native bridge skeleton manifest stabilization bundle implementation`。

选择原因：skeleton 写集已足够作为本阶段落点，且 build system 风险已被明确隔离为后续 preflight。manifest stabilization 可以固定本轮新增 native 文件的 owner / truth / stop-line，避免后续误把 skeleton 当作 callable bridge。

C 暂缓：smoke-to-production extraction hardening。

暂缓原因：本轮没有搬运 smoke implementation，暂无 extraction 缺口。

D 拒绝：直接 callable C ABI / FFI implementation。

E 拒绝：direct AppKit / Metal object creation。

F 拒绝：public API / renderer state write / backend-ready truth。

## 同形边界刹车

不得把 skeleton `.h` / `.m`、C ABI surface contract、token ownership、teardown planning 或 smoke evidence 包装成 native bridge implementation permission、C ABI callable permission、FFI permission、native-handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

下一步若进入 manifest stabilization，只能固定 skeleton 写集和 stop-line，不得新增 callable behavior。

## 停止线

- no callable C ABI implementation。
- no FFI declaration。
- no runtime `.cj` FFI declaration。
- no build config / package config modification。
- no native handle / raw pointer。
- no raw pointer return。
- no native object creation。
- no Metal / AppKit resource creation。
- no drawable / command buffer / GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no public diagnostics。
- no public API。
- no smoke lab native modification。

## 设计意图出口自检

- 本轮是否改变主题状态：是。production native bridge skeleton 写集进入 manifest stabilization 阶段。
- 本轮是否改变 canonical tail / endpoint：否。runtime canonical endpoint 仍是 `CjguiInternalRendererNoNativeBridgeTeardownImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownPlanDraft()`。
- 本轮是否改变 owner / truth / stop-line：不改变 runtime owner / truth；确认 skeleton artifact stop-line 必须保持 no callable C ABI / no FFI / no native object / no build integration。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer production native bridge skeleton manifest stabilization bundle implementation`。
- 是否同步 topic manifest：本宏包末尾统一同步。
- 已同步的 topic manifest：待本宏包封账同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 唯一后续入口

`P1 internal Renderer production native bridge skeleton manifest stabilization bundle implementation`
