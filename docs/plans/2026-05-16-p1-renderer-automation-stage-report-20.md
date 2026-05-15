# P1 Renderer 自动化阶段报告 20

状态：automation stage report / Renderer mainline / no runtime truth

## 本轮完成的阶段包

1. `NSApplication` shared-application accessor call native side-effect containment preflight package：
   - Decision：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-native-side-effect-containment-preflight-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-native-side-effect-containment-preflight-decision.md)
   - 结论：允许进入 internal-only no-call native containment implementation；只新增 deterministic fact C ABI，不允许 actual `sharedApplication` call、`NSApplication` creation / activation、activation policy mutation、event loop、visible order、drawable、render、renderer state write、backend-ready truth 或 public API。

2. `NSApplication` shared-application accessor call containment implementation package：
   - Runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment.cj)
   - Native bridge：[cjgui_native_bridge.h](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.h) / [cjgui_native_bridge.m](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/cjgui_native_bridge.m)
   - Native probe：[verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh)
   - Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh)
   - Closure：[2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-stage-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-stage-closure-review.md)
   - Next-boundary：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-next-boundary-decision.md)

3. Containment implementation manifest stabilization package：
   - Manifest：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-manifest.md)
   - Manifest closure：[2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-implementation-manifest-stabilization-closure-review.md)

4. `NSApplication` shared-application accessor call containment policy value boundary package：
   - Decision：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-decision.md)
   - Runtime owner：[runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy.cj)
   - Owner probe：[verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh)
   - Closure：[2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-stage-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-stage-closure-review.md)
   - Next-boundary：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-next-boundary-decision.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-next-boundary-decision.md)

5. Containment policy manifest stabilization package：
   - Manifest：[2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md)
   - Manifest closure：[2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest-stabilization-closure-review.md)
   - Navigation sync：已同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)、[GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、[docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)、[runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)、[DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)、[renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)、[renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md) 与 [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)。

## 当前 canonical endpoint / default draft / runtime input

- Endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment stop-line reconciliation decision`

下一轮只允许做 docs-only stop-line reconciliation decision，消费 containment policy endpoint 并判断 no-call containment policy facts 是否足够作为后续 stage input。不得新增 runtime owner、native C ABI、`foreign func`、probe、public API、diagnostics、renderer state write、actual application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible-order implementation、production `nextDrawable`、color attachment、encoder、draw、`commit` / `present`、GPU submission、render 或 backend-ready truth。

## 边界保持说明

- 未 stage / commit / push。
- 未修改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 未触碰 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，行数保持 10065。
- Public declaration allowlist 仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- 本轮新增 native C ABI 只返回 deterministic containment fact integers；不返回 pointer / handle / `id` / `Class`，不调用 actual `sharedApplication` accessor，不创建或激活 `NSApplication`，不启动 event loop。
- Containment policy owner 是 value-only owner，不含 `foreign func`，不新增 native C ABI，不新增 public surface。
- 本轮 truth 仍是 no-call containment policy facts：actual application singleton accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate / bounded run loop / auto-close / teardown-before-visible / non-user-visible required、application side effect / activation / event-loop / visible-order / drawable / render still blocked、no public surface、no renderer state write 与 no backend-ready truth。

## 验证命令与结果

- Red probe：`runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh` 在 implementation 前失败，原因为 containment C ABI 尚不存在。
- Red probe：`runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh` 在 implementation 前失败，原因为 owner 尚不存在。
- Red probe：`runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh` 在 implementation 前失败，原因为 policy owner 尚不存在。
- `runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_accessor_call_containment.sh`：通过；16 个 containment fact C ABI 均返回预期 deterministic code，`success=true reason=none`。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_owner.sh`：通过。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_containment_policy_owner.sh`：通过。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh`：通过。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_guard_policy_owner.sh`：通过。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh`：通过。
- `runtime/cjgui/native/scripts/verify_native_bridge_nsapplication_shared_application_guard.sh`：通过，`success=true reason=none`。
- `runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_guard_policy_owner.sh`：通过。
- `cd runtime/cjgui && source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && cjpm build --target-dir /tmp/cjgui-accessor-call-containment-policy-final-build-verify --skip-script`：通过；仍打印既有 230 个 warnings。
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`：通过；直接运行先因 Clang module cache 写入用户缓存目录受 sandbox 限制失败，改用 `CLANG_MODULE_CACHE_PATH=/tmp/cjgui-clang-module-cache-package` 后通过。
- `source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh && labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：已运行；当前自动化环境返回 `default Metal device is unavailable`，exit code 20。根据 [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)，report-6 已由用户在 Metal-capable local shell 复核解除，后续自动化环境单独复现该错误应记录为 smoke environment unavailable，不作为代码回归或 Renderer blocker。
- `git diff --check`：通过。
- Touched Markdown / Cangjie / Objective-C / header / shell whitespace 与 final newline scan：通过。
- Markdown absolute link target scan：通过。
- New plan reachability scan：通过；本轮新增 plans 文件均可从 README / tracker / plans README / runtime README / design index / topic manifest 入口抵达。
- 中文标题/正文抽查：通过。
- Public declaration scan：未新增 public declaration；allowlist 仍仅 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native/build forbidden scan：owner / native header / native source 无 actual `sharedApplication` call、activation、visible-order、drawable、encoder、draw、present、`commit]` 或 renderer state write；probe 脚本自身保留 forbidden-token guard regex，属于自检逻辑。
- Protected path scan：`runtime/cjgui/cjpm.toml` 与 `runtime/cjgui/src/runtime_state.cj` 无 diff。
- `wc -l runtime/cjgui/src/runtime_state.cj`：10065。

## GitNexus 结果

- `impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `context CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness --repo cangjie-live-codelattice`：Symbol not found。
- `impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentDraft --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- `impact CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyFacts --repo cangjie-live-codelattice`：target not found / impactedCount 0 / risk UNKNOWN。
- 结论：GitNexus 对近期新增 Renderer symbols 未索引，未把 UNKNOWN / 0 impacted 当成安全证明；安全性由源码读取、red/green probes、build、package link probe、smoke classification、forbidden scan、protected path scan、manifest / reachability scan 兜底。
- Final `detect-changes --repo cangjie-live-codelattice --scope unstaged`：返回 `Changes: 11 files, 3 symbols`、`Affected processes: 0`、`Risk level: low`。Changed symbols 被归到 README / design navigation 文档符号，未覆盖近期新增 Renderer owner / native containment symbols；继续按 GitNexus index gap 处理。

## 人工介入

是否需要人工介入：否

automation_blocker: false
