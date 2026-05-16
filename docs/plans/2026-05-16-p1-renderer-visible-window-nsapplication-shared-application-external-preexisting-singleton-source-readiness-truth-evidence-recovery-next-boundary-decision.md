# P1 Renderer 可见窗口 NSApplication Shared-Application source readiness truth evidence recovery 下一边界决策

状态：next-boundary / witness packet preflight only

## Decision

下一段不得进入 source readiness truth owner、production singleton owner implementation 或 production actual accessor call site。由于现有 evidence 无法恢复 truth，下一段只能打开 external owner witness packet recovery preflight。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness packet recovery preflight decision`

## Allowed Scope

下一段最多允许：

- 定义 external owner witness packet 的字段集合；
- 定义 preexisting singleton observation、main-thread observation、source lifetime 与 cleanup ownership 的 preflight requirements；
- 定义 Renderer non-creation / non-accessor invariant；
- 定义 dehydrated-only packet 形状；
- 定义 missing / ambiguous / wrong-thread / Renderer-created / throwaway source fail-closed classification；
- 继续保持 witness truth、source readiness truth 与 production singleton ownership truth 为 false。

## Forbidden Scope

下一段仍禁止：

- source readiness truth upgrade；
- source readiness truth runtime owner；
- production singleton owner implementation；
- production actual accessor call site；
- native C ABI；
- actual `NSApplication` ownership；
- `NSApplication.sharedApplication` call；
- `setActivationPolicy` / `activateIgnoringOtherApps` / `run` / `stop` / `terminate`；
- `NSWindow` / `NSView` / `CAMetalLayer` creation；
- visible order；
- `nextDrawable`；
- command queue / command buffer / encoder；
- render / commit / present / GPU submission；
- artifact write / diagnostics publication；
- pointer / handle / `id` / `Class` return；
- public API / public C ABI；
- `runtime_state.cj` / `runtime/cjgui/cjpm.toml` change。
