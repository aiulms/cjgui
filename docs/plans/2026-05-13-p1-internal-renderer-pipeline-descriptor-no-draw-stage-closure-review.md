# Pipeline descriptor no-draw 阶段收口复核

日期：2026-05-13

状态：已完成 B/C/D first slice

## 实际路线

本阶段完成 token-backed `MTLRenderPipelineDescriptor` create/destroy、no-draw configuration 与 runtime-adjacent FFI call owner。Native bridge 新增 descriptor C ABI，只返回 `int32_t` status 或通过 `uint64_t*` 输出 opaque token；runtime owner 只脱水 internal facts。

## 产物

- Native C ABI：`cjgui_native_bridge_pipeline_descriptor_create`、`destroy`、`token_classify`、`double_destroy_classify`、`configure_no_draw`、`color_pixel_format_classify`、`sample_count_classify` 与 still-blocked classification callables。
- Runtime owner：[runtime_renderer_pipeline_descriptor_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_planning.cj)、[runtime_renderer_pipeline_descriptor_create_destroy.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_create_destroy.cj)、[runtime_renderer_pipeline_descriptor_configuration.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_configuration.cj)、[runtime_renderer_pipeline_descriptor_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_pipeline_descriptor_runtime_call.cj)。
- Native probes：[verify_native_bridge_pipeline_descriptor_create_destroy.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_descriptor_create_destroy.sh)、[verify_native_bridge_pipeline_descriptor_configuration.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_descriptor_configuration.sh)、[verify_native_bridge_pipeline_descriptor_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_pipeline_descriptor_runtime_call.sh)。

## 证据

- `cjpm build --target-dir /tmp/cjgui-renderer-pipeline-descriptor-no-draw-target --skip-script` 已通过。
- Pipeline descriptor create/destroy probe 已通过，覆盖 main-thread create/destroy、opaque token、valid/stale/double-destroy、cleanup count 与 no pipeline state / shader / encoder / draw / submit。
- Pipeline descriptor configuration probe 已通过，覆盖 color pixel format、sample count、still-blocked facts 与 cleanup count；其中 `rasterSampleCount` 在创建后默认就是 `1`，probe 记录该事实但仍要求配置后 classification 为 `223`。
- Pipeline descriptor runtime call probe 已通过，临时仓颉包完成 create → configure → classify → destroy → double destroy，且 token 只在函数局部存在。

## 未授予的权限

本阶段不授予 `MTLRenderPipelineState` creation、shader library / function creation、render command encoder creation、encoder binding、`setRenderPipelineState`、draw、vertex buffer、`commit`、`present`、GPU submission、render execution、backend-ready truth、renderer state write 或 public API permission。

## GitNexus 记录

GitNexus impact 对上游 endpoint / default draft 和新增 symbols 均返回 not found / impactedCount `0` / risk `UNKNOWN`。本阶段按近期新增 owner 未索引处理，并用源码、build、probe、scan、manifest 兜底。

## 设计意图出口自检

- 本轮改变主题状态：是，从 pipeline state no-draw planning 推进到 pipeline descriptor no-draw runtime call。
- 本轮改变 canonical tail / endpoint：是，canonical tail 变为 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness`。
- 本轮改变 owner / truth / stop-line：是，新增 descriptor owners 和 native C ABI；stop-line 继续禁止 pipeline state / shader / encoder / draw / submit。
- 本轮改变唯一 next opening：是，指向 `P1 internal Renderer shader library no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
