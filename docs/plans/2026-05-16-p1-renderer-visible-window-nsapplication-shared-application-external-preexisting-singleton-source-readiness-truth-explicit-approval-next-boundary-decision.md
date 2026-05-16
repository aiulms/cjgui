# P1 Renderer 可见窗口 NSApplication Shared-Application source readiness truth explicit approval 下一边界决策

状态：next-boundary / blocker recovery only

## Decision

下一段不得进入 production singleton owner implementation，也不得新增 source readiness truth owner。由于本轮 evidence 不足，下一段只能打开 recovery decision，用来定义缺失 evidence 的补齐路径。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth evidence recovery decision`

## Recovery Scope

下一段最多允许：

- 列出 source readiness truth 缺失 evidence；
- 明确 external owner-provided preexisting singleton witness 的输入契约；
- 明确 source lifetime / cleanup ownership / main-thread observation 的 truth 前置条件；
- 继续拒绝 throwaway singleton 与 Renderer-created singleton；
- 继续保持 source readiness truth false；
- 继续保持 production singleton ownership truth false。

## 禁止项

下一段仍禁止：

- production singleton owner implementation；
- actual `NSApplication` ownership；
- `NSApplication.sharedApplication` call；
- `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；
- `NSWindow` / `NSView` / `CAMetalLayer` creation；
- visible order；
- `nextDrawable`；
- command queue / command buffer / encoder；
- render / commit / present / GPU submission；
- artifact write / diagnostics publication；
- public API / public C ABI；
- `runtime_state.cj` / `runtime/cjgui/cjpm.toml` change。
