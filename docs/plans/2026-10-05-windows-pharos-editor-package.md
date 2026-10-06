# Windows Pharos 编辑器整包接续（2026-10-05）

**框架与产品责任校准（2026-10-06）。** 本包同时负责CJGUI Windows后端和现有Pharos消费，不是只把编辑器在来宾中跑起来。窗口/消息泵/线程/输入来源/安装交接/排版命中/GPU与文件平台语义归框架后端；平台无关的选择、owner、布局及资源契约优先复用CJGUI公共核心，发现公共缺口应沿真实责任层修复。产品只留文档与Markdown语义和声明式接线，不能复制公共机制或用慢打、重投绕过框架缺陷。保护E/H写集是禁止覆盖并行工作，不是禁止本包必要的公共框架修改；先核现有契约与diff，按最小影响实施并验证相关调用兼容。按原整包连续完成，不以单个探针或构建修复结束；报告分别列框架机制、平台适配、产品接线及正常消费依据。本条仅澄清原范围，不恢复已暂停线程。

本包由用户交给 Windows 执行模型启动。2026-10-06 用户再次暂停长上下文执行线程，准备换工具接续；目标与 A–F 固定验收门不变。最新接续以本页「冻结隔离、完整 UI 归属与输入交接」为准，较早源码复核及执行记录保留为历史，不能将其中已修事项或旧咨询要求重新执行。指导本次只复核源码、已有运行原件与控制通道边界并更新本任务，不代替执行者开发，不恢复旧线程或启动虚拟机。

**交付目标：让现有 Pharos Mark 在 Windows 上完成正常写作链：打开文档 → 源码编辑 → Markdown 预览 → 回到原选区继续编辑 → 公开 Agent 修改 → 人继续输入 → 撤销／重做 → 保存 → 关闭重开。** 使用现有编辑器检验 Windows 后端；设置、thermo 或另写一个玩具编辑器不作为前置交付。

这是一包连续实施任务，包含必要旧问题、Windows 后端和产品消费。内部按依赖安排工作，最后集中报告；不要每完成一个探针就停止询问是否继续。不能把“编译出窗口／画出文字”改称整包完成，也不承诺一个夜间就达到 macOS 全部能力。

<a id="windows-dispatch-input-package-20261006"></a>
## 2026-10-06 接续方案：冻结隔离、完整 UI 归属与输入交接（当前执行依据）

**决定：采用隔离后的 A，不等待 E/H 整仓合龙；先完成下述两项框架机制，再直接闭合原整包。** 目录遗失需在来宾核实，但不是架构阻塞。并行源码量大也不等于不能构建一个冻结副本。用户恢复执行后，重上架、隔离构建和本包必要框架修复均在原授权内，不再为它们逐项请示。此文档更新本身不恢复暂停线程。

### 本次复核事实与可复用资产

- 指导核了正典 native、共享消费、runner、[本轮索引](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/INDEX.md)及[Astra 答复](../../artifacts/windows-pharos-20261005/consultations/input-handoff-thread-affinity/answer.md)，未运行 VM 或重跑设备链。保留删 restamp、真实来源 claim、UTF-8 终止修复、能力拆分和已有 owner 决策/ACK 重试；这些确有接线。不能把它们改称完整输入交接已经完成。
- 本地 [源码 ZIP](../../artifacts/windows-pharos-20261005/guest-transfer/pharos-windows-source.zip) 实算 `a3343b67…`，118 个源码条目及生成清单一致；本次核查时它们也与当前正典逐项一致，含 `main.cj=8cb1f174…`、renderer `27f819bc…`。可先冻结此 ZIP 恢复构建基线。它不自动包含本节后续修复，最终需另冻新包并建立差分来源。
- 已有专用线程创建 HWND/D3D，但其余导出 API 仍直接在调用线程执行，`require_session` 仅查非空。所谓创建/懒 Attach/Detach 是 **Win32 `AttachThreadInput`**；不是运行时线程 attach，也没有实现 Astra 的命令封送。消息环目前仅存 message/wParam/lParam，IME 内容、修饰键在晚到的消费时才读，来源冻结仍不完整。
- 安装门内字符、导航和组合开始仍有直接返回路径；native 安装成功即清门，早于共享 owner 确认。满 32 个 range claim 会释放第 33 笔载荷；事件入队失败还可能让前驱序号先行推进。这些是当前源码可定位缺口，尚非本轮新增设备丢字证明。
- `pread` 的串行位置恢复 RED/GREEN 接受；它仍由 seek/read/restore 三步组成，不能由此推出共享 fd 并发语义成立。旧 `not_main_thread` 已有首次失配原件，不能再写成只有 M:N 猜测；但新 dispatcher 是否解决，仍要在最终正常包验收。

### 1．构建隔离：恢复已有产物路径，避免反复编译和踩现场

使用既有 Parallels Windows VM 与常驻 worker。核 UUID、SDK 实际版本及 worker 身份；不重装 SDK，不循环 `prlctl exec` 开新终端。沿用第六节的直接 EXE 退出码与中文/空格路径门。

1. 保留现有 ZIP、四代 relay 原件及日志；新建 `C:\cjgui-windows-w1\runs\<run-id>\source`、`relay`、`accept`。源码、target、日志和结果均按 run 隔离。现有 `stage_pharos_windows.py` 会删固定 staging/覆盖 ZIP，先参数化输出目录；不在旧现场原样执行。解包后逐项核 manifest，不能只看顶层哈希或复制成功。
2. 框架修复先落正典 W 责任层；把本轮明确的修复及其必要共享依赖同步到隔离快照，保留前后清单。共享文件按函数核差分，不能覆盖 E/H 整文件。若公共 API 已并行变更，就冻结相互匹配的依赖集并编译验证；不把等待整仓结束当默认方案。最终产物只来自冻结目录，不边构建边读取变化的 live 树。
3. relay 复用键包含实际 BC 内容哈希、工具链/llc 身份、目标 ABI 与全部影响代码生成的参数，输出路径等非语义差异应明确归一。匹配已归档关系才可复用 obj；不匹配只为该新 BC 重生成一次。不得拿旧 EXE、旧捕获日志充当本轮结果。先完成 native 快速反例与必要 FFI 设计，再做昂贵的应用 BC 构建；不是每改一个 native 分支就重跑 25 分钟 llc。
4. 不重复已失败的 PATH/CANGJIE_HOME/junction/bin-copy 重定向实验，见[原记录 §3](../../artifacts/windows-pharos-20261005/evidence/20261006-rework/RED-GREEN-20261006.md)。本包可沿用已建立的受控 SDK 临时交换，补齐安全边界：同 SDK 独占构建锁；原版 llc 与 llc-real 双哈希准入；**交换及交换后校验都进入恢复保护**；正常/失败/取消均恢复并核原版哈希。现脚本交换在 try/finally 前，须修。worker 取消不得把唯一恢复责任方一并杀掉；保留可验活的外层恢复责任。wrapper 与 PS 的硬编码路径一起改为本轮目录。

### 2．框架方案一：完整原生 UI dispatcher，仓颉 owner 不迁移

采用已取得的 Astra 方案：进程内一个原生 UI dispatcher 管理 renderer sessions。仓颉继续由单一逻辑 owner 串行运行控制器和 DocumentSession；后台解析只提交待采纳结果。**不另造 Windows 编辑器、不把 owner 搬进 WndProc、不用 cjProcessorNum=1 或 re-home 解决线程归属。**

