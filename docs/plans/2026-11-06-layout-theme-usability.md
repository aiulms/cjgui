# 普通应用布局、组件美感与诊断闭环

2026-11-06 本阶段交付为 **macOS experimental 候选**：修复长正文挤掉标题/底栏和窄横排文字越界，补齐可共同消费的主题角色、布局配方及只读诊断，并用隔离小说工作台、包外普通工具和通知示例实际消费。它不等于框架成熟、正式SDK发布或16/32ms性能门通过。

主线程 Sol 6.1 集成；实际使用 Terra 6.1 分包完成布局归因/反例，Luna 6 分包完成公共文档试用与受控小说消费，随后主线程用实图/AX修复接入遗漏并集中验证。复用 LayoutEngine、Theme、NamedStyle/BoundStyle、Inspector、现有反馈组件和业务 owner，不增加平行运行时、验证规则或焦点状态机。

## 框架结果与归属

- `src/composable_ui.cj`：纵排只有一个非固定 `growY` 子节点时，先给自然/固定兄弟及gap分配，再将剩余高度给它；长正文不再抢掉标题/底栏。多个 grow 子节点沿用原行为。自然宽度、非 stretch 的横排子节点受父宽约束，显式固定宽/min仍可有意溢出；保留 alignX/alignY 的节点定位语义。
- 同一声明校验和运行布局入口拒绝多于一个直接子节点的 ScrollArea，返回 `scroll_area_requires_at_most_one_child`；0/1子节点保持有效。原来静默只消费首个子节点会使应用看似丢内容；动态 materialize 后同样检查。
- `src/composable_ui_theme_roles.cj`：在现有 Theme 上增加 warmPaper、navigation/item/action/input/card/caption及empty/loading/error/success角色；整组 BoundStyle 含既有交互投影，catalog可共享注册角色名供手写/生成使用。选择仍归 owner，hover/pressed/focus/disabled仍归窗口；不把按钮 align 当内部文字对齐。现有状态/内容反馈组件增加 themed 样式适配。
- `src/composable_ui_layout_diagnostics.cj`、diagnostics/window/inspector：接受场景的声明fixed/min/ideal/max/grow/placement、父内容分配、矩形溢出/祖先裁剪、label和value同时为空、合成交互态可读。Inspector可选择节点查看，`diagnosticSnapshot(includeNonVisible: true)`可包含已经 materialize 的零大小/屏外节点。读取不重建源场景、不写业务。矩形事实不代表圆角、变换、遮挡或完整视觉可见性，也没有伪造求解器追踪。`window.contentBounds()`返回真实逻辑内容分配；窗口关闭/尚无分配时为None。
- 公共说明在 [STYLE_ROLES](../../runtime/cjgui/STYLE_ROLES.md)、[布局配方](../../runtime/cjgui/LAYOUT_PRIMITIVES.md)、[README](../../runtime/cjgui/README.md)及开发quickstart。三栏配方明确 horizontal 子面板的交叉轴 stretch、单内容 scroll、持久viewport、正文grow、条件底栏；不依赖窗口frame减常数。

本阶段没有新增 native/FFI、runtime_state或renderer_state写入；实际输入/保存继续进入原应用 owner。`composable_ui_window.cj`的开工已有性能改动保留，仅叠加上述读取接口。CodeGraph查询未覆盖所问仓颉符号，CodeLattice项目选择/分析未成功，故不将图工具结果当影响范围或运行证明；用直接源码、相关测试及正常消费补证。

## ArkUI / HDS 取舍与真实画面

