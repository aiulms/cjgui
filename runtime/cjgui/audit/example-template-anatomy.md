# 示例解剖：`tree_outline_consumer` → 新示例填写清单

> 数据快照：HEAD `dc27dff`，**247 条未提交改动**，快照时间 `2026-10-21T07:40:16Z`（UTC）。
> **本规格基于未提交改动的工作区，提交后数字会变。** 下文 `文件:行` 只对该快照有效，不是任何干净 commit 的行号。
> 方法：纯静态阅读 + `find`/`grep`/`git` 只读检查；未构建、未运行、未修改任何已有文件。
> 仓库根：`/Users/jiangxuanyang/Desktop/cangjie`；示例实际位于 `runtime/cjgui/examples/tree_outline_consumer/`（不是仓库根的 `examples/`）。

## 0. 结论（先看这 5 行）

| # | 结论 | 证据 |
| --- | --- | --- |
| 1 | 一个新示例最短只需 **4 个文件**：`cjpm.toml`、`src/main.cj`、`run.sh`、`cjgui_macos_app.sh` | 模板目录正好这 4 个文件：`runtime/cjgui/templates/macos_application/ui_only/`；`create_macos_application.sh:46,71-74` 只替换路径占位符 |
| 2 | 真正入口是 **`run.sh`**；`cjgui_macos_app.sh` 只是被 runner `source` 的 bundle 配置 | `run.sh:4-7` → `run_macos_application.sh:9-12,90`；验证脚本也是调 `zsh run.sh`：`verify_framework_preview_consumer_chains.sh:267` |
| 3 | `cjpm.toml` 的 `cjgui` 依赖必须写相对路径；`tree_outline_consumer/cjpm.toml:10` 和 `generated_panel_consumer/cjpm.toml:10` 的绝对路径是**换机器/换用户名即坏**的坑 | 正确写法见 `settings_form_window_app/cjpm.toml:10` 的 `../..`；runner 会校验依赖必须等于 framework 目录：`macos_build_config.py:184-185` |
| 4 | 示例自己的测试放在 **`src/*_test.cj`**，与 `main.cj` 同 package；`cjpm.toml` **没有** `[test]` target 配置 | `src/catalog_content_update_test.cj:5-10`、`src/shared_definitions_consumption_test.cj:6-10`；全仓 examples 的 `cjpm.toml` 无 `[test]` 段 |
| 5 | `export_check/` **不进正常构建、不随导出包发布**；只被导出链验证脚本复制进一个临时 round | 复制点：`verify_framework_preview_consumer_chains.sh:314-316`；导出白名单不含它：`export_framework_preview.sh:181-183` |

## 1. 真实文件树（`find runtime/cjgui/examples/tree_outline_consumer -type f`）

```text
runtime/cjgui/examples/tree_outline_consumer/
├── cjpm.toml                                  477 B / 14 行
├── cjpm.lock                                   24 B / 3 行（version=0，空 [requires]）
├── run.sh                                     231 B / 7 行（可执行）
├── cjgui_macos_app.sh                         341 B / 10 行（被 source 的配置）
├── verify_large_text_consumer.sh             1027 B / 19 行（可执行）
├── src/
│   ├── main.cj                              39886 B / 786 行
│   ├── catalog_content_update_test.cj        7751 B / 158 行（3 个 @Test）
│   └── shared_definitions_consumption_test.cj 20539 B / 406 行（7 个 @Test）
├── export_check/
│   └── export_interaction_check.cj           6132 B / 133 行
├── .cjgui/                                   # 生成物，git 忽略（.gitignore:51）
│   ├── bundle-staging/                       # 生成目录，当前为空
│   └── native/lib/
│       ├── cjgui_macos_application_host.fingerprint
│       ├── cjgui_macos_application_host.linked.fingerprint
│       ├── libcjgui_internal_renderer.a
│       └── libcjgui_macos_application_launcher.a
└── build-script-cache/                       # 生成物；其 bin/ 被 .gitignore:37 忽略
    └── release/cjgui/bin/
        ├── .script-hash
        ├── build-script
        ├── cjgui.cjo
        └── script-log
```

### 1.1 逐个文件/目录的职责

