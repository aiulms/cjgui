# CJGUI 能力矩阵（审计线·包 C，静态源码核对）

数据快照：HEAD `dc27dff`，239 条未提交改动，快照时间 2026-10-21T04:42:43Z。
**本审计基于未提交改动的工作区。** 纯静态源码核对，未构建、未运行、未采信 artifacts/ 验收报告或 docs/ 完成度声明。

范围与方法：
- 行来源三取并集：(a) roadmap E1–E6、F1–F11（docs/plans/2026-09-26-framework-capability-roadmap.md:108–141）；(b) runtime/cjgui/src/*.cj 组件工厂 public func（实际约定为 `cjgui*` 前缀，`public func cjgui` 去重 107 个，其中真正构界面的组件工厂约 45 个，本节按 node kind 归并为 26 行）；(c) 四平台 native 导出符号按功能分组（macOS 头文件 `native/cjgui_internal_renderer.h` 提取 355 个去重符号；Windows `platforms/windows/native/cjgui_windows_renderer.c` 146 个；Linux `platforms/linux/native/*.c` 123 个；OHOS `platforms/ohos/host/ohos_renderer.cpp` + `cjgui_host_bridge.cpp` 71 个）。
- 判定规则（写死）：**真实现** = 该平台仓颉分支有实际逻辑且 native 侧有对应实现（两来源都支持，各附 文件:行）。**静默空壳** = 仓颉侧有该平台分支但只返回常量/空值，或 native 接受数据但不消费。**没接** = `@When` 无该平台分支或 native 无对应符号（附仓颉侧反证 文件:行）。**待确认** = 证据不足以落三态。
- 路径约定：仓颉侧行号相对 `runtime/cjgui/src/`，macOS native 相对 `runtime/cjgui/native/`，其余相对 `runtime/cjgui/platforms/<平台>/native|host/`。
- 仓颉侧平台分支通过 `rg '@When' src/*.cj` 定位；`@When[os != "macOS"]` 分支内部可能只有常量桩，Linux/Windows/OHOS 落进去拿空值——本矩阵不按对称性猜，逐格核对。
- 重大边界事实：**OHOS 的仓颉侧不是主树**，而是冻结快照 `platforms/ohos/snapshot/src/`（369 文件；其中 runtime_renderer_session.cj 仅 2844 行、全文无 `@When`，早于主树的多平台统一改造）。OHOS 各格判定基于该快照 + `platforms/ohos/host/ohos_renderer.cpp`。快照哈希见 platforms/ohos/FINGERPRINT.txt。
- 关键机制：主树共享 FFI 声明集中在 `src/runtime_renderer_session.cj` 的 `foreign {}`（1263 行起）；逐能力用 `@When` 成对包装——macOS 真调用，非 macOS 分支常量桩。native 侧四平台共用同一 `CjguiInternalRendererComposableNodeKind` 枚举（macOS `native/cjgui_internal_renderer.h:255-269`；OHOS 快照头 `platforms/ohos/snapshot/cjgui_internal_renderer.h:245-269` 同款，kind 1–17，11=LAYER_HOST 仅仓颉侧容器）。

三态记号：**真** = 真实现；**壳** = 静默空壳；**无** = 没接；**？** = 待确认。

---

## 第一节 roadmap 条目（E1–E6、F1–F11）

| 行 | 含义 | macOS | Windows | OHOS | Linux |
| --- | --- | --- | --- | --- | --- |
| E1 | 组合终态、同身份草稿恢复/取回、切文档、owner 会话 | 真 | 真 | 真 | 真 |
| E2 | 字素边界、bidi 视觉—逻辑位置、affinity、导航/扩选 | 真 | 真 | 壳 | 真 |
| E3 | 编辑器公开生成、活草稿重排、owner 移交事务 | 真 | 无 | 无 | 无 |
| E4 | 大文档有界窗口、inline 预算、失败回退 | 真 | 真 | 真(部分) | 真 |
| E5 | 富文本 style run、内联内容测量/命中 | 真 | 壳 | 壳 | 壳 |
| E6 | 固定快照租约、撤权/关闭/重装生命周期 | 真 | 真 | 真 | 真 |
| F1 | 阴影（矩形/圆角）、线性渐变、效果输出范围契约 | 真 | 壳 | 真 | 壳 |
| F2 | 帧时钟、可中断补间/弹簧、交互过渡、空闲休眠 | 真 | 真 | 真 | 真 |
| F3 | 效果分组、alpha mask、组透明度、混合模式 | 真 | 壳 | 壳 | 壳 |
| F4 | 背景模糊/材质、窗口级系统材质 | 真 | 真 | 真 | 壳 |
| F5 | VoiceOver/AX、焦点可见性、系统主题/减少动态 | 真 | 壳 | 壳 | 壳 |
| F6a | 多显示器 scale、静态 DPI 接线 | 真 | 真 | 真 | 真 |
| F6b | 运行中动态缩放（不改窗重开） | 真 | ？ | ？ | ？ |
| F7 | 布局/裁剪/效果边界诊断叠加、帧成本汇总 | 真 | 真 | 无 | 真 |
| F8 | 剪贴板/拖放/文件 PNG 扩展 | 真 | 壳 | 壳 | 壳 |
| F9 | 通用重绘/合成复用、提交阶段观测 | 真 | 真 | 壳 | 壳 |
| F10 | 公共目录、手写/生成一致性、独立包消费 | 真 | 真 | 真 | 真 |
| F11 | 节点级亚点平移、一致坐标变换 | 真 | 真 | 真 | 真 |

E1 — macOS：`set_composable_owned_text_session`[MWLO] + AppKit marked text/代理（`native/cjgui_internal_renderer.m`，组合 reanchor 4153 调用、AX 22241）。Windows：FFI 真接 + WndProc 现场冻结 RESULTSTR/COMPSTR 的 IME 槽（`cjgui_windows_renderer.c:330-336`）。Linux：`cjgui_linux_session.c:2634`（is_editable_text_kind）+ owned session 符号；但 Linux native 全目录无 XIM/preedit（rg 无命中），后果：**Linux 上没有系统输入法可组合，组合恢复链路实际不触发，只有 owned 会话的保存/恢复生效**。OHOS：快照编辑链 + `recover_active_text_proxy`[MWLO] + arkts 文本代理（`platforms/ohos/arkts/cjgui-text-proxy.ets`）。

E2 — macOS：`text_position_v1`、`text_stop_resolve`（`native/cjgui_internal_renderer.h` 符号表）+ TextKit。Windows：`cjgui_windows_renderer.c:12297`（text_position_v1 定义）、`:8777`（grapheme_cluster_range）。Linux：text_position_v1/text_visual_neighbor/text_stop_resolve 符号（`cjgui_linux_session.c`）。OHOS：仅有字素边界（`ohos_renderer.cpp:249` grapheme_cluster_range）；`text_position_v1`/`text_visual_neighbor`/`text_stop_resolve` 在 ohos_renderer.cpp 与 cjgui_host_bridge.cpp 无定义（rg 全文无命中）。后果（OHOS 壳）：**OHOS 上依赖精确字符位置/视觉邻居的左右键导航与双向文本落点没有 native 实现，只能退化为按字节近似或被具名拒绝**。

E3 — owner handoff 家族（owner_handoff_begin/bind/complete/seal、accept_owner_command_receipt 等 13 符号）仅 macOS native 有（`native/cjgui_internal_renderer.h`）；仓颉侧对应模块 `composable_ui_mac_owner_handoff.cj` 本身即 mac 专属（17 处 `@When[os == "macOS"]` + 8 处 `@When[os != "macOS"]` 空桩）。后果（Win/OHOS/Linux 无）：**生成候选的接受事务没有 owner 移交链，非 macOS 上生成界面只能走普通 action 提交，无"模型→控件→owner→重排"闭环**。

E4 — macOS：同步 + 异步测量（`src/async_multiline_measure.cj:19-47` FFI 无 @When；mac 实现 `native/cjgui_async_multiline_measure.m`）。Windows：`CjguiAsyncMultilineMeasurePoll`（`cjgui_windows_renderer.c:18325-18345`）。Linux：`cjgui_linux_async_measure.c:239`。同步基础测量四平台皆有（measure_composable_multiline_natural_height[MWLO]）。OHOS(部分)：native 无 `CjguiAsyncMultilineMeasurePoll`（rg 无命中）。后果：**OHOS 上长文本自然高度没有后台测量通道，只能同步测量或退化**。

E5 — `set_composable_text_runs`[MWLO] 四平台都能携带 run；styled 专用测量 `measure_composable_styled_text`、typography 版本仅 macOS（`native_text_typography.cj:49-51`：`@When[os != "macOS"]` 分支返回 `TEXT_SERVICE_UNSUPPORTED` 常量）。后果（Win/OHOS/Linux 壳）：**混合字体/字号 run 的精确测量在非 macOS 返回不支持，布局退化为默认整段排版**；OHOS 绘制侧仍解析 run 上色（`ohos_renderer.cpp:1137` parseTextStyleRuns）。

E6 — 主体在共享核心 `runtime/cjgui/shared_operation_core/src/`（全文仅 2 处 @When，平台无关）；窗口/退出侧 request/complete/retain/release_application_exit_lifecycle_owner[MWLO] 四平台真。差异：`acquire_application_cleanup`/`complete_application_cleanup`/`enable_main_thread_dispatch` 仅 macOS（头文件符号，Win/Linux/OHOS 无）。后果：**非 macOS 上租约退役只在共享核心记账，渲染器侧清理回合钩子（cleanup 回合端点）不存在**。

F1 — macOS 真：阴影 GPU 绘制（`cjgui_internal_renderer.m:10660-10730`）+ 渐变 shader（:11410 顶点字段）。OHOS 真：`ohos_renderer.cpp:6352`（drawShadow）、gradientPresent 消费（:6280 附近绘制循环）。Windows 壳：shadow/gradient 字段仅做 isfinite 校验（`cjgui_windows_renderer.c:5371-5380`），无绘制 pass（rg 'shadowPresent|gradientPresent' 绘制路径 0 命中）。后果（Win）：**声明了阴影/渐变的区域只画平色填充，效果被静默丢弃**。Linux 壳：渐变真（`cjgui_linux_session.c:903-941`）；阴影无任何消费（无 shadowPresent 命中，:1765-1783 的未实现清单也未包含它，属未接）。后果（Linux 阴影）：**矩形阴影完全丢弃，节点照常平色绘制**。

F2 — 动效定义共享无平台分支（`src/composable_ui_animation.cj`、`composable_ui_position_motion.cj` 无 @When），由 `CjguiComposableUiWindowTurnScheduler` 驱动（mac/Win/Linux 共用，`src/linux_application_host.cj:14` 起、`src/windows_application_host.cj:9` 起）；OHOS 快照 `snapshot/src/composable_ui_window.cj`（10899 行）含同一调度器（:563）+ 宿主 RedrawJob 队列（`ohos_renderer.cpp:4440-4756`）。四平台真。

F3 — 拆三个子能力：
- alpha mask：mac 真（effectGroup/mask 体系）；win 真（`cjgui_windows_renderer.c:522-549` sceneMaskPixelShader、:1828-1849 mask shader 编译）；linux 无（rg sceneMask=0）；ohos 无（rg sceneMask=0）。后果（Linux/OHOS）：**遮罩声明被接受但不生效，被遮内容原样全量绘制**。
- 组透明度/离屏合成：mac 真；win 壳（`cjgui_windows_renderer.c:7339` 把组 opacity 逐节点乘进 alpha，无离屏合成；Linux 同款做法在 :1766-1771 被自家注释判为会双重混合，Windows 未做该修正）；linux 壳（`cjgui_linux_session.c:1765-1771` 注释明示"left unpainted instead of approximated"）；ohos 真（`ohos_renderer.cpp:6289-6319` 整组画进一个 layer 后一次性 blend）。后果（Win）：**组透明度按逐节点近似，重叠子内容会加深**；后果（Linux）：**效果组整体不透明度完全不生效**。
- 混合模式：mac 真（normal/multiply）；win 无（rg MULTIPLY=0）；linux 无；ohos 真（`ohos_renderer.cpp:6318` BLEND_MODE_MULTIPLY）。后果（Win/Linux）：**multiply 等混合声明被忽略，按普通覆盖绘制**。

F4 — 内部背景模糊：mac 真（backdrop 体系 161 处引用）；win 真（`draw_windows_backdrop_blur`，`cjgui_windows_renderer.c:7330-7360+`，失败回退未模糊）；linux 壳（`cjgui_linux_session.c:1772-1775` 注释明示"no correct blur exists here yet"，声明被接受）；ohos 真（`ohos_renderer.cpp:1275-1281` BackdropFrame 离屏位图路径）。后果（Linux）：**背景模糊声明被静默接受但渲染为不模糊**。系统窗口材质：mac 真（`cjgui_internal_renderer.m:4259/35034/35674` NSVisualEffectView）；Win/OHOS/Linux 无对应实现（rg 无系统材质 API）。后果：**非 macOS 窗口没有系统级材质/毛玻璃背景，只能用仓颉声明的背景色**。

F5 — 拆子能力：
- AX 属性/动作（读屏）：mac 真（`cjgui_internal_renderer.m:22241-22242` NSAccessibility role/element、:17975 AXAction）；win 无（全文无 UIA）；linux 无（无 ATK/AT-SPI）；ohos 无（host 与 arkts 均无 accessibility 代码）。后果：**非 macOS 上框架控件对外部读屏完全不可见，语义只存在于仓颉层**。
- 键盘导航/焦点：mac 真；win 真（WM_KEYDOWN/VK_ 23 处，TAB_TITLE 焦点停靠 :2880）；linux 真（`cjgui_linux_session.c:2643-2649` is_keyboard_focus_kind、:3786 tab_title_is_stop）；ohos 真（`ohos_renderer.cpp:6686/6723` 焦点种类、focus_composable_node[MWLO]）。
- 语义帮助传输：mac 真；win/linux/ohos 壳（`src/runtime_renderer_session.cj:5385-5387`：`@When[os != "macOS"]` 的 `internalRendererSetComposableSemanticHelp` 直接返回 `CJGUI_INTERNAL_RENDERER_OK`）。后果：**帮助文本在任何非 macOS 平台都"成功"地不传输**。
- 系统主题/减少动态：mac 真；win 减少动态真（:9389-9391 SPI_GETCLIENTAREAANIMATION）、主题跟随无（backgroundColorScheme 只存声明值 :932）；linux 主题壳（`cjgui_linux_session.c:2349-2389` 只存声明值，缺省 LIGHT）；ohos 无（rg dark/colorScheme 无命中）。后果（Win/Linux）：**框架不读系统深色模式，界面配色只随调用方声明**。

F6a — DPI/scale：mac 真；win 真（s->dpi 驱动全部几何 :5382、backdrop sigma :7350）；linux 真（window_scale 符号 + deviceScale 进绘制变换 :1439）；ohos 真（XComponent 物理像素与核心投影坐标域统一，`ohos_renderer.cpp:14722` 注释）。F6b — 运行中动态缩放：mac 真（test_toggle_composable_backing_scale 等链）；win/linux/ohos 待确认（未检索到运行中 DPI 变更处理；Windows WM_DPICHANGED 无命中）。

F7 — `set_diagnostic_overlay`/diagnostic_*[MWL.]：mac/win/linux 真；ohos 无（ohos_renderer.cpp 无 diagnostic_ 符号）。后果（OHOS）：**无法打开布局/裁剪/效果边界叠加，诊断只剩日志通道**。

F8 — 拆子能力：
- 数据传输事件环（copy/paste/drop 事件协议）：configure/item/format/source_*[MWLO] 四平台真。
- OS 剪贴板：mac 真（NSPasteboard）；win 无（rg clipboard=0）；linux 无（无 X11 selection 拥有者代码）；ohos 无（无 pasteboard）。后果：**非 macOS 上 Ctrl-C/V 不接系统剪贴板，框架内传输事件环仍是活的**。
- PNG 准入：prepare/finish_composable_png_transfer[MWL.] mac/win/linux 真；ohos 无（ohos_renderer.cpp 无此符号；图片走 prepare_composable_image_resource[MWLO] 路径）。后果（OHOS）：**PNG 准入/拒绝事务（含记账回执）不存在，剪贴板/文件 PNG 消费场景不成立**。
- 拖放：mac 真；win/linux/ohos 无（win 无 RegisterDragDrop/WM_DROPFILES，rg 无命中）。后果：**非 macOS 无真实 OS 拖入，drop 事件只能由应用自行注入**。

F9 — 批量节点准备/复用：mac 真、win 真（prepare/reuse_composable_node_batch[MW..]）；linux/ohos 壳→单节点回退（`src/runtime_renderer_session.cj:3421-3424`：OHOS 分支的 batch 包装转调逐节点 scalar 路径；linux native 无 batch 符号）。后果（Linux/OHOS）：**大场景准备走逐节点路径，批量复用与截止时间预算不生效（功能等价、性能路径退化）**。提交观测（present/query/ack/ticket_stats[MWLO]）四平台真；partial present 四平台均无（与 roadmap §2 :98 声明一致，非落后项）。

F10 — 生成式目录与手写同规则是仓颉共享层（`src/composable_ui_generated.cj` 等，OHOS 快照同文件存在）；四平台真（快照层）。支持面受各平台底层能力限制（见 F3/F5/F8 各格）。

F11 — 节点亚点平移/坐标变换：mac 真（translateY 23 处进 shader 场景点）；win 真（geometry.translateY 28 处 + rotation :7332）；linux 真（`cjgui_linux_session.c:1431/1439-1455` slot_paint_transform 含平移/旋转/缩放）；ohos 真（translateY 28 处）。

---

## 第二节 组件工厂（按 node kind 归并）

工厂行号：`src/composable_ui.cj`（ Vertical :5429、Horizontal :5435、Stack :5444、Wrap :5454、AspectRatio :5467、Spacer :5479、SplitView :5497、Tabs :5580、ScopedSplitView :5645、ScopedActionRow :5723、Slider :5745、Text :5772/5788、Button :5819/5828、TextInput :5840/5854、IntegerInput :5864、MultilineTextInput :5879、BooleanInput :5892、BoundFormField :5936、SelectableListRow :6020、Image :6044、ImageFromTransfer :6064、ScrollArea :6077/6088、VirtualList :6098、VariableHeightList :6112、LayerHost :6125、AnchoredLayer :6132、AnchoredLayerWithReference :6146、ContextMenuLayer :6160、ContextMenuBounds :6173、DialogLayer :6193、DialogLayerWithReference :6204）；Grid `src/composable_grid.cj:77`；Tree `src/composable_ui_tree.cj:763`；VectorGraphic `src/composable_vector_graphics_component.cj:10`；GeneratedSliderComponent `src/composable_ui_generated.cj`；ExperimentalDocumentPreview `src/runtime_renderer_session.cj:5165`。kind 常量定义 `src/composable_ui.cj:16-53`。

| 行（工厂 → kind） | macOS | Windows | OHOS | Linux |
| --- | --- | --- | --- | --- |
| Vertical/Horizontal（:5429/:5435 → 1/2） | 真 | 真 | 真 | 真 |
| Stack（:5444，LAYOUT_STACK） | 真 | 真 | 真 | 真 |
| Wrap（:5454，LAYOUT_WRAP） | 真 | 真 | 真 | 真 |
| AspectRatio（:5467，LAYOUT_ASPECT_RATIO） | 真 | 真 | 真 | 真 |
| Spacer（:5479） | 真 | 真 | 真 | 真 |
| Text（:5772 → 3） | 真 | 真 | 真 | 真 |
| Button（:5819 → 4） | 真 | 真 | 真 | 真 |
| TextInput（:5840 → 5） | 真 | 真 | 真 | 真 |
| IntegerInput（:5864 → 6） | 真 | 真 | 真 | 真 |
| MultilineTextInput（:5879 → 10） | 真 | 真 | 真 | 真 |
| BooleanInput（:5892 → 7） | 真 | 真 | 真 | 真 |
| ScrollArea（:6077 → 8） | 真 | 真 | 真 | 真 |
| Image / ImageFromTransfer（:6044/:6064 → 9） | 真 | 真 | 真 | 真 |
| LayerHost（:6125 → 11，仓颉侧容器） | 真 | 真 | 真 | 真 |
| AnchoredLayer/ContextMenuLayer/DialogLayer 家族（:6132-:6206 → 层 + 12） | 真 | 真 | 壳 | 真 |
| SplitView / ScopedSplitView（:5497/:5645 → 13） | 真 | 真 | 真 | 真 |
| Slider / FieldSlider（:5745 → 14） | 真 | 真 | ？ | 真 |
| VectorGraphic（→ 15） | 真 | 壳 | 壳 | 壳 |
| Tabs（:5580 → 16/17） | 真 | 真 | ？ | 真 |
| Tree（tree.cj:763） | 真 | 真 | 无 | 真 |
| VirtualList（:6098） | 真 | 真 | 真 | 真 |
| VariableHeightList（:6112） | 真 | 真 | 真 | 真 |
| SelectableListRow（:6020） | 真 | 真 | 真 | 真 |
| Grid（grid.cj:77） | 真 | 真 | 真 | 真 |
| CardGrid（card_grid.cj，适配器类） | 真 | 真 | 无 | 真 |
| BoundFormField/Groups + FormFeedback 家族（:5936 起） | 真 | 真 | 真 | 真 |
| CommandToolbar / ContextCommandMenuLayer + Projection | 真 | 真 | 壳 | 真 |
| Generated UI 入口 / GeneratedSliderComponent | 真 | 真 | 真 | 真 |
| ExperimentalDocumentPreview / QueueSubmitShellReady（session:5165） | 真 | 真 | 真 | 真 |
| Table / CollectionView / FilteredList（内部构建，无独立 public 工厂） | 真 | 真 | 真 | 真 |

容器/布局原语（行 1–5）：四平台共享布局引擎（`CjguiComposableUiLayoutEngine`，kind 1/2 普通节点 + 布局意图，`src/composable_ui.cj:63-66`），native 按普通矩形/文本节点绘制：mac 通用绘制（`cjgui_internal_renderer.m:11871` 起的节点绘制）、win 通用 quad/文本路径（:7330-7360）、linux 圆角/渐变/文字 CPU 几何（`cjgui_linux_session.c:1784+`）、ohos OH_Drawing 绘制循环（`ohos_renderer.cpp:6200-6400`）。

Text/Button（行 6–7）：四平台真（win 文本 atlas + BUTTON :2880；linux 文字 quads；ohos 排版与 run 上色 :1137）。

文本输入三件套（行 8–10）：mac AppKit 代理；win IME 冻结槽（:330-336）；linux `is_editable_text_kind`（:2634-2643）+ fontconfig 排版（`cjgui_linux_text.c`）；ohos `isEditableTextKind` 覆盖 5/6/10（`ohos_renderer.cpp:386-388`）+ arkts 代理。

BooleanInput（行 11）：ohos 真（`ohos_renderer.cpp:8825` kind==kKindBooleanInput 分支、:460 kEvBooleanChanged）。

ScrollArea/Image（行 12–13）：ohos scroll 真（SCROLL_AREA 8 处引用 :7951 等）、图片 fit/fill 几何（:388 OhosImageGeometry）。

AnchoredLayer/ContextMenuLayer/DialogLayer 家族（行 15）——OHOS 壳：菜单项投影/提交 [MWLO] 真（`ohos_renderer.cpp` 有 set_composable_command_menu_item、configure/commit_composable_command_menu），但 `set_composable_context_menu_guard` 仅 [MWL.]（OHOS 无符号），`stage_modal_return`/`modal_return_receipt` 仅 macOS（`native/cjgui_internal_renderer.h`；仓颉侧无 OHOS 分支）。后果（OHOS 壳）：**弹出层/菜单能出现，但没有防重入门与模态返回结算，重复触发和收尾语义弱于其他平台**。

SplitView（行 16）：手柄为普通可交互节点，拖拽走通用指针事件 + SET_SPLIT_SIZE 操作（mac/win/linux/ohos 指针事件链各真：win :2995-2998 布局租约、linux 按钮/激活 :3838 switch、ohos POINTER_* 事件 37-40）。native 无 split 专属分支属设计内（见 kind 13 命名 SPLIT_DIVIDER 注释）。

Slider（行 17）——OHOS 待确认：mac 真（SLIDER 11 处 + 指针 FIFO）；win 真（:3214 SLIDER 专属分支、:2995 拖拽租约）；linux 真（:2649 焦点种类 + :3838 键盘激活）；ohos_renderer.cpp 无任何 slider 引用（rg 0 命中），仅通用节点绘制与通用激活。待确认点：**快照层 slider 值联动（cjguiSliderValueForPointer）在 OHOS 通用指针链上是否闭环未核**；写不出后果，标待确认。

VectorGraphic（行 18）——Win/OHOS/Linux 壳：mac 真（`cjgui_internal_renderer.m` VECTOR_GRAPHIC 10 处 + vector render/submission stats 测试符号）；win 场景节点校验接受 kind≤17（:5360-5362）但矢量载荷无任何绘制消费（rg vector 绘制 0 命中）；linux 激活 case 认识该 kind（:3841）但绘制无矢量路径；ohos 无 kind 校验亦无矢量代码（rg 'vector' 仅 STL 头）。后果：**矢量图形在 Windows/Linux/OHOS 上被静默接受并退化为普通底色矩形，图形内容丢失**。

Tabs（行 19）——OHOS 待确认：mac 真（TABS/TAB_TITLE 3+19 处）；win 真（TAB_TITLE 焦点停靠 :2880）；linux 真（:3786-3819 键盘停靠、:3840 激活）；ohos：kind 16/17 无任何专门处理，仅通用 ACTIVATE（事件 27）可用。待确认点：**tab 键序导航与 accepted 状态在 OHOS 快照层是否闭环未核**。

Tree / CardGrid（行 20/24）——OHOS 无：`platforms/ohos/snapshot/src/` 全目录 rg `cjguiComposableTree`、`CjguiComposableUiCardGrid` 无命中（VirtualList/VariableHeightList/Preview 均在）。后果：**OHOS 快照没有树/卡片网格工厂，调用即编译失败，属源级缺失而非运行时退化**。

Table/CollectionView/FilteredList（行 30）：内部构建器（`src/composable_ui_table.cj:118` cjguiTableMergeSort 为 private；collection_view/filtered_list 仅类与内部函数），统一经 VariableHeightList 引擎落地，无平台分支。

CommandToolbar（行 27）——OHOS 壳：菜单项投影 [MWLO] 真；`set_composable_command_completion_policy`/`set_composable_command_identity` 仅 macOS（`native/cjgui_internal_renderer.h`，非 macOS 仓颉侧无分支）。后果（OHOS）：**命令补全策略与身份解析不生效，工具栏命令仍可触发但补全候选行为不可用**。`README.md:618` 关于"菜单和快捷键仅在 macOS bridge 平台边界内成立"的限定仍准确（AppKit 菜单 vs 自绘菜单是两回事）。

---

## 第三节 四平台 native 能力符号分组

记号同前。macOS 列以 `native/cjgui_internal_renderer.h` 355 符号为基线；组内逐符号核对四平台实现（win/linux/ohos 判据为 `cjgui_windows_renderer.c` / `platforms/linux/native/*.c` / `platforms/ohos/host/*.cpp` 中的定义或注册）。

| 能力组 | macOS | Windows | OHOS | Linux |
| --- | --- | --- | --- | --- |
| 窗口生命周期（create/destroy/activate/window_frame/标题/occupied_session_count） | 真 | 真 | 真 | 真 |
| 场景提交/呈现（configure/set_node/set_geometry/present/query/ack） | 真 | 真 | 真 | 真 |
| 窗口背景快照（stage_window_background/window_background_snapshot） | 真 | 真 | 无 | 真 |
| 准备管线（begin/prepare/advance/promote/cancel） | 真 | 真 | 真 | 真 |
| 批量准备/复用（node_batch/reuse_batch） | 真 | 真 | 壳 | 壳 |
| 文字测量（measure_text/multiline_natural_height/text_runs） | 真 | 真 | 真 | 真 |
| typography 专用测量（*_typography、styled、异步 typography） | 真 | 壳 | 壳 | 壳 |
| 异步文本测量（cjgui_async_composable_*、*Poll/*Release） | 真 | 真 | 无 | 真 |
| 文字位置/字素（text_position_v1/text_stop_*/grapheme/visual_neighbor） | 真 | 真 | 壳 | 真 |
| IME/组合（arm/reanchor_composition/composed_prefix） | 真 | 真 | 壳 | 壳 |
| owned 文本会话/代理恢复（owned_text_session/recover_active_text_proxy） | 真 | 真 | 真 | 真 |
| 选区安装/来源范围（install_owned_source_selection、source_install_gate/settlement） | 真 | 真 | 壳 | 真 |
| installed-range（arm/receipt/activate/cancel/claim/copy/ack） | 真 | 真 | 无 | 真 |
| 跨选择 transfer（selection_transfer_* 21 符号、candidate selection） | 真 | 壳 | 壳 | 壳 |
| 选区绘制发布（stage/finish_selection_paint_publication、selection_background_version） | 真 | 真 | 壳 | 真 |
| 指针捕获（cancel/epoch/gesture_key/continuation） | 真 | 真 | 真 | 真 |
| 指针选择派发（freeze/bind/complete/refuse_pointer_selection_dispatch） | 真 | 壳 | 壳 | 壳 |
| 输入泵/owner 消费（pump_event/main_pumped_*/owner_consumed_*） | 真 | 真 | 壳 | 真 |
| owner handoff（owner_handoff_*、command receipt、trace 家族） | 真 | 壳 | 壳 | 壳 |
| 数据传输（configure/item/event_*/png_transfer） | 真 | 真 | 壳 | 真 |
| 图片资源（prepare_image/image_resource_state） | 真 | 真 | 真 | 真 |
| 命令/上下文菜单（command_menu_item/configure/commit/guard/modal_return） | 真 | 真 | 壳 | 真 |
| 表单/共享操作（shared_form/shared_collection/shared_operation） | 真 | 真 | 真 | 真 |
| 诊断（diagnostic_*、overlay、workload） | 真 | 真 | 无 | 真 |
| 应用退出/清理（exit lifecycle、cleanup、main_thread_dispatch） | 真 | 真 | 真 | 真 |
| 测试/验证 harness（test_* 约 150 符号） | 真 | 壳 | 无 | 壳 |

