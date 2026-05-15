# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Native Guard 预检清单稳定化闭环审查

## 结论

Accessor native guard preflight manifest 已稳定化。当前允许的下一步是 implementation owner，且 implementation 不得新增 native bridge C ABI。

## 已固定内容

- 上游：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorScopeReadiness`
- 既有 native evidence：`cjgui_native_bridge_nsapplication_shared_application_guard_*`
- 当前 truth：accessor call / accessor scope / singleton creation 仍 blocked，main-thread gate / bounded run loop / auto-close / teardown / non-user-visible 仍 required，activation policy / activation / event loop / visible order / drawable / render 仍 blocked。
- 当前 stop-line：不调用 accessor，不创建 `NSApplication`，不 activation，不 event loop，不 visible order，不 drawable，不 render，不写 renderer state，不扩 public API / public C ABI。

## 下一 opening

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor native guard implementation`

## 设计意图同步要求

Implementation 完成后必须同步 README、tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与相关 topic manifest，并把唯一 next opening 更新为 accessor guard policy value boundary decision，除非 build/probe/smoke/scans 发现 blocker。
