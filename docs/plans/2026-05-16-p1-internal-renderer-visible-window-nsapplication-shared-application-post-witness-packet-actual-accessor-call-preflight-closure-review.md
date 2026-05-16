# P1 Renderer 可见窗口 NSApplication Shared-Application Post-Witness-Packet Actual-Call Preflight Closure 复核

状态：closure review / value-only owner / no actual accessor call

## Closure 范围

本 closure 复核 [post-witness-packet actual-call preflight decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-post-witness-packet-actual-accessor-call-preflight-decision.md) 是否只打开 actual-call preflight revalidation，并保持所有 actual accessor side effects blocked。

## 通过项

- 新增 runtime owner [runtime_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight.cj)。
- 新增 owner probe [verify_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_post_witness_packet_actual_accessor_call_preflight_owner.sh)。
- Owner 只消费 witness packet truth admission preflight readiness 与 actual accessor call preflight guard readiness。
- Owner 明确 `only_actual_call_preflight_opened=true`，但 `actual_accessor_call_implementation=false` 与 `production_actual_accessor_call_site=false`。
- Owner 保持 witness truth、source readiness truth、production singleton ownership truth、renderer state write 与 backend-ready truth false / blocked。

## 未改变项

- 未修改 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)。
- 未修改 [runtime/cjgui/cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)。
- 未修改 production native bridge header / source。
- 未新增 public declaration、public C ABI、`foreign func`、pointer / handle / `id` / `Class` return。
- 未调用 application singleton accessor，未创建或激活 `NSApplication`，未执行 cleanup / teardown、visible order、drawable、render、commit、present 或 GPU submission。

## Closure 结论

Post-witness-packet actual-call preflight revalidation 可以封账。下一步只能进入 actual accessor call first-slice explicit human approval decision；没有明确人工授权前，自动化不得进入 actual accessor call first slice。