实际阅读官方 [ArkUI按钮](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-common-components-button/)（更新2026-10-16）、[UI Design Kit](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ui-design-introduction/)（2026-07-28）、[焦点设计](https://developer.huawei.com/consumer/cn/doc/doccenter-ux-design/hmi-focus-0000001748650376/)和[多设备新闻阅读](https://developer.huawei.com/consumer/cn/doc/doccenter-multi-device/multi-news-read/)。原始阅读摘录和PC参照截图位于证据根的 `arkui-*.txt` / `arkui-pc-reference.png`。

采用明确主次操作、成组表面、选中与获焦可并存、大屏侧栏+内容区和参与布局的工具栏。PC/2in1、鼠标/键盘与可调整窗口为前提。32pt控件、4/8/12/16间距、暖纸颜色和密度是CJGUI适配值，不是官方token；没有照搬移动触摸留白/胶囊外形，也没有引入ArkUI或其他GUI依赖。

实图先后揭示了两处消费错误：多个scroll直接子节点使内容缺失；补单内容容器后，缺少alignY stretch又使侧栏过矮。两次RED截图保留，不能用静态断言抵消。最终暖纸小说画面的导航使用选中底色与独立焦点边框、主动作集中强调、长标题省略、短信息自然排版；空检索结果不预留54点空块。

- 前像： [原应用只读截图](../../work/usability-20261106/evidence/novel-before.png)。它只证明当时可见原件，不是受控副本源码前像。
- 接入RED： [scroll子节点遗漏](../../work/usability-20261106/evidence/novel-first-candidate.png)、[缺少交叉轴stretch](../../work/usability-20261106/evidence/novel-scroll-fixed.png)。
- 最终视觉：[素材普通窗口](../../work/usability-20261106/evidence/novel-materials-normal.png)、[1080×650窄窗](../../work/usability-20261106/evidence/novel-materials-narrow.png)、[1396×850宽窗](../../work/usability-20261106/evidence/novel-materials-wide.png)、[章节窄窗](../../work/usability-20261106/evidence/novel-chapter-narrow-visible.png)。宽窗请求1450被屏幕限制为实际1396，未把请求值当实测。
- 另一普通消费：[包外纯UI工具、暗主题](../../work/usability-20261106/evidence/public-tool-dark.png)。从公开创建入口生成，真实输入“公共角色可用”、点击计数+1后owner和画面一致。
- 通知示例：[最终错误/禁用暗主题](../../work/usability-20261106/evidence/notification-delivery-error.png)、[亮主题](../../work/usability-20261106/evidence/notification-delivery-light.png)。新反馈使用实际表单摘要，不把空字段错误误作无错误。原230固定高卡片和26高标签栏挤压控件，现改为320最小高度和30标签栏；最终AX显示输入底部与滑块顶部相隔8点。该示例仍保留历史生成区域空白及其他旧展示风格，本轮不称其整窗完成美化。

## 正常消费与证据

证据根：[work/usability-20261106/evidence](../../work/usability-20261106/evidence)。保留失败、输入及版本身份，不删慢样本、不重投刷绿。

| 具体问题 | 结果与原件 |
| --- | --- |
| 长正文是否挤掉兄弟、居中文字是否越父边 | `layout-slice-red.log`两例RED；修复后剩余空间4例+旧definite multiline7例通过；在`usability-tests.log`中可复核各例 |
| 新诊断是否可信、Inspector是否能选中且不自失效 | `diagnostic-final-tests.log` 3/3通过，含真实Mac应用主循环和Inspector接受场景；早期直接start/pump夹具失败原件保留 |
| 错误scroll声明及反馈角色 | `scroll-children-red.log`；`scroll-feedback-green.log` 5/5通过，含合法0/1子节点和反馈组件适配 |
| 旧viewport/collection契约是否受损 | `viewport-regression.log` 6/6通过 |
| 共同源码是否能构建 | `framework-scroll-feedback-build.log` 中 `cjpm build --skip-script`通过，保留已有warnings |
| 导出闭包是否实际检查脚本/模板/文档 | `export-closure-fixed.log` 聚焦测试通过；修复测试夹具原先漏拷DOCUMENT_CLIENT和shared_document消费者的问题，不把缺失夹具当生产缺陷 |
| SDK包外能否只用公开入口消费 | `public-final-package-build.log`通过；实际运行/AX与截图在public-tool相关原件，最终来源归档`public-final-build-provenance.json`；路径含空格 |
| 小说正文输入、保存、切页、缩放、重启 | 私有v3=630 UTF-8字节，经物理Unicode输入“验收甲”保存v4=639，再加“乙”保存v5=642；最终重启仍读到v5与标记。`novel-delivery-build.log`、`novel-delivery-run.log`及`novel-delivery-chapter-ax.json`；目录点击从素材页真实切回正文 |
| 长/短/空内容及可达性 | 普通/窄/宽窗真实截图；`novel-search-empty-ax.json`为真实no_match；`novel-narrow-wheel-ax.json`和对应截图显示滚到末素材；空结果不建空占位。未把Cmd+Down尝试当正文到尾证明 |
| 通知错误是否和可应用状态一致 | `notification-delivery-error-ax.json`阈值70999、真实错误提示、Apply disabled且控件不重叠；`notification-delivery-reset-ax.json`恢复70、错误消失、Apply可用；最终构建`notification-canonical-resolved-build.log` |

最初根 `cjpm test --skip-script --filter=...` 被既有多测试文件重复foreign声明/重载歧义阻挡，见`layout-red.log`；未删测试或扩公共API来掩盖。之后使用真实生产cjo和独立test-only入口运行上述相关文件。`usability-tests.log`总17中有1个旧Inspector夹具失败，因此不能称该总日志全绿；它由后续3/3的正常应用夹具验证替代。没有重新宣称根全套测试通过。

本次物理Unicode输入不等于系统IME组合/候选/交错已验证；没有重新证明16/32ms、超长文档、移动极窄窗、其他平台或外部真实模型调用。新增角色/布局/诊断的运行范围为macOS。本阶段布局不是通用多栏自适应断点系统；小说侧栏220和资料栏318固定，中间min280/ideal700/max1024，实际检查宽度1080–1396。

## SDK、候选与并行工作边界

交付入口：[评审包README](../../work/usability-20261106/README.md)、[启动隔离候选](../../work/usability-20261106/launch-review.command)、[SDK源码zip](../../work/usability-20261106/CJGUI%20Usability%20SDK.zip)。

最终macos-dev导出为621文件、451生产包源、596闭包输入，逐文件SHA及zip完整性已核对，当前源与596输入无漂移。复用官方导出器，没有复制target/cache进SDK。

- exported content SHA256：`602c6600c139691a02e3b98803867dff59a0f2bd6d2fbe26dddd54ef6c66e437`
- source-lock文件 SHA256：`1900200e120a95c8857d5ca20d6ebe5c1104ae8f0b89fb5a1e501594a093027b`
- SDK zip SHA256：`7259dc723dcd7fdac7e284ef14f8265a4920f7f0a01886c2bc5b903fdb6efaf7`
- 小说最终可执行文件 SHA256：`aeec9b5cab064a6c6ac5c864f443a256ea0a1a4859bd8199ad9cac1f58b80d81`
- 小说所链接renderer / launcher：`9166a4f52b988875fe3c238e39d1dbe13396346ce2fed3f7ead776f85651628d` / `5335cab6faeb01f55a6aa2cf94eb52e573b22ae0c42f98065c8a6abc0468e574`。通知与公共工具各自的构建provenance分别留存，不宣称各路径编译出的archive字节相同。

小说副本只有源/必要配置与依赖，不复制用户正文或历史产物；数据在本线`novel-data`。旧捕获清单记录935文件/26,885,114字节，却没有保存三个UI文件的源码前像，因此不伪造“精确旧基线补丁”。原目录在任务期间持续增加作品、地图、剧情与试写等业务。

另交付 [UI重放补丁](../../work/usability-20261106/integration-patch/novel-ui-integration.patch) 与 [前后像manifest](../../work/usability-20261106/integration-patch/manifest.json)：基于一次较新的原件捕获，仅重放UI布局/样式，保留新增业务和非UI控制器方法。主线程独立核对非UI方法未变，并在其before副本上`git apply --check`通过。补丁SHA为`a321ae517d7ae4140f7355693ffd993582f585600e24cac83709e94832305792`。**该补丁未编译/未应用，旧候选运行结果不证明它通过；原main.cj随后又有并行变化，不能直接覆盖或盲套。** 原目录与用户数据均未写；后续由其当前执行者按manifest整合。

开工已有差异保存在`baseline/preexisting.patch`/`status.txt`。最终对比确认性能阶段文档、native头/实现与两项native测试、MACOS_CANDIDATE及runtime_renderer_session差异与开工相同。正式05b与旧16/32ms未过门、H/W/Linux状态保持；未stage、commit或push。本阶段不启动性能专项、平台迁移或架构替换。

## 收尾与空间

遵循 [产物容量规则](../../AGENTS.md#artifact-space-budget)。开工宿主约207.5GiB可用，预计峰值不超过3GiB，实际新增保留远低于10GiB且宿主始终高于20GiB。受控小说构建脚本落实空间检查、当前/上一份bundle、精确ID/运行检查和finally清理；没有将文档当脚本已实施。

自有临时应用均已按精确bundle/PID关闭，未碰原小说工作台实例。含空格的包外SDK/构建目录在保存独有锁、源、provenance及必要原件后退役；通知从临时SDK路径迁到最终SDK时，构建正确拒绝旧编译配置，再在本线退休target后重建，领域依赖路径也一并接通。失败日志全部保留。旧target冗余产物回收，上一可用通知bundle保留。精确删除清单与分配/可用空间见 [cleanup-space.json](../../work/usability-20261106/evidence/cleanup-space.json)：本线专属目录保留约0.790GiB，删除本线重复/退休产物所计已分配284.21MiB；该次卷可用增量284.08MiB，宿主剩余约208GiB。同卷有并行任务，可用变化不全部归因于本线。另复用根target当前155MiB及原通知native缓存约4.7MiB，缺少其开工分配基线，不能把全量当新增；即使全额计入仍不到1GiB。

仍保留：锁定SDK源码和zip、最近SDK源码；小说当前/上一bundle及增量构建目录、私有数据；通知当前/上一bundle及复用构建目录；native测试隔离归档、必要RED/GREEN原件与UI重放前后像。没有清理旧存量、正式SDK或归属不明文件。

最终文件核对：`git diff --check`、本阶段/STYLE_ROLES共23个本地链接、SDK621个逐文件SHA及22项新声明的原生句柄签名扫描均通过，见`evidence/final-verification.json`。根native及性能线差异与开工一致。
