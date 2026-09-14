# CJGUI runtime 与样例

更新：2026-09-12。状态：[ACTIVE_DIRECTION.md](ACTIVE_DIRECTION.md)。
仓颉包当前名为 cjgui，版本 0.0.0，输出 static；不承诺稳定公共 API。

## 当前目录

- src/：runtime、窗口投影和 demo_support；部分旧模块仍是摘要模型，需读源码确认。
- shared_operation_core/：不链接 renderer/AppKit/Metal 的普通 core 包，包含通用契约、socket transport、列表消费者和公开客户端。
- native/：平台桥接与本地 R1 internal renderer。
- demo/：程序化状态/harness 样例，目前不能当作窗口应用。
- examples/shared_operation_window_app/：正常启动的 macOS 共同操作窗口；人类窗口输入和受授权的本地外部操作进入同一列表。
- examples/shared_operation_second_consumer/：只消费 core 的列表命令行消费者，使用不同数据和授权范围。
- examples/backup_rule_config_consumer/：不同领域的无窗口配置消费者，含消费者专属字段和动作。
- examples/rule_set_application/：纯仓颉、多记录、稳定 ID、草稿/撤销和版本化本地规则集文件领域。
- examples/rule_set_window_app/：普通 macOS bundle 消费者，组合通用列表/详情窗口；`zsh run.sh --build-only` 只构建并签名，不构成 GUI 验收。
- examples/rule_set_second_consumer/：不依赖 renderer 的独立规则集消费者，真实 socket 验收动态创建、草稿应用和有界变化读取。
- probe/：针对性探针，不是正常库消费的替代品。
- native/scripts/：相关验证入口。

## Experimental：定义可组合窗口

当前是通用主链初版，API 仍为 experimental。文字/资源、多行文档、通用鼠标选择、键盘焦点/动作与动态绑定生命周期已有针对性实现和当前窗口验证；完整边界见 [ACTIVE_DIRECTION.md](ACTIVE_DIRECTION.md)。

普通 macOS app 不再复制 sample launcher、native 编译或 bundle 过程；请用
[Experimental macOS 应用宿主](MACOS_APPLICATION_HOST.md) 的
`CjguiMacosApplicationHost`、`cjgui_macos_app.sh` 与统一 runner。两个现有窗口
消费者是这个入口的兼容实例，而非新应用的 native 依赖。

新建应用优先使用 `scripts/create_macos_application.sh ui-only|collaboration`；需要在临时目录证明
没有隐式连接当前工作区时，使用 `scripts/export_framework_preview.sh` 导出源码预览后再创建。runner 的
`source_origin`/`resource_origin` 日志用于核对实际预览来源；验证时清除继承的
`CJGUI_NATIVE_SOURCE_DIR`，但不删除开发者的显式覆盖能力。完整的工具链选择、路径依赖、资源和预览边界见
[Experimental macOS 应用宿主](MACOS_APPLICATION_HOST.md)。

`src/composable_ui.cj` 与 `src/composable_ui_window.cj` 是当前的实验性
开发者入口。应用在仓颉中构造纵向/横向容器、文字、按钮、文本/整数/布尔
编辑器和滚动区，并为节点提供稳定 `nodeId`、资源 ID、动作名及样式；布局器
一次计算的 bounds/clip 同时供 Metal 矩形、命中、焦点、无障碍和事件版本校验
使用。原生层只接收这一份通用场景，不能增加领域字段或页面排列分支。

一个普通窗口消费者实现 `CjguiComposableUiController`：

1. `buildUi()` 从领域快照构造组件树；页面顺序、分组、间距、颜色和动作都在
   消费者仓颉代码中调整。
2. `uiSceneVersion()` 是全部渲染可见声明的廉价失效提示，而不只是领域内容版本：内容、
   树层级、样式、资源和本地 UI 状态变化都必须推进它；窗口另行分配投影身份，并在同一已显示快照上
   清空 FIFO 后才重投影。事件以节点 ID（数组 index 仅作诊断）和投影身份解析；
   原目标已经移除时调用 `rejectUiEvent()` 显示未应用原因，而不是重定向输入。
