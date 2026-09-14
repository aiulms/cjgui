# CJGUI 当前方向与实施状态

更新：2026-09-14。本文件是唯一当前状态入口。历史数据保留在阶段报告，不作为仍待执行的指令。

## 当前任务

用户已明确授权并要求优先执行[仓库提交、主分支同步与开发接续](../../docs/plans/2026-09-14-repository-checkpoint-and-sync.md)。此时冻结新的动态能力和并行写入；Terra 是唯一 Git/index 写入者，先盘点、保全并验证可审阅的源码/文档边界，再安全同步 `origin/main`。正常规则/文档应用不动；不 force push、reset、clean 或丢弃未明改动。

同步前已保存但尚未整阶段验收的[动态复合组件、弹层引用与共同操作](../../docs/plans/2026-09-14-dynamic-component-composition-milestone.md)衔接如下：候选内变量高度行的 scoped 身份、声明式锚点/初始焦点、缺失引用拒绝与跨窗口声明快照隔离已有针对性 RED/GREEN；性能探针正在从毫秒计时改为 30 样本纳秒 cold/warm/churn/失败恢复，并尚未完成两种正常消费者、正式 Preview 独立消费和多窗口前台实证。收口完成后，回到该阶段作为唯一开发任务；不要把此次 Git 同步或已有 probe 当作这些未验项的完成声明。

前一[安全组件组合与稳定身份](../../docs/plans/2026-09-14-component-identity-milestone.md)已有实现及执行侧针对性证据，指导已只读抽查候选事务和正常消费入口，按这些范围接受，不标整体验收完成。规则恢复手工内容 ID `22` 并使用 scoped split，文档操作栏使用 scoped action row。局部 key 安全诊断、候选容量边界、动态物化/引用以及正式导出证据仍需本轮闭合；具体复现与方案要求见当前阶段页。

本轮已串行通过 scoped layout/window probes、规则 5/5、文档 6/6、规则/文档 bundle build、pointer-consumer verifier 和根 `cjpm build --skip-script`；计时仅为 30 样本的同进程 `MonoTime`，small/medium 为 0ms、large 最大 1ms，不代表物理呈现。两份独立临时 bundle 的 CUA/公开 UDS 交叉验收已确认规则首条、后续行滚动、外部编辑/应用回显，以及文档切换 owner 后 action node ID 不变而 resource target 改绑。临时实例已经正常退出，临时 bundle、日志和 UDS 描述符已移入废纸篓；用户正常规则/文档实例未被此阶段停止或写入。

当前遗留：系统 IME/VoiceOver与独立物理输入、实际呈现、多窗口完整前台接续、安装/公证/发布仍未整体验收；自动化 Right 和坐标拖动已有各自证据，不再列为未验。身份阶段完成报告没有给出最终导出日志/payload，指导暂不接受此前“最终消费收口”表述，已要求恢复必要原始日志并核对已有证据；没有则随本轮最终源码导出消费补齐，不把工作区 bundle build 或历史 payload 当本轮证明。

### 前阶段接受范围与原始入口

**连续指针阶段唯一当前结论（09-14）：** 当前源码已完成受控 native 捕获、普通消费者坐标拖动、真实 public UDS 同轮交错和正式 Preview 消费。新增的键盘路由实证不再直接调用 overlay：pointer 焦点后，`NSApplication sendEvent` 经 key window/first responder 到 composable overlay（route flags `31`），再由仓颉 owner 处理，direct control 与 application route 各产生一次调整；原始日志为 `/private/tmp/cjgui-pointer-capture-app-route-final/probe.log`。此前 CUA `Right` 后状态不变只说明当时的自动化观测没有产出，未区分工具是否投递、投给哪个 window，或当时 responder 状态；不能用它断言“未到 scene”或“不是源码问题”。当前隔离的文档滑块窗口 PID `89253`、源码 binary SHA-256 `86c71876ae50f7605aa21fb1c526a389488ad37837b1a13d25dfe657c27c97b6`，已由 CUA Raise、坐标拖动建立 pointer focus 后真实发送 `Right`，AX 读回滑块和状态文本由 `160` 同步变为 `192`。这是当前桌面自动化键盘链路的通过证据；若需与之区分的物理键盘，及系统 IME、VoiceOver、安装、公证、发布仍为 `not_run`。最终 Preview source/preview payload 均为 `56df3bd50a5065c8f7f6002a82d58517962e60a09bf671e1a31842cbb0cbcc8a`，三消费者在含空格隔离目录构建通过；UDS 混合原始 `probe.log`/`public-calls.log` 位于 `/private/tmp/cjgui-pointer-public-interleave-app-route-final/`。根 `cjpm build --skip-script`、控件消费者及相关 probes 均串行通过。

