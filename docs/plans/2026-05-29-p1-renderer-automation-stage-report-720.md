# P1 Renderer Automation Stage Report 720

日期：2026-05-29

## 小设计

当前真实 tail 是 `CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness`，属于 component runtime replay action/state/render 链路。最近几轮已经反复出现 replay / result / runtime-contract 同构节奏，所以本轮触发周期收敛，选择把 stage716 的 replay action-state-render 输出推进到 visual runtime manager，而不是继续复制 replay inspection/result owner。四个连续 slice 是 stage717 replay visual preview、stage718 replay style/focus resolver、stage719 replay text/caret host surface、stage720 replay visual runtime manager。

Slice 2 消费 Slice 1 的 layout/style/text/focus preview，生成最小 style resolver dry-run 与 focus manager dry-run ledger；Slice 3 消费 Slice 2 的 resolved style/focus receipts，生成 text selection / caret / composition placeholder 与 demo-host inspection surface；Slice 4 消费 Slice 3，抽出 shared visual runtime manager/runtime contract/execution receipt contract，并接入 Todo、settings、AI-generated settings、chat composer 四个 demo runtime surfaces。关键 stop-line：不执行真实 input pipeline、不 dispatch action、不提交 state、不发布 visibility、不提交 renderer、不写 renderer_state/runtime_state、不扩 public component API / native bridge。

## Four-Slice Package

1. Slice 1 / stage717：消费 stage716 action-state-render executor，新增 shared replay layout/style/text/focus preview，生成 layout constraint / style token / text run / focus target ledgers，并接入四个 demo visual preview surfaces。
2. Slice 2 / stage718：消费 stage717 preview ledgers，新增 shared replay style resolver dry-run 与 focus manager dry-run，生成 resolved visual style / focus movement / validation focus handoff ledgers，并接入四个 demo style-focus resolutions。
3. Slice 3 / stage719：消费 stage718 resolver receipts，新增 shared replay text/caret model，生成 selection / caret / composition placeholder ledgers和 demo-host inspection surface，并接入四个 demo text/caret host surfaces。
4. Slice 4 / stage720：消费 stage719 host surface，抽出 shared replay visual runtime manager/runtime contract/execution receipt contract，固定 `replay_action_state_render_visual_resolve_text_caret_host` cycle order，并接入四个 demo visual runtime surfaces。

## 真实能力增量

本轮把 stage716 的 replay action/state/render executor 推进到视觉运行时链路：layout/style/text/focus preview -> style resolver / focus manager dry-run -> text/caret host surface -> shared visual runtime manager。它不是 public API，也不是 production layout/style/focus/text engine；真实增量在于后续可以消费一个可复用 visual runtime manager，而不必继续为每个 demo 复制 preview / resolver / text-caret / host-surface readiness 模板。

## 周期收敛

已触发周期收敛。收敛结果是 stage720 同时绑定 stage717 preview、stage718 resolver、stage719 host surface 和 stage716 executor，并把 Todo/settings/AI-generated settings/chat composer 接入同一 runtime manager。`future_per_demo_replay_visual_runtime_template_need_reduced=true` 是本轮核心收敛证据。

## 辅助 Envelope / Readiness

stage717-720 仍是 internal owner / readiness / focused suite 形态。它们只证明 replay visual runtime 的结构化 dry-run 能力，不证明 backend-ready truth、production render truth、owner acceptance、input dispatch、state commit、visibility publication、renderer submission、layout engine、text shaping、stable public API 或 native bridge readiness。

## 修改文件

- [runtime_renderer_stage717_replay_visual_preview.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage717_replay_visual_preview.cj)
- [runtime_renderer_stage718_replay_style_focus_resolver.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage718_replay_style_focus_resolver.cj)
- [runtime_renderer_stage719_replay_text_caret_host_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage719_replay_text_caret_host_surface.cj)
- [runtime_renderer_stage720_replay_visual_runtime_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage720_replay_visual_runtime_manager.cj)
- [verify_renderer_stage717_replay_visual_preview_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage717_replay_visual_preview_owner.sh)
- [verify_renderer_stage717_replay_visual_preview_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage717_replay_visual_preview_suite.sh)
- [verify_renderer_stage718_replay_style_focus_resolver_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage718_replay_style_focus_resolver_owner.sh)
- [verify_renderer_stage718_replay_style_focus_resolver_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage718_replay_style_focus_resolver_suite.sh)
- [verify_renderer_stage719_replay_text_caret_host_surface_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage719_replay_text_caret_host_surface_owner.sh)
- [verify_renderer_stage719_replay_text_caret_host_surface_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage719_replay_text_caret_host_surface_suite.sh)
- [verify_renderer_stage720_replay_visual_runtime_manager_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage720_replay_visual_runtime_manager_owner.sh)
- [verify_renderer_stage720_replay_visual_runtime_manager_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage720_replay_visual_runtime_manager_suite.sh)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

