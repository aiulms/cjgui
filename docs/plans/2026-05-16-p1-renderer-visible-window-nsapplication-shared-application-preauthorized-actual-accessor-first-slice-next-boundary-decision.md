# P1 Renderer visible-window NSApplication shared-application 预授权 actual accessor first slice next-boundary decision

日期：2026-05-16

状态：next-boundary / source-readiness truth runway

## 结论

本阶段选择下一入口：

`P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source readiness truth value boundary / internal readiness owner decision`

原因：本轮已经把上一轮 explicit approval blocker 在预授权范围内消费掉，并把 isolated probe / throwaway creation evidence 重新固定为 value-only first-slice facts。下一步的真实缺口不是再次询问 first-slice permission，而是把 external preexisting singleton source readiness truth 的 value boundary 做成 internal owner，并继续要求 source owner、lifetime、main-thread confinement、cleanup ownership 与 headless fail-closed 证据保持可审计。

## 下一入口允许做什么

- 新增 internal-only readiness owner。
- 只消费本阶段 preauthorized first-slice readiness 与既有 source / witness packet evidence。
- 固定 source readiness truth value boundary、truth still conditional、cleanup responsibility before production implementation 与 fail-closed classification。
- 保持 production actual accessor call site、production singleton owner implementation 与 actual `NSApplication` lifecycle 操作 blocked。

## 下一入口仍然禁止什么

不得调用 `setActivationPolicy`、`activateIgnoringOtherApps`、`run` / `stop` / `terminate`，不得创建 production visible `NSWindow`，不得调用 `makeKeyAndOrderFront` / `orderFront`，不得启动 AppKit event loop / bounded pump， 不得调用 production `nextDrawable`，不得配置 production drawable texture color attachment，不得创建 render command encoder，不得 draw / commit / present，不得提交 GPU work，不得写 renderer state / `runtime_state.cj`，不得修改 `runtime/cjgui/cjpm.toml`，不得新增 public API 或 public / production C ABI。

## 导航要求

完成下一入口后需要同步 [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)、[GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、[docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)、[runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)、[DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 与相关 topic manifests。