- 将 session 有关的 C ABI 入口变为命令封送，原实现成为 dispatcher 内部函数。session 查找/代次判断、HWND/焦点/IMM32、D3D immediate context、DXGI Present/resize/释放统一在 UI 线程执行并保留内部线程断言；只读纯值查询可用明确的不可变快照。不能先在调用线程取得可变 session 裸指针再排队。
- 命令拥有所需输入/输出和生命周期，队列有容量、命令 ID 与结局。调用者栈指针不得在返回后仍被 UI 使用；开始执行后的超时不是“未执行”，不得重发副作用。未开始的命令可原子取消，已开始的结果持留待取。UI 内合法重入走内部函数，不能同步等自己；出队后释放队列锁再调用可能重入的系统 API。
- `pump(timeout)` 是待满足的取事件请求，dispatcher 必须继续处理消息与其他命令，不把整个 UI 线程堵在该请求上。零超时仍服务已就绪消息；FIFO 持续有值、连续鼠标移动、无输入三类负载都要公平且有界，无事时阻塞等待。事件文字/几何/claim 的出队租约须覆盖调用者完成复制，不被另一次 pump 或 destroy 提前释放。
- 关闭以 session 代次退役新准入、完成/拒绝等待者、保存未决输入，再由 UI 线程结束 IME、销毁 HWND/图形资源；关闭一窗不能停止其他窗。禁止线程仍运行就清零 session/释放资源。`request_application_stop` 应投到 dispatcher，不能对任意调用线程直接 PostQuitMessage。
- 逻辑 owner 检查不能被 native 封送替代：同一 host 的并发 turn 必须被拒绝或由既定 owner 串行交接。不同调用 OS tid 的合法调用与不同逻辑 owner 并发必须分别检测；不把某次运行未迁移当作线程正确性证明。

**本组固定反例：** 原生 A/B 两调用线程操作同一 session，实际执行 tid 始终为 UI tid；真实仓颉默认调度负载正常；两个逻辑 owner 并发调用被拦；pump 等待中 resize/关闭仍收敛且另一窗存活；SetFocus 重入无死锁；命令执行中超时不二次提交/不悬空输出；持续 FIFO 下 OS 消息不饿死。记录实际 API 调用的 caller/execution/HWND tid、session 代次和返回状态，不依赖旧错误字段。

