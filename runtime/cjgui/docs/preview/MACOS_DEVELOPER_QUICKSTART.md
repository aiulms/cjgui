# CJGUI macOS 开发预览

这是 experimental 源码开发包，面向 Apple Silicon（arm64）macOS。需要自行安装 **Cangjie 1.1.3 cjnative、Xcode Command Line Tools 和 Python 3.11+（本轮3.14，使用标准库 tomllib）**；`xcrun` 应能找到有效的 macOS SDK。runner 声明最低部署目标12.0，实际交付只按本次宿主系统验收，未验证全部旧版macOS。包中没有整套SDK或预编译CJO／BC／对象。

解压后在本目录打开终端，创建自己的应用（父目录须存在、目的目录须不存在）：

```sh
export CANGJIE_HOME="/你的工具链/cangjie-1.1.3"
zsh framework/cjgui/scripts/create_macos_application.sh mixed-form "../My Print Tool"
cd "../My Print Tool"
./run.sh --commands
# 只构建：./run.sh --build-only
```

`run.sh` 从相对path依赖指向的本包构建框架、shared core和原生实现，日志中的 `source_origin` 给出实际输入。首次构建才生成缓存，不需要作者工作区。不要继承其他项目的 `CJGUI_NATIVE_SOURCE_DIR` 覆盖；需要时可显式设置 `CJ_GUI_SDKROOT` 选择自己的系统SDK。重建需要SDK；完成的 `target/release/CJGUIMixedFormStarter.app` 已携带两项Cangjie运行库，可以直接打开，无需源码包或SDK。该App仅本机ad-hoc签名，未公证，不是正式发行安装包。

### 升级已有应用（同一出口的增量替换）

升级 = 把应用指向新的源码包，保留业务源码。不要用新模板重建应用：

1. 解压新包（与旧包并存），只修改应用 `cjpm.toml` 的 `cjgui` /
   `cjgui_shared_operation_core` 两条 path 依赖，以及 `run.sh` 里的框架根目录；
2. `./run.sh --build-only`，然后正常启动完成一次编辑与读回；
3. 其余源码无需改动。

一处有意的源码契约收紧（复合组件工厂）：字段元素上挂载的**可编辑控件**
必须把框架给出的 `ownerAvailable` 传给 `enabled`（文本框同样如此）：

```cangjie
cjguiComposableTextInput(field.nodeId, field.semanticId, field.label, field.draftText,
    field.bindingResourceId, style, enabled: field.ownerAvailable, fieldId: field.fieldId,
    operationActionName: field.writerOperation, operationResourceId: field.ownerTargetResourceId)
```

否则当 owner 已禁止编辑时，接受阶段会以
`composite_element_availability_mismatch` 拒绝该场景，而不是展示一个看起来可写、
写入必然被拒的控件。只读副本（普通文本节点）不受此限，不需要禁用。

本版 SDK 的交付闭包由 `source-lock.json`（format 2）冻结：共同源、native `.m/.h`、
`build.cj`、脚本、配置、模板与资产逐项记录原始 SHA-256；仅 `.cj` 的旧扁平锁仍可按
原有方式使用（兼容保留）。用同一锁再次导出会得到逐字节一致的内容；任一输入漂移
（包括 native 或脚本先行变化）会在写盘前具名拒绝。

普通入口自行固定本应用的 native 归档，不写框架共享缓存；无需运行历史验收中的私有重链脚本。`.cjgui/macos-build` 是按内容复用的只读仓颉编译输入与配置，源码仍从本包修改；`build-provenance.json` 记录实际 linker 消费、SDK/宏/归档身份。相同应用／target 的 build/test 仍须串行。

默认编辑左侧手写区，无需连接或模型。点击“开启本地协作”后，当前终端输出 `DESCRIPTOR_PATH`；只在本次私有本地会话使用。另一个终端进入应用目录：

```sh
python3 client.py DESCRIPTOR inspect
python3 client.py DESCRIPTOR generate
python3 client.py DESCRIPTOR set --field copies --value 6
python3 client.py DESCRIPTOR read
# 人可继续编辑任一投影，再读回；Apply或⌘S显式提交
python3 client.py DESCRIPTOR apply
```

手写、运行时生成、外部读写都使用同一份字段、动作和业务owner；打印预设值只在内存中，退出后重置。连接关闭后descriptor失效。这些是真实公共客户端调用，未包含真实模型服务、另一套协议或业务存储。

组合模式的工具栏、⌘P面板、操作按钮的右键及原生菜单复用同一命令声明；Apply／⌘S、Reset／⌘R
仍操作原表单 owner。⌘T 切主题，enabled／checked／字段帮助及错误反馈来自各自原声明。
份数滑块、布尔、公共 PNG、字距／行高和只读文本省略均可与生成字段组合；完整业务值不被截断。
公开修改后，人可直接继续原字段输入，再用 `client.py read` 精读。`client.py reorder` 调整已接受生成结构，
`client.py check-refusal` 核对 typed 拒绝而不改 owner。

