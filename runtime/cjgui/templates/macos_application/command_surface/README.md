# command-surface starter

可选模板。只在需要命令工具栏、上下文菜单或只读命令诊断时使用；默认 `ui-only` 仍是
最小的本地 controller 骨架，不携带命令或 Inspector 代码。

```sh
zsh "$CJGUI_ROOT/scripts/create_macos_application.sh" command-surface /tmp/MyCommandApp
cd /tmp/MyCommandApp
./run.sh
```

创建、构建、运行和分发仍走 `create_macos_application.sh` 与
`run_macos_application.sh`，没有额外工具链。

## 公共用法

每个命令指向自己的 owner 控件。工具栏、快捷键和原生菜单激活后把命令解析到目标，
执行的是目标控件声明的动作；因此两条命令不能共用一个笼统目标，否则动作无法区分。

```cangjie
let commands = ArrayList<CjguiComposableUiCommand>([
    CjguiComposableUiCommand("app.add", CjguiComposableUiNodeReference.manual(22),
        "计数 +1", CjguiComposableUiShortcut("n"), "Edit", 0, true, false),
    CjguiComposableUiCommand("app.reset", CjguiComposableUiNodeReference.manual(23),
        "清零", CjguiComposableUiShortcut("r"), "Edit", 1, count != 0, false)
])
let metadata = ArrayList<CjguiCommandToolbarMetadata>([
    CjguiCommandToolbarMetadata("app.add", "APP_ADD", 0, detail: "增加计数"),
    CjguiCommandToolbarMetadata("app.reset", "APP_RESET", 0, detail: "把计数归零",
        disabledReason: "计数已经为 0")
])
let presentation = CjguiCommandPresentation(commands, metadata)
```

- 工具栏：`cjguiComposableCommandToolbar(scope, semantic, presentation.placement(), style: CjguiCommandToolbarStyle.themed(theme))`
- 原生/快捷键：窗口把命令解析到上面声明的目标，目标动作进入 controller
- 上下文菜单：`menu.open(window, request, presentation, owner, source: CjguiContextMenuCommandSource.RequestLocal, style: ...)`
- 面板条目：`presentation.paletteItems()`，交给既有的 `CjguiSearchableSelectionPanel`
- 提示文字：`presentation.contextMenuProjection(request)`（由菜单内部使用，应用不需要再拼一份）

触发按钮只携带命令 id。应用把它交给 `window.invokeCommand`（工具栏激活前缀经
`cjguiCommandToolbarCommandId` 解析）或由菜单调用 `invokeContextMenuCommand`；
声明、目标解析、禁用与撤销检查仍在窗口和原业务 owner 中完成。

`WindowCommand` 行必须仍是窗口的活命令，目标与声明一致；`RequestLocal` 行只属于
当前请求，适合右键目标上的临时动作，窗口仍核对 accepted 目标和选择票据。上下文
菜单把命令 id 放在 `event.text`，同一声明可以落到同一个 owner 控件；普通窗口命令
分发到目标时文本为空，按目标动作执行。

`checked`、`enabled` 与快捷键都从声明读取，`metadata` 只补展示用的动作名、详情和
禁用原因。打开菜单期间切换主题调用 `menu.restyle(...)`，不重建请求、查询或滚动位置。

## Inspector

模板把 `CjguiMacosInspector` 挂在同一个 `CjguiMacosApplication` 上。`starter.inspector`
命令只设置一个待打开标记，主循环在 `pumpOneTurn` 之后调用 `inspector.open()`：框架不
从命令处理器里重入第二个窗口。Inspector 的命令页是只读的，读取
`diagnosticCommandSnapshot`，不会试执行命令，也不会复制业务正文。

## 实验性边界

`CjguiCommandPresentation`、命令工具栏、上下文命令菜单和 Inspector 命令页仍属本阶段
的实验性公共接口，只验证 macOS 自绘路径；不包含子菜单、图标库、平台矩阵、IME 或
可视化编辑器能力。默认 `ui-only` 模板不受影响。
