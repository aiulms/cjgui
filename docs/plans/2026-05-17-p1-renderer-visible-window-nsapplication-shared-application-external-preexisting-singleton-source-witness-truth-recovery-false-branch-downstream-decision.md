# P1 Renderer visible-window NSApplication shared-application source witness truth recovery false-branch downstream decision

状态：decision / internal-only false-branch downstream owner selected

## 决策

本轮选择 A：在当前用户预授权范围内，推进 `external preexisting singleton source witness truth recovery false-branch downstream` 的 internal-only readiness owner。

该阶段只消费上一段 `source witness truth recovery value boundary` readiness，把 value boundary 中仍为 false 的 external source witness truth 分类为 downstream false branch，并把后续路线回退到 external owner witness packet / source readiness evidence gap。它不恢复 source witness truth，不恢复 source readiness truth，也不授权 production singleton ownership implementation 或 production actual accessor call site。

## 原因

- stage 62 已确认 source witness truth recovery value boundary 仍保持 external source witness truth false、source readiness truth false 与 production singleton ownership truth false。
- 当前缺口不是缺少同构 wrapper，而是缺少可被 production runtime 接受的 external owner witness packet / source readiness evidence。
- 在证据缺口关闭前，继续前进到 production singleton owner implementation 或 actual accessor production call site 会跨越 stop-line。

## 写集

- 新增 internal owner：[runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_false_branch_downstream.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_false_branch_downstream.cj)
- 新增 owner probe：[verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_false_branch_downstream_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_external_preexisting_singleton_source_witness_truth_recovery_false_branch_downstream_owner.sh)

## Truth boundary

- `source_witness_truth_recovery_value_boundary_readiness_preserved=true`
- `source_witness_truth_recovery_false_branch_classified=true`
- `external_owner_witness_packet_evidence_gap=true`
- `source_readiness_evidence_gap=true`
- `external_preexisting_singleton_source_witness_truth=false`
- `source_readiness_truth_value=false`
- `production_singleton_ownership_truth=false`
- `production_singleton_implementation=false`
- `production_actual_accessor_call_site=false`
- `runtime_state_write=false`
- `cjpm_toml_change=false`

## Stop-line

本阶段不调用 application singleton accessor，不创建或激活 `NSApplication`，不修改 activation policy，不运行 AppKit event loop / bounded pump，不执行 cleanup / teardown，不创建 window / view / layer，不 visible order，不取 drawable，不 render，不写 renderer state，不扩 public API 或 production C ABI。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth recovery evidence-gap terminal boundary / downstream branch decision`
