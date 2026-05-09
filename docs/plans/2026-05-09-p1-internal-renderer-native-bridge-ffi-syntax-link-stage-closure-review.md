# P1 内部渲染器 native bridge FFI 语法与链接阶段收口复核

日期：2026-05-09

状态：closure review / planning owner added

## 文件定位

本 closure 封账 native bridge FFI syntax / link stage 的 runtime planning owner 与 isolated probe evidence。

本轮不写真实 runtime FFI declaration，不调用 native callable，不修改 `runtime/cjgui/cjpm.toml`，不创建 native object，不扩 public API。

## 新增 runtime owner

- Owner file：`runtime/cjgui/src/runtime_renderer_native_bridge_ffi_link.cj`
- Runtime input：`CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`
- Canonical endpoint：`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeFfiLinkDraft()`

## 当前真相

`CjguiInternalRendererNoNativeBridgeFfiLinkReadiness` 只表达：

- native bridge FFI syntax / link intent。
- isolated probe evidence policy。
- no-resource callable link admission policy。
- runtime package link denial / fallback policy。
- public surface denial policy。
- no-native-bridge-FFI-link readiness facts。

它不是 runtime FFI call、真实 runtime FFI declaration、package link permission、native bridge implementation、native object permission、backend-ready truth 或 public API。

## GitNexus 影响检查

编辑 runtime owner 前已对上游入口执行 impact：

- `CjguiInternalRendererNoNativeBridgeFfiDeclarationReadiness`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。
- `cjguiInternalExecuteDefaultRendererNativeBridgeFfiDeclarationDraft`：GitNexus 返回 UNKNOWN / not found，按近期新增 owner 未索引处理。

未出现 HIGH / CRITICAL 风险。后续以源码、`cjpm build`、probe 与扫描兜底。

## 验证证据

- `labs/native_bridge_ffi_probe/scripts/build_and_run.sh` 通过，证明 isolated `foreign func` syntax 与 direct `cjc` link 可行。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-ffi-syntax-link-stage-target --skip-script` 已通过，只有既有 unused warnings。

## 未完成事项

`runtime/cjgui` package 仍未接入 production `.m` package link。当前没有 `[ffi.c]`、没有 production native source inclusion、没有 runtime FFI call。

因此下一步不应直接进入 runtime callable implementation，而应先规划 package link integration。

## 停止线

- no actual runtime FFI call。
- no public API / diagnostics。
- no resource callable。
- no native object / handle / raw pointer。
- no native pointer return。
- no Metal / AppKit usage。
- no renderer state write。
- no `runtime_state.cj` modification。
- no production `.m` package link in this stage。
- no backend-ready truth。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`、isolated FFI probe、direct `cjc` link evidence、symbol probe 或 planning facts 包装成 runtime FFI permission、runtime callable permission、package integration permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 设计意图出口自检

- 本轮是否改变主题状态：是，FFI syntax / link stage 已新增 planning owner 并获得 isolated probe evidence。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeFfiLinkReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_native_bridge_ffi_link.cj`；truth 只限 syntax / link planning 与 package link fallback；stop-line 继续禁止 runtime FFI call 与 public / native resource。
- 本轮是否改变唯一 next opening：是，转向 package link integration preflight。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
