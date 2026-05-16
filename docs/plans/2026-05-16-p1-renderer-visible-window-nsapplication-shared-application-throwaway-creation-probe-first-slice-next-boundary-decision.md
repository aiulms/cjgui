# P1 Renderer 可见窗口 NSApplication Shared-Application Throwaway Creation Probe First Slice 下一边界决策

状态：next-boundary decision / production ownership requires new approval

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership preflight approval decision`

## 下一段只允许判断的问题

- 是否允许从 throwaway creation evidence 进入 production singleton ownership
  preflight。
- 若允许，production singleton owner 是谁，生命周期谁负责，何时 teardown，如何
  fail-closed。
- 是否存在比 throwaway creation 更合适的 external production application harness。

## 当前不能自动做的事

- 不能把 `classification=241` 当作 production ownership truth。
- 不能把 throwaway singleton 暴露给 runtime state、public API、production public
  C ABI、artifact 或 diagnostics publication。
- 不能进入 activation、activation policy mutation、AppKit event loop、bounded pump、
  visible order、drawable、render 或 GPU submission。

## 进入条件

下一阶段若要进入 production singleton ownership preflight，必须重新获得人工批准，
并明确：

- ownership source；
- lifecycle / teardown owner；
- headless / CI fail-closed route；
- no activation / no event loop / no visible order / no drawable / no render stop-line；
- no public API / no production public C ABI / no runtime_state.cj write / no
  `cjpm.toml` change。

## Same-shape Boundary Brake

当前 next boundary 不是 application-ready、accessor-ready、visible-ready、
drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
或 publication wrapper。
