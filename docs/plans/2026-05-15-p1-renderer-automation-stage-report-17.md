# P1 Renderer automation stage report 17

## 本轮完成的阶段包列表

1. `NSApplication` shared-application accessor native guard preflight bundle：新增 [preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-native-guard-preflight-decision.md)、closure、next-boundary、manifest 与 manifest stabilization closure；结论是只允许 internal no-side-effect accessor native guard owner，仍不得调用 application singleton accessor、创建 `NSApplication`、activation、修改 activation policy、运行 AppKit event loop、进入 native visible order、drawable、render、renderer state write 或 backend-ready truth。
2. `NSApplication` shared-application accessor native guard implementation bundle：新增 [runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj) 与 [verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh)，只消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness` 并复用既有 no-side-effect shared-application guard C ABI。
3. `NSApplication` shared-application accessor guard policy value boundary bundle：新增 [decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-visible-window-nsapplication-shared-application-accessor-guard-policy-value-boundary-decision.md)、closure、next-boundary、manifest 与 manifest stabilization closure；新增 [runtime_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy.cj) 与 [verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh)，固定 accessor call / accessor scope / singleton creation still-blocked 与 main-thread、bounded run loop、auto-close、teardown before visible、non-user-visible 等 required facts。
4. Navigation / manifest stabilization bundle：同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)、[GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、[docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)、[runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)、[DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)、[renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)、[renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md) 与 [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)。

## 当前 canonical endpoint / default draft / runtime input

- Canonical endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call stop-line reconciliation decision`

下一轮只允许做 accessor call stop-line reconciliation decision：判断是否能进入后续 accessor call preflight，以及如何继续保持 no-call、no-create、no-activation、no-event-loop、no-visible-order、no-drawable、no-render、no-state-write、no-backend-ready truth。不得直接调用 application singleton accessor。

## 边界保持说明

- 未 stage / commit / push。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 `runtime/cjgui/src/runtime_state.cj`；行数保持 10065。
- Public declaration allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 未新增 public API、public C ABI、diagnostics、renderer state write、native visible-order implementation、drawable / encoder / draw / commit / present / GPU submission 或 backend-ready truth。
- `NSApplication` shared-application accessor native guard 只复用既有 no-side-effect guard C ABI；accessor guard policy 仅作 internal value boundary。
- 不把 probe evidence、isolated evidence、planning facts、smoke facts 或 no-submit facts 误读为 backend-ready truth。

## 验证命令与结果

- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh` 前置执行；本 sandbox 下 `envsetup.sh` 的 `ps` 探测用 `/tmp/cjgui-ps-shim/ps` 返回 `zsh` 兜底。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh`：通过，确认 owner 存在、复用 existing shared-application guard C ABI、未调用 application singleton accessor、未创建 application、未 activation / event loop / visible-order / renderer state write / backend-ready truth。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh`：通过，确认 owner 存在、消费 accessor native guard readiness、未新增 public surface、未 renderer state write、未 backend-ready truth。
- 相关回归 probes 通过：`verify_native_bridge_nsapplication_shared_application_guard.sh`、`verify_renderer_visible_window_nsapplication_shared_application_accessor_scope_owner.sh`、`verify_renderer_visible_window_nsapplication_shared_application_guard_policy_owner.sh`、`verify_renderer_visible_window_nsapplication_shared_application_native_guard_owner.sh`、`verify_renderer_visible_window_nsapplication_shared_application_feasibility_owner.sh`、`verify_renderer_visible_window_nsapplication_creation_activation_scope_owner.sh`、`verify_renderer_visible_window_nsapplication_guard_policy_owner.sh`、`verify_renderer_visible_window_nsapplication_native_guard_owner.sh`、`verify_renderer_visible_window_application_activation_policy_owner.sh`、`verify_renderer_visible_window_visible_order_native_guard_owner.sh`。
- `cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui && cjpm build --target-dir /tmp/cjgui-accessor-guard-policy-final-build --skip-script`：通过；仍有既有 230 条 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：本 automation shell 返回 `default Metal device is unavailable` exit 20；按 report-6 后用户 Metal-capable shell 复核与当前 smoke manifest 分类为 automation smoke environment unavailable，不设 blocker。
- `git diff --check`：通过。
- Touched Markdown / `.cj` / `.sh` whitespace 与 final newline scan：通过。
- Markdown absolute link target check：report 写入前仅缺本 report 文件自身；report 写入后需复跑。
- README / tracker / plans README / runtime README / DESIGN_INTENT_INDEX / topic manifest reachability：通过。
- 中文标题 / 正文抽查：通过，新 owner 与 probes 均含中文维护注释，新增 stage docs 含中文边界正文。
- Public declaration scan：只发现允许项 `runtime/cjgui/src/runtime_queue_public_submit.cj:781 public func cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native/build forbidden scan：新增 owner probes 通过，确认无 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation、event loop、visible order call、drawable、render encoder、draw、commit / present、pointer / handle / `Class` / `id` return 或 new public C ABI。
- Protected path scan：`runtime/cjgui/cjpm.toml` 与 `runtime/cjgui/src/runtime_state.cj` 未改；`runtime_state.cj` 为 10065 行。

## GitNexus 结果

- Pre-edit impact / context：
  - `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorReadiness` 系列新符号、accessor native guard endpoint / draft、accessor guard policy endpoint / draft 与相关 native guard symbols 在 `cangjie-live-codelattice` 中均为 target not found / UNKNOWN / 0 impacted。
  - 该结果不作为安全证明；本轮已用源码读取、build、owner probes、native probe regression、smoke、forbidden scans、protected path scan 与 manifest checks 兜底。
- `node /Users/jiangxuanyang/Desktop/GitNexus-RC-Tool/gitnexus/dist/cli/index.js detect-changes --repo cangjie-live-codelattice --scope unstaged`：`Changes: 8 files, 3 symbols`，`Affected processes: 0`，`Risk level: low`。
- GitNexus unstaged detect 未覆盖 untracked new owners / probes / plans；按 index gap 记录，不把图谱低风险视为唯一安全证明。

## 人工介入

是否需要人工介入：否

automation_blocker: false
