# P1 Renderer Automation Stage Report 573

日期：2026-05-26

## 本轮定位

当前真实 tail 来自 stage570 `component runtime text input demo-host surface contract`，next opening 是 `stage571_component_runtime_text_input_input_event_adapter_after_stage570`。最近几轮已经把 text input 从 host-route text edit surface 收敛到 component runtime model、state executor、demo surface、layout/style/measurement 和 demo-host surface contract；本轮触发轻量周期收敛，不再只继续刷新 preview/probe，而是把 demo-host text input surfaces 接入共享 input-event adapter、owner-local state/render cycle executor 和 demo execution contract。

Stop-line：本轮不新增 public component API，不启用真实 input event pipeline，不 dispatch action，不提交 state update，不发布 visibility，不执行 renderer，不写 renderer-state / runtime_state，不扩 native bridge，不声明 production render truth 或 backend-ready truth。

## Three-Slice Macro Package

Slice 1：stage571 新增 `runtime_renderer_stage571_component_runtime_text_input_event_adapter.cj`，消费 `CjguiInternalRendererStage570ComponentRuntimeTextInputDemoHostSurfaceContractReadiness`，生成 shared text input input-event adapter、normalized event ledger，并把 Todo keyboard edit、settings caret movement、AI-generated settings selection change、chat composer validation trigger 事件映射到同一组 owner-local adapter facts。

Slice 2：stage572 新增 `runtime_renderer_stage572_component_runtime_text_input_cycle_executor.cj`，消费 stage571 normalized events，生成 shared text input event cycle executor、action intent ledger、value edit state delta dry-run ledger、caret/selection transition dry-run ledger、validation trigger preview ledger、RenderCommand refresh receipt ledger，以及 Todo、settings、AI-generated settings、chat composer 四个 cycle receipts。它把 Slice 1 的 normalized input events 转成可检查但不提交的 state/render dry-run receipts。

Slice 3：stage573 新增 `runtime_renderer_stage573_component_runtime_text_input_demo_execution_contract.cj`，消费 stage572 cycle receipts，生成 shared text input demo execution contract/helper，并把 Todo、settings、AI-generated settings、chat composer 接到同一组 checkable text input event execution surfaces。它把 Slice 2 的 owner-local state/render cycle receipts 推进为 demo surface 可检查 contract，并准备 `stage574_component_runtime_text_input_focus_validation_probe_after_stage573`。

## 真实能力增量

本轮把 text input 从“可检查 demo-host surface”推进到“可检查 input event -> state/render cycle -> demo execution surface”：同一条共享链路现在覆盖 keyboard edit、caret movement、selection change、validation trigger、value edit state delta、caret/selection transition、validation preview、RenderCommand refresh receipt 和四个 demo execution surfaces。

周期收敛已触发：近期已经连续推进 text input model/state/surface/layout/measurement/host surface，本轮没有再做同构 preview/readiness owner，而是抽出 shared text input input-event adapter、shared text input event cycle executor、shared demo execution contract/helper，减少后续为每个 demo 重写 text-input event execution owner/probe/readiness 的必要性。

辅助 envelope / readiness 只用于固定 fresh chain、owner-local dry-run facts 和 stop-line；不升级 production truth、backend-ready truth、owner acceptance、public API、input pipeline、action dispatch、state commit、visibility publication、renderer submission、renderer_state write 或 runtime_state write。

## 修改文件

- `runtime/cjgui/src/runtime_renderer_stage571_component_runtime_text_input_event_adapter.cj`
- `runtime/cjgui/src/runtime_renderer_stage572_component_runtime_text_input_cycle_executor.cj`
- `runtime/cjgui/src/runtime_renderer_stage573_component_runtime_text_input_demo_execution_contract.cj`
- `runtime/cjgui/native/scripts/verify_renderer_stage571_component_runtime_text_input_event_adapter_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage571_component_runtime_text_input_event_adapter_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage572_component_runtime_text_input_cycle_executor_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage572_component_runtime_text_input_cycle_executor_suite.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage573_component_runtime_text_input_demo_execution_contract_owner.sh`
- `runtime/cjgui/native/scripts/verify_renderer_stage573_component_runtime_text_input_demo_execution_contract_suite.sh`
- `docs/plans/2026-05-26-p1-renderer-automation-stage-report-573.md`
- `README.md`
- `GUI_TASK_TRACKER.md`
- `docs/plans/README.md`
- `runtime/cjgui/README.md`
- `docs/plans/DESIGN_INTENT_INDEX.md`

