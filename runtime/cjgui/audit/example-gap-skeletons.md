# CJGUI 示例缺口骨架（包 B：5 个组件）

> 数据快照：HEAD `dc27dff`，`247` 条未提交改动，快照时间 `2026-10-21T07:40:16Z`。
> **本规格基于未提交改动的工作区，提交后数字会变。** 下文 `文件:行` 只对该快照有效。
> 本轮是纯静态规格：未运行构建、测试或应用；所有骨架**均未编译验证**。`examples/` 下没有新建或修改任何文件。
> 选型按任务写死的 5 项：`cjguiComposableSplitView`、`cjguiComposableSelectableListRow`、`cjguiComposableGrid`、`cjguiComposableDialogLayer`、`cjguiComposableContextCommandMenuLayer`；`CjguiComposableUiTreeListSource.buildRow` 不需要，`cjguiContextCommandMenuProjection` 只作为第 5 项的辅助调用出现。

## 0. 公共约定

- 入口用 `src/application_host.cj` 的真实公共面，不按平台分叉：
  - 创建宿主：`cjguiCreatePlatformApplicationHost(controller, configuration!)`，macOS 声明在 `src/application_host.cj:21-24`。
  - 宿主最小面：`start()` / `pumpOneTurn()` / `isOpen()` / `close()` 在 `src/application_host.cj:12-15`。
  - 窗口配置：`CjguiMacosApplicationWindowConfiguration(title, width, height, ...)` 在 `src/macos_application_host.cj:25-30`。
  - 循环形态与 `examples/settings_form_window_app/src/main.cj:1174-1175` 一致（`while (...isOpen()) { let _ = ...pumpOneTurn() }`），只是把那里的 `CjguiMacosApplication` 换成公共宿主接口 `src/application_host.cj:13-14`；settings 的 `openWindow` 与失败检查见同文件 `1149-1155`，本规格不复制它的 Inspector/外部连接部分。
  - 公共宿主的 `start()`（`src/application_host.cj:12`）就是打开配置里的窗口；返回 `false` 等价于 settings 里的 `!opened.didOpen`（`examples/settings_form_window_app/src/main.cj:1152-1155`）。
- 每个骨架只给 `src/main.cj`。真实示例还需要 `cjpm.toml`、`run.sh`、`cjgui_macos_app.sh`（见 `audit/example-template-anatomy.md`），本轮不创建。
- 每个 `cjgui*` 调用后都标注了签名来源；构造类型（`Cjgui...`）在需要时也标了来源。
- 节点 id 不能和组件派生 id 撞车：split 的手柄默认是 `nodeId + 2`（`src/composable_ui.cj:5506-5510`），grid 的行/单元格/分隔线由 `CjguiGridSpec` 派生（`src/composable_grid.cj:43-57`）。下面骨架已避开。

---

## 1. `cjguiComposableSplitView`

**未编译验证**

**为什么该补：** 它是“无测试且无消费者”组里唯一有 probe 真实调用形态的手写分割容器，补上才能给日常窗口一个可运行的分栏骨架，而不是只靠 `pointer_controls_consumer_probe.cj` 的几何断言。

**建议目录名：** `examples/split_view_window_app`

### 最小 `src/main.cj`

