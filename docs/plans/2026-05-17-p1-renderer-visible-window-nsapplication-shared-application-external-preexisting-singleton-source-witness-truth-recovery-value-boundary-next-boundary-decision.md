# P1 Renderer visible-window NSApplication shared-application source witness truth recovery value boundary next-boundary decision

状态：next-boundary / source witness truth recovery false branch

## 结论

下一入口选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth recovery false-branch downstream / next readiness owner decision`

原因：本阶段只把 recovery preflight 汇入 value boundary，并继续保持 external source witness truth、source readiness truth 与 production singleton ownership truth 为 false。下一步只能分类该 false branch，把它路由回 external owner witness packet / source readiness evidence gap；不能进入 production singleton owner implementation，也不能新增 actual accessor production call site。

## 下一入口允许做什么

- 只做 internal-only source witness truth recovery false-branch downstream owner。
- 只消费本阶段 value-boundary readiness。
- 继续保持 external preexisting singleton source witness truth false。
- 继续保持 source readiness truth、production singleton ownership truth、production implementation 与 production actual accessor call site blocked。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。