3. `applyUiEvent()` 把稳定节点的资源/动作交给已有领域入口，不在窗口或 native
   层保存业务真相；`rejectUiEvent()` 显示失效目标；`requestWindowClose()` 保留领域的关闭决策。

输入节点的有效目标是 `nodeId`、`resourceId`、节点种类与投影版本的组合。正常同对象刷新保留
正在进行的本地编辑；删节点、换绑资源/类型、禁用或转为只读会拒绝旧事件。Tab/Shift-Tab 遍历
文本、按钮与布尔节点；Space/Return 激活按钮或切换布尔值。`cjguiComposableMultilineTextInput`
默认把 Tab 用作导航，只有显式 `tabInsertsText: true` 才插入制表符。窗口可用
`bindCommand("save"|"undo"|"redo", nodeId)` 把 Command 快捷键映射到已有语义按钮，而非向
native 写业务规则。

### 表单与选择列表组合（experimental）

`cjguiComposableBoundFormField(...)` 接收已有 core 的
`CjguiSharedFormFieldDescriptor` 与 `CjguiSharedFormFieldProjection`，并生成标签、文本/整数/布尔编辑器及
可见校验提示。调用者仍提供自己的 container/editor/validation node ID、主题样式与 selected
`operationResourceId`；字段值、校验和版本继续属于领域 owner。helper 会验证 descriptor/projection 的
resource/field 对应关系，不能以不匹配的 projection 静默渲染。常见 required/range/format 错误会变成可读
文案（例如“请填写保留天数”），未知领域错误只显示通用提示而不泄漏内部错误码。

`cjguiComposableSelectableListRow(...)` 把 `CjguiComposableUiVirtualListItem` 的稳定资源、可访问标签、选中/
焦点样式和 action relation 组合为一个普通按钮节点。它不拥有列表选择；controller 仍通过 `applyUiEvent()` 调用
已有领域入口。两个 helper 写入同一节点的 `fieldId`、`operationActionName` 与 `operationResourceId`，所以人侧
编辑、AX 投影和 shared-operation 外部字段/动作关系不会各自维护一份映射。

文本事件默认严格按投影版本解析。只有紧接一代、同一仍聚焦的可编辑文本节点，且当前领域投影仍等于上一笔本地
已接受文本时，才会接住在 replacement projection 构造期间抵达的本地续写；删除、换资源/种类、禁用/只读或外部
改值仍调用 `rejectUiEvent()`。这处理连续键入的宿主时序，不是陈旧事件的通用豁免。

### 重复组件实例与命令生命周期（experimental）

`CjguiComposableUiComponentRegistry` 是每个 controller 持有的有界（64 个 live
实例）仓颉构建上下文。列表重排不能用数组下标当 key；实例提供 `nodeId(localKey)`、
`semanticId(localKey)` 和 `focusScopeId()`，所以一个字段组/编辑器函数不必再预留全局数字段。
同一候选轮重复 `use(key)` 返回 `duplicate_component_key`；临时隐藏请调用 `retain(key)`，恢复时
保留原实例身份。注册表没有进程级实例表；每个实例最多 64 个局部 key，超限显式失败。

动态组件 controller 应同时实现 `CjguiComposableUiSceneRefreshParticipant`：其
`beginSceneRefresh()`、`prepareSceneRefresh()`、`candidateSceneCommands()`、`commitSceneRefresh()` 和
`rollbackSceneRefresh()`直接委托给 registry。窗口在一次 refresh 中依次构造候选组件/scene/command，
校验并交给 native staging；只有 native present 被接受后才同步提交组件身份与命令。测量、布局、逐节点
setter、present 或命令校验失败都会丢弃候选，继续保留旧 scene、旧命令和旧 live 实例；相同重试不会反复
生成候选身份。旧 `begin()`/`finish()` 仍保留给低层兼容调用，但普通应用不应在 `buildUi()` 中提前销毁实例。

组件的公开窗口投影 `semanticId` 是 generation/slot 组成的 opaque 安全令牌（例如
`component-12-2`），不是业务 key 的可解析编码；业务 key 仅由 controller 内的 registry
持有。这样公共空白分隔协议保持严格，不会让任意 local key、分隔符或换行进入 transport。

