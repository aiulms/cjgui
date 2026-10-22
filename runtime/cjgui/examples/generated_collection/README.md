# 公共集合的手写／生成共同接入（experimental）

macOS 薄消费者；业务直接使用 `rule_set_application` 的现有 owner、草稿、动作与读取接口，不复制规则或保存引擎。初始手写列表和外部生成列表／表格调用同一个 `CjguiGeneratedUiCollection` 声明。注册的列、表格排序／筛选、稳定 key 选择仍使用现有公共组件。

```sh
source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
./run.sh --build-only
./run.sh
# 另一个终端，使用上方 COLLECTION_READY 输出的 descriptor：
python3 client.py inspect --descriptor /实际/descriptor
python3 client.py list --descriptor /实际/descriptor
python3 client.py table --descriptor /实际/descriptor
python3 client.py rearrange --descriptor /实际/descriptor
python3 client.py reject --descriptor /实际/descriptor
python3 client.py read --descriptor /实际/descriptor
```

窗口中点击记录，使用筛选和排序按钮；在右侧编辑名称。外部切换 `records` 同 key 的 list/table 或重排 shell 后，选择、查询、排序和未提交草稿继续存在；点击“应用草稿”仍进入同一个业务 owner。客户端沿用公共能力目录、候选提交／接受、字段及实例读回，无新增 RPC。

公共接入：

```cangjie
let collection = CjguiGeneratedUiCollection("rules", "ruleCollection", rows, table, selection)
let _ = collection.register(catalog)
// 手写：collection.buildNode(viewportId, viewportSemanticId, contentId,
//                           contentSemanticId, "list", style)
// 生成：kind=ruleCollection，collection=rules，presentation=list 或 table
```

应用只注册编译好的 Cangjie source、TableSource（含列／既有动作）和 CollectionSelection。描述不能提供行数据、源码、文件路径、native 指针或权限；未知 kind、未注册 collection、非法 presentation 在候选校验时拒绝，保留旧结构。标量属性的 `values` 枚举由共同 validator 强制执行；有 `encoding` 的结构化 token 继续使用原有 grammar。

构建只生成投影：不设置查询、排序、selection，不执行 Apply/Cancel；候选和 accepted 继续使用现有 holder 与窗口事务。每次投影的测量状态是私有派生值，viewport 使用现有几何提交协议。表头复用 TableSource.buildHeader，作为首条虚拟行，随内容滚动。行由原有有限物化器创建，不预建全部 80 条 UI 节点；源查询／筛选／排序的现有成本边界不变。

每个注册集合使用自身已声明的行身份空间；同时挂载多个视图时应注册各自 scoped source/table，选择对象可按应用意图共享。同 key 改绑另一注册集合，使用新声明的 selection/viewport，不从旧投影搬用状态。首版没有固定表头、表格单元格编辑、多列排序、拖放、持久化或新的集合 RPC。

实际验收为 macOS／Metal／合成原始键鼠事件；其他平台只有共同仓颉源码，未运行，不宣称支持已验。无真人物理输入或 IME、严格性能、GiB、包外重新验收。现有开发源码包 `0654927a...` 不包含本能力；下次分发需纳入本 adapter、枚举校验、消费者和普通构建配置修正。

本例 `target/release/bin/main --check` 是有限无窗口检查入口：注册引用拒绝、保旧、候选回滚、同 key 切换、不同集合重绑、零行预物化。正常交互证据及精确编译输入见 E 当前 RESULT。

## 公共轻量 Inspector（experimental / macOS）

本例默认关闭；点击“开发：Inspector”打开同一应用宿主的只读副窗。搜索 semantic/identity/field/action，选择节点可查看身份、真实父级／深度、已接受几何和裁剪、必要样式与绑定，并在业务窗口画框。点击“刷新”取当前第一页，“下一页”沿同一 session/accepted 版本读取；缺祖先时明确标记不完整树。冻结只锁读数，源场景变化仍显示 STALE；旧快照不能重新框到其他节点，刷新后需重新选择。关闭副窗不关闭业务窗，也不修改业务 owner、草稿或选择。

应用复用现有 `CjguiMacosApplication`，只提供被检查窗口的 opaque identifier：

```cangjie
let inspector = CjguiMacosInspector(application, businessWindowIdentifier)
// UI 动作只记请求；在现有 application.pumpOneTurn() 返回后处理：
let result = inspector.open(collectCosts: true)
// 原应用循环内做生命周期回收，不会采样：
inspector.synchronizeLifetime()
// finally：
inspector.close()
```

