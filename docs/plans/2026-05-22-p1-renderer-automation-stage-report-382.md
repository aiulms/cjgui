# P1 Renderer Automation Stage Report 382

日期：2026-05-22

## 本轮主题阶段包

本轮从真实 tail stage381 `shared component model convergence exit` 接续。README、tracker、runtime README、DESIGN_INTENT_INDEX 与 stage381 report 均指向 `stage382_shared_layout_style_input_focus_demo_probe_after_shared_component_model`。

本轮没有回到 surface / probe / result / readiness 同构循环，而是消费 stage381 shared component model，新增一个 internal demo probe：把 shared semantic node、layout / style / text / input / focus、owner-local state delta 与 RenderCommand refresh plan 接入 AI-generated settings demo 和 Todo demo surface dry-run。

## A/B/C/D 完成情况

- A 路线收敛：完成。stage381 已经完成 convergence exit，本轮确认无需再次收敛，并以 `route_convergence_needed=false` 接续实际消费路线。
- B 真实 UI framework 能力增量：完成。新增 demo surface 消费能力，证明 shared layout / style / text / input / focus 可以驱动 owner-local preview。
- C 接入现有 demo 链路：完成。stage382 同时接入 AI-generated settings demo 与 Todo demo surface dry-run。
- D 验证与交接：完成。已跑 TDD red、owner probe、focused suite、独立 build、diff check、public / forbidden / protected scans、GitNexus impact / detect-changes、CodeLattice static review，并完成本 report 与 latest-entry 同步。

## 真实能力增量

新增 [runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj)：

- `CjguiInternalRendererStage382SharedDemoSemanticSurface`：从 stage381 shared component model 派生 AI-generated settings demo 与 Todo demo semantic surface。
- `CjguiInternalRendererStage382SharedDemoLayoutStyleTextInputFocusSurface`：把 shared layout / style / text / input / focus 消费成 demo layout slots、style tokens、text runs、input bindings 与 focus traversal。
- `CjguiInternalRendererStage382SharedDemoStateRenderRefresh`：把 demo input 映射到 owner-local state delta，并产生 RenderCommand refresh preview。
- `CjguiInternalRendererStage382SharedLayoutStyleInputFocusDemoProbeReadiness` / `cjguiInternalExecuteDefaultRendererStage382SharedLayoutStyleInputFocusDemoProbeDraft()`：成为本轮 canonical endpoint。

这不是 public component API，也没有启用真实 layout engine、真实 input event pipeline 或 renderer submission。它的价值在于：stage381 的 shared model 已被两个 demo surface 实际消费，不再只是孤立 owner。

## 辅助内容

新增 [verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh) 与 [verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh)。它们只是 focused verification envelope，不是能力本身。

## 实际修改文件