`cjguiComposableVertical(..., inputScopeId: instance.focusScopeId())` 可把一个组件根设为普通
焦点范围，不会创建 native layer。上述 participant 路径会自动替换已接受 scene 的完整命令集合，应用
不应在每个 `pumpOneTurn()` 后无条件调用 `replaceCommands()`；低层 `replaceCommands(commands)` 仍只接收
当前已提交 scene 中有效 target 的完整新集合，失败保留原集合；`revokeCommand(id)` 用于独立撤销。相同 Command
快捷键可用于不同 scope，但同一 scope 的冲突会失败。键盘先取当前 focus scope 的声明；没有
scope 时才可取 global fallback，因此顶层 layer/另一个编辑器不能穿透到 base command。Cmd-A/C/X/V
和 marked text 仍由原生文本服务优先；无快捷键菜单动作应走自己的 Cangjie 菜单/动作调用，不要填造
一个快捷键。实例/命令 API 是仓颉公共实验接口，native 不接收业务 key、command id 或回调。

多行文字仍由 AppKit TextKit 负责组合、选择与字形排版，仓颉 document owner 只接收已提交
投影。它的公共 UTF-8 边界当前是保守 profile：拒绝 UTF-8 标量内部、CRLF、常见组合标记/变体
选择器/肤色/ZWJ 相邻位置，并按连续区域指示符成对处理；这不是“已实现全部 Unicode extended
grapheme segmentation”的承诺。原生 TextKit 的位置与公共 UTF-8 转换分别验证；消费者不得把被
拒绝的公开范围静默取整到另一段文字。

可参考两个布局不同、但共享同一渲染/输入主线的正常入口：

- `examples/adaptive_layout_public_consumer/`：并列的两个可组合组件以稳定业务 key
  声明普通 scope，并可在运行时隐藏、恢复和替换同 chord 的 scoped command；
  `zsh run.sh --build-only` 只重建/签名，`zsh run.sh` 启动窗口。它的可授权
  `SET_MARKED` 外部写入会由同一 controller 的下一轮投影读回，不把外部连接另作内容 owner。
- `examples/rule_set_window_app/`：命令行、可滚动规则列表、详情草稿和文件动作；
  `zsh run.sh --build-only` 只重建/签名，`zsh run.sh` 启动窗口。
- `examples/notification_threshold_window_app/`：卡片式通知通道/阈值/开关配置；
  当前草稿、草稿版本与已应用基线都由 `notification_threshold_application/` 所有，
  外部可读取/编辑草稿，旧基线应用会返回 `stale_draft`，而
  `notification_threshold_consumer/` 仍可在不启动 renderer 的情况下使用同一领域。

所有上述 API 仍为 experimental：不是稳定控件库，也不承诺完整 IME、富文本或
多平台行为。一次 `layout` 只在本次递归求解内复用相同的文本、完整 style 和约束宽度
请求，容量上限 1,024，调用结束即丢弃；它不保存第二份组件树，也没有开发者维护的脏标记。
`layoutWithMetrics(..., reuseMeasurements: false)` 是用于测试差分的实验性无复用参考入口，
返回同一 canonical scene 与本次只读测量/递归工作计数，不能作为第二个运行时状态 owner。
生产窗口通过 `CjguiInternalRendererTextMeasurer` 调用与绘制相同的 AppKit 字体服务，按字号、
字重、字体族和约束宽度得到字形 bounds、行高和基线；其跨刷新 scalar 缓存键包含这些实际影响项，
容量限制为 128。生产测量失败会令本轮投影失败、保留旧场景并给出
非 OK 状态，不能静默当作真实测量成功。单行静态文字、按钮及文本/整数/布尔字段的可见文本由
TextKit/AppKit 完成 shaping 后，在场景提交前栅格成节点持有的 Metal 纹理；形状、图片和这些
文字纹理严格按同一已接受 scene 的 painter order 合成。活动单行字段把唯一 `inputProxy` 的文本、
选区、光标和 marked range 作为派生纹理状态；TextKit 仍是 IME、候选和选择的唯一 owner。多行字段
同样复用该唯一 TextKit layout graph 的可见 glyph、选择、光标和候选几何，但将其离屏结果作为有序
scene 纹理提交，不再有置顶的正文覆盖层；因此这不是自研文字引擎或第二份可写正文。文字纹理没有
跨场景的全局缓存：它随已接受/COW 场景的节点（最多 1,024 个）存活，key 包含实际文本、字体、原始
几何、resolved 可见 tile、tile 相对 node 的偏移、scale、选区和组合状态。tile 保留原布局宽度而只栅格
node∩clip；单节点最多 8 MiB、已接受 scene 合计最多 24 MiB，资源失败保留旧场景/旧派生纹理并按声明的
重试边界处理；
完全裁掉、替换或关闭时释放。首次帧的 GPU readback 是诊断，不会因每次正常编辑而同步执行，也没有
另建领域状态或透明原生控件覆盖页面。