组级后果说明（非真格）：
- 窗口背景快照 OHOS 无：**OHOS 不能回读窗口背景事实，背景相关事务只能单向声明**（`ohos_renderer.cpp` 无 stage_window_background/window_background_snapshot 符号）。
- installed-range Linux 双门注意：`internalRendererInstalledRangeSupported()` Linux=false（`src/runtime_renderer_session.cj:2624-2628`，注释称"本阶段不实现 installed-range 家族"），而 `internalRendererSourceRangeSupported()` Linux=true（:2633-2638）指向同一批 sidecar 符号（arm/receipt/activate/cancel/claim/copy/ack）。本行 Linux 判"真"指生产者侧链（:2636 注释明列消费点）；:2624 假门管辖的子机制（claim/恢复侧）未逐点核到消费，**不扩大判为全家族真**。
- 批量准备 Linux/OHOS 壳：见 F9 行（`src/runtime_renderer_session.cj:3421-3424` OHOS 分支显式转调逐节点；linux native 无 batch 符号）。
- typography 测量 Win/OHOS/Linux 壳：`src/native_text_typography.cj:49-51` 等非 macOS 分支返回 UNSUPPORTED 常量（E5 后果）。
- 异步测量 OHOS 无：见 E4 行。
- 文字位置 OHOS 壳：grapheme 有（`ohos_renderer.cpp:249`），position/neighbor 无（E2 后果）。
- IME/组合 OHOS/Linux 壳：`arm_composition_reanchor`[MWL.]（OHOS 无符号）；`cancel_composition` 反而是 [WLO]（macOS 头无此名，其取消走 marked text 协议）。后果（Linux）：**无系统 IME，组合锚定保护不触发**；后果（OHOS）：**组合 reanchor 在快照/宿主均未接**。
- 选区安装/来源范围 OHOS 壳：仓颉门 `internalRendererSourceRangeSupported()` OHOS 分支 false（`src/runtime_renderer_session.cj:2641`）；Windows 有独立结算真链（`internalRendererWindowsSourceSettlementSupported()` :2658-2660 + source_install_receipt/finish/gate :2667-2710）；Linux 生产者侧真（`platforms/linux/native/cjgui_linux_installed_range.c` + 门 Linux=true :2633-2638）。`source_handoff_*` 5 符号仅 macOS（跨窗口移交，归入下一行 transfer 的边界）。后果（OHOS）：**来源范围安装链不可用，文本编辑接受缺少范围级结算**。
- 跨选择 transfer 非macOS 壳：`internalRendererSelectionTransferSupported()` 仅 macOS=true（`src/runtime_renderer_session.cj:2650-2656`）；Win/Linux 显式 false 走 restore 路径（:2653-2654 注释）；OHOS 落 `@When[os != "macOS" && os != "Windows" && os != "Linux"]` 假分支。后果：**A→B 选择移交会话（source_handoff_* 与 capture/install/verify/commit 全家）只有 macOS 有**。
- 选区绘制发布 OHOS 壳：`internalRendererSelectionBackgroundVersion()` OHOS 分支返回 0（`src/runtime_renderer_session.cj:2142-2144`），且 `selection_background_version` FFI 声明本身不含 OHOS（:1304-1306 `@When[os == "macOS" || os == "Windows" || os == "Linux"]`）；注释（:1300-1303）写明返回 0 会让候选场景整场被拒（selection_background_backend_unsupported）。后果（OHOS）：**按主树契约，OHOS 候选场景会因选区背景版本 0 被整场拒绝；现行 OHOS HAP 依赖旧快照树绕开此门**。
- 指针选择派发非macOS 壳：freeze/bind/complete/refuse 四符号 mac-only（`src/runtime_renderer_session.cj:5325-5346` foreign 块 `@When[os == "macOS"]`；非 macOS 包装返回 0/OK 常量 :5348-5372）。后果：**非 macOS 指针发起的选择没有原生 FIFO 溯源，owner 校验只能靠共享层票据**。
- 输入泵 OHOS 壳：`owner_consumed_input_provenance` Linux/OHOS 分支返回全零（`src/runtime_renderer_session.cj:2611-2621` 注释明示"具名拒绝，不伪造"）。后果（OHOS/Linux）：**依赖已消费输入来源票据的 owner 完成守卫会具名拒绝，而不是放行**。
- owner handoff 非 macOS：见 E3 行。
- 数据传输 OHOS 壳：`data_transfer_event_binary_size/copy/delivery_ordinal/expected_owner_version`、`set_composable_data_transfer_item_bytes` 均为 [MWL.]（OHOS 只有 format/source_id/identity/kind 四个只读字段）。后果（OHOS）：**传输条目只有元数据，二进制载荷通道不存在，剪贴板级内容交换不成立**。
- 命令菜单 OHOS 壳：guard/modal_return/completion_policy/identity 缺失（见第二节 CommandToolbar 行）。
- 诊断 OHOS 无：见 F7 行。
- 测试 harness：`test_*` 约 150 个符号仅 macOS（`native/cjgui_internal_renderer.h`）；Windows 侧仅少量 debug_*/contract_* 探针（`cjgui_windows_renderer.c` debug_last_exec_tid 等），Linux 仅 ABI_TRACE 环境变量日志。后果：**Windows/Linux/OHOS 上依赖注入/探针式验收不可用，只能走外部驱动**。

