# P1 Renderer Automation Stage Report 628

日期：2026-05-26

## 本轮定位

真实 tail 来自 stage624：`CjguiInternalRendererStage624SharedFocusValidationDemoHostRuntimeContractReadiness` 已把 focus/validation 的 host integration、host frame、host interaction receipt 收敛成 shared demo-host runtime contract，next opening 指向 component runtime / focus-validation host input adapter。

最近多轮持续在 focus / validation / input / state / render / surface / runtime 上做相邻 dry-run，已触发周期收敛。本轮没有继续复制 per-demo host input owner / probe，而是把 stage624 demo-host runtime contract 推进到 shared host input adapter、normalized host input event、non-dispatching cycle executor 和 reusable host-input runtime contract。

当前 canonical endpoint 是 `CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractReadiness` / `cjguiInternalExecuteDefaultRendererStage628SharedFocusValidationHostInputRuntimeContractDraft()`。

当前 next route 是 `stage629_component_runtime_focus_validation_host_input_result_surface_after_stage628`。

## Four-Slice Macro Package

Slice 1: stage625 focus/validation host input adapter

- 新增 [runtime_renderer_stage625_focus_validation_host_input_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage625_focus_validation_host_input_adapter.cj)。
- 消费 stage624 shared focus/validation demo-host runtime contract。
- 生成 shared host input adapter、host input binding ledger、validation display host input route、focus handoff host input route、input feedback host input route、semantic diff host input route。
- 产出 Todo、settings、AI-generated settings、chat composer 四个 demo host input adapters。

Slice 2: stage626 focus/validation host input event normalizer

- 新增 [runtime_renderer_stage626_focus_validation_host_input_event_normalizer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage626_focus_validation_host_input_event_normalizer.cj)。
- 消费 Slice 1 的 stage625 host input adapters。
- 生成 shared host input event normalizer、normalized validation display event、normalized focus movement event、normalized input feedback event、normalized semantic diff event。
- 四个 demo host input adapters 被归一成四个 demo normalized host input events。

Slice 3: stage627 focus/validation host input cycle executor

- 新增 [runtime_renderer_stage627_focus_validation_host_input_cycle_executor.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage627_focus_validation_host_input_cycle_executor.cj)。
- 消费 Slice 2 的 stage626 normalized host input events。
- 生成 shared non-dispatching host input cycle executor、action intent preview、state delta dry-run、RenderCommand refresh、focus transition、validation display、input feedback receipts。
- 四个 normalized demo events 变成可检查的 host input cycle receipts。

Slice 4: stage628 shared focus/validation host-input runtime contract

- 新增 [runtime_renderer_stage628_shared_focus_validation_host_input_runtime_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage628_shared_focus_validation_host_input_runtime_contract.cj)。
- 消费 Slice 3 的 stage627 host input cycle receipts。
- 抽出 shared focus/validation host-input runtime contract/helper/execution receipt contract。
- 固定 `host_input_event_action_state_render_host_surface_receipt` cycle order。
- Todo、settings、AI-generated settings、chat composer 共用同一组 host-input runtime surfaces，减少后续 per-demo focus/validation host-input adapter / normalizer / executor / runtime owner 和 probe 模板。

## 真实能力增量

本轮把 stage624 的 demo-host runtime contract 推进成一条更完整的 host input dry-run route：host frame / interaction receipt 不再只停在 host surface，而是能经由 shared host input adapter 变成 normalized host input events，再进入 non-dispatching action/state/render cycle，并落到 shared host-input runtime contract。

这更接近真实 UI framework 的原因是：后续 result surface、validation display、focus transition 和 input feedback 可以消费同一个 host-input runtime contract，而不是为 Todo、settings、AI-generated settings、chat composer 各自复制 adapter、normalizer、cycle executor 和 runtime probe。

## 周期收敛结果

本轮触发周期收敛。收敛点是把 repeated focus/validation host-input preview/probe 链路压缩为一条 shared route：

- `future_per_demo_focus_validation_host_input_template_need_reduced=true`
- `host_input_runtime_bound_to_stage625_adapter=true`
- `host_input_runtime_bound_to_stage626_normalizer=true`
- `host_input_runtime_bound_to_stage627_cycle_executor=true`
- 四个 demo 共用同一路线：Todo、settings、AI-generated settings、chat composer。