**本轮可见文字与 CAS 补证（09-14）：** 同一当前源码隔离 document 窗口的 CUA AX 与截图均显示中文三行正文及完整的 `emoji 🙂 不会被拆开。`，列表项、编辑区和状态预览三处一致；因此 CJK/emoji 的当前可见渲染为通过。解锁后的正常 document 窗口还完成了最小 GUI→CAS→GUI 链：通过原生编辑控件粘贴 `GUI 输入：仓颉中文🙂\n第二行：UTF-8 字节边界。`，得到文档 v12；随后经公开 `REPLACE_RANGE` 以 expected v12 在 UTF-8 字节 `63..63` 追加 `CAS 追加：已核验。`，应用为 v13，AX 的列表、编辑区、预览和公开 read-range 均读回同一完整内容，窗口 `pending=none`、`failure=none`。CUA 的直接 `typeText` 同一 CJK 字符串只留下 ASCII 片段，故它不是 CJK 键入通过证据；物理键盘与系统 IME 仍为 `not_run`。

下方过程记录中较早的“GUI 滚动/点击”或“GUI→CAS→GUI 为 `not_run`”仅描述当时锁屏前的边界，均由本段及变量集合阶段末尾的解锁后补验覆盖。

**旧实例复查与恢复（09-14）：** 用户已确认是其手动关闭此前仅作保护性观察的规则 PID `13539` 和文档 PID `18369`，并授权重启。按原 normal bundle 已重启为规则 PID `9726` 与带 `--with-connection` 的文档 PID `9728`；重启本身未写入用户数据。后续上述 CJK/CAS 验收只改动了默认文档的未保存内存状态，未传入 `--file`、未触发保存；它不替代当前源码的规则 GUI 验收，历史截图或日志也不补作该证据。

### 过程记录（非当前状态）

**2026-09-14 连续指针交互与共同操作控件：源码、受控 native、普通 bundle 公共调用和 Preview 消费已有分项证据，整阶段仍在接续；当前源码的人工拖拽/键盘与“公开调用和突发拖动同轮竞争”仍为 `not_run`。** `CjguiComposableUiPointerCaptureVersionProvider` 让已捕获目标按其 owner revision 判断有效性：规则分隔区仅看 `splitFirstSizeVersion`，文档滑块仅看所选文档的 `previewLimitVersion`，无关对象外部写不取消拖动；同目标外部写、目标删除、模态转换均取消并撤销平台捕获。两个普通消费者分别经同一公开控件/owner 路径采用 split 和 slider；`SET_SPLIT_SIZE`（160..720）与 `SET_PREVIEW_LIMIT`（128..512、步长32）均经过现有授权、CAS、读回，未新增第二可写状态。生命周期 probe 已覆盖移出原 bounds 后结束、同 owner 外写取消、无关 owner 外写保持捕获、目标删除和模态取消。受控连续负载在每条件 30 个新 session 样本中：低频 240 次 update 全处理、合并0、每轮真实待处理 FIFO 上限1；突发 960 次 update 实处理30、合并930、每轮 FIFO 上限3，end 均保留，另一 idle window 的 scene/submission 均无变化。计时是 native enqueue 至仓颉 dispatch/投影的受控阶段（低频 20/22/45ms，突发10/11/14ms 的 min/avg/max），不代表物理呈现或人类输入延迟。核心 `cjpm test --skip-script` 46/46、规则 16/16、控件消费和根 `cjpm build --skip-script` 均通过；新 normal bundle 的公开 socket 分别实际写入 split=416、previewLimit=224，并拒绝 stale CAS。最新 Preview 在含空格隔离路径重新导出、构建三消费者，source/preview payload 同为 `bf2dc2e8a5f1f56d71522449f73ff13da06fad3decb8a30e140133fb1840d831`。已解锁后仅只读截取到规则集（PID 13539，9月13日启动）和文档（PID 18369，9月14日02:02启动）旧进程窗口；其 AX 快照仍超时，且为保护未知会话未重启/写入，故不能把截图冒充当前源码的真实拖拽验收。安装、公证、发布同为 `not_run`。