```cangjie
package cjgui_split_view_window_app

import cjgui.*

class SplitViewSkeletonController <: CjguiComposableUiController {
    private var revision: Int64 = 1

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark() // 签名: src/composable_ui.cj:1561
        let root = cjguiComposableLayerHost(1, "split-root", theme.page) // 签名: src/composable_ui.cj:6125
        let content = cjguiComposableVertical(2, "split-content",
            CjguiComposableUiStyle(padding: 16, gap: 12, growX: 1, growY: 1)) // 签名: src/composable_ui.cj:5429（样式构造: src/composable_ui.cj:1048）
        content.add(cjguiComposableText(3, "split-title", "分割视图示例", theme.heading)) // 签名: src/composable_ui.cj:5772

        let first = cjguiComposableVertical(31, "split-first",
            CjguiComposableUiStyle(padding: 12, gap: 8,
                background: CjguiComposableUiColor(0.12, 0.18, 0.30, 1.0))) // 签名: src/composable_ui.cj:5429
        first.add(cjguiComposableText(33, "split-first-text", "左栏：初始 180pt", theme.body)) // 签名: src/composable_ui.cj:5772
        let second = cjguiComposableVertical(34, "split-second",
            CjguiComposableUiStyle(padding: 12, gap: 8,
                background: CjguiComposableUiColor(0.08, 0.12, 0.22, 1.0))) // 签名: src/composable_ui.cj:5429
        second.add(cjguiComposableText(35, "split-second-text", "右栏：剩余宽度", theme.body)) // 签名: src/composable_ui.cj:5772

        content.add(cjguiComposableSplitView(30, "split-demo", first, second,
            CjguiComposableUiSplitAxis.HORIZONTAL, 180, 120, 160,
            CjguiComposableUiStyle(growX: 1, growY: 1), operationResourceId: 8000)) // 签名: src/composable_ui.cj:5497-5500；轴常量: src/composable_ui.cj:112
        root.add(content)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // TODO: 待确认 拖拽手柄后 firstSize 的归属与回写路径。
        // 公共 cjguiComposableSplitView 不持有 splitState；窗口只对带 splitState 的 divider
        // 应用拖拽/键盘尺寸（src/composable_ui_window.cj:12623-12632、18409-18424）。
        // probe 也只验证几何与语义投影，没有事件回写样例（probe/pointer_controls_consumer_probe.cj:30-52）。
        // 本骨架保持只读展示，不伪造 SET_SPLIT_SIZE 处理。
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = SplitViewSkeletonController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("示例：分割视图", 900u32, 560u32)) // 签名: src/application_host.cj:21-24；配置: src/macos_application_host.cj:25
    if (!host.start()) { host.close(); return 1 } // 签名: src/application_host.cj:12、:15
    while (host.isOpen()) { // 签名: src/application_host.cj:14
        let _ = host.pumpOneTurn() // 签名: src/application_host.cj:13
    }
    host.close() // 签名: src/application_host.cj:15
    return 0
}
```

### 验收标准

窗口打开后能看到左右两栏和中间一条 8pt 宽的分割手柄：左栏初始约 180pt、右栏占剩余宽度；把窗口横向缩小时，左栏不低于 120pt、右栏不低于 160pt（窗口本身更窄时由框架按轨道裁剪）。关闭窗口后进程以 0 退出。拖拽手柄是否改变宽度不在本骨架的验收范围（需要先确认尺寸归属，见代码里的 TODO）。

---

## 2. `cjguiComposableSelectableListRow`

**未编译验证**

**为什么该补：** 它是 11 项里唯一全仓零真实调用的一项，没有测试、probe 或示例可抄；不补一个最小可运行骨架，就没人能实际看到“通用可选行”的选中/焦点/资源绑定契约。

**建议目录名：** `examples/selectable_list_row_window_app`

### 最小 `src/main.cj`

