# P1 Renderer visible-window NSApplication shared-application source witness truth recovery preflight next-boundary decision

状态：next-boundary / source witness truth recovery value boundary

## 结论

下一入口选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth recovery value boundary / internal readiness owner decision`

原因：本阶段只打开 recovery preflight，并把 recovery 所需的 external owner witness、accepted witness packet、preexisting singleton observation、main-thread observation、source lifetime、cleanup ownership、renderer non-creation / non-accessor invariant 与 headless fail-closed facts 固定成 prerequisites。下一步只能把这些 preflight facts 汇入 value boundary，继续保持 witness truth false，而不是进入 production singleton owner implementation。

## 下一入口允许做什么

- 只做 internal-only source witness truth recovery value boundary。
- 只消费本阶段 recovery preflight readiness。
- 继续保持 external preexisting singleton source witness truth false。
- 继续保持 source readiness truth、production singleton ownership truth、production implementation 与 production actual accessor call site blocked。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。