| 路径 | 是什么 | 谁生成、谁消费 | 新示例 |
| --- | --- | --- | --- |
| `cjpm.toml` | cjpm 模块清单：包名、`src-dir`、链接选项、`cjgui` 依赖、两条 native FFI 库 | 人写；cjpm/runner 读（`cjpm.toml:1-14`） | **必须** |
| `cjpm.lock` | cjpm 锁文件，内容仅 `version = 0` 和空 `[requires]`（`cjpm.lock:1-3`）；模板不带它 | cjpm 生成；本树提交了它 | 可选/生成，不手写 |
| `run.sh` | 用户/CI 入口：定位自身与 `CJGUI_ROOT`，`exec` framework 的 runner（`run.sh:4-7`） | 人/验证脚本调；`verify_framework_preview_consumer_chains.sh:267` | **必须** |
| `cjgui_macos_app.sh` | bundle 配置片段：bundle 名、可执行名、identifier、显示名、resources（`cjgui_macos_app.sh:4-10`） | 被 `run_macos_application.sh:90` `source`；不独立执行 | **必须** |
| `verify_large_text_consumer.sh` | 本示例专属的大文本 fixture 验收：设环境变量、调 `run.sh`、grep 两条 READY 事实（`verify_large_text_consumer.sh:9-17`） | 人/专项验收；未发现其他脚本引用它 | 按需 |
| `src/main.cj` | 唯一应用包：`package`、数据源 `CatalogSource`、控制器 `CatalogController`、`main()` 入口（`main.cj:6,20-21,186,732`） | cjpm 编译；runner 启动 | **必须** |
| `src/catalog_content_update_test.cj` | 内容增量更新单测（3 个 `@Test`，`catalog_content_update_test.cj:24,63,114`） | `cjpm test` | 推荐 |
| `src/shared_definitions_consumption_test.cj` | 共享样式/图片/交互上下文/页签/可读性单测（7 个 `@Test`） | `cjpm test` | 推荐（至少 1 个测试文件） |
| `export_check/export_interaction_check.cj` | 导出 round 的交互驱动：带自己的 `main()`，直接驱动已导出 controller 的事件入口（`export_interaction_check.cj:12,55-64`）；不在 `src/`，不参与正常构建 | 仅 `verify_framework_preview_consumer_chains.sh:314-316` 复制使用 | 按需 |
| `.cjgui/` | runner 的 native 归档、fingerprint、bundle staging、构建快照 | `run.sh` 生成；被 `.gitignore:51` 忽略 | **不要提交/复制** |
| `build-script-cache/` | framework `build.cj` 的脚本缓存/binary | 构建生成；其 `bin/` 被 `.gitignore:37` 忽略 | **不要提交/复制** |

关键事实：`git ls-files` 显示受版本控制的只有 9 个文件（上面 `find` 结果里其余都是生成物）；`.cjgui/` 和 `build-script-cache/` 都是本机构建产物，换机器后由 `run.sh` 重新生成。`git status --porcelain runtime/cjgui/examples/tree_outline_consumer` 在该快照为空，说明这 9 个文件是干净提交内容、生成物被忽略。

## 2. `cjpm.toml`：照这个填

### 2.1 可直接套用的骨架

以 `runtime/cjgui/examples/<name>/cjpm.toml` 为位置，`<name>` 替换为示例目录名：

```toml
[package]
cjc-version = "1.1.3"
name = "<package_name>"                     # 与 src/main.cj 的 package 保持一致
version = "0.0.0"
output-type = "executable"
src-dir = "src"
link-option = "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc -headerpad_max_install_names"

[dependencies]
cjgui = { path = "../.." }                   # 从 examples/<name>/ 回到 runtime/cjgui

# 仅在真的用到时保留：
# cjgui_shared_operation_core = { path = "../../shared_operation_core" }
# cjgui_settings_form_application = { path = "../settings_form_application" }

[ffi.c]
cjgui_internal_renderer = { path = "./.cjgui/native/lib" }
cjgui_macos_application_launcher = { path = "./.cjgui/native/lib" }
```

对照来源：`settings_form_window_app/cjpm.toml:1-16` 是相对路径 + 额外依赖的完整样例；`tree_outline_consumer/cjpm.toml:1-14` 是 UI-only 最小样例（但第 10 行是绝对路径坑，见 2.2）。

### 2.2 字段逐项

| 字段 | 填什么 | 证据/说明 |
| --- | --- | --- |
| `cjc-version` | `"1.1.3"` | tree:2、settings:2 相同；runner 默认工具链必须是 1.1.3（`run_macos_application.sh:45-58`） |
| `name` | 与 `src/main.cj` 的 `package` 同名 | tree cjpm:3 = `cjgui_ui_only_starter`，main:6 相同；settings cjpm:3 = main:1 相同 |
| `version` | `"0.0.0"` | 两个示例一致（tree:4、settings:4） |
| `output-type` | `"executable"` | tree:5、settings:5 |
| `src-dir` | `"src"` | tree:6、settings:6；测试文件也在这个目录下 |
| `link-option` | 原样保留整串：4 个 framework（AppKit/Metal/MetalKit/QuartzCore）+ `-lobjc` + `-headerpad_max_install_names` | tree:7、settings:7；这是 macOS 自绘后端所需的 native 链接面 |
| `[dependencies] cjgui` | **相对路径**；examples/<name> 下用 `"../.."` | settings:10；绝对路径坑见 2.3 |
| 额外依赖 | 按需；`shared_operation_core` 从 examples/<name> 是 `"../../shared_operation_core"`，同目录应用是 `"../<app>"` | settings:11-12 |
| `[ffi.c]` 两条 | 两个库都必须有，路径写 `"./.cjgui/native/lib"` | tree:12-14、settings:14-16；两个条目名与 runner 识别名一致（`macos_build_config.py:204-206`） |
| `[test]` | **不要加**；本仓示例没有 test target 配置 | 全仓 `runtime/cjgui/examples/*/cjpm.toml` 检索不到 `[test]`；测试发现走 cjpm 默认 + `*_test.cj` 约定（见 §6） |

