# 阶段任务：CJGUI 示例补齐规格（示例线）

你是这条线唯一的执行者。任务不是写成品代码，是把「哪些组件没人会用、该补什么示例、示例骨架长什么样」查清楚、写下来，让下一个人照着填就能跑。

上一轮的审计已经把账建完了（`runtime/cjgui/audit/` 6 个文件）。你这轮是消费这份账，不是重做。全程零构建、零改动。

## 0. 先读什么

只读这些：

1. `runtime/cjgui/audit/public-api-surface.md`（主输入，86 行组件表）
2. `runtime/cjgui/audit/capability-matrix.md` 的第一节和第二节（只看组件相关部分，第三节 native 不用看）
3. `runtime/cjgui/examples/tree_outline_consumer/` 整个目录（当模板看，这是现有最完整的示例之一）
4. `runtime/cjgui/examples/settings_form_window_app/` 的 `cjpm.toml` 和 `src/main.cj`

不要读 `docs/plans/` 里其他 2000 多个文件。不要读 `docs/archive/`。

## 1. 硬边界（越界即任务失败）

- 不运行 `cjpm build` / `cjpm test` / 任何编译、链接、启动应用的命令。三条并行线正在构建，抢构建锁会把所有人拖慢。
- 不修改、不删除、不新建 `runtime/cjgui/examples/` 下的任何东西。那是只读区，你这轮只出规格，不出成品。
- 不碰 `runtime/cjgui/src/`、`runtime/cjgui/native/`、`runtime/cjgui/platforms/`、`.workbuddy/`。
- 不执行任何 git 写操作（add / commit / push / checkout / stash / reset）。
- 只新增 `runtime/cjgui/audit/` 下 3 个文件，不要顺手扩张。
- 你写的代码片段一律标注「未编译验证」。不要声称跑通过。
- 用 Grep / rg 检索，不要整文件读大文件。

## 2. 路径事实（先记住）

- 每个示例目录的结构是 `examples/<名字>/src/main.cj`，不是把 .cj 放目录根。
- `examples/` 下 28 个条目，去掉 `__pycache__` 是 **27 个真实消费方**。
- `examples/**/*.cj` 共 **79 个**（不含 `.cjgui/macos-build/` 下的构建副本）。
- `runtime/cjgui/src/*.cj` 共 503 个文件。
- 两处 `cjpm.toml` 还写死绝对路径（已知问题，本轮不修，只记）：`examples/generated_panel_consumer/cjpm.toml:10`、`examples/tree_outline_consumer/cjpm.toml:10`，都是 `cjgui = { path = "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui" }`。

### 数据快照（开工第一件事，必须先记下来）

工作区有大量未提交改动（其他并行线的在途工作）。审计反映的是「此刻的树」，不是某个干净 commit。记下这三个值，写进产出文件开头：

    git rev-parse --short HEAD
    git status --short | wc -l
    date -u +%Y-%m-%dT%H:%M:%SZ

并写明一句：「本规格基于未提交改动的工作区，提交后数字会变」。

### 上一轮审计已确认的基线（用来交叉核对，不是让你重算）

`audit/public-api-surface.md` 的结论段写着：

- 组件工厂表 **86 行**
- 有 `///` 文档 45 条 / 无 21 条
- 有测试 35 条 / 无 31 条
- 有示例消费者 55 条 / 无 11 条
- **无测试且无消费者 4 条**

无示例消费者的 11 条（来自审计第 5 节，直接抄，不要重新判断）：

    cjguiComposableGrid
    cjguiComposableSplitView
    cjguiComposableSelectableListRow
    CjguiComposableUiTreeListSource.buildRow
    CjguiSearchableSelectionPanel.buildRow
    cjguiComposableContextCommandMenuLayer
    cjguiContextCommandMenuProjection
    cjguiComposableDialogLayer
    CjguiComposableUiInspectorPanel.buildUi
    CjguiGeneratedUiStructureHolder.buildAccepted
    CjguiGeneratedUiCollection.buildComposite

其中「无测试且无消费者」的 4 条：

    cjguiComposableSplitView            src/composable_ui.cj:5497
    cjguiComposableSelectableListRow    src/composable_ui.cj:6020
    CjguiGeneratedUiCollection.buildComposite        src/composable_ui_generated_collection.cj:56
    CjguiComposableUiInspectorPanel.buildUi          src/composable_ui_inspector.cj:191

如果你查出的数字与上面不一致，照实报你测到的，并解释差异来源。不要为了对上而改数。

## 3. 任务包

### 包 A：11 个组件的「可抄来源」盘点（先做这个）

对这 11 个组件逐个回答一个问题：**想给它写示例，有没有现成的调用形态可抄？**

每个记录这五项：

