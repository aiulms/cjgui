# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment 分支清单稳定化复核

状态：manifest stabilization closure / docs-only / no runtime truth

## 稳定化结果

分支清单已固定 current branch sealed 结论：containment policy readiness 足够作为 no-call branch endpoint，actual application singleton accessor call 继续 blocked，不再新增同构 no-call wrapper。

## 已固定内容

- Current endpoint：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- 下游：`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety preflight decision`

## 停止线复核

没有打开 application singleton accessor call、`NSApplication` creation / activation、activation policy mutation、event loop、native visible order、production drawable、color attachment、encoder、draw、GPU submission、render、renderer state write、public API、public C ABI、public diagnostics 或 backend-ready truth。

## 出口自检

- 清单与 closure 指向同一 current endpoint。
- 下游不是 accessor call implementation。
- 后续若新增 runtime owner，必须以 cleanup / headless safety value facts 为边界，并运行 code/native 验证链。
