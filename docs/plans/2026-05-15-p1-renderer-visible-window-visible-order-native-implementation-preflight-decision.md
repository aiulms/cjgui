# P1 Renderer 可见窗口 Visible Order Native Implementation 预检决策

## 决策结论

本阶段选择 A/B 路线：不直接实现 native visible order，但允许打开一个更窄的 no-side-effect native guard first slice。

该 first slice 只能在 production native bridge 中新增整数 guard callable，并在 runtime internal owner 中脱水为 facts。它只证明 native bridge 侧可以显式表达 `NSApplication` ownership required、application creation deferred、activation deferred、bounded run loop required、auto-close required、headless / CI-like fail-closed、content-view prerequisite 与 visible order still blocked。

## 上游

- `CjguiInternalRendererVisibleWindowVisibleOrderPolicyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowVisibleOrderPolicyDraft()`

## 允许的实现面

- 新增 runtime internal owner：`runtime_renderer_visible_window_visible_order_native_guard.cj`。
- 新增 no-side-effect production native C ABI guard callable。
- 新增 native guard probe，验证所有 callable 只返回 deterministic integer facts。
- 更新 native bridge isolated compile / symbol allowlist / package-adjacent probes，使新增 callable 被纳入 no-side-effect surface。

## 停止线

不允许调用 `makeKeyAndOrderFront`、`orderFront`、`activateIgnoringOtherApps`、production `nextDrawable`、`renderCommandEncoder`、`drawPrimitives`、`commit`、`presentDrawable` 或任何真实 render execution。不得创建 `NSApplication`，不得 activation，不得运行 AppKit event loop，不得返回 pointer / handle / `id` / `Class`，不得新增 public declaration，仍不得修改 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## GitNexus 预检

GitNexus 对当前 visible-order policy endpoint、planned native guard endpoint 与 draft 均返回 target not found / UNKNOWN。该结果只说明近期新增符号未被图谱覆盖，不作为安全证明；本阶段必须用源码读取、probe、build、forbidden scan 与 manifest check 兜底。

## 下一边界

若本预检完成同步，下一 opening 转为：

`P1 internal Renderer visible-window production harness visible-order native guard no-side-effect implementation`
