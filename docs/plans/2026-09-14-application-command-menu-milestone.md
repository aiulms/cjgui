# 大阶段：应用命令、菜单与快捷键统一接入

2026-09-14，沿用户持续推进授权，原任务 Terra/xhigh 协调 Luna/high 实施完整阶段，原目录、不提交推送。

## 目标与方向

开发者声明一个“保存”“撤销”或“当前记录操作”，可由窗口按钮、菜单和快捷键触发；切换窗口、焦点和弹层后，命令可用性与目标随已接受状态变化。外部系统继续通过既有授权动作操作同一真实内容，不另造命令业务状态。交付可供其他桌面应用复用的命令/菜单接入能力，而不是增加规则编辑器按钮或制作宣传页。

上一图片阶段已按受控范围接受：指导抽查 orphan与暂缓需求区分、accepted需求恢复/显式preload、资源压力及最终独立导出日志。9图、36MiB场景与65次churn区分缓存与scene引用，20显式预加载有界推进，真实application 30批次/输入与图片加载交错，含空格导出的公共双窗消费者共享一次加载，payload `0b6908f5ac43cdda730eb96ea8921b012092ce7de7d3d5a830e35e4dc42de2b4`。不重跑其完整资源矩阵；后续发现相关实际缺陷按依赖承接。

复用 [设计意图导航](DESIGN_INTENT_INDEX.md)、[框架避坑](../research/gui-framework-pitfalls-intelligence.md) 的主线程重入/关闭、焦点与布局单一真相，以及 [共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md) 的owner与权限边界。已有 `CjguiComposableUiCommand/Shortcut`、`declareCommand/replaceCommands`、scene participant、scope/reference、层宿主/焦点、native输入FIFO和application target是实现起点；查相关旧命令/系统集成阶段资产，不复活退役Action Router或新建并行命令runtime。

六主线取舍：已有GPU/图片/文字路径继续使用，本轮增加普通开发者应用接入与人的键盘/菜单操作；组件组合提供稳定命令引用，语义动作保持同一真实执行入口，调度验证重入和窗口生命周期。自绘内容路线不变，系统菜单用窄AppKit适配属于平台服务，不改成原生控件套壳。

## 实施范围

1. **可组合命令声明。** 审查现有公开命令必须有数字 targetNodeId 和Command快捷键的限制，演进为最小兼容声明：稳定命令身份、可选快捷键、显示名称、可用/勾选状态及稳定目标引用。优先复用已接受scene中的节点/作用域引用与candidate命令事务，不要求应用提前计算动态节点ID。现有数字ID/快捷键接口保留。明确重复声明、快捷键冲突、目标缺失/移除、候选拒绝及代际过期处理；不静默选第一个目标。
2. **菜单消费与单一执行入口。** 仓颉声明菜单分组/项目/必要分隔，至少接通应用菜单栏与现有自绘上下文菜单的共用命令表示。按钮可沿现有真实owner动作，菜单/快捷键进入相同Cangjie dispatch，不能在native复制业务分支。应用或窗口菜单如何合成由Terra确定明确且简单的优先级，不做完整桌面Shell或插件菜单系统。若现有命令可直接扩展就复用；不为了共用而强迫所有外部动作先物化屏外控件。
3. **窗口/焦点/弹层正确路由。** A/B窗口可拥有同名操作与相同快捷键，当前key窗口与焦点作用域决定人的触发目标；窗口切换、弹窗覆盖、关闭A、命令回调改变场景或关闭窗口时不能误写B或访问释放资源。菜单显示期间状态变化，执行时仍复核当前目标、generation和可用性，不能只凭打开时快照。已有授权不因菜单或弹窗重复索取，真实业务确认条件仍遵守。
4. **系统文字服务与正常消费。** 文本框中的复制/剪切/粘贴、选区和系统组合输入沿现有TextKit/AppKit处理，应用快捷键不能抢掉未声明的标准文字行为。只做必要系统输入集成回归，不自研IME，不扩全量VoiceOver项目。规则与文档或另一个既有正常消费者实际使用菜单/快捷键，至少一个自绘上下文菜单复用命令、同进程两个窗口选择不同真实目标。外部授权动作修改内容后，菜单可用/勾选状态与界面一起更新，人可继续执行；公开接口不绕过原权限/CAS/owner。

