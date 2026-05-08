# P1 内部 Renderer 真实 Metal device-layer 第一刀实现切片闭环复核

日期：2026-05-07

本轮性质：implementation slice / internal-only owner shell。

## 本轮定位

本轮承接 [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)，新增一个极窄 internal owner shell：[runtime_renderer_metal_device_layer_real.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj)。

该 owner 只表达 real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts。它是 dehydrated native result facts，不是真实 `MTLDevice` / `CAMetalLayer` 创建，不修改 native bridge、Objective-C、Metal、AppKit，也不新增 C ABI / FFI。

## 落地内容

新增 internal symbols：

- `CjguiInternalRendererRealMetalDeviceLayerIntent`
- `CjguiInternalRendererRealMetalDeviceShellPolicy`
- `CjguiInternalRendererRealMetalLayerBindingShellPolicy`
- `CjguiInternalRendererRealMetalDeviceLayerTeardownProof`
- `CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- `cjguiInternalBuildRendererRealMetalDeviceLayerIntent(...)`
- `cjguiInternalBuildRendererRealMetalDeviceShellPolicy(...)`
- `cjguiInternalBuildRendererRealMetalLayerBindingShellPolicy(...)`
- `cjguiInternalBuildRendererRealMetalDeviceLayerTeardownProof(...)`
- `cjguiInternalBuildRendererNoRealMetalDeviceLayerReadiness(...)`
- `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`

固定事实：

- owner file：`runtime/cjgui/src/runtime_renderer_metal_device_layer_real.cj`
- canonical endpoint：`CjguiInternalRendererNoRealMetalDeviceLayerReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`
- runtime input：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`
- current truth：real Metal device-layer intent / device shell policy / layer binding shell policy / teardown proof / no-real-metal-device-layer readiness facts

## 失败关闭与延迟姿态

open path 只形成 dehydrated shell facts。若 upstream endpoint 处于 defer-only，新的 intent 与后续 policy 继续保持 defer；若 upstream blocked、inconsistent 或缺少关键 no-side-effect facts，则 fail-closed，不生成 ready permission。

该 endpoint 不把 `CjguiInternalRendererNoNativeTeardownImplementationReadiness` 或 `CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness` 包成 Metal-ready、device-ready、layer-ready、backend-ready、resource-ready、receipt、record 或 publication wrapper。

## 停止线

本轮保持以下停止线：

- no native bridge modification。
- no Objective-C / Metal / AppKit modification。
- no C ABI / FFI declaration。
- no bridge call。
- no retain / release / destroy。
- no native handle。
- no raw pointer。
- no real `MTLDevice`。
- no real `CAMetalLayer`。
- no `MTLCommandQueue`。
- no drawable。
- no command buffer。
- no render pass。
- no encoder。
- no pipeline state。
- no shader / descriptor creation。
- no draw call。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no backend ready truth。
- no public diagnostics / API。
- no public API expansion。

## 下游同步

本闭环同步到：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [real Metal device-layer first implementation preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-preflight-decision.md)
- [native teardown contract hardening manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-native-teardown-contract-hardening-manifest.md)
- [real backend platform object first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-backend-platform-object-first-implementation-slice-manifest.md)
- [Metal device-layer implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-metal-device-layer-implementation-admission-manifest.md)
- [Metal device-layer owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-metal-device-layer-owner-manifest.md)

## 验证记录