```cangjie
package cjgui_selectable_list_row_window_app

import cjgui.*
import std.collection.*

class SelectableListRowSkeletonController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    private var selectedResourceId: Int64 = -1
    private let items = ArrayList<CjguiComposableUiVirtualListItem>([
        CjguiComposableUiVirtualListItem("alpha", 7101, "第一项：Alpha"),
        CjguiComposableUiVirtualListItem("beta", 7102, "第二项：Beta"),
        CjguiComposableUiVirtualListItem("gamma", 7103, "第三项：Gamma")
    ]) // 签名: src/composable_ui.cj:1655-1666

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark() // 签名: src/composable_ui.cj:1561
        let root = cjguiComposableLayerHost(1, "row-list-root", theme.page) // 签名: src/composable_ui.cj:6125
        let content = cjguiComposableVertical(2, "row-list-content",
            CjguiComposableUiStyle(padding: 16, gap: 8, growX: 1, growY: 1)) // 签名: src/composable_ui.cj:5429
        content.add(cjguiComposableText(3, "row-list-title", "可选行示例（点击选中）", theme.heading)) // 签名: src/composable_ui.cj:5772

        // normalStyle / selectedStyle：签名要求传入普通 CjguiComposableUiStyle（不是 bound style）。
        // 选中或焦点任一为真时组件内部统一选 selectedStyle（src/composable_ui.cj:6032-6036）。
        let normalStyle = CjguiComposableUiStyle(padding: 10, minHeight: 34,
            textColor: CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0)) // 签名: src/composable_ui.cj:1048
        let selectedStyle = CjguiComposableUiStyle(padding: 10, minHeight: 34,
            textColor: CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0),
            background: CjguiComposableUiColor(0.19, 0.27, 0.40, 1.0),
            border: CjguiComposableUiColor(0.55, 0.70, 0.92, 1.0)) // 签名: src/composable_ui.cj:1048、:265

        var index = 0
        while (index < items.size) {
            let item = items[index]
            // 逐参数依据：
            //   nodeId          = 10 + index，本骨架自用、互不重复；
            //   semanticId      = "selectable-row-<item.key>"，行内唯一；
            //   item            = 上面的公开三字段构造，resourceId 同时成为按钮 resourceId；
            //   actionName      = "SELECT_ITEM"，点击后由 ACTIVATE 事件的 node.actionName 识别；
            //   normalStyle     = 未选中外观；
            //   selectedStyle   = 选中/焦点外观；
            //   isSelected      = 以 item.resourceId 作为业务选择键比较；
            //   isFocused       = false（TODO: 待确认 来源，见本循环后的说明）；
            //   enabled         = 省略，用默认 true；
            //   operationActionName = 省略；组件在空串时回落到 actionName（src/composable_ui.cj:6037-6041）。
            content.add(cjguiComposableSelectableListRow(
                10 + index, "selectable-row-${item.key}", item, "SELECT_ITEM",
                normalStyle, selectedStyle,
                item.resourceId == selectedResourceId,
                false)) // 签名: src/composable_ui.cj:6020-6031
            index += 1
        }

        // TODO: 待确认 isFocused 的数据来源。本骨架没有保存窗口句柄，也不把“选中”冒充“焦点”；
        // 若要逐行显示框架焦点，需要在 bindWindow 后读取窗口焦点身份，并与 item/node 稳定身份比较，
        // 该查询入口本轮未核对，故先固定传 false。
        root.add(content)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE &&
            event.node.actionName == "SELECT_ITEM") { // 事件码: src/composable_ui_window.cj:59
            selectedResourceId = event.node.resourceId
            revision += 1
            return CjguiComposableUiDispatchResult(true) // 签名: src/composable_ui_window.cj:565-570
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = SelectableListRowSkeletonController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("示例：可选列表行", 640u32, 520u32)) // 签名: src/application_host.cj:21-24；配置: src/macos_application_host.cj:25
    if (!host.start()) { host.close(); return 1 } // 签名: src/application_host.cj:12、:15
    while (host.isOpen()) { // 签名: src/application_host.cj:14
        let _ = host.pumpOneTurn() // 签名: src/application_host.cj:13
    }
    host.close() // 签名: src/application_host.cj:15
    return 0
}
```

### 验收标准

窗口里出现三行列表（Alpha / Beta / Gamma），每行都能看到自己的标题。用鼠标点任意一行，该行背景和边框立即变成选中样式，其余行保持普通样式；再点另一行，选中样式随之移动，原行恢复普通样式。关闭窗口后进程以 0 退出。

---

## 3. `cjguiComposableGrid`

**未编译验证**

**为什么该补：** 表格是最常见的业务布局刚需，组件已有 5 处测试调用和完整的 `CjguiGridSpec` 构造可抄，但 `examples/` 至今没有消费者；补一个最小骨架能直接把“列宽由 spec 固定、短行补齐、表头规则线唯一”表现出来。

**建议目录名：** `examples/grid_table_window_app`

### 最小 `src/main.cj`

