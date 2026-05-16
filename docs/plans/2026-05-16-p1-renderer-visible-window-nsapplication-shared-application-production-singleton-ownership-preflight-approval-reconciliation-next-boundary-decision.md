# P1 Renderer 可见窗口 NSApplication Shared-Application Production Singleton Ownership Preflight Approval Reconciliation 下一边界决策

状态：next-boundary decision / human approval required

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`

## 下一段只允许判断的问题

- 是否明确批准打开 production singleton ownership preflight。
- 若批准，production singleton ownership source 是什么。
- ownership 生命周期由谁负责，如何 teardown，如何 fail-closed。
- 是否存在 external production application harness，避免把 throwaway singleton 升级为 runtime truth。
- 如何继续保持 no activation、no activation policy mutation、no AppKit event loop、no
  bounded pump、no visible order、no drawable、no render、no publication stop-line。

## 当前不能自动做的事

- 不能把 `classification=241` 当作 production singleton ownership proof。
- 不能将 isolated throwaway singleton 写入 runtime state、public API、production C ABI、
  artifact 或 diagnostics publication。
- 不能新增 production actual accessor call site。
- 不能创建、持有、激活或 teardown production `NSApplication`。

## 进入条件

下一阶段若要进入 production singleton ownership preflight，必须重新获得人工批准，并明确：

- ownership source；
- lifecycle / teardown owner；
- headless / CI fail-closed route；
- no activation / no activation policy mutation / no AppKit event loop / no bounded
  pump / no visible order / no drawable / no render；
- no artifact publication / no public diagnostics；
- no public API / no production public C ABI；
- no `runtime_state.cj` write / no `cjpm.toml` change。

## Same-shape Boundary Brake

当前 next boundary 不是 application-ready、backend-ready、renderer state write、
publication、receipt、record、diagnostics、visible-ready、drawable-ready 或 render-ready wrapper。