---

## 第四节 文档落后于代码

以下为「docs/ 或 roadmap 声称缺失/待做/未发布，但源码已有实现」的条目。判定仅据源码；不含仅"待验证"类消费声明。

1. **只读文本溢出（textMaxLines/textOverflow）——README 声称仅 macOS，实际 Linux/OHOS 已实现。**
   - 文档：`runtime/cjgui/README.md:397-398`「当前实际绘制消费仅 macOS；Linux/Windows 原生绘制尚未接入，OHOS 冻结副本也未移植」。
   - 源码：Linux `platforms/linux/native/cjgui_linux_text.c:1292-1334`（layout_limited，U+2026 尾省略）+ `cjgui_linux_session.c:882`（session 调用）；OHOS `platforms/ohos/host/ohos_renderer.cpp:7064-7065/7390-7395`（maxLines/ellipsis 进排版 extras）；Windows `platforms/windows/native/cjgui_windows_renderer.c:5224` 仅 ABI 注释声明字段、无绘制消费（此平台文档说法仍成立）。
   - 边界：Linux/OHOS 属"已实现"；Windows 仍缺；文档三条断言里两条已过时。

2. **应用内部背景模糊——README 声称 OHOS snapshot 未发布，OHOS native 后端已实现。**
   - 文档：`runtime/cjgui/README.md:340-341`「OHOS snapshot 尚未发布该能力，目录单列 backdrop_blur=macos:experimental_supported,ohos:unpublished_snapshot」。
   - 源码：`platforms/ohos/host/ohos_renderer.cpp:1275-1281` BackdropFrame 离屏位图 + 模糊路径（OH_Drawing 无画布回读，先拷贝再滤波）。快照仓颉侧声明确实未带（README 对 snapshot 的表述部分成立），但 native 能力已超出文档描述——「首个成熟版本」边界核对时不应把 OHOS 模糊记为从零开发。