辅助 envelope / readiness 仍然存在，但只作为可验证边界：owner readiness、suite packet、stop-line facts 和 next route fact。它们不被解释为 production truth、backend-ready truth 或 live host execution。

## Stop-Line

本轮没有扩 stable public API / public C ABI，没有改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，没有改 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)，没有改 native bridge。

保持以下边界：

- `production_render_truth=false`
- `backend_ready_truth=false`
- `owner_acceptance_granted=false`
- `layout_engine_enabled=false`
- `style_resolver_enabled=false`
- `focus_manager_enabled=false`
- `input_event_pipeline_execution=false`
- `action_dispatch=false`
- `state_update_committed=false`
- `visibility_publication_admitted=false`
- `visibility_published=false`
- `public_component_api_added=false`
- `renderer_submission=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `native_bridge_expansion=false`

## 修改文件

Runtime owner:

- [runtime_renderer_stage625_focus_validation_host_input_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage625_focus_validation_host_input_adapter.cj)
- [runtime_renderer_stage626_focus_validation_host_input_event_normalizer.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage626_focus_validation_host_input_event_normalizer.cj)
- [runtime_renderer_stage627_focus_validation_host_input_cycle_executor.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage627_focus_validation_host_input_cycle_executor.cj)
- [runtime_renderer_stage628_shared_focus_validation_host_input_runtime_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_stage628_shared_focus_validation_host_input_runtime_contract.cj)

Focused probes / suites:

- [verify_renderer_stage625_focus_validation_host_input_adapter_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage625_focus_validation_host_input_adapter_owner.sh)
- [verify_renderer_stage625_focus_validation_host_input_adapter_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage625_focus_validation_host_input_adapter_suite.sh)
- [verify_renderer_stage626_focus_validation_host_input_event_normalizer_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage626_focus_validation_host_input_event_normalizer_owner.sh)
- [verify_renderer_stage626_focus_validation_host_input_event_normalizer_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage626_focus_validation_host_input_event_normalizer_suite.sh)
- [verify_renderer_stage627_focus_validation_host_input_cycle_executor_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage627_focus_validation_host_input_cycle_executor_owner.sh)
- [verify_renderer_stage627_focus_validation_host_input_cycle_executor_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage627_focus_validation_host_input_cycle_executor_suite.sh)
- [verify_renderer_stage628_shared_focus_validation_host_input_runtime_contract_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage628_shared_focus_validation_host_input_runtime_contract_owner.sh)
- [verify_renderer_stage628_shared_focus_validation_host_input_runtime_contract_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_stage628_shared_focus_validation_host_input_runtime_contract_suite.sh)

Latest-entry docs:

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [2026-05-26-p1-renderer-automation-stage-report-628.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-26-p1-renderer-automation-stage-report-628.md)

## 验证结果

TDD red pass:

- stage625 owner probe 在 source 缺失时失败，rc=2，分类为 missing source。
- stage626 owner probe 在 source 缺失时失败，rc=2，分类为 missing source。
- stage627 owner probe 在 source 缺失时失败，rc=2，分类为 missing source。
- stage628 owner probe 在 source 缺失时失败，rc=2，分类为 missing source。

Green focused probes / suites:

- `zsh -n` 通过 8 个新增 owner / suite scripts。
- stage625 owner probe 通过。
- stage626 owner probe 通过。
- stage627 owner probe 通过。
- stage628 owner probe 通过。
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage625_focus_validation_host_input_adapter_suite.sh` 通过。
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage626_focus_validation_host_input_event_normalizer_suite.sh` 通过。
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage627_focus_validation_host_input_cycle_executor_suite.sh` 通过。
- `zsh runtime/cjgui/native/scripts/verify_renderer_stage628_shared_focus_validation_host_input_runtime_contract_suite.sh` 通过。

Build / scans:

- stage628 suite 内执行 `cjpm build --target-dir /private/tmp/cjgui-stage625-stage628/stage628/target --skip-script`，结果通过。
- build log 有既有 large stack-frame warnings，并新增 stage626 / stage628 相关 warning；未升级为失败。
- stage628 suite 通过 public / foreign declaration scan。
- stage628 suite 通过 forbidden native/render token scan。
- stage628 suite 通过 protected path scan，确认 `runtime/cjgui/cjpm.toml`、`runtime_state.cj`、native bridge 未修改。
- `cjfmt -f` 已用 sandbox-safe `ps` shim 完成 stage625-628 四个 `.cj` 文件格式化。
- 初次 stage628 suite build 暴露 constructor arity mismatch，已修正 stage625-628 readiness constructor stop-line bool 传参并重新格式化、重跑 suite chain。
- `git diff --check` 通过。
- 本轮修改文件 / 新增文件尾随空白扫描通过。
- 本轮修改文件冲突标记扫描通过。