1. 完整签名（含全部参数和默认值），给 `文件:行`
2. `src/*_test.cj` 里有没有直接调用？给文件名 + 行号，贴出那一行原代码
3. `src/` 其他文件里框架内部有没有调用？给 `文件:行`
4. `probe/` 或 `examples/*/export_check/` 目录下有没有？给 `文件:行`
5. 结论，三选一：
   - `可抄` —— 至少有一处真实调用，能照着改
   - `只能按签名推` —— 一处调用都没有，只能从参数列表推
   - `不可推` —— 签名依赖复杂类型或接口，光看签名写不出来

注意审计里提过一句：`cjguiComposableSplitView` 在 `probe/pointer_controls_consumer_probe.cj` 有调用，属于「审计口径外」。这类要算进「可抄」，因为那就是可抄的来源。

输出 `runtime/cjgui/audit/example-gap-sources.md`，表格 + 每个组件一小节。

### 包 B：挑 5 个，写最小示例骨架

**选择规则写死，不许自己发明：**

1. 先取「无测试且无消费者」4 条里的 **2 条**（另 2 条 `buildComposite` / `buildUi` 是实现接口的方法，不是独立组件，排除）
   → 即 `cjguiComposableSplitView`、`cjguiComposableSelectableListRow`
2. 再从「有测试可抄」的 7 条里补，优先顺序按用户最可能想用：
   `cjguiComposableGrid`（表格布局是刚需）> `cjguiComposableDialogLayer`（弹窗）> `cjguiComposableContextCommandMenuLayer`（右键菜单）> `CjguiComposableUiTreeListSource.buildRow`
3. 同类只选一个：命令菜单那两条（`...ContextCommandMenuLayer` 和 `cjguiContextCommandMenuProjection`）只选前者

凑够 5 个就停。

每个给这四样：

- **为什么该补**：一句话，说清「没有它别人会卡在哪」
- **最小示例**：一段完整的 `main.cj` 骨架，包含 import、`cjguiCreatePlatformApplicationHost` 或对应的宿主入口、组件调用、最小事件循环、关闭。能省的就省，只保留让这个组件画出来所必需的
- **建议目录名**：放在 `examples/` 下叫什么，小写下划线
- **验收标准**：跑起来应该看到什么（人话，比如「窗口里左右两栏，中间有一条可拖动分隔条」）

输出 `runtime/cjgui/audit/example-gap-skeletons.md`。

⚠️ 骨架里的每个 API 调用都必须来自包 A 查到的真实签名。参数个数、类型、顺序对不上就是错。拿不准的用 `// TODO: 待确认` 标出来，不要编。

⚠️ 骨架一律标「未编译验证」。这条不是免责声明，是让人知道下一步必须先编译再落地。

### 包 C：示例模板解剖

挑 `examples/tree_outline_consumer/` 拆开讲清楚：一个合格示例由哪些文件组成，每个文件干什么。

至少覆盖：

- `cjpm.toml`（依赖怎么写的、两个还写死绝对路径的为什么是坑）
- `src/main.cj`（入口结构、宿主创建、事件循环、退出）
- `run.sh` / `cjgui_macos_app.sh`（分别是干什么的，哪个是真入口）
- `export_check/`（那是干什么的，新示例要不要照做）
- `*.cj` 测试文件（示例自己的测试放哪）

输出 `runtime/cjgui/audit/example-template-anatomy.md`，写成「新示例照这个填」的清单，不要写成散文。

## 4. 报告格式

三个产出文件之外，报告直接在对话里给，按这个顺序：

1. 做了什么，产出哪 3 个文件
2. 包 A：11 个组件里，`可抄` / `只能按签名推` / `不可推` 各几个，分别是哪些
3. 包 B：选了哪 5 个，为什么选它们（对应哪条选择规则）
4. 包 C：一个合格示例最少要几个文件
5. 你拿不准的地方（宁可标「待确认」，也不要硬写）
6. 空间账：本轮新增多少 KiB

## 5. 验收（我会这样查你）

1. 从包 A 的「可抄」结论里随机抽 3 条，去它给的行号看，那行是不是真的有调用。有一处对不上，整包退回。
2. 从包 B 的 5 个骨架里挑 2 个，把参数个数和类型跟真实签名逐个对。对不上就是编的。
3. 看包 B 选的那 5 个，是否符合我写死的选择规则。自己加戏选的，退回。
4. `git status` 里除了 `runtime/cjgui/audit/` 下 3 个新文件之外没有别的改动。
5. 没有任何构建产物，没有新建 `artifacts/`。

## 6. 遇到问题怎么处理

- grep 漏了、找错了，自己补，不用报。
- 某个组件签名太复杂、看不明白怎么调用，标 `不可推` + 写清卡在哪，跳到下一个，别死磕。
- 整包做完集中报一次，不要每做完一包停一次。
- 不确定就标「待确认」。表格填不满没关系，猜出来的假答案才是问题。

## 7. 容量

纯文本产出，预计新增不到 100 KiB。不要创建示例目录、不要复制源码树、不要生成截图。