`CjguiComposableUiStyle` 提供字号、字重、`system`/`monospaced` 字体族、最小/期望/最大
尺寸与横纵对齐，以及独立的 `cornerRadius` 与 `clipsContent`；前者只修饰本节点的边框/背景，后者才将
圆角传为子内容、Metal、TextKit、命中和滚动共用的 resolved clip。row/column 先保留 fixed/min 约束，增长子项触及 max 后把剩余空间继续交给
仍可增长的同级项，整数余量按声明顺序稳定分配。横向子项的自然高度使用它已分配的宽度测量，
而不是把行高当作文字宽度。空间仍不足时只按既有父 clip 裁剪，不悄悄破坏 fixed/min。
未知字体族归一为 `system`。`CjguiComposableUiTheme.beaconDark()` 和
`paperLight()` 提供两个可复用主题，局部样式仍可覆盖。`cjguiComposableImage` 用逻辑资源
ID、版本、路径和缩放模式声明 PNG；native session 私有地以三者为键用 `MTKTextureLoader`
解码 Metal 纹理，只保留活跃资源，并将可复用缓存限制为 8 项、32 MiB。资源缺失或无效会拒绝该次场景投影；
同 ID 的版本/路径更新、移除和关闭都会走受控失效与回收。样例 `run.sh --build-only` 会把
蓝色 `composable-beacon.png` 与珊瑚 `composable-beacon-coral.png` 放入 bundle 的
`Contents/Resources`；正常 bundle 消费者应传入文件名等 bundle-relative 路径，不应把
源码树前缀传给运行时资源解析。

节点可显式声明 `displayValueRole`（例如 `draft`、`applied`）；外部投影同时输出直接可解析的
`WINDOW_FIELD_VALUE node resource field role value_source typed_value`，不要求消费者拆解关系
目标 ID。普通循环应在真实外部 `INVOKE` 后调用 `requestRefresh()`，随后调用
`refreshIfNeeded()`；后者只比较 Cangjie UI revision 与 native resize revision，空闲和
`GET_CONTEXT`/`GET_CHANGES` 不会执行 `buildUi`、布局或 native 重交。兼容的 `refresh()`
仍是一次显式保守重建。相同候选场景不配置或提交 native 场景，测量命中缓存时也不重复跨 FFI；
仅层级/绑定变化会刷新仓颉语义投影而不强制 GPU 提交。多行 TextKit 缓存按稳定节点/资源身份、
实际文本、字体/颜色和宽度失效，不会因整幅 projectionVersion 变化而作废。通用的透明图片首帧诊断若
无法安全比对源像素会标记 `image_pixel_unverified`，不冒充绘制失败或像素相等；原生场景探针
已以测试侧生成、非方形的已知 RGBA fixture 对生产 drawable 逐像素验证 FIT/FILL、裁剪、
完全透明和半透明合成，并有省略图片节点的负对照。节点还能声明 `enabled`，文本/整数字段
可声明 `readOnly`：禁用节点不再获得焦点或事件；只读文本仍允许聚焦、选择和复制，但不能进入
编辑领域事件。物理中文 IME 的候选、提交、删除和粘贴尚未实测，不能由程序化 Unicode
输入替代。`WINDOW_*` 诊断把 session、当前/accepted/submitted scene、Metal readback
completion、多行 TextKit tile prepare、pending/failure 和 build/layout/submission 计数分开；
`WINDOW_WORK_TIMING_MS` 是最近一次真实 projection 的 build、layout、实际 native
text measurement、native staging/present 四项单调时钟诊断，`WINDOW_MEASUREMENT_CALL_COUNT`
是该轮越过 production measurer cache 的调用数。`0` 表示小于当前毫秒分辨率或该阶段未发生，
不能解释为端到端延迟为零；它们不是业务延迟、GPU 完成或人眼可见证明。Metal completion 与 overlay
绘制都不等于用户肉眼看见，故 `presentationState` 仍为
`unavailable`。临时测量或 drawable/encoder 不可用会保留上一有效场景和输入映射，标记
`refresh_*` pending，等待一次显式 `retryPendingRefresh()`、真实外部变更、resize 或人机事件；
不会在空闲循环无限重试。

