# P1 内部渲染器 platform object NSView runtime FFI call owner 阶段封账

日期：2026-05-10

状态：closure review / first slice 已落地

## 本轮结论

本轮完成 `P1 internal Renderer platform object NSView runtime FFI call owner stage bundle` 的 first slice。Actual route 是真实 runtime internal owner + runtime-adjacent verification probe：新增 owner 复用同 package 已验证的 `foreign func` declarations，执行局部 `NSView` create / classify / destroy / stale / double-destroy 序列，并把观察结果脱水为 internal facts。

本轮没有重复声明 `cjgui_native_bridge_nsview_*` C ABI。原因是上游 [runtime_renderer_platform_object_nsview_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_nsview_create_destroy.cj) 已声明同名 `foreign func`，且 `CPointer<UInt64>` + `inout createdToken` out-token 语法已经通过主包 build。新 owner 只复用既有声明，避免 duplicate declaration 风险。

## 实际写集

- 新增 [runtime_renderer_platform_object_nsview_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj)。
- 新增 [verify_native_bridge_nsview_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。

未修改：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/src/runtime_state.cj`
- `labs/macos_bridge_smoke` native files
- public runtime API / diagnostics

## Owner 与 truth

- Owner：`runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj`
- Endpoint：`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`

Current truth 只包括：

- existing foreign declarations reused。
- out pointer syntax stable。
- runtime internal call executed。
- opaque token stayed internal。
- create / classify / destroy lifecycle observed。
- occupied count `0 -> 1 -> 0` observed。
- destroyed token stale observed。
- double destroy fail-closed observed。
- invalid token fail-closed observed。
- main-thread destroy gate observed。
- no pointer / handle / `id` / `Class` return。
- no `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer` / Metal / QuartzCore。
- no public surface。
- no renderer state write。
- no backend-ready truth。

## Runtime-adjacent probe

新增 probe 使用 production native bridge 编译 static archive，并生成临时仓颉 package 验证同一组 C ABI：

- `cjgui_native_bridge_nsview_create`
- `cjgui_native_bridge_nsview_destroy`
- `cjgui_native_bridge_nsview_token_classify`
- `cjgui_native_bridge_nsview_table_occupied_count`
- `cjgui_native_bridge_nsview_double_destroy_classify`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread`

Probe 观察到的预期序列是 create -> classify valid -> occupied count increment -> destroy -> classify stale -> double destroy fail-closed，并检查 `runtime/cjgui/cjpm.toml` 未发生 native bridge wiring。

## GitNexus 影响记录

- `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft`：GitNexus impact 返回 not found / `UNKNOWN` / impacted count `0`。

该结果按近期新增 owner 尚未索引处理。本轮用源码阅读、主包 build、runtime-adjacent probe、public declaration scan、native forbidden scan、protected path scan 与 GitNexus detect changes 兜底。

## 停止线

- 不新增 public API / diagnostics。
- 不返回 token 到 public surface。
- 不返回 `Class` / `id` / pointer / handle。
- 不持久化 token 到 module-level mutable state。
- 不写 renderer state。
- 不修改 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 不导入 Metal / QuartzCore。
- 不把 runtime internal token facts 包装成 backend-ready、render permission、renderer state write permission、Metal layer permission、receipt / record / publication。

## 下游入口

唯一 next opening：

`P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`

该入口只能评估 token-backed `NSView` runtime-call facts 是否足够进入 renderer backend shell integration preflight；不得直接创建 layer、Metal device、command queue、drawable、command buffer、GPU submission、render execution、public API 或 renderer state write。

## 下游接续

下游 [NSView backend shell integration manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-backend-shell-integration-manifest.md) 已完成，并把 canonical tail 推进为 `CjguiInternalRendererNoBackendNsViewPlatformIntegrationReadiness` / `cjguiInternalExecuteDefaultRendererBackendNsViewPlatformIntegrationDraft()`。该下游只新增 internal value owner，不新增 native C ABI，不修改 production native bridge、`runtime/cjgui/cjpm.toml` 或 `runtime_state.cj`，不创建 layer / Metal resource，也不改变本 closure 的 no public / no pointer / no renderer state / no backend-ready stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 token-backed `NSView` create / destroy first slice 推进到 runtime internal FFI call owner first slice。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 为 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_platform_object_nsview_runtime_call.cj`；truth 限定为 runtime internal create / classify / destroy call facts；stop-line 继续禁止 public / pointer / window / layer / Metal / renderer state / backend-ready。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
