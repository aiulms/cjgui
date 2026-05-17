# P1 Renderer Automation Stage Report 91

日期：2026-05-17

状态：automation report / continuous engineering stage package / non-D3 explicit approval rerun contract

## 本轮目标

本轮不是完成单个 next opening，而是在当前 Renderer visible-window `NSApplication` shared-application runtime native-readiness stop-line 内连续推进工程阶段包。输入路线来自 stage90 explicit approval evidence mesh：可以继续做 non-D3 explicit approval evidence mesh rerun / package-link replay / failure-domain continuity，但不能消费 D3 approval，也不能越过 runtime native probe execution、production `NSApplication.sharedApplication` accessor call site、visible window、drawable、render encoder、draw、commit、present、renderer state write 或 public surface 边界。

## GitNexus / CodeLattice 预检

- GitNexus repo 使用 `cangjie-live-codelattice`。
- GitNexus `context` / CLI `impact` 对最新 stage90 endpoint 返回 not found / `UNKNOWN`，因此没有把图谱缺失当作安全证明。
- CodeLattice source sidecar 对 stage90 draft 做 impact preview，结果为 LOW / no callers。
- 后续用源码阅读、focused probes、build、protected path scan、public declaration scan、forbidden scan 与 GitNexus `detect_changes` 兜底。

## 真实工程增量

本轮完成 6 个真实工程增量：

1. 新 internal owner + focused owner probe
   - 新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract.cj)。
   - 新增 focused owner probe [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_rerun_contract_owner.sh)。
   - Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalRerunContractDraft()`。
   - Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeExplicitApprovalHandoffEvidenceMeshReadiness`。

2. 新 native/script probe + RED/GREEN 验证
   - 新增 two-pass mesh rerun contract [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_mesh_rerun_contract.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_mesh_rerun_contract.sh)。
   - RED：目标 owner / scripts 不存在时 `test -f` / `test -x` 失败。
   - GREEN：两次隔离 `TMPDIR` 运行 stage90 mesh runner，确认 `first_mesh_runner_passed=true`、`second_mesh_runner_passed=true`、`two_pass_mesh_rerun_contract_passed=true`、`stable_non_d3_approval_facts_across_reruns=true`、`environment_drift_between_mesh_reruns=false`。

3. Source/build/probe evidence strengthening
   - 新增 source/build guard [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_source_build_guard.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_source_build_guard.sh)。
   - Guard 串联 owner probe、`cjpm build --skip-script`、public declaration scan、protected path scan 与 native forbidden scan。
   - GREEN：`runtime_package_build_passed=true`、`source_build_guard_passed=true`、`code_failure_domain=false`。

4. Capability / handoff / rerun contract
   - 新增 handoff packet aggregator [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_evidence_handoff_packet.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_evidence_handoff_packet.sh)。
   - 它聚合 two-pass rerun packet 与 source/build packet，输出 explicit approval evidence handoff packet。
   - GREEN：`mesh_rerun_contract_passed=true`、`source_build_guard_passed=true`、`handoff_packet_ready=true`、`required_next_actor=human_operator`、`required_shell=explicitly_approved_shell`。

5. Probe orchestration runner / focused regression suite
   - 新增 focused regression suite [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_regression_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_explicit_approval_regression_suite.sh)。
   - Suite 串联 owner probe、mesh rerun contract、source/build guard 与 handoff packet。
   - GREEN：`rerun_contract_owner_probe_passed=true`、`mesh_rerun_contract_passed=true`、`source_build_guard_passed=true`、`evidence_handoff_packet_passed=true`、`explicit_approval_regression_suite_passed=true`。

6. Blocker recovery / bugfix + 验证闭环
   - 初版 handoff wrapper 在复用外部 packet 时没有给 external log 补 route marker，导致 handoff packet guard RED。
   - 修复为对外部 packet log 注入 wrapper-local `route_classification` marker，并让 handoff / regression suite 支持外部 packet env var 复用，避免递归重跑 heavy mesh。
   - 复验 handoff packet 与 regression suite 均 GREEN。

这些增量不是同一类型：本轮覆盖 owner、native/script RED/GREEN、source/build evidence、handoff packet、orchestration suite、bugfix recovery 六类，因此没有停在 3 个同构 shell wrapper 上。

## Housekeeping

以下内容不计入真实工程增量：

- 本 report 本身。
- README / tracker / plans README / DESIGN_INTENT_INDEX / runtime README 的 latest-entry 最小同步。
- automation memory 更新。
- 本轮未新增 compact manifest、topic manifest reconciliation 或完整 decision / closure / manifest 包；当前没有 truth / authority 扩张、public surface、protected path、GPU / renderer state 等硬边界变化。

## 验证结果

- `zsh -n`：所有新增 scripts 通过。
- Owner probe：通过。
- Two-pass mesh rerun contract：通过，当前 shell 两次均分类为 `automation_smoke_metal_unavailable` / exit 20，`failure_domain=automation_environment`。
- Source/build guard：通过，包含 `cjpm build --skip-script`。
- Direct runtime build：通过，使用 `/tmp` `ps` shim 后执行 `cjpm build --target-dir /tmp/cjgui-stage91-direct-build --skip-script`；构建仍有既有 warning，但无新增失败。
- Handoff packet：RED 后修复并 GREEN。
- Focused regression suite：通过。
- `git diff --check`：通过。
- Protected path scan：未修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- Public declaration scan：新 owner 未新增 `public` / `foreign` declaration。
- Forbidden scan：未发现 non-comment / non-guard `NSApplication.sharedApplication` actual accessor、visible order、`nextDrawable`、render encoder、draw、commit、present、GPU submission 或 renderer state write。
- GitNexus `detect_changes --repo cangjie-live-codelattice --scope all`：LOW / affected_count 0；图谱只覆盖 tracked docs diff，不覆盖本轮 untracked new files，因此仍以上述 source/build/probe/scans 作为兜底证据。

## Environment Blocker

本轮遇到的是 environment blocker，不是 code failure：fresh mesh 两次都报告 `automation_smoke_metal_unavailable` / exit 20、`failure_domain=automation_environment`、`code_failure_domain=false`。

该 blocker 没有作为终点处理；本轮继续推进 non-Metal / non-D3 路线，落地 rerun contract、source/build guard、handoff packet 与 regression suite，没有消耗 human-approved D3 execution。

## Stop-line

当前 stop-line 保持：

- `runtime_native_probe_execution=false`
- `human_approved_d3_execution_consumed=false`
- `application_singleton_accessor_call=false`
- `native_bridge_expansion=false`
- `protected_path_modified=false`
- `production_public_c_abi_added=false`
- `renderer_state_write=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`
- no `nextDrawable`
- no render encoder / draw / commit / present / GPU submission

## 当前 next route

下一条可推进路线：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness explicit human-approved D3 runtime native probe execution in a Metal-capable shell, or continue non-D3 explicit approval rerun contract / source-build guard / handoff packet / regression suite replay without consuming D3 approval`。

若要进入 D3 runtime native probe execution，必须由人明确批准，并在 Metal-capable shell 中执行；否则仍只能继续 non-D3 evidence / replay / guard 路线。
