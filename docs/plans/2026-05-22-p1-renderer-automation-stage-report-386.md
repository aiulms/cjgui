# P1 Renderer Automation Stage Report 386

日期：2026-05-22

## 本轮主题阶段包

本轮从真实 tail stage384 `shared input event to action intent adapter demo probe` 接续，完成一个 two-slice macro package：

- Slice 1 / stage385：消费 stage384 input event adapter，新增 shared text input + focus editing demo probe。
- Slice 2 / stage386：消费 stage385 editing packet，新增 edited text -> demo surface / RenderCommand refresh preview。

本轮没有回到 surface / probe / result / readiness 同构循环，也没有把 isolated probe evidence 升级为 production truth。

## 小设计复核

当前真实 tail 是 stage384：AI-generated settings 与 Todo demo 的 input event 已能映射为 shared action intent，并复用 stage383 state/render preview。stage385 把 Todo text entry 与 settings focus target 推进为 shared text input editing dry-run，覆盖 character insert、backspace、caret placement、focus editing state 与 owner-local text buffer delta。stage386 读取 stage385 的 suite packet 与 readiness，产出 Todo edited text surface refresh、settings focus surface refresh、caret RenderCommand refresh preview，并绑定 stage383 render bridge、stage384 input adapter 与 stage385 editing dry-run。关键 stop-line 保持 internal-only：不启用真实 input pipeline、action dispatch、state commit、layout engine、renderer submission、renderer-state write 或 runtime_state write。

## 两个 Slice

Slice 1 新增 [runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj)：

- `CjguiInternalRendererStage385SharedTextInputEditEventStream`：从 stage384 input event adapter 派生 Todo text entry character insert / backspace / caret placement 编辑事件。
- `CjguiInternalRendererStage385SharedFocusEditingState`：保留 settings focus target，同时激活 Todo text entry focus target。
- `CjguiInternalRendererStage385TextInputFocusEditingDryRun`：生成 owner-local text buffer delta、caret/selection preview 与 focus-after-editing preview。

Slice 2 新增 [runtime_renderer_stage386_edited_text_render_refresh_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage386_edited_text_render_refresh_demo_probe.cj)：

- `CjguiInternalRendererStage386EditedTextDemoSurfaceRefresh`：消费 stage385 edited text buffer delta，生成 Todo edited text surface refresh 与 settings focus refresh preview。
- `CjguiInternalRendererStage386EditedTextRenderCommandRefreshPlan`：把 edited text refresh 绑定到 stage383 render bridge、stage384 input adapter 与 stage385 editing dry-run。
- `CjguiInternalRendererStage386EditedTextStateRenderExecutorDryRun`：形成 owner-local state/render dry-run，但保持 state update uncommitted 与 refresh preview-only。

Slice 2 的 suite 明确读取 `/tmp/cjgui-stage385-final-1/stage385-shared-text-input-focus-editing-demo-probe-suite.packet`，并要求 `stage385_shared_text_input_focus_editing_demo_probe_consumed=true`、`edited_text_refresh_bound_to_stage385_editing_dry_run=true`。

## 真实能力增量

本轮让 minimal UI framework 内部链路从“input event -> action intent”继续前进到“text input/focus editing -> edited text render refresh preview”。这比新增 owner/envelope 更进一步：Todo demo 现在有可复用的 text editing dry-run 形态，settings demo 的 focus target 也能被编辑状态保留并进入 refresh preview。

这仍不是 public component API、真实 input event pipeline、真实 text editor、state commit、layout engine 或 renderer backend submission。

## 辅助内容

新增 focused owner / suite：

- [verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh)
- [verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_suite.sh)
- [verify_renderer_stage386_edited_text_render_refresh_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_owner.sh)
- [verify_renderer_stage386_edited_text_render_refresh_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_suite.sh)

这些只是 verification envelope，不是能力本身。

## 修改文件

