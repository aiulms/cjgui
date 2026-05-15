# P1 Renderer 可见窗口 NSApplication Shared-Application Native Guard 预检决策

## 决策结论

本阶段选择 A 路线：允许下一刀进入 internal-only、no-side-effect `NSApplication` shared-application native guard implementation bundle。

该 implementation 只能新增 deterministic integer guard facts，用来确认 application singleton accessor 仍 blocked、application singleton creation 仍 blocked、main-thread affinity required、bounded run loop required、auto-close required、headless fail-closed、teardown before visible mode required、non-user-visible mode required、activation policy mutation still blocked、activation still blocked、event loop still blocked、visible order still blocked、drawable still blocked 与 render still blocked。它不是 application singleton accessor permission，也不是 `NSApplication` creation / activation permission、visible-window ready、drawable ready、render ready 或 backend-ready truth。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()`

## 下一刀允许的实现面

- 可新增 runtime internal owner，建议文件为 `runtime_renderer_visible_window_nsapplication_shared_application_native_guard.cj`。
- 可新增 production native bridge internal C ABI，命名必须保持 `cjgui_native_bridge_nsapplication_shared_application_guard_*`，只返回 `int32_t` dehydrated facts。
- 可新增 native probe 与 runtime owner probe，验证 guard facts、符号存在与停止线。
- 可更新 existing native bridge probe allowlist，使新增 guard callable 不被旧 no-resource / package-link probes 误报。
- 可新增 implementation stage closure、next-boundary decision、manifest 与 manifest stabilization closure。

## 严格禁止

下一刀不得调用 application singleton accessor、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得做 native visible order implementation，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，不得写 renderer state，不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 结果

GitNexus 对 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`、`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()` 与既有 `cjgui_native_bridge_nsapplication_guard_ownership_required` 返回 not found / UNKNOWN。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段必须以源码读取、build、probe、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 下一边界

若 implementation、probes、build 与 scans 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application guard policy value boundary decision`

该 next opening 仍不是 application singleton accessor、application creation / activation、visible order、drawable acquisition、GPU submission、render、renderer state write、backend-ready truth 或 public API permission。