**09-14 后续实证（历史快照；键盘归因已由上方唯一当前结论更新）：** 用户旧 PID 未动；当前源码的独立临时 normal bundle 完成坐标拖动和真实 UDS 读回：文档 `128 → 外部352 → 人工192`，规则 `436 → 外部416 → 人工452`。真实 public UDS 与预先入队的 pointer burst 在同一 `pumpOneTurn` 交错：无关 B owner 保持 A capture，A 正常 end 且 B scene `1 → 2`；同 owner A 写入取消 capture，旧 move/end 均为 `99`、不能覆盖外部 `416`。受控生命周期复跑为 30 样本低频 `240/240/0`、FIFO 高水位 `2`，突发 `960/30/930`、高水位 `4`；控件消费者、生命周期、UDS 混合 probe 和根 `cjpm build --skip-script` 均串行通过。该轮 CUA `Right` 无状态变化只是未能判定其投递/目标/responder，不能得出“未到 scene”或“非源码问题”；物理键盘、IME、VoiceOver、安装、公证、发布仍未验。

指导已只读抽查布局阶段生产默认、最终报告与binary hash（匹配）及正式导出绑定，按以下范围接受；GUI/IME旧欠项继续保留。

[前阶段：局部更新的布局复用与稳定性能](../../docs/plans/2026-09-14-incremental-layout-reuse-milestone.md) 按范围完成。公共 cache 绑定 `CjguiComposableUiLayoutMeasurementEnvironment`，native session 与 resize/backing-scale generation 分隔缓存；default 只接受显式 `layoutReuseKey` 的安全区域，未标记区域规范布局。完整 structural signature 仍可通过 `allowStructuralSignatures: true` 显式用于诊断，但不进入正常窗口。缓存限制 4 条目、1,024 节点、262,144 字节字符串和 524,288 字节估算总量，pending 与 accepted 都计入；nested scroll/layer、失败 candidate 和环境改变都不能错误晋升。规则 header 与文档 action bar 为两个实际消费者，`WINDOW_LAYOUT_REUSE` 仅投影派生工作。

最终计时证据为 `/private/tmp/cjgui-incremental-layout-timing-v4-final/incremental-layout-reuse-report.json`（probe SHA-256 `7316e3a68eaac22cb672a7afef8c736ab8f55f831a5ab0192f9fa9ada90d1807`）：同进程交错 canonical、diagnostic structural 和生产 opt-in，6 条件 × 3 行数、每条件每模式 30 个有效样本，Cangjie `MonoTime` 分别测 build/layout，比较与打印在计时外。760 行 local 的 build+layout p50 为 canonical 3.771ms、diagnostic structural 9.293ms、production opt-in 3.415ms；因此默认关闭完整签名。warm/local 的显式稳定区域有收益；resize/font/full invalidation 完整求解且 p50 为 4.164/4.176/4.220ms，高于 canonical 3.762/3.748/3.805ms，不宣称收益。每个 cache 结果均在计时外与同测量缓存的 canonical target 比较 projection。

当前普通 bundle 报告为 `/private/tmp/cjgui-incremental-layout-normal-window-v4-final.json`：规则批次/CAS/readback/完成帧通过，`WINDOW_LAYOUT_REUSE 1 0 14 14 1`；文档 replace/stale CAS/range readback/完成帧通过，`1 0 6 6 1`。core 全量 `cjpm test` 串行通过 45/45；首次 PendingClientRequest 编译错是与 build 并发写同一 target 的临时产物竞争，未扩大 internal API。最新 Preview 在含空格隔离路径重新导出并构建三消费者，payload `59270f894920aa41f2782aa50dd21250655be363ea4c4d6e9b3e55c5554b33c7`，原始根 `/private/tmp/cjgui-framework-preview-consumption.a0y9Qx`。这些是源码、受控 native 进程和导出消费证据；人工 GUI/IME、VoiceOver、安装/公证/发布均为 `not_run`。

