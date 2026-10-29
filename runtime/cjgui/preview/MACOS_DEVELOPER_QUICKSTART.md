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

### DS49 公共能力（本包新增）

- **多定义一次候选**：一个候选可同时新增/替换多个完整组合定义，每个定义有自己的
  `COMPOSITION_END`；端点通过 catalog 发布 `COMPOSITION_BUDGET`（本版
  definitions=8、elements=96、template_nodes=256、bytes=262144）。任何一段非法都整批
  零发布，未提及的定义保留，删除需显式 `COMPOSITION_REMOVE`。
- **界面文档**：`python3 cjgui_generated_edit.py DESCRIPTOR ui-export FILE` 导出
  `cjgui.ui-document` v1；`ui-import FILE --save-import-plan P` 在当前端点重新发现与
  校验并生成计划；`ui-apply P` 用原候选票据执行。应用可用
  `./run.sh --ui-document FILE` 从已保存界面启动（当前 catalog 重新校验，失败保留默认界面）。
  保存计划按严格 JSON 类型解析，并按当前端点、accepted 版本与完整摘要重建预览；
  端点/基线/候选/diff 任一不符即具名拒绝且零提交，合法旧计划继续可执行。
- **窗口内文档工作流（experimental）**：`CjguiGeneratedUiDocumentSession` 提供
  保存界面、预览载入、确认载入、取消预览、恢复已存界面五项普通命令；mixed 与 rules
  正常窗口都有可见按钮/菜单。保存只写已接受结构，预览不提交，确认复用同一预览的
  基线与 CAS，恢复重读文件而不重放 ticket；业务草稿/Apply/Cancel 仍归原 owner。
- **工作区组件**：应用可显式注册 Tabs/tabPage、ScrollArea、Split、Image，复用已有
  presentation 与属性规格，表单默认词汇保持轻量。
- **多对象接入**：`CjguiGeneratedUiMultiObjectBinding` 只按声明的实例 key 解析应用自己的
  对象，并用 frozen owner target/incarnation 拒绝迟到事件；业务 owner、授权和持久化仍归应用。
  mixed 的卡片集合与 rules 的规则记录都实际构造该适配，不再维护第二套多对象 provider；
  手写、生成和外部入口共用同一 owner 草稿。

### 公共文档生命周期与完整读回（§17）

Rules 与 mixed 建项模板使用同一 session/workspace/close guard。应用只在启动调用
documentWorkspace.beginStartup(path)，在普通 turn 调用 finish()，关闭仍交原 guard；
startupPending()/startupResult() 读取同一操作的准确结果。关闭先结算不会丢终态；
UNKNOWN 仍待定，接受后又变更不采用旧文件基线，忙时不接管新操作。合法空文件
可以直接采用而不提交候选，不能把 submitted=false 当成拒绝。旧 manual/scoped 接入
保持兼容，正常窗口支持范围仍为本包的 macOS 参考实现，API 为 experimental。

client.py 的 read --instance KEY / read --owner ID 直接使用 typed 查询，保留完整
form_state、逐字段 owner、draft/applied、版本、可用性和拒绝/校验原因。缺失正文或
版本为 null；未发布的 owner 仍为 -1，不从别的层级猜值。同名字段在不同 owner 下
分别保留，读取不会执行业务修改。

开发者仍写真实领域的草稿、Apply/Cancel、版本和持久化；字段/范围/绑定只维护一份，
手写控件、生成实例与公开写入共同使用。例如只把 domain.cj 中 copies 的 maximum
从24改48，校验和两种界面都消费新范围；布局只替换 main.cj 的公共容器/子节点。
无需复制启动票据观察者、版本下界或另一份关闭结算。mixed 的界面文件不保存其内存
打印预设；重开进程建立新的默认业务值。

### DS51 正常入口与界面文件（本包更新）

三个现成入口都从本包直接运行：

- **mixed-form（空区开始）**：创建后不预置界面文档，空区可见；`python3 client.py DESCRIPTOR generate` 由真实 catalog 生成图像、字段和 Select，A/B 两个 owner 复用同一运行时定义。窗口内同时挂载“主详情布局”和“辅助摘要布局”两个独立工作区：各自有真实 Surface、session 和界面文件关联，命令由作用域身份派生，交换位置或重建不会串写。
- **ui-only**：原纯本地入口，不挂载文档工作区，也不产生文件状态或后台任务。
- **已有规则消费者**：`consumers/rule_set_window_app` 以 `./run.sh --open ./existing-rules.cjgui-rules` 打开业务文件；列表/表格/卡片和生成字段共用同一公共工作区。

界面文件工作流不依赖启动参数：路径输入、打开、另存始终可见。空路径保存具名拒绝 `ui_document_path_empty`；另存到新文件使用不覆盖发布，当前文件走与普通保存相同的冲突检查，其他已存在目标具名拒绝 `ui_document_save_as_target_exists`。外部改写后保存得到 `ui_document_save_conflict` 并保留外部字节；无变化预览只绑定文件、零提交，merge/替换载入在显式保存前保持 dirty。

业务保存与界面文件保存是两件事：⌘S/Apply 只提交业务 owner，界面按钮只写已接受结构（`cjgui.ui-document` v1）；任一保存成功不掩盖另一方未保存。两个消费者的系统关闭按钮、⌘W 和⌘Q 都先询问全部工作区：未保存界面时显示“保存界面 / 放弃本次界面改动 / 取消关闭”，保存界面不会 Apply 或保存业务草稿，放弃界面也不会丢业务内容，在途票据仍拒绝退出；取消后可继续编辑。删除对象后旧视图读写被拒绝，剩余对象继续可用。完整说明见 `framework/cjgui/README.md` 的 DS51 段。