需要使用已有调试窗口的开发者也可消费公共 `CjguiComposableUiInspectorPanel`；它是普通 controller，不含规则集领域逻辑。副窗由既有应用窗口生命周期维护，未增加 IPC、Inspector server、窗口管理器或外部框架依赖。

快照取自原 `diagnosticSnapshot`，每页最多128节点，仅已物化且和视口相交的 accepted 投影。层级来自 accepted preorder/subtree span，未用矩形猜树；元数据不复制业务正文、标签值或草稿。仅显式打开／刷新／翻页取快照。源窗口 accepted version 的纯标量用于将保留读数标旧，不进行周期诊断／GPU采样；面板自身重绘不会采样自己或引发业务重绘。

CPU 显示最近刷新尝试的 build/layout/nativeStageAndSubmit；GPU 显示已完成 frame 的 duration；资源显示现有累计计数及当时的字节快照。accepted/submitted/completed 标识分别列出，不拼成同帧耗时、不相加，也不代表物理上屏。-1 显示 unavailable，0 保留为实测零；默认未开启的额外工作量字段不会冒充零。

`CjguiComposableUiDiagnosticOverlayOptions` 增加可选 session/accepted 版本及 ownerKey。旧构造默认保持原无固定版本行为；Inspector 使用固定版本，场景变化自动撤框，`clearDiagnosticOverlay(ownerKey)` 仅能清自己的层。新增诊断字段均为可选构造参数，原消费者源码保持兼容。

范围为 macOS 的正常副窗／Metal 叠加。未做全局鼠标拾取、持续录制、瀑布图、计数器采样器、物理上屏延迟、其他平台／IME／VoiceOver／严格性能。旧0654927a开发包不包含集合或Inspector能力，本轮只交当前源和可启动候选，不更新大分发包。

`collectCosts` 默认false，只显示当前已有数据；true临时启用窗口现有workload/timing采集门，业务下一次刷新后可见CPU阶段，关闭时在同一session恢复原开关。不强制刷新业务，不创建新计时器；同一业务窗口使用一个Inspector接线对象。配置门与样本是否available分开，读取原设置不会把未就绪的样本误认为关闭。

## 普通键盘、焦点与屏幕阅读器消费（macOS）

初始 Tab／Shift+Tab 从自绘窗口进入既有声明顺序，跳过禁用控件。公共 `cjguiNavigateGeneratedCollection(collection, event, window)` 复用 `CollectionSelection.navigate`，应用再经原 owner 选择该记录；FOCUS只更新现有逻辑焦点，不成为第二次点击或业务写入。结果分开 `isHandled`、逻辑变化 `didChange` 和显示／作用域焦点接受 `didAcceptViewFocus`；未知命令不写状态，边界键仍能显示独立滚动后藏住的焦点项。`cjguiRevealGeneratedCollectionFocus` 用同一集合的真实 source key、已接受稀疏测量和 viewport 显示焦点项，并把键盘留在该滚动作用域；应用不计算像素偏移或复制行 key 编码。

通用窗口入口 `revealVirtualListItem(semanticId, itemKey, viewport)` 也可用于其他虚拟列表，必须匹配已接受列表的 viewport；未知节点／key／不同 viewport 返回false。它表示显示请求已接受，实际画面随下一次正常提交更新，不是上屏证明。

右侧名称和布尔字段仍使用同一个公共表单绑定。名称编辑时按⌘K打开已有 dialog layer，“返回编辑”或Esc由公共模态书签恢复原字段和选区；未进入文本框时打开，关闭后返回说明按钮，不请求恢复不存在的文本选区。每次打开都重新选择真实返回目标。说明弹窗不应用草稿。“导出（未提供）”为明确禁用项，本例没有新增导出业务。

公开客户端的 `keyboard`、`keyboard-rearrange`、`keyboard-remove` 操作沿原候选协议，在生成区消费同一 label/enabled owner：同key字段换位置，或移除当前名称字段。字段输入和生成变化都经现有接缝，不强设测试焦点。

既有macOS AX bridge发布accepted角色、名称、值、状态与动作。Control+Option+Space／Return不能当普通按钮激活；真实VoiceOver动作须从系统服务进入AX动作。AX查询、AXPress、普通键盘和真实VoiceOver证据分别记录，实际支持／未验范围见当前RESULT；不凭AX dump或进程存在宣称VoiceOver可用。其他平台与全IME／性能矩阵未纳入本簇。