```cangjie
package cjgui_grid_table_window_app

import cjgui.*

class GridTableSkeletonController <: CjguiComposableUiController {
    public func uiSceneVersion(): Int64 {
        return 1
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark() // 签名: src/composable_ui.cj:1561
        let root = cjguiComposableLayerHost(1, "grid-root", theme.page) // 签名: src/composable_ui.cj:6125
        let content = cjguiComposableVertical(2, "grid-content",
            CjguiComposableUiStyle(padding: 16, gap: 12, growX: 1, growY: 1)) // 签名: src/composable_ui.cj:5429
        content.add(cjguiComposableText(3, "grid-title", "表格示例（列宽固定）", theme.heading)) // 签名: src/composable_ui.cj:5772

        // columns 与 rows 的形态直接取自可抄测试 src/composable_grid_test.cj:17-18。
        // 最后一行故意只给两格：组件会补一个空单元格，第三列仍占 120pt。
        let spec = CjguiGridSpec([80, 40, 120],
            [["名称", "数量", "说明"], ["苹果", "3", "水果"], ["香蕉", "12", "水果"], ["缺一格", "7"]]) // 签名: src/composable_grid.cj:33-41

        let gridStyle = CjguiComposableUiStyle() // 签名: src/composable_ui.cj:1048
        let cellStyle = CjguiComposableUiStyle(textColor: CjguiComposableUiColor(0.91, 0.95, 1.0, 1.0),
            fontSize: 13.0, minHeight: 30) // 签名: src/composable_ui.cj:1048
        let separatorStyle = CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.25, 0.38, 0.60, 1.0)) // 签名: src/composable_ui.cj:1048
        let ruleStyle = CjguiComposableUiStyle(
            background: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0)) // 签名: src/composable_ui.cj:1048

        content.add(cjguiComposableGrid(20, "gap-grid", spec,
            gridStyle, cellStyle, separatorStyle, ruleStyle)) // 签名: src/composable_grid.cj:77-81
        root.add(content)
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        let _ = event
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = GridTableSkeletonController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("示例：表格", 720u32, 520u32)) // 签名: src/application_host.cj:21-24；配置: src/macos_application_host.cj:25
    if (!host.start()) { host.close(); return 1 } // 签名: src/application_host.cj:12、:15
    while (host.isOpen()) { // 签名: src/application_host.cj:14
        let _ = host.pumpOneTurn() // 签名: src/application_host.cj:13
    }
    host.close() // 签名: src/application_host.cj:15
    return 0
}
```

### 验收标准

窗口里出现一张三列表格：表头是“名称 / 数量 / 说明”，列宽分别是 80 / 40 / 120pt，表头下面有一条 1pt 的规则线，单元格之间有 1pt 的分隔线，文字四周有 6pt 内边距。最后一行“缺一格 / 7”只有两格内容，但第三格的位置仍然保留 120pt，表格右边缘不会缩回去。横向拉伸窗口时列宽保持不变。关闭窗口后进程以 0 退出。

---

## 4. `cjguiComposableDialogLayer`

**未编译验证**

**为什么该补：** 弹窗是最常见的模态交互，组件已有测试、4 个 probe 和 `templates/application/ui_only` 的精确调用，但 `examples/` 只用了同族的 `WithReference` 版本；补一个精确函数的示例能把“遮罩 + 居中 + 初始焦点 + 控制器关闭”这条链路固定下来。

**建议目录名：** `examples/dialog_layer_window_app`

### 最小 `src/main.cj`

```cangjie
package cjgui_dialog_layer_window_app

import cjgui.*

class DialogLayerSkeletonController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    private var dialogOpen: Bool = false

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark() // 签名: src/composable_ui.cj:1561
        let root = cjguiComposableLayerHost(1, "dialog-root", theme.page) // 签名: src/composable_ui.cj:6125
        let content = cjguiComposableVertical(2, "dialog-content",
            CjguiComposableUiStyle(padding: 16, gap: 12, growX: 1, growY: 1)) // 签名: src/composable_ui.cj:5429
        content.add(cjguiComposableText(3, "dialog-title", "弹窗示例", theme.heading)) // 签名: src/composable_ui.cj:5772
        // ownerNodeId 必须等于下面打开按钮的 nodeId（11），ownerSemanticId 必须等于它的 semanticId。
        content.add(cjguiComposableButton(11, "open-dialog", "打开弹窗", "OPEN_DIALOG", 0,
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction)) // 签名: src/composable_ui.cj:5828-5833
        root.add(content)

        if (dialogOpen) {
            let dialog = cjguiComposableDialogLayer(20, "demo-dialog", "demo-dialog-layer",
                "open-dialog", 11,
                CjguiComposableUiStyle(fixedWidth: 420, fixedHeight: 220, padding: 16, gap: 10,
                    cornerRadius: 14,
                    background: CjguiComposableUiColor(0.08, 0.12, 0.22, 1.0),
                    border: CjguiComposableUiColor(0.45, 0.72, 1.0, 1.0)),
                initialFocusNodeId: 22) // 签名: src/composable_ui.cj:6193-6198
            dialog.add(cjguiComposableText(21, "demo-dialog-title", "这是一个模态弹窗", theme.heading)) // 签名: src/composable_ui.cj:5772
            dialog.add(cjguiComposableButton(22, "close-dialog", "关闭", "CLOSE_DIALOG", 0,
                theme.primaryAction, interactionStyle: theme.primaryActionInteraction)) // 签名: src/composable_ui.cj:5828-5833
            root.add(dialog)
        }
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        if (event.eventKind == CJGUI_COMPOSABLE_UI_EVENT_ACTIVATE) { // 事件码: src/composable_ui_window.cj:59
            if (event.node.actionName == "OPEN_DIALOG") {
                dialogOpen = true
                revision += 1
                return CjguiComposableUiDispatchResult(true) // 签名: src/composable_ui_window.cj:565-570
            }
            if (event.node.actionName == "CLOSE_DIALOG" && dialogOpen) {
                dialogOpen = false
                revision += 1
                return CjguiComposableUiDispatchResult(true)
            }
        }
        // 36 是 escape/外部关闭意图的平台事件码，目前没有公开常量；模板直接写 36
        // （templates/application/ui_only/src/main.cj:164-173）。
        // TODO: 待确认 36 在目标后端是否都稳定，以及是否应等待框架补公开常量后再引用。
        if (event.eventKind == 36 && dialogOpen) {
            dialogOpen = false
            revision += 1
            return CjguiComposableUiDispatchResult(true)
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = DialogLayerSkeletonController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("示例：弹窗", 760u32, 540u32)) // 签名: src/application_host.cj:21-24；配置: src/macos_application_host.cj:25
    if (!host.start()) { host.close(); return 1 } // 签名: src/application_host.cj:12、:15
    while (host.isOpen()) { // 签名: src/application_host.cj:14
        let _ = host.pumpOneTurn() // 签名: src/application_host.cj:13
    }
    host.close() // 签名: src/application_host.cj:15
    return 0
}
```

