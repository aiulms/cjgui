# P1 Renderer visible-window NSApplication shared-application production singleton ownership value boundary next-boundary decision

状态：next-boundary / false-branch downstream decision

## 结论

下一入口选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application production singleton ownership false-branch downstream decision / next readiness owner decision`

原因：production singleton ownership value boundary 已打开，但 source readiness truth 与 external witness truth 仍为 false，不能进入 production singleton owner implementation、actual accessor production call site、cleanup execution 或 AppKit lifecycle control。下一段只允许做 downstream branch decision，明确 false ownership branch 是否继续留在 value-only runway，或回到 source readiness evidence 缺口。

## 下一入口允许做什么

- 只做 internal-only / docs-backed branch decision 或 readiness owner。
- 保持 production singleton ownership truth false。
- 保持 production implementation 与 production actual accessor call site blocked。
- 记录下一步应补 source readiness evidence、external witness truth，还是继续 manifest stabilization。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。
