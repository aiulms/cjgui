# P1 Internal Renderer NSApplication Shared-Application External Preexisting Singleton Source Witness Admission Policy Preflight Closure Review

状态：closure / value-only owner closed

## 本轮关闭内容

本轮完成 external preexisting singleton source witness admission policy preflight：

- 新增 internal-only owner [runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight.cj)。
- 新增 owner probe [verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_admission_policy_preflight_owner.sh)。
- 当前 owner 只消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessContractShapeReadiness`。
- 当前阶段没有修改 production native bridge、`runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## Closure 结论

admission policy preflight 可以封账为 value-only owner。它只表达 admission 前置条件，不表达 witness truth，也不表达 production singleton ownership truth。

保留的关键结论：

- external owner identity 必须先于 admission；
- preexisting singleton observation 必须先于 admission；
- main-thread observation proof 必须先于 admission；
- source lifetime proof 与 external cleanup ownership 必须先于 admission；
- admission 期间不得由 Renderer 调用 application singleton accessor；
- admission 期间不得由 Renderer 创建 application singleton；
- admission 期间不得执行 cleanup / teardown；
- admission result 必须保持 dehydrated value facts；
- headless / CI-like 环境仍 fail-closed。

## Stop-line 检查

保持。未新增 production singleton owner、production actual accessor call site、native C ABI、activation、activation policy mutation、AppKit event loop、bounded pump、cleanup / teardown execution、window / view / layer creation、visible order、drawable、render、artifact publication、public API、production C ABI、renderer state write 或 backend-ready truth。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload schema preflight decision`
