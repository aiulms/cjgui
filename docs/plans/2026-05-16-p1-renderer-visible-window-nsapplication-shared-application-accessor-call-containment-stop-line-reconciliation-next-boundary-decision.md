# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Stop-Line Reconciliation 后续边界决策

状态：next-boundary decision / docs-only branch gate

## 当前阶段出口

Accessor call containment stop-line reconciliation 已完成 docs-only 封账。当前 canonical endpoint 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`

Runtime input 保持：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment branch closure / next accessor call decision`

## 下一段只允许判断的问题

- 当前 no-call containment branch 是否已经足够作为阶段封账。
- 是否继续保持 accessor call blocked，并把后续转向其他 visible-window harness prerequisite。
- 是否需要一份更高层 docs-only branch closure 来拒绝 actual accessor call implementation，或明确它需要人类产品/风险判断。
- 是否存在新的非同构 evidence gap，例如 cleanup co-ownership、headless safety、CI artifact policy、main-thread ownership 或 teardown proof，而不是继续包装 blocked facts。

## 不自动继承的权限

- 本阶段不授权 application singleton accessor call。
- 本阶段不授权 `NSApplication` creation / activation side effect。
- 本阶段不授权 activation policy mutation。
- 本阶段不授权 AppKit event loop。
- 本阶段不授权 native visible order implementation。
- 本阶段不授权 production drawable acquisition。
- 本阶段不授权 color attachment、command buffer、encoder、draw、GPU submission 或 render。
- 本阶段不授权 renderer state write、public API、public C ABI、public diagnostics 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 branch-level next decision，不是 accessor call implementation。
- 已保留 upstream / downstream 指向：上游为 containment policy endpoint；downstream 为 future branch closure / next accessor call decision。
- Same-shape Boundary Brake：下一段仍必须证明不是 no-call wrapper、application-ready wrapper、visible-ready wrapper、drawable-ready wrapper、render-ready wrapper 或 backend-ready wrapper。