### 验收标准

窗口打开后先看到“打开弹窗”按钮。点击后出现一个居中的 420×220pt 弹窗，背景把主界面遮住并阻挡输入，键盘焦点初始落在弹窗里的“关闭”按钮上。点“关闭”或按 Esc 后弹窗消失、主界面恢复可操作；再次点击“打开弹窗”能重新打开。关闭主窗口后进程以 0 退出。

---

## 5. `cjguiComposableContextCommandMenuLayer`

**未编译验证**

**为什么该补：** 右键菜单是桌面刚需；投影函数和菜单层在 `src/` 测试与内部 `attachTo` 里都有调用，但 `examples/` 没有消费者，补一个骨架能把“请求 -> 投影 -> 层”的声明部分固定下来，并明确还缺哪些生命周期接线。

**建议目录名：** `examples/context_command_menu_window_app`

### 最小 `src/main.cj`

```cangjie
package cjgui_context_command_menu_window_app

import cjgui.*
import std.collection.*

class ContextCommandMenuSkeletonController <: CjguiComposableUiController &
    CjguiComposableUiContextMenuRequestHandler {
    private var revision: Int64 = 1
    private var contextMenuRequest: ?CjguiComposableUiContextMenuRequest = None
    private let scope = CjguiComposableUiIdentityScope("gap-context-menu-demo") // 签名: src/composable_ui.cj:4139-4148

    public func uiSceneVersion(): Int64 {
        return revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let theme = CjguiComposableUiTheme.beaconDark() // 签名: src/composable_ui.cj:1561
        let root = cjguiComposableLayerHost(1, "context-menu-root", theme.page) // 签名: src/composable_ui.cj:6125
        let content = cjguiComposableVertical(2, "context-menu-content",
            CjguiComposableUiStyle(padding: 16, gap: 12, growX: 1, growY: 1)) // 签名: src/composable_ui.cj:5429
        content.add(cjguiComposableText(3, "context-menu-title", "右键菜单示例", theme.heading)) // 签名: src/composable_ui.cj:5772
        // 右键目标必须是可接收输入的节点；按钮满足这个条件，并给请求提供稳定的 nodeId/resourceId。
        content.add(cjguiComposableButton(4, "menu-target", "右键点击这里", "NOOP", 0,
            theme.primaryAction, interactionStyle: theme.primaryActionInteraction)) // 签名: src/composable_ui.cj:5828-5833
        root.add(content)

        if (let Some(request) <- contextMenuRequest) {
            // 命令的 targetReference 必须指向本次请求的目标；窗口会在接受场景里再次校验，
            // 目标不匹配会拒绝而不是把命令改绑到 request.nodeId（src/composable_ui_context_command_menu.cj:131-138）。
            let commands = ArrayList<CjguiComposableUiCommand>([
                CjguiComposableUiCommand("demo.copy",
                    CjguiComposableUiNodeReference.manual(request.nodeId),
                    "复制", CjguiComposableUiShortcut("c"), "Edit", 0, true, false)
            ]) // 签名: src/composable_ui_window.cj:1317-1330；NodeReference.manual: src/composable_ui.cj:4258-4260；Shortcut: src/composable_ui_window.cj:1204-1218
            let metadata = ArrayList<CjguiCommandToolbarMetadata>([
                CjguiCommandToolbarMetadata("demo.copy", "COPY", request.resourceId)
            ]) // 签名: src/composable_ui_command_toolbar.cj:59-74
            let projection = cjguiContextCommandMenuProjection(request, commands, metadata) // 签名: src/composable_ui_context_command_menu.cj:136-138
            // 请求对象只能由窗口创建：CjguiComposableUiContextMenuRequest 的 init 不是 public
            // （src/composable_ui_window.cj:785-829），应用侧只能从 requestContextMenu 回调拿到。
            root.add(cjguiComposableContextCommandMenuLayer(scope.child("context-menu"),
                "context-menu-demo", request, projection, "menu-target")) // 签名: src/composable_ui_context_command_menu.cj:291-295
        }
        return root
    }

    // 窗口在右键/键盘入口创建请求后回调这里；返回 true 表示应用接受该请求。
    public func requestContextMenu(request: CjguiComposableUiContextMenuRequest): Bool { // 签名: src/composable_ui_window.cj:836
        contextMenuRequest = Some(request)
        revision += 1
        return true
    }

    // 窗口在 superseded / outside / escape / stale-target 等结束时回调这里。
    public func contextMenuRequestEnded(requestId: Int64, reason: String): Unit { // 签名: src/composable_ui_window.cj:837
        let _ = reason
        if (let Some(current) <- contextMenuRequest) {
            if (current.requestId == requestId) {
                contextMenuRequest = None
                revision += 1
            }
        }
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        // 最小关闭路径：窗口把 Escape/外部点击派发成 36 号事件，text 带冻结的 requestId。
        // 条件照既有菜单类 src/composable_ui_context_command_menu.cj:566-570；36 没有公开常量。
        // TODO: 待确认 完整请求生命周期：
        //   1) 菜单行激活（eventKind == 27）如何把 CJGUICONTEXTCOMMAND:<requestId>:<commandId>
        //      交给 window.invokeContextMenuCommand(requestId, commandId)（src/composable_ui_window.cj:8501），
        //      并在成功/失败后清空 contextMenuRequest；
        //   2) 请求被新请求替换（superseded）时，clear 与重新 build 的先后顺序；
        //   3) 右键入口是否还需要应用侧显式调用 window.requestContextMenuForFocusedNode()
        //      （src/composable_ui_window.cj:16514）还是只依赖指针入口。
        // 本骨架只验收“请求 -> 菜单层出现 + Escape/外部点击消失”，不宣称菜单行可执行。
        if (event.eventKind == 36) {
            if (let Some(request) <- contextMenuRequest) {
                if (event.text == "escape:${request.requestId}" ||
                    event.text == "outside:${request.requestId}") {
                    contextMenuRequest = None
                    revision += 1
                    return CjguiComposableUiDispatchResult(true) // 签名: src/composable_ui_window.cj:565-570
                }
            }
        }
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        let _ = eventKind
        let _ = nodeId
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

main(args: Array<String>): Int64 {
    if (args.size != 0) { return 2 }
    let controller = ContextCommandMenuSkeletonController()
    let host = cjguiCreatePlatformApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("示例：右键菜单", 720u32, 520u32)) // 签名: src/application_host.cj:21-24；配置: src/macos_application_host.cj:25
    if (!host.start()) { host.close(); return 1 } // 签名: src/application_host.cj:12、:15
    while (host.isOpen()) { // 签名: src/application_host.cj:14
        let _ = host.pumpOneTurn() // 签名: src/application_host.cj:13
    }
    host.close() // 签名: src/application_host.cj:15
    return 0
}
```