`[ffi.c]` 的路径是相对 manifest 的；runner 在生成快照时会把这两条改写到本应用私有的 native 目录（`macos_build_config.py:204-206`），所以作者侧保留 `./.cjgui/native/lib` 即可，不要写绝对路径。runner 注释也说明 cjpm 会先合并依赖 FFI、再合并应用 FFI，因此两边必须指向同一个私有归档（`run_macos_application.sh:252-255`）。

### 2.3 绝对路径坑（本任务的核心结论）

两处实证：

| 文件:行 | 实际值 | 问题 |
| --- | --- | --- |
| `runtime/cjgui/examples/tree_outline_consumer/cjpm.toml:10` | `cjgui = { path = "/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui" }` | 换机器、换用户名、换 checkout 根目录即找不到依赖 |
| `runtime/cjgui/examples/generated_panel_consumer/cjpm.toml:10` | 同一个绝对路径 | 同上 |
| `runtime/cjgui/examples/settings_form_window_app/cjpm.toml:10` | `cjgui = { path = "../.." }` | 正确：相对 manifest 解析，随目录一起移动 |

为什么是坑，不只是“风格问题”：

1. cjpm 按 manifest 中的字面 path 解析；作者机器之外的路径不存在，依赖解析/构建直接失败。
2. runner 还会显式校验依赖目录必须等于它自己解析出的 framework 目录：`macos_build_config.py:184-185` 的 `resolve(app, dependency["path"]) != runtime` 会抛 `application cjgui dependency must match the runner's framework directory`。也就是说，换目录后不是“悄悄用错的框架”，而是启动前就被拒绝。
3. 导出预览必须重写这类路径：`export_framework_preview.sh:188-192` 把 consumer 的 `cjgui` 改成 `../../framework/cjgui`；`export_fingerprint.py:136-146` 把 `consumers/tree_outline_consumer/cjpm.toml` 列为 `REWRITTEN_ENTRIES`，明确“不按作者原件逐字节比较”。这反证了作者侧的绝对路径不是可发布内容。

正确写法（相对路径怎么算）：

```text
runtime/cjgui/examples/<name>/cjpm.toml
  ..        -> runtime/cjgui/examples
  ../..     -> runtime/cjgui                  # cjgui 依赖
  ../../shared_operation_core -> runtime/cjgui/shared_operation_core
  ../settings_form_application -> runtime/cjgui/examples/settings_form_application
```

模板也证明相对路径是契约：`templates/macos_application/ui_only/cjpm.toml:10` 写的是占位符 `__CJGUI_FRAMEWORK_RELATIVE_PATH__`，`create_macos_application.sh:46` 用 `os.path.relpath(destination, framework_root)` 算出真实相对路径，再在 `:71-74` 替换。不要手工填作者绝对路径。

补充：`adaptive_layout_public_consumer/cjpm.toml:10` 写的是 `${CJGUI_ROOT}`；这不是本仓模板或 settings 示例采用的相对路径写法，依赖外部环境/重写，不要把它当模板。新示例统一用 `../..`。

同类问题还有一处：`tree_outline_consumer/verify_large_text_consumer.sh:7` 的 `CJGUI_CANGJIE_HOME` 默认值是作者机器路径 `/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3`。它可被环境变量覆盖，但默认值仍不可移植；新示例的验收脚本不要复制这个默认值，应要求调用者设置 `CANGJIE_HOME`/`CJGUI_CANGJIE_HOME` 或从环境读取。

## 3. `src/main.cj`：入口解剖

### 3.1 文件头

| 项 | tree 的写法 | 证据 |
| --- | --- | --- |
| 包声明 | `package cjgui_ui_only_starter`，与 cjpm `name` 一致 | `main.cj:6`；测试文件同 package：`catalog_content_update_test.cj:5`、`shared_definitions_consumption_test.cj:6` |
| import | `cjgui.*`、`std.collection.*`、`std.env.*`、`std.time.*` | `main.cj:8-11`；最小可用通常只需要 `cjgui.*` + `std.collection.*` + `std.env.*` |
| 一个包一个 `main` | 顶层 `main(): Int64`，没有 `func` 关键字 | `main.cj:732`；导出链按这段文本重命名（`verify_framework_preview_consumer_chains.sh:308-312`） |

### 3.2 控制器：必须实现的 5 个方法

接口定义：`runtime/cjgui/src/composable_ui_window.cj:734-747`。tree 的 `CatalogController` 从 `main.cj:186` 开始，5 个方法如下：