3. **文字位置/视觉邻居公共符号——roadmap 把 E2 列为缺口，macOS+Windows+Linux 已有公共实现。**
   - 文档：`docs/plans/2026-09-26-framework-capability-roadmap.md:111`（E2「当前E新能力」/缺口清单项）；`:156`（bidi/affinity「需按反例补齐」）。
   - 源码：`native/cjgui_internal_renderer.h`（text_position_v1/text_stop_resolve/text_stop_neighbor）；Windows `cjgui_windows_renderer.c:12297/8777`；Linux `cjgui_linux_session.c`（text_position_v1/text_visual_neighbor/text_stop_neighbor）；OHOS `ohos_renderer.cpp:249`（grapheme）。仓颉侧公共入口 `src/composable_ui.cj`（cjguiTextGeometryCaretRect/cjguiTextStopResolve/cjguiTextVisualNeighbor/cjguiGraphemeClusterRangeUtf8 等）。
   - 边界：E2 的"按反例补齐"仍是有效要求（消费证据未采信），但"从零开发"不成立；三平台 native 已有公共位置查询原语，OHOS 缺。

4. **F3/F4 的跨后端效果——roadmap 声明不覆盖其他后端，Windows/OHOS 实际已带相当部分。**
   - 文档：`docs/plans/2026-09-26-framework-capability-roadmap.md:129`（F1「其他后端不由此自动覆盖」）、`:131`（F3「不扩称所有模式或 H 后端」）、`:132`（F4「OHOS 后端…另验」）。
   - 源码：Windows alpha mask（`cjgui_windows_renderer.c:1828-1849`）+ 背景模糊（:7330）；OHOS 阴影/渐变/效果组/multiply 混合（`ohos_renderer.cpp:6280/6289-6319/6352`）+ 背景模糊（:1275）。Linux 明确未画（:1765-1783 自家注释），与文档一致。
   - 边界：这些是"保守范围声明"而非"缺失断言"；列此处是因为它们直接决定「首个成熟版本」能对 Windows/OHOS 声明什么——效果层在两平台已不是空白。