上一多窗口阶段的关键源码及 exception/identity/partial-creation 原始日志、最新导出绑定日志已由指导只读抽查，按受控运行/公共消费范围接受；没有重跑执行测试或声明人工验收。旧 26c0c45c 是历史，最终多窗口 payload 为下文 a34c49a1。

**同进程多窗口阶段按范围完成：完整公开 target 读取、外部积压下的 B 进展、生命周期异常/共享 loop 归属、失败恢复与最终 Preview 消费均已验证。前台人工 A→B 操作、系统中文输入/IME、滚动/选区可见性和物理呈现仍为 `not_run`；未声明旧文字或变量集合阶段的人工 GUI 欠项完成。**

- [前阶段：多窗口](../../docs/plans/2026-09-14-multi-window-application-milestone.md)：应用级窗口生命周期、单调度器预算、同owner多窗口更新及独立关闭/失败恢复已有按范围证据，前台欠项继续承接。
- 多窗口当前证据：`CjguiMacosApplicationWindowIdentifier` 绑定不可复用 application owner 与单调 window generation；跨 application 和重建旧 id 均拒绝。公共 client 提供 `window-progress <target>`、`window-interaction <target>` 和 `wait-window --target`，关闭 A 后 A 的 context/progress/interaction 均返回 `unknown_window_target`，B 仍独立可读；重开 A 是 generation 4 的新 target。实际公开 CAS 在连接存活时使 B 到 scene 2；四个真实 public UDS caller 的有界积压中，transport `ready_high_water=4`、`serviced_actions=133`，235 个被记录的 turn 中有37个服务外部动作，B 仍从 scene 1 到2（一次 CAS turn 的 wait budget 为0，故不宣称每轮都有正等待预算）。`pumpOneTurn` 的回调异常现在释放 guard 并把异常继续传播；关闭 application A 后，B 仍处理真实输入；native capacity 造成的 B 首次创建失败不影响 A，容量释放后 B 可重新创建。`native/scripts/verify_multi_window_application.sh` 的本轮原始根为 `/private/tmp/cjgui-multi-window-application.boxfKa`，组合结论包括 `exception_guard=passed`、`identity_binding=passed`、`partial_creation=passed`、`busy_backlog_b_progressed=true`、`closed_target_rejected=true`、`sibling_target_survived=true` 与 `endpoint_cleared=true`。最终 Preview 从该源码重新导出并在含空格隔离路径构建三种消费者，source/preview payload 同为 `a34c49a1874a83d997f89b77a99a62b9274716dc741a89cc38fc22c82f04de97`，document bundle 为 `e1dafb594c476f81e03fa90a4aa981ee053057726d5bedaf6e8edbe1d89a76fd`，日志根为 `/private/tmp/cjgui-framework-preview-consumption.pmbLyk`。这些都是源码/受控运行/导出消费证据，submitted 不是前台可见声明。
- [前阶段：变量集合与源码证据](../../docs/plans/2026-09-14-variable-height-collections-milestone.md)：指导已抽查布局修正、局部revision、公开macOS摘要wrapper及native边界；最后GUI滚动显露/点击/共同接续继续not_run，不能把协议读回与旧bundle当最终窗口验收。
- [前阶段与未验承接](../../docs/plans/2026-09-13-low-latency-text-resource-milestone.md)：120Hz预算仍是优化方向；100KB插入残余与系统输入/真实呈现边界保留，不反复重测无关文字矩阵。GUI欠项不阻塞独立仓颉布局工作。
- 当前已证：以同一 test-only binary（SHA-256 `9bffe01b...dff09`）运行的 `reuse → full → full → reuse` 受控对照，覆盖正常/256混合两 workload、开头/中部/末尾、光标/范围；每模式720个有效样本，正文复用全部为0 raster/0 upload，强制既有完整正文准备全部为1 raster/1 upload（各1,468,416 bytes）。外层 `selection_caret_total_ms` 为毫秒粒度：复用p50/p95为0ms、max6ms，只能表示低于时钟分辨率而非零耗时；full-body p50=14ms、p95=15ms、max19ms。它是当前机制对照，不是历史版本比较、插入延迟或物理呈现。原始根为`/private/tmp/cjgui-selection-ab-final.BEBjz7`，含manifest、四轮stdout/stderr与回归/导出日志。插入100KB多段的历史约16ms残余仍不能被本对照覆盖或改写。
- [正常窗口显示、输入与缩放阶段](../../docs/plans/2026-09-13-window-display-input-scale-milestone.md)按已证范围接受：指导直接看原始工具截图确认中英文/箭头/emoji正向；核对文字与图片UV路径分离、backing通知及2x→1x受控结果。正式导出三消费者成功日志为`/private/tmp/cjgui-preview-document-closure-green-2.stdout`，source/preview payload与指导当前只读重算均为`f0266b8d824b8d3c1baa6161a42c65c499f3c6bc1701bafb0003d89c63d5ff6f`，renderer为`20f1a1512d58be233aaa737f925e4f316be3e060cb0aed80d6c6f7a0b1cb9e44`。指导未重跑构建/开发测试。
- [连续编辑阶段](../../docs/plans/2026-09-13-continuous-editing-local-update-milestone.md)的mode toggle及重复准备修复已承接到正式导出。其100KB多段16/17/17ms和长单段首/中179/171ms属于当时测试条件；verbose观测已改为按需，后续须重新建立当前基线，不能跨观测条件宣传加速。长单段残余保留，不无依据扩第二排版图。
- 已解决正常窗口文字倒置、导出文档core缺失，以及 CJK/emoji 后追加ASCII导致可见字形损坏：根因是 `NSTextView.font` 的首字符fallback getter 被误当成base样式变化，随后全局setter清除了逐字符fallback runs。修复保存最后一次实际全局写入的base font，只有同node/同base/非空且已建立fallback时跳过setter；首次聚焦、清空、重绑和真实样式变化仍赋值。AppKit probe已覆盖CJK/emoji owner确认、清空、外部恢复；最终源码app此前已在前台完成本地Z→v1、外部CAS→v2/stale conflict、状态投影和本地Q→v3，但该次之后增加了base-font区分与test-only A/B seam。当前无测试flag app已重新构建启动，因锁屏未能读回最后窗口，不能把前一截图冒充当前binary验收。物理键盘/IME、VoiceOver、真实多显示器、presented事件、安装公证发布仍未验；CUA Unicode typeText/粘贴异常的具体事件归因也未闭合。
- 可变高度集合当前源码实现已完成核心/两消费者/规模探针，并经三轮指导复核补齐：变量路径先解估计范围，若真实行较矮则只在同一128行预算内补测至覆盖视口，最后按同一测量快照发布 range/total/origin；overscan 先保可见行且只作为后置有界 buffer，避免前置 estimate 压缩后重建不同范围。公共变量 row source 以单项 revision、title 和全局 measurement generation 形成派生缓存键；stable key/intra-row anchor 覆盖前插、删除后继回退、屏外修改不自动reveal、主动显露和宽度失效。核心红测已复现并修复“1000 estimate/10 actual 高度的500px空白”与`overscan=1000`越界；回归还覆盖超过128 key淘汰返回、混合高度、尾部 reveal、宽度失效。规则把 selection 仅折入A/B的行级revision，generation只保留字体，且revision组合为饱和算术；文档样例只使用 `cjguiExperimentalDocumentPreview` 公共仓颉结果，internal bridge/`CString`/资源释放不再出现在消费者。该实验入口限定macOS、<=2KiB scalar-safe输入窗口、`maxBytes=4..512`/`maxClusters=1..160`，native在组成簇选择前预留省略号预算；文档消费者补齐ZWJ回缩 RED→GREEN 后为5/5，runtime为7/7、规则为1/1。`verify_composable_ui_appkit_text.sh`、两应用当前 build、根`cjpm build --skip-script`和最终preview export均按相应范围通过；导出后迁移到含空格路径的三种消费者都从导出框架构建，source/preview payload同为`b1f6302b…305645`，本次原始成功日志为`/private/tmp/cjgui-framework-preview-consumption-final-log.pe0OpN`，current normal rule/document bundles分别为`84f3a384…7f936b1`与`c9734ebc…02b1fc`；旧公开owner原始JSON不冒充新bundle GUI验收。平台无关规模probe不链接该bridge，按复核结论没有因这一封装重跑，仍只对应先前source/scale-binary指纹。毫秒计时布局p50/p95=0仅是时钟下限。当前 normal rule bundle 已经完成实际外部 owner→屏外行→CAS读回（含陈旧冲突拒绝）；人工滚动显露/后续点击、UI scroll/selection 不变量及 current normal GUI 连续链仍为`not_run`，阶段等待指导最终验收，不把源构建/探针冒充完成。
- 执行任务`01a08f82-b682-73c0-a9b0-25a27bc5ffd8`整阶段完成或重大阻塞主动报告指导`01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。下一候选据实际主线程/渲染热点和正常消费决定，不能无限追单一长单段。Cangjie1.1.3、包根runtime/cjgui、原目录、不切分支、不stage/commit/push、不安装发布、不覆盖用户实例；锁屏继续独立工作。

## 方向与本轮取舍

最新GUI状态（2026-09-14）：中文正文末尾输入ASCII `Z` 后，owner/AX正确而可见汉字乱码的根因已定位并修复，未采用全量fallback、延后刷新或全量glyph失效。实际前台源码窗口曾确认CJK/emoji完整、本地Z→v1、外部CAS append→v2、stale v1→`version_conflict`、状态同步与本地Q→v3；当前最终normal binary重新启动后系统锁屏，尚待解锁后以同一GUI接续最小复查。A/B当前binary对照和正式三消费者导出已完成，详见本阶段末尾记录。

锁屏期间已完成首帧 `scene_color_mismatch` 修正：按最终drawable texel反推逻辑点，纳入同节点及上层正文/瞬态几何覆盖；覆盖场景如实降级，干净色块仍比较。指导抽查源码、场景成功日志和最终三消费者导出，payload为`d15a8c634d611bbb3e850d975d031a98920ca41abfd7dc3b82948121263b4cf0`；生产源码消费已经完成，只有相关前台接续继续挂起，不能用旧运行进程代替新bundle。当前转向可变高度集合，不继续围绕已经闭合的取样问题打转。

CJGUI 是基于仓颉、类似 GPUI 的高性能自绘/GPU GUI 框架，macOS 首个平台、窄平台桥接。GPUI 是参照，不逐接口复刻，不宣称已有相当性能。人和外部 AI/模型/Agent/脚本通过同一应用内容、上下文和真实动作共同操作；应用开发者决定界面与交流体验，不强制聊天窗或 Agent runtime。S-expression 仍是可替换的候选编码。

领域拥有内容、草稿和业务规则；组件拥有必要的焦点、选区与视口。画面、AX和外部语义是投影，不另造可写真相。已有授权可覆盖屏外批量操作；可见性、弹窗和AI身份不自动增加授权门槛，真实约束/冲突/未授权目标仍须处理。

六主线取舍：布局性能和连续指针已有按范围证据；真实新增暴露nodeId碰撞，当前优先开发者安全组合/动态身份与语义目标稳定。不是增加样例按钮，而是让复合组件可重复嵌套消费；GPU/文字/资源已有成果保留，旧系统交互边界单列。

方向与旧资产入口：[设计意图导航](../../docs/plans/DESIGN_INTENT_INDEX.md)、[项目方向](../../docs/core/GUI_PROJECT_DIRECTION.md)、[共同操作设计](../../docs/core/AI_NATIVE_UI_SEMANTICS.md)。历史避坑重点落实在布局状态归属、测量失效与无变化不重绘，不能仅列链接；旧 opening 禁令不恢复。

## 已接受交付与边界

以下为执行报告与指导源码/证据审阅结论；本次状态整理没有重跑开发测试，不是框架整体完成声明。

| 主线 | 已有能力与证据 | 尚有边界 |
| --- | --- | --- |
| 组件/布局 | 仓颉组件树、测量布局、稳定身份、层宿主与固定行高虚拟集合；画面/命中/焦点共用最终布局 | 约束分配与单轮测量复用已有验证；物化行128、native节点1024仍为已声明容量 |
| 自绘/GPU | 有序形状/图片/静态和活动多行文字 tile 合成、alpha 混合、圆角/clip 与连续形状合批；多行仍取同一 resolved clip 和唯一 TextKit graph | submitted、GPU completed不同于人已看见；presentation unavailable、完整呈现延迟未证实 |
| 文字输入 | owner确认与旧FIFO冲突、组合取消、范围布局、稳定缓存；相同 geometry/font 不再重复失效，消除已复现约1.5s视口重排；当前受控输入重复纹理准备已消除 | 当前100KB多段input p50约16–17ms、长单段首/中约179/171ms；有效样本数及消费欠项见上，历史数字不混作当前性能 |
| 资源/调度 | 有界缓存、单一调度器、4个异步加载槽、队列/代际清理；正常窗口空闲与混合负载已有测量 | 跨场景资源收敛、局部提交效率继续评估；旧 retained future 和 lsof行数不当活worker/FD计数 |
| 语义/动作 | 真实owner写入/CAS/批次/定向读取/观察；streamIdentity同锁快照；交互读取独立授权 | 脚本调用、独立Agent消费、实际GUI接续按具体证据区分；旧无stream字段描述已被后续修复取代 |
| 正常包消费 | 通用macOS Host、内容指纹构建与bundle资源；规则/文档和独立消费者有实际消费历史 | 最终bundle只继承对应源码的验证；安装、公证、发布、稳定ABI和跨平台未验 |

最近文字阶段报告：core 40/40、runtime 5/5、native text/scene/window/host、项目根build通过；两个最终bundle重建并完成公开owner写入/冲突/读回/完成帧。已解锁实窗出现正常AX树，不等于物理中文IME、VoiceOver或人工像素验收。详细样本条件和探针局限见[文字布局交付](../../docs/plans/2026-09-13-incremental-text-layout-milestone.md)。

## 跨阶段承接

- 100KB多段尾部和超长单段布局成本保留。多段重复模式切换已修复；剩余长单段首/中成本不阻塞独立的显示/比例工作，如本阶段改动导致回退再带证据处理。不重复直接操作proxy storage和第二TextKit图的失败方案，也不把它们变成永久架构禁区：重新考虑须有不同根因证据与安全方案。
- 系统中文输入法集成（组合/候选定位/提交/取消）、VoiceOver、真实输入到呈现、多显示器DPI仍有未验项。输入法仅集成系统服务，不自研引擎、词库或候选生成，不穷举全部输入法；系统侧问题记录反馈，继续独立框架工作。AX树、程序化组合、公开socket调用分别标记，不能代替系统集成实测。
- K3此前确切CLI/model只读调用已接收提示但约120秒无答复，无有效建议。按环境受限保留，不算一次有效咨询，不重复撞同一故障或换模型。
- 工具链/长期FFI workaround按[反馈入口](../../docs/plans/DESIGN_INTENT_INDEX.md#问题反馈如何接回主线)接回既有账本，保留复现、影响与移除条件，不未经授权对外提交issue。

## 历史证据入口

[文字组合与AX](../../docs/plans/2026-09-13-text-composition-accessibility-milestone.md)、[正常宿主与包](../../docs/plans/2026-09-13-normal-app-host-package-consumption-milestone.md)、[高效观察与定向读取](../../docs/plans/2026-09-13-efficient-observation-targeted-read-milestone.md)、[公平调度与成本](../../docs/plans/2026-09-12-fair-scheduling-performance-baseline-milestone.md)。更早组件/层/资源/集合资产见设计导航。

[本次整理前的完整状态快照](../../docs/archive/2026-09-13-active-direction-before-status-consolidation.md)保留所有旧数据与冲突文案，仅作历史查证，不作为执行入口。

## 执行与自动接续

遵守[AGENTS.md](../../AGENTS.md)。每次阶段完成或升级，同时审阅交付及整体缺口，维护本页一个明确的当前阶段、状态、下一候选和遗留边界。必要旧问题与新框架能力一起安排，不按小补丁停工，也不把阶段改名当解决遗留。

原30分钟heartbeat `cjgui-4` 只是兜底，执行主动报告是主通道。先紧凑快照，正常且无新证据保持安静；只在状态异常/报告缺失或连续快照可疑陈旧时有界补查最近执行记录，不能仅因active或游标不变无限视为健康，也不能仅因任务耗时长就打断或重发。

同一问题两次实际修复验证失败后按AGENTS使用只读K3；两轮有效建议验证仍失败立即升级指导给具体方法。次数跨阶段累计，环境失败不计源码修复。锁屏只跳过依赖桌面的项目，不改系统设置，继续独立工作。

原目录、不新worktree、不切分支、不stage/commit/push/发布，不覆盖并行修改。完整交付或实质升级主动回报指导任务；最新用户指令始终优先。
