# P1 内部渲染器 CAMetalLayer no-attach 类可见性与 runtime 调用阶段封账

日期：2026-05-11

状态：closure review / A 路线已落地

## 本轮结论

本轮完成 macro bundle 的 A 路线：QuartzCore / `CAMetalLayer` no-attach class availability 与 runtime internal FFI call owner 已落地。Actual route 是 production bridge no-attach C ABI + internal runtime owner + no-attach probe。

本轮没有推进 B / C / D：没有创建 `CAMetalLayer` / `CALayer`，没有 token-backed `CAMetalLayer` table，没有 attach 到 token-backed `NSView`，没有导入 Metal，也没有创建 `MTLDevice` / command queue / drawable / command buffer。

## 实际写集

- 修改 [cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h)，新增 no-attach capability、classification 与 callable declaration。
- 修改 [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)，允许 QuartzCore import，只做 `NSClassFromString(@"CAMetalLayer")` 与 blocked facts。
- 新增 [runtime_renderer_cametallayer_no_attach_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_cametallayer_no_attach_call.cj)。
- 新增 [verify_native_bridge_cametallayer_no_attach.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_cametallayer_no_attach.sh)。
- 更新已有 native / package probe allowlist 与 link flags，使 QuartzCore no-attach class lookup 可复核。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure。
- 同步 README、tracker、plans README、runtime README、设计意图索引与三个 topic manifest。

未修改：

- `runtime/cjgui/cjpm.toml`
- `runtime/cjgui/src/runtime_state.cj`
- `labs/macos_bridge_smoke` native files
- public runtime API / diagnostics

## Owner 与 C ABI

Runtime owner：

- Owner：`runtime/cjgui/src/runtime_renderer_cametallayer_no_attach_call.cj`
- Endpoint：`CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`
- Runtime input：`CjguiInternalRendererNoCAMetalLayerAttachmentReadiness`

新增 no-attach C ABI：

- `cjgui_native_bridge_quartzcore_import_available(void)`
- `cjgui_native_bridge_cametallayer_class_available(void)`
- `cjgui_native_bridge_cametallayer_no_attach_admission(void)`
- `cjgui_native_bridge_cametallayer_allocation_still_blocked(void)`
- `cjgui_native_bridge_cametallayer_device_binding_still_blocked(void)`

这些 callable 只返回 `int32_t` classification status，不返回 pointer / handle / `id` / `Class`。

## 固定停止线

- QuartzCore import 已允许，但只用于 no-attach class lookup / static availability facts。
- 不 import Metal。
- 不创建 `CAMetalLayer` / `CALayer`。
- 不设置 `NSView.layer` 或 `wantsLayer`。
- 不创建 `MTLDevice` / `MTLCommandQueue`。
- 不获取 drawable，不调用 `nextDrawable`。
- 不创建 command buffer，不调用 `commandBuffer` / `commit` / `present`。
- 不写 renderer state，不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 public API / diagnostics。
- 不把 no-attach class lookup 或 runtime facts 包装成 backend-ready、render permission、GPU submission、state write、receipt、record 或 publication。

## 下游入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`

该入口只能评估是否允许 main-thread immediate-release allocation feasibility；仍不得 attach 到 `NSView`，不得绑定 Metal device，不能获取 drawable、render 或写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 `CAMetalLayer` attachment planning 推进到 no-attach QuartzCore / class lookup / runtime internal call owner。
- 本轮是否改变 canonical tail / endpoint：是，最新 endpoint 为 `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 `runtime_renderer_cametallayer_no_attach_call.cj`；truth 限定为 no-attach observed facts；stop-line 继续禁止 layer allocation / attachment、Metal、drawable、GPU submission、renderer state write、public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
