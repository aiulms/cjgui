# P1 Renderer Automation Stage Report 840

日期：2026-06-10 06:27:06 CST

本轮 automation：`cjgui-ui-framework-autopilot`

## Tail 校准

- 本轮先读取 `AGENTS.md`、automation memory、`README.md`、`GUI_TASK_TRACKER.md`、`docs/plans/README.md`、`runtime/cjgui/README.md`、`docs/plans/DESIGN_INTENT_INDEX.md`、`docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md` 与最新 report `2026-06-10-p1-renderer-automation-stage-report-836.md`。
- README / tracker / plans README / runtime README / design index / latest report 均指向 stage836，next route 是 `stage837_publishable_state_focus_manager_after_stage836`。
- 未发现 stage837+ source owner / focused script / report；stage829-836 仍是已报告但未 stage 的 untracked artifacts，符合当前 automation tail 状态。本轮不是收口既有产物，而是从 stage836 tail 正常推进。
- 工作区起始状态已有 5 个 tracked doc edits 与 stage829-836 untracked artifacts；本轮保留这些内容，不 stage / commit / push。

## 本轮小设计

当前真实 tail 属于 publishable state layout/style runtime manager 后的 focus manager 能力链路。没有未收口的 stage837+ artifacts；已有 stage829-836 未跟踪产物是已报告但未 stage 的正常状态。最近多轮曾有 publication / review / state-store wrapper 节奏，stage833-836 已转入 layout/style 能力族，本轮继续能力收敛到 focus manager，而不是回到 gate / rehearsal vNext。四个 slice 是：stage837 从 stage836 shared layout/style runtime manager 解析 owner-local focus traversal manager input；stage838 消费 stage837 生成非派发 focus movement / selection / caret / rollback / explain preview；stage839 消费 stage838 接入 Todo/settings/AI-generated settings/chat composer/file browser 五类 demo focus inspection/result surfaces；stage840 消费 stage839 抽 shared focus runtime manager/contract/receipt，并固定减少 per-demo focus owner 模板。关键 stop-line：不移动真实焦点，不执行 input pipeline，不提交 state-store，不写 `renderer_state` / `runtime_state`，不扩 public API / public C ABI / native bridge。

## Four Slice Macro Package

### Slice 1：stage837 publishable state focus manager

新增 [runtime_renderer_stage837_publishable_state_focus_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage837_publishable_state_focus_manager.cj)。

- 消费 stage836 shared publishable layout/style runtime manager。
- 生成 owner-local focus traversal manager input、focus scope candidate ledger、focusable slot order ledger 与 caret anchor candidate ledger。
- 绑定 stage834 text/focus measurement plan 与 stage836 runtime manager，准备 stage838 focus movement preview。

### Slice 2：stage838 focus movement preview

新增 [runtime_renderer_stage838_publishable_state_focus_movement_preview.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage838_publishable_state_focus_movement_preview.cj)。

- 消费 stage837 focus manager input。
- 生成 non-dispatching owner-local focus movement preview、selection/caret transition preview、focus rollback snapshot 与 focus change explain receipt。
- 保持 focus dispatch / focus mutation / input pipeline execution blocked，只产出可检查 preview decision。

### Slice 3：stage839 focus demo surface

新增 [runtime_renderer_stage839_publishable_state_focus_demo_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage839_publishable_state_focus_demo_surface.cj)。

- 消费 stage838 focus movement preview。
- 接入 Todo、settings、AI-generated settings、chat composer、file browser 五类 demo focus inspection surfaces。
- 生成 focus result surface receipt，不执行 host mutation。

### Slice 4：stage840 shared focus runtime manager

新增 [runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj)。

- 消费 stage839 demo surface。
- 抽出 shared publishable focus runtime manager、runtime contract 与 execution receipt contract。
- 固定 cycle order：`publishable_state_focus_demo_runtime`。
- 接入 Todo、settings、AI-generated settings、chat composer、file browser 五类 runtime surfaces。
- 准备 next route：`stage841_publishable_state_text_model_after_stage840`。

## 真实能力增量

