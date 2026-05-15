# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 阶段闭环审查

## 阶段结果

Accessor native guard implementation 已完成。新增 runtime internal owner [runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_visible_window_nsapplication_shared_application_accessor_native_guard.cj)，canonical endpoint 为 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardReadiness`，default draft 为 `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorNativeGuardDraft()`，runtime input 为 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`。

本阶段新增 owner probe [verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_renderer_visible_window_nsapplication_shared_application_accessor_native_guard_owner.sh)。Probe 红绿：owner 创建前以 `missing owner` 失败；owner 创建后通过。

## Truth

Owner 复用既有 `cjgui_native_bridge_nsapplication_shared_application_guard_*` no-side-effect C ABI，重新锚定 accessor scope 之后的 native guard facts：

- application singleton accessor call still blocked
- application singleton accessor scope still blocked
- application singleton creation still blocked
- main-thread gate / bounded run loop / auto-close required
- teardown before visible / non-user-visible required
- activation policy / activation / event loop still blocked
- native visible order / production drawable / render still blocked
- no pointer / handle / `id` / `Class` return
- no public API / public C ABI addition
- no renderer state write
- no backend-ready truth

## 停止线复核

本阶段没有修改 `runtime/cjgui/cjpm.toml`，没有触碰 `runtime_state.cj`，没有新增 native header / source symbol，没有调用 application singleton accessor，没有创建 `NSApplication`，没有 activation、activation policy mutation、event loop、visible order、drawable、encoder、draw、`commit` / `present`、GPU submission 或 render。

## 验证

- owner probe：通过。
- `cjpm build --target-dir /tmp/cjgui-accessor-native-guard-build --skip-script`：通过；仍有既有 unused warnings。
- GitNexus：当前新增 endpoint / draft 未被图谱索引，返回 not found / UNKNOWN；不作为安全证明。

## 下一步

进入 manifest stabilization，并把下一 opening 固定为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor guard policy value boundary decision`