- [runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage382_shared_layout_style_input_focus_demo_probe.cj)
- [verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh)
- [verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- 本 report。

## 验证结果

- TDD red：`zsh runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh` 在 source 缺失时 exit 2。
- TDD red：`CJGUI_STAGE382_TMPDIR=/tmp/cjgui-stage382-red-1 CJGUI_STAGE381_SHARED_LAYOUT_STYLE_INPUT_FOCUS_INPUT_PACKET=/tmp/nonexistent-stage381.packet zsh runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh` 在 source 缺失时 exit 6。
- Owner probe：`zsh runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_owner.sh` 通过。
- Focused suite：`CJGUI_STAGE382_TMPDIR=/tmp/cjgui-stage382-final-1 CJGUI_STAGE381_SHARED_LAYOUT_STYLE_INPUT_FOCUS_INPUT_PACKET=/tmp/cjgui-stage381-final-1/stage381-shared-component-model-suite.packet zsh runtime/cjgui/native/scripts/verify_renderer_stage382_shared_layout_style_input_focus_demo_probe_suite.sh` 通过，生成 `/tmp/cjgui-stage382-final-1/stage382-shared-layout-style-input-focus-demo-probe-suite.packet`。
- Suite packet 固定 `route_convergence_needed=false`、`stage381_shared_component_model_consumed=true`、`ai_generated_settings_demo_consumed_shared_component_model=true`、`todo_demo_surface_consumed_shared_component_model=true`、`shared_layout_model_consumed_by_demo_surface=true`、`shared_style_model_consumed_by_demo_surface=true`、`shared_text_model_consumed_by_demo_surface=true`、`shared_input_model_consumed_by_demo_surface=true`、`shared_focus_model_consumed_by_demo_surface=true`、`owner_local_state_delta_from_demo_input_materialized=true`、`render_command_refresh_plan_from_demo_surface_materialized=true`、`stage383_shared_action_state_render_bridge_demo_probe_prepared=true`。
- 独立 build：`cjpm build --target-dir /tmp/cjgui-stage382-independent-build-1/target --skip-script` 通过，仍为既有 `231 warnings generated, 231 warnings printed`。
- `git diff --check` 通过。
- stage382 public / foreign declaration scan 通过。
- stage382 forbidden native / render token scan 通过。
- protected path scan 通过，未修改 `runtime/cjgui/cjpm.toml`、`runtime_state.cj`、native bridge header / implementation。
- `runtime/cjgui/src/runtime_state.cj` 保持 10065 行，本轮未修改。

## GitNexus / CodeLattice 结果

- GitNexus repo list 确认存在 `cangjie-live-codelattice`，路径为 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`。
- GitNexus Tool CLI impact 对 `CjguiInternalRendererStage381SharedComponentModel`、`cjguiInternalExecuteDefaultRendererStage381SharedComponentModelDraft`、`CjguiInternalRendererStage382SharedLayoutStyleInputFocusDemoProbeReadiness`、`cjguiInternalExecuteDefaultRendererStage382SharedLayoutStyleInputFocusDemoProbeDraft` 返回 not found / `risk=UNKNOWN`；不能作为安全证明。
- GitNexus MCP / Tool CLI `detect-changes --scope all` 仍只识别 tracked latest-entry Markdown section symbols，未覆盖 untracked stage382 owner/scripts/report；安全结论依赖源码读取、focused suite、build 与 scans。
- CodeLattice `codelattice_symbol` / `native_review` 为 static-only，明确 `scriptsExecuted=false`、`coverageVerified=false`、`runtimeVerified=false`，未作为 production readiness 证明。

## 当前 endpoint

Canonical runtime endpoint：

- `CjguiInternalRendererStage382SharedLayoutStyleInputFocusDemoProbeReadiness`
- `cjguiInternalExecuteDefaultRendererStage382SharedLayoutStyleInputFocusDemoProbeDraft()`

Current next route：

- `stage383_shared_action_state_render_bridge_demo_probe_after_stage382`

## Runtime / Harness 状态

本轮未执行 bounded runtime native first-frame probe。原因：本轮只新增 internal Cangjie owner 与 focused suite，不改 native bridge、runtime harness、renderer backend 或 protected state path；stage382 能力不依赖 live Metal。

未遇到新的 CJGUI harness 缺口，也没有新的宿主限制分类。`production_render_truth=false`、`backend_ready_truth=false`、`renderer_state_write=false`、`runtime_state_write=false`、`native_bridge_expansion=false` 继续保持。

## 剩余缺口

第一帧链路：

- stage380 仍是最近的 isolated bounded first-frame 正向证据；本轮没有把它升级为 production render truth。
- first-frame evidence 仍未接入 baseline / semantic comparison、production truth recheck 与 write admission 同一 verified chain。

renderer-state write / runtime_state write：

- 本轮没有 renderer-state write，也没有 runtime_state write。
- 仍缺同一 verified contract 下的 production render truth、backend-ready truth、semantic runtime admission、write token、mutation request、guarded executor positive result、visibility publication admission 与 rollback-ready result。

最小 UI framework：

- 本轮让 shared component model 被 AI-generated settings / Todo demo surface 消费，但还没有真实 layout engine、真实 text editing、真实 input event pipeline、focus traversal runtime、state commit、renderer submission 或 public component API。
- 下一步最值得推进的是 `stage383_shared_action_state_render_bridge_demo_probe_after_stage382`：把 demo surface input/action intent 接到可复用 owner-local state update dry-run 与 RenderCommand refresh bridge，继续避免回到同构 surface/probe/readiness 循环。
