# Render command encoder no-submit 规划预检

日期：2026-05-11

状态：preflight decision / route A selected

## 上游证据

- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness` 已证明 command buffer create / classify / destroy / double-destroy 的 runtime internal call facts 可以在函数局部脱水。
- Command buffer tail 仍明确 `commit` blocked 与 encoder creation still blocked。
- `MTLRenderPassDescriptor` create / destroy 已有 token-backed lifecycle facts，但 color attachment 未配置。
- Render pass descriptor color attachment recovery 与 drawable texture lifetime recovery 已确认 production drawable texture lifetime 暂停。
- Drawable no-present 与 visible-window evidence 仍是隔离 probe / recovery facts，不是 production runtime drawable lifetime truth。

GitNexus impact：

- `CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`：`UNKNOWN` / not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererCommandBufferRuntimeCallDraft`：`UNKNOWN` / not found / impactedCount `0`。

以上符号为近期新增 owner，索引尚未覆盖；本轮以源码阅读、build、probe 与 scan 兜底。

## 路线判断

本轮选择 A：`P1 internal Renderer render command encoder no-submit planning / blocker facts`。

选择理由：

- 当前缺 production drawable texture lifetime。
- 当前缺 `colorAttachments[0]` 配置。
- 创建真实 `MTLRenderCommandEncoder` 需要有效 render pass descriptor；没有 color attachment 时不应尝试 encoder creation。
- 现有 command buffer / descriptor native callable 已能表达 encoder creation still blocked，暂不需要新增 production native C ABI。
- Render command encoder no-submit planning 可以先固定前置条件、blocker 和 stop-line，避免后续把 command buffer / descriptor lifecycle 误读成 encoder permission。

本轮不选择 B：

- Still-blocked callable 会重复现有 command buffer / descriptor blocker facts。
- 新增 native C ABI 会扩大 callable surface，但不会提供新的安全证据。

本轮不选择 C：

- 缺 color attachment 与 production drawable texture lifetime，encoder feasibility probe 必须停止。
- 不应为了 probe 构造无效 descriptor 或依赖未证明的 drawable texture。

## 本阶段允许的输出

- 新增 internal runtime owner：`runtime_renderer_render_command_encoder_no_submit_planning.cj`。
- Endpoint：`CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`。
- Default draft：`cjguiInternalExecuteDefaultRendererRenderCommandEncoderNoSubmitPlanningDraft()`。
- Runtime input：`CjguiInternalRendererNoCommandBufferRuntimeCallReadiness`。
- Facts：descriptor attachment missing、production drawable texture lifetime missing、encoder creation blocked、draw blocked、pipeline / vertex buffer blocked、commit / present / GPU submit / render blocked。

## 停止线

不创建 render command encoder，不调用 `renderCommandEncoderWithDescriptor`，不 draw，不调用 `drawPrimitives` / `drawIndexedPrimitives`，不创建 pipeline state，不创建 vertex buffer，不调用 `commit`，不 present，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 no-submit planning facts 包装成 render permission、GPU submission permission、backend-ready truth 或 state write permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，Renderer 主线从 drawable texture lifetime recovery 进入 render command encoder no-submit planning。
- 本轮是否改变 canonical tail / endpoint：预检建议新增 `CjguiInternalRendererNoRenderCommandEncoderNoSubmitPlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，建议新增 no-submit planning owner；truth 限 encoder 前置缺口与 stop-line facts。
- 本轮是否改变唯一 next opening：是，若 A 完成，转为 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
- 是否同步 topic manifest：待 closure / manifest 完成后同步。
- 已同步哪些 topic manifest：待同步。

## 推荐后续

`P1 internal Renderer render command encoder no-submit planning value boundary bundle`
