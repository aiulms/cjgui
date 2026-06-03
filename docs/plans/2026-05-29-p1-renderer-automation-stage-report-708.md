# P1 Renderer Automation Stage Report 708

日期：2026-05-29

## 小设计

当前真实 tail 是 stage704 的 text input component runtime cycle executor，属于 component runtime / demo-host input 链路。工作区已有 stage689-704 未提交 artifacts；本轮先复核 stage704 focused suite 通过，再消费 stage704，不把 prompt stage 号当真相。最近多轮仍在 replay / inspection / result / runtime contract 节奏上推进，因此本轮继续触发周期收敛，但落点从“再包 runtime”转为把 component slot/cycle 输出推进到 normalized input event、action intent、state/render/feedback dry-run 和 shared input event cycle executor。

本轮完成四个连续 slice。Slice 1 用 stage705 消费 stage704，生成 shared component runtime input event normalizer、text edit / submit / validation dismiss / focus move normalized input events 与四个 demo normalized input surfaces。Slice 2 用 stage706 消费 stage705，生成 non-dispatching component action intent adapter 与四类 action intents。Slice 3 用 stage707 消费 stage706，生成 owner-local state delta dry-run、RenderCommand refresh preview、input feedback refresh、focus transition refresh、semantic diff explain 与四个 demo state/render/feedback surfaces。Slice 4 用 stage708 消费 stage707，抽出 shared component runtime input event cycle executor/runtime contract/execution receipt contract，并把 Todo、settings、AI-generated settings、chat composer 接到同一条 input event cycle surface。关键 stop-line 是不执行真实 input pipeline、不 dispatch action、不 commit state、不发布 visibility、不提交 renderer、不写 renderer_state/runtime_state、不扩 public/native bridge。

## Four Slices

1. Stage705 `component_runtime_input_event_normalization`
   - 消费 `CjguiInternalRendererStage704TextInputComponentRuntimeCycleExecutorReadiness`。
   - 生成 shared component runtime input event normalizer。
   - 生成 text edit、submit、validation dismiss、focus move normalized component input events。
   - 接入 Todo、settings、AI-generated settings、chat composer normalized input surfaces。

2. Stage706 `component_runtime_action_intent_adapter`
   - 消费 stage705 normalized input events。
   - 生成 shared non-dispatching component runtime action intent adapter。
   - 生成 text edit、submit、validation dismiss、focus move action intents。
   - 把四个 demo action intent surfaces 绑定回 normalized input event shape。

3. Stage707 `component_runtime_state_render_feedback_dry_run`
   - 消费 stage706 action intents。
   - 生成 shared state/render/feedback dry-run surface。
   - 生成 state delta dry-run、RenderCommand refresh preview、input feedback refresh、focus transition refresh、semantic diff explain。
   - 接入 Todo、settings、AI-generated settings、chat composer 四个 state/render/feedback surfaces。

4. Stage708 `component_runtime_input_event_cycle_executor`
   - 消费 stage707 state/render/feedback dry-run。
   - 生成 shared component runtime input event cycle executor、runtime contract、execution receipt contract。
   - 固定 `component_runtime_normalized_input_action_state_render_feedback_result` cycle order。
   - 接入四个 demo input event cycle surfaces，并准备 `stage709_component_runtime_input_event_replay_surface_after_stage708`。

## 真实能力增量

本轮把 stage704 component runtime slot/binding/cycle contract 推进到可复用的 internal input event cycle：normalized input event -> action intent -> state/render/feedback dry-run -> shared executor。相比继续生成同构 surface / readiness，本轮新增的能力是 component runtime input event normalization 与后续 action/state/render/feedback cycle 的共同执行形态；后续 demo-host replay 或 host inspection 可以直接消费 stage708，而不必为 Todo、settings、AI-generated settings、chat composer 分别重建 input event owner。

本轮完成 shared helper / common executor / common contract / demo surface 接入：

