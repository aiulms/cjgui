# P1 渲染器 CAMetalLayer allocation/table runway 预检

日期：2026-05-11

状态：preflight decision / 选择推进到 create-destroy first slice

## 预检结论

`CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` 已封账，足以打开 `CAMetalLayer` allocation/table runway。本轮选择连续推进 A、B、C：

- A：`CAMetalLayer` allocation without attachment feasibility。
- B：`CAMetalLayer` token-backed table shell，不 attach。
- C：`CAMetalLayer` token-backed create/destroy first slice，不 attach、不设 device。

本轮拒绝 D：`CAMetalLayer` attach/detach to token-backed `NSView`。拒绝理由是 attachment 需要单独评估 `NSView.layer` / `wantsLayer` / detach 语义；本轮只能证明 layer token lifecycle，不证明 attachment permission。

## 风险门判断

- QuartzCore import 已由上游 no-attach owner 验证，允许继续使用。
- `CAMetalLayer` class availability 已可观察，允许进行 main-thread allocation feasibility。
- 允许 fixed-capacity table 保存 `CAMetalLayer*`，但 token 仍是不透明整数，不是 pointer cast，不进入 public surface。
- create/destroy 必须 main-thread，invalid / stale / double destroy 必须 fail-closed。
- destroy 只清空 table entry 并 revoke token，不 attach、不 detach、不设置 device。
- 不需要修改 `runtime/cjgui/cjpm.toml`。
- 不需要 public API、renderer state write、Metal import、`MTLDevice`、drawable 或 command buffer。

## 选择路线

选择 C：

`P1 internal Renderer CAMetalLayer token-backed create/destroy first slice`

该选择允许新增 production native C ABI、runtime internal owner 和 probes，但 stop-line 不变：不 attach 到 `NSView`，不设置 `NSView.layer` / `wantsLayer`，不 import Metal，不设置 `CAMetalLayer.device`，不调用 `nextDrawable`，不 render，不写 `runtime_state.cj`。

## GitNexus 预检

已对上游 endpoint / default draft 与 native callable 名称运行 impact：

- `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness`：not found / UNKNOWN。
- `cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft`：not found / UNKNOWN。
- `cjgui_native_bridge_surface_capabilities`：not found / UNKNOWN。
- `cjgui_native_bridge_cametallayer_allocation_feasible`：not found / UNKNOWN。
- `cjgui_native_bridge_cametallayer_create`：not found / UNKNOWN。

记录为近期新增 native/runtime owner 尚未索引；本轮用源码、build、probe、scan 与最终 `detect_changes` 兜底。未收到 HIGH / CRITICAL blast radius。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 no-attach class/runtime facts 进入 allocation/table runway。
- 本轮是否改变 canonical tail / endpoint：预检阶段准备转向 `CjguiInternalRendererNoCAMetalLayerCreateDestroyReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，计划新增 allocation、object table、create/destroy owners；stop-line 仍禁止 attach、Metal、drawable、public、state write。
- 本轮是否改变唯一 next opening：是，若 C 成功则转向 `P1 internal Renderer CAMetalLayer NSView attach/detach preflight decision`。
- 是否同步 topic manifest：是，已在本轮 manifest stabilization 同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