### 验收标准

窗口里看到“右键点击这里”的目标区域。在目标上点右键，指针附近出现一个单层菜单，宽度 220pt，里面有一行“复制  ⌘c”；按 Esc 或点击菜单外面，菜单消失，主界面恢复。菜单行点击后的业务执行不在本骨架验收范围（见 TODO）。关闭主窗口后进程以 0 退出。

---

## 附：签名引用与 TODO 汇总

### 各骨架引用的签名行

| 骨架 | 主要签名行 |
| --- | --- |
| `cjguiComposableSplitView` | `src/composable_ui.cj:5497-5500`（组件）；`src/composable_ui.cj:5429`（vertical）；`src/composable_ui.cj:5772`（text）；`src/composable_ui.cj:6125`（layer host）；`src/composable_ui.cj:1048`（style init）；`src/composable_ui.cj:112`（HORIZONTAL）；`src/application_host.cj:21-24`、`12-15`；`src/macos_application_host.cj:25` |
| `cjguiComposableSelectableListRow` | `src/composable_ui.cj:6020-6031`（组件）；`6032-6041`（样式/operationActionName 回落语义）；`src/composable_ui.cj:1655-1666`（VirtualListItem）；`src/composable_ui.cj:5828-5833`（内部 button 目标）；`src/composable_ui.cj:5429`、`5772`、`6125`、`1048`、`265`；`src/composable_ui_window.cj:59`、`565-570`；`src/application_host.cj:21-24`、`12-15`；`src/macos_application_host.cj:25` |
| `cjguiComposableGrid` | `src/composable_grid.cj:77-81`（组件）；`src/composable_grid.cj:33-41`（GridSpec）；`src/composable_grid.cj:21-31`（字段）；`src/composable_grid.cj:43-57`（派生 node id）；`src/composable_ui.cj:5429`、`5772`、`6125`、`1048`；`src/application_host.cj:21-24`、`12-15`；`src/macos_application_host.cj:25` |
| `cjguiComposableDialogLayer` | `src/composable_ui.cj:6193-6198`（组件）；`src/composable_ui.cj:5828-5833`（button）；`src/composable_ui.cj:5772`、`5429`、`6125`、`1048`；`src/composable_ui_window.cj:59`、`565-570`；`src/application_host.cj:21-24`、`12-15`；`src/macos_application_host.cj:25` |
| `cjguiComposableContextCommandMenuLayer` | `src/composable_ui_context_command_menu.cj:291-295`（组件）；`136-138`（projection）；`src/composable_ui_window.cj:785-829`（request，init 非 public）、`835-838`（handler 接口）；`src/composable_ui.cj:4139-4148`、`4158-4168`（scope）；`src/composable_ui_window.cj:1317-1330`（command）、`1204-1218`（shortcut）；`src/composable_ui.cj:4258-4260`（NodeReference.manual）；`src/composable_ui_command_toolbar.cj:59-74`（metadata）；`src/composable_ui_context_command_menu.cj:566-570`（既有 Escape/outside 判定）；`src/composable_ui_window.cj:8501`（invokeContextMenuCommand，仅 TODO 引用）；`src/application_host.cj:21-24`、`12-15`；`src/macos_application_host.cj:25` |

