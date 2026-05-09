# P1 渲染器 native bridge callable C ABI 第一实现收口复核

日期：2026-05-09

状态：implementation closure / no-resource callable only

## 文件定位

本 closure 记录 production native skeleton 已新增第一批 no-resource callable `C ABI`。本轮只修改 production native skeleton 与 probe 脚本，不接仓颉 FFI，不新增 runtime `.cj` FFI declaration，不修改 build config，不创建 native object。

## 实现范围

修改文件：

- [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)
- [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
- [verify_native_bridge_skeleton_compile.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh)
- [verify_native_bridge_cjpm_integration_boundary.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh)

新增 callable allowlist：

- `cjgui_native_bridge_surface_version(void)`
- `cjgui_native_bridge_surface_capabilities(void)`
- `cjgui_native_bridge_status_ok(void)`
- `cjgui_native_bridge_no_resource_admission(void)`

## 当前 truth

本轮 truth 只限 production native no-resource callable facts：

- surface version query。
- surface capability query。
- status taxonomy query。
- no-resource bridge admission query。
- probe allowlist 与 object symbol allowlist。

这些 callable 都是 deterministic、side-effect-free、no-resource、no-pointer-return；不读写 runtime state，不访问 global mutable state，不创建 native object，不依赖 AppKit / Metal。

## 暂缓与禁止

main-thread query 暂缓到后续独立 preflight。原因是本轮不引入 Foundation / pthread / Cocoa / Metal / QuartzCore 依赖判断，避免扩大 production native skeleton 的平台边界。

本轮仍禁止 FFI、runtime `.cj` FFI declaration、`runtime/cjgui/cjpm.toml` 修改、package / build config 修改、native handle / raw pointer、native pointer return、AppKit / Metal object、retain / release / destroy、drawable、command buffer、GPU submission、render、renderer state write、`runtime_state.cj` 修改、public runtime API / diagnostics 与 smoke native edits。

## GitNexus 影响记录

编辑前已对上游 planning endpoint 运行 impact：

- `CjguiInternalRendererNoCallableCAbiReadiness`：`Target not found`，impactedCount `0`，risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererCallableCAbiDraft`：`Target not found`，impactedCount `0`，risk `UNKNOWN`。

没有收到 `HIGH` / `CRITICAL` 风险。本轮最终 GitNexus detect changes 结果在 manifest stabilization closure 中固定。

## 初始验证记录

实现后已先行验证：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过，输出保留 no `cjpm` native source inclusion、no FFI、no resource/native-object callable C ABI。

完整验证结果：

- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过，确认 no `cjpm` native source inclusion、no FFI、no resource/native-object callable `C ABI`。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-callable-c-abi-first-implementation-target --skip-script`：通过，仅保留既有 `230 warnings`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过。
- `git diff --check`：通过。
- 新 native / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- Markdown 中文标题与正文抽查：通过。
- protected path check：`runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行，tracked diff 为 `0`。
- comment-aware public declaration scan：仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- native forbidden scan：通过，未出现 smoke callable name、Cocoa / Metal / QuartzCore import、AppKit / Metal object、pointer return、native handle / token return。
- GitNexus `detect_changes(scope=unstaged)`：risk `low`，affected processes `0`，affected_count `17 files / 18 symbols`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，callable `C ABI` 从 planning 推进到 no-resource first implementation。
- 本轮是否改变 canonical tail / endpoint：否，runtime planning endpoint 仍是 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`；本轮新增的是 production native callable symbols。
- 本轮是否改变 owner / truth / stop-line：是，production native skeleton truth 从 no callable skeleton 扩展为 no-resource callable surface；stop-line 继续禁止 FFI、native object、pointer、AppKit / Metal、state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI first implementation next-boundary decision`。
- 是否同步 topic manifest：是。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 后续入口

`P1 internal Renderer native bridge callable C ABI first implementation next-boundary decision`