### DS52 可事务化集合挂载与公共集合工作区（本包新增）

- **挂载生命周期归 holder 接受事务**：候选和普通接受渲染只准备独立的 viewport/几何；
  `commitCandidateRefresh` / `settleAcceptedRenderViewState` 才发布，
  `rollbackCandidateRefresh` / `discardSceneViewState` 只丢本次 staging，
  `disposeViewState` 释放本 holder。最后一个实例删除、整区释放、同 key 换 kind 都在 commit
  按接受结构对账退休；被拒候选不改变旧句柄的 offset/几何。直接 `buildComposite`（无 holder
  事务）保持旧的立即发布语义。
- **公共入口** `CjguiCollectionWorkspace(collection, viewState, scope, modePresentations: ...)`：
  - `projectBusinessQuery`/`projectBusinessSort`/`toggleSort`：业务视图是同一个 TableSource
    事实的单一投影入口；
  - `encodedSnapshot`/`restoreEncoded`/`resetView`：只含 mode/query/sort/columns，复用
    `CjguiComposableUiCollectionViewCodec`；非法快照整段拒绝保旧，未知列忽略、缺失列补齐、
    被删排序列清空；不含业务记录、选择、指针捕获或未提交候选；
  - `reveal` / `revealIn(scope, instanceKey, key)`：只移动一个具名 accepted mount，缺失或
    已退休拒绝，不回退到“最后构建/全部挂载”；
  - `setMode` 只切视图 token；mode→声明 presentation 由应用 `modePresentations` 提供，仍走
    普通候选，不存在隐藏模式；
  - `commandDeclarations(savedSnapshot)`/`ownsCommand`/`buildStatusLine`：命令 id 由 canonical
    scope 派生，两个挂载/两个工作区不共享；restore 的可用性来自真实已保存快照。
- **真实变高**：mixed 的列表行按标题实际换行测量（窄窗可见长短行不同高度），表格保持固定
  行高；列表与表格同源同时挂载，各自 viewport/offset。
- **生成集合的键盘/选择/reveal（§13）**：用手写或生成的 `CjguiGeneratedUiCollection` 挂载，
  按键事件携带该挂载的 **viewport 对象**；由 holder/region 或
  `collection.acceptedViewForViewport(event.node.scrollViewport)` 解析出 accepted view，再调用
  `cjguiNavigateGeneratedCollection(collection, view, event, window)`。旧代、非 accepted、
  外来 viewport 一律不处理；reveal 用该挂载 measured rows，只移动活动挂载。同一 collection
  的列表/表格共享数据与选择，但 viewport/offset 独立。scope-only `acceptedView` 在多个
  holder 使用同一局部 scope/key 时返回 None，调用方应改用
  `acceptedView(scope, instanceKey, holderIdentity)`（holder/region 已封装）。窗口命令/列控制使用
  `workspace.buildActionBar` 与 `workspace.buildColumnEditor`，事件经
  `actionForEvent`/`applyColumnEvent` 回到同一 scope 的 workspace；持久化由应用回调提供。

- **JPEG 与图片资源（§14）**：普通 `cjguiComposableImage` 接受 bundle 相对 PNG/JPEG；
  注册式资源用 `CjguiGeneratedUiImageResourceSpec(key, "PNG"|"JPEG", version, name, relativePath)`
  + `catalog.registerImageResource`，手写显示调用 `cjguiComposableImageResource(...)`，
  生成结构用同一 `resource`/`resourceVersion` 属性；运行时改资源引用走普通候选/UI 文档，
  同 key 同版本不得改指向，错误版本和损坏字节整段拒绝/失败，合法图片继续可用。
  资产在 `cjgui_macos_app.sh` 的 `CJGUI_MACOS_APP_RESOURCES` 声明，构建时进入
  `Contents/Resources`；不要在源码里写绝对路径。PNG/JPEG 之外的格式、拖放/剪贴板、
  SVG、动画与色彩管理不承诺。
- **应用退出（§14 A4）**：多窗口 `CjguiMacosApplication` 用
  `exitDecisionProvider` 逐个咨询存活窗口的既有关闭决策，任一拒绝则应用退出返回 false，
  不先关闭任何窗口；取消后继续使用。示例：
  ```cangjie
  class ExitDecision <: CjguiMacosApplicationExitDecisionProvider {
      let controllers: ArrayList<MyController>
      func requestApplicationExit(): Bool {
          for (controller in controllers) {
              if (controller.isWindowOpen() &&
                  !controller.requestWindowClose().shouldClose) { return false }
          }
          return true
      }
  }
  let app = CjguiMacosApplication(maximumWindowCount: 2,
      exitDecisionProvider: ExitDecision(controllers))
  ```
  其中 `MyController.requestWindowClose()` 是消费者**既有的关闭决策入口**；它只返回
  `shouldClose`，不会关闭窗口。真正的窗口关闭由 application 在全部允许后统一执行。

- **仍未验/未完成**：其他平台、严格性能、完整 IME/VoiceOver；原速（0µs）HID 输入分歧仍未
  归因——本包记录只证明 0µs 自有通道大量未到 native、2ms 通道立即另存 3/3 完整，原件
  “AX 全串→另存少尾两字”未重现；需要 native 收文事实才能完成归属。运行中准备的源不作为
  本包基线。

自验入口（在 `framework/cjgui` 内）：

```sh
python3 -m unittest discover -s shared_operation_core -p 'test_*.py'
cd examples/rule_set_application && cjpm test
```

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

生成界面的保存计划、跨进程应用、拒绝保旧与恢复见 `framework/cjgui/shared_operation_core/GENERATED_EDITING.md`；
同目录 `example_generated_edit.py` 提供可直接调用的入口。

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
