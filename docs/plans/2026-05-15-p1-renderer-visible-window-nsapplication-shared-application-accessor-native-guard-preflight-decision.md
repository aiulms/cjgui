# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 预检决策

## 决策结论

本阶段选择 A 路线：允许下一刀进入 internal-only `NSApplication` shared-application accessor native guard implementation bundle，但不新增 production native bridge C ABI。

当前 production bridge 已有 `cjgui_native_bridge_nsapplication_shared_application_guard_*` no-side-effect integer facts，可证明 application singleton accessor 仍 blocked、singleton creation 仍 blocked、main-thread gate / bounded run loop / auto-close / teardown before visible / non-user-visible 仍 required，且 activation policy、activation、event loop、visible order、drawable 与 render 仍 blocked。下一刀只允许新建 runtime internal owner 复用这些既有 C ABI，并把证据重新锚定到 accessor scope value boundary 之后。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft()`

## 下一刀允许的实现面

- 新增 internal runtime owner，默认文件为 `runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj`。
- 该 owner 只能消费 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`。
- 该 owner 可以声明 `foreign func` 指向既有 `cjgui_native_bridge_nsapplication_shared_application_guard_*` callables，但不得新增 native header / source symbol。
- 该 owner 只能脱水 accessor native guard facts：accessor guard call still blocked、accessor scope still blocked、singleton creation still blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、activation policy / activation / event loop still blocked、native visible order still blocked、production drawable still blocked、render still blocked 与 no backend-ready truth。
- 可新增 owner probe，验证 runtime owner、upstream input、既有 C ABI 引用与停止线。
- 可复跑既有 native guard probe `verify_native_bridge_nsapplication_shared_application_guard.sh` 作为 C ABI evidence。

## 严格禁止

下一刀不得调用 application singleton accessor、`setActivationPolicy`、`activateIgnoringOtherApps`、`run`、`makeKeyAndOrderFront`、`orderFront`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得修改 activation policy，不得运行 AppKit event loop，不得做 native visible order implementation，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，不得写 renderer state，不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`，不得新增 native bridge C ABI。

## GitNexus 结果

GitNexus 对 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`、`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeDraft()`、`cjgui_native_bridge_nsapplication_shared_application_guard_accessor_blocked` 与 `CjguiNativeBridgeNsWindowHarnessLifecycleClassification` 返回 not found / UNKNOWN / impactedCount 0。该结果只说明近期 Renderer/native symbols 未被索引覆盖，不能作为安全证明；本阶段必须以源码读取、build、probe、forbidden scan、protected path scan 与 manifest reachability 兜底。

## 下一边界

若 implementation、owner probe、既有 native probe、build 与 scans 全部通过，下一 opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary decision`

该 next opening 仍不是 application singleton accessor、application creation / activation、visible order、drawable acquisition、GPU submission、render、renderer state write、backend-ready truth、public API 或 public C ABI permission。
