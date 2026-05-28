# P1 Renderer Automation Stage Report 570

日期：2026-05-26

## 本轮定位

当前真实 tail 来自 stage567 `component runtime text input demo surface contract`，next opening 是 `stage568_component_runtime_text_input_layout_style_preview_after_stage567`。最近几轮已经把 text edit / text input 从 host-route surface 收敛到 component runtime model、state executor 和 demo surface contract，本轮继续消费这条链路，但不再只生成同构 readiness：把 text input 的 value / selection / caret / validation 推到 layout/style/text/focus preview、measurement receipts 和 demo-host surface contract。

Stop-line：本轮不新增 public component API，不启用真实 input event pipeline，不 dispatch action，不提交 state update，不发布 visibility，不执行 renderer，不写 renderer-state / runtime_state，不扩 native bridge，不声明 production render truth 或 backend-ready truth。

## Three-Slice Macro Package

Slice 1：stage568 新增 `runtime_renderer_stage568_component_runtime_text_input_layout_style_preview.cj`，消费 `CjguiInternalRendererStage567ComponentRuntimeTextInputDemoSurfaceContractReadiness`，生成 shared text input layout/style/text/focus preview、layout constraint ledger、style token ledger、text run ledger、caret/selection preview ledger、validation adorn preview ledger、focus target preview ledger，以及 Todo、settings、AI-generated settings、chat composer 四个 preview surfaces。

Slice 2：stage569 新增 `runtime_renderer_stage569_component_runtime_text_input_measurement_affordance_executor.cj`，消费 stage568 preview surfaces，生成 shared text input measurement/affordance executor、intrinsic size receipt、caret rect receipt、selection rect receipt、validation adornment receipt、focus ring receipt，以及四个 demo 的 measurement receipts。它把 Slice 1 的 visual preview 变成可检查的 owner-local measurement receipts。

Slice 3：stage570 新增 `runtime_renderer_stage570_component_runtime_text_input_demo_host_surface_contract.cj`，消费 stage569 measurement receipts，生成 shared text input demo-host surface contract/helper，并把 Todo、settings、AI-generated settings、chat composer 接到同一组 checkable text input host surfaces。它把 Slice 2 的 measurement receipts 推进为 demo-host 可检查 surface route，并准备 `stage571_component_runtime_text_input_input_event_adapter_after_stage570`。

## 真实能力增量

本轮把 text input 从“组件级 demo surface contract”推进到“可被 demo host 检查的 visual/measurement surface contract”：同一条链路现在覆盖 layout constraints、style tokens、text runs、caret/selection rect、validation adornment、focus ring 和 chat composer host surface。Chat composer 继续作为新增 demo surface 消费方参与，避免 Todo/settings/AI-generated settings 三件套封闭循环。

周期收敛未触发强制换线；当前 tail 本身是上一轮收敛后的 text input component runtime chain。本轮完成 shared preview、shared measurement executor、shared demo-host surface contract/helper，减少后续为每个 demo 重写 text input layout/style/measurement/host-surface owner 的必要性。

辅助 envelope / readiness 只用于固定 owner-local dry-run 事实、fresh chain 和 stop-line，不升级 production truth、backend-ready truth、public API、layout engine、style resolver、text shaping、focus manager、renderer submission、renderer_state write 或 runtime_state write。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage568_component_runtime_text_input_layout_style_preview.cj`
- `runtime/cjgui/src/runtime_renderer_stage569_component_runtime_text_input_measurement_affordance_executor.cj`
- `runtime/cjgui/src/runtime_renderer_stage570_component_runtime_text_input_demo_host_surface_contract.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage568_component_runtime_text_input_layout_style_preview_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage568_component_runtime_text_input_layout_style_preview_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage569_component_runtime_text_input_measurement_affordance_executor_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage569_component_runtime_text_input_measurement_affordance_executor_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage570_component_runtime_text_input_demo_host_surface_contract_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage570_component_runtime_text_input_demo_host_surface_contract_suite.sh`
- `docs/plans/2026-05-26-p1-renderer-automation-stage-report-570.md`
- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`

## 验证结果

- RED probes：stage568 / stage569 / stage570 owner probes 在源码落地前均因缺少对应 `.cj` owner 文件失败，确认测试先行。
- Formatting：`cjfmt -f` 已逐文件格式化 stage568、stage569、stage570 owner。
- Script syntax：`zsh -n` 覆盖 stage568 / stage569 / stage570 六个 focused scripts，全部通过。
- Owner probes：stage568 / stage569 / stage570 owner probes 全部通过。
- Focused suites：刷新 stage567 suite 后，stage568 suite 消费 stage567 packet 并生成 stage568 packet；stage569 suite 消费 stage568 packet 并生成 stage569 packet；stage570 suite 消费 stage569 packet 并生成 stage570 packet，全部通过。
- Build：`cjpm build --target-dir /private/tmp/cjgui-stage568-stage570/independent-build/target --skip-script` 在 `runtime/cjgui` 通过。输出仍有大量既有 unused warnings；新增 stage568-570 大 readiness builder/default draft 触发 stack-frame warning，但 build 成功。
- Scans：新增 `.cj` 通过 public/foreign scan、forbidden native/render token scan、protected path scan；新增 `.cj` 与 scripts 通过 trailing whitespace scan；`git diff --check` 通过。

本轮没有执行 bounded runtime native probe；改动停留在 internal owner、focused shell probe、dry-run suite 和 build 层，没有触及 Metal/AppKit live path。未遇到新的 CJGUI harness 缺口或宿主限制。

## GitNexus / CodeLattice

使用 repo `cangjie-live-codelattice`。预编辑 `context` / `impact` 查询 stage567 endpoint 返回 not found / UNKNOWN，未把 UNKNOWN 当安全证明，转为源码读取、focused probes、build 与 scans 兜底。后编辑 `context` / `impact` 查询 `CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractReadiness` 仍未被图覆盖，risk UNKNOWN；Tool CLI positional impact 同样返回 target not found / UNKNOWN。

`detect-changes --repo cangjie-live-codelattice --scope all` 返回低风险、affected processes 0，但只覆盖已跟踪文档符号，不覆盖本轮新增 untracked owner/scripts/report；因此不能作为 production safe 证明。CodeLattice `native_review` / `impact` 为 static-only/no runtime proof，impact summary 为 medium；alias status 可用但 stable window 因当前大批 dirty/untracked automation artifacts 为 RED。

## 当前 Endpoint / Next Route

Canonical endpoint：`CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractReadiness` / `cjguiInternalExecuteDefaultRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractDraft()`。

Next route：`stage571_component_runtime_text_input_input_event_adapter_after_stage570`，建议把 stage570 的 checkable text input host surfaces 接到 component-runtime text input input-event adapter，继续保持 non-dispatching / owner-local dry-run，优先覆盖 keyboard text edit、caret movement、selection change 和 validation-triggered preview。

## 距离真实 UI Framework

第一帧链路、renderer-state write、runtime_state write 均未变化；本轮不提升 renderer submission 或 production truth。Minimal UI framework 仍缺真实 public component API、真实 input event pipeline、action dispatch、committed state update、layout engine、style resolver、text shaping、focus manager、backend execution、renderer submission 与可见 demo readback。增量在于：text input 已从 component runtime model/state/surface 进入 layout/style/text/focus preview、measurement receipts 和 demo-host surface contract，可作为后续真实 text component、input adapter、focus manager 与 demo host integration 的内部前置 contract。

## 收口结论

本轮完成完整 three-slice macro package。没有 stage / commit / push。
