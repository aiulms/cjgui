# P1 internal Renderer visible-window NSApplication shared-application accessor call preflight stage closure review

## Closure 结论

Accessor call preflight value-boundary stage 已完成。新增 runtime owner [runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight.cj)，新增 owner probe [verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh)。

当前 canonical endpoint：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallPreflightDraft()`

Runtime input：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorGuardPolicyReadiness`

## 本阶段真实变化

- 新增 internal facts / admission / readiness owner。
- 新增 owner probe。
- owner 只消费 accessor guard policy readiness。
- owner 固定 future native accessor call guard required。
- owner 固定 actual application singleton accessor call still blocked。
- owner 固定 no application creation / activation / event loop / visible order / drawable / render / state write / backend-ready truth。

## 边界保持

- 未 stage / commit / push。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未新增 public API。
- 未新增 public C ABI。
- 未新增 native bridge C ABI。
- 未修改 production native `.h` / `.m`。
- 未调用 application singleton accessor。
- 未创建 `NSApplication`。
- 未 activation，未修改 activation policy，未运行 AppKit event loop。
- 未进入 native visible order、production drawable、color attachment、encoder、draw、`commit` / `present`、GPU submission、render 或 renderer state write。

## 验证摘要

- `verify_renderer_visible_window_nsapplication_shared_application_accessor_call_preflight_owner.sh`：通过。
- 相关回归 owner probes：accessor guard policy owner 与 accessor native guard owner 通过。
- `cjpm build --target-dir /tmp/cjgui-accessor-call-preflight-build --skip-script`：通过，仍有既有 unused warnings。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh`：通过，包含 Metal device、readback、first frame 与 auto-close assertions。

## 结论

本阶段可以封账。当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call native side-effect containment preflight decision`

下一轮仍不得直接实现 actual `sharedApplication` call。