| 接口方法 | tree 实现 | 必须做什么 |
| --- | --- | --- |
| `uiSceneVersion(): Int64` | `main.cj:387-389` 返回 `revision` | 每次“渲染器可见状态”变化都要递增；窗口用它做廉价失效判断（接口注释 `composable_ui_window.cj:735-739`） |
| `buildUi(): CjguiComposableUiNode` | `main.cj:395-505` | 返回本次场景根节点；先同步数据（`syncWithData`，705-713），再构建节点树 |
| `applyUiEvent(event): CjguiComposableUiDispatchResult` | `main.cj:553-636` | 处理按下/文本/滚轮/键盘/焦点；有状态变化才返回 `didApply=true` |
| `rejectUiEvent(eventKind, nodeId): CjguiComposableUiDispatchResult` | `main.cj:638-640` 返回 false | 目标已失效时把“输入未应用”反馈给人，不能静默吞键（接口注释 742-745） |
| `requestWindowClose(): CjguiComposableUiDispatchResult` | `main.cj:642-644` 返回 `CjguiComposableUiDispatchResult(true, shouldClose: true)` | 只有 `shouldClose=true` 才会走正常关窗 |

返回值语义：`CjguiComposableUiDispatchResult` 的 `didApply` 与 `shouldClose` 是公开字段（`composable_ui_window.cj:559-570`）。状态改了却返回 false，窗口不会重绘；状态没改却返回 true，会做无意义刷新。`rejectUiEvent` 两种现有写法：tree 直接返回 false（`main.cj:638-640`），settings 把“输入未应用”写进 status 并返回 true（`settings_form_window_app/src/main.cj:919-923`）；新示例至少要保证不静默改状态，最好给人可见反馈。

### 3.3 `buildUi()` 的组织方式

tree 的返回根是一个滚动容器，不是裸 `vertical`：

- `cjguiComposableScrollArea(20, "catalog-scroll", viewport, ...)`（`main.cj:404-405`），内部 `section` 垂直容器（406），再放标题/图标/动作行/页签/树列表。
- 非虚拟节点用显式唯一 nodeId：标题 21、图标 29、动作 23-26、详情 64、状态 63、页签容器 71 等（`main.cj:407-433,472,486,499`）。
- 虚拟列表行内部用 nodeId `0` + `CjguiComposableUiIdentityScope` 的局部 key，避免手工保留整段 nodeId（`main.cj:520-545`）；行的稳定 key 来自数据源（`childAt` 返回的 `CjguiComposableUiTreeNode`，60-83）。
- `semanticId` 用于测试/验收读取 accepted scene（如 `catalog-large-details`，462-473；验收读回 723-729）。

新示例照做：根节点一个；每个节点有稳定 `semanticId`；同一场景内 nodeId 不重复；重复行用 identity scope，而不是复制整段数字。

### 3.4 `applyUiEvent()` 的事件类型

公开常量在 `composable_ui_window.cj:59-65`：

| kind | 含义 | tree 的处理 |
| --- | --- | --- |
| 27 | `ACTIVATE`（按下/激活） | 只有 27 允许改展开/多选/动作（`main.cj:590-634`） |
| 28 | `TEXT_CHANGED`（文本结果） | tree 没有文本输入，不处理 |
| 29 | `BOOLEAN_CHANGED` | tree 不处理 |
| 30 | `SCROLL`（滚动意图） | 列表节点 27 上滚动（`main.cj:581-589`） |
| 31 | `FOCUS`（焦点变化） | tree 明确不因焦点改状态（`main.cj:590-594`） |
| 35 | 键盘导航（NAVIGATE；无公开常量） | 列表节点 27 上处理方向键/Shift/全选（`main.cj:559-580`） |

tree 的分发顺序值得照抄：先处理列表级的键盘/滚轮，再拒绝非 27 的激活路径，最后按 `actionName` 分发（`CATALOG_GROUP_TOGGLE`、`CATALOG_LEAF_TOGGLE`、`CATALOG_EXPAND_ALL`、`CATALOG_COLLAPSE_ALL`、`CATALOG_SELECT_ALL`、`CATALOG_CLEAR`，595-634）。新示例至少处理 27（按钮）和 28（文本），其余返回 `false`。

### 3.5 入口、事件循环、退出

tree 的 `main()`（`main.cj:732-786`）：

```cangjie
main(): Int64 {
    let source = CatalogSource(...)                       // 1. 业务状态由应用自己持有
    let controller = CatalogController(source, ...)       // 2. 控制器持有投影/视图状态
    let host = CjguiMacosApplicationHost(                 // 3. 单窗口宿主
        controller,
        configuration: CjguiMacosApplicationWindowConfiguration("CJGUI 知识目录", 640u32, 520u32)
    )
    controller.attachWindow(host.window())                // 4. 可选：把窗口交给控制器做 focus/readback
    if (!host.start()) { return 2 }                       // 5. 首帧启动失败
    println("TREE_OUTLINE_CONSUMER_READY ...")            // 6. 发布可 grep 的就绪事实
    getStdOut().flush()
    while (host.isOpen()) {                               // 7. 事件循环
        let _ = host.pumpOneTurn()
    }
    return 0                                              // 8. 窗口关闭后正常退出
}
```

逐项证据：

