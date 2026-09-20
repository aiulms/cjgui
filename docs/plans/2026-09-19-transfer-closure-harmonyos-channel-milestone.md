# 大阶段：数据交换可靠性收尾与鸿蒙自绘通道验证

> **2026-09-19 用户最新指令：鸿蒙暂缓，集中 macOS。** 本页不再作为完整继续执行指令；鸿蒙所有开发/环境排查挂起。macOS 必要旧项连同通用树/多选新能力已迁入[新阶段](2026-09-19-macos-tree-selection-milestone.md)。新阶段含指导本轮证据复核与剩余问题的具体方案，下方“继续鸿蒙/所有独立工作完成”等旧安排由此取代；历史代码/日志保留，不清理。


日期：2026-09-19。状态：用户要求准备完整任务，待交给外部执行 AI 启动；本文件不唤醒旧 Codex 任务或定时。

## 最新指导复核：交付报告收到，仍有独立可完成项（2026-09-19）

本节覆盖下方执行记录中的“全部完成”“唯一环境阻塞”。指导做静态源码/脚本审阅和原始日志核对，未运行构建、桌面操作或鸿蒙应用，未恢复旧定时。仍是本阶段的旧项与新能力一并推进，不另开阶段，也不要求重做已接受绿色。

**已确认的进展：** 两个桌面脚本已去掉按通用进程名杀进程，使用按轮应用身份和 PID；A1 原始日志确有对照进程存活结果。A4 run-17/21/22 分别有 hover 后撤销旧目标、已入队后有效代际撤销的双拒、模态打开时撤销声明/关闭后重装的受控绿色；最后一项证明显式撤销声明路径，不自动证明保留声明时框架 scope 阻断。A3 已接入 test-only dealloc 日志。鸿蒙 .hvigor build.log 在 12:38:47 有 BUILD SUCCESSFUL，但没有设备运行证据。khfDY2 与当前 native m 的差异仅为 CJGUI_INTERNAL_TESTING dealloc 观察，不为该差异单独重跑正式导出；它不是逐字节同源码，需保留差异范围。

### 本轮发现与执行方案（优先处理，和 B 继续结合）

