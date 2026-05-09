# P1 渲染器 native bridge callable C ABI 第一实现预检

日期：2026-05-09

状态：preflight decision / no-resource callable only

## 文件定位

本预检判断是否可以从 callable `C ABI` planning manifest 进入第一批 production native callable implementation。结论只覆盖 no-resource callable surface，不接仓颉 FFI，不新增 runtime `.cj` FFI declaration，不修改 build config，不创建 native object，不创建 native handle / raw pointer。

本文件不是 runtime truth，不是 public API 承诺，也不是 native bridge ready、backend ready、Metal / AppKit ready 或 renderer ready permission。

## 上游证据

已读取并确认：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [P1 设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)
- [callable C ABI planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-callable-c-abi-planning-manifest.md)
- [callable C ABI planning manifest closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-internal-renderer-native-bridge-callable-c-abi-planning-manifest-stabilization-closure-review.md)
- [native bridge C ABI surface contract manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-c-abi-surface-contract-manifest.md)
- [production native bridge skeleton write-set manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-production-native-bridge-skeleton-write-set-manifest.md)
- [native bridge cjpm integration first implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-cjpm-integration-first-implementation-manifest.md)
- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`

## GitNexus 影响记录

编辑 production native callable surface 前已运行 GitNexus impact：

- `CjguiInternalRendererNoCallableCAbiReadiness`：`Target not found`，impactedCount `0`，risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererCallableCAbiDraft`：`Target not found`，impactedCount `0`，risk `UNKNOWN`。

该结果与近期新增 owner 尚未被索引的状态一致。本轮没有收到 `HIGH` / `CRITICAL` 风险；继续使用源码、probe、`cjpm build`、smoke 与禁区扫描兜底。

## 取舍结论

选择 `P1 internal Renderer native bridge callable C ABI first implementation bundle`。

允许第一批 callable 只使用 `cjgui_native_bridge_*` 前缀，并且只返回 deterministic `uint32_t` facts：

- `cjgui_native_bridge_surface_version(void)`
- `cjgui_native_bridge_surface_capabilities(void)`
- `cjgui_native_bridge_status_ok(void)`
- `cjgui_native_bridge_no_resource_admission(void)`

这些函数只表达 version / capability / status taxonomy / no-resource admission facts。它们不创建资源，不返回 pointer，不读写 global mutable state，不访问 AppKit / Metal，不接仓颉 FFI，也不改变 runtime truth。

## 暂缓项

main-thread query / classification 暂缓。本轮为了保持 production skeleton 不导入 Cocoa / Metal / QuartzCore，也避免引入 Foundation / pthread 依赖判断，只先实现不需要平台框架的 version / capability / status / no-resource admission callable。

runtime FFI declaration 暂缓。native callable implementation 与仓颉 runtime FFI 必须拆阶段，后续另开 `P1 internal Renderer native bridge runtime FFI syntax / link preflight decision`。

## 明确禁止

- 不使用 `cjgui_app_run`。
- 不使用 `cjgui_last_error_*`。
- 不接 FFI。
- 不新增 runtime `.cj` FFI declaration。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 package / build config。
- 不创建 native handle / raw pointer。
- 不返回 native pointer。
- 不创建 `NSWindow` / `NSView` / `CAMetalLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不导入 Cocoa / Metal / QuartzCore。
- 不调用 retain / release / destroy。
- 不获取 drawable / `nextDrawable`。
- 不创建 command buffer / `commandBuffer`。
- 不调用 `commit` / `present`。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不修改 `runtime/cjgui/src/runtime_state.cj`。
- 不新增 public runtime API / diagnostics。
- 不修改 smoke native files。

## 同形边界刹车

不得把 no-resource callable `C ABI` 包装成 FFI permission、runtime callable permission、native object permission、native-handle permission、Metal / AppKit permission、backend-ready permission、GPU-submission permission、render permission、public API permission、receipt、record 或 publication。

第一批 callable 只证明 production native surface 有 side-effect-free C functions，不证明 runtime bridge integrated。

## 后续同步要求

实现完成后必须同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX、三个 topic manifest，并给 callable planning manifest、C ABI surface manifest、production skeleton manifest、`cjpm` integration manifest 补 downstream 指向。

## 设计意图出口自检

- 本轮是否改变主题状态：是，callable `C ABI` 从 planning 进入 first implementation preflight。
- 本轮是否改变 canonical tail / endpoint：否，runtime planning endpoint 仍是 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`；本预检只批准 production native no-resource callable surface。
- 本轮是否改变 owner / truth / stop-line：是，允许 production native skeleton `.h` / `.m` 承载第一批 no-resource callable；stop-line 继续禁止 FFI、native object、pointer、AppKit / Metal、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI first implementation bundle`。
- 是否同步 topic manifest：是，将在本宏包实现与 manifest stabilization 中同步。
- 已同步的 topic manifest：本预检先记录同步要求，最终 closure 固定同步路径。

## 后续入口

`P1 internal Renderer native bridge callable C ABI first implementation bundle`
