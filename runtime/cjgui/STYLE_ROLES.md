# 主题角色与桌面组合（experimental）

普通应用先选 `CjguiComposableUiTheme.paperLight()`、`beaconDark()` 或
`warmPaper()`，再选角色。角色返回现有 `CjguiComposableUiNamedStyle`；
`boundStyle()` 一次携带基础样式与交互态，避免只换颜色却忘记 hover/focus。
旧 Theme 字段、显式 Style + InteractionStyle 调用均兼容，不建立全局主题。

```cangjie
let theme = CjguiComposableUiTheme.warmPaper()
let selected = CjguiComposableUiInteractionState.SELECTED
let navigation = cjguiComposableButton(101, "nav-notes", "素材与笔记", "OPEN_NOTES", 1,
    theme.navigationRow().boundStyle(), ownerInteractionState: selected)
let save = cjguiComposableButton(102, "save", "保存", "SAVE", 1,
    theme.actionStyle(primary: true).boundStyle())
let search = cjguiComposableTextInput(103, "search", "检索素材", query, 1,
    theme.fieldStyle().boundStyle(growX: Some(1)), fieldId: "query")
```

| 入口 / 公开名 | 用途与默认值 |
| --- | --- |
| `navigationRow()` / `navigation` | 全宽导航，32pt 高、8pt 内边距、单行省略；owner 提供选中态 |
| `itemRow()` / `item` | 相关资料/数据行，全宽、自然高度、最小36pt、最多两行 |
| `actionStyle(primary: true)` / `primary_action` | 主操作，32pt 高、8pt 圆角、单行省略 |
| `actionStyle()` / `secondary_action` | 次操作，完整交互态、保持中性表面 |
| `actionStyle(quiet: true)` / `quiet_action` | 低强调操作；不用于替代导航选中态 |
| `fieldStyle()` / `input` | 单行输入，32pt 高、8pt 内边距和圆角 |
| `surfaceStyle()` / `card` | 主题分组表面；暖纸主题12pt 内边距、8pt gap、10pt 圆角 |
| `captionStyle()` / `caption` | 11pt 支持信息，标题/正文沿用主题 heading/body |
| `feedbackStyle(EMPTY/LOADING/ERROR/SUCCESS)` | 显式语义反馈，自然高度；文本、状态、重试动作仍归应用 |

字号、32pt 控件与4/8/12/16间距是 CJGUI 的桌面适配值，不是对 HarmonyOS
设计 token 的逐项复制。可以用 `boundStyle(fixedHeight: Some(28), ...)`
调整密度。局部调整只接受现有几何/排版参数；颜色在主题或命名定义中集中声明。
长说明使用自然高度，空结果不创建固定高空文本；短内容可以保留有目的的阅读留白。

状态继续由原有引擎合成：normal → selected → checked → focused → hover →
pressed → disabled。导航 hover 只调前景，选中底色和焦点边框可同时保留；按下及
禁用按既定优先级覆盖。仅 SELECTED/CHECKED 能由 owner 提供；不能用 owner bits
伪造 hover、焦点或禁用。真正禁用请传 `enabled: false`。几何不随交互 paint 改变。

现有 `CjguiStatusFeedback` 和 `CjguiContentFeedback` 可直接传
`CjguiStatusMessageStyle.themed(theme, kind)` / `CjguiContentStateStyle.themed(theme, kind)`，
保留文字类型标记、no-data/no-match 区分和原动作，不另建反馈状态机。

`alignX/alignY` 定位节点在父容器中的位置，不能用来居中按钮内部文字。
导航使用全宽角色，长文字使用受约束宽度与省略；需要图文组合时使用现有横排/文本
子树和相同语义动作，不增加第二套输入状态机。

## 手写、生成与混合界面

把同一主题的角色注册到已有 capability catalog 即可发现和使用同名样式：

```cangjie
for (role in theme.namedStyles()) {
    let registered = catalog.namedStyles().register(role)
    // 注册失败应由应用报告；重复注册不是切换主题。
}
```

生成式结构仍使用既有 `style` 名称引用和候选事务，未知名称被拒绝；更换已注册角色
用 catalog 的 `update`。字段/动作/业务草稿仍从同一 owner 绑定。
`ui-only` 入门模板与通知阈值普通消费者使用相同入口；小说工作台选择暖纸主题。
这些接口为 experimental，新增角色的运行验证限本阶段 macOS，未宣称其他后端表现。

## 视觉参考与取舍

本阶段实际阅读 [ArkUI 按钮](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-common-components-button/)
（页面更新2026-10-16）、[UI Design Kit](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ui-design-introduction/)
（2026-07-28）、[焦点设计](https://developer.huawei.com/consumer/cn/doc/doccenter-ux-design/hmi-focus-0000001748650376/)
及[新闻阅读多设备案例](https://developer.huawei.com/consumer/cn/doc/doccenter-multi-device/multi-news-read/)。
采用清晰的操作层次、成组表面、独立选中/焦点、大屏侧栏加内容区、工具栏参与布局等
原则。PC/2in1 和可调整窗口为前提；不照搬手机胶囊默认、触摸留白、标题栏沉浸或
光影材质，也不宣称实现了整套 HDS。未引入 ArkUI/UI Design Kit 的运行时或依赖。

组合见 [布局配方](LAYOUT_PRIMITIVES.md)，字段错误见 [字段与反馈](FIELD_CONTROLS.md)。

## HIG 桌面主题（新增，experimental）

`CjguiComposableUiTheme.higLight()` / `higDark()` / `hig(dark:)` 提供一套按 Apple macOS HIG
方向校准的桌面角色；手写与生成式界面共用同一批 `namedStyles()`，不引入 SwiftUI/AppKit 依赖，
也不改变既有 `paperLight()/beaconDark()/warmPaper()` 的默认外观。

- 颜色取自本机 NSColor 语义色实测（light/dark，含 alpha 合成）：窗口背景、正文背景、
  分隔线、主强调、键盘焦点环、禁用文字；取样脚本与逐项来源见阶段证据
  `work/prototype-host-20261108/hig/`。
- 控件高度 28pt（AppKit large 实测；自绘 + 中文正文选它而非 24pt regular）、正文 13pt、
  标题 22pt、说明 11pt（HIG 内置文本样式）；间距 4/8/12/16 与圆角 7/10 属 CJGUI 项目决定，
  不是 Apple 官方 token。
- 交互态仍由既有引擎合成：悬停/按下用 label 6%/12% 叠加，焦点用键盘焦点指示色 3pt 环，
  选中/勾选用 12% accent 底 + accent 文字；几何不随状态改变。亮/暗切换只重发同名角色调用
  `catalog.namedStyles().update()`，不重新提交已接受结构。
- 未做（如实差异）：标题栏跟随外观、玻璃/模糊/材质、完整原生控件外观。

```cangjie
let theme = CjguiComposableUiTheme.hig(dark: false)
let form = CjguiGeneratedUiFormBinding(domain, ownerId)
let catalog = form.capabilityCatalog()
for (role in theme.namedStyles()) {
    let _ = catalog.namedStyles().register(role)
}
// 生成式结构里字段写 style=input、主操作写 style=primary_action/次操作 secondary_action
```

实际消费：`examples/prototype_host_app`（三例：设置表单 / 资产列表详情 / 素材卡片面板）。