## 验收与性能约束

- 对真实缺口建立可区分复现与回归：动态重排后稳定目标、不同窗口相同快捷键、弹层覆盖、disabled操作、旧菜单回调、执行中关闭/重入、候选失败保持旧命令、撤销或保存的真实内容读回。新增类型不存在只算编译契约RED，不当旧功能失败。
- 普通native菜单选择/快捷键事件至少各一次进入正式application路径，内容和可见状态对应；受控测试补竞态/错误，不冒称人工物理键盘。前台可用时操作隔离正常bundle，锁屏则继续独立代码/测试/导出并保留具体未验，不反复解锁。
- 菜单校验/只读查询不得无故build/layout/提交，也不能阻塞等待外部模型。用现有计数证明空闲/反复校验无多余工作；命令调度若有可疑开销再用真实单调时钟针对性测量，不补跑完整图片/大文档矩阵。所有派生命令/菜单绑定有明确窗口或application生命周期，关闭后清理回调/引用。
- 公共API说明稳定性等级、参数/失败语义和最小消费例子。最终源码含空格独立导出，实际构建运行使用新公共菜单能力的消费者；菜单资源与平台桥接来自导出包，不拷private native到消费者，不硬编码作者路径。保持纯UI不需外部服务，LICENSE/NOTICE随包。
- 相关核心/窗口/native/两消费者、根build、声明/FFI影响检查与diff检查按AGENTS；同target串行构建。保留原始source/binary/预览payload/日志。已有资源/性能接受范围仍独立，不声称GPU完成、物理呈现、安装公证或发布。

## 分工与持续推进

Terra负责公共声明兼容、菜单宿主与事件/焦点路由、主线程生命周期及复杂实现；接口和写集明确后给Luna完整的消费者迁移、绑定回归、文档和独立导出工作包，明确的小实现也交Luna。默认一个Luna，原生消息回实际父代理，构建和前台由Terra协调，不让子代理向指导逐项请示。只审关键风险，不把对方整套验证重做。