本轮把 stage836 的 layout/style runtime output 推进到 focus manager first slice。对 minimal UI framework 的增量是：publishable state slot values 现在能通过 shared layout/style runtime manager 形成 owner-local focus traversal input、focus movement preview、selection/caret transition preview、rollback/explain receipt、五类 demo focus inspection surfaces 与 shared focus runtime manager。它仍然不是生产 focus manager，也不执行真实输入或 host mutation；但后续 text model / selection / caret / composition placeholder 可以直接消费 stage840 shared focus contract，而不必继续复制 per-demo focus readiness。

## 周期收敛

已触发能力收敛。本轮没有继续做 publication gate / owner review / visibility rehearsal vNext，而是从 layout/style resolver 继续进入 focus manager 能力族。final packet 固定 `future_per_demo_focus_template_need_reduced=true`，减少后续同构 focus owner/probe/readiness 的必要性。

## Public API 结果

- 本轮没有新增 public surface。
- 没有新增 stable public API。
- 没有扩 public C ABI。
- public declaration scan 只列出现有 public surface：
  - `cjguiExperimentalComponentPreviewApiReady(): Bool`
  - `cjguiExperimentalQueueSubmitShellReady(): Bool`
- 既有 `cjguiExperimentalComponentPreviewApiReady(): Bool` 仍是 `experimental_preview`，不代表 stable compatibility、production truth 或 renderer/runtime write permission。

## 辅助 envelope / readiness

- owner / suite scripts 是 focused verification evidence，不是 production runtime truth。
- stage837-840 packet facts 证明 internal focus manager input / movement preview / demo surface / runtime manager materialized。
- public / forbidden / protected scans 只用于守住 stop-line。
- GitNexus / CodeLattice 对新 untracked source owner 仍有 stale baseline / symbol not found 覆盖缺口；源码读取、focused suites、build 与 scans 是本轮兜底证据。

## 修改文件

新增 source owners：

- [runtime_renderer_stage837_publishable_state_focus_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage837_publishable_state_focus_manager.cj)
- [runtime_renderer_stage838_publishable_state_focus_movement_preview.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage838_publishable_state_focus_movement_preview.cj)
- [runtime_renderer_stage839_publishable_state_focus_demo_surface.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage839_publishable_state_focus_demo_surface.cj)
- [runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj)

新增 focused owner / suite scripts：

- [verify_renderer_stage837_publishable_state_focus_manager_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage837_publishable_state_focus_manager_owner.sh)
- [verify_renderer_stage837_publishable_state_focus_manager_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage837_publishable_state_focus_manager_suite.sh)
- [verify_renderer_stage838_publishable_state_focus_movement_preview_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage838_publishable_state_focus_movement_preview_owner.sh)
- [verify_renderer_stage838_publishable_state_focus_movement_preview_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage838_publishable_state_focus_movement_preview_suite.sh)
- [verify_renderer_stage839_publishable_state_focus_demo_surface_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage839_publishable_state_focus_demo_surface_owner.sh)
- [verify_renderer_stage839_publishable_state_focus_demo_surface_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage839_publishable_state_focus_demo_surface_suite.sh)
- [verify_renderer_stage840_publishable_state_focus_runtime_manager_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage840_publishable_state_focus_runtime_manager_owner.sh)
- [verify_renderer_stage840_publishable_state_focus_runtime_manager_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage840_publishable_state_focus_runtime_manager_suite.sh)

Latest-entry 同步：

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)

新增 report：

- [2026-06-10-p1-renderer-automation-stage-report-840.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-06-10-p1-renderer-automation-stage-report-840.md)

## 验证结果

### RED probes

在新增 source owners 前，stage837-840 owner probes 均按预期失败，失败原因均为 missing source，exit 2：

- stage837 missing `runtime_renderer_stage837_publishable_state_focus_manager.cj`
- stage838 missing `runtime_renderer_stage838_publishable_state_focus_movement_preview.cj`
- stage839 missing `runtime_renderer_stage839_publishable_state_focus_demo_surface.cj`
- stage840 missing `runtime_renderer_stage840_publishable_state_focus_runtime_manager.cj`

### Focused owners / suites

