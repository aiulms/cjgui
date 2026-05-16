# P1 Renderer visible-window NSApplication shared-application source readiness truth value boundary next-boundary decision

状态：next-boundary / production singleton ownership value boundary only

## 结论

下一入口选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership value boundary / internal readiness owner decision`

原因：本阶段已经把 source readiness truth value boundary 固定成 internal readiness owner，但 truth 仍为 conditional / false。下一段只能把这个 false / conditional source readiness 与 preauthorization facts 投影到 production singleton ownership value boundary，继续表达 ownership truth blocked、implementation blocked 与 production actual accessor call site blocked。

## 下一入口允许做什么

- 新增 internal-only readiness owner。
- 只消费本阶段 source readiness truth value boundary readiness 与 preauthorized first-slice readiness。
- 固定 production singleton ownership value boundary、ownership truth still false、implementation blocked、actual accessor call site blocked、cleanup / teardown ownership仍不由 Renderer 执行。
- 继续保持 source readiness truth 不升级为 true。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。

## 导航要求

完成下一入口后需要同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)、[GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、[docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)、[runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)、[DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 与相关 topic manifests。