字体资源可选入口为 `./run.sh --fonts`：同字段手写/生成使用两份已登记字体；
`client.py DESCRIPTOR inspect` 公开实际资源状态，`font-switch --font-resource preview-serif` 或 `preview-mono`
切换生成结构引用，仍用原 writer。字体和许可证随普通 bundle/源码包携带，相对资源定位不依赖作者路径。
完整声明、失败回退和生命周期见 [公共字体资源](framework/cjgui/FONT_RESOURCES.md)。默认旧模式不加载字体。

`./run.sh --styled-text` 在同一字体入口上消费多样式说明，按实际字体和字号自动计算高度、换行及末行省略。
`client.py DESCRIPTOR styled-generate` 使用同一 `assets/styled-description.tsv`；`styled-color`、`styled-size`、`styled-font-current` 修改既有声明。完整契约见[公共多样式文本](framework/cjgui/STYLED_TEXT.md)。

其他起点：把创建命令中的 `mixed-form` 换成 `ui-only`、`command-surface` 或 `collaboration`。
`ui-only` 是原纯本地入口，`command-surface` 是独立公共命令入门，`collaboration` 是原可选协作骨架。
mixed-form 不传 `--commands` 仍是原简洁手写表单。各模板默认均不开外部连接；不使用协作时无需Python客户端。

mixed-form 使用公共 Wrap、整数步进和状态反馈；字段标签、范围及 writer 来自 `src/domain.cj` 的同一声明。更换字段名、范围、动作或显示标签时修改应用声明和自己的业务操作，`src/main.cj` 按声明画字段，`client.py` 按实际目录发现，不需要改 native。按⌘K打开说明，Esc回到原字段／选区；⌘S只应用内存草稿，不保存文件。

Inspector 默认关闭，点击“开发：Inspector”才打开同一应用的只读副窗。普通运行不依赖它。示例不持续采样成本，需要诊断时显式使用 `inspector.open(collectCosts: true)`，关闭由原生命周期恢复。

集合／键盘示例已经随包放在 `consumers/generated_collection`：

```sh
cd consumers/generated_collection
./run.sh
# 该独立演示会输出本地 descriptor；另一终端：
python3 client.py inspect --descriptor DESCRIPTOR
python3 client.py keyboard --descriptor DESCRIPTOR
python3 client.py keyboard-rearrange --descriptor DESCRIPTOR
```

它直接引用本包的框架和 `framework/rule_set_application`。示例保留原有可选检查入口，不必重跑历史整套验收。[集合用法](consumers/generated_collection/README.md)、[布局](framework/cjgui/LAYOUT_PRIMITIVES.md)、[字段与反馈](framework/cjgui/FIELD_CONTROLS.md)。

打开已有规则文件时，可进入 `consumers/rule_set_window_app` 运行 `./run.sh --open ./existing-rules.cjgui-rules`，再通过界面保存；相对路径由现有 owner 解析为同一绝对目标。该消费者包含列表／表格／卡片、窄窗布局与生成字段，仍直接消费本包公共组件。它与上面的内存打印模板用途不同。

作者端需要冻结一次已接纳的源码集合时，正式导出入口支持 `--source-lock JSON`（相对 framework 根的 `.cj` 路径到 SHA256 的映射）：已选源码漂移会拒绝发布，后来新增叶子不自动吸入；默认导出仍包含当前生产源。锁文件随候选保存，不成为创建／运行应用的额外依赖。

锁集合须覆盖本包发布模板的普通仓颉源；缺少模板主文件或辅助模块会明确拒绝导出，避免交付无法建项的空壳。
模板测试源可不纳入锁集合。导出不包含 target、native/lib、旧 artifacts 或预置编译缓存。

改业务与布局见 [混合表单一页接入](framework/cjgui/templates/macos_application/mixed_form/README.md)，宿主生命周期与打包配置见 [macOS应用宿主](framework/cjgui/MACOS_APPLICATION_HOST.md)。[本次候选说明](MACOS-CANDIDATE.md)、[包内容说明](preview-manifest.md) 与 `source-manifest.json` 记录支持边界和实际导出身份。所有新增API为experimental；实际VoiceOver仍未验，其他平台、全IME／严格性能及旧native harness失败独立保留，不能由本包建项成功推定通过。

本包包含当前表单反馈：手写／生成区的错误与 Apply 状态来自同一 owner 快照；typed client 的 `form_state()`（`client.py read`）直接提供合法／非法／未知、原错误、版本和动作原因，`cancel` 使用原还原动作。非法草稿可保留并修正，不把“可编辑”当成“校验通过”。
