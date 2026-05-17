# P1 Renderer automation stage report 86

状态：completed / non_d3_recovery: true / automation_blocker: false_for_non_d3_recovery / external_d3_blocker: true

时间：2026-05-17T17:28:14+0800

## 本轮完成的工程阶段包

本轮接续 stage report 85 的 D3 external handoff blocker，没有把 next opening 当作停止点。当前 automation shell 仍不能执行 runtime native probe，但这只阻止 D3 runtime native execution；本轮在同一 stop-line 内完成 3 个真实工程增量，用 script-managed evidence 强化 non-Metal recovery / handoff route。

真实工程增量：

1. external capability detector：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_external_capability_detector.sh)。该 probe 重跑 stage85 external handoff classification，读取 handoff packet，并生成 capability packet，记录 `cjpm_available=true`、`cjc_available=true`、`clang_available=true`、`xcrun_available=true`、`system_profiler_available=true`、`auto_close_smoke_available=true`，同时确认 `smoke_environment_classification=automation_smoke_metal_unavailable` / exit 20、`failure_domain=automation_environment`、`d3_approval_env_true=false`。
2. handoff rerun contract：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_handoff_rerun_contract.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_handoff_rerun_contract.sh)。该 probe 消费 capability packet，生成 rerun contract，固定下一次真正 D3 runtime native probe execution 需要 `required_next_actor=human_operator`、`required_shell=metal_capable_shell`、`required_explicit_approval=true`，并记录 `automation_can_continue_non_d3_recovery=true`。
3. related regression guards aggregation：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_recovery_guard_aggregation.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_recovery_guard_aggregation.sh)。该 probe 嵌套验证 failure-domain guard、external handoff classification、capability detector 与 rerun contract，生成 aggregation packet，固定 `related_regression_guards_aggregated=true`、`non_metal_recovery_route_landed=true`、`code_failure_domain=false`。

不计入工程增量的 housekeeping：

- 本 report。
- README、GUI_TASK_TRACKER、docs/plans README、runtime/cjgui README、DESIGN_INTENT_INDEX 的 latest-entry / next route 最小同步。
- topic navigation reconciliation 仍折叠进 report；本轮未新增 compact manifest 或 topic manifest 长流水。

## 当前 canonical endpoint / default draft / runtime input

本轮不改变 runtime canonical endpoint：

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureFirstSliceReadiness`

## Environment blocker / route switch

遇到 environment blocker：是。stage85 / capability detector / aggregation guard 均确认当前 automation shell 为 `automation_smoke_metal_unavailable` / exit 20，`failure_domain=automation_environment`，`code_failure_domain=false`。

已切换路线：是。本轮没有把 Metal unavailable 当作终点，而是切到 non-D3 recovery route，落地 capability detector、handoff rerun contract 与 related regression guard aggregation。D3 runtime native probe execution 仍必须等 human-approved Metal-capable shell。

## Stop-line

stop-line 保持：是。本轮只新增 probe/script/docs。没有调用 application singleton accessor，没有新增 production native C ABI，没有扩展 native bridge，没有执行 runtime native probe，没有创建或激活 `NSApplication`，没有调用 `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`，没有创建 visible `NSWindow`，没有 visible order、`nextDrawable`、render、commit、present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` change 或 public API。

## 验证结果

- RED：三个新增脚本在新增前分别以 missing script exit 127 失败。
- capability detector first GREEN：失败，暴露 `envsetup.sh` 在当前 sandbox 中调用 `ps` 被拒；已按 stage84 模式加入 `/tmp` ps shim 后 GREEN 通过。
- capability detector fixed GREEN：通过，输出 capability packet 与 `cjpm_available=true` / `cjc_available=true` / `smoke_environment_classification=automation_smoke_metal_unavailable` / `d3_approval_env_true=false`。
- handoff rerun contract GREEN：通过，输出 rerun contract 与 `required_next_actor=human_operator`、`required_shell=metal_capable_shell`、`required_explicit_approval=true`。
- recovery guard aggregation GREEN：通过，输出 `related_regression_guards_aggregated=true`、`non_metal_recovery_route_landed=true`、`automation_can_continue_non_d3_recovery=true`。
- 嵌套 probe 链重跑 stage85 / stage84，覆盖 environment classification、native bridge skeleton / no-resource symbols / cjpm package link regression 与 runtime package build。
- direct `cjpm build --target-dir /tmp/cjgui-stage86-direct-build --skip-script`：通过，仍为既有 230 warnings。
- closure scans：`git diff --check` 无输出；protected path scan 对 `runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 无输出；production native bridge forbidden diff scan 无命中；public / foreign declaration diff scan 无命中；new script hard-boundary token scan 在排除注释与 grep guard pattern 后无命中；新增三个脚本 executable bit 存在。

## GitNexus / CodeLattice 结果

使用 GitNexus repo：`cangjie-live-codelattice`。

- Pre-edit CLI `context init --repo cangjie-live-codelattice` 在当前 CLI 中被解析为 `context init` symbol query，返回 ambiguous `init` candidates；不作为安全证明。
- Pre-edit CLI impact `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness`：UNKNOWN / target not found，impactedCount 0。
- Pre-edit CLI impact `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionDraft`：UNKNOWN / target not found，impactedCount 0。
- CodeLattice sidecar `before_edit` 对 live repo path 返回 `path_denied`，不作为安全证明。
- Pre-edit MCP `detect_changes --scope all`：changed_count 3、changed_files 10、affected_count 0、risk_level low。
- Final MCP `detect_changes --scope all`：changed_count 3、changed_files 10、affected_count 0、risk_level low。
- Final CLI `detect-changes --repo cangjie-live-codelattice --scope all`：Changes 10 files / 3 symbols、Affected processes 0、Risk level low。
- GitNexus UNKNOWN / not found / path_denied 不作为安全证明；本轮用 RED/GREEN probe、嵌套 build/probe chain、source review 与 closure scans 兜底。

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness source/build/probe evidence strengthening for non-D3 recovery guards, or explicit human-approved D3 runtime native probe execution in a Metal-capable shell`

如果没有 explicit human-approved Metal-capable shell，不应执行 runtime native probe；可以继续做 source/build/probe evidence strengthening，但不得继续新增同构 no-accessor / no-bridge / no-runtime-execution wrapper。

## 设计意图出口自检

- 本轮是否改变主题状态：是，新增 non-D3 recovery guard route。
- 本轮是否改变 canonical tail / endpoint：否。
- 本轮是否改变 owner / truth / stop-line：不新增 runtime owner；新增 script-managed capability / rerun / aggregation evidence；stop-line 不扩张。
- 本轮是否改变唯一 next opening：是。
- 是否需要同步 topic manifest：否。
- 已同步的 topic manifest：none。
- 若未同步，理由：本轮按普通 automation stage report 执行，latest-entry 已同步；topic manifest 延后到下一阶段包边界或硬边界再压缩。

## 人工介入

需要人工介入：只限 D3 runtime native probe execution。当前自动化仍可继续 non-D3 source/build/probe evidence strengthening；若要真正执行 runtime native probe，必须由 human-approved Metal-capable shell 明确跨 D3。

automation_blocker: false_for_non_d3_recovery
