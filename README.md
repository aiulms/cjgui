# CJGUI

**用仓颉写界面，让人和 Agent 直接操作同一份应用。**

CJGUI 是面向 macOS 与鸿蒙的自绘 GUI 框架。用仓颉定义组件、布局和业务状态，以自绘、排版缓存和虚拟列表减少编辑与滚动中的重复工作。

窗口与 Agent 共用字段、规则和动作。Agent 可以读取当前选择、修改应用数据，也可以在运行中组合表单和面板；人随后继续在窗口里操作。

[开始使用](#运行一个窗口) · [创建应用](#创建自己的应用) · [鸿蒙支持](#macos-与鸿蒙) · [开发文档](runtime/cjgui/README.md)

<sub>开发预览 · macOS / Apple Silicon 优先 · 鸿蒙模拟器预览 · Apache 2.0</sub>

## 看一次接续编辑

在窗口里写一段文字，通过公开接口追加内容，再回到窗口继续写。三个步骤读写同一份文档，修改直接出现在编辑区。

![窗口编辑、公开接口追加、回到窗口续写的 26 秒实录](https://raw.githubusercontent.com/aiulms/cjgui/main/docs/assets/demo/cjgui-shared-document-real-demo.gif)

<sub>26 秒实录，外部操作由脚本调用公开接口。[观看 MP4](docs/assets/demo/cjgui-shared-document-real-demo.mp4) · [截图与录制说明](docs/assets/demo/README.md)</sub>

## 为什么这样设计

### 窗口和 Agent 共用业务规则

以规则编辑器为例：人在窗口里修改记录，Agent 读取当前选择并批量修改，随后人继续检查和编辑。双方操作同一份数据，字段校验、授权和版本冲突由应用与框架统一处理。

字段的类型、必填、长度限制和写入动作由应用声明。手写表单、生成表单和外部查询读取这份声明；生成控件的修改仍交给该字段的业务处理器。[字段与操作接入](runtime/cjgui/README.md#运行时生成式接入experimental已接通公开闭环)

### 界面可以在运行中调整

手写主窗口旁边，可以留出一块生成区：Agent 根据应用提供的组件、字段、样式和动作提交面板结构，框架将它显示在窗口里。生成控件直接使用应用的数据绑定。

调整结构时，同 key 的控件可以接续草稿；结构不合法时保留原界面。移除生成区后，人仍能继续操作手写控件。[生成接口与示例](runtime/cjgui/README.md#运行时生成式接入experimental已接通公开闭环)

### 用仓颉组织 UI，复用到桌面与鸿蒙

组件树、布局、场景和业务逻辑由仓颉维护，平台后端接入窗口、绘制与系统输入。macOS 使用 AppKit / Metal；鸿蒙使用 ArkTS 薄宿主、XComponent / OH_Drawing。设置和温控示例已把共享仓颉核心带进鸿蒙 HAP。

应用可以从普通 UI 模板开始，再按需开放共同操作和界面生成。模型、Agent 和交互方式由应用开发者选择。[应用模板](runtime/cjgui/MACOS_APPLICATION_HOST.md) · [鸿蒙后端](runtime/cjgui/platforms/ohos/README.md)

### 编辑和滚动复用已有资源

改动一段正文时，复用仍有效的排版与纹理；滚动大列表时，按视口创建条目。图片按身份和版本缓存，动效结束后停止持续提交。

已有 3700 行混合文本的双窗口局部修改、滚动和接续编辑测量；PNG 传递、效果与连续平移也已有 macOS 应用验证。[文字性能记录](docs/plans/2026-09-23-incremental-text-style-binding-milestone.md) · [局部刷新记录](docs/plans/2026-09-26-framework-capability-roadmap.md#f-local-refresh-next)

## macOS 与鸿蒙

| | macOS / Apple Silicon | 鸿蒙 / 华为模拟器 |
| --- | --- | --- |
| 绘制 | AppKit 窗口、Metal 自绘合成 | XComponent、OH_Drawing 自绘 |
| 已可试用 | 多窗口、文字编辑、生成界面、共同操作、PNG 传递、主题、效果与连续平移 | 设置与温控 HAP 的触摸、系统字段编辑、生成面板、共享图片和共同操作 |
| 从哪里开始 | [文档窗口](runtime/cjgui/examples/shared_document_window_app/) · [规则编辑器](runtime/cjgui/examples/rule_set_window_app/) | [设置应用](labs/ohos_cjgui_app/) · [温控应用](labs/ohos_thermo_app/) |

鸿蒙已在两款 HAP 中验证外部提交界面、系统输入、应用数据读回和继续编辑。手写区域与生成区域使用同一套组件和业务绑定。[平台构建与部署](runtime/cjgui/platforms/ohos/README.md)

<details>
<summary>开发预览的范围</summary>

公共 API 仍为 experimental。当前可用范围和正在推进的工作见 [开发动态](runtime/cjgui/ACTIVE_DIRECTION.md)。

- macOS 的编辑器持续输入与统一位置机制仍在完善；完整 VoiceOver 操作和物理跨屏表现仍待验。
- 鸿蒙的小文档编辑器与可中断惯性滚动仍在汇合；当前 SDK / 镜像 / 输入法组合的 marked range 与取消回调待验。模拟器记录的适用范围限于模拟器，真机性能与发布审核另行验证。
- macOS PNG 交换支持静态、非交错的 8-bit RGB/RGBA 子集。局部刷新复用排版、纹理与场景资源，Metal 主绘制路径仍提交完整帧。

</details>

## 运行一个窗口

准备 macOS / Apple Silicon、仓颉 1.1.3 和 Xcode Command Line Tools。将 SDK 路径替换为你的安装目录：

```sh
export CANGJIE_HOME=/absolute/path/to/cangjie-1.1.3
source "$CANGJIE_HOME/envsetup.sh"

git clone https://gitcode.com/aiulms/cjgui.git
cd cjgui
zsh runtime/cjgui/examples/rule_set_window_app/run.sh
```

最后一条命令启动规则编辑器；追加 `--build-only` 可只构建。要试用上面的文档窗口，运行 `zsh runtime/cjgui/examples/shared_document_window_app/run.sh`。

runner 负责平台桥接构建和应用 bundle。[环境与打包说明](runtime/cjgui/MACOS_APPLICATION_HOST.md) · [工具链问题](docs/setup/CANGJIE_ISSUE_LEDGER.md)

## 创建自己的应用

沿用上面的工具链环境，在仓库根目录执行：

```sh
zsh runtime/cjgui/scripts/create_macos_application.sh ui-only /tmp/MyCJGUIApp
zsh /tmp/MyCJGUIApp/run.sh
```

`ui-only` 创建普通 UI 应用。需要共同操作入口时，换成 `collaboration` 并使用另一个新目录。界面和业务动作由仓颉 controller 定义，框架 runner 管理构建与打包。

[模板与资源指南](runtime/cjgui/MACOS_APPLICATION_HOST.md) · [公开客户端：授权、读取与调用](runtime/cjgui/shared_operation_core/README.md)

## 文档与贡献

- [开发文档](runtime/cjgui/README.md)：组件、布局、输入、生成界面与渲染。
- [共同操作设计](docs/core/AI_NATIVE_UI_SEMANTICS.md)：字段、上下文、动作和授权。
- [开发动态](runtime/cjgui/ACTIVE_DIRECTION.md) · [设计导航](docs/plans/DESIGN_INTENT_INDEX.md) · [完整文档目录](docs/README.md)。
- [初赛材料](docs/contest/2026-10-07/README.md)：项目提案、验证、查重与演示。
- [协作规则](AGENTS.md) · [问题反馈](docs/setup/CANGJIE_ISSUE_LEDGER.md)。

## 许可证

[Apache License 2.0](LICENSE) · Copyright 2026 CJGUI contributors · [NOTICE](NOTICE)

原创代码、文档和原创资源采用 Apache 2.0；第三方软件与平台 SDK 保持各自许可证。
