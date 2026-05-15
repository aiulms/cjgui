# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment Stop-Line Reconciliation 决策

状态：docs-only decision / no-call containment endpoint / no runtime truth

## 决策结论

本阶段选择 A/C 路线：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness` 足够作为当前 no-call containment policy endpoint，也足够作为后续 branch-level next decision 的唯一 runtime input；但它不授权 actual application singleton accessor call，不授权 `NSApplication` creation / activation、activation policy mutation、event loop、native visible order、production drawable、render、renderer state write、backend-ready truth、public API 或 public C ABI。

本阶段是 decision-only stop-line reconciliation。它只回答“containment policy facts 是否已经足够封账当前 no-call endpoint”，不回答“是否可以实现 accessor call”。结论是可以封账当前 no-call endpoint，并把下一刀转向 branch-level next decision；不得继续新增同构 no-call wrapper，也不得跳过 branch closure 直接进入 actual `sharedApplication` call。

## 上游

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- [containment policy manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-policy-value-boundary-manifest.md)

## Reconciliation 判定

- containment policy facts 已经把 accessor-call discussion 与 accessor-call implementation 分离：actual call blocked、no singleton accessor call、singleton creation blocked。
- no-call containment endpoint 已经表达 main-thread gate、bounded run loop、auto-close、teardown-before-visible、non-user-visible、application side-effect blocked、activation / event-loop / visible-order / drawable / render blocked。
- 继续新增 value-only “no-call wrapper”会落入 Same-shape Boundary Brake：只是把 blocked facts 换名，不增加新的 owner / teardown / verification / lifecycle 语义。
- branch-level next decision 可以评估是否 stop here、是否保持 no-call branch、是否进入更窄的 docs-only harness decision，或是否需要人工产品/风险判断；但本 decision 本身不批准任何 runtime implementation。

## 不授权项

- 不调用 `sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation，不 mutation activation policy。
- 不运行 AppKit event loop。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不创建 color attachment、render command encoder、command buffer 或 draw call。
- 不 `commit` / `present`，不提交 GPU work，不执行 render。
- 不写 renderer state。
- 不新增 public API / public C ABI / public diagnostics。
- 不新增 runtime owner、native C ABI、`foreign func` 或 probe。
- 不修改 `runtime/cjgui/cjpm.toml` 或 `runtime/cjgui/src/runtime_state.cj`。

## GitNexus 结果

GitNexus 对当前 containment policy endpoint / default draft 返回 target not found / UNKNOWN / 0 impacted；`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段为 docs-only reconciliation，并以 source reading、manifest reachability、forbidden scan、protected path scan 与最终 `detect-changes` 兜底。

## 下一边界

若本 decision / closure / manifest 同步与 docs-only scans 通过，当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment branch closure / next accessor call decision`

该 next opening 仍是 docs-only branch decision，不是 `sharedApplication` call implementation，不是 application creation / activation、event loop、visible order、drawable、render、renderer state write、backend-ready truth 或 public API permission。
