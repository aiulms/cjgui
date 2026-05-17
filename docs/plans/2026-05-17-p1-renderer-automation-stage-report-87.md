# P1 Renderer automation stage report 87

状态：completed / source_build_probe_evidence: true / automation_blocker: false_for_non_d3_recovery / external_d3_blocker: true

时间：2026-05-17T18:11:28+0800

## 本轮完成的工程阶段包

本轮接续 stage report 86 的 `source/build/probe evidence strengthening` next opening，没有把 D3 Metal blocker 当作终点，也没有继续新增同构 no-accessor / no-bridge wrapper。当前 automation shell 仍不能执行 D3 runtime native probe；本轮在同一 stop-line 内完成 5 个真实工程增量，达到目标线 4 到 6 个。

真实工程增量：

1. 新 internal owner + focused owner probe：[runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence.cj) 与 [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_owner.sh)。新 owner 消费 closure-completion readiness，把 non-D3 source owner probe、runtime package build、recovery aggregation guard、failure-domain matrix 与 focused regression suite 固定为 evidence route；focused owner probe GREEN。
2. source/build/probe evidence guard：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_source_build_probe_evidence_guard.sh)。新增前 RED 为 missing script exit 127；GREEN 后串联 owner probe、stage86 recovery aggregation guard 与 `cjpm build --skip-script`，生成 evidence packet，确认 `runtime_package_build_passed=true`、`source_build_probe_evidence_strengthened=true`。
3. failure-domain matrix：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_failure_domain_matrix.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_failure_domain_matrix.sh)。新增前 RED 为 missing script exit 127；GREEN 后消费 capability packet，生成 matrix packet，确认 `toolchain_plane=cjpm_cjc_available`、`native_probe_prerequisite_plane=clang_and_auto_close_smoke_available`、`environment_plane=automation_environment_blocked`、`approval_plane=d3_approval_absent`。
4. focused regression orchestration runner：[verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_focused_regression_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_focused_regression_suite.sh)。新增前 RED 为 missing script exit 127；GREEN 后编排 source/build/probe guard、failure-domain matrix 与 recovery aggregation guard，输出 `focused_regression_suite_passed=true`。
5. bugfix + 验证闭环：source/build/probe guard 首轮 GREEN 暴露 direct `cjpm build` 从 repo root 运行导致 `./cjpm.toml` missing；已改为在 `runtime/cjgui` 内执行。随后又修复 loose `failure_domain=` parser 误匹配 `code_failure_domain=false` 的问题，改为从 packet 读取 anchored facts；source/build/probe guard 与 focused regression suite 均重新 GREEN。

不计入工程增量的 housekeeping：

- 本 report。
- README、GUI_TASK_TRACKER、docs/plans README、runtime/cjgui README、DESIGN_INTENT_INDEX 的 latest-entry / next route 最小同步。
- topic navigation reconciliation 仍折叠进本 report；本轮未新增 compact manifest 或 topic manifest 长流水。

多个增量是否同一类型：否。本轮覆盖 internal owner、focused owner probe、build-backed guard、failure-domain matrix、probe orchestration runner 与 bugfix recovery，已补充不同类型增量。

## 当前 canonical endpoint / default draft / runtime input

本轮把当前 internal evidence tail 推进到 source/build/probe evidence owner：

- canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeSourceBuildProbeEvidenceReadiness`
- default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeSourceBuildProbeEvidenceDraft()`
- runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbeRuntimeNativeReadinessProbeExecutionClosureCompletionReadiness`

该 endpoint 只表达 source/build/probe evidence readiness；不执行 runtime native probe，不创建 singleton，不调用 application accessor，不扩 native bridge，不消费 human approval，不升级 production ownership truth。

## Environment blocker / route switch

遇到 environment blocker：是。failure-domain matrix、source/build/probe guard 与 focused regression suite 均确认当前 automation shell 为 `automation_smoke_metal_unavailable` / exit 20，`failure_domain=automation_environment`，`code_failure_domain=false`。

已切换路线：是。本轮没有把 Metal unavailable 当作终点，而是继续 non-D3 source/build/probe evidence strengthening。D3 runtime native probe execution 仍必须等 human-approved Metal-capable shell。

## Stop-line

stop-line 保持：是。本轮没有调用 application singleton accessor，没有新增 production native C ABI，没有扩展 native bridge，没有执行 runtime native probe，没有创建或激活 `NSApplication`，没有调用 `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`，没有创建 visible `NSWindow`，没有 visible order、`nextDrawable`、render、commit、present、GPU submission、renderer state write、`runtime_state.cj` write、`runtime/cjgui/cjpm.toml` change 或 public API。

## 验证结果

- RED：source/build/probe guard、failure-domain matrix、focused regression suite 三个新增脚本在新增前分别以 missing script exit 127 失败。
- focused owner probe GREEN：通过，输出 `runtime_native_probe_source_build_probe_evidence_owner_present=true`、`source_build_probe_evidence_strengthening_route=true`、`runtime_native_probe_execution=false`。
- failure-domain matrix GREEN：通过，输出 `smoke_environment_classification=automation_smoke_metal_unavailable`、`failure_domain=automation_environment`、`code_failure_domain=false`、`source_build_probe_route_available=true`。
- source/build/probe guard first GREEN：失败，暴露 build cwd bug；修复后 GREEN。
- source/build/probe guard parser recovery：修复 loose parser 后 GREEN，输出 `runtime_package_build_passed=true`、`source_build_probe_evidence_strengthened=true`、`failure_domain=automation_environment`。
- focused regression suite GREEN：通过，输出 `source_build_probe_guard_passed=true`、`failure_domain_matrix_passed=true`、`recovery_aggregation_guard_passed=true`、`focused_regression_suite_passed=true`。
- direct `cjpm build --target-dir /tmp/cjgui-stage87-direct-build --skip-script`：通过，仍为既有 230 warnings；direct build 需要 `/tmp` ps shim 后 source envsetup。
- closure scans：`git diff --check` 无输出；protected path scan 对 `runtime/cjgui/src/runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 无输出；production native bridge forbidden diff scan 无命中；public / foreign declaration diff scan 无命中；new source/script hard-boundary token scan 在排除注释与 grep guard pattern 后无命中；新增四个脚本 executable bit 存在。

## GitNexus / CodeLattice 结果

使用 GitNexus repo：`cangjie-live-codelattice`。

- Pre-edit MCP context / impact for previous closure-completion endpoint and default draft：target not found / UNKNOWN，impactedCount 0；不作为安全证明。
- Pre-edit Tool CLI context / impact for previous closure-completion default draft：target not found / UNKNOWN；不作为安全证明。
- GitNexus UNKNOWN / not found 不作为安全证明；本轮用 source reads、focused owner probe、nested RED/GREEN probes、direct build 与 closure scans 兜底。
- Final MCP `detect_changes --scope all`：changed_count 3、changed_files 10、affected_count 0、risk_level low；仅覆盖 tracked docs/script changes，不覆盖本轮新增 untracked source/script/report。
- Final CLI `detect-changes --repo cangjie-live-codelattice --scope all`：Changes 10 files / 3 symbols、Affected processes 0、Risk level low。
- Final MCP context / impact for new source/build/probe endpoint：target not found / UNKNOWN，impactedCount 0；不作为安全证明。
- CodeLattice `codelattice_changed_symbols` on live repo path returned `path_denied`；不作为安全证明。
- 新增 untracked source/script/report 以 focused owner probe、source/build/probe guard、failure-domain matrix、focused regression suite、direct build 与 scans 为主证据。

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness human-approved D3 runtime native probe execution in a Metal-capable shell, or non-D3 focused regression suite rerun / source-build-probe evidence maintenance without crossing D3`

如果没有 explicit human-approved Metal-capable shell，不应执行 runtime native probe。当前自动化可继续 rerun / maintenance / evidence strengthening，但不应继续制造同构 no-accessor / no-bridge / no-runtime-execution wrapper。

## 设计意图出口自检

- 本轮是否改变主题状态：是，source/build/probe evidence route 已成为当前 non-D3 evidence tail。
- 本轮是否改变 canonical tail / endpoint：是，推进到 source/build/probe evidence owner。
- 本轮是否改变 owner / truth / stop-line：新增 internal owner 与 script-managed evidence；truth 不升级到 production；stop-line 不扩张。
- 本轮是否改变唯一 next opening：是。
- 是否需要同步 topic manifest：否。
- 已同步的 topic manifest：none。
- 若未同步，理由：本轮按普通 automation stage report 执行，latest-entry 已同步；topic manifest 延后到下一阶段包边界或硬边界再压缩。

## 人工介入

需要人工介入：只限 D3 runtime native probe execution。当前自动化仍可继续 non-D3 focused regression suite rerun / source-build-probe evidence maintenance；若要真正执行 runtime native probe，必须由 human-approved Metal-capable shell 明确跨 D3。

automation_blocker: false_for_non_d3_recovery