- stage837-840 owner probes all passed after source creation.
- Pre-format recursive stage840 suite first exposed a compile error in stage838: a stale field reference to `didConfirmFocusManagerBoundToStage837FocusManagerInput`. Root cause was an incorrect handoff-field name; patched to consume `didConfirmOwnerLocalFocusTraversalManagerInputMaterialized`.
- Pre-format recursive stage840 suite then exposed a suite expectation bug: stage837 expected raw `focus_traversal_measurement_ledger_materialized=true` in the stage836 packet, but stage836 owns only transitive measurement consumption and runtime-manager binding facts. Patched the suite to require `stage834_publishable_state_text_focus_measurement_plan_consumed_transitively=true`.
- Fresh recursive stage840 suite passed and built `runtime/cjgui`: `/private/tmp/cjgui-stage837-stage840-fix2/stage840/stage840-publishable-state-focus-runtime-manager-suite.packet`.
- Fresh explicit stage837 suite passed: `/private/tmp/cjgui-stage837-stage840-fix2-explicit/stage837/stage837-publishable-state-focus-manager-suite.packet`.
- Fresh explicit stage838 suite passed: `/private/tmp/cjgui-stage837-stage840-fix2-explicit/stage838/stage838-publishable-state-focus-movement-preview-suite.packet`.
- Fresh explicit stage839 suite passed: `/private/tmp/cjgui-stage837-stage840-fix2-explicit/stage839/stage839-publishable-state-focus-demo-surface-suite.packet`.
- `cjfmt -f <file> -o <file>` passed for all four new `.cj` files using a temporary `ps` shim and toolchain envsetup.
- Post-format explicit stage837 suite passed: `/private/tmp/cjgui-stage837-stage840-postfmt/stage837/stage837-publishable-state-focus-manager-suite.packet`.
- Post-format explicit stage838 suite passed: `/private/tmp/cjgui-stage837-stage840-postfmt/stage838/stage838-publishable-state-focus-movement-preview-suite.packet`.
- Post-format explicit stage839 suite passed: `/private/tmp/cjgui-stage837-stage840-postfmt/stage839/stage839-publishable-state-focus-demo-surface-suite.packet`.
- Post-format stage840 suite passed and built `runtime/cjgui`: `/private/tmp/cjgui-stage837-stage840-postfmt/stage840/stage840-publishable-state-focus-runtime-manager-suite.packet`.

stage840 final packet confirms:

```text
stage839_publishable_state_focus_demo_surface_consumed=true
stage838_publishable_state_focus_movement_preview_consumed_transitively=true
stage837_publishable_state_focus_manager_consumed_transitively=true
stage836_publishable_state_layout_style_runtime_manager_consumed_transitively=true
shared_publishable_focus_runtime_manager_materialized=true
publishable_focus_runtime_contract_materialized=true
publishable_focus_execution_receipt_contract_materialized=true
cycle_order_publishable_state_focus_demo_runtime_materialized=true
todo_focus_runtime_surface_materialized=true
settings_focus_runtime_surface_materialized=true
ai_generated_settings_focus_runtime_surface_materialized=true
chat_composer_focus_runtime_surface_materialized=true
file_browser_focus_runtime_surface_materialized=true
focus_runtime_manager_bound_to_stage837_focus_manager_input=true
focus_runtime_manager_bound_to_stage838_movement_preview=true
focus_runtime_manager_bound_to_stage839_demo_surface=true
future_per_demo_focus_template_need_reduced=true
stage841_publishable_state_text_model_after_stage840_prepared=true
focus_manager_enabled=false
focus_mutation=false
input_pipeline_execution=false
public_component_api_added=true
new_public_surface_added=false
stable_public_api_added=false
public_c_abi_added=false
state_store_commit_published=false
action_dispatch=false
state_update_committed=false
visibility_publication_admitted=false
visibility_published=false
renderer_submission=false
renderer_state_write=false
runtime_state_write=false
native_bridge_expansion=false
runtime_package_build_passed=true
stage837_stage840_public_declaration_scan_passed=true
stage837_stage840_forbidden_native_render_token_scan_passed=true
stage840_protected_path_scan_passed=true
new_public_surface=none
public_surface_stability_unchanged=experimental_preview
next_route=stage841_publishable_state_text_model_after_stage840
stage840_publishable_state_focus_runtime_manager_suite_passed=true
```

### Build / scans