5. **布局原语 Stack/Wrap/AspectRatio/Spacer——核对结果：不落后。**
   - 审计下发示例猜测其"近期新增、文档未跟上"；核实：`src/composable_ui.cj:5444/5454/5467/5479` 已实现，且 roadmap `:37`（2026-10-19 路线收束）已明写「已有公共实现与限域消费，不再列为从零补齐」，`runtime/cjgui/LAYOUT_PRIMITIVES.md` 整页即其文档。此条无文档落后，仅在此关闭该猜测，防止重复立项。

6. **Linux installed-range 生产者侧——roadmap 缺口表未提及，源码+门控已接通。**
   - 文档：roadmap `:121`（H6）及缺口表未列 Linux 选区链；基线表 `:99` 把选区几何归为 macOS 基线。
   - 源码：`platforms/linux/native/cjgui_linux_installed_range.c`（511 行，arm/receipt/active_receipt/activate/cancel/claim/copy/ack/release 全家）+ 仓颉门 `internalRendererSourceRangeSupported()` Linux=true（`src/runtime_renderer_session.cj:2633-2638`，注释点名该 sidecar 文件）。
   - 边界：Linux 的 installed-range 是"示例正文唯一编辑入口"的生产者侧；跨选择 transfer 仍 macOS-only（:2650-2656），文档若按平台粒度更新能力清单应记 Linux 该项为真。

