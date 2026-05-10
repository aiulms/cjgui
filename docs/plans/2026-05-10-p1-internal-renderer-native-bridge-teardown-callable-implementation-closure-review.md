# P1 内部渲染器 native bridge teardown callable implementation 复核

日期：2026-05-10

状态：implementation closure / no-resource callable

## 实现结论

本轮按 preflight 选择 no-resource teardown admission callable first implementation，并完成极窄实现。新增 callable 只返回 status / classification facts，不执行真实 destroy，不调用 retain / release，不创建或绑定 native object，不返回 pointer / handle，不扩 public API。

## 实际写集

- `runtime/cjgui/native/cjgui_native_bridge.h`
- `runtime/cjgui/native/cjgui_native_bridge.m`
- `runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- 相关 native probe allowlist / runtime-adjacent probe script
- README、tracker、plans README、runtime README、设计意图索引、topic manifests
- 本阶段 preflight / closure / next-boundary / manifest 文档

## 新增 callable

- `cjgui_native_bridge_teardown_admission(uint64_t token)`：valid token 返回 revoke-before-destroy-required；invalid / dangling token fail-closed。
- `cjgui_native_bridge_destroy_not_supported(void)`：返回 destroy-not-supported classification。
- `cjgui_native_bridge_revoke_before_destroy_required(void)`：返回 revoke-before-destroy-required classification。
- `cjgui_native_bridge_double_destroy_classify(uint64_t token)`：stale token 返回 double-destroy denied；invalid / dangling token fail-closed。

这些 callable 都是 no-resource C ABI，只消费现有 opaque token classification，不绑定 token 到 native object，不执行 destroy。

## Runtime owner

- Owner：`runtime/cjgui/src/runtime_renderer_native_bridge_teardown_admission_call.cj`
- Runtime input：`CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`
- Endpoint：`CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`
- Truth：destroy-not-supported、revoke-before-destroy-required、invalid / dangling token fail-closed、double-destroy denial 与 no-actual-destroy internal facts。

该 owner 只在 internal-only 范围调用 no-resource teardown admission C ABI 并脱水 facts，不写 renderer state，不创建 public surface。

## 验证记录

阶段实现后已通过：

- `runtime/cjgui/native/scripts/verify_native_bridge_teardown_admission.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_skeleton_compile.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_symbols.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_token_issue_revoke.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_cjpm_package_link_probe.sh`
- `runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh`
- `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-teardown-admission-call-target --skip-script`

最终矩阵仍需在 manifest closure 前统一复核 smoke、diff、whitespace、link target、public declaration scan、protected path 与 GitNexus detect。

## 停止线复核

- no actual destroy。
- no retain / release。
- no native object。
- no token-to-resource binding。
- no raw pointer / native pointer / native handle。
- no public API / diagnostics。
- no Cocoa / Metal / QuartzCore import。
- no AppKit / Metal object。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no smoke native edits。
- no backend-ready truth。

## GitNexus 记录

编辑 runtime owner 前已对 `CjguiInternalRendererNoPlatformObjectNativeCallableReadiness`、`cjguiInternalExecuteDefaultRendererPlatformObjectNativeCallableDraft` 与 `cjgui_native_bridge_surface_capabilities` 运行 upstream impact。GitNexus 返回 not found / UNKNOWN，`impactedCount=0`，未出现 HIGH / CRITICAL；本轮以源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable implementation 从 planning boundary 进入 no-resource admission callable implementation。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeTeardownAdmissionCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownAdmissionCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_admission_call.cj`；truth 固定为 no-resource teardown admission classification facts；stop-line 继续禁止 actual destroy / retain / release / native object / public API。
- 本轮是否改变唯一 next opening：是，closure 后进入 manifest stabilization。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
