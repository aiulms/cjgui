# CJGUI 当前方向与实施状态

更新：2026-09-27。目标：仓颉核心、macOS 首平台、高性能自绘/GPU GUI 框架；人和外部系统操作同一份内容，支持手写、生成及混合界面，共同信息单一定义。

## 当前阶段与执行状态

[长文本增量更新与完整样式绑定](../../docs/plans/2026-09-23-incremental-text-style-binding-milestone.md) **已通过指导验收，以页末「指导验收结论（2026-09-24，本阶段收口）」的适用域和保留边界为准**。原始任务、裁决与逐轮记录是历史证据，不再是待执行清单。[交接说明](../../docs/plans/2026-09-19-external-executor-handoff-prompt.md) 已同步。

执行任务 **「CJGUI 文字性能与阶段收口」**（`01a0d1c8-6610-7cd2-8946-773000f9b226`）由 GPT-6 Sol / xhigh 主执行、GPT-6 Luna / high 配合，该包实施与验收已完成，该任务没有新的实施指派。指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。旧执行任务及30分钟自动化保持暂停。

**H 线运行时生成式界面包已按模拟器范围交付。** [原交接节](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-generated-consumption-next)记录共享 region/候选事务/旧事件防护及设置、thermo 两款 normal HAP 的外部提交→真实画面→系统输入/动作→owner 精确读回；设置还通过同 key 重排草稿接续、非法候选保留旧面板、外部校准和移除生成控件后的手写接续。真实 Sol 模型生成/看图修订与脚本候选分别留证；最终两包平台指纹同为 `213fbd65…`，性能原数、HAP/SDK/镜像身份和针对性回归见原运行目录。marked/cancel 在当前版本仍待验，物理设备性能与发布审核另列。路线保持仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制；E/F 并行改动及旧任务/30分钟自动化状态不变，未 stage/commit/push。

**H 线下一实施包：共享图片资源与鸿蒙实际绘制。** 按[原交接当前接续](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-image-resource-next)复用公共 PNG/key/version/accepted 持有与观察机制，补鸿蒙有界加载、实际绘制、缓存和异步退役；设置/thermo normal HAP 均完成手写/生成图片及系统编辑接续。F 负责 PNG 交换入口，H 负责图片后端，E 保留文档语义；生命周期及生成消费原证按影响复用。此次指导仅限域读码/原证和文档接续，未构建或操作设备。

