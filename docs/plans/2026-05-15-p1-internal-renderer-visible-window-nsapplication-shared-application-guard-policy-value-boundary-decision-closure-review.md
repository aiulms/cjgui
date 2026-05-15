# P1 内部 Renderer 可见窗口 NSApplication Shared-Application Guard Policy Value Boundary 决策封账复核

## 完成内容

本阶段完成 `NSApplication` shared-application guard policy value boundary docs-only 决策：

- 当前 shared-application native guard endpoint 已确认足够作为下一层 policy value owner 的上游输入。
- 直接 application singleton accessor call、`NSApplication` creation、activation policy mutation、activation 或 event loop implementation 被明确推迟。
- 下一刀收窄为 internal policy value boundary，不新增 native C ABI，不调用 AppKit application API。

## 未越过的停止线

- 未新增 runtime implementation。
- 未修改 production native bridge。
- 未调用 application singleton accessor。
- 未创建 `NSApplication`。
- 未 activation，未运行 AppKit event loop。
- 未调用 visible order、production `nextDrawable`、encoder、draw、`commit` / `present`。
- 未提交 GPU work，未写 renderer state，未新增 public API。

## 设计意图出口自检

- policy value boundary decision 没有把 native guard integer facts 误读成 application-ready truth。
- 下一 opening 是 policy value boundary implementation，不是 native `sharedApplication` / `NSApplication` implementation。
- Same-shape Boundary Brake：没有新增 visible-ready、drawable-ready、backend-ready、render-ready、state-write、receipt、record 或 publication wrapper。
