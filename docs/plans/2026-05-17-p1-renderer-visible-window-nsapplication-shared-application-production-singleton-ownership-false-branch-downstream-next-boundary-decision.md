# P1 Renderer visible-window NSApplication shared-application production singleton ownership false-branch downstream next-boundary decision

状态：next-boundary / source witness truth recovery preflight

## 结论

下一入口选择：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness truth recovery preflight / internal readiness owner decision`

原因：false-branch downstream owner 已确认 production singleton ownership truth 仍为 false，且阻断原因不是 value boundary 缺失，而是 source readiness truth / external witness truth evidence gap 仍未关闭。下一步应回到 external preexisting singleton source witness truth recovery，而不是继续新增 ownership false-branch receipt、record、publication 或 application-ready wrapper。

## 下一入口允许做什么

- 只做 internal-only / docs-backed source witness truth recovery preflight 或 readiness owner。
- 保持 production singleton ownership truth false。
- 保持 production implementation 与 production actual accessor call site blocked。
- 明确 external preexisting singleton witness truth 仍缺哪些 admission facts。
- 继续保留 headless fail-closed、main-thread confinement、cleanup ownership 与 artifact non-publication guard。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump，不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。