必要旧问题与新能力一起推进，独立工作不等清零；同一失败按AGENTS跨模型累计，3次有效修复仍失败交指导给方案、最迟第4次升级，不再调用K3。完整阶段完成或重大结构阻塞向指导 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61` 主动报告并给下一主线建议，不按单个按钮/API/测试停工。无需另开执行卡或自动化。

保留所有未提交修改；不stage/commit/push、不切分支、不建worktree，不动其他模型的推广和素材。自有临时窗口整轮复用，阶段结束统一回收，保留原始证据，不关闭用户实例。ACTIVE维护唯一当前阶段和范围，旧数值/细节用链接归档，避免多段“当前”互相冲突。

## 指导方案：菜单测试没有 keyWindow

用户已取消K3；本问题现在由指导给方案，Terra实施。源码核对：`verify_application_command_menu_native.sh` 直接cjc链接并启动独立probe，没有复用正常 `cjgui_macos_application_launcher.m` 的AppKit主线程`[application run]`宿主；测试helper却在选择菜单项内部追加finishLaunching/activate/makeKey与10ms NSRunLoop等待。这是与正常消费明显不同的启动路径，优先验证它，而不是继续叠加激活调用。尚未实证主循环差异是唯一根因。

1. 将原生菜单集成验收接到现有正常bundle/launcher运行路径，复用同一Cangjie probe逻辑和真实FIFO/owner断言，不另造生产启动器。菜单操作前按可观察条件建立前台：记录main thread、activationPolicy、isRunning/isActive、窗口visible/canBecomeKey/isKey、实际keyWindow与didBecomeActive/didBecomeKey通知。正常主线程持续处理事件，有限等待应放在测试协调侧，避免主线程同步等待自己需要执行的激活回调。
2. 前台激活与菜单执行分开。先通过正常窗口操作/测试准备建立A或B为key，再选当前真实NSMenuItem；选择helper本身不为了session参数偷偷把窗口改成key，否则会掩盖跨窗口路由缺陷。保留生产回调只从真实keyWindow解析目标的约束，不swizzle keyWindow、不直接塞FIFO冒充菜单选择。
3. 先在一个正常隔离bundle内证明菜单→AppKit action→FIFO→owner→内容读回；再做A/B切换和关闭/旧回调。若正常bundle也无key，用上述状态区分未激活、不能成为key、启动生命周期和外部锁屏，停止同条件重复尝试并回报精确观测。无前台环境时保留not_run，但独立命令/消费者/导出继续；不能只把老probe改绿就放弃正常菜单验收。

依据：仓库正常launcher的AppKit主循环，以及Apple对 [NSApplication.run](https://developer.apple.com/documentation/appkit/nsapplication/run%28%29) 与 [finishLaunching](https://developer.apple.com/documentation/appkit/nsapplication/finishlaunching%28%29) 的职责说明。指导仅作源码分析与方案，未亲自运行或修改开发实现。

## 指导复核后的完整接续

2026-09-14：执行报告已完成菜单集成。指导检查实际代码后认可启动诊断方向有效：正常 bundle probe 的成功条件包含 A/B readiness、菜单/快捷键操作、旧项按当前 key 窗口路由、关闭 A 后 B 操作及 owner 次数 1/3，非只靠脚本退出码。现阶段只接受这些已报告且源码可解释的分项，不将整阶段标绿。接续目标仍为“普通开发者可直接使用的桌面命令与菜单”，不能只补一条日志就停工。

1. **先交代已有证据，再补真实缺口。** 给出最终正常 bundle 日志、源码/二进制身份和导出根的精确路径。`verify_application_command_menu_native.sh` 当前凭 probe 写入的 `passed` 判断，脚本打印固定汇总并删除结果目录；这不等于伪造，但会丢失实际 readiness/失败诊断。改为保留本轮 probe 实际观测与判定、源码/二进制身份和日志，临时进程正常回收。优先复用已有证据，找不到才补相关运行，不能拿 green 命名目录中的旧失败日志替代。本次抽查 `...native-green-4/run.log` 仍为 status=99、saves=0 的旧诊断，不作为最终否定或通过结论。
2. **补正常桌面菜单的框架行为。** `CjguiCommitStagedComposableCommandMenu` 每次提交都会全局重建 `NSApp.mainMenu`，包括非 key 窗口提交；`CjguiRebuildComposableCommandMenuForKeyWindow` 全量替换菜单。先复现“B 的输入/外部更新时 A 菜单打开或保持不变”的表现，保证无关窗口/相同菜单投影不反复替换活动菜单。复用 accepted 命令投影与窗口生命周期，采用内容变化和 key 窗口切换驱动的窄更新，不新增常驻轮询或第二命令 owner。区分菜单对象更新计数与 GPU/build 计数，按同样场景证明消除无谓工作，不重跑整个图片/大文档矩阵。
3. **焦点与系统服务一并完成。** 同一窗口不同 focus scope 可以声明相同快捷键，native 菜单却把各项注册为同一个 key equivalent：定向核验是否先命中非当前 scope 而被仓颉拒绝，造成正确命令没有执行。执行前校验须保留；有效菜单显示状态和快捷键选择也要与真实 scope/顶层 layer 一致。核验全量替换 mainMenu 是否丢失正常应用退出、隐藏及标准文字 responder 行为，说明框架默认与应用声明的边界；仅作窄 AppKit 服务适配，不扩成桌面 shell。使用真实菜单 tracking 或前台菜单操作补一条外部写入后可用/勾选状态更新、人继续操作的正常消费者证据，旧项/候选失败/执行中关闭只补缺失的高风险回归。锁屏仅跳过桌面部分，其余继续。
4. **新公共能力的独立消费交付。** 当前 `verify_framework_preview_consumption.sh` 仍是模板/文档/图片消费者，不包含本轮菜单使用证明。复用导出流程，在含空格路径用导出包公共 API 构建并运行菜单消费者，至少完成两个不同 owner 的命令、稳定目标、按钮/菜单同一动作与内容读回，来源绑定本轮最终源码；不复制 private native，不把构建旧模板当新 API 已消费。将公开命令构造、无快捷键声明、scope/disabled/checked、失败语义、平台菜单边界和实验稳定性写进已有 runtime README，修正其“native 不接收 command id”的旧说法：native 可持有不解释业务的命令标识，真实动作仍归仓颉。

Terra/xhigh 负责菜单宿主、作用域和更新时序；把公共消费者、README与导出完整工作包交 Luna/high。旧问题与新消费并行推进，构建串行；明确方案的实现可再交 Luna，不重复整套验收。完成以上完整交付后统一报告：已完成能力、原始证据路径、确切未验边界和下一主线建议；同步 ACTIVE 的唯一当前结论，不按单项停工。仍不调用 K3，累计三次有效失败或更早结构阻塞向指导升级。

### 完成报告复核与系统命令收口

指导已读取 `/private/tmp/cjgui-command-menu-native-runs/run.g3oVjH/result` 与实际名为 `manifest.txt` 的清单，四项生产/probe 源码哈希与工作区一致；readiness=255、后台提交重建4→4、B enabled/checked/shortcut flags=7、owner计数1/3及layer计数1的受控结果接受。未重跑开发测试。仍须完成以下同一交付的衔接，不能把原生菜单存在当作正常应用全部行为已验证。

- **系统退出接回已有应用退出 owner。** 新标准菜单直接向 responder chain 发 `terminate:`，当前 normal launcher 未见 `applicationShouldTerminate` 或等价接入，已有 `CjguiMacosApplicationExitDecisionProvider`/`requestApplicationExit` 决策在仓颉。先用带拒绝决策的临时双窗消费者，经真实 Quit action 验证拒绝是否保留窗口/内容/连接；不能只检查有 Quit 菜单项。若绕过，采用窄平台退出意图→正常应用调度→已有 exit decision→异步允许/拒绝的路径，主线程不可同步等仓颉回调，不在 native 重写保存逻辑；沿用主循环正常停止和已有清理。覆盖取消/拒绝后继续编辑、允许后统一清理、连续两次退出请求幂等；不得在用户实例上试验。
- **Undo/Redo 与应用命令的唯一处理。** 标准 Edit 先创建 Cmd-Z/Shift-Cmd-Z 的 `undo:`/`redo:`，文档同样声明对应 owner 命令。明确匹配优先级，先证明正常文档/层的快捷键产生一次正确 owner 撤销/重做，标准文本 fallback 仅在没有适用的已声明命令时使用；disabled 或被 layer 覆盖不能偷偷改用另一路径。保留系统组合输入与剪贴板职责，不另造 undo 栈。采用实际事件→内容/版本读回，不能只断言 selector 或条目存在。
- **同一前台窗口未改变的菜单不要重建。** 后台窗口已修复，但当前 `CjguiCommitStagedComposableCommandMenu` 对 key window 仍无条件全量重建。对已接受菜单的可见内容、有效 scope/快捷键与 key window 身份做必要变化判断；仅场景版本变化不应重建菜单，拒绝恢复保持一致。用前台连续内容输入而命令投影不变的场景记录菜单对象/重建次数，菜单状态确实变化仍及时更新；实际菜单 tracking 未验证则保留欠项，不将任意重建声称安全。
- **最终导出保留可复核证据。** 报告的 `/private/tmp/cjgui-framework-preview-consumption.x9AVud` 当前不存在，runner 默认 cleanup 删除整目录。先找已留存原始输出；若仅临时证据丢失，在上述实际代码变更完成后只做一次必要的最终导出/菜单消费并启用已有 KEEP_TMPDIR 选项，报告实际存在的 manifest/log/payload。公开消费者目前通过 `invokeCommand` 证明仓颉命令消费，不能将其独自标作原生菜单点击或按钮点击已执行；与 native probe 的证明范围分别写清。不要仅因证据路径问题重复整个历史矩阵。

Terra亲自定退出/命令优先级方案与最小桥接；Luna复用当前消费者落实明确的回归、未变菜单更新判定、最终公共导出及文档工作包，按写集协调。完成这一组后一次报告，不以发现新疑点为由无限扩大为全套系统服务。未验物理输入、IME/VoiceOver和发布保持原边界。下一阶段候选回到组件/自绘画面表达和测量效率，待本次影响正常退出的衔接完成后由指导结合全局缺口选定，避免长期只围绕菜单样例打转。

### 2026-09-14 完成记录

系统命令收口已完成，未 stage、commit 或 push。标准 Quit 仍由 AppKit `terminate:` 发起；bridge 仅在当前 key CJGUI session 上投递一个合并的退出意图，正常应用回合消费后调用既有 `CjguiMacosApplicationExitDecisionProvider` 与 `requestApplicationExit()`。native 没有保存业务决定，也没有从主线程同步等待仓颉。普通双窗 LaunchServices bundle 的 RED 为 `/private/tmp/cjgui-command-menu-exit-native-runs/run.VZqjTS`：原实现的标准 Quit 直接退出，未得到仓颉回执。修复后的 `/private/tmp/cjgui-command-menu-exit-native-runs/run.3AkAAV/result` 为 `verdict=passed`：两次拒绝都保留 live external connection、两窗口及 B 的 `persisted@2`，相邻重复 Quit 合并为一次决策；第三次允许后 `application_open=false`、`windows_after_allow=0`，共三次有意区分的退出请求。

标准 Edit 的 document/layer owner 优先级也已接通。若任一已声明 owner 占用 Cmd-Z 或 Shift-Cmd-Z，标准 Undo/Redo 项仍在菜单中，但其 key equivalent 被移除；因此 disabled/layer 声明也不会静默落到文本 responder。没有任何声明时，原生文本 Undo/Redo 仍可处理，框架未创建另一套 undo 栈。修复前 `/private/tmp/cjgui-command-menu-native-runs/run.KOq68p/result` 显示标准 Edit shortcut flags 为 3、owner 未收到事件。修复后 `/private/tmp/cjgui-command-menu-native-runs/run.DgiPhR/result` 为 `verdict=passed`：document Cmd-Z/Shift-Cmd-Z 各一次，内容读回 `current@4`、`undo_count_b=1`、`redo_count_b=1`；layer 与 disabled layer 的标准 Edit flags 均为 0，layer owner 只处理一次，disabled owner 不改写内容。

菜单提交现在比较 current key window 的有效投影（命令集合、enabled/checked、有效 focus scope、key-window 身份），而不是任意 scene version。前台同投影刷新从 RED `/private/tmp/cjgui-command-menu-effective-projection-red/run.HXAz6a` 的 `rebuild_before=1,rebuild_after=2` 收敛到 `/private/tmp/cjgui-command-menu-effective-projection-runs/run.OP1SEJ/result` 的 `1→1`；菜单状态/焦点或 key window 实际变化时仍重建。

最终公共导出只在上述源码完成后运行一次，并使用 `CJGUI_PREVIEW_CONSUMPTION_KEEP_TMPDIR=1` 保留证据：`/private/tmp/cjgui-framework-preview-consumption.delrQW/command-menu-preview.manifest`。含空格 relocated framework 的纯 public 消费者构建运行通过，`command_owners=2`、stable target、按钮与 `invokeCommand` 共享动作、projection readback、disabled 拒绝均为 true；source/preview payload 一致，为 `04f8aa872fa94f2975f0ad1dde7c93620c8487dd32c051560bd17980a91335c6`。这只证明公开 Cangjie 命令消费，不把它冒充为原生菜单或按钮物理点击；前两组 normal AppKit bundle 分别承担原生 Quit/Edit 证明。

完成前验证：`runtime/cjgui` 的 `cjpm test --skip-script --jobs 1 --parallel 1` 为 9/9，`cjpm build --skip-script`、命令 contract/binding probes、相关 shell 语法与 `git diff --check` 均通过。现有 `chmod` 和 AppKit `allowedFileTypes` 弃用警告未在本范围修复。人工菜单栏 tracking、物理键盘、IME/VoiceOver、安装、公证和发布均未运行，不能由上述合成 `NSApplication sendEvent` 或导出消费替代。