- `cjpm build --target-dir /private/tmp/cjgui-stage837-stage840-postfmt/stage840/target --skip-script` passed inside the stage840 suite.
- Direct `cjpm build --target-dir /private/tmp/cjgui-stage837-stage840-direct-build/target --skip-script` also passed.
- Build warning stream remains the existing unused-function / large owner stack-frame pattern; build exits 0.
- `zsh -n` passed for all stage837-840 owner / suite scripts.
- Public declaration scan passed; stage837-840 add no public declarations.
- Explicit public scan showed only:
  - `cjguiExperimentalComponentPreviewApiReady()`
  - `cjguiExperimentalQueueSubmitShellReady()`
- Stage837-840 public/foreign/forbidden native/render token scan passed; explicit forbidden scan had no matches.
- Protected path scan passed for `runtime/cjgui/cjpm.toml`, `runtime/cjgui/src/runtime_state.cj`, `runtime/cjgui/native/cjgui_native_bridge.h`, and `runtime/cjgui/native/cjgui_native_bridge.m`; none were modified.
- `git diff --check` passed.

## GitNexus / CodeLattice

Required production registry: `cangjie-live-codelattice`.

- Pre-edit GitNexus MCP context for `CjguiInternalRendererStage836PublishableStateLayoutStyleRuntimeManagerReadiness` returned symbol not found.
- Pre-edit Tool CLI context for stage836 returned symbol not found.
- Pre-edit Tool CLI impact for stage836 returned target not found / risk `UNKNOWN`; not treated as safe.
- Pre-edit Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all` reported only 5 tracked docs changes / 2 doc symbols / risk low.
- CodeLattice pre-edit impact for stage836 returned stale baseline / symbol not found / risk `UNKNOWN`; not treated as safe.
- Post-edit Tool CLI context for `CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness` returned symbol not found.
- Post-edit Tool CLI impact for stage840 returned target not found / risk `UNKNOWN`; not treated as safe.
- Post-edit Tool CLI `detect-changes --repo cangjie-live-codelattice --scope all` reported only 5 tracked docs changes / 2 doc symbols / risk low; untracked stage837-840 files were not graph-covered.
- CodeLattice impact for stage840 on `/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui` returned stale baseline / file_added / symbol not found / risk `UNKNOWN`; not treated as safe.
- CodeLattice `changed_symbols` reported stale baseline and only tracked `README.md` hunks from the runtime root, with no changed symbols.
- CodeLattice `docs_tests` was unassessable due no changed symbols supplied / stale baseline, with no missing doc/test candidates.
- Production alias status is YELLOW due dirty worktree: 5 modified files and 38 untracked files at the post-source status check before report creation.

## Runtime / Native Probe

No bounded runtime native probe was executed. This package is internal owner / focused suite / dry-run only and does not require live AppKit / Metal execution. No CJGUI harness gap or host limitation was encountered.

## Stop-line 状态

- 第一帧链路：未改变。
- renderer-state write：未执行、未授权、未写入。
- runtime_state write：未执行、未授权、未写入。
- native bridge / C ABI：未扩展。
- renderer submission：未执行。
- production render truth / backend-ready truth：未升级。
- owner acceptance：未授予。
- preview component API commit：未提交。
- state-store commit：未发布。
- action dispatch：未执行。
- input pipeline execution：未执行。
- focus manager：只完成 owner-local traversal input / movement preview / demo inspection surface / runtime manager dry-run；未启用 production manager 或真实 focus mutation。
- stable public API：未新增。
- experimental public API：未新增；只消费 existing preview component API runway。

## 距离真实 UI framework 仍缺什么

本轮推进了 publishable state -> layout/style runtime -> focus traversal input -> focus movement preview -> demo inspection/result surface -> shared focus runtime manager，但仍没有真实 focus mutation、text editing model、IME/composition handling、layout engine、style resolver execution、state-store commit、visibility publication 或 host mutation。第一帧链路和 renderer-state write 边界未改变。下一步最有价值的是基于 stage840 shared focus runtime manager 进入 text model first slice：让 text run / selection / caret / composition placeholder 有 owner-local text value model 和可检查 edit preview，而不是继续复制 focus surface wrapper。

## Canonical Endpoint / Next Route

当前 canonical endpoint：

`CjguiInternalRendererStage840PublishableStateFocusRuntimeManagerReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererStage840PublishableStateFocusRuntimeManagerDraft()`

当前 next route：

`stage841_publishable_state_text_model_after_stage840`

本轮未 stage / commit / push。
