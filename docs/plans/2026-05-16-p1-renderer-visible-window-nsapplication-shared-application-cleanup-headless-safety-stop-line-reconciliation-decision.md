# P1 Renderer 可见窗口 NSApplication Shared-Application Cleanup / Headless Safety 停止线复核决策

状态：decision / docs-only / no runtime truth

## 背景

上一阶段已新增 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`，并把 cleanup co-ownership、headless fail-closed、CI artifact policy evidence-only、main-thread ownership proof、teardown proof before visible 与 non-user-visible mode 固定为 internal value facts。

本决策只复核这些 facts 是否足够作为当前 non-call evidence endpoint 封账，不把它们升级为 application singleton accessor call、`NSApplication` creation、activation、event loop、visible order、drawable、render 或 backend-ready truth。

## 决策

选择 A/C：

1. 接受 cleanup / headless safety endpoint 作为当前 non-call evidence endpoint。
2. 继续保持 actual `sharedApplication` accessor call blocked。
3. 不再新增同构 cleanup / headless / non-user-visible wrapper。
4. 下一口转向 lifecycle / run-loop / teardown evidence gap classification，而不是 actual accessor call implementation。

## 理由

当前 endpoint 已经表达了生产可见窗口路径在调用 shared application 前必须满足的最低安全条件：cleanup 共同所有权、headless fail-closed、CI artifact 仅作 evidence、主线程所有权证明、visible 前 teardown proof 与非用户可见模式约束。

这些条件能封住“不能把前序 no-call policy 误读成 ready”的缺口，但还不能证明真实 AppKit lifecycle、bounded run loop、teardown order、artifact capture 与失败分类已经具备 production 运行证据。因此下一阶段应先分类这些 evidence gap，而不是越过 stop-line。

## 明确不授权

- 不调用 `sharedApplication`。
- 不创建 `NSApplication`。
- 不 activation。
- 不修改 activation policy。
- 不运行 AppKit event loop。
- 不调用 `makeKeyAndOrderFront` / `orderFront`。
- 不调用 production `nextDrawable`。
- 不配置 color attachment。
- 不创建 encoder。
- 不 draw。
- 不 `commit` / `present`。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不新增 public API / public C ABI / public diagnostics。
- 不修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## 下一步

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification decision`