实现参考只读 [GPUI dispatcher](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/dispatcher.rs>) 的队列与唤醒；系统约束见 [Windows 窗口线程归属](https://learn.microsoft.com/en-us/windows/win32/procthread/creating-windows-in-threads)、[D3D11 多线程](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-render-multi-thread-intro)。不引入 GPUI 等运行时依赖。AttachThreadInput 仅在有证明的焦点操作中短时配对使用，不再承担线程正确性。

### 3．框架方案二：捕获、安装、owner 结算组成一条输入交接

复用已经接通的 arm/receipt、claim→共享 `submitInstalledRange16`→owner 决策→ACK，不恢复 restamp 或同文旁路。Windows 普通 SourceRange 能力与尚未实现的 selection-transfer 分开；不为本包开启全部 macOS transfer。

- **捕获时拥有事实。** WndProc 当场复制 IME RESULTSTR、同消息后继 COMPSTR、相位、composition ID；同时冻结修饰键、重复次数、捕获顺序、目标绑定/安装请求和实际来源。之后不能重新读“现在的”HIMC、Shift 或 scene 补来源。`projectionVersion` 始终保留产生时版本。指针/press 的旧几何也不能被刷新成新 scene；按已有 press 租约连续性判决。
- **安装成功先 provisional。** 按 `Ready → Holding(request,captureCut) → ProvisionalInstalled → OwnerConfirmed(receipt) → Draining → Ready` 实施；native 安装成功不能先清门。以 Windows 窄适配的 request/outcome/receipt 完成入口，区分 installed、superseded、conflict、closed；owner 后续检查失败不放行，调用失败不能忘掉请求。取消/换绑后的输入保留旧目标，不能投给新 request。
- **导航是顺序屏障。** 纯字符可沿共享已接受前缀连续物化；导航/选择/组合开始后，暂存后续原始意图，等共享处理器裁决与新选择安装确认后再生成范围。固定 `A→Left→B` 应为 `BA`，不能由旧 caret 得到 `AB`。ACK 重试只补确认，不再次 replace；发布 scene 也不等于前缀 ACK，不能丢未结算后缀。
- **容量有责任。** 将待决队列、claim、shadow 和必要副本合并计费，预留恢复/组合终态槽。普通突发有界，首次超限的原目标及完整载荷可取回，之后拒绝必须可见；不承诺无限输入全部保留。32 claim 的第33笔、raw 环满、分配/事件入队失败均不能仅计数并吞字；序号/前驱仅随成功准入提交，失败不得留下不存在的前驱。预留恢复载荷必须有正常可达的取回/放弃责任方，不能只有测试打印。

**本组固定反例：** XY 连发且每笔之间 present；同 binding 外部同长度写/同字节新版本；A→B→A 身份复用；门内 `A→Left→B`；门内 RESULTSTR/RESULTSTR+COMPSTR/END；捕获 Shift+Left 后松 Shift 再消费；native 安装成功后 owner 拒绝；旧请求结束不放行新请求；owner 已提交但 ACK 失败；第33笔与入队失败后下一笔。每项核原来源、唯一结局及完整载荷/owner 字节；不能靠250ms慢打、重复投递、扩大等待或放松共同守卫拿绿。

### 4．两项机制完成后，连续完成原编辑器整包

先在同一正常 Pharos 走完整小文档主链：中文/空格路径打开→无刻意逐字延时的系统输入→中段非空选区→Markdown 预览→无编辑切回→免点击精确替换→Undo/Redo→公开 Agent 改版→人继续输入→保存→同二进制新实例重开及续写。各步使用动作前冻结源跨度/版本/完整字节独立计算期望，截图对应同实例和相应 accepted 结果。诊断 CLICK_NODE/SendMessage 不能冒充最终 SendInput；每次投递核发送数/焦点，观察结算可轮询，但不重复动作救绿。

随后完成**本页第六节原固定门**：系统 IME、Unicode、几何/生命周期、PNG/失败恢复、20笔真实工作重叠、成本原数、空闲/回收及含空格同源交付。默认窗口下模式按钮已有超出裁剪区的原记录，须分清产品布局声明和框架测量/命中，在责任层修正常尺寸可达性；只把验收窗口放到特定大尺寸不能宣称默认交互已可用。保存前补共享 fd 的两个位置读真实交错及顺序读取反例；若 Windows 文件垫片仍不能履约，就修窄平台文件服务或证明/实施覆盖所有相关访问的串行所有权，不能只给 pread 自身加一把锁便宣称与其他 read/seek 不竞争。保留现有串行 GREEN，不重建通用 POSIX 库。

本轮不追加 1GiB、完整 visual 结构编辑、UIA、Linux、Android 或另一新应用。探针用于压缩定位与构建成本；机制门通过就继续正常产品，不把工作变成新一轮纯验证器工程。旧矩阵按影响复用，产物变更后的主链与受影响面绑定最终同一源集。性能在虚拟 GPU/x64 模拟层如实分项报告，不以工作时长推导性能或承诺物理机器结果。

### 执行、咨询与结束规则

执行模型由用户当前工具决定。用户已说明 GLM5.3 无额度，本包不再调用 Pi/GLM，也不要求执行者再向同型号咨询；旧第七节与早先 Pi 模板不作为本轮开工条件。已经取得 Astra 裁决，以上方案直接实施，不重复问同一架构。查 Microsoft Learn/本机 SDK 及仓颉技能解决 API 细节；仅出现推翻既定前提的新证据时，整理具体冲突交指导，其他独立项继续。既有失败次数不因换工具清零。

恢复后按整包持续推进，不以“咨询完成/探针绿/源码改完/上下文深”停止；只在用户叫停、真实外部阻塞或必须交回的新架构矛盾时中止依赖工作。工具/目录/本地构建缺口在本包内修。写集可分工，guest 构建/SDK交换/桌面串行，保留用户及 E/H 的进程/文件/剪贴板/暂存/stash。结尾集中报告框架机制、平台接线、正常消费、明确未验边界与可启动产物；清理准确归属的自有临时资源，核 SDK 恢复，不 stage/commit/push。

<a id="windows-input-pump-review-20261006"></a>
## 2026-10-06 源码复核：恢复正确输入，再闭合原编辑器整包

本节是较早复核原件；其中已完成的修复、已取得的咨询以及工具隔离实验按上方当前执行依据更新，不把旧措辞重复下发。

**方向没有变；当前不能按原报告继续堆后半链。** 保留 Win32 + D3D11/DXGI + DirectWrite + IMM32 + WIC、同一个 Pharos 及共同 owner/会话/解析/保存。构建、UTF-8 manifest、native 适配、PRESS_BEGIN 先于 FOCUS、runner 有界取消的有效成果复用；不重跑 W0/W1。当前仍没有最终正常编辑器整链证据。接续的新框架能力是：Windows 宿主有界且不饿死输入的消息泵、真实来源可解释的范围输入接续，以及同源正常编辑器消费。

本次核查了当前正典源码、验收脚本、relay 注入器及本机已有索引；**没有操作 VM**。暂停报告中的 accept9/accept10 完整原件在本机索引中尚未定位，不能把报告里的 `not_main_thread` 或点击无排水归因当作复现结论。执行者先归档对应来宾原件和二进制身份；确实缺失就登记，不以新轮倒证旧轮。[离线判据复核](../../artifacts/windows-pharos-20261005/guidance-review-20261006/admission-predicate-results.json)仅证明实际源码判据的假阳性，不冒充 Windows 运行。

新增[生产分支抽取反例](../../artifacts/windows-pharos-20261005/guidance-review-20261006/replay_native_input_seams.py)已在 Mac host clang 执行，[结果](../../artifacts/windows-pharos-20261005/guidance-review-20261006/replay_native_input_seams_result.json)固定当前 renderer SHA：四类事件来源 41→42、range/binding 不变，清 pending shadow 后 FIFO 仍有5条；安装 pending 下 IME RESULTSTR `handled=1/freed=1/update=0/terminal=0/successor=0/queueFull=0`，无门正控 update/terminal 各1。这是实际分支抽取的机制证据，尚非 Windows 完整 owner 错写/丢字的运行复现。脚本和旧 RED 保留，实施后同一反例应反转并补正常产品消费。

### 已确认的必要返工

| 项目 | 当前源码事实及风险 | 本包处理与区分验收 |
| --- | --- | --- |
| 输入来源重盖 | `cjgui_windows_renderer.c` 的 present 成功路径遍历 FIFO，将 kind 28/51/52/33 的事件及几何槽 `projectionVersion` 全改成新 scene。未逐事件证明文本、选择、owner 基线和来源仍适用。同 binding 不等于同一文本位置；binding 守卫仍在，不能夸称所有跨绑定检查已失效，但旧坐标来源确被抹掉 | 删除无条件重盖，保留真实产生时的身份。同绑定纯画面更新可以在消费侧有证明地接续；文本/owner 变化须走既有版本/锚点契约或具名拒绝并保全输入。若生产者缺少必要来源，先定最小来源与安装/FIFO交接契约，不能把当前版当来源。反例覆盖纯刷新合法接续、同 binding 外部写入、换绑/ABA、旧选择或组合终态不得错写 |
| 输入被门丢弃 | `source_install_gate_holds_input` 只增计数；字符/导航/组合开始返回未消费，无延期队列。WndProc 默认处理不会替 CJGUI 保存编辑意图。尤其 IMM32 RESULTSTR 在开始失败后仍被标 handled 并消费，结果无 owner 事务也无可恢复载荷 | 保留安装对齐门；实现或复用有容量责任、真实来源和顺序的待决输入交接。正常同绑定短暂安装后按 FIFO 恰一次兑现；换绑/版本冲突不得投到新目标，须明确终态/恢复路径；满载不能假成功。连发、自动重复、代理对和组合提交都不能靠 250ms 节奏救绿。不是简单删门，也不是给无来源旧按键盲重放 |
| 零超时消息泵 | `pump_windows_messages` 先取 CJGUI FIFO，空且 `remaining==0` 就返回，尚未 `PeekMessageW`。共同调度器预算用尽与 drain 后续轮会调用 pump(0)，可反复不搬运系统消息；FIFO 持续有值时也需核系统队列公平性 | `timeout=0` 表示不阻塞等待，不表示不处理已就绪系统消息。先用实际函数做 FIFO空、OS队列有消息的 pump(0)/pump(1) 区分；再实现有界系统消息服务与 FIFO 排水，保护 WM_QUIT、关闭、输入、公平性和空闲不自旋。不能声称这一源码缺口已解释 accept10，须同实例轨迹确认 |
| 线程失配证据不足 | native guard 比较 current OS tid 与创建时 ownerThreadId；现有 pump tid 打印在 guard 成功之后，不能排除被拒的调用。某轮 tid 不变也不能证明另一轮没有迁移；共同窗口的 lastNativeFailure 还可能保留此前错误，不能代替本次 FFI 返回码 | 在首个拒绝点记录 API、session/token、HWND创建线程、owner/current tid、turn/场景及实际返回状态，贯穿创建→pump→present→destroy。先区分真实线程迁移、调用者错误、历史错误字段、旧 session、旧 DLL/EXE。不能删 guard、随调用改 ownerThreadId，或单凭“仓颉 M:N”建立第二套线程架构。若确需固定 UI 线程，先独立裁决窄适配及 Cangjie 回调/owner归属，保持公共 owner 串行契约 |
| 构建来源准入 | `guest-transfer/llc-relay/llc_wrapper.c` 只按 `pharos_mark.opt.bc` 文件名注入固定 obj；捕获 CopyFile 的失败未挡住成功返回，wrapper 内无内容 hash 门。报告的构建后 SHA 对比不能代替下一次注入的先决条件 | relay 可继续使用，但纳入正式可复现入口：冻结源码/依赖/ABI/编译器版本与哈希/完整flags/BC/obj/nativeDLL/EXE关系，注入前核输入和obj；不匹配/捕获失败必须非零，不允许旧obj。使用隔离工具链目录或明确工具重定向，移除对用户SDK全局llc的长期替换，核原件恢复哈希。不变的输入可复用已验obj，不必每次重复13–29分钟生成；app输入改变才重新relay。Mac产obj+来宾链接如实标为混合构建，不能写来宾原生完整编译 |
| 验收假阳性 | `Probe-Click` 匹配 `CLICK_RESULT 107`，native 返回 `CLICK_RESULT 107 missing` 也通过；CLICK_NODE 实际使用 SendMessageW。TypeUnicode 每单元250ms，未核 SendInput 返回数；foreground 失败仅记录；替换只查旧token消失且任意X出现 | 只修这些必要工具门：missing/未送达必须失败；SendInput精确发送数+目标HWND/焦点+owner/accepted核对。CLICK_NODE保留为明确标注的局部诊断，最终鼠标腿走系统输入。基于动作前版本、源跨度、完整字节独立算结果；同长错文、错范围、零投递均红。不得扩成另一条无尽日志验证器工程 |

源码入口：[`cjgui_windows_renderer.c`](../../runtime/cjgui/platforms/windows/native/cjgui_windows_renderer.c)（present、`pump_windows_messages`、`source_install_gate_holds_input`、`queue_owned_range_replace`、`handle_windows_ime_composition`、CLICK_NODE）；[`windows_application_host.cj`](../../runtime/cjgui/src/windows_application_host.cj)；[`llc_wrapper.c`](../../artifacts/windows-pharos-20261005/guest-transfer/llc-relay/llc_wrapper.c)；[`pharos-writing-chain-acceptance.ps1`](../../artifacts/windows-pharos-20261005/runner/batches/acceptance/pharos-writing-chain-acceptance.ps1)。按符号读必要代码，不重新通读所有平台历史。

另有保存前必须核对的小接缝：[`cjgui_windows_posix_compat.c`](../../runtime/cjgui/platforms/windows/native/cjgui_windows_posix_compat.c) 的 `pread` 用 `_lseeki64 + _read`，会改变 fd 位置，不能仅凭注释“单线程owner”声称与位置读等价。共同 `ImmutableBase.readAt` 确实调用该符号。先核本轮冻结装配中后台读取/保存的实际调用者，用两个不同偏移及共享句柄交错验证；需要修复就在 Windows 窄文件服务内保持位置读取语义。`renameat`/`fsync` 也按保存链实际使用核失败保旧及路径语义，不扩写通用 POSIX 层，不据一次正常保存宣称掉电持久性。

### 实施顺序与咨询

1. **冻结一次可解释输入，稳定宿主。** 复用现有 VM、已装SDK与常驻worker。先把relay准入和最小验收门修可信，再做 pump(0) 与首次线程拒绝的区分实验；可以并行读码/离线反例，但同一guest图形桌面与cjpm target串行。不要又从GPU画矩形开始。
2. **统一输入接续。** 把重盖、安装待决、pending shadow、IME结果、旧来源拒绝作为同一交付来处理。立即准备一次聚焦 `gpt-6-astra/max` 只读咨询：提供上述反例、当前 Windows 生产者字段、核心消费门、E的现行契约，要求最小字段/队列归属/顺序与终态；已有裁决前提相同则复用。在此期间可继续 pump/构建/工具的独立工作。共享头/核心若确需小改，列出受影响函数和E/H边界；不能批量覆盖在途树或为Windows放宽共同旧事件守卫。
3. **先闭合完整小文档正常链。** 正常 Pharos 打开中文/空格路径→快速系统输入→中段非空选择→预览→无编辑切回→免点击首笔精确替换→Undo/Redo→同owner公开Agent改版→人免点击续写→保存→正常关窗→同二进制新实例打开和续写。单次投递，状态变化或明确截止结算；输入可以依契约拆笔，但逐笔范围/版本/合法前缀及终态完整字节须成立。禁止为了拿绿反复点焦点、重投正文、退化成末尾追加。
4. **继续完成原第六节固定门。** 系统IME、Unicode、几何/生命周期、正常编辑器PNG、受控设备恢复、20笔真实工作期间公开请求、空闲/回收、含空格同源交付均仍在包内。无变化原件复用；变更后的输入链与最终产物必须对应同一源码/ABI。不要增加1GiB、完整visual编辑、UIA、Linux或新的前置消费者目标。

线程与消息泵参考 [Microsoft PeekMessageW](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagew)，输入计数参考 [Microsoft SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)。本地 GPUI `gpui_windows/src/platform.rs` 的消息循环、`dispatcher.rs` 的主线程归属仅作实现思路参考，不引入依赖；精确目录见本页原参考节。普通明确接线直接做，API查Microsoft Learn与SDK头；根因不明按第七节 Pi→精确GLM5.3，复杂技术 gpt-6.1-sol/max，未决身份/线程契约 Astra/max。不得用“需要裁决”停住全部工作，也不能换模型清零累计失败。

### 收尾与停止边界

高频无条件调试文件输出改为默认关闭、按实例有界的诊断；保留能重算的原件，不因删诊断失去唯一证据。最终核EXE/DLL/源码/relay链及原SDK恢复，提供用户可直接启动的正常编辑器。仅清本轮准确归属的进程/端口/文件，保留用户VM、窗口、输入历史、剪贴板、E/H改动及暂存/stash；不stage/commit/push。

本节不是新一轮纯探针任务。上述明确反例及受影响检查通过后就推进正常写作链，最后按原固定门集中报告；不在每个绿色后请示。若旧故障经首次独立咨询及一次新证据追问仍无可验证方案，仅交回该依赖并继续独立项。不能因长上下文、已有todo勾完或“理论上能工作”将整包称完成。

<a id="windows-tool-handoff-review-20261005"></a>
## 换工具接续：当前复核与执行顺序（2026-10-05）

**方向保持；实施顺序收紧到正常 Pharos。** 旧线程「推进 Windows 编辑器移植 A–F」已暂停，现有 Windows renderer、仓颉 host、共同包适配和 runner 保留。接续者不从 W0/W1 重启，不另造编辑器，也不先把全部 Windows 底层接口做完才尝试产品。当前尚无正常 Pharos Windows 写作链，更不能把 native 输入探针称作编辑器已可用。

### 已有成果的有效范围

- Windows native 已有 D3D11／DirectWrite、样式、DPI、累计纹理预算、鼠标与 UTF-16 事件等实现和定向原件。最新[输入原件](../../artifacts/windows-pharos-20261005/runner-sessions/bc279ba2cd8347b0adb9db78c4b4ee19/guest-results/input-contract/windows-input-contract-run.log)的构建、探针和 worker 退出均为 0；清单 50/50，源码包 `79bd9e84f9c35a70ad6f5221621c617f5bafdbd4def1ab342e08fb94b942522b`。该[探针](../../artifacts/windows-pharos-20261005/renderer-contract/cjgui_windows_input_contract.c)使用 **SendMessageW + native FIFO 读取**；标签／值、拖选 1:3、A/B 范围载荷、旧 DPI 坐标拒绝有效，尚无仓颉 owner、SendInput 正常产品或真实 IME 证明。
- [runner](../../artifacts/windows-pharos-20261005/runner/windows_runner.py)的返回码／不完整帧／超时退役已有修复和负控；有效证据复用。运行中主动取消与跨任务应用持有另见下文，不能由 15/15 回包测试推导成立。
- SDK 已在来宾当前用户 `C:\Users\jiangxuanyang\AppData\Local\Programs\Cangjie` 持久安装，暂停报告为 1.1.3。新工具只核一次实际版本与可执行文件路径；若已变更，沿现安装做兼容验证，不重复安装，不改 Mac SDK。
- Windows 正典实现入口为 [native](../../runtime/cjgui/platforms/windows/native/) 与 [windows_application_host.cj](../../runtime/cjgui/src/windows_application_host.cj)。目前产品仍由 [stage_pharos_windows.py](../../artifacts/windows-pharos-20261005/runner/stage_pharos_windows.py)从现有 `apps/pharos_mark/src` 和四个共同包生成装配；不存在一个已经完成的 `apps/pharos_mark_windows` 产品入口。名称不作为验收门，同源和可复现构建才是。

### 第一优先：把正式产品构建和正常启动打通

1. 接续已有[源码发现咨询材料](../../artifacts/windows-pharos-20261005/consultations/pharos-package-source-discovery/request.md)，不接受其假设为结论。[失败原件](../../artifacts/windows-pharos-20261005/runner-sessions/1c570524093f423b89a85fd9b8658355/guest-results/pharos-build-logs/pharos_mark.log)是 **127 errors generated、仅打印 8 条诊断**，涉及 7 个不同类型；“包内有声明”不证明该次 cjc 真读到了这些文件，也不证明这 8 条就是第一根因。先对应失败那次 archive／manifest／实际来宾源码／cjc 参数及完整诊断，区分旧包装配、文件发现、条件编译与后续连带错误。新清单不能倒证旧构建。
2. [旧慢构建咨询](../../artifacts/windows-pharos-20261005/consultations/pharos-app-timeout/answer-followup.md)已有进程证据：某次无新输出时仍在 app 单元 `llc` 代码生成，外部停止并非编译器给出的失败。不得再用“没日志＝卡在链接”归因，也不反复用相同输入全量编译等待超时；先做能区分假设的小检查，必要时只重建受影响 app 单元。新构建需要固定输入和阶段原数，不继承旧残留 exe 当新结果。
3. 正常产品的平台边界必须一起核清：host 条件编译、实际被选中的传输、应用侧 `pharos_*` 原生服务及 DLL／库闭包。当前 app 生成清单无应用 `[ffi.c]`，冻结 `main.cj` 有 35 个 `pharos_*` foreign 声明且未打包其 native 源；不能把“8 条类型诊断解决”直接视为可运行。已有 macOS 诊断注入／PDF 等辅助不能整套成为 Windows 正常启动前置；通过正典平台边界按需隔离。正常入口需要的时间、文件、进程、owner／公开传输服务必须真实实现，其他能力具名不支持；不能用返回成功的空壳换取链接通过，不能复制 owner／历史／解析器。另有具体待核点：host／产品用 `@When[os == "windows"]`，共同 transport 用 `"Windows"`；用当前 SDK 的极小目标条件检查确定取值后统一，不能由字符串差异直接归因上述类型报错，也不能不核就改共享传输。
4. 将反复使用的 staging、native 构建、包构建与运行命令收敛为正式入口（平台／产品 tools 下，现有脚本按职责迁移或包装；artifacts 只存输入快照和结果）。一次完成同步、指纹、构建、闭包及正常启动；不依赖执行线程的记忆或来宾中手改文件。共享修复仍回正典，E/H 在途写集按函数避让，不重构整份产品主文件。

### 同包必修：三个源码安装／恢复接缝

以下为当前源码与共同契约复核发现，**尚未在 VM 跑新增 RED**。接续者先在当前生产函数上各落一个最小负控，再最小修复，并最终在正常 Pharos 消费；不把静态推理写成设备结论。

| 问题与落点（`cjgui_windows_renderer.c`） | 机制要求与区分验收 |
| --- | --- |
| `set_source_install_gate` 存 pending 并返回 OK，但 `queue_owned_range_replace`、`enqueue_windows_navigation`、`begin_windows_composition` 未消费这个门 | 安装待决期间不能按旧选择发布编辑；复用共同具名拒绝／延期语义，不能静默丢键或私自重放无来源输入。负控：新非空范围票已挂起、尚未安装时字符／Delete／组合开始不产生旧范围 owner 事务；正确安装后首笔只替换新冻结范围 |
| `install_owned_source_selection` 在 `SetFocus` 前调用要求已经聚焦目标且 proxy 正文相等的 `windows_validate_active_text`；声明入口也要求先聚焦。共同窗口 `sourceInstall` 路径却有意跳过先 focus | 分清 accepted 目标准入与“当前已活跃”校验。以正确票据准备目标 proxy，并在同一次接管安装焦点和非空范围，失败保旧。负控：A 为源码目标、焦点在预览／另一节点 B，A 的正确请求应完成安装；错误代次拒绝不动 B。不得靠产品额外点击或永远先聚焦掩盖原子安装契约 |
| `recover_active_text_proxy` 只查 accepted 节点／正文，未核当前活跃身份就改 session 全局 proxy 和选区 | 按公共头文件“非活跃目标拒绝且不变”履约。负控：A 正在编辑，accepted 中另有 B，恢复 B 必须拒绝且 A 的正文镜像、选区、待决输入不变；随后 A 仍能正常输入 |

源码位置：上表依次为当前 native 约 3860/5374/5537/5623、6009/5319/6120、6074 行；以符号为准。已有 DPI、样式 run、label/value 和累计纹理预算问题不再列为待返工。presentation TEXT 的直接可视输入未接齐属于主链之后的扩展，本包先保证源码编辑与只读预览。

### 控制通道：补一个取消切面，明确应用持有方式

[worker_run.ps1](../../artifacts/windows-pharos-20261005/runner/worker_run.ps1)在任务 `WaitForExit` 期间不读取 STOP；host `run_batch` 只捕获 `Exception`，本次纯内存中断检查发现 `KeyboardInterrupt` 后协议仍为 connected，最终 STOP 不能立即结束在跑的 guest 任务，最长可能等到该任务预算。下一次长构建前补**同 session/job 身份的有界取消或断连回收**，验活跃子进程与回执，不能只改捕获类型后宣布解决，也不能批量杀控制台或用户进程。不重建一个通用远控平台。

worker 在一项任务结束后关闭 kill-on-close job，后代一并回收。因此不能 `Start-Process Pharos` 后让脚本立即返回、再在下一任务找那个窗口。优先把本轮正常消费放进**同一个有界 guest 作业**，应用保持到原件落盘再清理；确需跨批持有才实现明确的实例所有权。最终另提供用户可正常启动的产物及命令，不以验收器保活替代正常入口。

### 接续到结束：一个产品链，最后一次汇合

执行顺序为“构建／启动 → 三处接缝与源码编辑 → 预览原选区往返 → 人／公开 Agent／人 → 保存关开”，独立的 PNG／设备恢复可以交错推进；以上顺序不是逐段请示点。不得先扩 visual 编辑、UIA、GB 文档、Linux 或第二个前置应用。

功能接通后按原第六节固定门完成 Unicode／系统 IME、PNG／失败保旧、设备恢复、20 笔真实负载下的公开操作、空闲和开关资源、含空格同源交付。旧证据按源码影响复用；最终同一构建必须有 SendInput→共同会话→owner 完整字节→accepted 画面以及保存／新实例复开原件。不能用 SendMessage 探针和仓颉编译分别通过来拼成这条证据。

新工具不需要旧线程上下文即可从上述路径接续。按第七节 **Pi→精确 GLM5.3、复杂问题 gpt-6.1-sol/max、未决公共契约 gpt-6-astra/max** 咨询，已有答案前提不变就复用；当前构建源码发现问题的请求已写好但暂停前未调用。不得因换工具清零失败累计。遇具体阻塞只暂停其依赖，不能把全部时间继续消耗在 runner／探针，最后按固定门集中报告。

### 本轮执行记录（2026-10-05，Sisyphus 接续中，整包未完成）

- 正式链收敛：stage/prepare/包构建已成固定入口（115 项清单、zip 哈希门、应用原生库同链编译）；六个依赖包干净重建全绿。证据索引见 `artifacts/windows-pharos-20261005/evidence/20261005-sisyphus-handoff/INDEX.md`。
- 三接缝已修并探针收口：RED `gate_leak range=1 nav=2` → GREEN `PASS gate=3 install=0:5 first=X stale_refused recover_refused continue=Y`；旧输入契约回归仍绿。
- 阻塞（只暂停依赖部分）：产品包前端已出 `.cjo`，`llc` 在 ARM64 模拟 x64 上三轮预算（45/117/125 分钟）无产出且不可续跑；`--stack-trace-format=simple` 对照同样爬行。`main.cj` 的 `runPharosApplication`（3742 行单函数）与 E 在途 `async_multiline_measure`（已给诚实失败桩）的裁定归 E；E 当日在 mac 侧撞上同样的 `@When` 大小写与 lambda 裸块错误（本轮已顺手修 3 行）。验收二进制与 A–F 门待 llc 收敛后执行。
- E/H 写集、暂存/stash、用户文件、剪贴板、实例均未动；无 stage/commit/push；各 guest 会话均已按身份关闭。

## 一、固定方向：同一个编辑器，共享核心，补 Windows 适配

macOS、鸿蒙和 Windows 的文档模型、事务、撤销、Markdown 规则与公开协议必须同源。Windows 平台入口可以不同；业务正文不能再有一份独立实现。不是把 AppKit 或 ArkTS 文件逐份翻译成 Windows 代码。

| 层 | 本包选定路线 | 复用与约束 |
| --- | --- | --- |
| 编辑器业务 | 现有 `document_core`、`app_services`、`markdown_engine`、`editor_surface` | 复用 DocumentSession、DocumentFile、SourceMap、历史、快照和保存；平台只提供必要服务 |
| 框架 | CJGUI 仓颉组件、布局、状态、场景接受、文本会话与共同操作 | 延续原 owner 和 accepted 身份，不在 Windows 桥里复制业务正文、撤销或第二套布局 |
| 窗口／事件 | Win32 | HWND、消息泵、键鼠、焦点、捕获、剪贴板、窗口尺寸与 DPI；默认走 Unicode API |
| GPU 自绘 | D3D11 + DXGI | 将 W1 的有效图形经验接入 CJGUI 正常 renderer；对象按设备／窗口／资源代次归属，不能长期保留实验中的全局单窗口状态 |
| 排版与文字绘制 | DirectWrite + CJGUI 的 D3D11 提交 | 持留同一份排版，绘制、命中、caret、选区和上下导航共用；字形栅格结果进入有界缓存。DirectWrite 不会自动替应用完成 D3D11 绘制。[微软说明](https://learn.microsoft.com/en-us/windows/win32/directwrite/rendering-directwrite) |
| 系统输入法 | 先走 Win32／IMM32 消息到现有文本会话 | 对照本地 GPUI 的实际路径，接组合、提交／取消、焦点和候选定位。TSF 是出现已证能力缺口时的扩展方向，不先并造两套输入栈。不得自研输入法或把直接注入汉字当作系统组字。[组合消息](https://learn.microsoft.com/en-us/windows/win32/intl/wm-ime-composition) |
| PNG | Windows WIC 解码 + 现有 CJGUI 图片准入／缓存 + D3D11 纹理 | 解码前预算、尺寸和失败原因沿共同契约；WIC 只承担平台解码。[系统编解码器](https://learn.microsoft.com/en-us/windows/win32/wic/native-wic-codecs) |
| Agent 入口 | 现有 shared-operation 协议与 owner 队列 | 若 Unix socket 不适用，为同一协议补 Windows 本地传输；可用 loopback TCP，保留身份、授权和版本校验，不另造业务服务器 |
| 无障碍 | 后续 Windows UI Automation 平台投影 | 保留共同语义模型。本包不把 UIA 全覆盖、讲述人验证作为启动编辑器的前置条件，也不能因此宣称已支持 |

初期采用 DirectWrite 字形／run 栅格与有界纹理缓存；彩色字形若需要 Direct2D 系统接口，可封装在同一 Windows 文字适配内部，仍消费同一布局，不另起整套 UI 框架。不能把 shaping cluster 直接等同 Unicode 字素；分段服务与现有文本会话的契约不明确时按第七节咨询。

不在本包改用 Vulkan、Qt、Slint、Flutter、SDL、WebView 或可见的系统 EDIT 控件替代 CJGUI 自绘正文。GPUI 等仅查实现思路与测试，不成为开发、构建、运行或发布依赖。Linux／Android 不在本包开工，现有 macOS／鸿蒙后端也不换路线。

## 二、起步只读这些，并保留当前工作

1. 框架 [AGENTS](../../AGENTS.md)、[ACTIVE](../../runtime/cjgui/ACTIVE_DIRECTION.md)、本任务；阶段意图按需看[设计导航](DESIGN_INTENT_INDEX.md)、[共同操作契约](../core/AI_NATIVE_UI_SEMANTICS.md)。
2. 产品 [AGENTS](</Users/jiangxuanyang/Desktop/Pharos Mark/AGENTS.md>)、[STATUS](</Users/jiangxuanyang/Desktop/Pharos Mark/STATUS.md>)及[架构的状态归属和范围输入部分](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/ARCHITECTURE.md>)。首次写仓颉前读 [cangjie-coding 技能](</Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md>)。
3. [W1 报告](../../artifacts/windows-w1/REPORT.md)、本轮指导的 [RED 原件](../../artifacts/windows-w1/guidance-review-20261005/red.json)和[只读回放程序](../../artifacts/windows-w1/guidance-review-20261005/replay.py)。原 RED 保留，修后另存 GREEN。
4. 直接相关资产：框架 [src](../../runtime/cjgui/src/)、[FFI 与 POD](../../runtime/cjgui/src/runtime_renderer_session.cj)、[公开传输](../../runtime/cjgui/shared_operation_core/src/shared_operation_transport.cj)；产品 [四个共享包](</Users/jiangxuanyang/Desktop/Pharos Mark/packages/>)、[macOS 入口](</Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark/src/main.cj>)、[鸿蒙薄装配与控制器](</Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/application/src/>)。只按依赖读相关符号，不通扫历史计划。

Windows 机制参考位于[本地 GPUI Windows 源码](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/ZED/zed/crates/gpui_windows/src/>)：`window.rs`／`events.rs` 看窗口与 IMM32，`directx_devices.rs`／`directx_renderer.rs`／`directx_atlas.rs` 看提交和资源退役，`direct_write.rs` 看排版与字形。先定位关键函数和测试，再查对应 Microsoft Learn 及本机 SDK 头文件；不从记忆猜 ABI、消息含义或 HRESULT。

开始时记录两仓当前差异和暂存边界。E/macOS 的文字安装、性能和输入改动，H 的 OHOS renderer／snapshot／ArkTS／transport，以及既有暂存都保留。不切分支、不 reset/stash、不自动 stage/commit/push，不用整文件覆盖共享写集。共享核心确需变化时按函数做最小通用修复；已有未完成并行修改不可直接改写。冲突只阻塞其依赖部分，Windows 独立工作继续。

## 三、工作环境：就在已安装的 Windows 虚拟机里实施与验收

使用 Mac 上现有 Parallels 的 Windows 11 来宾，不另买／另装虚拟机，不在 macOS 上编译一个近似版本冒充 Windows。W1 使用的 VM UUID 为 `{9e5dedb2-90f8-4d21-80f0-41e194407fab}`，工作目录为 `C:\cjgui-windows-w1`；使用前按身份核对，不据此操作其他虚拟机。

W1 报告记录 SDK 1.1.3、`x86_64-w64-mingw32`，路径 `C:\cjgui-windows-w0\sdk\cangjie`。先取实际 `cjc/cjpm` 版本；若用户已换成 1.2.0，沿用并验证受影响兼容面，不为旧报告反复重装，也不升级两仓的全局 SDK 要求。编译器、应用及实际加载的自建 DLL 架构逐项核对；目标是当前 x64 来宾产物，不假装已支持 Windows ARM64 原生编译。

控制通道复用 W1 经验，但先修第四节中已证的退出码与生命周期问题。长脚本按文件传输／执行，避免反复调用 `prlctl exec` 开新控制台。采用一个有身份、可退出的 worker；每批复用或明确回收，不留下无限重连的旧 worker。核对客户机实际部署脚本的路径和 SHA，不能拿 Mac 上 `worker_batch.ps1` 的检查替代实际运行的 `worker_run.ps1`。

前台验收在 Windows 来宾的交互会话完成。优先 guest-side 有界驱动与截图／读回；Mac 屏保、Mac 工具报错、Windows 会话状态分别判断。不以抢不到焦点推断框架错误，不改变系统锁屏策略；工具确实无法输入时保留具体错误，继续不依赖桌面的实施。

## 四、必要旧问题一次并入本包，不另开验证长跑

W1 的 D3D11 设备、着色／透明混合／裁剪／resize 和仓颉参数到图形的结果保留；它尚未证明 CJGUI 编辑器正常消费。指导已核对源码及原件，以下按实际缺口补齐：

| 必要项 | 已发现的问题 | 本包如何闭合 |
| --- | --- | --- |
| 事件改变状态与画面 | W1 `drainEvents()` 只累计事件，场景来自硬编码参数；注入后没有事件驱动的状态提交 | 在 Pharos 真输入链完成事件 → 共同事务 → 新 owner → accepted 文字画面。受控断开处理器时验收必须失败 |
| 纹理实际使用 | `w1gpu.c` 的纹理支路要求 alpha 参数为负，现有场景调用未进入 | 显式覆盖采样支路与像素，再在正常编辑器的共同图片节点消费 PNG；分配出纹理不等于画过 |
| runner 准确报错 | 畸形 `[exit=…]` 被当 0；传输异常伴部分成功正文也可返回 0，指导 RED 已复现 | exe → PowerShell → worker → host 的唯一真实退出码链；缺失、格式错、超时、截断具名失败；用确实返回 7 的程序做全链负控 |
| 有界执行与回收 | `Start-Process` 只打印 ExitCode、不显式传递；同步读管道可能卡住；worker 每批启动且无限重连 | stdout/stderr 均有界收集，连接／任务／关闭有截止；3 批共 12 个轻任务核对自有进程与窗口不累积，结束按 PID／实例回收 |
| 资源证据 | W1 shutdown 把计数直接清 0，不能证明零泄漏 | 正常创建／释放点记账，覆盖部分初始化失败及 5 次开关编辑器；debug layer 可用时附 live-object 原件，不可用就明示，不伪造 0 |

集中更正旧报告中的范围，不重做整个 W0：VendorId 十进制 `88099906` 对应十六进制 `0x05404C42`；原 `1,000,000,007` 小于 `2^32`；`cjpm run` 行为不能直接外推到 `cjpm test`；原 Int64 负控在最大值 `+1` 时抛溢出，另用一个不溢出的错误期望证明断言汇总确实非零退出。截图颜色一致不等于同帧完整像素相等。保留 W1 真正的正控数据，不把这些修正变成整包的主要工作。

## 五、整包实施范围 A–F

### A．同源构建与 Windows 框架入口

拟建 `runtime/cjgui/platforms/windows/` 和产品 `apps/pharos_mark_windows/` 的薄装配，名称可按现有组织调整，不能另建第二个业务编辑器。Windows 构建显式选择共同源码与平台实现；当前主 `cjpm.toml` 含 AppKit／Metal 链接选项，不能原样照搬。

优先直接依赖共同包；工具链需要 staging 时由脚本从正典源码生成、带输入清单和 SHA，所有共享修复回正典，不能长期手工维护第二份 `text_session`／DocumentSession。Windows 专属实现放平台目录。正常入口必须从干净产物目录完成同步、构建、DLL 闭包检查与运行；不靠上次残留 DLL、手修生成清单或一串未归档临时命令。

保留公共签名和现有 POD 的意义。不支持的平台服务返回具名 unsupported，不以永远成功的 stub 通过构建。碰到不可分离的 macOS 硬绑定，抽出最小平台边界；先做影响分析，不能为 Windows 把 E/H 正在用的契约重写一遍。

### B．正常自绘窗口、排版与输入通路

接通窗口创建／关闭、消息泵、焦点、键盘、鼠标点击／拖选、滚轮、resize、DPI 和按需刷新。框架接收事件后在真实 owner 通路裁决；原生回调不持有另一份业务正文或执行自己的 Undo。

DirectWrite 持留布局绑定内容、样式、可用宽度、DPI 与 accepted 版本。命中／caret／选区查询必须取对应版本的同一布局；失效就重建或具名重试，不混用上一帧几何。字体回退、UTF-8 字节 ↔ UTF-16、代理项、组合字符和字素导航不得用“每字符固定宽度／每个 UTF-16 单元一步”替代。

D3D11 的纹理、字形和图片必须有预算、缓存键、引用及设备代次。空闲不持续全量 build/layout/upload；caret 闪烁可以按需提交，但不应每次重排／上传正文。普通窗口和 GPU 生命周期用真正的生产路径，不长期留在 W1 `w1_*` 实验接口。

### C．现有 Pharos 的正常编辑与预览

本包先复现 **UTF-8 文档不超过 256 KiB 的正常写作范围**。复用已存在的容量准入机制，打开及人／Agent／Undo／Redo 按同一结果长度规则裁决；超范围具名拒绝，禁止截断加载或丢数据。这是本包验证范围，不是把共享编辑器永久限制到 256 KiB。

正常窗口提供打开／新建、源码正文、保存、撤销／重做、预览切换等已有动作。支持中文和含空格路径、LF／CRLF 原字节保留。复用现有样式和呈现描述；平台菜单、快捷键及文件选择器可适配 Windows 习惯，不为移植重做首页设计。

源码面做到插入、Enter、Backspace/Delete、方向移动、Shift 扩选、非空选区替换、上下导航、滚动后编辑、焦点往返与光标闪烁。Markdown 预览复用同一解析器与 SourceMap，至少实际显示标题、段落、强调、列表与代码块。源码中段非空选区 → 预览 → 返回，正文零修改；安装确认后免点击输入精确替换原范围，再 Undo 完整还原。

源码／预览共用同一个文档实例；不把预览字符串重新导入为正文。直接在 visual 呈现面编辑是下一项扩展，只有主链全绿且仍可推进时再接现有 `editor_surface`；只读预览绝不能报告为 visual 编辑通过。

### D．系统输入法接现有会话，人的事务与 Agent 共用

将 Win32 普通文字和 IMM32 组合生命周期接到现有窗口拥有会话；平台只给正文范围、preedit、选区与终态。确保 RESULTSTR／WM_CHAR 等相邻通路不会重复提交。组合期间不提前写 owner；提交恰好一笔，取消零笔；组合开始于非空范围时冻结该范围。系统候选位置取同一 accepted caret。处理失焦、会话换绑与旧事件退役，复用已有恢复／草稿机制。

用来宾当前已安装系统输入法做一次真实组字提交和一次 ESC 取消；若需要改变输入源，按身份记录和恢复。缺输入法／系统回调时如实列出具体环境边界，不能用 `SendInput(KEYEVENTF_UNICODE)` 注入成品汉字代替 IME 验收；独立的普通输入与框架生命周期测试继续。

公开连接至少实际消费发现／context、同版本范围读、带版本修改、Undo／Redo、保存以及 owner／accepted 读回。Windows 传输必须复用现有协议解析、授权和串行 owner 队列；调用可以由来宾内真实公开客户端发出，避免无必要地暴露到其他网络。

完成“人修改 → 脚本 Agent 通过公开协议修改同一 owner → 人免点击续写”。外部改版后按现有 ChangeMap／锚点契约恢复或具名拒绝，不能吞掉输入或插到错误文档。脚本客户端和真实模型调用分开标注；本包不以额外调用模型充当技术闭环。

### E．图片和异常恢复服务于编辑器

让正常 Pharos 窗口中至少一个实际使用的共同图片节点走 PNG → WIC → 共同准入／缓存 → D3D11 纹理，可使用现有产品资源或界面图片；不为此另造 Markdown 图片语法或专用展示应用。覆盖非对称小 PNG 的像素／alpha、裁剪、换图、坏 PNG 和超预算拒绝，拒绝保留此前有效资源。图像 oracle 独立于被测 shader／解码结果。

处理 `Present`／`ResizeBuffers` 的设备移除或重置错误，记录原因，终结旧设备代资源，重建并根据当前 owner 恢复画面；失败有界，不能不停自旋。按[微软设备恢复说明](https://learn.microsoft.com/en-us/windows/uwp/gaming/handling-device-lost-scenarios)核实 Windows 桌面接法，不照抄 UWP 宿主。

允许通过测试闸在真实错误处理入口注入一次失败，证明原 owner 不丢、旧资源不复用、恢复后继续编辑；明确是受控故障，不能写成真实驱动掉线。夜间不执行影响整台来宾的强制 TDR、禁用显卡或重启用户虚拟机。候选提交失败保留旧 accepted 场景；已提交的业务 owner 不因 GPU 失败回滚，也不能谎报已经呈现。

### F．冻结一次、完成真实写作链和可复现交付

受影响针对性检查通过后冻结一份源码输入，从含空格目录的随包源码构建最终 x64 Pharos，运行下表。应用、native DLL、共享包、客户端与数据夹具的来源和 SHA 对应同一轮；构建后的源码再变就只重做实际受影响链。

运行探针是验收辅具，最终应留下可由用户正常启动的编辑器、构建／运行说明和独立测试数据。不能只交一段自动自关闭程序。

## 六、固定验收门：证明现有编辑器在 Windows 消费

| 项目 | 本包必须取得的事实 |
| --- | --- |
| 正式入口 | 来宾中干净产物构建成功；应用及自建 DLL 为 x64；包含中文／空格路径的文档从正常入口打开；画面确由 CJGUI 自绘 |
| 人类输入通路 | 使用来宾 [SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput) 经系统队列投递，核发送数、目标 HWND、实际焦点及到达事件；至少一笔输入导致 owner 与可见正文精确变化。PostMessage 仅能标消息级证据，不能覆盖本项 |
| 范围与 Unicode | 中段非空选择后替换，owner 按冻结源跨度精确匹配；覆盖代理对、分解重音及一个多标量簇的移动／删除，边界不切坏；一次明确编辑意图恰一笔，纯选择零笔 |
| 组合输入 | 系统 IME 可见预编辑、提交与取消；分别核 owner 的零／一／零事务和完整字节。普通注入与系统组字分开留证 |
| 源码／预览往返 | 同版本预览的实际画面；无编辑往返后非空选区保持，免点击首笔替换及 Undo 全文还原；不能只核末尾 caret |
| 人／Agent 共同操作 | 同一实例、同一 owner 的人→公开写→人；全程请求／回包、版本与完整 owner 字节对应；过期版本、非法范围／越界容量拒绝后版本和正文保持 |
| 保存与复开 | 保存成功回执后检查真实文件完整字节；正常关窗，再由同一最终二进制打开，新的 owner 完整字节一致，重开后还能输入 |
| 几何与生命周期 | resize、最小化／恢复、滚动后的点击、选择、输入仍在正确位置；DPI 受控检查标明方式，未做物理跨屏就保留边界；失焦不误写，关闭后旧回调不访问退役窗口 |
| 图片与失败 | 正常编辑器图片实际采样显示；坏数据／超预算保旧；受控设备错误走真实恢复入口，owner 保持且恢复后继续编辑 |
| 响应与资源 | 一轮至少 20 笔公开读／写在编辑器实际滚动或预览工作期间完成，记录是否真的交叠；输入→owner／accepted 的 p50/p95/max、实际样本数、RSS、build/layout/upload/submit 原数分别报告，不把 IPC 回包当显示完成 |
| 空闲与回收 | 失焦静止至少 10 秒核不空转；聚焦闪烁单列。3 批 worker 与 5 次编辑器开关核自有资源回到基线；旧窗口／用户进程不在清理范围 |
| 同源交付 | 含空格源码包可独立构建，清单逐项核实；测试退出码贯穿到底，必需原件写入失败不能仍返回 PASS |

夹具与期望由冻结的原始字节及明确编辑跨度计算，不能拿当前 owner 自己生成自己的预期。IME 的多键组字按一次提交意图计数；普通逐键输入按实际事务契约分开核对。模拟故障、系统合成输入、物理人手输入是三种证据，分别标明。

这些是本包功能门；不要为了“全绿”删除失败腿或反复改等待时间。性能如实报告当前虚拟 GPU + x64 模拟环境，不外推物理 Windows 机器，也不从 W1 出图推断 16ms 已通过。慢点先定位最大贡献与可复现负载，不能让一个未定性能问题阻塞所有独立功能。

本包不要求 macOS 的 1GiB／全部 visual 结构编辑／全部生成式面板／UIA 与讲述人／物理多屏／安装签名发布同步完成。这些继续属于目标能力，未实现就留在后续，不拿初包成功宣称三端完全等价。

## 七、原咨询安排（历史；本轮以上方执行规则为准）

执行模型由用户当前工具配置决定。咨询使用独立上下文，不能把长会话里的既有归因当成前提。沿用 [AGENTS 的咨询纪律](../../AGENTS.md#independent-model-consultation)，本包用户新指定的技术顾问为 **`gpt-6.1-sol`**，取代旧模板里的 `gpt-6-sol`；不把口头型号写成不存在的 `slo`。

| 遇到的情况 | 行动 |
| --- | --- |
| 已定方案、语言／API 细节 | 查仓颉技能、SDK 头文件、Microsoft Learn 和现有实现，直接完成；不每个小补丁都花一次咨询 |
| 日常疑难、原因不清、需要独立质疑 | **Pi CLI → `zai-coding-cn/glm-5.3`**，即使执行者本身是 GLM5.3 也另开上下文；不能使用 Pi 默认模型或静默换 flash |
| GLM 无可靠方案的复杂技术故障 | **Codex CLI → `gpt-6.1-sol`，`max`**；先核当前 CLI 和模型支持，保留答案与退出码，不可用要具名记录 |
| 线程／FFI／GPU 资源所有权、文本身份或公共契约存在实质未决问题 | 可直接 **Codex CLI → `gpt-6-astra`，`max`** 聚焦只读架构咨询，不需要先问遍所有模型；已有裁决前提没变就复用 |
| 要替换本节固定平台路线、引入外部 GUI 运行时、另造编辑器或改变数据模型 | 把事实、备选、代价与建议交回本指导线程；执行者不自行改变目标。用户夜间未回复不是批准，其余独立工作继续 |

Pi 调用使用新问题文件；先在该目录准备 `request.md`，下例路径按实际问题替换，并保存真实退出码：

```bash
consultation_dir='artifacts/windows-pharos-20261005/consultations/ime-ownership'
/Users/jiangxuanyang/.local/bin/pi -p \
  --provider zai-coding-cn --model glm-5.3 \
  --no-session --no-context-files --no-extensions --no-skills \
  --no-prompt-templates --no-themes --tools read,grep,find,ls \
  --system-prompt '只读技术咨询。只查问题所需文件，不修改、不构建、不操作桌面。质疑已有归因，给区分实验、机制方案和验收反例。' \
  @"$consultation_dir/request.md" > "$consultation_dir/answer.md" 2> "$consultation_dir/stderr.log"
consultation_rc=$?
printf '%s\n' "$consultation_rc" > "$consultation_dir/exit.txt"
```

Sol／Astra 沿产品 [AGENTS 的 Codex CLI 只读模板](</Users/jiangxuanyang/Desktop/Pharos Mark/AGENTS.md>)，Sol 型号改为 `gpt-6.1-sol`，使用精确新问题的输入文件、`read-only` 和 `max`。不要启动顾问改代码或操作虚拟机，也不打印凭据。

问题包只放：目标与不变量、当前精确版本、最小失败、相关代码／diff、已尝试假设及原始结果、需要区分的方案。要求顾问检查归因而非赞同现有结论。答复不是验收；按反例和正常编辑器验证。

普通问题两次实质修复无进展必须咨询；核心机制第一次实质修复失败后不盲试第二方案。首次咨询和一次有新证据的追问仍无可靠方案，就集中交回该问题并继续独立工作；不更换模型后清零失败累计，不把夜间时间消耗在同一试错圈。成批、重复、可复核的日志分类可优先 `laya-ask`，它不能替代查阅、根因分析或实际验收。

## 八、执行节奏与最终报告

先把控制通道变得可信，同时厘清共同源码与平台边界；随后连续完成框架与编辑器接线，最后做一次冻结版本的集中消费。独立咨询等待期间推进其他必要工作。已有有效绿色证据按影响复用，不重跑无关 H、E 全套，也不接着扩 H round18 验证器。

桌面、同一构建 target 与高风险共享文件串行使用。只收回本包拥有的实例、worker、端口和临时数据；不批量杀 WindowsTerminal／conhost／explorer，不关闭用户编辑器或虚拟机。若操作剪贴板，开始前重新核实有效备份，恢复前核序号，用户已改动就保留现值并如实报告。

在现有状态文档中只短更 Windows 当前状态，保留 E/H。完整原件建议集中到 `artifacts/windows-pharos-20261005/`，一个证据索引关联源码清单、构建、输入、协议、owner、文件、截图、错误／恢复与成本，避免每天再建一套治理台账。旧 RED 原件不覆盖。

最终集中回答：

1. 现有 Pharos 在 Windows 实际能做什么，正常启动命令及可运行产物在哪里。
2. 本包复用了哪些共同模块，新增哪些 Windows 适配；是否产生必须回归 E/H 的公共改动。
3. 上述固定门逐项 PASS／FAIL／BLOCKED／NOT_RUN，附最终二进制身份与原始证据，不只报测试总数。
4. 人→Agent→人和保存重开的完整字节／版本，以及范围、组字、失败保旧的判别结果。
5. 当前环境下的成本原数、最慢环节和未证明的能力；不按代码行数或咨询次数宣称进度。
6. 自有资源清理和并行写集保护情况；未完成项给出具体原因和下一落点。

交付完成前保持连续推进，不把每个 A–F 小节另拆成等待用户确认的任务。若到达真实依赖阻塞或需要改变固定方向，报告该问题的最小材料和已完成部分，不能把整包改名为完成。
