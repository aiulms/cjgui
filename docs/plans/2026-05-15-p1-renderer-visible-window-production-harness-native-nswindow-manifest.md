# P1 Renderer 可见窗口生产 Harness 原生 NSWindow Manifest

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness native NSWindow harness scope unlock decision` 到 bounded first slice implementation。阶段完成后，runtime 内部新增 token-backed `NSWindow` harness readiness，production native bridge 新增窄 C ABI，并通过 native / build / scan 兜底验证。

## 新增或更新的 owner

- Native bridge：`cjgui_native_bridge_nswindow_harness_*`
- Runtime owner：`CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsWindowHarnessDraft()`
- Probe：`verify_native_bridge_nswindow_harness_create_destroy.sh`

## 新增 native C ABI

- `cjgui_native_bridge_nswindow_harness_table_capacity`
- `cjgui_native_bridge_nswindow_harness_table_enabled`
- `cjgui_native_bridge_nswindow_harness_table_occupied_count`
- `cjgui_native_bridge_nswindow_harness_create`
- `cjgui_native_bridge_nswindow_harness_destroy`
- `cjgui_native_bridge_nswindow_harness_token_classify`
- `cjgui_native_bridge_nswindow_harness_double_destroy_classify`
- `cjgui_native_bridge_nswindow_harness_create_requires_main_thread`
- `cjgui_native_bridge_nswindow_harness_destroy_requires_main_thread`
- `cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked`
- `cjgui_native_bridge_nswindow_harness_command_buffer_still_blocked`
- `cjgui_native_bridge_nswindow_harness_render_encoder_still_blocked`
- `cjgui_native_bridge_nswindow_harness_present_still_blocked`

## 事实边界

只承认固定容量 table、opaque token、main-thread create / destroy、classify、stale token、double-destroy fail-closed 与 blocked facts。`NSWindow` token 不是 pointer，不返回 `NSWindow *`、`id` 或 `Class`。

## 停止线

不调用 production `nextDrawable`；不 visible order；不创建 `NSApplication`；不创建 command buffer / encoder；不 present / commit / draw / render；不提交 GPU work；不写 renderer state；不扩 public API；不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 上游 / 下游

- Upstream：`CjguiInternalRendererNoVisibleWindowProductionHarnessReadiness`
- Current：`CjguiInternalRendererVisibleWindowNsWindowHarnessReadiness`
- Downstream next opening：`P1 internal Renderer visible-window production harness NSWindow content-view attachment preflight decision`

## 设计意图出口自检

- manifest 已同步当前 owner、truth、stop-line、canonical tail 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