1. **A1 新验收本身覆盖用户剪贴板，尚未收口。** `verify_instance_isolation.sh` 在保存 before.plist 前直接写入 `USER-ORIGINAL-$RUN_TAG`，最终恢复的是它制造的 fixture，不是脚本启动前的真实用户值。先在第一次写入前建立独立的外层全类型快照及 EXIT/失败清理，内层 fixture 不能覆盖外层快照；中途非本轮复制仍按 change-count/内容条件保留。能用独立 pasteboard 的守卫单测优先独立，真实 Cmd-C/V 留给一条受保护的链。`verify_shared_document_transfer_chain.sh` 在 Cmd-C 后多次操作、等待后才 snapshot expected，可能把用户新复制当作测试值；必须确认预期 payload/类型与本轮写入再接管 expected，失配则保留用户值并停止依赖步骤。不要尝试凭测试值恢复已丢失的历史剪贴板。隔离验收的 `control_alive` 只验进程存活，报告不能写“仍响应公开读”；补一次对应 descriptor 的真实只读请求。对照实例也需统一 EXIT 清理、信号前核对本轮身份，启动失败留下的实例必须可回收。
2. **A2 还不是系统 tracking 公平性证明。** `/private/tmp/cjgui-composable-data-transfer-cross-window/20260919125828-67611/a2-timeline.log` 有 APPLIED 和驱动进程仍在，但该轮 probe 无 target-enter、drop 成功或其他实际 tracking 证据。驱动 alive 包含移动、睡眠和松手后等待；墙钟同秒也不等于即时。按原 A2 增加系统 source begin/target entered/up/end 的同轮单调时钟观察，在确已 entered 且未 up/end 的区间发送 UDS 请求，读回实际字段；等待驱动阶段信号，不用固定 sleep 猜。当前每步 post 已睡 30ms，循环又睡 20ms，60 步至少约 3 秒，脚本 `sleep 2` 的“移动已完成”注释不成立。未进入拖动时记录无效实验，不能把该次请求完成用于公平性结论。重复 hover 的 read/parse/build/layout 差值断言仍未补，继续按 A2 做，不重跑无关性能矩阵。
3. **A3 释放断言过弱。** 集成脚本只检查 dealloc 行数 >=1；14/16 个对象释放仍允许关键近上限对象一直泄漏。为被测关键声明对象加 test-only 单调观察 ID，记录创建/释放、阶段与所属 session，断言本轮受跟踪对象按预期阶段结清；观察器不可持强引用。payload 被 FIFO/owner/pasteboard 合法持有时单列，不能用 item 已释放推出所有 NSString/NSData 都释放。补一条故意保留被测对象的负对照验证断言真的会失败，再验证 drain/cancel/close 正常释放。实际分配峰值仍未测须保留，不能以改名规避原资源目标。
4. **B 的客户端/服务端协议现在不能完成所写闭环。** `state_server.cpp` 收到 STATE 回复后执行 `if (served && pending.empty()) break` 关闭连接；`Index.ets` 准备在同一连接接着发三次 OP。客户端还在 connect Promise 完成后才注册 connect 回调，首条 STATE 可能根本不发。优先统一为一个有界请求/响应一条连接的最小客户端，连接成功后直接发送，逐条等待与断言，再执行下一请求；或有理由时统一长连接，但不能两端各假设一套。按字节流累积到换行解析，不能假设一次 socket message 就是一条响应；配置连接/读写超时、帧长上限，传播错误，不吞 send 失败。先在 Mac 用可移植 owner/协议源做逻辑和 socket 定向验证，再等鸿蒙运行，不把 host 测试当鸿蒙权限证据。
5. **B 的身份、授权与外部性需修正。** STATE 输出 CARD 1/2，owner 实际只接受 0/1，EXT-SIM 使用 TOGGLE 2 必然 unknown_card；选一套稳定 ID 并在显示/协议/owner/测试统一。`human`/`ext1` 是公开硬编码常量且 HELLO 直接公布，不构成真实会话授权；人类输入走内部入口，网络入口不能接受 human 身份，外部使用每会话授权能力且不经未认证 HELLO 泄露。loopback 只限制网络范围，不能代替授权。EXT-SIM 是同应用客户端，只能验进程内网络路径；按 B4 另有独立客户端/独立普通应用的实际调用，明确不使用 hdc 特权/转发的验证条件。未运行前不得宣称普通应用通信可行。
6. **B 的生命周期不是已实现的代际拒绝。** `g_generation` 只增加和打印，实际校验仍是 window 指针转整数，不能抵御指针复用；surface 创建还无条件 MOVE 两卡，重建会覆盖已有业务位置。资源重建应从既有 owner 快照重绘，初次布局与后续恢复分开；用真实注册生命周期上下文携带单调 generation，排队任务保存 generation，执行时检查 active，不假定裸系统指针能辨别所有迟到回调。若系统回调无历史 generation，明确依赖其序列化契约及注销/清理保证，不伪造检查。`CardsRenderer::surfaceDestroyed` 在销毁 context 后才 glDeleteProgram/glDeleteBuffers，调整为在正确 current context 内释放 GL 对象再释放 EGL，初始化任一步失败均清理已获资源。
7. **B 的服务停止路径也未接通。** `StateServer::stop` 没有调用点，且仅关闭 listenFd 后 join，已 accept 的连接若阻塞 recv 可永久不退出；listenFd 在两个线程间无同步。让 owner/服务寿命明确归属应用生命周期，surface 重建不重新开重复监听；停止能唤醒监听和活动连接，线程有界退出，失败也归还 fd/清运行标志。最小方案可用 poll/超时 + 受控 fd 所有权，避免跨线程 close/fd 重用竞态。先用空闲连接、半帧、超长帧、关闭/重启和端口占用做 host 定向验证。此处及上一项属结构/生命周期风险，应合成一个小问题包咨询 Terra CLI 后实施，不需指导逐补丁再审。

**环境核实范围：** 本次只读 `devecocli emulator list` 显示四个实例 stopped，hdc 为空；旧 pc 镜像 info.json/sdk-pkg.json 仍在，版本元数据为 API24/6.1.0.117。磁盘当次仅约19Gi可用。尚未验证镜像完整性或注册失效的根因，不把“文件存在”称完好，也不预先认定必须重下8.9GB。先有界核对管理器路径/注册/CLI版本与 GUI 可见性、保留准确启动错误；能合法复用旧镜像则复用。需要账号/许可的用户步骤给具体页面与原因，不循环申请。目标仓颉 SDK 仍需现场核实安装情况，普通 HAP 构建不是替代；这些环境项不阻塞上列已有代码修正与 host 定向验证。

交付仍采用本文件 A+B 整阶段范围：修正上述真实缺陷、完成能够独立运行的 host 验证与实验客户端/运行说明，再补可用的模拟器证据；SDK/设备确不可用时保留分层阻塞，不称“所有独立工作完成”。不恢复旧 Codex 定时，不新开治理台账或把该报告另算一个阶段。

## 交付目标与执行方式

交付两项相互独立、可以交错推进的成果：把 macOS 数据交换的剩余可靠性问题收好；在 Mac 上开发一个实际运行于鸿蒙模拟器的薄自绘原型，验证仓颉、输入、绘图、共享状态与外部操作的通道。不是全面移植 CJGUI，也不是再做一个只有按钮的 ArkUI 示例。

外部执行 AI 是主要实施者；指导 AI 给方向、取舍与本任务中的诊断方案。必要时按[执行提示词](2026-09-19-external-executor-handoff-prompt.md)调用 Codex CLI 的 Terra/xhigh 做聚焦只读咨询。内部可以分步、串行验证，但对外交付整个阶段，不逐函数、脚本或小实验停工。先完成可能误操作用户实例的脚本隔离；随后旧项与新能力穿插推进，不等待全部旧项清零。不能仅写两份评估报告结束。