- [runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage385_shared_text_input_focus_editing_demo_probe.cj)
- [runtime_renderer_stage386_edited_text_render_refresh_demo_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage386_edited_text_render_refresh_demo_probe.cj)
- [verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh)
- [verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_suite.sh)
- [verify_renderer_stage386_edited_text_render_refresh_demo_probe_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_owner.sh)
- [verify_renderer_stage386_edited_text_render_refresh_demo_probe_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_suite.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- 本 report。

## 验证结果

- TDD red：`zsh runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_owner.sh` 在 owner source 缺失时 exit 2。
- TDD red：`CJGUI_STAGE385_TMPDIR=/tmp/cjgui-stage385-red-1 CJGUI_STAGE385_INPUT_PACKET=/tmp/nonexistent-stage384.packet zsh runtime/cjgui/native/scripts/verify_renderer_stage385_shared_text_input_focus_editing_demo_probe_suite.sh` 因 owner source 缺失 exit 6。
- TDD red：`zsh runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_owner.sh` 在 owner source 缺失时 exit 2。
- TDD red：`CJGUI_STAGE386_TMPDIR=/tmp/cjgui-stage386-red-1 CJGUI_STAGE386_INPUT_PACKET=/tmp/nonexistent-stage385.packet zsh runtime/cjgui/native/scripts/verify_renderer_stage386_edited_text_render_refresh_demo_probe_suite.sh` 因 owner source 缺失 exit 6。
- Owner probe：stage385 / stage386 owner probes 均通过。
- Smoke：stage385 suite 使用 `/tmp/cjgui-stage384-final-1/stage384-shared-input-event-to-action-intent-adapter-demo-probe-suite.packet` 通过。
- Smoke：stage386 suite 使用 `/tmp/cjgui-stage385-green-smoke-1/stage385-shared-text-input-focus-editing-demo-probe-suite.packet` 通过。
- Fresh chain：stage381 -> stage382 -> stage383 -> stage384 -> stage385 -> stage386 全部通过。
- Final stage385 packet：`/tmp/cjgui-stage385-final-1/stage385-shared-text-input-focus-editing-demo-probe-suite.packet`。
- Final stage386 packet：`/tmp/cjgui-stage386-final-1/stage386-edited-text-render-refresh-demo-probe-suite.packet`。
- Final facts：`shared_text_input_edit_event_stream_materialized=true`、`owner_local_text_buffer_delta_materialized=true`、`edited_text_render_command_refresh_plan_materialized=true`、`edited_text_refresh_bound_to_stage385_editing_dry_run=true`。
- 独立 build：`cjpm build --target-dir /tmp/cjgui-stage386-independent-build-1/target --skip-script` 通过；仍为既有 `231 warnings generated, 231 warnings printed`。
- `git diff --check` 通过。
- stage385 / stage386 public / foreign declaration scan 通过。
- stage385 / stage386 forbidden native / render token scan 通过。
- protected path scan 通过，未修改 `runtime/cjgui/cjpm.toml`、`runtime_state.cj`、native bridge header / implementation。
- `runtime/cjgui/src/runtime_state.cj` 保持 10065 行，本轮未修改。

## GitNexus / CodeLattice 结果

- GitNexus repo list 确认存在 `cangjie-live-codelattice`，路径为 `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui`。
- GitNexus impact 对 stage384 consumed endpoint 仍返回 not found / `risk=UNKNOWN`；不能作为安全证明。
- GitNexus impact 对 `CjguiInternalRendererStage385SharedTextInputFocusEditingDemoProbeReadiness`、`cjguiInternalExecuteDefaultRendererStage385SharedTextInputFocusEditingDemoProbeDraft`、`CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness`、`cjguiInternalExecuteDefaultRendererStage386EditedTextRenderRefreshDemoProbeDraft` 返回 not found / `risk=UNKNOWN`；不能作为安全证明。
- GitNexus MCP context 对 stage386 endpoint 返回 symbol not found。
- GitNexus MCP `detect_changes --scope all` 与 Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all` 只识别 tracked latest-entry Markdown section symbols，未覆盖 untracked stage385 / stage386 owner、scripts、report；安全结论依赖源码读取、focused suite、build 与 scans。
- CodeLattice `native_review` 为 static-only，明确 `scriptsExecuted=false`、`coverageVerified=false`、`runtimeVerified=false`，未作为 production readiness 证明。
- CodeLattice `changed_symbols` 对 workspace root 返回 `path_denied`，对 runtime root 返回 `not_a_git_repo`；本轮已用 GitNexus detect-changes、source reading、suite/build/scan 兜底。

## 当前 endpoint

Canonical runtime endpoint：

- `CjguiInternalRendererStage386EditedTextRenderRefreshDemoProbeReadiness`
- `cjguiInternalExecuteDefaultRendererStage386EditedTextRenderRefreshDemoProbeDraft()`

Current next route：

- `stage387_shared_text_edit_action_commit_dry_run_after_stage386`

## Runtime / Harness 状态

本轮未执行 bounded runtime native first-frame probe。原因：本轮只新增 internal Cangjie owner 与 focused suites，不改 native bridge、runtime harness、renderer backend、protected state path 或 live Metal 依赖。

未遇到新的 CJGUI harness 缺口，也没有新的宿主限制分类。`production_render_truth=false`、`backend_ready_truth=false`、`renderer_state_write=false`、`runtime_state_write=false`、`native_bridge_expansion=false` 继续保持。

## 剩余缺口

第一帧链路：

- stage380 仍是最近 isolated bounded first-frame 正向证据；本轮没有把它升级为 production render truth。
- first-frame evidence 仍未接入 baseline / semantic comparison、production truth recheck 与 write admission 同一 verified chain。

renderer-state write / runtime_state write：

- 本轮没有 renderer-state write，也没有 runtime_state write。
- 仍缺同一 verified contract 下的 production render truth、backend-ready truth、semantic runtime admission、write token、mutation request、guarded executor positive result、visibility publication admission 与 rollback-ready result。

最小 UI framework：

- 本轮新增 text input/focus editing dry-run 与 edited text RenderCommand refresh preview，但还没有真实 input event pipeline、真实 text editing runtime、focus traversal runtime、state commit、renderer submission、layout engine 或 public component API。
- 下一步最值得推进的是 `stage387_shared_text_edit_action_commit_dry_run_after_stage386`：把 edited text refresh 链路推进到 shared text edit action commit dry-run / rollback preview，继续保持 action dispatch、state commit 与 renderer submission blocked。