## 验证结果

- RED probes：stage717 / stage718 / stage719 / stage720 owner probes 在 source 不存在时均按预期失败，分类为 missing source。
- Focused owner probes：stage717 / stage718 / stage719 / stage720 均通过。
- `cjfmt -f`：stage717-720 四个 `.cj` owner 文件格式化完成；初次 `envsetup.sh` 因 sandbox 禁止 `ps` 失败，按既有 suite 模式加本地 `ps` shim 后通过。
- `zsh -n`：stage717-720 八个 focused scripts 语法检查通过。
- Focused suite：`verify_renderer_stage720_replay_visual_runtime_manager_suite.sh` 通过，生成 packet `/private/tmp/cjgui-stage717-stage720/stage720/stage720-replay-visual-runtime-manager-suite.packet`。
- Independent build：`cjpm build --skip-script` 在 `runtime/cjgui` 下通过，使用 target `/private/tmp/cjgui-stage717-stage720/independent-build/target`。build log 为既有 unused / stack-frame warning 流，并新增 stage717-720 unused / stack-frame warnings，退出成功。
- Protected paths：`runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、native bridge `.h/.m` 无修改。
- Public / foreign / forbidden scan：stage717-720 source 未新增 `public` / `foreign`，未出现 native bridge、renderer submission、renderer_state/runtime_state write 等 forbidden token。
- Whitespace / `git diff --check`：通过；未发现 trailing whitespace / conflict marker。

## GitNexus / CodeLattice

- GitNexus Tool CLI `context` / `impact` for `CjguiInternalRendererStage716ComponentRuntimeInputEventReplayActionStateRenderExecutorReadiness`：symbol not found / target not found，`impactedCount=0`，`risk=UNKNOWN`；未把 UNKNOWN 当安全证明。
- GitNexus Tool CLI `context` / `impact` for `CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness`：symbol not found / target not found，`risk=UNKNOWN`。
- GitNexus MCP / Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all`：indexed graph 仍只看到 5 files / 2 markdown symbols，affected processes 0，risk low；未覆盖本轮 untracked source/scripts。
- CodeLattice `codelattice_project` quick on `runtime/cjgui`：single manifest-backed project，static-only，runtimeProof=false，coverageProof=false。
- CodeLattice `codelattice_change_review` impact for stage720 readiness：识别 Struct/init 候选但目标有歧义，risk UNKNOWN，static-only。
- CodeLattice `native_review`：static production_assist risk LOW；changed_symbols 子步骤因 project root 不是 git repo 失败，workspace git root又被 live repo deny list 拒绝，因此仍以 source/probe/build/scan fallback 为准。
- `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status`：registry 是 `cangjie-live-codelattice`，worktree dirty，stable window RED；status only，无 smoke。

## Stop-Line

本轮没有执行 bounded runtime native probe；能力不依赖 live Metal / AppKit。未遇到新的 CJGUI harness 缺口或宿主限制。

保持不变：

- `host_mutation=false`
- `production_render_truth=false`
- `backend_ready_truth=false`
- `owner_acceptance_granted=false`
- `input_event_pipeline_execution=false`
- `action_dispatch=false`
- `state_update_committed=false`
- `visibility_publication_admitted=false`
- `visibility_published=false`
- `renderer_submission=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `native_bridge_expansion=false`

## 当前 Endpoint / Next Route

当前 canonical endpoint：

- `CjguiInternalRendererStage720ReplayVisualRuntimeManagerReadiness`
- `cjguiInternalExecuteDefaultRendererStage720ReplayVisualRuntimeManagerDraft()`

当前 next route：

- `stage721_component_runtime_visual_state_store_preflight_after_stage720`

下一条最值得推进的工程目标：消费 stage720 visual runtime manager，推进 component state store dry-run / rollback snapshot / commit preflight，让 replay visual runtime 的 owner-local state 边界更可复用，继续保持真实 state commit 与 visibility publication blocked。

## 距离真实 Demo

第一帧链路、renderer-state write、runtime_state write 仍未推进。本轮让 minimal UI framework 的 replay visual path 更接近可复用 runtime manager，但距离真实 demo 还缺真实 input event pipeline、owner acceptance flow、component state store commit/preflight、可见 demo-host inspection UI、RenderCommand 到 backend adapter 的执行桥、真实 layout/style/text/focus engine 与 public component API preflight。

## Public API 边界

本轮未接近稳定 public component API，只推进 internal shape。若后续进入 public API，仍需完成 internal visual runtime manager 的多轮 demo proof、state store preflight、compatibility note、host inspection UI proof 与 public surface preflight。

## 完整性说明

本轮完成 4 个 slice，且 Slice 4 消费 Slice 3 并接入 Todo/settings/AI-generated settings/chat composer 四个 demo surface，同时抽出 shared visual runtime manager。未 stage / commit / push。