- `shared_component_runtime_input_event_normalizer_materialized=true`
- `text_edit_normalized_component_input_event_materialized=true`
- `submit_normalized_component_input_event_materialized=true`
- `validation_dismiss_normalized_component_input_event_materialized=true`
- `focus_move_normalized_component_input_event_materialized=true`
- `shared_component_runtime_action_intent_adapter_materialized=true`
- `component_action_intent_non_dispatching=true`
- `shared_component_runtime_state_render_feedback_dry_run_materialized=true`
- `component_runtime_state_delta_dry_run_materialized=true`
- `component_runtime_render_command_refresh_preview_materialized=true`
- `component_runtime_input_feedback_refresh_materialized=true`
- `component_runtime_focus_transition_refresh_materialized=true`
- `shared_component_runtime_input_event_cycle_executor_materialized=true`
- `shared_component_runtime_input_event_cycle_runtime_contract_materialized=true`
- `component_runtime_input_event_execution_receipt_contract_materialized=true`
- `future_per_demo_component_runtime_input_event_template_need_reduced=true`

## 周期收敛

已触发周期收敛。近期 tail 反复出现 result surface / host inspection / runtime contract 与 action-state-render runtime contract 模式；本轮没有继续复制 vNext runtime wrapper，而是把 stage704 的 component runtime contract 消费为 shared input event normalizer、action intent adapter、state/render/feedback dry-run 和 input event cycle executor。后续可以从 stage708 进入 replay surface / host inspection preview，而不用重复每个 demo 的 normalized event、action intent、state render feedback owner。

辅助 envelope / readiness 只记录 internal dry-run、input event cycle contract 和 stop-line，不解释为 production truth、backend-ready truth、owner acceptance、renderer submission、renderer_state write 或 runtime_state write。

## 修改文件

新增 source：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage705_component_runtime_input_event_normalization.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage706_component_runtime_action_intent_adapter.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage707_component_runtime_state_render_feedback_dry_run.cj`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage708_component_runtime_input_event_cycle_executor.cj`

新增 focused scripts：

- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage705_component_runtime_input_event_normalization_owner.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage705_component_runtime_input_event_normalization_suite.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage706_component_runtime_action_intent_adapter_owner.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage706_component_runtime_action_intent_adapter_suite.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage707_component_runtime_state_render_feedback_dry_run_owner.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage707_component_runtime_state_render_feedback_dry_run_suite.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage708_component_runtime_input_event_cycle_executor_owner.sh`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage708_component_runtime_input_event_cycle_executor_suite.sh`

文档同步：

- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-29-p1-renderer-automation-stage-report-708.md`
- `/Users/jiangxuanyang/Desktop/cangjie/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md`
- `/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md`

## 验证结果

- 预复核：`verify_renderer_stage704_text_input_component_runtime_cycle_executor_suite.sh` 通过，确认当前 stage704 tail 可消费。
- TDD RED：stage705、stage706、stage707、stage708 owner probes 在 source 添加前均以 missing source 失败。
- Owner probes：stage705、stage706、stage707、stage708 owner scripts 均通过。
- `cjfmt`：对四个新增 `.cj` 文件逐个运行 `cjfmt -f` 成功；首次 envsetup 因 sandbox `ps` 限制失败，随后使用本仓库既有 `ps` shim fallback 成功。
- Focused suite：`verify_renderer_stage708_component_runtime_input_event_cycle_executor_suite.sh` 通过，packet 位于 `/private/tmp/cjgui-stage705-stage708/stage708/stage708-component-runtime-input-event-cycle-executor-suite.packet`。
- Stage708 suite 内部确认 runtime package build 通过、public / foreign scan 通过、forbidden native/render token scan 通过、protected path scan 通过。
- 独立 `cjpm build --skip-script` 通过，target 使用 `/private/tmp/cjgui-stage705-stage708/independent-build/target`，log 位于 `/private/tmp/cjgui-stage705-stage708/independent-build/cjpm-build.log`。构建仍有既有 stack-frame warning 流；本轮新增 stage707/stage708 stack-frame warning，但 build 成功。
- `zsh -n` 对 stage705-708 八个新增 scripts 通过。
- `git diff --check` 通过。
- 新增 stage705-708 source / scripts trailing whitespace scan 通过。
- 独立 protected path check 对 `runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m` 无输出。
- 独立 public / foreign scan 对 stage705-708 source 无输出。
- 独立 forbidden native/render token scan 对 stage705-708 source 无输出。

## GitNexus / CodeLattice

遵守 `cangjie-live-codelattice` 口径。预编辑对 stage704 endpoint 运行 GitNexus Tool CLI context 与 impact，均返回 symbol not found / UNKNOWN；未当作安全证明，改用源码读取、stage704 suite、focused probes、build 和 scans 兜底。预编辑 detect-changes 只看到已有 tracked README-style docs 变动，未覆盖未跟踪 source。

后编辑对 `CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorReadiness` 运行 GitNexus Tool CLI context 与 impact，仍返回 symbol not found / UNKNOWN；detect-changes 仍只识别 tracked README-style docs，未覆盖新增 untracked stage705-708 source/scripts。因此本轮安全结论来自 focused scripts、source scans、protected path scans 和 `cjpm build --skip-script`，不是图谱覆盖。

CodeLattice before-edit 能静态定位 stage704 source，但 impact 对 stage704 readiness 因 struct/init candidates ambiguous 返回 UNKNOWN。CodeLattice production_assist 对显式 changedSymbols 给出 LOW 风险、0 caller；native_review 的 changed_symbols 子动作因 project root 不是 git repo 返回 `not_a_git_repo`，并提示使用 workspace CLI。CodeLattice 结果只作为静态参考，不作为 runtime / coverage / production readiness。

`cangjie-production-alias-check.sh --status` 显示 `cangjie-live-codelattice` registry entry 存在，工作区 dirty=69，stable window 为 RED；未切换默认 registry，未运行 production smoke。

## Stop-Line

本轮未做：

- production render truth / backend-ready truth 升级
- owner acceptance grant
- 真实 input event pipeline execution
- action dispatch
- state update commit
- visibility publication admission / published
- renderer submission
- renderer_state write
- runtime_state write
- native bridge expansion
- public component API / public C ABI 扩张
- text shaping / selection editing runtime
- focus manager / layout engine / style resolver 启用

未修改 `runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/cjpm.toml`、native bridge header / implementation。

## 当前 Endpoint / Next Route

Canonical endpoint：

- `CjguiInternalRendererStage708ComponentRuntimeInputEventCycleExecutorReadiness`
- `cjguiInternalExecuteDefaultRendererStage708ComponentRuntimeInputEventCycleExecutorDraft()`

Current next opening：

- `stage709_component_runtime_input_event_replay_surface_after_stage708`

## Runtime Native Probe

本轮没有执行 bounded live Metal / AppKit runtime native probe。当前 slice 是 internal owner dry-run、component runtime input event normalization/action/state/render/feedback/cycle executor contract，不需要 live renderer 或 native bridge。未遇到新的 CJGUI harness 缺口或宿主限制。

## 仍然缺什么

第一帧链路仍未推进到真实 renderer submission。renderer-state write 和 runtime_state write 仍保持关闭。Minimal UI framework 距离真实 demo 还缺：真实 host input pipeline、demo-host event queue execution、Action Gateway dispatch、owner-local state commit、text editing/selection runtime、focus manager、layout engine、style resolver、RenderCommand 到 host/runtime 的真实 refresh，以及把 stage708 input event cycle executor 接到 replay / host inspection / demo-host runtime path。

下一条最值得推进的工程目标：`stage709_component_runtime_input_event_replay_surface_after_stage708`，把 stage708 normalized input/action/state/render/feedback cycle 变成可检查 replay surface 和 host inspection preview，继续保持无 production write、无 renderer submission、无 runtime_state write。

## 完整性说明

本轮完成 4 个 slice，且 Slice 2 消费 Slice 1、Slice 3 消费 Slice 2、Slice 4 消费 Slice 3；未触发只做 1-3 个 slice 的例外条件。