| 步骤 | API | 证据 |
| --- | --- | --- |
| 创建单窗口宿主 | `CjguiMacosApplicationHost(controller, configuration:)` | `main.cj:737-740`；类定义 `macos_application_host.cj:1007` |
| 取框架窗口 | `host.window()` | `main.cj:741`；`macos_application_host.cj:1036` |
| 启动 | `host.start()` | `main.cj:742`；`macos_application_host.cj:1100` |
| 泵一帧 | `host.pumpOneTurn()` | `main.cj:783`；`macos_application_host.cj:1186` |
| 是否还开着 | `host.isOpen()` | `main.cj:782`；`macos_application_host.cj:1213` |
| 关闭 | `host.close()` | 一次性验收路径 `main.cj:774`；实现 `macos_application_host.cj:1238` |
| 就绪事实 | `println(...)` + `getStdOut().flush()` | `main.cj:755-758`；验证脚本 grep `TREE_OUTLINE_CONSUMER_READY`（`verify_framework_preview_consumer_chains.sh:272,286`） |

退出语义：用户点关闭 → 窗口关闭 → `host.isOpen()` 为 false → 循环结束 → `return 0`。`pumpOneTurn` 在窗口已关时会自己 `close()` 并返回 false（`macos_application_host.cj:1186-1209`）。更稳妥的写法是模板的入口：启动失败也显式 `host.close()`（`runtime/cjgui/templates/macos_application/ui_only/src/main.cj:76`），循环后 `host.close()`（同文件 80）。

一次性验收模式（可选）：tree 通过环境变量启用大文本 fixture（`main.cj:716-721`），打印 `TREE_OUTLINE_CONSUMER_LARGE_TEXT ...` 后若 `CJGUI_TREE_OUTLINE_ACCEPTANCE_ONESHOT=1` 就 `host.close()` 并返回 0（`main.cj:759-777`）。这是示例自己的验收开关，不是框架入口约定。

`main` 的签名形式：tree 用无参 `main(): Int64`，settings 用 `main(args: Array<String>): Int64`（`settings_form_window_app/src/main.cj:1190-1196`）。如果希望被 `verify_framework_preview_consumer_chains.sh` 第 2b 步复用，必须保留无参、无 `func` 的 `main(): Int64 {` 文本，因为脚本按字面替换它（`verify_framework_preview_consumer_chains.sh:308-312`）。

### 3.6 需要多窗口/外部连接时的第二种入口

tree 是单窗口 UI-only；`settings_form_window_app` 展示了另一种写法：

- `CjguiMacosApplication(maximumWindowCount: 2)`（`settings_form_window_app/src/main.cj:1148`）
- `application.openWindow(controller, configuration:)`（1149-1151）
- `application.window(businessId)`（1157），控制器 `bindWindow(window)`（1158/110-113）
- 外部连接 `CjguiSharedOperationExternalConnection(...)` + `enableWindowProgressReads` + `enableGeneratedUiProvider` + `attachExternalConnection`（1159-1163）
- Inspector `CjguiMacosInspector(application, businessId)`（1166）
- 循环 `while (application.isOpen()) { application.pumpOneTurn() ... }`（1174-1184）
- 收尾 `inspector.close(); application.close()`（1185-1186）

选择规则：纯 UI / 单窗口 → 用 `CjguiMacosApplicationHost`（tree、模板）；需要多窗口、descriptor、Inspector、外部连接 → 用 `CjguiMacosApplication`（settings、generated_collection 等）。不要为了“看起来完整”引入外部连接。

## 4. `run.sh` 与 `cjgui_macos_app.sh`

### 4.1 调用链（谁调谁）

```text
人 / 验证脚本
  └─ zsh run.sh [--build-only] [args...]                     # tree run.sh:4-7
       └─ zsh $CJGUI_ROOT/scripts/run_macos_application.sh \
              $APP_DIR/cjgui_macos_app.sh "$@"
            ├─ source cjgui_macos_app.sh                     # runner:90（只读变量）
            ├─ 校验 4 个必填变量                              # runner:92-95
            ├─ 生成 native 归档到 $APP_DIR/.cjgui/native/lib # runner:224-237
            ├─ prepare 构建快照 .cjgui/macos-build/application # runner:256
            ├─ cjpm build --skip-script -i -V                # runner:273
            ├─ 组装 target/release/<BUNDLE>.app              # runner:295-300
            └─ exec .../Contents/MacOS/<EXEC> "$@"           # runner:352
```

### 4.2 两个脚本各干什么

| 文件 | 角色 | 关键证据 |
| --- | --- | --- |
| `run.sh` | **真入口**。自定位 `APP_DIR`，把 `CJGUI_ROOT` 设为 `APP_DIR/../..`，`exec` framework runner，并把配置路径和全部参数传过去 | `run.sh:4-7`；settings 版本多一个“已有 `CJGUI_ROOT` 就不覆盖”的判断（`settings_form_window_app/run.sh:5-8`） |
| `cjgui_macos_app.sh` | **不是入口**，而是被 runner `source` 的 bundle 配置片段：4 个必填名字 + 可选 resources；没有 `exec`，也没有自己的 main | `cjgui_macos_app.sh:4-10`；`run_macos_application.sh:90` `source "$APP_CONFIG"`；必填校验 92-95 |