Suite packet:

- `/private/tmp/cjgui-stage625-stage628/stage628/stage628-shared-focus-validation-host-input-runtime-contract-suite.packet`
- 关键 facts 包括 `stage627_focus_validation_host_input_cycle_executor_consumed=true`、`stage626_focus_validation_host_input_event_normalizer_consumed_transitively=true`、`stage625_focus_validation_host_input_adapter_consumed_transitively=true`、`stage624_shared_focus_validation_demo_host_runtime_contract_consumed_transitively=true`、`shared_focus_validation_host_input_runtime_contract_materialized=true`、`shared_focus_validation_host_input_runtime_helper_materialized=true`、`shared_focus_validation_host_input_execution_receipt_contract_materialized=true`、`cycle_order_host_input_event_action_state_render_host_surface_receipt_materialized=true`、`future_per_demo_focus_validation_host_input_template_need_reduced=true`、`runtime_package_build_passed=true`、`stage629_component_runtime_focus_validation_host_input_result_surface_prepared=true`。

## GitNexus / CodeLattice

按 `cangjie-live-codelattice` 执行。Graph 未覆盖新增 fresh symbols，因此 UNKNOWN / not found 没被当作安全证明：

- 编辑前 `context` / `impact` 查询 stage624 tail 时，GitNexus 未找到 symbol，impact risk 为 `UNKNOWN`、`impactedCount=0`。
- 编辑后查询 `CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractReadiness`，GitNexus 仍未找到 fresh symbol，impact risk 为 `UNKNOWN`、`impactedCount=0`。
- `detect-changes --repo cangjie-live-codelattice --scope all` 返回 README sections 为 changed symbols，risk low；但该结果未覆盖新增 untracked stage625-628 sources/scripts。
- CodeLattice static review 对 stage625-628 给出 static-only 结果，没有 runtime production proof；因此仍以源码读取、focused suites、package build 和 scans 兜底。
- `/Users/jiangxuanyang/Desktop/codelattice/scripts/cangjie-production-alias-check.sh --status` 确认 live repo 路径为 `/Users/jiangxuanyang/Desktop/cangjie`，工作区 dirty，stable window RED；本轮未把 isolated probes 解释为 production truth。

## Native / Harness

本轮未执行 bounded runtime native probe，因为没有改 native bridge、Metal/AppKit call site、runtime state、renderer-state write 或 visible-window path。未遇到新的 CJGUI harness 缺口或宿主限制。

toolchain `envsetup.sh` 在 sandbox 内直接调用时需要现有 `ps` shim 适配；本轮沿用 suite 内临时 `ps` shim，不改变 repo source。

## 与真实 Demo 的距离

第一帧链路仍未发布新的 production truth；renderer-state write 与 runtime_state write 仍保持 blocked。当前 minimal UI framework 增量是内部 contract：focus/validation 的 host runtime surface 已能进入 host input adapter、normalized event、action/state/render dry-run cycle，并落到 shared host-input runtime contract。

距离真实可写 UI 仍缺：

- 真实 input event pipeline 到 stage628 host-input runtime contract 的 live adapter。
- 真实 focus manager / layout engine / style resolver / text shaping。
- state update commit 与 RenderCommand submission。
- demo host inspection 的 live host execution 与 result surface refresh。
- public component API 与 stable runtime API。

## Canonical Endpoint / Next Route

Canonical endpoint:

- `CjguiInternalRendererStage628SharedFocusValidationHostInputRuntimeContractReadiness`
- `cjguiInternalExecuteDefaultRendererStage628SharedFocusValidationHostInputRuntimeContractDraft()`

Next route:

- `stage629_component_runtime_focus_validation_host_input_result_surface_after_stage628`

下一条最值得推进的工程目标：把 stage628 shared host-input runtime contract 接到 component runtime focus/validation host-input result surface，让 validation/error surface、focus movement preview、input feedback display 和 semantic diff refresh 消费同一 shared runtime contract。
