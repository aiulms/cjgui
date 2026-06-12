# P1 Renderer Automation Stage Report 844

日期：2026-06-10

## Tail 校准

本轮启动时读取了 `AGENTS.md`、`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`docs/plans/DESIGN_INTENT_INDEX.md`、`docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md` 与最新 stage840 report。真实 tail 是 `CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness`，next opening 是 `stage841_publishable_state_text_model_after_stage840`。仓库已有 stage829-840 owner / script / report untracked artifacts，属于已报告但未 stage 的正常状态；没有发现 stage841+ owner/script/report 高于 report 的未收口产物。

本轮小设计：当前 tail 属于 publishable state focus runtime manager -> text model 能力链路，应该从 focus 运行时转向文本值、选择、光标和 composition placeholder，而不是继续做 focus/surface/rehearsal vNext。最近几轮存在 manager/surface 收敛节奏，本轮仍保留 shared manager，但把能力族推进到 text model 与 text edit preview。四个 slice 依次是 stage841 text model、stage842 text edit preview、stage843 demo text surface、stage844 shared text runtime manager。stage842 消费 stage841 的 text model，stage843 消费 stage842 的 preview receipt，stage844 消费 stage843 的五类 demo surface 并抽出 common runtime contract。本轮触发能力收敛，目标是减少后续每个 demo 重复写 text inspection/runtime owner 的必要性。关键 stop-line 是不做真实 text shaping、IME、input dispatch、state commit、host mutation、renderer/runtime state write、native bridge/C ABI 或稳定 public API 扩张。

## Four-slice macro package

1. Slice 1, stage841: 新增 `runtime_renderer_stage841_publishable_state_text_model.cj`，消费 stage840 focus runtime manager 与 stage834 text/focus measurement evidence，生成 owner-local text value model、text run ledger、selection range model、caret position model、composition placeholder model，并准备 `stage842_publishable_state_text_edit_preview_after_stage841`。
2. Slice 2, stage842: 新增 `runtime_renderer_stage842_publishable_state_text_edit_preview.cj`，消费 stage841 readiness，生成 non-dispatching text edit preview、selection/caret delta preview、composition placeholder edit preview、text rollback snapshot 与 text change explain receipt，并准备 `stage843_publishable_state_text_demo_surface_after_stage842`。
3. Slice 3, stage843: 新增 `runtime_renderer_stage843_publishable_state_text_demo_surface.cj`，消费 stage842 readiness，把 text preview 投到 Todo、settings、AI-generated settings、chat composer、file browser 五类 demo text inspection/result surfaces，并准备 `stage844_publishable_state_text_runtime_manager_after_stage843`。
4. Slice 4, stage844: 新增 `runtime_renderer_stage844_publishable_state_text_runtime_manager.cj`，消费 stage843 surface，抽出 shared publishable text runtime manager、runtime contract、execution receipt contract、`publishable_state_text_demo_runtime` cycle order 与五类 demo runtime surfaces，并准备 `stage845_publishable_state_text_input_adapter_after_stage844`。

## 能力增量

真实能力增量是把 publishable state / focus runtime 链路推进到 owner-local text model 与可检查 text edit preview：现在 dry-run 链可以表达文本值、文本 run、selection range、caret position、composition placeholder、rollback snapshot、change explain receipt，并把这些结果投到五类 demo surface。stage844 把五类 demo 的 text runtime 表达压缩为 shared text runtime manager / contract / receipt，减少后续继续复制 Todo/settings/chat/file-browser/AI-generated UI text runtime owner 的必要性。

辅助 envelope / readiness 仍只用于 focused evidence。它们不是 production text shaping、不是 IME、不是输入管线执行、不是 state-store commit、不是 renderer submission，也不是 runtime/native bridge 扩张。

## Public API

本轮没有推进新的 public API first slice，没有新增稳定 public API，没有新增 public C ABI。stage844 packet 仍处在既有 public component API runway 之后，但 public declaration scan 只列出既有 surface：

- `runtime_renderer_stage758_minimal_public_preview_api_declaration.cj`: `public func cjguiExperimentalComponentPreviewApiReady(): Bool`
- `runtime_queue_public_submit.cj`: `public func cjguiExperimentalQueueSubmitShellReady(): Bool`

本轮新增 stage841-844 owner 均为 internal-only；`new_public_surface_added=false`、`stable_public_api_added=false`、`public_c_abi_added=false`。

## 修改文件

- 新增 `runtime/cjgui/src/runtime_renderer_stage841_publishable_state_text_model.cj`
- 新增 `runtime/cjgui/src/runtime_renderer_stage842_publishable_state_text_edit_preview.cj`
- 新增 `runtime/cjgui/src/runtime_renderer_stage843_publishable_state_text_demo_surface.cj`
- 新增 `runtime/cjgui/src/runtime_renderer_stage844_publishable_state_text_runtime_manager.cj`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage841_publishable_state_text_model_owner.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage841_publishable_state_text_model_suite.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage842_publishable_state_text_edit_preview_owner.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage842_publishable_state_text_edit_preview_suite.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage843_publishable_state_text_demo_surface_owner.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage843_publishable_state_text_demo_surface_suite.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage844_publishable_state_text_runtime_manager_owner.sh`
- 新增 `runtime/cjgui/native/scripts/verify_renderer_stage844_publishable_state_text_runtime_manager_suite.sh`
- 最小同步 `README.md`
- 最小同步 `GUI_TASK_TRACKER.md`
- 最小同步 `docs/plans/README.md`
- 最小同步 `runtime/cjgui/README.md`
- 最小同步 `docs/plans/DESIGN_INTENT_INDEX.md`
- 新增本 report