## 已有检查入口

以下命令是当前工作树的针对性复核入口；通过它们不等同于 API 稳定、打包发布或第三方模型兼容。
工具链及 SDK 以实际机器为准，遇到问题再查 [构建资料](../../docs/setup/BUILD_FROM_ZERO.md)。

在仓库根目录：

    unset SDKROOT CJ_GUI_SDKROOT
    source /Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh
    zsh runtime/cjgui/native/scripts/verify_internal_renderer_clear_window.sh
    zsh labs/macos_bridge_smoke/scripts/verify_auto_close.sh

在 runtime/cjgui 目录：

    cjpm test --parallel 1 --no-progress
    cjpm build --skip-script
    cd shared_operation_core && cjpm test --no-color
    cd ../examples/shared_operation_second_consumer && zsh test.sh
    cd ../backup_rule_config_consumer && zsh test.sh
    cd ../rule_set_application && cjpm test --no-color
    cd ../rule_set_second_consumer && zsh test.sh
    cd ../rule_set_window_app && zsh run.sh --build-only
    cd ../notification_threshold_window_app && zsh run.sh --build-only
    cd ../.. && zsh native/scripts/verify_composable_ui_layout.sh
    zsh native/scripts/verify_composable_scene_renderer.sh
    zsh native/scripts/verify_composable_ui_window_controller.sh
    zsh native/scripts/verify_composable_ui_appkit_text.sh

根包的普通 `cjpm test` 会先运行 `build.cj`，生成并链接内部 AppKit/Metal/MetalKit
sidecar；`cjpm build --skip-script` 只在该 archive 已存在时用于复核源码构建。此机器的
1.1.3 默认路径使用 `xcrun` 选择的 SDK；如需针对旧 1.1.0 或兼容性回退，可显式设置
`CJ_GUI_SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`。R1 verifier 将 wrapper
与 probe 放在同一临时 package 编译；它成功不代表 API 稳定、发布完成或第三方环境兼容。
窗口样例迁移后的构建与已完成的 GUI 验收见
[shared_operation_window_app](examples/shared_operation_window_app/README.md)；纯 core 列表与备份规则消费者的
独立 AF_UNIX 验收见 [shared_operation_second_consumer](examples/shared_operation_second_consumer/README.md) 和
[backup_rule_config_consumer](examples/backup_rule_config_consumer/README.md)。

共同操作为 experimental：应用开发者定义资源类型、上下文、资源字段、动作描述、typed 参数、目标集合与业务结果；领域自身拥有版本和修改真相。共享 transport 只处理私有 descriptor、分片 frame、作用域和声明校验，随后调用领域的外部入口；人类入口调用同一个领域处理器。外部 `GET_CONTEXT`、`GET_CHANGES` 与动态 `INVOKE` 使用稳定 ID 和刚读到的版本；增量游标过期时必须全量重同步。不要把固定 socket、分隔符协议、单次读取或 UI 投影当作业务真相。

## 相关入口

[项目方向](../../docs/core/GUI_PROJECT_DIRECTION.md) · [当前阶段交付](../../docs/plans/2026-09-13-ordered-gpu-composition-milestone.md) · [验收标准](../../docs/core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md)

旧长篇阶段记录见 [历史快照](../../docs/archive/2026-09-11-direction-governance/README.md)。
