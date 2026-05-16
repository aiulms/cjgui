# P1 Renderer 可见窗口 NSApplication Shared-Application witness packet truth admission preflight closure review

状态：closure / value-only owner / no-call branch

## Closure

本阶段已完成 external preexisting singleton source witness packet truth admission preflight。新增 runtime internal owner 与 owner probe，owner 只消费 witness packet acceptance gate preflight readiness，并把 accepted dehydrated packet、acceptance gate prerequisite、carry-forward facts 与 fail-closed classification 固定为 packet truth admission preflight。

Owner：

[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight.cj)

Owner probe：

[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_packet_truth_admission_preflight_owner.sh)

## Accepted Facts

- acceptance gate before packet truth admission is required；
- accepted packet readiness / version / external owner identity / preexisting singleton observation / main-thread observation are carried forward；
- accepted source lifetime / cleanup ownership / Renderer non-creation / Renderer non-accessor invariants are carried forward；
- accepted packet remains dehydrated；
- truth admission remains pre-truth；
- acceptance missing / blocked / invariant mismatch / headless cases fail closed；
- source readiness truth recovery remains deferred；
- pointer / handle / `id` / `Class` / native object / diagnostics / artifact payload remains forbidden。

## Canonical 状态

当前 canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketTruthAdmissionPreflightDraft()`

当前 runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPacketAcceptanceGatePreflightReadiness`

## Stop-line

Stop-line 保持：不升级 source readiness truth；不升级 witness truth；不实现 production singleton owner；不新增 production actual accessor call site；不新增 native C ABI；不调用 `NSApplication.sharedApplication`；不创建或激活 `NSApplication`；不修改 activation policy；不运行 AppKit event loop / bounded pump；不执行 cleanup / teardown；不创建 window / view / layer；不 visible order；不 `nextDrawable`；不创建 command queue / command buffer / encoder；不 render / commit / present / GPU submission；不写 artifact；不发布 diagnostics；不返回 pointer / handle / `id` / `Class`；不新增 public API / public C ABI；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## Closure Decision

本阶段可以封账。它明确选择继续 no-call audit branch；下一步只能进入 actual accessor side-effect audit branch closure / next actual accessor call decision。该 next opening 仍不是 actual call implementation。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`
