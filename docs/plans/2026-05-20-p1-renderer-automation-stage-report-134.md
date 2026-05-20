# P1 Renderer Automation Stage Report 134

Run time: 2026-05-20T00:23:46+0800

本轮接续 [stage report 133](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-19-p1-renderer-automation-stage-report-133.md)，完成 `first-frame bounded reprobe classification -> AppKit visible-order smoke first slice -> packet / suite integration and Metal-readiness reprobe` 连续阶段包。本轮不写 [runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)，不扩 [cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge、public API 或 public C ABI，不请求 drawable，不执行 encoder / draw / commit / present，不把 isolated probe evidence 升级为 production truth。

## 连续工程闭环

1. Bounded first-frame / Metal capability reprobe classification：先重新执行 stage133 bounded first-frame packet，确认当前 shell 的 `bounded_first_frame_observation_first_slice_executed=false`、`first_frame_observation_first_slice_failure_classification=host_metal_device_unavailable`、`renderer_state_write=false`；再执行 native bridge Metal device / layer binding reprobe，确认 `metal_default_device_available=-111`、`metal_device_binding_probe=skipped_no_device`。该闭环把当前第一帧失败原因收窄到宿主 default Metal device 不可用，而不是新的 CJGUI harness 缺口。
2. AppKit visible-order smoke first slice：新增 owner [runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice.cj)、owner probe、bounded AppKit visible-order smoke probe 与 packet。probe 在不依赖 Metal 的情况下实际观测 `NSApplication sharedApplication -> NSWindow -> NSView -> contentView -> makeKeyAndOrderFront -> bounded run loop -> visible -> orderOut/close cleanup`。
3. Packet / suite integration and bugfix：新增 focused suite [verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice_suite.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_visible_order_smoke_first_slice_suite.sh)，串联 stage133 token-gate suite、visible-order smoke probe、Metal binding reprobe、runtime build 与 public/protected/forbidden scans。TDD GREEN 前修复了 packet 对 nested `TMPDIR` 目录未创建导致 `mktemp` 失败的问题，并把 `visible_order_to_metal_next_gap=metal_device_unavailable` 固定到 result envelope。

## 能力推进

当前 canonical endpoint 已推进到：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationRuntimeNativeProbeD3BoundedResultEnvelopeVisibleOrderSmokeFirstSliceDraft()`。

Stage133 已把 first-frame positive facts 绑定到 production-truth token gate 与 renderer-state write token gate。Stage134 没有继续重复证明 token denial，而是向真实窗口链路前移一段：在当前无 Metal device 的宿主中，先独立证明 `NSApplication / NSWindow / NSView / visible order / cleanup` 可由 bounded native smoke 观测，并把下一段缺口明确落到 Metal device / drawable readiness，而不是 AppKit visible-window harness。

## Runtime Probe / 环境分类

本轮执行了两类 bounded runtime native probe：

- bounded first-frame packet：当前 shell 未进入 first-frame observation，失败分类为 `host_metal_device_unavailable`，`renderer_state_write=false`。
- bounded AppKit visible-order smoke probe：`visible_order_smoke_observed=true`、`visible_order_auto_close_cleanup_observed=true`、`nsapplication_shared_application_observed=true`、`nswindow_created=true`、`nsview_created=true`、`nsview_content_view_attached=true`，不要求 Metal device。

当前分类结论：AppKit visible-window harness 这一段没有新缺口；第一帧链路的当前宿主限制是 default Metal device 不可用，Metal binding reprobe 固定为 `metal_device_binding_probe=skipped_no_device`。本轮没有把宿主限制写成新的 recovery / handoff 文档，而是转向不依赖 Metal 的相邻真实工程闭环。

## 验证结果

- TDD RED 1：先新增 stage134 focused suite 并执行，失败于缺少 visible-order smoke owner / packet / probe。
- TDD RED 2：补齐 packet 后 suite 失败，root cause 是 packet 给 probe 设置 `TMPDIR="$TMP_DIR/visible-order-probe"` 但未创建目录，导致 `mktemp` 失败。
- Stage134 focused suite：`stage134_visible_order_smoke_first_slice_suite_passed=true`。
- Suite packet：`bounded_visible_order_smoke_probe_executed=true`、`visible_order_smoke_route_classification=visible_order_smoke_observed`、`visible_order_smoke_observed=true`、`visible_order_auto_close_cleanup_observed=true`、`nsapplication_window_view_chain_observed=true`、`metal_device_required=false`、`metal_device_binding_reprobe_executed=true`、`metal_default_device_available=-111`、`metal_device_binding_probe=skipped_no_device`、`visible_order_to_metal_next_gap=metal_device_unavailable`、`drawable_requested=false`、`first_frame_observed=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- Runtime package build：由 stage134 focused suite 执行 `cjpm build --skip-script`，通过。
- Stage134 shell scripts `zsh -n`：通过。
- `git diff --check`：通过。
- Public / foreign declaration scan：通过，新增 owner 未新增 public surface。
- Forbidden native/render/capture token scan：通过，新增 owner 未含 native AppKit / Metal execution token。
- Protected path scan：通过，[runtime_state.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_state.cj)、[cjpm.toml](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/cjpm.toml)、native bridge header / impl 未被修改。
- `runtime_state.cj` 行数：10065，未变化。

## GitNexus / CodeLattice

GitNexus Tool CLI 使用 `cangjie-live-codelattice`：

- 对 pre-edit suspect visible-order symbols 与新增 stage134 endpoint / default draft 的 impact 查询返回 target not found、ambiguous 或 risk `UNKNOWN`，未作为安全证明。
- `detect-changes --repo cangjie-live-codelattice --scope all` 只覆盖已跟踪 README/docs 的 changed symbols，affected processes 为 `0`，risk 为 `low`；当前 GitNexus 图没有覆盖本轮未跟踪新增 owner / scripts，未作为新增 runtime owner 的完整安全证明。

CodeLattice sidecar 对新增 default draft 给出 caller count `0`、risk `LOW`，但 struct readiness 命中同名 Struct / Init 候选而存在歧义。最终安全判断依赖源码复核、focused suite、runtime build、probe result envelope、public/protected/forbidden scans 与 `git diff --check`。

## 第一帧链路剩余缺口

第一条真实渲染链路现在能表达并验证到：

`NSApplication -> NSWindow -> NSView -> contentView attachment -> visible-order bounded run loop -> auto-close cleanup`。

仍未完成：

- 当前 shell 没有可用 default Metal device，`MTLDevice` / layer device binding 不能正向观测。
- `CAMetalLayer -> drawable -> command queue -> command buffer -> render pass -> encoder -> pipeline -> vertex buffer -> draw -> commit / present` 仍未在本轮推进为正向事实。
- `first_frame_observed=false`、`positive_live_probe_observed=false`、`nonzero_frame_hash_observed=false`。
- `result_envelope_promoted_to_production_truth=false`、`production_render_truth=false`、`backend_ready_truth=false`。
- `renderer_state_write_admission_ready=false`、`renderer_state_write=false`、`runtime_state_write=false`。
- 未扩 public C ABI / native bridge / stable public API。

## Next Route

当前 canonical endpoint 是 visible-order smoke first slice。下一条最值得推进的工程目标：

`P1 Renderer visible-window NSApplication shared-application runtime native-readiness drawable readiness reprobe after visible-order smoke first slice: consume stage134 visible-order smoke suite packet, keep AppKit visible-order / cleanup facts isolated, then on a Metal-capable host re-run Metal device + CAMetalLayer device binding + drawable readiness as the next bounded native slice; if current host remains no-device, continue with command-queue / render-pass / result-envelope contract code that does not require runtime Metal execution. Keep first-frame truth, production truth, renderer_state_write, runtime_state_write, native bridge expansion and public C ABI blocked until focused positive evidence exists.`

本轮完成三个相邻工程闭环，不适用“只完成 1 个闭环”的停止说明。
