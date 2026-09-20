# 2026-09-19 ACTIVE 整理前历史快照

> 仅供追溯，不是当前任务或授权。原文件为 `runtime/cjgui/ACTIVE_DIRECTION.md`；全部原文保留，Markdown 相对链接已按归档目录调整。有效任务只见[当前状态](../../runtime/cjgui/ACTIVE_DIRECTION.md)。下文的“当前/继续/暂停”等指令均属于历史时点。

原文件 SHA-256：`53e2df8bd892b5116456ec7d90d8e1ee12452d42d68cb5dc5bab725a2c62962f`。

---

# CJGUI 当前方向与实施状态

更新：2026-09-19。本文件是唯一当前状态入口。历史数据保留在阶段报告，不作为仍待执行的指令。

## 当前任务

**当前阶段：macOS 通用树形视图、多选与共享批量操作（2026-09-19，任务已下发；工作区已有树相关新增实现，尚待执行者完整报告与阶段验收）。**
用户最新要求：鸿蒙 SDK 尚未获批，先集中 macOS。鸿蒙实验/SDK/模拟器相关开发、验证与排障全部挂起，保留资产，不等待鸿蒙才能推进主线。指导已准备[完整新任务](../plans/2026-09-19-macos-tree-selection-milestone.md)与[执行提示词](../plans/2026-09-19-external-executor-handoff-prompt.md)。外部执行 AI 主导，Terra CLI 按需聚焦咨询；原 Codex 定时与旧 Terra/Luna 任务继续暂停。本次仅复核/规划/文档，未运行开发。

本次接受分项：实际进入目标→公开 UDS APPLIED→松手前返回→同轮 drops=1，证明活动拖动期间接续；请求实际在 driver 静止 HOLD_START 之前，不虚称静止保持期/即时完成。hover read/parse/build/layout 差值断言已补；A4 已有受控撤销/重绑/过期事件与应用显式移除模态下声明的绿色。前期文档接续/公共clipboard导出保留，不重做。

必要旧项：剪贴板外层 LAST_EXPECTED 未跟随内层恢复更新，且 chain 粘贴后仍无条件 snapshot；正常释放检查只打印不判残留，负对照另设不等条件，不能证明关键对象释放。两项根因和可区分验收已写入新任务，合并一次 Terra 只读检查方案后由执行者落实。旧 acceptance3 是早期日志，不能替代新改动的验收。实际内存峰值仍未测；没有证据不把22/16直接解释为合法存活。

新能力：在仓颉既有虚拟列表/稳定身份/布局/输入/自绘基础上交付通用树、多选与键盘；规则窗口复用 BATCH_SET_ENABLED，外部授权操作100条含视口外记录并读回，独立 UI-only 第二消费者证明复用；100/1000/10000逻辑节点验证行物化和实际成本，最终一次公共导出。旧项与新能力按依赖交错，不先清零全部旧问题，不只补示例界面。

鸿蒙已有 Terra 咨询、C++ host/HAP构建为执行方报告，按用户要求本次不继续验收；不称仓颉/设备通道通过。其余长期未验：外部TextEdit实拖、人工物理输入、系统IME/VoiceOver、GPU实际呈现/真机性能、安装发布。