因此：**真入口是 `run.sh`**。直接执行 `cjgui_macos_app.sh` 不会启动应用；它只是变量声明。验证脚本也一律用 `zsh run.sh`（`verify_framework_preview_consumer_chains.sh:267`、`verify_exported_new_capabilities.sh:159`）。

### 4.3 `cjgui_macos_app.sh` 必填项

| 变量 | tree 值 | 约束 |
| --- | --- | --- |
| `CJGUI_MACOS_APP_BUNDLE_NAME` | `CJGUIUiOnlyStarter` | 纯名字，不能含 `/` 或 `.app`（runner:96-99） |
| `CJGUI_MACOS_APP_EXECUTABLE_NAME` | `CJGUIUiOnlyStarter` | 同上；最终 bundle 内的可执行名 |
| `CJGUI_MACOS_APP_IDENTIFIER` | `org.example.cjgui.ui-only-starter` | 反向 DNS；不能含 `/` |
| `CJGUI_MACOS_APP_DISPLAY_NAME` | `CJGUI UI-only Starter` | 窗口/应用显示名 |
| `CJGUI_MACOS_APP_RESOURCES` | 一个 `composable-beacon.png` | 可空；settings 用 `()`（`settings_form_window_app/cjgui_macos_app.sh:8`）；图片用 bundle basename |

runner 先清空这些变量和 resources 数组，再 source 配置（`run_macos_application.sh:86-90`），所以配置必须自己赋全部 4 个名字。`CJGUI_RUNTIME_DIR` 由 runner 设置（84），配置里的 `$CJGUI_RUNTIME_DIR/resources/...` 才能解析。

注意：`settings_form_window_app/native/Info.plist` 不在 runner 的读取路径上；runner 自己生成 `Info.plist`（`run_macos_application.sh:300`）。新示例不要为了“像 settings”而额外造 `native/Info.plist`，除非有另一条构建链明确消费它。

## 5. `export_check/`：是什么、谁消费、要不要照做

内容：只有一个 `export_interaction_check.cj`（133 行）：

- 与主应用同 package：`package cjgui_ui_only_starter`（`:12`）。
- 定义 `exportCheckEvent` 构造 35（键盘）事件（`:17-25`）；`exportCheckReport` 打印 `EXPORT_TREE_CHAIN ...`（`:49-53`）。
- 自己的 `main(): Int64`（`:55`）：直接 `CjguiComposableUiWindow(controller)`（`:59`）→ `window.start()` + `window.refresh()`（`:60`）→ `expandAll()` / `applyUiEvent(35, ...)` / `refreshIfNeeded()` → 最后 `window.close()`（`:118`）。
- 它不依赖 AppKit bundle 的 `main`，而是被复制进导出 round 后作为该 round 的唯一 `main` 运行。

消费者（唯一找到的）：

- `runtime/cjgui/native/scripts/verify_framework_preview_consumer_chains.sh` 第 2b 步：
  - 把导出的 consumer 复制成 `tree-interaction-round`，删掉 `target`/`.cjgui`（`:298-300`）；
  - 把 `main(): Int64 {` 文本改成 `func consumerAppMain(): Int64 {`，断言没有 `func main()`（`:306-313`）；
  - 把本文件复制为 round 的 `src/export_interaction_check.cj`（`:314-316`）；
  - 运行后 grep 固定的 `EXPORT_TREE_CHAIN ready/expanded/down/shift_down/select_all/collapse/window` 行（`:366-377`）。

是否随导出包发布：**不**。

- `export_framework_preview.sh` 的 consumer 文件白名单只包含 `src/` 树、`cjpm.toml`、`run.sh`、`cjgui_macos_app.sh`、`README.md`、`client.py` 等（`:181-183`），没有 `export_check/`。
- `export_fingerprint.py` 只哈希 consumer 的 `src/*.cj`、`cjgui_macos_app.sh`，以及被重写的 `cjpm.toml`/`run.sh`（`:84-92,136-146`），也没有 `export_check/`。
- 因此它是**仓库内的验证资产**，不是示例运行时的一部分。

新示例要不要照做：**默认不要**。只有同时满足以下条件才加：

1. 该示例被加入 `export_framework_preview.sh:171-173` 的 `consumers`（full profile 额外加入 `tree_outline_consumer`、`generated_panel_consumer`、`adaptive_layout_public_consumer`；基础 consumers 还有 `generated_collection`、`rule_set_window_app`）；
2. 导出链验证脚本为它新增一个类似 2b 的 round；
3. 你愿意维护一个与主 `main()` 同包、但函数名/打印 token 不同的第二入口。

否则，普通示例只需要单元测试（§6），不需要 `export_check/`。

## 6. 测试：怎么放、怎么跑到

### 6.1 放法