### TODO 待确认清单

| 骨架 | TODO 位置 | 待确认内容 |
| --- | --- | --- |
| `cjguiComposableSplitView` | `applyUiEvent` 内 | 手柄拖拽后 `firstSize` 由谁持有、如何回写；公共函数没有 `splitState`，窗口只处理 state-bound divider（`src/composable_ui_window.cj:12623-12632`），probe 只测几何。 |
| `cjguiComposableSelectableListRow` | `buildUi` 行循环后 | `isFocused` 的数据来源；骨架没有窗口句柄，固定传 `false`，不把选中当焦点。业务命名上 `actionName` 与 `operationActionName` 的约定也已用注释固定为“空串回落到 actionName”。 |
| `cjguiComposableGrid` | 无 | 参数全部按 `src/composable_grid.cj:77-81` 与测试 `composable_grid_test.cj:17-18` 填；`caretNodeId`/`caretOffset` 使用默认值，未接单元格内光标。 |
| `cjguiComposableDialogLayer` | `applyUiEvent` 内 | 关闭意图事件码 `36` 没有公开常量，暂按 `templates/application/ui_only/src/main.cj:164-173` 的既有用法；需确认目标后端稳定性和是否补常量。 |
| `cjguiComposableContextCommandMenuLayer` | `applyUiEvent` 内 | 菜单行激活到 `window.invokeContextMenuCommand` 的接线、`contextMenuRequest` 清理顺序、superseded 处理、键盘入口是否需应用主动调用；骨架只做“请求 -> 层出现 + Escape/外部点击消失”。 |