## 同字段手写／生成滑块（experimental / macOS）

默认右侧“手写保留天数”使用共同 `cjguiComposableFieldSlider` 和当前主题。公开客户端
`python3 client.py sliders --descriptor <本窗口descriptor>` 把生成区切换为同字段 slider、原始
整数草稿框和原集合。两处滑块共享当前记录的 retentionCount、1..90 范围、草稿、原写动作与
Apply；轨道、填充和头部由公共布局派生，应用不画滑块、不维护第二份值。

本例显式注册 `cjguiGeneratedSliderComponent()`，只公开该 FieldSpec 已声明的写动作；外部改值
仍通过 `GeneratedUiSession.invoke_action`，携带原动作要求的 fieldId、text、expectedDraftVersion
和当前 owner/version，不增加滑块 RPC。拖动后可以键盘继续调整；外部修改后两处重新投影，后续
操作使用当前 owner。生成的 step、thumbDiameter、trackThickness 和颜色 token 共用公共声明。

controller 将手写 slider 事件转发 `region.handleFieldSliderEvent`，并通过现有
PointerCaptureVersionProvider／SliderCaptureProvider 转发 region 的捕获方法。适配器只保留
既有输出凭证和独立变更修订，不保留业务数值；映射中的已接受值和提交后的 owner 读回分开。
空值、非整数、Int64 溢出及越界草稿会在两处显示原文的只读提示，原始整数框仍可修复草稿。

`--check-slider-visual`、`--check-slider-generated`、`--check-slider-binding` 检查共同图形／独立
手写布局、端点／步长／禁用、注册约束、旧目标拒绝及非法草稿保留；`--check-slider-context`
把正常手写投影交给生产 transport，核对原集合键与字段写动作声明。正常键鼠、公开 owner 精读、
AX 与实际 VoiceOver 的结果见 E 当前 RESULT；其他平台、包外分发、GiB、IME 与严格性能未扩验。

## 普通负载成本观察（experimental / macOS）

`./run.sh --observe-costs` 使用相同的 80 条记录、1000×640 窗口和业务 owner。Inspector 仍默认关闭；该选项临时启用现有 workload/timing 计数，并且只在处理外部请求后输出一行现有诊断标量（最多 96 行，不遍历导出整树，不定时采样）。授权与 `enableWindowProgressReads` 一起接通现有只读 `GET_WINDOW_PROGRESS`，没有新增协议。关闭窗口时在会话仍有效期间恢复原开关；finally 只做幂等收尾。

初始窗口尚未接受场景时，现有快照可能显示 `closed`/scene 0；它不表示窗口已经完成关闭。`-1` 表示未知。GPU completed frame 与真实物理呈现不同，RPC 往返也不是输入到上屏延迟。文字 raster/upload 是累计工作，live/候选峰值、effect 资源、RSS 分别解释；不以 RSS 未回初值判泄漏。

只读文字和按钮文字的同 key 重排，沿现有候选事务按稳定身份取复用来源，并比较节点局部的字形覆盖。完整来源/几何凭据继续严格核对，真实正文、宽度、字体、样式及行数限制仍会失效；输入框继续原路径。本轮仅 macOS 实跑，未重验其他平台、IME、真人 VoiceOver、GiB 或严格性能门。

本轮成本修复同时接通普通同步 scene 与私有 prepare，资源来源按稳定 nodeId/resourceId/kind 识别；只有换位的静态文字／按钮查找来源，未改槽位继续 COW 快路。字形复用后重新签发当前几何凭据；普通带标签控件用实际绘制的标签＋值封存字形来源，业务字段和语义值仍保持原值。受影响正常链实测同 key 重排 raster/upload 20→2，字节 3,563,520→688,128；余下是生成输入／复选控件原严格路径，不宣称输入会话迁移或整个控件缓存已统一。没有新增缓存、公共协议或调度开关。

实际交付是冻结仓颉输入的 macOS 候选；本轮未合入 DS 后续布局／滚轮／owner 改动。确切构建输入与普通消费证据以 E 当前 RESULT 和 flat source recipe 为准，不能用当前主树与候选混称同源。既有源码分发包 3b1899e2 保持不变，本次成本修复通过单份源码差量保存，未重导出开发包。