## 验证

- TDD red probe: 四个 owner probe 在新增 source 前均以 missing source 失败，确认 probe 能卡住缺失 owner。
- Source probe: stage841、stage842、stage843、stage844 owner probes 在新增 source 后通过。
- Focused suites: 显式 upstream packet 链 stage841 -> stage842 -> stage843 -> stage844 通过；post-format packet 位于 `/private/tmp/cjgui-stage841-stage844-postfmt/stage844/stage844-publishable-state-text-runtime-manager-suite.packet`。
- Recursive suite: stage844 suite 曾在旧 stage820 递归 build 阶段暴露新 owner constructor arity bug；已修复 stage842/stage843 constructor 参数缺口，后续显式 full chain 通过。
- Format: 对四个新增 `.cj` owner 执行 `cjfmt`。
- Build: 在 `runtime/cjgui` 执行 `cjpm build --target-dir /private/tmp/cjgui-stage841-stage844-direct-build/target --skip-script` 通过；输出仍包含既有 unused function / stack-frame warnings。
- Shell syntax: 八个新增 focused scripts 的 `zsh -n` 通过。
- Public declaration scan: 未发现 stage841-844 新 public declaration；仅列出既有两个 public funcs。
- Forbidden/native/render scan: stage841-844 新 owner 未包含 native bridge expansion、renderer state write、runtime_state write、C ABI 或 renderer submission token。
- Protected path scan: 未修改 `runtime/cjgui/cjpm.toml`、`runtime/cjgui/src/runtime_state.cj`、`runtime/cjgui/native/cjgui_native_bridge.h`、`runtime/cjgui/native/cjgui_native_bridge.m`。
- `git diff --check`: 通过。

最终 stage844 packet 确认 `stage843_publishable_state_text_demo_surface_consumed=true`、`stage842_publishable_state_text_edit_preview_consumed_transitively=true`、`stage841_publishable_state_text_model_consumed_transitively=true`、`stage840_publishable_state_focus_runtime_manager_consumed_transitively=true`、`shared_publishable_text_runtime_manager_materialized=true`、`publishable_text_runtime_contract_materialized=true`、`publishable_text_execution_receipt_contract_materialized=true`、`cycle_order_publishable_state_text_demo_runtime_materialized=true`、`todo_text_runtime_surface_materialized=true`、`settings_text_runtime_surface_materialized=true`、`ai_generated_settings_text_runtime_surface_materialized=true`、`chat_composer_text_runtime_surface_materialized=true`、`file_browser_text_runtime_surface_materialized=true`、`text_runtime_manager_bound_to_stage841_text_model=true`、`text_runtime_manager_bound_to_stage842_edit_preview=true`、`text_runtime_manager_bound_to_stage843_demo_surface=true`、`future_per_demo_text_template_need_reduced=true`、`stage845_publishable_state_text_input_adapter_after_stage844_prepared=true`。

## GitNexus / CodeLattice

- CLI `context` for `CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness`: symbol not found。
- CLI `impact CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness --repo cangjie-live-codelattice`: target not found，risk `UNKNOWN`。
- CLI `context` / `impact` for `CjguiInternalRendererStage844PublishableStateTextRuntimeManagerReadiness`: symbol not found / risk `UNKNOWN`。
- CLI `detect-changes --repo cangjie-live-codelattice --scope all`: 只覆盖 tracked docs，未覆盖新增 untracked stage841-844 owner/script，不能作为安全证明。
- CodeLattice `impact` / `symbol_context` for stage844: stale baseline / file_added / symbol not found，risk `UNKNOWN`。
- CodeLattice docs/tests assist with stage844 changed symbol: unknown changed symbol count 1。
- Production alias status after work: dirty tree RED，原因是既有 docs modifications 与 stage829-844 untracked artifacts；未 stage/commit/push。

由于图谱未覆盖新增 target，本轮安全判断采用 source reading、focused suites、build、public/protected/forbidden scans 与 `git diff --check` 兜底。

## Stop-line / runtime native

本轮没有执行 bounded runtime native probe；能力范围是 internal owner-local text model / dry-run surface / shared runtime contract，不依赖 live Metal/AppKit，也未遇到 CJGUI harness 缺口或宿主限制。没有修改 native bridge、`runtime_state.cj` 或 `cjpm.toml`。

第一帧链路未改变；renderer-state write 与 runtime_state write 仍为 false。minimal UI framework 距离真实 demo 仍缺真实 input adapter、文本 shaping/layout 执行、IME/composition 事件、state commit、host mutation、RenderCommand 到可见 surface 的运行时刷新，以及可验证 accept/reject/edit loop。

## Endpoint / next route

当前 canonical endpoint:

- `CjguiInternalRendererStage844PublishableStateTextRuntimeManagerReadiness`
- `cjguiInternalExecuteDefaultRendererStage844PublishableStateTextRuntimeManagerDraft()`

当前 next route:

- `stage845_publishable_state_text_input_adapter_after_stage844`

下一条最值得推进的工程目标是把 normalized input / key edit intent 接到 stage841 text model 与 stage842 edit preview，形成 non-dispatching text input adapter，并继续保持 no state commit / no host mutation / no renderer-state write，直到 focused proof 能解释 selection/caret/composition preview 的输入来源。