**经核对不属于落后的条目**：`ACCESSIBILITY.md:17`「未接通其他平台原生辅助服务」与本矩阵 F5-AX 格一致（win/linux/ohos 确无 UIA/ATK/a11y 桥）；`README.md:618` 菜单仅 macOS AppKit 边界的限定与源码一致；roadmap `:98`「native 绘制仍整帧」与四平台无 partial present 一致。

---

## 统计

三态计数（按本文件所有判定格；？单列）：

| 平台 | 真实现 | 静默空壳 | 没接 | 待确认 |
| --- | --- | --- | --- | --- |
| macOS | 74 | 0 | 0 | 0 |
| Windows | 61 | 11 | 1 | 1 |
| OHOS | 41 | 21 | 9 | 3 |
| Linux | 57 | 15 | 1 | 1 |

- 每平台 74 格（74 行）；四平台合计 296 格：真 233、壳 47、无 11、待确认 5。
- 矩阵总行数：74 行（第一节 18 行，含 F6 拆分；第二节 30 行；第三节 26 行；F3 三子行、F5 四子行、F8 三子行按独立行计入）。
- 文档落后条目：5 条实条 + 1 条「核对后不落后」关闭（第 5 条布局原语）。
- 待确认清单（5 格）：
  1. F6b 运行中动态缩放 × Windows / OHOS / Linux（3 格）：未检索到运行中 DPI/缩放变更处理。
  2. Slider × OHOS（第二节行 17）：快照层指针→值联动未核闭环。
  3. Tabs × OHOS（第二节行 19）：tab 键序导航与 accepted 状态在快照层未核。
- 判定来源声明：本矩阵全部格基于上述 HEAD 与工作区状态的源码静态核对；「真实现」表示两来源（仓颉分支 + native 符号/绘制路径）均可指到文件:行，**不等价于已通过运行验收**——运行证据按仓库规则另行采信，本文件不背书任何平台的实际消费结论。