**执行状态（2026-09-27）：**第九次 A–E 与 TCP 转发归属返工保留；华为模拟器已进入[真实后端接续](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#华为模拟器真实后端接续2026-09-27)。旧 HAP 私有 SDK `libnative_window.so` 占位库遮蔽系统实现是 `KnownShimNoRef` 根因，现排除该库，正常 HAP 从系统 `libsurface.z.so` 取得原生引用并提交真实首帧。原 `rev9h-verify`/`rev9j-exact-mutation` 75 项、64 PASS/11 BLOCKED/0 FAIL 属旧产物范围；新证据按本轮 HAP/PID 单列，报告 7 的历史记录保留。

**接续入口：**指定 target 的独立本机端口→设备 7856、双探针端点与 PID/token 接线保留；本轮只有明确创建成功回执才拥有转发清理权。抢占反例修后他方映射存活且零 `rm`；离线入口测试共 20 项通过。模拟器测试使用 `127.0.0.1:5555` 的当轮实例与原票日志。

**模拟器验收：**①真实 XComponent 挂载/卸载与 Create/Flush 在途保活、引用归还；②同票 queued/committing 停止、终态/ACK、全零收敛及重开；③实际像素、裁剪、命中与 owner 更新，均已有当轮或可复用的严格实证。④系统 IME 的焦点、可见草稿、拼音/英文提交、系统选区及替换已实测；marked range 与取消回调在框架应用及独立 ArkTS 最小对照中均未观测到，保留为精确待验/上游反馈项。物理设备性能与发布审核另列。

**H 线上包交付：**[系统输入能力与正常消费接续](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#h-input-consumption-next)已按模拟器当前能力交付：设置与 thermo 正常 HAP 各完成同实例系统输入→公开 owner 读回→外部换版/校准→继续编辑，并以真实系统非空选区、提交前可见草稿和精确替换补证；同 PID `12810` 的 STOP 全零→新实例真实引用/首帧→授权写读通过。框架已修全文草稿/UTF-16 范围、旧回调、同代几何重绘和仍挂载重开。当前 SDK/镜像/小艺组合及独立 ArkTS 对照未收到应用 marked/cancel 回调，保留版本化复现与上游反馈；这不推出模拟器整体不支持。详细身份、反例与截图见原交接节；E/F 并行改动保留，未 stage/commit/push。

Pharos Mark 在 `/Users/jiangxuanyang/Desktop/Pharos Mark` 独立推进 macOS 编辑器，以产品检验框架；当前事实只见 [STATUS](</Users/jiangxuanyang/Desktop/Pharos Mark/STATUS.md>)，完整接续见[实施计划当前接续节](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#input-session-20260927>)（2026-09-27）。已采纳内部文本会话承载平台服务的方案 R，借鉴与责任边界见[输入契约](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/ARCHITECTURE.md#text-input-session-contract>)。先修产品文本删除可拆 UTF-8 的权威事务边界；框架复用范围 Source/Sink、回执和 accepted 几何，补会话身份、同步查询、组合与连续输入确认，再接 Markdown SourceMap 和唯一 owner。D 仍须正式 region/真实绑定/公共候选与 accepted 事件路由，保存任务隔离、流式导出与搬迁独立推进。已有有效资产和基线复用；STATUS 已拆分，继续维护短摘要。通用输入/布局/渲染修在 CJGUI，文档语义与工作区修在产品；本次指导仅源码/日志复核及文档更新，未重跑产品验证或启动执行任务。鸿蒙并行写集保持独立，共同值契约交 H 线，不以 H 全部接入作为 macOS 收口前置。

**macOS 文本会话文件误写与恢复（2026-09-27 15:19，Pharos 线写集）：** `runtime/cjgui/src/text_session.cj`（未跟踪）在 15:11:34 被未知写入替换为早期有界窗口实现（9,234 B，`bindWindow` API，缺 ticket/代次/校准/镜像成员），令 `composable_ui_window.cj` 的 G4 会话接缝与 `text_session_test.cj` 共 10 处编译失败，框架树与 P4 线 15:12–15:16 的构建检查同时受阻。已按权威内容恢复（25,640 B，sha `155762c2…`，与 12:43–14:12 四份 Spaced 导出快照逐字节一致），`cjpm build --skip-script` 与 `cjpm test` 333/333 均通过；被替换内容隔离于 `Pharos Mark/artifacts/session-incident-20260927/`。窗口/测试/产品三处消费者均按镜像版 API，如要改用有界窗口实现需先迁移三者。

**Pharos 线 1b 第二消费者真实输入链通过（2026-09-27 17:20，框架主责）：** `examples/range_text_window_app` 普通窗口的真实合成键盘链全绿：启动即 `bindRangeTextSession` 绑定（绑定身份必须与正文节点 `(nodeId, resourceId)` 完全一致，错一个字段即静默退回 owner 路径并被 `leaked_range_events` 记账）；真实点击后平台适配器持真焦点，Hello→Shift+Left×5→Hi 非空范围替换→Backspace→CJK/emoji 共 10 笔意图全部由窗口拥有的会话判决并写入 owner（`decisions=10 accepted=10 applied=10 rejected=0 leaked_range_events=0`，owner 188→196 B）；同笔整值伴随事件照常到达 owner（`full_text_events=10`）但不被消费。证据 `Pharos Mark/artifacts/cjgui-range-text-consumer-real-input.log`，脚本 `native/scripts/verify_range_text_window_app_real_input.sh`。同轮修 `native/tests/desktop_input_driver.swift` 非 BMP 投递（emoji 原把标量截成单个 `UniChar` 触发 Swift trap，exit 133；改为同一事件携带完整代理对）；新增 `native/tests/ax_focus_probe.swift`——System Events 对隐藏代理的 `AXFocusedUIElement` 读为 missing value，焦点证据改经 AX API（适配器 `AXTextArea focus=1` + 节点选中范围回读绑定）。组合式节点自身 `AXFocused` 经 AX API 读为 false（AppKit 按真实 firstResponder 链回答该属性），如实记录、留给人工 VoiceOver。

**第三条通用框架线：第三次指导复核的 macOS P2/P3 主消费链已通过（2026-09-27），并行新布局后的桌面复验待验。** 当前结果与证据范围见[动效正常消费、主题接线与 P3 可用性](../../docs/plans/2026-09-26-framework-capability-roadmap.md#p3-consumption-review-package)。保留先前 298/298、注入 29 FAILED、alpha 0.502/0.251 和纯 alpha 工作量原证；本轮修复聚焦多行 run 清除/背景、首次交互和主题动效目标、accepted 绑定代次，接通共同动效注册→公开客户端候选 accepted→真实控件及系统主题→accepted 画面。控件验收判据、可控 scale/reveal、多窗同负载 AX 动作和统一构建源集均已消费验证；Cangjie 源码 `cjpm build` 成功、`cjpm test` 320/320，两类消费者从含空格本地导出构建运行并有源/产物指纹及注入失败拒绝。并行文本线追加空文本 native 布局后已重新编译和导出，控件真实键鼠复跑因另一应用保持前台而未完成；先前完整桌面 PASS 仅适用当时源码。导出后同一 native 文件又有正在进行的文本 range-edit 改动，该轮工作区不同于当时 P3 导出指纹，不将其称为最终整仓快照。公共动效仍标 experimental；GPU 完成、人工 VoiceOver、物理跨屏、OHOS snapshot 和既有低频停机 signal 11 未获本轮通过证据；系统强调色已由下述 P3 接续包交付。E 主责 IME/正文输入，F 与 E 协调共同渲染；工作区未 stage/commit/push。

**第三线 P4 接续包已通过指导限域验收（2026-09-27）。** [原任务节与判别证据](../../docs/plans/2026-09-26-framework-capability-roadmap.md#p4-blur-review)：组 opacity 0.4→1 终值、背景缓存 scale/Gaussian/光标颜色依赖、透明组 native restage 和公开效果提交/回退/EFFECTS 增量已修；正常生成应用与公开客户端实测 accepted blur8、帧 5 `unblurred/non_opaque_clear`、帧 7 `blurred`。CJGUI 335/335、shared core 60/60、Python 51 与 native/双消费者结果已核原日志；15:42:59 含空格导出 94 项指纹经指导独立复算一致。本次未重跑构建或桌面；工作树文本会话/窗口已追加输入线修改，本结论只覆盖该已验证快照，不覆盖新增输入改动。三项旧修复不再重开；系统窗口材质、OHOS 绘制快照、透明根实际模糊、人工 VoiceOver/物理跨屏按原范围接续。E/H 改动保留，未 stage/commit/push。

**F 线 P4 系统窗口内容背景材质首包已交付（2026-09-27）。** [原节结果与边界](../../docs/plans/2026-09-26-framework-capability-roadmap.md#p4-window-material-current)：窗口级平台无关请求、macOS 宿主适配、主题同事务、减少透明度回退、公开状态/增量和手写/生成正常消费已接通。native 判别探针、CJGUI 342/342、shared core 61/61、Python 53/53 与含空格同源双消费者导出通过；当前机器减少透明度为真，正常应用实际读到 `opaque_fallback/reduce_transparency`，恢复系统材质由受控 native 环境证明。最终导出应用的真实按钮与备注粘贴后手写/生成字段同值已验；本机减少透明度开启，前台系统材质视觉、逐键物理输入与 VoiceOver 未验；OHOS 后端仍归 H 线。E/H 并行改动保留，未 stage/commit/push。

**F 线 P3 普通控件语义、焦点与系统强调色已交付代码及双消费者汇合（2026-09-27）。** [原节结果与限制](../../docs/plans/2026-09-26-framework-capability-roadmap.md#p3-controls-semantics-accent)：accepted 控件语义/AX、生成准入与树键盘 reveal、macOS sRGB8 强调色跟随/固定及公开增量已接通；UI-only 15/15、生成 13/13，CJGUI 356/356、shared 61/61、Python 56/56、native AX 和含空格同源导出通过。两窗正常 owner/AX 响应链及最新完整前台键鼠回归 PASS（14 个不同 Tab 焦点、reveal、同 owner AXPress/指针、禁用、resize）；旧大正文两窗探针仍有短排版时序及滚动失败，真实 VoiceOver 被首次 Quickstart 阻断，不能记作通过。正文/IME 归 E，鸿蒙后端归 H；并行改动保留，未 stage/commit/push。

**F 线开发者诊断首个消费包已交付（2026-09-27）。** [原任务节结果与证据](../../docs/plans/2026-09-26-framework-capability-roadmap.md#f-diagnostics-and-regression)：旧两窗 FAIL 保留；修正探针的 1 ms 早期投递 20/20 在途、owner/accepted p95 7/24 ms，头→中→尾 158 步及独立触底腿通过，未放宽预算；三相位全覆盖和旧滚动精确首因未由新证据证明；公共有界诊断快照及默认隐藏的非交互边界叠加已由 UI-only、生成应用和真实公开客户端消费。CJGUI 359/359、native 检查与含空格同源双消费者导出 `v9` 通过，开关不增加 Metal 提交或效果字节，关闭后空闲收敛。系统 VoiceOver 已启动尝试但导航/激活动作无可归因证据，未记通过并恢复原关闭状态；不可测细分 GPU 计数保持 unavailable。E 正文/IME 与 H 后端并行改动保留，未 stage/commit/push。

**F 线下一实施包：PNG 剪贴板与拖放的公共消费。** 按[原规划当前接续](../../docs/plans/2026-09-26-framework-capability-roadmap.md#f-png-transfer-next)完成二进制/格式与预算、accepted 目标归属、原 owner 接受及既有图片资源呈现；UI-only/生成双消费者与标准系统 PNG 来源共同验收。复用本包诊断和旧文本交换，E 保留正文/IME及文档插图语义，H 保留鸿蒙接入。VoiceOver 继续待验；本次指导只读复核和文档接续，未重跑桌面/构建。

## 已接受的交付

- **样式与输入**：聚焦优化限定真实输入，候选资源/scratch 与失焦预算拒绝保持旧资源；命名样式整组绑定、生成页签标题、真实标题切换/STYLES/局部像素和两模板消费均有对应证据。
- **增量文字与绘制**：局部属性、字体、选区/锚点和可见资源复用；离屏修改后滚动见新内容并可继续编辑。多行单片/多片共用 TextKit 准备；同几何 ASCII/Unicode 分片的 scene 平面逐字节相等，一字节变造被检出。准备失败与合法空 inset 的 native 边界、普通窗口自然高度测量失败保留 accepted 并恢复均通过。
- **正常同进程双窗**：27 热样本 A 同步段 p95=22.014ms，B owner/accepted 观察上界 p95=25.269/42.433ms；全行改写另有单次对照。实际 auto-height 消费者为 3700 行、102490 UTF-16 / 161690 UTF-8，不用固定/填满高度绕开测量：27 热样本 A p95=68.947ms，B owner/accepted 观察上界 p95=72.008/88.995ms，满足本负载 100/150ms 预算；冷预热 243.822ms 另列。
- **连续性与回归**：关闭 A 后，同实例 B 的逐字工具输入进入真实 owner 并精确读回；独立聚焦/失焦/再聚焦链通过。最后的 scope-remap exit109 已定位为探针漏传命令 focusScope：空 scope 拒绝、正确 scope 接受、旧场景排队前与新场景均有焦点、旧事件拒绝、新 Cmd-K 应用、Tab 到正确兄弟均通过。重开图片复用应用缓存，新 session 解码 0、提交/完成帧 1，旧代不得推进计数。最终完整 controller 探针 exit0，日志 `/private/tmp/cjgui-sol-scope-remap-focused-both.log`；本次只改探针/构建脚本，未改产品代码。
- **同源交付**：`/private/tmp/cjgui-sol-autoheight-final-export-20260924`，83 项（75 identical/8 rewritten），指纹 `fe0544e304b2101240d424500f589c38f280148052a9b26dd9b0158b27c2274d`。指导读取源码/原始日志并重新逐文件比对；性能分位数已重算，未重跑产品测试。最终探针修改后产品导出仍一致。工作区尚未 stage/commit/push，此为本地预览交付。

## 保留边界与下一步

- 新能力只解决已解析内容宽度的 multiline 自然高度。无约束 preferredWidth、普通 TEXT 的旧测量路径仍可能昂贵；旧四指标测量 API 保持原语义。编辑器的大文档应按范围取数、视口布局及增量索引设计，不能把 GB 文件交给一个要求立即精确全文高度的普通字段。
- 一次 tail 局部刷新曾出现额外 raster，随后多次通过但首因未定位；保留原始失败和分段观测。重遇或新生产变化触及该路径时继续定位，不把连续绿色当作已修复。
- 证据分别标记 native 受控探针、正常应用、公开客户端和 CGEvent/AX 工具输入。人工物理输入、系统 IME/VoiceOver、显示器实际呈现、整体峰值内存、GB/真机性能和发布不由本阶段结果覆盖。

具体历史、源码版本及日志索引只见阶段页。阶段接续结合编辑器的实际需求及[设计导航](../../docs/plans/DESIGN_INTENT_INDEX.md)，审视组件布局、自绘/GPU、文字输入、资源调度、语义动作与普通开发者接入六条主线。