- GitNexus impact 已按要求先跑四个符号：`CjguiInternalRendererNoNativeTeardownImplementationReadiness`、`cjguiInternalExecuteDefaultRendererNativeTeardownContractDraft`、`CjguiInternalRendererNoMetalDeviceLayerImplementationReadiness`、`cjguiInternalExecuteDefaultRendererMetalDeviceLayerAdmissionDraft`。当前索引未命中这些近期 internal 符号，返回 risk `UNKNOWN` 与 impacted count `0`；本轮未修改这些既有符号，只新增独立 owner shell。
- `cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script` 已尝试执行，但当前 shell 与交互式 zsh 均未找到 `cjpm`，因此 build 受本机工具链 PATH 限制未完成。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 通过，auto-close log assertions passed。
- `git diff --check` 通过。
- 新 runtime / closure no-index whitespace check 通过。
- Markdown absolute link missing target check 通过，限定 project docs scope 并避开 `reference_repos/`。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 通过。
- Markdown 中文标题与中文正文抽查通过；本轮新增 closure 未使用 `Decision` / `Boundary` / `Verification` / `Next Opening` 作为主标题。
- forbidden check 通过：protected paths 无 diff/status，`runtime/cjgui/src/runtime_state.cj` 行数仍为 `10065`，无 tracked `.cj` diff。
- comment-aware public declaration scan 通过，仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- new owner stop-line scan 通过，未出现真实 native bridge / Objective-C / AppKit 修改、C ABI / FFI declaration、native handle / raw pointer、retain / release / destroy、真实 `MTLDevice` / `CAMetalLayer`、`MTLCommandQueue`、drawable、command buffer、render pass、encoder、pipeline state、draw call、GPU submission、renderer state write、module-level `var` 或 public diagnostics / API。
- 文件头维护注释检查通过：Owner / Truth / Stop-line / Same-shape Boundary Brake 均存在。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)` 完成，summary risk_level 为 `low`，affected_count 为 `0`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 real Metal device-layer first implementation preflight completed 推进到 first implementation slice completed。
- 本轮是否改变 canonical tail / endpoint：是，最新 runtime shell endpoint 变为 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner file、current truth 与 stop-line；未修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、smoke、harness、entry 或 protected paths。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`。
- 是否需要同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。
- 若未同步，理由：不适用。

## 唯一后续入口

`P1 internal Renderer real Metal device-layer first implementation slice closure / next real Metal device-layer decision`

## 下游切片后续边界决策

下游 real Metal device-layer first implementation slice next-boundary decision 已完成：

- [real Metal device-layer first implementation slice next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-next-boundary-decision.md)

该 decision 确认 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()` 足够作为当前 no-real-metal-device-layer shell endpoint，但本 closure 记录的 `cjpm build` 未完成仍是验证缺口。下一步先补 build verification follow-up，不把本 closure、owner shell 或 smoke evidence 升格为真实 `MTLDevice` / `CAMetalLayer` permission、native bridge permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice build verification follow-up`

## 下游 build 验证跟进

下游 real Metal device-layer first implementation slice build verification follow-up 已完成：

- [real Metal device-layer first implementation slice build verification follow-up](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-build-verification-follow-up.md)

该 follow-up 已恢复 `cjpm` / `cjc` toolchain env，并完成 required build attempt。build 未通过，失败归类为代码问题：`runtime_renderer_metal_device_layer_real.cj` 中 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness(...)` 4 个构造分支 expected 30 arguments, found 31。该失败不授权 manifest stabilization、native bridge / Objective-C / Metal / AppKit modification、真实 `MTLDevice` / `CAMetalLayer`、command queue、drawable、command buffer、GPU submission、renderer state write、backend ready truth 或 public API。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first slice build fix bundle`

## 下游 build 恢复闭环

下游 real Metal device-layer first slice build recovery and stabilization 已完成：

- [real Metal device-layer first slice build recovery closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-slice-build-recovery-stabilization-closure-review.md)

该闭环确认上一段 build failure 根因是 `runtime_renderer_metal_device_layer_real.cj` 内构造参数数量 / 顺序不一致；修复只限该 owner，未修改 native bridge、Objective-C、Metal、AppKit、C ABI / FFI、smoke、harness、entry 或 protected paths。`cjpm build --target-dir /tmp/cjgui-renderer-real-metal-device-layer-first-slice-target --skip-script` 通过，auto-close smoke 通过；本 closure 记录的 build gap 已关闭。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer first implementation slice manifest stabilization bundle implementation`

## 下游 manifest 封账

下游 real Metal device-layer first implementation slice manifest stabilization 已完成：

- [real Metal device-layer first implementation slice manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-renderer-real-metal-device-layer-first-implementation-slice-manifest.md)
- [real Metal device-layer first implementation slice manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-07-p1-internal-renderer-real-metal-device-layer-first-implementation-slice-manifest-stabilization-closure-review.md)

该 manifest 固定本 closure 新增 owner shell 的 `CjguiInternalRendererNoRealMetalDeviceLayerReadiness` / `cjguiInternalExecuteDefaultRendererRealMetalDeviceLayerShellDraft()`，但不把 owner shell、build recovery、reference evidence 或 smoke evidence 升格为真实 `MTLDevice` / `CAMetalLayer` permission、native bridge permission、backend-ready permission、GPU submission permission、renderer state write permission 或 public API permission。

新的下游后续入口：

`P1 internal Renderer real Metal device-layer branch closure / next real Metal device-layer decision`