## 验证结果

- RED probes：stage571 / stage572 / stage573 owner probes 在源码落地前均因缺少对应 `.cj` owner 文件失败，确认测试先行。
- Formatting：`cjfmt -f` 已逐文件格式化 stage571、stage572、stage573 owner。
- Script syntax：`zsh -n` 覆盖 stage571 / stage572 / stage573 六个 focused scripts，全部通过。
- Owner probes：stage571 / stage572 / stage573 owner probes 全部通过。
- Focused suites：刷新 stage570 suite 后，stage571 suite 消费 stage570 packet 并生成 stage571 packet；stage572 suite 消费 stage571 packet 并生成 stage572 packet；stage573 suite 消费 stage572 packet 并生成 stage573 packet，全部通过。
- Build：`cjpm build --target-dir /private/tmp/cjgui-stage571-stage573/independent-build/target --skip-script` 在 `runtime/cjgui` 通过。输出仍有大量既有 unused warnings；新增 stage571-573 大 readiness builder/default draft 触发 stack-frame warning，但 build 成功。
- Scans：新增 `.cj` 通过 public/foreign scan、forbidden native/render token scan、protected path scan；新增 `.cj` 与 scripts 通过 trailing whitespace scan；最终 `git diff --check` 通过。

本轮没有执行 bounded runtime native probe；改动停留在 internal owner、focused shell probe、dry-run suite 和 build 层，没有触及 Metal/AppKit live path。未遇到新的 CJGUI harness 缺口或宿主限制。

## GitNexus / CodeLattice

使用 repo `cangjie-live-codelattice`。预编辑 `context` / `impact` 查询 stage570 endpoint 返回 not found / UNKNOWN，未把 UNKNOWN 当安全证明，转为源码读取、focused probes、build 与 scans 兜底。后编辑 `context` / `impact` 查询 `CjguiInternalRendererStage573ComponentRuntimeTextInputDemoExecutionContractReadiness` 仍未被图覆盖，risk UNKNOWN；Tool CLI positional impact 同样返回 target not found / UNKNOWN。

`detect-changes --repo cangjie-live-codelattice --scope all` 返回低风险、affected processes 0，但只覆盖已跟踪文档符号，不覆盖本轮新增 untracked owner/scripts/report；因此不能作为 production safe 证明。CodeLattice `after_edit` / `native_review` / `impact` / `docs_tests` / `config_examples` 均为 static-only/no runtime proof，impact summary 为 medium；`changed_symbols` 在 `runtime/cjgui` root 因非 git repo 失败，在 live repo root 因 deny-list 拒绝。alias status 可用但 stable window 因当前大批 dirty/untracked automation artifacts 为 RED。

## 当前 Endpoint / Next Route

Canonical endpoint：`CjguiInternalRendererStage573ComponentRuntimeTextInputDemoExecutionContractReadiness` / `cjguiInternalExecuteDefaultRendererStage573ComponentRuntimeTextInputDemoExecutionContractDraft()`。

Next route：`stage574_component_runtime_text_input_focus_validation_probe_after_stage573`，建议把 stage573 的 checkable text input event execution surfaces 接到 focus/validation probe：优先验证焦点路由、validation adorn refresh、selection/caret state preview 与 RenderCommand receipt 的一致性，继续保持 non-dispatching / owner-local dry-run。

## 距离真实 UI Framework

第一帧链路、renderer-state write、runtime_state write 均未变化；本轮不提升 renderer submission 或 production truth。Minimal UI framework 仍缺真实 public component API、真实 input event pipeline、action dispatch、committed state update、layout engine、style resolver、text shaping、focus manager、backend execution、renderer submission 与可见 demo readback。增量在于：text input 已从 component runtime model/state/surface/host surface 进入可检查的 input-event adapter、state/render cycle executor 和 demo execution contract，可作为后续真实 text component、focus manager、validation model、input pipeline adapter 与 demo host integration 的内部前置 contract。

## 收口结论

本轮完成完整 three-slice macro package。没有 stage / commit / push。