| 项 | tree 的事实 | 证据 |
| --- | --- | --- |
| 位置 | 直接放在 `src/`，与 `main.cj` 同目录 | `src/catalog_content_update_test.cj`、`src/shared_definitions_consumption_test.cj` |
| 命名 | `*_test.cj` | 两个文件均以 `_test.cj` 结尾；cjpm 约定这类文件只在 test target 编译 |
| package | 与主文件相同：`package cjgui_ui_only_starter` | `catalog_content_update_test.cj:5`、`shared_definitions_consumption_test.cj:6` |
| import | `std.unittest.*` + `std.unittest.testmacro.*` | `catalog_content_update_test.cj:9-10` |
| 组织 | 多个 `@Test func ...(): Unit`；允许 private 辅助函数/类 | `catalog_content_update_test.cj:24,63,114`；`shared_definitions_consumption_test.cj:12,70,130,156,198,245,295` |
| 数量 | 3 + 7 = 10 个 `@Test` | 两文件的 `@Test` 计数 |

### 6.2 target 配置在哪

**没有。** `runtime/cjgui/examples/*/cjpm.toml` 中没有 `[test]` 段，也没有 test-dir/test-dependencies 配置；测试发现使用 cjpm 的默认行为：`src-dir = "src"`（`tree_outline_consumer/cjpm.toml:6`）下的 `*_test.cj`。

### 6.3 怎么跑到

仓库内没有找到只针对 tree consumer 的单测脚本（对 `cjpm test` + `tree_outline_consumer` 的检索无专用入口）。框架文档给出的通用流程：

```sh
# 1) 先生成 native 归档和 cjpm 构建快照
cd runtime/cjgui/examples/tree_outline_consumer
zsh run.sh --build-only

# 2) 在 runner 生成的构建快照里跑测试（不是原始目录）
cd .cjgui/macos-build/application
cjpm test --skip-script
# 可按名过滤：
# cjpm test --skip-script --filter catalogRenamePatchesByKeyAndStructuralChangeRebuilds
```

证据：

- `MACOS_APPLICATION_HOST.md:84` 明确这条流程：“先 `./run.sh --build-only`，再在 `.cjgui/macos-build/application` 运行标准 `cjpm test --skip-script`（可加原 `--filter`）”。
- runner 的 `prepare` 对应用源码调用 `snapshot_sources(..., include_tests=True)`（`macos_build_config.py:197`），所以 `src/*_test.cj` 会进入测试可用的快照；框架自身源码默认排除测试（`macos_build_config.py:112-116`）。
- 快照里的 manifest 会把 FFI 路径改写到本应用私有 native 目录（`macos_build_config.py:200-207`），并用 runner 已验证的 native 归档链接；直接在原始目录裸跑 `cjpm test` 可能遇到 `./.cjgui/native/lib` 未生成或 build.cj 介入的问题，因此以快照为准。
- 同一 cjpm target 的 build/test 必须串行（`MACOS_APPLICATION_HOST.md:82`），不要和同一示例的 `run.sh` 同时跑。

### 6.4 新示例的测试清单

- [ ] 至少一个 `src/<topic>_test.cj`，同 `package`。
- [ ] import `std.unittest.*`、`std.unittest.testmacro.*`。
- [ ] 覆盖核心状态转移和至少一个拒绝/边界路径（照 `catalog_content_update_test.cj` 的“真实 dispatch 路径”而不是只测 getter）。
- [ ] 不新增 `[test]` 配置；不加第二个 `main()`。
- [ ] 用 `run.sh --build-only` 后的快照跑 `cjpm test --skip-script`，记录命令与结果。

## 7. 新建一个示例的最短文件清单

### 7.1 必须（4 个，缺一不可）

| # | 文件 | 一句话模板 |
| --- | --- | --- |
| 1 | `runtime/cjgui/examples/<name>/cjpm.toml` | 复制 §2.1；`name` 与 `package` 同名；`cjgui = { path = "../.." }`；保留 `link-option` 和两条 `[ffi.c]` |
| 2 | `runtime/cjgui/examples/<name>/src/main.cj` | `package <name>` + 控制器实现 5 个接口方法 + 顶层 `main(): Int64` 创建 `CjguiMacosApplicationHost`、`start()`、`while (isOpen()) pumpOneTurn()`、失败/结束 `close()` |
| 3 | `runtime/cjgui/examples/<name>/run.sh` | 7 行：`APP_DIR` 自定位；`CJGUI_ROOT="$APP_DIR/../.."`；`exec zsh "$CJGUI_ROOT/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "$@"`（可加 settings 的 `CJGUI_ROOT` 已存在则不覆盖判断） |
| 4 | `runtime/cjgui/examples/<name>/cjgui_macos_app.sh` | 只写配置：bundle/executable/identifier/display 四个名字 + `CJGUI_MACOS_APP_RESOURCES`（不用图片就 `()`） |

### 7.2 推荐（1 个）

| # | 文件 | 一句话模板 |
| --- | --- | --- |
| 5 | `runtime/cjgui/examples/<name>/src/<topic>_test.cj` | 同 package；`@Test` 覆盖核心状态转移与拒绝路径；用 runner 快照里的 `cjpm test --skip-script` 跑 |

### 7.3 按需（4 类，不要默认创建）