**2026-09-19 方向纠偏：** 运行时生成/修改界面是既定框架方向，应用可选择不接入；此前“可选扩展”及 README 的固定手写表述收窄了目标，已校准[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[生成契约](../core/AI_NATIVE_UI_SEMANTICS.md#运行时生成与修改界面)与[验收标准](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#运行时生成式界面验收)。现有动态组件与候选提交是基础，不等于外部生成已接通。树/多选在当前范围内收口，下一完整阶段优先[运行时生成与共同编辑](../plans/2026-09-19-runtime-generated-ui-milestone.md)，不以控件齐全为前置。该阶段仅已规划，本次没有启动开发或恢复定时；旧项按实际剩余带入。源码存在、脚本消费和真实模型生成分别验收。

用户同日进一步确认：一等公民包括同等开发权与数据权；同角色/授权下，AI 直接发现和使用完整的已支持信息与构建能力，不只是操作已有固定界面的按钮。组件注册是共同的可扩展机制，首轮少量控件不构成 AI 的长期限制；目标是减少截图转译、人工接线与数据镜像。

共同信息的落地原则与边界已记入[单一定义设计](../core/AI_NATIVE_UI_SEMANTICS.md#共同信息只定义一次)，并接入下一生成式阶段的[新增字段/规则变更验收](../core/CJGUI_UI_FRAMEWORK_COMPLETENESS_CRITERIA.md#共同定义的接入成本验收)。这是设计与任务补充，尚未证明实现完成，不额外启动开发。

## 历史状态（供追溯，不是当前指令）

**前状态（2026-09-17 晚暂停，已被上条取代）：** 30 分钟指导自动化 `cjgui-4` 已暂停。Terra 与现有 Luna 允许自然完成当前这一轮并保存证据、清理自有临时实例，随后保持空闲，不启动下一轮或新阶段。指导今晚不再复核接续；等待用户明天明确说继续后恢复。本条优先于下方较早的持续执行说明，未完成项如实保留。

**本轮共享文档窗口接续（2026-09-17）：分项通过，整阶段仍继续。** 当前源码的自有内存文档窗口已经完成桌面自动化的公开外写 `v0→v1`、不同真实指针选区的 Cmd-C/Cmd-V `v1→v2`、公开 read-range 读回、再公开外写 `v2→v3` 与窗口回显。该链明确经过 normal window、AppKit clipboard、native FIFO、仓颉 transfer provider 和既有 range owner；不是 direct callback，也不是人工物理输入。另一个 current-source test-only runner 已将 production destination callback→native FIFO→Cangjie normal window→既有文档 range owner 跑通，并在进程内公开 `READ_RANGE` 协议 dispatcher 读回；其 cancel、旧 target、换绑、禁用与关闭后 token 均 fail-closed。该受控 runner 不含跨窗 AppKit 派发或 Unix-socket 读回，不能和桌面证据混称。末步“窗口人工替换第二次外写文本并公开读回”在 macOS 锁屏时无法执行，标为 `not_run`；规则消费者、系统跨窗最终 drop、外部文本 drag/drop、modal/close、过期 identity、payload 峰值/释放及 tracking 公平性仍待完成。自有实例未带 `--file`，已退出；原运行目录的 socket 已不在，临时连接目录已移入废纸篓。

**09-17 数据交换复核结论：当前阶段继续，尚未整体验收。** 已修正旧导出 consumer 直接调用 `owner.applyDataTransfer` 的绕过路径；保留的 `/private/tmp/cjgui-framework-preview-consumption.Ltv5Bp` 是当前公开 clipboard 分项证据，其 `data-transfer-preview.manifest` 与原始 build/run/driver 日志均保留；run 显式标为 `mode=clipboard`、`platform_drop=false`。同一公开窗口还实际经历禁用期 Cmd-V（0 owner event）→启用后的 Cmd-V（1 owner event），并通过 `disabled_endpoint_rebind=true` 与 `disabled_endpoint_platform_paste_rejected=true` 记录。两段正式 clipboard 驱动均使用全 type/data 快照和 change-count 条件恢复，最新 run 均报 `restored=true`。native RED→GREEN 覆盖 production `draggingEntered → prepareForDragOperation → performDragOperation` 的受控 destination callback→FIFO（hover enter、drop、hover leave 及 native probe 内相同 format/payload 读回），以及 `draggingExited` 的无 PASTE/DROP 取消、hover 后 target 重绑/删除时清 slot和旧 target fail-closed；前者尚未进入 Cangjie window/业务 owner，且仍是 test-owned dragging info/pasteboard，不是跨窗 AppKit 派发。普通多窗口默认摆放也已修复：可容纳的第二窗与首窗 frame 不交叠。新版自有 CUA trace 已真实进入 target `draggingEntered`、看到正确 structured UTI并命中 node 14，却没有收到 CUA release 后的 `prepare/perform`，故只能称跨窗 target-enter 通过、最终 drop 仍是 automation `not_run`；未观察到完成派发不能单独归因于 CUA 是否投递 mouse-up。接续中的 trace 诊断已改变 current native/probe 源码，故 Ltv5Bp 不再声称覆盖当前 trace 版本；待本阶段新增行为完成后再做一次最终导出。该证据仍不包括同进程跨窗口实际 drop、外部文本 drag/drop、modal/目标关闭、实际 transfer payload 峰值/释放及两个正常业务消费者的完整窗口接续；这些须按阶段页完成。桌面自动化不能标为人工物理输入；不得把它或旧直接回调拼成 drop 通过。Terra按阶段页继续补齐，不换新方向；已验旧证据不反复重跑。

用户于2026-09-17恢复持续执行与30分钟指导自动化。原任务Terra/xhigh协调Luna/high在原目录实施[通用剪贴板、拖放与人机共同数据导入](../plans/2026-09-17-data-transfer-milestone.md)：复用既有组件/命令/系统文本输入/owner与授权传输，增加开发者可声明的有界文本/自定义格式copy、paste、drag/drop，同一业务接收同时服务人类与外部调用；两个正常消费者和独立导出验证。不新建Agent、输入法或第二状态机。完整范围、必要旧项与验收见阶段页，未提交未推送。

前一[高频交互的局部刷新与跨窗口公平调度](../plans/2026-09-14-interaction-scheduling-efficiency-milestone.md)经指导只读按已验范围接受。当前focused重叠：A已有64条hover pending时B普通输入与真实UDS抵达，external round1/pre-wait3ms、B动作/版本各+1、A释放动作+1、第65条拒绝，关A后B存活；只证明受控有界积压，不扩大为无限持续负载。960节点nextDrawable两组p50/p95为5.0625/6.125ms、5.667/6.084ms，encoder291/333us、250/292us；指导同意保留生产同步/节流，不宣称整体加速。locked合并日志sample20切行，独立result完整wait=0已核对。

当前最终导出 `/private/tmp/cjgui-framework-preview-consumption.QChXnf`，payload `eebdb44bfe1c3afe67e15c12cfd94e8800b0dc12d917c5a36f6ef9c36bc54c86`；指导核对ui/window/host/session/native m/h六项与当前一致。实际日志区分UI/document仅build、collaboration公开handoff及image/menu/vector运行；不称六类全运行。当前完整90轮在sample23 connection closed，原始 `/private/tmp/cjgui-interaction-scheduling-overlap-green-5`，一次有界搜索未定位原因；历史90绿/current focused绿/current full中断分列。该旧项与正常同A可见接续明确承接新阶段，不以锁屏猜测替代根因；再次出现同类连接问题先定位，不反复整套重跑。物理输入、系统IME/VoiceOver、实际呈现、安装公证发布边界保留。

前一[通用交互状态、组件样式与主题](../plans/2026-09-14-interaction-styles-themes-milestone.md)按受控范围接受，仍有明确承接项，不能称全场景完成。指导读取 native press-boundary/result，operation/action换绑、禁用、删除重建、模态/失焦、无关B与纯paint保持A、失败候选/重试和重复hover均为true；theme continuity原始日志末行PASS，像素变化且选区[2,11]、focus、scroll保持，idle无工作。这些是受控生产入口，标签physical不代表人工物理输入。106的实际根因为未挂载菜单目标预注册，执行改为已有SceneRefreshParticipant候选声明，报告controller通过；原始最终日志入口待执行补充，旧日志不能作新结果。

直接成本分解的当前 960 节点热态90样本显示：`nextDrawable` p50/p95 `5.062/6.125ms`、encoder CPU `291/333us`、present/commit 调用及 readback wait 为 `0`；锁屏时独立重测为 `5.667/6.084ms` 与 `250/292us`。余项明确不归因为 drawable/GPU；这些不是 GPU completed、实际呈现或端到端输入延迟，也没有安全 CPU 优化可宣称整体加速。旧 Preview l0P234 仍保留历史消费证据；native 测试分支已改变导出 payload，最终源码需再做一次正式 Preview 消费。当前 macOS 锁屏，故同 A 人类可见输入→外写→再输入、物理键盘、系统 IME/VoiceOver、实际呈现、安装/公证/发布仍为 `not_run`；旧 drag 对照不替代本阶段的 hover/press 混合证明。

前一GPU提交阶段经指导只读复核按受控与桌面自动化范围接受：原始30样本重算480组stage_submit p50/p95=1.611/2.029ms；当前最终tp8mzk与桌面w0mBBB导出各七项关键源码相同。桌面接续manifest报告A v1→外写v2→A v3，指导未亲自重复桌面动作。优化前逐样本文件丢失，仅保留指导此前实际核对的汇总值；不把旧路径当可重新读取的基线。

历史阶段[矢量GPU提交效率与正常应用接续](../plans/2026-09-14-vector-submission-efficiency-milestone.md)已按上方限定范围接受；原目录未提交、未推送。通用提交从176-byte通用顶点与4KiB小块转为每个矢量节点的16-byte local Metal buffer加绘制期uniform，画面顺序、clip、MSAA、命中与COW scene owner不变。16/128/480、各30次局部paint当前样本的通用提交均为0，480为480次draw、首帧480次上传/后30帧0上传/480次复用，encoder CPU为250us；`stage_submit` p50/p95=1.611/2.029ms（含可能等待，不作GPU完成或物理呈现时延）。几何容量变更仅上传一个改动节点；1x→2x→1x的两次resize均0上传、5次复用、驻留12,288B。已有正常 `Adaptive Layout Public Consumer` 复用可点击矢量组件和既有 `TOGGLE_RESOURCE` action，normal bundle经外部0→1→2状态读回。最终含空格导出为`/private/tmp/cjgui-framework-preview-consumption.tp8mzk`：其公共manifest正确标记桌面输入为`not_run`，不再伪造true；另一个相同导出bundle的 CUA 桌面自动化已实际完成A输入→外部A读/写→A输入、版本1→2→3与几何读回，独立manifest为`/private/tmp/cjgui-vector-interactive-desktop-final/manifest`。这条是桌面自动化输入，不等同物理人工输入；物理输入、IME/VoiceOver、GPU completed、安装/公证/发布仍为`not_run`。具体实现、原始产物和基线边界见阶段页。

前一[应用命令、菜单与快捷键统一接入](../plans/2026-09-14-application-command-menu-milestone.md)经指导只读复核按下述受控范围接受。指导读取三组原始 result，最终独立导出的 host/window/session/native 文件与工作区一致；退出 probe 的 native 指纹早于最后菜单更新，不虚称它覆盖最终产物所有退出场景。无 key 退出边界已随当前阶段承接。普通 LaunchServices 双窗 bundle 的 Quit 经实际标准菜单项进入既有 `CjguiMacosApplicationExitDecisionProvider`：两次拒绝均保留连接、窗口与 B 的 `persisted@2` 内容，重复请求合并，第三次允许后 application 关闭且窗口归零；原始回执为 `/private/tmp/cjgui-command-menu-exit-native-runs/run.3AkAAV/result`。同一 normal bundle 的实际 `NSApplication sendEvent` 验证 Cmd-Z/Shift-Cmd-Z 各只到一个 document owner、内容读回 `current@4`；layer 和 disabled layer 的声明都保留快捷键而不回退标准 Edit responder，原始回执为 `/private/tmp/cjgui-command-menu-native-runs/run.DgiPhR/result`。相同 key window、命令投影与有效 scope 不变时，仅 scene 版本更新的重建计数保持 `1→1`，回执为 `/private/tmp/cjgui-command-menu-effective-projection-runs/run.OP1SEJ/result`。最终公共导出只运行一次且保留于 `/private/tmp/cjgui-framework-preview-consumption.delrQW`：含空格 relocated 包的两个纯 public Cangjie owner 构建运行，`command_owners=2`、stable target、按钮/`invokeCommand` 同一 action、projection readback 和 disabled 拒绝均通过，manifest 为该目录的 `command-menu-preview.manifest`，source/preview payload 均为 `04f8aa872fa94f2975f0ad1dde7c93620c8487dd32c051560bd17980a91335c6`。`runtime/cjgui` 核心测试 9/9、命令 contract/binding probes、runtime build、shell/diff 检查均通过。README 已写明 native 只持有不解释的稳定 command id、Quit 的异步意图边界、Undo/Redo 优先级及有效投影更新规则。以上是受控正常 AppKit 菜单和合成 `sendEvent` 证据；人工菜单栏 tracking、物理键盘、IME/VoiceOver、安装/公证/发布仍为 `not_run`。

前一[应用内图片资源复用与异步更新](../plans/2026-09-14-application-image-resource-milestone.md)经指导只读抽查按受控范围接受：共享加载/版本更新、orphan与候选需求清理、有界预加载推进、压力下cache与scene保留量、真实application混合负载及最终含空格独立导出。接受范围不含物理显示/输入或安装发布。

当前源码的独立双窗 domain runner 证明同 key 的初始实际加载/解码均为 1、两窗订阅为 2；蓝色 `BGRA=224,96,24,255` 与珊瑚 `76,100,236,255` 由真实 drawable readback 区分，30 次热切换均 ready（7–8ms 的受控 `MonoTime` 样本，不作端到端或物理呈现时延声明）。A 发起同 key v3 后关闭，B 仍 ready，subscriber/active-session 收敛为 1；路径/版本、坏文件失败与显式新版本恢复也有普通消费者覆盖。新增 gate RED→green：A 的 16 个未启动孤儿请求关闭后被释放，B 一次 pump 后 ready；强制候选失败会清候选独有 requester，而明确 `prepareImageResource` preload 跨无关 scene commit 继续有效。20 preload overflow RED 中前16加载后另4永久 busy；修复后20次实际加载在6 turns收敛，按 reusable cache=8 保留8 ready、其余12回到可再请求的 unrequested，不伪称全驻留。9 图/36MiB/65-version 压力分别实测 cache=8/8,192B、scene ref=1/cache=0、records=64，不能把 reusable cache 预算误读为总 GPU 内存。公开 UDS 30 次写入和 B 的普通 AppKit 输入交错时，16 个显式 preload 实际全启动、peak in-flight=4/peak pending=16，日志根为 `/private/tmp/cjgui-image-fairness-final/`。含空格隔离目录导出后，纯 public API 的双窗图片消费者用 bundle 内资源构建运行，两窗 ready、关 A 后 B ready、实际启动仅 1 次；manifest 为 `/private/tmp/cjgui-framework-preview-consumption.X4Xe9P/image-multiwindow-preview.manifest`，source/preview payload 同为 `0b6908f5ac43cdda730eb96ea8921b012092ce7de7d3d5a830e35e4dc42de2b4`。这都不是人工物理显示、物理输入、GPU completed、安装/公证/发布证明。原始 domain/consumer/public manifest 分别在 `/private/tmp/cjgui-application-image-explicit-overflow-green-2/manifest`、`/private/tmp/cjgui-application-image-resource-consumer/manifest`、`/private/tmp/cjgui-application-image-resource-public/manifest`；相关资源效率回归按 domain baseline/run delta（12/6/24）通过。未提交或推送。

前一[复杂场景局部更新与持续交互性能](../plans/2026-09-14-complex-scene-update-performance-milestone.md)经指导只读复核按受控范围接受：真实scope runner、generation重编号/拒绝恢复，以及同application的30次公开屏外批次与B输入接续、动态结构/字体/resize和idle/session收敛已具原始证据。指导核对mixed的8项源码哈希及两probe二进制指纹一致，未重跑测试；AppKit受控输入不是物理输入。证据入口 `/private/tmp/cjgui-complex-scene-application-mixed-current/manifest` 与 `/private/tmp/cjgui-complex-scene-scope-runner-current/complex_scene_timing.manifest`。

本轮的真实刷新事务新增仅包内的分段诊断；正常公共消费者仍只有毫秒投影，不能把它误读成纳秒计时。复杂 scope 的实际局部输入更新（33/257/961 nodes，各 30 样本）在 961 nodes 时 `stage+submit` 的 p50 按排序后中间两项均值定义为 `18.3445ms → 3.383ms`，p95 为 `22.972ms → 4.404ms`；它包含 configure、节点设置、present 以及可能的等待，不是纯查表、GPU 完成或物理呈现指标。优化是保持 first-seen scope code 语义的临时 `HashMap` 表，替代反复线性查找；33/257 节点基本持平，不推广为所有界面普遍加速。可复现入口 `native/scripts/complex_scene_performance_timing_runner.sh` 实际构建/运行 16/128/480 scope、各30条原始样本，输出源/二进制/参数/日志 manifest；当前原始根为 `/private/tmp/cjgui-complex-scene-scope-runner-current/`。scope 删除/重排的焦点 remap、旧 generation 事件拒绝、空/重复 scope、失败保留及重试新 generation 同由该入口覆盖。32/256/960 nodes × local-color/add-remove/reorder/image/resize 的当前源码原生场景矩阵共 450 样本，15 个 idle 与 15 个失败恢复记录完整；报告为 `/private/tmp/cjgui-complex-scene-scale-report-current.json`。

本轮同 application 混合负载入口 `native/scripts/verify_complex_scene_application_mixed.sh` 启动受控的两个真实 Cangjie normal windows：公开 UDS `REPLACE_RANGES` 30 次各更新 A 的16个屏外行，同时 B 每次经普通 AppKit text delegate 输入；公开客户端在开始和结束分别枚举精确 window target、读取 target context/progress，并对 A/B 版本和内容读回。第10次动态删除首行并重排/重定锚点，第15次插入新行，第20次字体失效和真实 NSWindow resize；完成后两窗口 build/submission 增量均为0、transport active client为0、native session已回收。当前原始 manifest、application/client 日志位于 `/private/tmp/cjgui-complex-scene-application-mixed-current/`；这仍是受控 normal application 证据，未声明人工物理输入、IME、GPU完成或物理呈现。

通用 renderer 已修复按钮相同 `label/value` 的重复绘制，不改变语义字段或不同表单标签/值的显示；独立 current-source 临时 bundle 的 CUA AX/截图已确认每个按钮只显示一次。根 `cjpm build --skip-script`、核心 9/9、规则 5/5、文档 6/6、两种 bundle build 均通过。正常规则/文档消费者的公开 UDS smoke 在 5 秒边界完成 create/CAS/readback/recovery，计时是 1ms 粒度；正式 Preview 在含空格隔离路径构建三种消费者通过，payload 为 `bf2d6ff558be365edac2588dac9864066a49a4a9788439b7863e1601d03069ab`，证据根为 `/private/tmp/cjgui-framework-preview-consumption.9rorTC`。

解锁后的 current-source 临时文档多窗口实例经 CUA 关闭可见 A 后，B 审阅窗口仍可见并可获得控件焦点；这是前台 sibling-survival 的最小证据，不替代物理键盘、IME 或人工 Cmd+` 切换。用户原有规则 PID `9726` 与文档 PID `9728` 未被停止或写入。系统 IME/VoiceOver、独立物理输入、实际呈现、安装/公证/发布仍为 `not_run`。

### 前阶段接受范围与原始入口

**连续指针阶段唯一当前结论（09-14）：** 当前源码已完成受控 native 捕获、普通消费者坐标拖动、真实 public UDS 同轮交错和正式 Preview 消费。新增的键盘路由实证不再直接调用 overlay：pointer 焦点后，`NSApplication sendEvent` 经 key window/first responder 到 composable overlay（route flags `31`），再由仓颉 owner 处理，direct control 与 application route 各产生一次调整；原始日志为 `/private/tmp/cjgui-pointer-capture-app-route-final/probe.log`。此前 CUA `Right` 后状态不变只说明当时的自动化观测没有产出，未区分工具是否投递、投给哪个 window，或当时 responder 状态；不能用它断言“未到 scene”或“不是源码问题”。当前隔离的文档滑块窗口 PID `89253`、源码 binary SHA-256 `86c71876ae50f7605aa21fb1c526a389488ad37837b1a13d25dfe657c27c97b6`，已由 CUA Raise、坐标拖动建立 pointer focus 后真实发送 `Right`，AX 读回滑块和状态文本由 `160` 同步变为 `192`。这是当前桌面自动化键盘链路的通过证据；若需与之区分的物理键盘，及系统 IME、VoiceOver、安装、公证、发布仍为 `not_run`。最终 Preview source/preview payload 均为 `56df3bd50a5065c8f7f6002a82d58517962e60a09bf671e1a31842cbb0cbcc8a`，三消费者在含空格隔离目录构建通过；UDS 混合原始 `probe.log`/`public-calls.log` 位于 `/private/tmp/cjgui-pointer-public-interleave-app-route-final/`。根 `cjpm build --skip-script`、控件消费者及相关 probes 均串行通过。

**本轮可见文字与 CAS 补证（09-14）：** 同一当前源码隔离 document 窗口的 CUA AX 与截图均显示中文三行正文及完整的 `emoji 🙂 不会被拆开。`，列表项、编辑区和状态预览三处一致；因此 CJK/emoji 的当前可见渲染为通过。解锁后的正常 document 窗口还完成了最小 GUI→CAS→GUI 链：通过原生编辑控件粘贴 `GUI 输入：仓颉中文🙂\n第二行：UTF-8 字节边界。`，得到文档 v12；随后经公开 `REPLACE_RANGE` 以 expected v12 在 UTF-8 字节 `63..63` 追加 `CAS 追加：已核验。`，应用为 v13，AX 的列表、编辑区、预览和公开 read-range 均读回同一完整内容，窗口 `pending=none`、`failure=none`。CUA 的直接 `typeText` 同一 CJK 字符串只留下 ASCII 片段，故它不是 CJK 键入通过证据；物理键盘与系统 IME 仍为 `not_run`。

下方过程记录中较早的“GUI 滚动/点击”或“GUI→CAS→GUI 为 `not_run`”仅描述当时锁屏前的边界，均由本段及变量集合阶段末尾的解锁后补验覆盖。

**旧实例复查与恢复（09-14）：** 用户已确认是其手动关闭此前仅作保护性观察的规则 PID `13539` 和文档 PID `18369`，并授权重启。按原 normal bundle 已重启为规则 PID `9726` 与带 `--with-connection` 的文档 PID `9728`；重启本身未写入用户数据。后续上述 CJK/CAS 验收只改动了默认文档的未保存内存状态，未传入 `--file`、未触发保存；它不替代当前源码的规则 GUI 验收，历史截图或日志也不补作该证据。

### 过程记录（非当前状态）

**2026-09-14 连续指针交互与共同操作控件：源码、受控 native、普通 bundle 公共调用和 Preview 消费已有分项证据，整阶段仍在接续；当前源码的人工拖拽/键盘与“公开调用和突发拖动同轮竞争”仍为 `not_run`。** `CjguiComposableUiPointerCaptureVersionProvider` 让已捕获目标按其 owner revision 判断有效性：规则分隔区仅看 `splitFirstSizeVersion`，文档滑块仅看所选文档的 `previewLimitVersion`，无关对象外部写不取消拖动；同目标外部写、目标删除、模态转换均取消并撤销平台捕获。两个普通消费者分别经同一公开控件/owner 路径采用 split 和 slider；`SET_SPLIT_SIZE`（160..720）与 `SET_PREVIEW_LIMIT`（128..512、步长32）均经过现有授权、CAS、读回，未新增第二可写状态。生命周期 probe 已覆盖移出原 bounds 后结束、同 owner 外写取消、无关 owner 外写保持捕获、目标删除和模态取消。受控连续负载在每条件 30 个新 session 样本中：低频 240 次 update 全处理、合并0、每轮真实待处理 FIFO 上限1；突发 960 次 update 实处理30、合并930、每轮 FIFO 上限3，end 均保留，另一 idle window 的 scene/submission 均无变化。计时是 native enqueue 至仓颉 dispatch/投影的受控阶段（低频 20/22/45ms，突发10/11/14ms 的 min/avg/max），不代表物理呈现或人类输入延迟。核心 `cjpm test --skip-script` 46/46、规则 16/16、控件消费和根 `cjpm build --skip-script` 均通过；新 normal bundle 的公开 socket 分别实际写入 split=416、previewLimit=224，并拒绝 stale CAS。最新 Preview 在含空格隔离路径重新导出、构建三消费者，source/preview payload 同为 `bf2dc2e8a5f1f56d71522449f73ff13da06fad3decb8a30e140133fb1840d831`。已解锁后仅只读截取到规则集（PID 13539，9月13日启动）和文档（PID 18369，9月14日02:02启动）旧进程窗口；其 AX 快照仍超时，且为保护未知会话未重启/写入，故不能把截图冒充当前源码的真实拖拽验收。安装、公证、发布同为 `not_run`。

**09-14 后续实证（历史快照；键盘归因已由上方唯一当前结论更新）：** 用户旧 PID 未动；当前源码的独立临时 normal bundle 完成坐标拖动和真实 UDS 读回：文档 `128 → 外部352 → 人工192`，规则 `436 → 外部416 → 人工452`。真实 public UDS 与预先入队的 pointer burst 在同一 `pumpOneTurn` 交错：无关 B owner 保持 A capture，A 正常 end 且 B scene `1 → 2`；同 owner A 写入取消 capture，旧 move/end 均为 `99`、不能覆盖外部 `416`。受控生命周期复跑为 30 样本低频 `240/240/0`、FIFO 高水位 `2`，突发 `960/30/930`、高水位 `4`；控件消费者、生命周期、UDS 混合 probe 和根 `cjpm build --skip-script` 均串行通过。该轮 CUA `Right` 无状态变化只是未能判定其投递/目标/responder，不能得出“未到 scene”或“非源码问题”；物理键盘、IME、VoiceOver、安装、公证、发布仍未验。

指导已只读抽查布局阶段生产默认、最终报告与binary hash（匹配）及正式导出绑定，按以下范围接受；GUI/IME旧欠项继续保留。

[前阶段：局部更新的布局复用与稳定性能](../plans/2026-09-14-incremental-layout-reuse-milestone.md) 按范围完成。公共 cache 绑定 `CjguiComposableUiLayoutMeasurementEnvironment`，native session 与 resize/backing-scale generation 分隔缓存；default 只接受显式 `layoutReuseKey` 的安全区域，未标记区域规范布局。完整 structural signature 仍可通过 `allowStructuralSignatures: true` 显式用于诊断，但不进入正常窗口。缓存限制 4 条目、1,024 节点、262,144 字节字符串和 524,288 字节估算总量，pending 与 accepted 都计入；nested scroll/layer、失败 candidate 和环境改变都不能错误晋升。规则 header 与文档 action bar 为两个实际消费者，`WINDOW_LAYOUT_REUSE` 仅投影派生工作。

最终计时证据为 `/private/tmp/cjgui-incremental-layout-timing-v4-final/incremental-layout-reuse-report.json`（probe SHA-256 `7316e3a68eaac22cb672a7afef8c736ab8f55f831a5ab0192f9fa9ada90d1807`）：同进程交错 canonical、diagnostic structural 和生产 opt-in，6 条件 × 3 行数、每条件每模式 30 个有效样本，Cangjie `MonoTime` 分别测 build/layout，比较与打印在计时外。760 行 local 的 build+layout p50 为 canonical 3.771ms、diagnostic structural 9.293ms、production opt-in 3.415ms；因此默认关闭完整签名。warm/local 的显式稳定区域有收益；resize/font/full invalidation 完整求解且 p50 为 4.164/4.176/4.220ms，高于 canonical 3.762/3.748/3.805ms，不宣称收益。每个 cache 结果均在计时外与同测量缓存的 canonical target 比较 projection。

当前普通 bundle 报告为 `/private/tmp/cjgui-incremental-layout-normal-window-v4-final.json`：规则批次/CAS/readback/完成帧通过，`WINDOW_LAYOUT_REUSE 1 0 14 14 1`；文档 replace/stale CAS/range readback/完成帧通过，`1 0 6 6 1`。core 全量 `cjpm test` 串行通过 45/45；首次 PendingClientRequest 编译错是与 build 并发写同一 target 的临时产物竞争，未扩大 internal API。最新 Preview 在含空格隔离路径重新导出并构建三消费者，payload `59270f894920aa41f2782aa50dd21250655be363ea4c4d6e9b3e55c5554b33c7`，原始根 `/private/tmp/cjgui-framework-preview-consumption.a0y9Qx`。这些是源码、受控 native 进程和导出消费证据；人工 GUI/IME、VoiceOver、安装/公证/发布均为 `not_run`。

上一多窗口阶段的关键源码及 exception/identity/partial-creation 原始日志、最新导出绑定日志已由指导只读抽查，按受控运行/公共消费范围接受；没有重跑执行测试或声明人工验收。旧 26c0c45c 是历史，最终多窗口 payload 为下文 a34c49a1。

**同进程多窗口阶段按范围完成：完整公开 target 读取、外部积压下的 B 进展、生命周期异常/共享 loop 归属、失败恢复与最终 Preview 消费均已验证。前台人工 A→B 操作、系统中文输入/IME、滚动/选区可见性和物理呈现仍为 `not_run`；未声明旧文字或变量集合阶段的人工 GUI 欠项完成。**

- [前阶段：多窗口](../plans/2026-09-14-multi-window-application-milestone.md)：应用级窗口生命周期、单调度器预算、同owner多窗口更新及独立关闭/失败恢复已有按范围证据，前台欠项继续承接。
- 多窗口当前证据：`CjguiMacosApplicationWindowIdentifier` 绑定不可复用 application owner 与单调 window generation；跨 application 和重建旧 id 均拒绝。公共 client 提供 `window-progress <target>`、`window-interaction <target>` 和 `wait-window --target`，关闭 A 后 A 的 context/progress/interaction 均返回 `unknown_window_target`，B 仍独立可读；重开 A 是 generation 4 的新 target。实际公开 CAS 在连接存活时使 B 到 scene 2；四个真实 public UDS caller 的有界积压中，transport `ready_high_water=4`、`serviced_actions=133`，235 个被记录的 turn 中有37个服务外部动作，B 仍从 scene 1 到2（一次 CAS turn 的 wait budget 为0，故不宣称每轮都有正等待预算）。`pumpOneTurn` 的回调异常现在释放 guard 并把异常继续传播；关闭 application A 后，B 仍处理真实输入；native capacity 造成的 B 首次创建失败不影响 A，容量释放后 B 可重新创建。`native/scripts/verify_multi_window_application.sh` 的本轮原始根为 `/private/tmp/cjgui-multi-window-application.boxfKa`，组合结论包括 `exception_guard=passed`、`identity_binding=passed`、`partial_creation=passed`、`busy_backlog_b_progressed=true`、`closed_target_rejected=true`、`sibling_target_survived=true` 与 `endpoint_cleared=true`。最终 Preview 从该源码重新导出并在含空格隔离路径构建三种消费者，source/preview payload 同为 `a34c49a1874a83d997f89b77a99a62b9274716dc741a89cc38fc22c82f04de97`，document bundle 为 `e1dafb594c476f81e03fa90a4aa981ee053057726d5bedaf6e8edbe1d89a76fd`，日志根为 `/private/tmp/cjgui-framework-preview-consumption.pmbLyk`。这些都是源码/受控运行/导出消费证据，submitted 不是前台可见声明。
- [前阶段：变量集合与源码证据](../plans/2026-09-14-variable-height-collections-milestone.md)：指导已抽查布局修正、局部revision、公开macOS摘要wrapper及native边界；最后GUI滚动显露/点击/共同接续继续not_run，不能把协议读回与旧bundle当最终窗口验收。
- [前阶段与未验承接](../plans/2026-09-13-low-latency-text-resource-milestone.md)：120Hz预算仍是优化方向；100KB插入残余与系统输入/真实呈现边界保留，不反复重测无关文字矩阵。GUI欠项不阻塞独立仓颉布局工作。
- 当前已证：以同一 test-only binary（SHA-256 `9bffe01b...dff09`）运行的 `reuse → full → full → reuse` 受控对照，覆盖正常/256混合两 workload、开头/中部/末尾、光标/范围；每模式720个有效样本，正文复用全部为0 raster/0 upload，强制既有完整正文准备全部为1 raster/1 upload（各1,468,416 bytes）。外层 `selection_caret_total_ms` 为毫秒粒度：复用p50/p95为0ms、max6ms，只能表示低于时钟分辨率而非零耗时；full-body p50=14ms、p95=15ms、max19ms。它是当前机制对照，不是历史版本比较、插入延迟或物理呈现。原始根为`/private/tmp/cjgui-selection-ab-final.BEBjz7`，含manifest、四轮stdout/stderr与回归/导出日志。插入100KB多段的历史约16ms残余仍不能被本对照覆盖或改写。
- [正常窗口显示、输入与缩放阶段](../plans/2026-09-13-window-display-input-scale-milestone.md)按已证范围接受：指导直接看原始工具截图确认中英文/箭头/emoji正向；核对文字与图片UV路径分离、backing通知及2x→1x受控结果。正式导出三消费者成功日志为`/private/tmp/cjgui-preview-document-closure-green-2.stdout`，source/preview payload与指导当前只读重算均为`f0266b8d824b8d3c1baa6161a42c65c499f3c6bc1701bafb0003d89c63d5ff6f`，renderer为`20f1a1512d58be233aaa737f925e4f316be3e060cb0aed80d6c6f7a0b1cb9e44`。指导未重跑构建/开发测试。
- [连续编辑阶段](../plans/2026-09-13-continuous-editing-local-update-milestone.md)的mode toggle及重复准备修复已承接到正式导出。其100KB多段16/17/17ms和长单段首/中179/171ms属于当时测试条件；verbose观测已改为按需，后续须重新建立当前基线，不能跨观测条件宣传加速。长单段残余保留，不无依据扩第二排版图。
- 已解决正常窗口文字倒置、导出文档core缺失，以及 CJK/emoji 后追加ASCII导致可见字形损坏：根因是 `NSTextView.font` 的首字符fallback getter 被误当成base样式变化，随后全局setter清除了逐字符fallback runs。修复保存最后一次实际全局写入的base font，只有同node/同base/非空且已建立fallback时跳过setter；首次聚焦、清空、重绑和真实样式变化仍赋值。AppKit probe已覆盖CJK/emoji owner确认、清空、外部恢复；最终源码app此前已在前台完成本地Z→v1、外部CAS→v2/stale conflict、状态投影和本地Q→v3，但该次之后增加了base-font区分与test-only A/B seam。当前无测试flag app已重新构建启动，因锁屏未能读回最后窗口，不能把前一截图冒充当前binary验收。物理键盘/IME、VoiceOver、真实多显示器、presented事件、安装公证发布仍未验；CUA Unicode typeText/粘贴异常的具体事件归因也未闭合。
- 可变高度集合当前源码实现已完成核心/两消费者/规模探针，并经三轮指导复核补齐：变量路径先解估计范围，若真实行较矮则只在同一128行预算内补测至覆盖视口，最后按同一测量快照发布 range/total/origin；overscan 先保可见行且只作为后置有界 buffer，避免前置 estimate 压缩后重建不同范围。公共变量 row source 以单项 revision、title 和全局 measurement generation 形成派生缓存键；stable key/intra-row anchor 覆盖前插、删除后继回退、屏外修改不自动reveal、主动显露和宽度失效。核心红测已复现并修复“1000 estimate/10 actual 高度的500px空白”与`overscan=1000`越界；回归还覆盖超过128 key淘汰返回、混合高度、尾部 reveal、宽度失效。规则把 selection 仅折入A/B的行级revision，generation只保留字体，且revision组合为饱和算术；文档样例只使用 `cjguiExperimentalDocumentPreview` 公共仓颉结果，internal bridge/`CString`/资源释放不再出现在消费者。该实验入口限定macOS、<=2KiB scalar-safe输入窗口、`maxBytes=4..512`/`maxClusters=1..160`，native在组成簇选择前预留省略号预算；文档消费者补齐ZWJ回缩 RED→GREEN 后为5/5，runtime为7/7、规则为1/1。`verify_composable_ui_appkit_text.sh`、两应用当前 build、根`cjpm build --skip-script`和最终preview export均按相应范围通过；导出后迁移到含空格路径的三种消费者都从导出框架构建，source/preview payload同为`b1f6302b…305645`，本次原始成功日志为`/private/tmp/cjgui-framework-preview-consumption-final-log.pe0OpN`，current normal rule/document bundles分别为`84f3a384…7f936b1`与`c9734ebc…02b1fc`；旧公开owner原始JSON不冒充新bundle GUI验收。平台无关规模probe不链接该bridge，按复核结论没有因这一封装重跑，仍只对应先前source/scale-binary指纹。毫秒计时布局p50/p95=0仅是时钟下限。当前 normal rule bundle 已经完成实际外部 owner→屏外行→CAS读回（含陈旧冲突拒绝）；人工滚动显露/后续点击、UI scroll/selection 不变量及 current normal GUI 连续链仍为`not_run`，阶段等待指导最终验收，不把源构建/探针冒充完成。
- 执行任务`01a08f82-b682-73c0-a9b0-25a27bc5ffd8`整阶段完成或重大阻塞主动报告指导`01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。下一候选据实际主线程/渲染热点和正常消费决定，不能无限追单一长单段。Cangjie1.1.3、包根runtime/cjgui、原目录、不切分支、不stage/commit/push、不安装发布、不覆盖用户实例；锁屏继续独立工作。

## 方向与本轮取舍

最新GUI状态（2026-09-14）：中文正文末尾输入ASCII `Z` 后，owner/AX正确而可见汉字乱码的根因已定位并修复，未采用全量fallback、延后刷新或全量glyph失效。实际前台源码窗口曾确认CJK/emoji完整、本地Z→v1、外部CAS append→v2、stale v1→`version_conflict`、状态同步与本地Q→v3；当前最终normal binary重新启动后系统锁屏，尚待解锁后以同一GUI接续最小复查。A/B当前binary对照和正式三消费者导出已完成，详见本阶段末尾记录。

锁屏期间已完成首帧 `scene_color_mismatch` 修正：按最终drawable texel反推逻辑点，纳入同节点及上层正文/瞬态几何覆盖；覆盖场景如实降级，干净色块仍比较。指导抽查源码、场景成功日志和最终三消费者导出，payload为`d15a8c634d611bbb3e850d975d031a98920ca41abfd7dc3b82948121263b4cf0`；生产源码消费已经完成，只有相关前台接续继续挂起，不能用旧运行进程代替新bundle。当前转向可变高度集合，不继续围绕已经闭合的取样问题打转。

CJGUI 是基于仓颉、类似 GPUI 的高性能自绘/GPU GUI 框架，macOS 首个平台、窄平台桥接。GPUI 是参照，不逐接口复刻，不宣称已有相当性能。人和外部 AI/模型/Agent/脚本通过同一应用内容、上下文和真实动作共同操作；应用开发者决定界面与交流体验，不强制聊天窗或 Agent runtime。S-expression 仍是可替换的候选编码。

领域拥有内容、草稿和业务规则；组件拥有必要的焦点、选区与视口。画面、AX和外部语义是投影，不另造可写真相。已有授权可覆盖屏外批量操作；可见性、弹窗和AI身份不自动增加授权门槛，真实约束/冲突/未授权目标仍须处理。

六主线取舍：布局性能和连续指针已有按范围证据；真实新增暴露nodeId碰撞，当前优先开发者安全组合/动态身份与语义目标稳定。不是增加样例按钮，而是让复合组件可重复嵌套消费；GPU/文字/资源已有成果保留，旧系统交互边界单列。

方向与旧资产入口：[设计意图导航](../plans/DESIGN_INTENT_INDEX.md)、[项目方向](../core/GUI_PROJECT_DIRECTION.md)、[共同操作设计](../core/AI_NATIVE_UI_SEMANTICS.md)。历史避坑重点落实在布局状态归属、测量失效与无变化不重绘，不能仅列链接；旧 opening 禁令不恢复。

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

最近文字阶段报告：core 40/40、runtime 5/5、native text/scene/window/host、项目根build通过；两个最终bundle重建并完成公开owner写入/冲突/读回/完成帧。已解锁实窗出现正常AX树，不等于物理中文IME、VoiceOver或人工像素验收。详细样本条件和探针局限见[文字布局交付](../plans/2026-09-13-incremental-text-layout-milestone.md)。

## 跨阶段承接

- 100KB多段尾部和超长单段布局成本保留。多段重复模式切换已修复；剩余长单段首/中成本不阻塞独立的显示/比例工作，如本阶段改动导致回退再带证据处理。不重复直接操作proxy storage和第二TextKit图的失败方案，也不把它们变成永久架构禁区：重新考虑须有不同根因证据与安全方案。
- 系统中文输入法集成（组合/候选定位/提交/取消）、VoiceOver、真实输入到呈现、多显示器DPI仍有未验项。输入法仅集成系统服务，不自研引擎、词库或候选生成，不穷举全部输入法；系统侧问题记录反馈，继续独立框架工作。AX树、程序化组合、公开socket调用分别标记，不能代替系统集成实测。
- 当前重复失败按用户2026-09-14新规则：取消K3，Luna/Terra累计3次有效修复仍失败交指导给方案，最迟第4次升级；结构问题可提前。历史K3记录不再作为执行指令。
- 工具链/长期FFI workaround按[反馈入口](../plans/DESIGN_INTENT_INDEX.md#问题反馈如何接回主线)接回既有账本，保留复现、影响与移除条件，不未经授权对外提交issue。

## 历史证据入口

[文字组合与AX](../plans/2026-09-13-text-composition-accessibility-milestone.md)、[正常宿主与包](../plans/2026-09-13-normal-app-host-package-consumption-milestone.md)、[高效观察与定向读取](../plans/2026-09-13-efficient-observation-targeted-read-milestone.md)、[公平调度与成本](../plans/2026-09-12-fair-scheduling-performance-baseline-milestone.md)。更早组件/层/资源/集合资产见设计导航。

[本次整理前的完整状态快照](2026-09-13-active-direction-before-status-consolidation.md)保留所有旧数据与冲突文案，仅作历史查证，不作为执行入口。

## 执行与自动接续

遵守[AGENTS.md](../../AGENTS.md)。每次阶段完成或升级，同时审阅交付及整体缺口，维护本页一个明确的当前阶段、状态、下一候选和遗留边界。必要旧问题与新框架能力一起安排，不按小补丁停工，也不把阶段改名当解决遗留。

原30分钟heartbeat `cjgui-4` 只是兜底，执行主动报告是主通道。先紧凑快照，正常且无新证据保持安静；只在状态异常/报告缺失或连续快照可疑陈旧时有界补查最近执行记录，不能仅因active或游标不变无限视为健康，也不能仅因任务耗时长就打断或重发。

同一旧问题累计3次有效修复失败后按AGENTS交指导给方案，最迟第4次升级；不再调用K3。次数跨阶段累计，环境失败不计源码修复。锁屏只跳过依赖桌面的项目，不改系统设置，继续独立工作。

原目录、不新worktree、不切分支、不stage/commit/push/发布，不覆盖并行修改。完整交付或实质升级主动回报指导任务；最新用户指令始终优先。
