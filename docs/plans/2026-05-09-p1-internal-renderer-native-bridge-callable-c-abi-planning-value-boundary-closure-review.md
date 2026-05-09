# P1 渲染器 native bridge callable C ABI planning value boundary 收口复核

日期：2026-05-09

状态：implementation closure / internal value boundary only

## 文件定位

本 closure 记录 callable `C ABI` planning value boundary 已新增并通过构建验证。该 value boundary 只表达 callable naming、status / capability callable admission、no-resource guard、runtime FFI separation 与 no-callable-C-ABI readiness facts，不修改 production native `.h` / `.m`，不实现 callable `C ABI`，不接 FFI。

## 新增 owner

- Owner file：[runtime_renderer_native_bridge_callable_c_abi.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_callable_c_abi.cj)
- Runtime input：`CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness`
- Default upstream draft：`cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft()`
- Canonical endpoint：`CjguiInternalRendererNoCallableCAbiReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`

## 新增语义

- `CjguiInternalRendererCallableCAbiPlanningIntent`
- `CjguiInternalRendererCallableCAbiNamingPolicy`
- `CjguiInternalRendererStatusCapabilityCallableAdmissionPolicy`
- `CjguiInternalRendererNoResourceCallableGuard`
- `CjguiInternalRendererRuntimeFfiSeparationPolicy`
- `CjguiInternalRendererNoCallableCAbiReadiness`

这些类型只承载 internal-only dehydrated facts：callable planning intent、production callable naming policy、status / capability query admission、no-resource callable guard、runtime FFI separation 与 no-callable-C-ABI readiness。

## GitNexus 影响记录

编辑 runtime owner 前已对上游入口运行 GitNexus impact：

- `CjguiInternalRendererNoNativeBridgeBuildSystemImplementationReadiness`：返回 `UNKNOWN / Target not found`，impactedCount `0`，risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererNativeBridgeBuildSystemAdmissionDraft`：返回 `UNKNOWN / Target not found`，impactedCount `0`，risk `UNKNOWN`。

该结果符合近期新增 owner 尚未被索引的现状。本轮没有忽略 `HIGH` / `CRITICAL` 风险；由于没有返回高风险，按任务要求继续使用源码、构建、smoke 与扫描兜底。

## 边界确认

本轮没有修改 `runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m`、`runtime/cjgui/cjpm.toml`、smoke native files、runtime `.cj` FFI declaration、public API files 或 `runtime_state.cj`。

本轮没有实现 callable `C ABI`，没有接 FFI，没有创建 native handle / raw pointer，没有返回 native pointer，没有 import / use Cocoa / Metal / QuartzCore in production skeleton，没有创建 AppKit / Metal object，没有调用 retain / release / destroy，没有提交 GPU work，没有执行 render，没有写 renderer state，也没有发布 public diagnostics。

## 构建记录

初始构建验证已执行：

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh`
- 在 `runtime/cjgui` 执行 `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-callable-c-abi-planning-target --skip-script`

结果：通过，输出包含 `cjpm build success`，仅保留既有 `230 warnings generated, 230 warnings printed.`。

## 最终验证记录

本宏包统一验证已完成：

- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_integration_boundary.sh`：通过，确认仍没有 `cjpm` native source inclusion、callable `C ABI` 或 FFI。
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`：通过，确认 production skeleton 仍只做 isolated compile / syntax check。
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-callable-c-abi-planning-target --skip-script`：通过，输出包含 `cjpm build success`，仅保留既有 `230 warnings generated, 230 warnings printed.`。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，输出包含 auto-close log assertions passed。
- `git diff --check`：通过。
- 新 runtime / docs no-index whitespace check：通过。
- Markdown absolute link missing target check：通过。
- README / tracker / plans README / runtime README reachability：通过。
- 中文标题与中文正文抽查：通过，新增 Markdown 主标题未使用 `Decision` / `Boundary` / `Verification` / `Next Opening`。
- forbidden check：`runtime_state.cj` 仍为 `10065` 行；protected tracked paths 无本轮 diff。
- comment-aware public declaration scan：仍只发现 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- owner header / stop-line scan：通过，文件头包含 Owner / Truth / Stop-line / Same-shape Boundary Brake，且实现级扫描未发现 callable `C ABI`、FFI、native pointer、AppKit / Metal object、GPU / render call、public API 或 module-level mutable `var`。
- native / build forbidden scan：通过；`runtime/cjgui/cjpm.toml`、production skeleton `.h` / `.m`、probe scripts 与 smoke native files 无本轮 diff；production skeleton 未出现 Cocoa / Metal / QuartzCore import、AppKit / Metal object、smoke callable name 或 callable implementation。
- GitNexus `detect-changes --scope unstaged`：`Changes: 17 files, 18 symbols`，`Affected processes: 0`，`Risk level: low`。

上述验证只证明 callable `C ABI` planning owner 可编译、文档链可达、边界扫描通过；不证明 callable implementation、FFI、native bridge implementation、native object、backend-ready truth、GPU submission、render、renderer state write 或 public API 可用。

## 设计意图出口自检

- 本轮是否改变主题状态：是。native bridge callable `C ABI` 从 preflight 推进到 internal value boundary。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoCallableCAbiReadiness` / `cjguiInternalExecuteDefaultRendererCallableCAbiDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner `runtime_renderer_native_bridge_callable_c_abi.cj`；truth 限于 callable planning facts；stop-line 继续禁止 production native edits、callable implementation、FFI、native object、renderer state write 与 public API。
- 本轮是否改变唯一 next opening：是，改为 `P1 internal Renderer native bridge callable C ABI planning manifest stabilization bundle` 之前的 next-boundary decision。
- 是否同步 topic manifest：是，本宏包同步三个 Renderer / smoke 相关 topic manifest。
- 已同步的 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。

## 后续入口

`P1 internal Renderer native bridge callable C ABI planning next-boundary decision`