沿用仓颉、macOS 首个平台、自绘/GPU、窄平台桥接、人和外部智能系统操作同一真实内容的定位。鸿蒙仅做实验通道和必要最小接缝；不绑定 Agent、聊天窗或 S-expression，不自研输入法，不大规模拆全仓、不更换 macOS 渲染路线。

## 最小上下文与资产复用

先读 AGENTS、ACTIVE 当前任务、本文件与执行提示词。按需要读取下列入口，不通读历史 plans：

- [数据交换阶段最新指导复核](2026-09-17-data-transfer-milestone.md#2026-09-19-指导复核功能分项接受整阶段待补证)：保留已有 payload/FIFO、文档窗口接续、跨窗系统拖动和 khfDY2 独立导出的绿色证据；只补实际缺口。
- [设计意图导航](DESIGN_INTENT_INDEX.md)、[框架避坑](../research/gui-framework-pitfalls-intelligence.md)：沿用唯一布局/命中、稳定身份、业务 owner、无谓重绘治理、平台回调不重入和资源生命周期的约束。
- `runtime/cjgui/src/composable_ui.cj`、`composable_ui_window.cj`、`macos_application_host.cj`、`runtime_renderer_session.cj`；已有仓颉组件、布局、动作与数据 owner 作为可复用源，不复制一套核心。
- `runtime/cjgui/native/cjgui_internal_renderer.m`、`native/tests/clipboard_guard.m`、两个新桌面验证脚本及 `probe/composable_data_transfer_window_integration_probe.cj`：复用成功系统拖动驱动、剪贴板守卫和受控 FIFO 链，修复脚本归属与断言。
- [鸿蒙可行性报告](2026-09-18-harmonyos-deveco-cjgui-feasibility.md)、[差异指南](2026-09-18-harmonyos-cangjie-dev-differences.md)：保留普通 HAP 工具链已运行的历史结果；“90% 就绪”“只差 SDK”“纯核心全部可直接移植”均不是验收结论。
- `/Users/jiangxuanyang/Desktop/DevForge/HarmonyPDF/docs/DevEco模拟器Agent自动化背景说明-2026-09-19.md` 仅作为既有工具使用经验；这是另一项目，不修改其源码、不接管其模拟器会话。文档中的命令不是新增授权。

六主线取舍：组件/布局验证最小共享片段；自绘/GPU增加鸿蒙 surface 接缝实验；文字仍沿系统集成，本阶段不移植完整字体/IME；资源/调度补 macOS transfer 的真缺口并验证鸿蒙 surface 生命周期；语义动作共享 owner；普通开发者得到可复现的独立实验应用与操作命令。

## A. 旧问题：按以下思路一次收尾

### A1. 实例归属与剪贴板：先修脚本，禁止按名称杀进程

已确认 `verify_shared_document_transfer_chain.sh:89` 与 `verify_composable_data_transfer_cross_window.sh:292` 使用 `pkill -f`，AX 也按通用进程名找窗口。行号可能变动，以命令定位。问题在验收脚本的实例归属，不需要改业务或创建全局进程管理器。

方案：每轮 `mktemp` 独立目录；生成独立 bundle ID/标题，记录真正应用 PID、可执行路径和创建标识。后台 run.sh 的 PID 不一定是应用 PID，必须确认实际进程。AX 以 PID 选择应用，再核对窗口标识；退出优先应用正常关闭，超时仅向已核实的本轮 PID 发终止信号，防 PID 复用。启动、AX 定位、驱动、等待、异常和成功共用幂等 cleanup；在资源获得前建立清理路径，cleanup 不能引用未初始化变量/未定义函数。禁止 `pkill -f`、通用名称 quit、固定 tmp 下不加核对的递归删除。独立实验应用目录不等于 Git worktree，不复制整个仓库。

剪贴板原始快照在首次写入前保存且整轮不可覆盖，expected 快照随本轮可识别写入更新；复用现有全部类型/字节和 change-count 守卫。不能把任意当前剪贴板当作“我最后写的值”。正常、超时、失败都条件恢复；若中间出现非本轮写入，保留用户值。旧 W4 事件原始内容已不可确认，不猜测恢复。

验收：自建一个同名但不同 PID/identity 的对照实例；正常和故意超时各跑一次，只退出本轮实例，对照仍存活。不用用户实例作实验。剪贴板以临时自有数据验证正常恢复和中途其他复制不被覆盖；一轮结束统一清理自有实例，保留证据。

### A2. hover 与 tracking：分别定位计算浪费和调度阻塞

`hoverPure` 目前只检查无业务接受/hover 清理；`otherWindowProgressed` 在 transfer 完成后手动 pump，不能证明拖动期间公平性。先补可区分的实验，再决定是否改生产。

- hover：同一目标的首次进入允许一次状态变化/必要绘制；将稳定重复 hover 单独计量，比较前后 payload read/parse、build/layout/submit 的差值，重复移动不得逐像素读取/解析 payload 或重建布局。leave 可有一次必要反馈。记录真实计时边界和样本，不把测试统计 UTF-8 临时分配算成纯生产成本，也不要求合法首次绘制为零。
- tracking：复用已成功 CGEvent source→target 路径，进入目标后按住约 2–3 秒再释放；用统一单调时钟标记 begin/entered/request-arrived/owner-applied/reply/up/drop。独立客户端在按住期间向另一窗口发一次真实授权操作，读回改变的字段；观察 hover 反馈和另一窗口进展。用请求/owner 日志判断期间完成还是松手后补做，不能仅以版本未降低或最终存活判通过。
- 若期间没有推进：先区分请求未抵达、连接处理未调度、owner 未调度、只缺刷新/呈现。沿已有 application/runloop 调度追踪模式和调用栈；异步业务不得在 `draggingUpdated/performDragOperation` 里递归调用 owner/pump。确定是嵌套 tracking 阻塞唯一 pump 时，带最小证据咨询 Terra，优先复用现有调度入口与有界非重入机制，不能临时再建一套事件循环。相关结构问题未解时只停该修复，继续鸿蒙独立实验。

验收须分别给 hover 工作量、tracking 内业务完成、释放后恢复；屏幕工具确实不可用时如实保留视觉反馈未验，不能用业务日志冒充呈现。

### A3. payload 生命周期：逻辑大小、对象存活和实际内存分开

现有 source/accepted/candidate/FIFO 字节是 NSString 的 UTF-8 逻辑大小，各项可指向共享对象，不能相加当总内存。session 数归零不能排除其他对象仍持有 payload。关闭前保留当前合法声明是正确行为，不要求活窗口所有字节归零。

先画本次实际持有链：offer/候选→accepted declaration→drag/pasteboard→FIFO→owner；标出引用而非复制。复用 test-only 统计，优先增加少量关键对象的弱引用/dealloc 观察或等价窄生命周期探针；观察不能反过来强引用被测对象。在候选被拒绝、合法源替换、cancel/drain、关闭两窗和 autorelease 池释放后检查对应对象的存活边界。仍被业务文档/系统剪贴板合法持有的数据单列，不要求它们一同消失。

以 128B/4KiB/512KiB 和有界重复轮次观察峰值/结束后收敛。若测进程分配/RSS，写清分配器缓存及仓颉 GC 的影响，不要求 RSS 每轮精确回到起点，也不通过无限等待 GC 把问题藏掉。逻辑字节与实际分配分列；若无法测实际峰值，保留该欠项并用对象存活证据限定结论，不能改名宣布全绿。不要为测量增加生产缓存或公共接口。

### A4. 失效与 FIFO：按生产契约构造场景，不机械要求全部拒绝

保留 run-16 的绿色。512KiB 文档总量、单项 payload 上限和 64KiB READ_RANGE 是不同边界；读取大结果按 UTF-8 合法边界分段。`pump` 有意先消费同一已显示快照的 FIFO 再发布场景，因此同批双事件不应被“每条刷新一次”人为变成过期。队列压力的同内容替换可接受但不增加版本，不等于 21 次不同内容写入。

补三类明确失效：①目标所在 scope 已被模态层遮蔽；②hover 后、drop 前目标删除/换绑/关闭；③旧事件已入队，但在下一次合法消费前其身份/已接受 generation 确实被独立更新。读取实际实现确定更新时间，不能伪造版本或把未接受候选当有效更新。断言旧目标不被修改、拒绝有解释、无半条数据、队列/hover 恢复；取消不得删除源。close 后使用有效系统派发或安全的失效 token 路径，不解引用已释放原生对象。

补规则窗口归因的原始公开读回路径。外部 TextEdit 拖入失败已记录；若没有新证据/新驱动方法，不继续重复调坐标，该项可明确环境未验。仅生产或消费者有新改动才更新受影响测试/最终导出，不重复全仓矩阵。

## B. 新能力：鸿蒙自绘与人机共同操作薄通道

### B1. 环境确认只做一次，开发在 Mac，运行在模拟器

先现场确认 DevEco、目标 SDK/仓颉目标库、模拟器 API/ABI、hdc 目标、编译/打包工具实际版本和当前可用权限。普通 macOS 仓颉 SDK 不等于鸿蒙 SDK；识别 `aarch64-linux-ohos` 不等于能链接运行。沿官方安装路径核对合法可用目标 SDK，局部环境变量不改全局工具链；需要账户登录/计划申请等用户操作则给精确缺项并继续独立工作，不绕过受控 SDK 访问。不要在 macOS cjpm target 中混入鸿蒙产物。

现有普通 HAP 构建/安装历史可复用，必要时做一次最小冒烟确认，不能反复重做 Hello World。模拟器是共享设备，先确认当前占用；不停止 HarmonyPDF 或其他用户应用，不擅自重启共享模拟器。可用独立已配置实例或独立应用身份；前台竞争时先做构建/源码工作。手机、2in1、真机能力分别记录，不拿模拟器性能代表真机。

### B2. 真正运行仓颉和复用最小核心

建议实验目录 `labs/ohos_gui_smoke`，存在则先查内容与归属。鸿蒙壳、桥、验证驱动在实验目录；必要的通用最小抽取留在原核心、让 macOS 仍消费同一份源码。先验证一个仓颉函数真实编译、打包进 HAP、运行并返回可变结果，给源码/库/包指纹和应用日志，不能用 ArkTS/C++ 重写结果冒充仓颉运行。

然后按实际依赖选最窄的现有纯仓颉布局/状态/动作片段接入；用依赖闭包的编译→链接→运行确认复用程度，不按 darwin 字符串占比估计。若现有包强绑 AppKit/Metal，明确阻塞符号和最小提取方案；必要时咨询 Terra 后抽取一个确实复用的纯值模块，禁止全仓拆包或复制第二套核心。当前文字测量/输入有 CoreText/AppKit 依赖，不能默认文本已经跨平台。

### B3. 一个可交互的自绘原型，按真实 SDK 选择窄桥

候选：薄应用壳提供 XComponent surface/NativeWindow，仓颉负责对象状态、布局和动作，平台桥负责输入及图形提交。优先检查当前 SDK 支持的 EGL/OpenGLES 接入；这是候选，不锁死后端。ArkTS 壳可以负责装载与生命周期，不能接管仓颉应有的业务状态。

场景固定为两张有稳定 ID 的自绘卡片/矩形。人点击选中并移动或切换其中一张的状态；仓颉生成布局和绘制数据，画面位置/颜色随实际字段变化。至少复用一个 CJGUI 既有核心片段并说明调用路径；仅 C++ 清屏、ArkUI 原生按钮或静态截图均不算 CJGUI 通道通过。文字/图标可沿平台最小能力显示，但不扩张为完整字体排版、IME、编辑器或主题系统。

验证 surface 创建→一次输入/重绘→尺寸变化→后台/前台或销毁重建→再次操作。关闭后的晚回调须由生命周期标识拒绝，不持有悬空窗口/GPU 句柄；实验创建失败能有界清理。尺寸/缩放转换用同一布局结果，native 不重写命中规则。空闲不持续无条件重建布局或提交新场景。输出 CPU 工作量/提交次数和实际显示证据，GPU完成与实际呈现不混称，不比较 macOS 或 GPUI 的性能数字。

### B4. 外部操作同一状态，分清调试渠道与普通应用能力

先用现有值契约/业务动作表达对象 ID、字段、参数、结果和版本；人和外部调用进入同一仓颉 owner。协议编码可替换，不能为了鸿蒙新建 Agent runtime。

验证一条完整链：人选卡片 A 并改变位置/状态→独立客户端读取精确字段→客户端在明确授权范围内改 A 或 B→画面相应变化→人继续修改→客户端读回最终字段。加一个 stale 版本和未授权请求，证明不写入。只比较计数器、把客户端数据镜像到另一状态、后台改文件等不算完成。

hdc shell/端口转发可用于开发调试，但必须另行验证通信能否作为普通沙盒应用的功能成立。选当前系统支持的最窄通信方式，明确端点发现、会话授权、权限声明和断线行为；默认最小暴露面和短期本机会话，不建公开无认证服务。至少有一次实际请求走不依赖 hdc 特权/转发的路径；若受网络/权限限制无法完成，保留调试通过与普通应用未验两个结论，不宣称可交付用户。应用可配置连接地址，不强制自动发现服务或云账号。

自绘内容不会自动出现在系统控件树。检查原型 surface 与卡片的可见语义，验证当前 SDK 的一个最小 accessibility provider 节点或实际支持限制，复用对象 ID/边界，避免额外业务状态。业务数据接口与系统无障碍投影分开，不把 dumpLayout→坐标点击称为直接业务操作，也不把节点可读称为 VoiceOver/鸿蒙屏幕朗读完整验收。

### B5. SDK 被阻塞时仍须交付实际新代码，不能伪装通道完成

若目标仓颉 SDK 确不可用：继续在实验目录完成普通 HAP 的 native surface、自绘输入/生命周期和普通权限通信实验，运行后明确标记“平台桥预验证，尚未运行 CJGUI 仓颉核心”。同时给所选 CJGUI 最小依赖闭包、编译失败原文、接回仓颉的单一接缝及可复现命令。不要把临时 C++/ArkTS owner 提升为生产核心；SDK 到位后替换该实验占位，而不是保留双 owner。

完成其余独立工作后才汇总外部阻塞；缺 SDK 时本阶段状态应为“旧项已验范围 + 鸿蒙平台预验证 + 仓颉通道阻塞”，不能标为全部完成。没有新条件不反复尝试下载/登录/重编同一失败。

## 统一验收与报告

- macOS：A1–A4 分项证据；原有绿色不重做。core/native/公共接口有改变时按 AGENTS 做相关测试、构建和影响检查；仅验证脚本改变只验脚本及对应行为。保留最终可读日志、source/binary 指纹，导出只在相关产物变化后刷新。
- 鸿蒙：源码、编译/链接、HAP 运行、核心实际复用、自绘交互、共享 owner 外部接续、surface 生命周期、普通权限通信、最小语义桥分别标状态；失败原文和未验条件必填。模拟器结果不称真机/发布证明。
- 最终交付：实验代码与运行入口；旧问题修正；对应原始证据；在本阶段页更新结果和下一步取舍。ACTIVE 仅留一个当前阶段、已接受项、剩余项及执行主体。不要再创建执行卡/每日台账。
- 同一构建 target 串行，单一主写入者；不新建 Git worktree、不切分支、不 stage/commit/push/发布。不修改安全设置、用户账号或不明实例，不提交上游 issue；发现 SDK/长期 workaround 时沿设计导航记入既有问题账本。
- 两条线都完成或所有独立工作做完仅剩明确外部阻塞时，才交付一次阶段报告。遇到公共契约、核心并发/FFI/GPU 生命周期等结构问题按提示词咨询 Terra，不自己反复猜测，也不因此停掉整阶段。

## 执行记录（2026-09-19，外部执行 AI）

### A1 实例归属与剪贴板 —— 完成并验收

- `verify_shared_document_transfer_chain.sh` 与 `verify_composable_data_transfer_cross_window.sh` 重构：
  每轮独立输出目录 + 复制示例应用为独立 bundle（名称/标识符含轮次标签）、记录真实应用 PID
  （按唯一目录 pgrep + `ps -o comm=` 对可执行名复核，落盘 `app.pid`）、AX 一律按
  `unix id is <pid>` 寻址、清理为 AXCloseButton 优雅关闭→复核后 TERM→复核后 KILL 的幂等路径，
  全程无 `pkill -f`。链脚本新增 `CHAIN_SKIP_GRACEFUL=1` 测试钩子以复现优雅关闭超时路径。
- 新增 `verify_instance_isolation.sh` 验收：剪贴板守卫语义（中途外部复制不被恢复覆盖 ✓、
  条件恢复返回原值 ✓）；对照实例在正常链与超时链两次运行中均存活且仍响应 ✓。
  修复过程中发现并修复 step5 应用侧 Cmd-C 写剪贴板未刷新 expected 快照导致用户剪贴板残留
  测试值的问题（快照后 `clipboard_final=USER-ORIGINAL-*` ✓）。
  证据：`/private/tmp/cjgui-a1-acceptance3.log`（PASSED all checks）。

### A4 失效场景 —— 场景②完成

- 探针新增 A4-2：hover→目标换绑+刷新→旧节点 drop：drop 在原生目标边界被拒（状态 15）、
  owner 零改动、内容不变（`CJGUI_TRANSFER_A4_HOVER_REBIND ... passed=true`，
  `/private/tmp/cjgui-controlled-window-payload-run-17.log`，整体 EXIT=0）。场景①（scope 遮蔽）
  与③（入队后身份独立更新）待后续轮。

### B1 鸿蒙环境确认 —— 完成（发现阻塞）

- ohos 仓颉目标库缺失：`cjc --target aarch64-linux-ohos` 报
  `target library path is not exist: .../modules/linux_ohos_aarch64_cjnative`；DevEco SDK 内无
  任何 Cangjie SDK（开发者权限下载项未安装）。
- 模拟器：`devecocli emulator list` 显示 Mate X7 / MateBook Pro / MatePad Pro 均为 stopped，
  启动报 "system image HarmonyOS 6.1.1(24) Beta1 cannot be found"——8.9GB 的
  `~/Library/Huawei/Sdk/system-image/HarmonyOS-6.1.1-B1`（system.img/ramdisk/info.json 完整，
  apiVersion 24）仍在但管理器不识别（DevEco 升级后注册失效）。DevEco Studio 已启动仍复现。
  可下载镜像均为 7.0.0(26.0.0) 系（与 API 26 SDK 配对），本机磁盘仅余 21Gi。
  **需要用户动作**：DevEco Studio → Device Manager 修复/重下镜像，或授权下载 7.0.0 镜像并接受许可。
- hdc 位于 `DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc`。

### B5 平台预验证（SDK 阻塞下按约交付真实代码）

- `labs/ohos_gui_smoke`：完整可构建的 HAP 工程——ArkTS 壳（XComponent surface + EXT-SIM 按钮）+
  原生 C++（`cards_owner` 单一业务 owner：SELECT/MOVE/TOGGLE + 版本 CAS + 双 token 鉴权、
  `cards_render` EGL/GLES3 双卡片自绘、`state_server` 127.0.0.1:7856 行协议服务器、
  `xcomp_bridge` 生命周期代际拒绝晚回调）。`devecocli build` BUILD SUCCESSFUL（含原生编译）。
  明确标注：**平台桥预验证，尚未运行 CJGUI 仓颉核心**；仓颉接回的单缝为
  owner/渲染接口层（当前 C++ owner 即实验占位，SDK 到位后由仓颉模块替换）。
- 运行证据待模拟器镜像修复后补（安装/驱动/hilog/截图）。

### 导出刷新豁免（2026-09-19 晚）

khfDY2 之后仅测试面变化（probe、验证脚本、TESTING 门控的 dealloc 日志、labs 实验），
生产源码与导出消费者未变——按"仅相关产物变化后刷新"规则，正式导出不重跑。

### A3 payload 生命周期 —— 观察机制 + 负对照 + 遗留发现（打开）

- 判定器在探针进程内收敛点执行（显式 drain + 集合判定），不依赖退出日志。
- 可复现发现（run-normal9，2026-09-19 14:53）：22 个已填充项中 **6 个（id 15,16,17,18,20,22）
  在全部窗口 close、occupied session 归零、判定边界之后仍未释放**——它们是各窗口最后一代
  accepted 声明。引用链定位（ctx 对象是否被 Cangjie 侧仍存活的 window 对象/注册表持有，
  还是 autorelease 无池累积）为下一轮工作；在此之前不能宣称该类对象无泄漏。
- 判定器与负对照已验证可用：泄漏注入被精确检出（leak 模式 created=22 released=0 →
  "negative control ok: leak detected"）。

### A3 payload 生命周期 —— 观察机制 + 负对照 + host 定向验证完成

- 观察点移至**首次填充**（占位对象不计入）：`markObservationFilled` 记录 create（id/role/node/version）、
  dealloc 记录 release；泄漏钩子仅在 `CJGUI_TRANSFER_LEAK_TEST=1` 时保留首个被跟踪对象。
- 脚本断言：正常模式输出生命周期证据（created=22 released=16——活窗口合法持有已接受声明，
  其余在运行期释放）；负对照模式注入泄漏被正确检出
  （created=22 released=0 → "negative control ok: leak detected"）。
- 按裁决实现 host 定向验证（`labs/ohos_gui_smoke/host_tests/test_cards_logic.cpp`，Mac 上
  clang++ 直接编译运行，**ALL PASSED**）：owner 单元（stale/unknown_card/unauthorized/1-based/
  初始布局仅一次）、能力会话（per-session capability、错误 token/`human` 走网络入口均拒绝）、
  半帧（不完整帧零响应，补全后恰一响应）、超长帧（服务端存活且新客户端可服务）、
  断连/重启/端口复用、stop 有界。

### A3 payload 生命周期 —— 对象存活观察已接入

- `CJGuiInternalComposableDataTransferItem` 增加 test-only dealloc 观察
  （仅 CJGUI_INTERNAL_TESTING 生效、不持引用，输出 role/node/version）；
  集成脚本在探针退出后统计释放事件并作为通过条件之一
  （run-20：`dealloc observations: 14`，探针 `passed=true`，
  `/private/tmp/cjgui-controlled-window-payload-run-20.log`）。
- 边界如实保留：现有字节计数为 NSString UTF-8 逻辑大小，进程 RSS/分配器缓存未测；
  结论限定为"逻辑字节收敛 + 对象释放事件可见"，不宣称实际内存峰值已测。

### A2 拖动保持期公平性 —— 单调时钟 + entered 门控版本（最终）

- 复核修正已落实：请求仅在 `transfer target entered` 出现后发送（轮询日志门控，不再固定 sleep）；
  时间线全部使用单调时钟（cgdrag 输出 HOLD_START/UP 的 `DispatchTime.uptimeNanoseconds`，
  驱动用 `time.monotonic_ns()`），同一时钟可直接比较。
- 实测（run 20260919141135-80860，status=0）：entered_seen=…418023333 → request=…443304916
  （+252ms）→ reply=…541071333（+978ms，APPLIED true v0→v1）→ up=…841611458（+7.4s）。
  **外部授权操作在 entered 之后、释放之前 6.3 秒完成**；同轮 drop 落地
  （`CJGUI_CROSS_DRAG_RESULT drops=1 payload=DRAG9 passed=true`）。
  公平性成立：拖动跟踪未阻塞 UDS/owner 调度；视觉 hover 反馈仍无录屏权限未验。

- 实验载体：跨窗 bundle 应用（源窗 UDS 连接 + 目标窗拖动目标）。CGEvent 拖动
  （down→60 步移动→在目标内按住 3 秒→up），按住期间独立授权客户端经公开 UDS 对
  **源窗口** 工作区执行 REPLACE_RANGE（expected v0，无竞争版本）。
- 时间线（`a2-timeline.log`）：`t0=…935 request=…938 reply=…938 up=…944
  ext_exit=0 drag_alive_at_reply=1`——**外部授权操作在拖动保持期间即时完成**
  （APPLIED true，v0→v1），拖动仍在保持、6 秒后才释放；不是松手后补做。
  跨窗拖动的应用内 UDS/owner 调度未被打断；拖动本身该次未落目标
  （RESULT 未打印，drops=0——拖动投递存在波动，同路径在上一轮两次成功，
  波动来源待后续轮用 trace 定位）。视觉 hover 反馈未验（无录屏权限）。

### A4 场景③ —— 完成

- 干净文档上两个有效 drop 入队后、未被任何 pump 消费前，目标禁用 + refresh
  （接受代际真实推进）：pump 消费后两事件均被拒绝（rejected=2、owner 零改动）、
  FIFO 收敛、内容不变。生产契约"旧事件对失效代际 fail-closed"成立
  （`CJGUI_TRANSFER_A4_STALE_QUEUE ... passed=true`，run-21，整体 EXIT=0）。
  场景①完成：探针控制器新增模态层（cjguiComposableDialogLayerWithReference，isModal），
  遮蔽期不声明目标——drop 在目标边界被拒（15）、owner 零改动；关闭模态后同一目标重新武装、
  drop 应用（CJGUI_TRANSFER_A4_MODAL passed=true，run-22，整体 EXIT=0）。
  **A4 三个失效场景全部完成。**

## Terra 咨询记录与验证（2026-09-19）

- 咨询包：`/private/tmp/cjgui-terra-review-bchannel/request.md`（surface 生命周期晚回调、EGL 清理顺序、
  重建状态保持、服务线程停止、协议/编号/授权、host 验证清单六题）；裁决
  `/private/tmp/cjgui-terra-review-bchannel/answer.md`（109 行，xhigh）。
- 已按裁决实施并验证：① SurfaceLease（互斥 {generation,window,active}）+ 静态存储回调结构
  （修复栈上 callback 指针缺陷）；② EGL 顺序改为"context current 时删 GL → 解绑 → destroy
  surface/context"，display 模块级单次 init/terminate，逐步回滚；③ ensureInitialLayout 与
  surface 恢复分离（重建不再 MOVE 复位、不再伪造 HumanTouch、不再推版本）；④ 服务线程 poll(100ms)
  + 非阻塞 fd + 线程内 close 归属 + stopFlag 有界退出，start 失败回滚并可报告；⑤ 卡片 ID 全链
  1-based 统一；⑥ 每会话 capability（urandom 128bit，握手颁发、不进 HELLO/日志、断连失效），
  网络入口 ExternalSession、触摸入口 HumanTouch，客户端不能自报身份。
- 裁决建议的 host 验证清单已落地为 `host_tests/test_cards_logic.cpp` 并 **ALL PASSED**
  （owner 单元/能力会话/半帧/超长帧/断连重启/端口复用/stop 有界）；清单中的真机项
  （surface 重建保持、EGL 回收循环）标注为模拟器/真机待验。

## 后续树阶段记录归属

树形视图轮的两段执行报告已原样迁至[树阶段执行记录](2026-09-19-macos-tree-selection-milestone.md#执行者历史报告与第四轮复核)，由该阶段维护；本页保留数据交换/鸿蒙记录。第四轮指导复核发现旧 A1 未闭合、当前 A3 判定器与历史负对照证据不一致，结论以该复核为准，下面的历史报告不能作为当前源码通过证明。

### A1/A3 判定器（Terra 裁决落地）

- 观察器移至首次填充（占位不计数）；进程内判定器（显式 drain + 集合运算，不依赖退出日志）；
  泄漏钩子严格 `<N>` 语法；负对照注入被精确检出（leak 模式 created=22 released=0 →
  "negative control ok: leak detected"，leak3）。
- **遗留发现（打开）**：正常收敛点 22 个已填充项中 6 个（id 15-18/20/22，各窗口最后一代 accepted
  声明）仍未释放——引用链定位（ctx vs window 对象持有 vs autorelease 无池）为下一轮工作。

## 官方资料入口

当前 API 签名/兼容范围以实际 SDK 头文件、官方版本文档及编译运行结果确认。以下仅支撑候选方向，不证明本机已就绪：

- [DevEco Studio 的 macOS 支持](https://developer.huawei.com/consumer/cn/deveco-studio/)。
- [XComponent、NativeWindow 与 EGL/OpenGLES 自定义渲染](https://developer.huawei.com/consumer/cn/doc/doccenter-games/games-universal-napi-xcomponent-0000002299097400)。
- [XComponent 渲染原理与排障](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-xcomponent-render-problem-guide)。
- [仓颉鸿蒙开发入口](https://developer.huawei.com/consumer/cn/cangjie)。语言技能检索未覆盖鸿蒙 SDK 接入细节时，不用普通 C FFI 示例推断平台专用接入形态。