| # | 文件 | 什么时候要 |
| --- | --- | --- |
| 6 | `export_check/<name>_interaction_check.cj` | 仅当示例被加入导出 consumer 列表，并需要第 2b 步“导出后仍能交互”的证明；同 package、独立 `main()`、打印稳定 token |
| 7 | `verify_<fixture>.sh` | 仅当示例有环境变量 fixture/一次性验收；照 `verify_large_text_consumer.sh:9-17`：设变量 → 调 `run.sh` → grep READY/事实行；不要复制作者工具链绝对路径 |
| 8 | `cjpm.lock` | cjpm 生成、可提交；模板不带；不要手写 |
| 9 | `README.md` / `client.py` | 仅当示例有 descriptor/外部连接，或需要人读的接入说明；导出白名单会带上（`export_framework_preview.sh:182-183`） |

### 7.4 不要创建/提交

- `.cjgui/`（native 归档、fingerprint、bundle staging、`macos-build` 快照）：runner 生成，`.gitignore:51` 忽略。
- `build-script-cache/`：构建缓存，其 `bin/` 被 `.gitignore:37` 忽略。
- `target/`、`*.a`、`*.app/`：`.gitignore:36,40,45`。
- `native/Info.plist`：runner 自己生成（`run_macos_application.sh:300`），当前示例的 `native/Info.plist` 不在 runner 读取路径上。
- 作者机器的绝对路径（依赖、工具链默认值、资源路径）。

### 7.5 填空顺序

1. `mkdir -p runtime/cjgui/examples/<name>/src`
2. 写 `cjpm.toml`（先确认 `../..` 能解析到 `runtime/cjgui`，且 `name` 与 `package` 一致）。
3. 写 `src/main.cj`：`package`/imports → 控制器 5 方法 → `buildUi` 最小场景（一个 `vertical` + 一个按钮/文本）→ `applyUiEvent` 处理 27/28 → `main()` 宿主循环。
4. 复制 `run.sh` 和 `cjgui_macos_app.sh`，改 4 个名字；resources 不用就置空。
5. 加 `src/<topic>_test.cj`，至少一个 `@Test`。
6. 需要 fixture 再加 `verify_<fixture>.sh`；需要导出交互证明再加 `export_check/` 并改导出链。
7. 先 `zsh run.sh --build-only`，再在 `.cjgui/macos-build/application` 跑 `cjpm test --skip-script`；最后正常 `zsh run.sh` 看窗口/READY 输出。

## 8. 提交前自查（按此顺序）

- [ ] `cjpm.toml:10` 不是 `/Users/...` 绝对路径；是 `../..` 或模板占位符算出的相对路径。
- [ ] `cjpm.toml` 的 `name` 与 `src/*.cj` 的 `package` 一致；所有源文件/测试文件同 package。
- [ ] `link-option` 保留完整 4 个 framework + `-lobjc` + `-headerpad_max_install_names`。
- [ ] `[ffi.c]` 两条都在，路径是 `./.cjgui/native/lib`。
- [ ] 控制器实现 `uiSceneVersion`/`buildUi`/`applyUiEvent`/`rejectUiEvent`/`requestWindowClose` 五方法（接口 `composable_ui_window.cj:734-747`）。
- [ ] 任何可见状态变化都递增 `uiSceneVersion`（或等价 revision）。
- [ ] `applyUiEvent` 只在状态改变时返回 `didApply=true`；`requestWindowClose` 返回 `shouldClose: true`。
- [ ] `main` 是顶层 `main(): Int64`（若要被导出链 2b 复用，保持无参、无 `func`）。
- [ ] `run.sh` 的 `CJGUI_ROOT` 指向 framework 根（examples/<name> 为 `../..`），且 `exec` 的是 `scripts/run_macos_application.sh`。
- [ ] `cjgui_macos_app.sh` 设置 4 个必填变量；resources 路径用 `$CJGUI_RUNTIME_DIR` 或 bundle basename。
- [ ] 测试文件在 `src/*_test.cj`，没有 `[test]` 配置，没有额外 `main`。
- [ ] 没有提交 `.cjgui/`、`target/`、`build-script-cache/`、`*.a`、`*.app/`。
- [ ] 验收脚本里的工具链/资源默认值不是作者机器绝对路径。

## 9. 快照、范围与局限

- 任务快照：HEAD `dc27dff`，247 条未提交改动，`2026-10-21T07:40:16Z`。写入前复查 worktree 为 248 条（并行改动落在其他文件）；本文件引用的 `tree_outline_consumer` 目录在该复查中仍是干净的，行号未变。**提交后这些数字与行号都会变**，以新快照重查。
- 示例实际路径是 `runtime/cjgui/examples/tree_outline_consumer`；任务描述里的 `examples/tree_outline_consumer` 少了 `runtime/cjgui/` 前缀，本文按实际路径引用。
- 本文是纯静态规格：没有构建、没有测试、没有启动应用；第 6.3 节命令来自 `MACOS_APPLICATION_HOST.md:84`，不是本轮执行结果。
- `settings_form_window_app/` 在该快照中是未跟踪目录（`git status` 显示 `??`），因此它作为“正确相对路径”的参照是工作区事实，不是已提交历史；提交后需重新确认。
- 行号以本快照的工作区为准；`docs/plans/` 与 `docs/archive/` 未读取。
