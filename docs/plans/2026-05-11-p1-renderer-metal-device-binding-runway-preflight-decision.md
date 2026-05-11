# Metal device binding 路线预检结论

## 范围

本轮从 `CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness` 继续推进 Metal device binding 路线。预检结论是可以在 production native bridge 内进入 A / B / C 连续切片：

- A：允许 `#import <Metal/Metal.h>`，观察 default `MTLDevice` availability，但不创建 command queue / drawable。
- B：允许固定容量很小的 token-backed `MTLDevice` create / classify / destroy first slice，token 仍是不透明整数，不是 pointer cast。
- C：允许把 token-backed `MTLDevice` 绑定到 token-backed `CAMetalLayer`，并支持 unbind / classify / double-unbind fail-closed；仍不调用 `nextDrawable`，不创建 command queue / command buffer，不提交 GPU work。

## 预检判断

- 上游 endpoint：`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`。
- 上游 default draft：`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft()`。
- 上游 owner：[runtime_renderer_cametallayer_attachment_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_cametallayer_attachment_runtime_call.cj)。
- 当前 `CAMetalLayer` attachment runtime call 已证明 token 局部使用、attach / detach / cleanup 归零、无 renderer state write、无 public API。
- Metal device binding 第一阶段不需要 `nextDrawable`、command queue、command buffer、encoder、GPU submission 或 render。
- `MTLDevice` token table 可以固定容量为 `2`，并在 destroy 前要求 layer unbind，避免 dangling binding。
- Layer binding / unbinding 必须 main-thread；invalid / stale / destroyed token 必须 fail-closed。
- `runtime/cjgui/cjpm.toml` 不需要修改；script-managed link probes 只需把 Metal framework 纳入临时 link 选项。

## GitNexus 影响面

已对上游 endpoint / default draft 与新增 symbol 运行 upstream impact。`CjguiInternalRendererNoCAMetalLayerAttachmentRuntimeCallReadiness`、`cjguiInternalExecuteDefaultRendererCAMetalLayerAttachmentRuntimeCallDraft`、`CjguiInternalRendererNoMetalDeviceAvailabilityReadiness`、`CjguiInternalRendererNoMetalDeviceCreateDestroyReadiness`、`CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`、`cjgui_native_bridge_metal_default_device_create`、`cjgui_native_bridge_metal_device_destroy`、`cjgui_native_bridge_cametallayer_bind_metal_device` 均返回近期未索引 / not found，`affected_count=0`，未出现 HIGH / CRITICAL。按近期新增 owner 未索引处理，由 source、build、probe 与 forbidden scan 兜底。

## 选择

本轮选择完成 C：`P1 internal Renderer Metal device CAMetalLayer binding first slice`。

## 停止线

本轮不调用 `nextDrawable`，不获取 drawable，不创建 `MTLCommandQueue`、command buffer 或 encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮改变主题状态：是，Renderer native bridge 从 `CAMetalLayer` runtime attachment call 推进到 Metal device layer binding first slice。
- 本轮改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。
- 本轮改变 owner / truth / stop-line：是，新增 Metal availability、device create/destroy、device-layer binding owner；stop-line 保持 no drawable / no command queue / no GPU work / no renderer state write。
- 本轮改变唯一 next opening：是，若验证封账后进入 `P1 internal Renderer drawable acquisition planning preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：将在本轮同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
