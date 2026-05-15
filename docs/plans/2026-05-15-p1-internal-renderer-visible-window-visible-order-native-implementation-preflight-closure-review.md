# P1 内部 Renderer 可见窗口 Visible Order Native Implementation 预检封账复核

## 完成内容

本阶段完成 visible-order native implementation preflight：

- 确认 visible-order policy facts 不能直接升级为 `makeKeyAndOrderFront` / `orderFront` permission。
- 确认下一刀只能打开 no-side-effect native guard first slice。
- 固定该 first slice 的实现面为 deterministic integer facts，不创建 application，不 activation，不 visible order，不获取 drawable。

## 未越过的停止线

- 未修改 runtime owner 或 native bridge。
- 未新增 C ABI / `foreign func`。
- 未创建 `NSApplication`，未 activation，未 order front。
- 未调用 production `nextDrawable`，未配置 color attachment，未创建 encoder，未 draw。
- 未提交 GPU work，未执行 render。
- 未写 renderer state，未修改 `runtime_state.cj`。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未新增 public API / public diagnostics。

## GitNexus 结果

GitNexus 对 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`、`cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`、`CjguiInternalRendererVisibleWindowVisibleOrderNativeGuardReadiness` 与 `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderNativeGuardDraft()` 均返回 not found / UNKNOWN。该结果已按近期新增符号未索引处理。

## 设计意图出口自检

- 当前 canonical endpoint 仍是 `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`。
- 下一 opening 是 native guard no-side-effect implementation，不是 native visible order implementation 直通。
- Same-shape Boundary Brake：下一段必须产生 native guard facts 与 runtime-local dehydration，不得包装成 visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication。
