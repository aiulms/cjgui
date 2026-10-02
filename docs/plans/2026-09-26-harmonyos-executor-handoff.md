# CJGUI 鸿蒙后端：无上下文执行工具交接

更新日期：2026-09-28。用户已授权接续实施。本文件将当前整包任务整理为新工具可直接执行的交接说明，不另立阶段或维护第二份进度账。唯一当前状态仍见 [ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md)，详细历史和原始判据见[阶段任务页](2026-09-25-harmonyos-backend-first-chain-prompt.md#review5-current-package)。

**执行要求：必要返工与新框架能力一起推进，持续完成整个工作包。等待编译、Codex 咨询、子代理或其他进程时，优先推进真实独立、尚未阻塞的任务；客观依赖或资源互斥使其他工作无法安全推进时，才等待。** 具体操作规则见第十节。

<a id="review9-current-package"></a>
## 第九次指导复核：统一资源生命周期，完成当前可达项（2026-09-27）

**当前结论（2026-10-02）：**S1样式反例修复与Pharos共享类接线保留；本次生产函数离线反例仍证实旧end误寄、绑定幂等漏epoch、安装挂起/假成功，双owner总门可接受错区间和误删。thermo尚未调用新生命周期。按[当前R1–R4整包](#h-source-preview-followup-20261001)接续，S1–S4未整体收口；旧N1–N4不重跑。

<a id="review9-handover-review"></a>
### 收尾限域复核：修接续入口，保留能力门控待验（2026-09-27）

**接受范围。** 原 §E 已允许真正依赖平台能力的实测单列待验，无须反复请求同一裁决，也不以用户未回复作为批准依据。本次读取交接页、原始 JSON/输入清单和入口源码，未构建、部署或操作设备，未全面重验 A–D。`rev9h-verify`/`rev9j-exact-mutation` JSON 为 75 项、64 PASS/11 BLOCKED/0 FAIL；73 项、62 PASS 是 `rev9i-cneg3` 的较早证据，保持版本对应。`rev9h` verify/thermo 的平台指纹、host/renderer 源输入一致；输入代理 T0–T6 有 PASS 原日志，真实 marked range 与可见草稿仍未获对应验收。保留这些交付，不能用它们替代四项真实平台待验。

**收尾原要求（本轮已完成）：**

1. **一键入口路径与部署顺序。** `run_pending_real_device_checks.sh` 的 `HERE/../../../..` 实际指向仓库内 `runtime`，使 LAB 和 DEST 都错误；按脚本位置或明确仓库根解析，并断言目标存在。能力判定目前发生在部署前，读取设备已安装应用，未安装/旧 HAP 的结果不能归因于待验产物。使用明确 target、当前产物身份和本轮启动实例建立能力见证；复用 `build_and_run.sh` 已有安装/启动流程，消除之后再次卸载安装造成的状态破坏。工具/部署/启动失败或证据缺失，与已确认 KnownShimNoRef 分开报告；能力判据仍以安全引用/等价所有权及真实发布事实为准。
2. **结果与归档不能吞失败。** 当前 lifecycle 管道失败后继续，clipping 显式 `|| true`，最终 echo 可使入口返回 0；归档还缺 clipping JSON/raw，旧公共 evidence 文件可能被再次复制。显式收集每步退出码及本轮结果身份，始终保存新鲜原始日志和两探针 evidence/raw，再按 FAIL 优先、其后 BLOCKED、完整通过才 PASS 汇总并返回对应非零/零状态。保留现有可识别 BLOCKED 码即可。一键入口不包含的人工/IME 项继续在登记表待验，不把脚本成功等同于四项全部关闭。

**原收束判据。** 用不访问设备的受控命令替身覆盖任意 CWD、部署/启动失败、能力不足、两探针失败、缺失/旧证据和全部通过，并核对出口及归档。原生命周期、输入与三产物基线按未变范围复用；当前设备能力无变化时停止重复复检，SDK、镜像或设备能力变化后再执行真实待验链。

**收尾实施与离线判别。** 入口以脚本位置解析仓库根，要求 `--target <hdc connectkey>`，在唯一新 `run-id` 目录中先做命令面预检，再由既有 `build_and_run.sh` 对指定设备构建、安装、清日志、启动；能力检查只读本轮 HAP 哈希、安装回执、启动断言、PID 和该 PID 的能力/发布日志，不重启或二次安装。两探针均经同一目标设备运行，分别记录退出码、stdout/stderr、当轮 evidence/raw 与实例标记；FAIL 优先于 BLOCKED，完整通过才 PASS（出口依次为 1/42/0）。`python3 runtime/cjgui/platforms/ohos/scripts/test_run_pending_real_device_checks.py` 的离线替身覆盖任意 CWD、设备工具/部署/启动/产物身份错误、KnownShimNoRef、缺失或旧能力、双探针失败、缺失或旧 evidence、FAIL 优先和全通过；旧入口在任意 CWD 的 RED 反例失败，修后 7 个用例通过。此处只证明接续入口的判别；**四项平台实测仍待能力变化后逐项审阅**，人工/IME 不因入口成功而关闭。

**追加限域复核：TCP 转发接线（2026-09-27）。** 指导独立重跑先前离线 7 用例，全部通过；当时未连接设备、部署或重跑平台验收。其后发现 lifecycle/clipping 两探针固定连接 `127.0.0.1:17856`，入口没有建立到目标设备 7856 的转发。旧映射可能指向另一设备，原替身也未建 socket，不能证明探针走本轮设备。

只补这一条交接机制：在能力确认后、探针运行前，为明确 `--target` 建立并校验本轮转发，记录目标/本机端口/设备端口和创建结果；优先使用独立本机端口并传给两个探针，复用现有设备 7856 服务。端口冲突或转发失败具名非零，不能默用既存映射；退出/失败时只回收本轮所有的转发。探针重启应用后继续以新 PID/token 确认连接归属，不能用启动前实例代替。离线增补“无旧转发也可连”“转发失败”“旧映射/占用不被误用”“两探针使用所传端点及自有清理”判别，其中至少一条用本机受控 socket 消费真实连接配置，不再只让 fake probe 打 PASS。既有七项与 A–E 原证复用；设备能力未变化时仍不复检。此项是验收工具接线，不扩张宿主/renderer 实现。

**先前接线结果。** 入口为指定 target 选独立本机端口，确认端口空闲、建立 `tcp:<local> → tcp:7856` 并核对全局转发表；端点传给两个探针，归档创建回执、双端口、实例 PID/token、socket 连通与清理结果。探针重启后读取清日志所对应的 PID/token，并拒绝与启动及先前探针实例重用。离线 `test_run_pending_real_device_checks.py` 当时 **14/14 PASS**：受控本机 socket 对两探针真实回包，去掉转发的旧入口变异使两探针均连接拒绝。该结果未覆盖下述创建归属竞态；四项真实平台能力及人工/IME 待验不因入口离线通过而关闭。

**TCP 指导复核与唯一返工（2026-09-27）。** 指导独立运行现有离线测试 **14/14 PASS（38.020s）**，核对两条生产探针确实把传入端点交给 `BoundedExchange`；本机 socket 用例运行的是探针替身，不代表设备协议/平台验收。新增临时确定性反例在端口预检后模拟另一进程建立相同 target/本机端口/7856 映射，本轮创建返回 32；真实入口仍因 `FORWARD_CREATE_ATTEMPTED=1` 和三元组相同执行 `fport rm`，删掉他方映射。原始结果见 [summary.json](/private/tmp/cjgui-forward-ownership-race-enyb_3ux/summary.json)，夹具和命令记录在同目录；入口源码 sha256 为 `8c3a4c1638b6e4e1043e4ace1744efdad20b9f67f2aa170896aaf9790cddfa6f`。这是受控本机反例，未连接设备。

只修转发的创建/清理归属：区分尝试中、确证本轮创建成功、明确失败和结果未知；失败或无成功回执时，端点相同不足以授权删除。创建期间收到信号，应先有界收取并固化创建子进程的终态/回执；仍不能确证归属则具名 FAIL、保留不确定映射及诊断。将上述抢占反例纳入现有测试，断言他方映射存活且零 `rm`，并保留确证自有映射的正常/异常/信号清理。复用 14 项与 A–E 原证，只补受影响离线判别；本项不涉及宿主/renderer，也不触发无变化设备复检。

**返工结果。** 创建由有界监督进程归档子进程 PID、退出码、stdout/stderr 与超时状态；仅 `rc=0`、明确 `Forwardport result:OK` 且无 `[Fail]` 才取得本轮清理权，退出时仍核对 target 与双端口。创建期信号先收结果；明确失败、缺回执、超时或监督进程失联均具名失败并保留不确定映射。相同端点抢占反例修前 `create rc=32 / rm=1 / 他方映射消失`，修后 `rc=32 / rm=0 / 他方映射存活`；确证自有映射在正常、探针失败及信号退出时清理。离线全套 **19/19 PASS**，追加工具启动失败反例及成功路径定向 **2/2 PASS**（现有测试共 20 项）；未连接设备，A–E 与四项平台待验状态不变。

**指导收口（2026-09-27）。** 限域核对监督进程、归属发布与退出清理源码，并查阅执行线程原始输出：同一抢占反例当前为 `rc=32 / rm=0 / mapping_survived=True`；抢占及两种创建期信号用例通过，监督失联用例在纠正测试名称后通过。本次未重新运行测试、构建或设备操作，未发现阻碍本项收口的问题。转发归属返工按此范围接受；既有证据复用，四项平台验收仅在能力变化或用户另行安排后接续。

### 华为模拟器真实后端接续（2026-09-27）

用户现以明确指定的华为 Pura 90 模拟器 `127.0.0.1:5555` 作为本阶段主要功能与生命周期环境。DevEco/SDK 26.0.0.105、API 24 镜像 6.1.0.117 下，旧 `KnownShimNoRef` 来自 HAP 私有目录中 SDK 的 `libnative_window.so` 链接占位库遮蔽系统实现，并非模拟器整体缺失原生引用。打包现排除该占位库，闭包校验禁止它进入 HAP；[正常产物运行日志](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/sim_real_normal_final/runlog_sim_real_normal_final.txt)对应 HAP SHA `f76af0dd…`，从系统 `/system/lib64/chipset-pub-sdk/libsurface.z.so` 取得 `NativeObjectReference rc=0` 并真实提交首帧。原 TCP 归属返工保留。

四项实测按原票、PID 和当轮产物归档：① [生命周期 C2/C5](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/sim_real_lifecycle_rev3/lifecycle.stdout.log) 证实同代 Create/Flush 持有期真实卸载、拒绝后续使用和一次引用归还；② [UI STOP HOST C7/C8](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/sim_stop_tickets_ui_rev1/verification/surface_stop_tickets_evidence.json) 在排队/提交票仍持有时发出同 PID 停止请求，C7 原票取消一次，C8 原票提交后结算并 ACK 一次，两个实例均 `stop settled`，重开写读通过。此项修正了宿主把正常窗口关闭判成 failed、提交票关闭后无人查询/ACK，以及旧探针 owner 路由关闭晚于票据终态的问题；③ [严格像素与裁剪证据](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/sim_native_ref_rev2/verification/clipping_evidence.json) 覆盖画面、裁剪边界、触摸命中和 owner 精确更新；④ [系统 IME 实测](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/ime-real-20260927-current/EVIDENCE.md) 覆盖焦点、可见未提交草稿、拼音/英文提交、选区及替换，marked range 与取消回调尚未取得。独立 ArkTS [最小对照](../../labs/ohos_ime_preview_control/artifacts/2026-09-27-control/RESULT.md) 在相同镜像/小艺输入法也只见提交回调及空的 `PreviewText` 哨兵；该组合的组合范围/取消仍需上游反馈或新镜像对照。模拟器功能证据、物理设备性能与上架审核分别记录。

本次受影响的离线轨迹/宿主测试 **19/19 PASS**、`cjpm build --skip-script`、测试变体与正常 HAP 构建/闭包/首帧均通过；[测试变体](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/sim_stop_ui_build/startup_assert_sim_stop_ui_build.txt) SHA `87fcff56…`。旧整包矩阵的失败记录保留为历史，不用此前宽松 C7/C8 判据替代这次原票证据；当前继续项是 IME marked range/取消能力的版本化复现与反馈，物理设备对照及发布审核另行进行。

<a id="h-input-consumption-next"></a>
### H 线系统输入能力与正常消费包：已交付（2026-09-27）

**指导结论与取舍。** 本次限域读取正常产物日志、STOP 原票 JSON、独立 ArkTS 对照及打包清理路径，未构建、部署或操作模拟器。接受上述真实系统引用/首帧、停止终态及有出处的生命周期/裁剪结果；打包已处理历史占位库残留。C7/C8 两个停止实例 PID 为 2299/5918，随后 `reopen_identity` 为新 PID 6336，因此本轮只证明重新启动后业务恢复；早前同 PID 5700 的证据保留在其原产物范围。独立对照只证明当前 SDK/镜像/输入法及该接入方式下未观察到 marked/cancel，尚不能认定整个模拟器不支持或上游存在缺陷。

下一步优先把系统输入的能力边界和人/外部接续做成可复用框架消费，不在原生命周期矩阵反复循环，也暂不整批追平 F 线效果快照。仓颉 owner、现有代理注册表、范围桥接、公共传输和 thermo 独立消费者继续复用；ArkTS 只承接平台输入，通用身份/范围/事务归框架，字段规则归领域应用。E 线 macOS 文本会话仍在推进，H 复用已稳定值契约，跨线差异先对照，不另造一套通用会话或改写 E 的在途文件。

**A．有界查明平台组合事件。** 从现有 `ohos_ime_preview_control` 出发，对照当前官方 SDK 声明和官方样例，核实 `enablePreviewText`、实际输入路径、`PreviewText` 的值/范围/空哨兵及取消语义；先判断候选留在输入法内部是否本就不向应用发布预编辑。只有找到可区分的新条件才补一次对应实验，复用已归档的键入/取消原证。若正确配置的独立控件仍无回调，交付精确的版本化观察与可重现材料，继续 B/C，不以重复重启或延长等待追逐同一结果；上游反馈材料准备好即可，对外发送按用户授权。

**B．框架统一消费与能力描述。** 核对系统全文草稿、预编辑片段、marked 范围、已提交文本分别代表什么，沿既有代理入口接线；明确 UTF-16 与框架字节范围转换，空范围、缺范围及无效哨兵分开处理。当前 `onChange` 的 `previewText.offset ?? 0` 和 `previewRange` 参数只传预编辑片段必须按实际桥接契约核对，不能把缺范围默认为正文起点。补缺陷时先建立具名反例，覆盖非零位置中文/emoji 选区替换、旧挂载回调、外部换版与未提交草稿。若平台确实提供组合事件，接通提交/取消且 owner 仅按既定事务推进；若未提供，保持普通草稿/提交可用，并通过既有发现或状态入口准确说明已支持及尚未观察的能力，不能由空 preview 推断一笔组合取消。可注入的框架组合反例与系统实测分别记账。

**C．正常应用的连续消费。** 设置应用与已有 thermo 独立消费者共用修后的代理/范围机制。按影响复用既有通过项，只补一条同实例连续链：系统输入与非空选区替换→可见草稿→提交及公开 owner 精确读回→外部授权换版→画面与新输入上下文校准→拒绝旧回调→继续编辑。使用正常 HAP；verify 只负责可控交错。额外补当前真实引用后端的一次同 PID STOP→全零→RESTART→新 appInstance→真实首帧及授权写读，已存在同版本原证则直接引用；新进程启动单独报告。若这条链发现缺陷，修公共宿主/仲裁机制，不重开其他已通过矩阵。

**D．整包交付与推进方式。** 变更汇合后只跑受影响的反例、构建和正常消费者链，冻结对应源码/HAP/SDK/镜像/输入法身份。报告区分实现、系统实测、受控反例与待验，更新本节及 ACTIVE 的短状态即可。复杂实现/根因用 `gpt-6-sol` 聚焦只读咨询；范围归属、组合与外部事务冲突或架构方案未定用 `gpt-6-astra`，按当前可用次高档执行；Laya 辅助比较，结论以源码和实验为准。等待编译或咨询时推进独立工作，同 target 构建及模拟器操作协调串行，保留 E/F 改动，未经要求不 stage/commit/push。

**本包实绩。** 当前 DevEco SDK `26.0.0.105`、模拟器镜像 `6.1.0.117`、小艺 `BASIC_MODE 1.2.1.307`：按 [TextInput 预览声明](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-text-common) 开启 `enablePreviewText(true)` 后，[独立 ArkTS 对照](../../labs/ohos_ime_preview_control/artifacts/2026-09-27-control/RESULT.md)与两款正常应用仍只观察到输入法内部候选、提交时的普通 `onChange`/空 `PreviewText`，未收到应用 marked range 或独立取消回调。框架代理现传完整草稿，将有效的非空 `PreviewText` 范围按 UTF-16 标量边界单独传递；缺失、空值、`-1` 不冒充取消。宿主在外部 owner 换版时轮换上下文，旧挂载回调拒绝，能力投影区分可用的草稿/选区与有条件但未观测的 marked/cancel；离线反例 14/14 PASS。

正常 HAP 中，[设置同实例人→外部→人](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_input_settings_normal_v3/h_input_runtime_identity.txt)与 [thermo 独立消费者同实例链](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_input_thermo_normal_v1/h_input_runtime_identity.txt)均有系统键盘、公开 owner 版本逐次读回、外部换版后的新上下文和继续编辑。系统全选的非空范围与提交前可见草稿另在当前正常 HAP 验证：[设置 `0→1`、选区 `[0,4)`](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_input_settings_selection_normal_v2/summary.json)及 [thermo `3→4`、选区 `[0,9)`](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_input_thermo_selection_normal_v1/summary.json)，两者提交后精确为 `选区替换H🚀`。设置首次截图揭示键盘改变同代 Surface 几何时草稿重绘被跳过；同代重绑现保留 native 引用并立即重绘，[修后草稿画面](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_input_settings_selection_normal_v2/draft.jpeg)与 owner 未提交读回对应。

[当前真实后端同 PID 探针](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/h_same_pid_restart_v3/verification/same_pid_restart_evidence.json) PASS：PID `12810`、HAP SHA `db3e93bc…`，实例 1 STOP 后 owner/renderer/票据/引用全零；实例 2 从仍有效的 UI 挂载事实取得**新的系统引用**、generation 2、新 token 与真实首帧，公开授权计数 `10→11`、版本 `0→1`。NEG4 夹具不再抹去真实挂载，引用反例计数现在实际拦截并计数平台调用。探针日志顺序与 hilog 系统行重排的假失败已由离线反例修正（同 PID 10/10、正常选区 7/7）；失败原件仍保留。两款正常 HAP 与测试 HAP 的构建/闭包/真实首帧、`cjpm build --skip-script`、本包离线 14+10+7 项及 `git diff --check` 通过。剩余平台项是 marked/cancel 应用回调在能产生预编辑的输入法/镜像或上游答复下复现；当前未观测不等于模拟器整体不支持。物理设备性能及发布审核各自单列。

**本包指导复核。** 限域核对上述 thermo 选区 JSON、同 PID 重开 JSON 与 renderer 的 UTF-16 预览入口：证据支持全选范围替换、STOP 全零、新实例引用及写读，源码区分完整草稿和 marked 元数据并检查代理对边界。未发现阻碍按此范围收口的问题；本次没有构建、重跑测试或操作设备。全选替换实测不能扩大为所有中间选区组字均已实测，marked/cancel 边界继续保留。

<a id="h-generated-consumption-next"></a>
### H 线运行时生成式界面与双消费者（2026-09-27）

**目标与依据。** 让外部系统在运行中的鸿蒙应用里提交新的界面结构，人能在该结构中操作真实字段和动作，外部再读回同一个 owner。开包时平台快照已有 `CjguiGeneratedUiStructureHolder`、组件注册与共享 `GET_GENERATED_UI_*` 协议，设置和 thermo 正常入口尚未接通 generated provider 与窗口 region；本包已补齐该消费缺口，结果见本节末。遵循[生成契约](../core/AI_NATIVE_UI_SEMANTICS.md#运行时生成与修改界面)，沿用仓颉组件→布局→场景→XComponent 自绘，以及现有 owner/TCP/输入代理。保留已通过的输入和生命周期资产，推进运行时结构消费；本包不以追平所有 macOS 视觉效果为前置。

**A．接通共享生成能力与后端支持范围。** 先以当前 OHOS 快照中的 holder/catalog/provider、macOS 已有正常 region 消费方式和两款鸿蒙应用的真实构建入口为依据，直接实施一条纵向链。首个切面采用后端可实际消费的纵横布局、文字、字段编辑器和动作按钮，设置至少包含名称字段与现有业务动作；thermo 使用自己的字段和规则。公开发现由共同注册定义与后端能力派生，属性、单位、范围和绑定来源一致；未知组件/字段/动作及尚未支持的属性具名拒绝，防止接受后静默丢弃。后端限制对手写与生成保持一致，不能另建 AI 专用业务副本或把生成限定为预写模板切换。

通用缺口修框架权威源，并通过现有同步机制进入平台快照和消费者；应用仅声明自己的字段、动作及布局。按依赖最小同步共享实现与配套 ABI/头文件，保留 H 已验证的平台适配，不整批覆盖 E/F 的在途源码。若生成所需接口发生漂移，先查既有实现与咨询裁决，迁移真实消费者，避免在 OHOS 复制一套生成器。对仍未接入的效果明确发布支持边界。

**B．窗口拥有的区域与真实接受事务。** 每个窗口/应用实例持有自己的 region、holder、绑定和路由；公共请求由原 owner 队列处理，沿既有 prepare/commit/rollback 进入正常窗口刷新。候选入队、结构接受、实际场景提交与呈现分别按真实事实回报；异步渲染失败/关闭时，候选终态、结构版本、accepted 节点和路由必须一致，旧界面保持可操作。复用公共候选 token/端点身份、快照与观察客户端，不把接收请求回包当作场景接受。结构提交不隐含修改 owner 或执行动作；成功接受结构版本恰好推进一次。Surface 未就绪期间保持原领域服务和停止入口可用，生成请求以真实 pending 或具名拒绝表达，不能使启动重新互等。

补与本包变化直接相关的判别反例：非法结构/未知绑定、旧结构版本、一次受控渲染拒绝、同 key 换绑后的旧事件、窗口关闭后的旧票。分别断言 accepted 结构/业务版本/路由及后续合法提交；后端失败通过测试接缝注入，正常消费走 normal HAP。原生命周期矩阵按未受影响部分复用。

**C．设置与 thermo 的正常消费闭环。** 使用同一公共客户端及本轮明确 target/端口/实例，正常 HAP 运行期间从外部发现能力并提交结构。由 accepted 身份、实际场景和截图确认新增控件，然后真实触摸该控件、系统编辑并提交，公开读回精确 owner 值和版本。接着外部授权改值→画面及输入上下文校准→人继续编辑；在同 key、同绑定条件下重排结构，保留草稿/选区及输入归属；非法候选后旧面板继续编辑；删除生成区域后手写区域和 owner 仍可用。生成控件事件必须回到原业务规则，不能用外部写入代替触摸/输入的证据。

先把设置完整链打通，再由 thermo 消费同一公共机制，应用新增业务规则或绑定只在共同定义中声明。系统输入复用上一包草稿/选区接缝，marked/cancel 按原版本边界记录。保留一次仅获得公开发现与业务目标的真实模型消费：模型生成并修改允许范围内的结构，通过公共通道接受后由人/工具驱动系统输入接续；原回复、公开拒绝及有界纠正分别保存，脚本提交与真实模型证据分开。模型暂不可用时继续其他实现，单列该项，不把脚本命名为模型验收。

**D．有界成本、同源交付与执行方式。** 复用描述的字节/深度/节点等预算；普通字段输入与空闲观察不重新解析完整候选。正常消费者分别记录无生成区、静态生成区、一次结构修改的解析/构建/提交计数及原始耗时；固定版本空闲采样应收敛，公开字段请求保持可服务。遇到超时先区分排队、布局/渲染与平台等待，再按证据修机制。

整包只做一轮受影响汇合：必要反例、`cjpm build --skip-script`、两款正常 HAP、公共客户端真实消费、HAP 闭包与源码/客户端/SDK/镜像身份清单。共享应用或核心发生变化时追加对应 macOS 同源回归，其余基线复用；测试变体与正常产物证据分开。只更新本节结果和 ACTIVE 短状态。复杂技术问题以 `gpt-6-sol`、架构/算法/事务归属以 `gpt-6-astra` 做聚焦只读咨询，按可用次高档；Laya 只作参考。等待构建/咨询时推进独立实现或材料，互斥构建及模拟器操作串行。连续完成 A–D，保留 E/F 并行改动，未经要求不 stage/commit/push。

**本包结果（2026-09-27，模拟器 normal HAP）。** 公共 `CjguiGeneratedUiWindowRegion` 接通 holder/catalog/provider、窗口 scene 接受/回滚、owner 修订与事件路由；设置和 thermo 分别声明本业务字段、动作和规则，OHOS 平台快照按依赖同步。候选票在实际场景接受后才终结；非法字段 `unknown_field`、旧版本、同 key 动作换绑旧事件、关闭旧票有判别测试。独立 `verify-transport+test-gates` 设置 HAP（SHA-256 `935d6fc0b43d3188035b12d3e90b8d3a9922eca2f2833e6c7c38978a7ca1573a`，PID `18136`）经原生 `GATE_REJECT_NEXT` 使 region 第二票以 `layout_or_native` REJECTED，旧结构/节点/owner 不变，下一合法候选 ACCEPTED；原帧与重放脚本见[失败注入目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/hgen-reject-20260927/)。macOS 生产窗口的测试专用 native present 失败注入另证同一窗口回滚链（[前一设置运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/hgen-settings-20260927/)的 `native_generated_commit_probe.log`）；两种测试变体均不冒充 normal HAP。目标 `127.0.0.1:5555`，镜像 `emulator 6.1.0.117(SP37DEVC00E115R4P11)`；最终正常设置 HAP SHA-256 `bd1939f3d87badf4707a4015dc4357c692917880077242ec44799bd8d8de443f` / PID `22694` / 自有转发 `17954→7856`，正常 thermo HAP SHA-256 `42735c72310da63fa86372216298c2f83d0ab181e3f2c826924661ba93d866ea` / PID `27809` / 自有转发 `17952→7857`。两包平台指纹同为 `213fbd65465f7fa8695b2461017f2567d279fdd5828215460fb2999da68ba8e1`，构建、HAP 闭包及正常启动通过；SDK、源码、产物及精确清理回执见 [最终设置运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/hgen-settings-aligned-20260927/) / [thermo 运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/hgen-thermo-20260927/)中的 source manifest 和清理文件。

真实 Sol 模型仅凭公开发现与业务目标生成候选，并在看过实际截图后修订颜色/字号；原回复与两次接受记录在[前一设置运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/hgen-settings-20260927/)，修订候选又在同源的最终设置 HAP 上经公共端点接受并显示。最终实例中，生成按钮真实触摸使计数 `10→11`；生成名称框经系统输入提交 `AlignedLive` 后 owner 精确读回版本 `2`。同 key/同绑定重排 `v1→v2` 时草稿 `AlignedLiveX` 与系统键盘仍可见，继续提交使 owner 版本 `2→3`；非法字段候选被拒后，旧生成按钮仍使计数 `11→12`。外部授权把名称改为 `AlignedExternal` 后，生成框校准并经系统输入继续编辑为 `AlignedResumed`；空纵向根移除生成控件后，手写按钮仍使计数 `12→13`。thermo 同机制在真实画面中生成备注框/升温按钮，触摸使温度 `22→23℃`，系统输入使备注 `ThermoLive` 精确读回；外部改值后继续编辑、同 key 重排亦被接受。原始票、协议回包、UITest、IME 日志和截图见两最终运行目录的 `submit`、`generated_gui_input`、`external_continue_gui`、`reorder*` 与 `clear_generated`；截图已逐张核对。thermo 候选为脚本构造，与真实模型证据分开。

成本原数见两最终运行目录的 `generated_performance.json`：设置无生成/静态/改版三相位累计 `decodes/builds/commits=0/1/1、1/3/3、2/7/7`，thermo 为 `0/1/1、1/3/3、2/9/9`；每相位两次相隔 200 tick 的空闲采样计数及纳秒累计相同，字段编辑期间解码计数不增加。原始纳秒累计和客户端往返耗时保留在该文件与 `exchanges.jsonl`；例如最终设置首次提交/票终结为 `16.458/15.319 ms`，thermo 为 `26.784/15.930 ms`，只表示本次模拟器及 TCP 路径。受影响验证：核心 `cjpm build --skip-script`、设置 7/7、thermo 2/2、核心 owner 修订定向 2 项、macOS 生成消费者 34/34、macOS native 与鸿蒙 test-gates 两条生成事务失败注入 PASS、共享 Python 客户端 70/70、正常消费离线 4 项、GUI 消费离线 4 项、native 重排接缝 4/4、`git diff --check` 通过。当前 marked/cancel 回调仍按既有 SDK/镜像/输入法组合保留待验；物理设备性能和发布审核另列。工作区 E/F 并行改动原样保留，未 stage/commit/push。

**生成式包指导限域复核。** 已抽查两款 normal HAP 的生成控件输入/owner 原证、测试 HAP 的拒绝第二票与恢复、两份平台 manifest，以及公共 region 的 commit/rollback 接线；未发现阻碍按上述范围收口的问题。两份性能 JSON 的三个阶段各两次空闲采样计数与耗时累计一致；提交/等票时间是分段客户端往返样本，不能当完整输入到画面时延。此次未构建、操作设备或重新看图，模型与脚本候选、normal 与测试 HAP 的证据保持区分。旧生命周期和生成消费基线按影响复用。

<a id="h-image-resource-next"></a>
### H 线共享图片资源与鸿蒙实际绘制（2026-09-28）

**目标与原缺口。** 执行对象鸿蒙 H 线，目录 `/Users/jiangxuanyang/Desktop/cangjie`。本包开始前两领域已能消费生成字段和动作，但 `platforms/ohos/host/ohos_renderer.cpp` 的 `set_composable_scene_node` 拒绝图片节点，`prepare_composable_image_resource` 与状态查询直接返回错误，故正常应用不能复用公共图片能力。优先补共享资源的实际平台消费；更复杂效果、滑动/长列表等后续按实需接续。F 的 PNG 剪贴板/拖放通用交换与 H 的声明图片显示复用相同资源身份；E 的编辑器插图与持久化仍归产品。

**复用与责任。** 复用 `CjguiGeneratedUiImageResourceSpec`、资源 key/version、accepted 绑定持有、窗口图片状态和观察修订，以及刚交付的 `CjguiGeneratedUiWindowRegion`。核心仓颉持有声明、预算策略、事务和业务；鸿蒙适配器调用当前 SDK 的公开解码/绘制服务，管理平台对象和线程约束。借鉴已验证的 macOS 图片路径的版本/缓存/退役机制，按平台 API 实现资源所有权，不复制 Metal 对象或另建 ArkTS 图片 UI 树。先查本机 SDK 头文件、官方说明与现有 OH_Drawing 路径，普通 API 接线直接做；异步资源/Surface 退役方案不明时先向 Astra 提供精确边界咨询。

**A．有界 PNG 资源后端与真实状态。** 首包沿当前公共目录的 PNG、`fit/fill` 和版本声明实现。HAP 携带每消费者自己的两张可判别 PNG，由应用声明受控资源定位；框架负责映射到应用沙箱资源或其所有的缓存，生成描述仍只引用已注册 key/version，不接受任意外部路径。明确像素格式、alpha 与色彩处理，布局测量/绘制/裁剪沿同一几何；通过平台服务解码，不另写 PNG 算法。

图片准备进入有界队列/缓存，耗时读取和解码不在 UI 回调、owner 长临界区或 Surface 租约里执行；绘制对象按当前 SDK 线程归属发布、使用与销毁。具体同步/异步切分应以 API 契约和实测决定，不能把潜在阻塞简单搬入另一个全局锁。按既有核心资源契约发布 unrequested/loading/ready/failed；完成/失败会请求必要刷新并更新公开资源状态，固定状态不持续申请帧。写明编码字节、尺寸/像素、解码内存、缓存/在途总额及任务数量上限；大小运算先检查溢出，读取/解码增长前尽可能准入，平台不可控临时内存和取数成本单列测量。损坏、超限、读取失败具名拒绝或失败回退，旧 accepted 界面可继续使用。

**B．资源身份、候选事务与退役。** 同一 key/version 的内容身份不可变，目录换版/移除按已有核心契约处理：新候选按当前目录校验，旧 accepted 引用在被替换前继续存活，普通 refresh 不因目录变化清空界面。candidate/accepted/解码在途/实际绘制分别持有可解释的引用，失败候选及重复 build 只回收自己的持有。同请求多节点共享时能复用；一个节点移除不误释放其他节点资源。

异步完成绑定资源身份与请求代次，Surface 重挂载、场景拒绝、旧资源替换、STOP/重开都不能让旧结果覆盖新图或使用退休对象。解码数据与 Surface/GPU 对象的寿命分开，只有平台要求时才因 Surface 改代重建相关对象。集中补四组确定性反例：v1 在途→v2 接受→旧完成；候选 native 拒绝→保旧→合法恢复；同资源重复 build/多节点持有→逐个移除；加载中停止→收敛→同 PID 新实例加载。复用已验证的 Surface/票据仲裁与测试接缝，只扩图片交错，不重跑所有旧生命周期排列。

**C．两款 normal HAP 的手写/生成共同消费。** 设置与 thermo 各以一份本领域资源声明供手写图片、公开发现和生成图片节点引用。通过真实公共客户端发现并提交包含图片的生成结构，核对 candidate 终态、accepted key/version、公开 resource_state 和真实截图；图案/透明像素与宽高比可判别，覆盖 fit、fill、父裁剪和一次真实窗口/Surface 几何变化。真实按钮切换资源版本后，旧 accepted 仍显示旧图；旧版本新候选被拒；合法新版本候选接受并显示新图。期间生成编辑器仍能系统输入并精确读回 owner，图片刷新不偷换字段绑定或草稿。

每消费者都保留自己的正常产物、输入/画面/读回证据；测试闸门只证明受控 loading 与迟到完成，正常应用若加载太快读不到 loading，如实记录。一轮只凭公开能力与业务目标的模型候选消费可复用上一包既有模型流程，新候选实际引用当前图片资源；模型暂不可用时继续实现与脚本链，模型项单列。手写/生成图片共用 renderer 与资源机制，不能一边走 ArkTS Image、一边走自绘来冒充等价。

**D．响应、交付与导航校准。** 两款 normal HAP 打包实际 PNG，记录资源/框架快照/配套 ABI/host/HAP/SDK/镜像身份；平台依赖逐项区分真实运行库和 SDK 链接占位库，并核对实际加载来源，保留此前 NativeWindow 遮蔽库的负控。核心与平台快照按依赖同步，保留 E/F 的在途实现，不整批覆盖。共享核心或应用有实改时补对应 macOS 同源消费；纯 H 后端改动按影响验。

记录无图片、冷加载、热复用、换版四种真实工作量：读取/解码/资源创建与释放、缓存命中、驻留/在途字节、build/submit、公开请求到 owner/scene 的分段时间。在有图片工作期间连续投递 20 个可识别公开请求，记录每个的成功、排队和接受时间；受控保持实验仅证明可服务性，不与无闸门耗时混算。图片完成后空闲计数稳定，移除/关窗后资源按声明策略收敛，重复循环不无界增长。依据实际热点修队列/缓存/调度或收紧已发布预算，不能以 TCP 往返样本代替渲染性能。

受影响反例、核心构建、两款 normal HAP 与含资源闭包在包末集中验证。已通过的字段/动作、候选事务和生命周期证据按未改范围复用；当前 marked/cancel 边界只在新版本/新触发条件下重查。顺手将 `platforms/ohos/README.md` 的旧阶段导航与能力说明对齐当前交接和真实支持面，简写入口，不复制历史账本。复杂技术用 `gpt-6-sol`、架构/算法/资源归属用 `gpt-6-astra` 聚焦只读咨询，按可用次高档，Laya 仅参考；等待构建/咨询时推进独立任务，同 target 与模拟器操作串行。完成后只更新本节结果和 ACTIVE 短状态，保留并行改动，未经要求不 stage/commit/push。

**本包实现。** 鸿蒙 renderer 现在由受控沙箱路径异步读取 PNG，以系统 ImageSource/PixelMap 解码并在渲染线程创建/销毁 OH_Drawing bitmap；同一 key/version 的手写与生成节点复用图片身份，按 fit/fill 和父视口裁剪绘制。资源上限为编码 4 MiB、像素 4194304、解码 16 MiB、在途 8、记录 64、绑定 256；闲置缓存上限 16 MiB，进程跟踪预算 128 MiB（含入场保留额，不等于实测 RSS）。candidate/accepted、解码任务及 renderer 工作分别持有资源，Surface 代次参与取用校验；release 后触发独立的渲染线程 bitmap 清理，不额外提交帧。核心几何修订改为对真实可见几何逐项混合，避免缩放重排时旧 XOR 值碰撞。设置与 thermo 各自打包两版 PNG，业务动作切版；HAP 闭包拒绝把 SDK 的 ImageSource/PixelMap/Drawing/NativeWindow 和 `libohos.*` 链接桩打包遮蔽系统实现。

**两款正常应用实证。** 最终 renderer/transport 源 SHA-256 分别为 `16ed72ce40089cbffa5027b37b493e9e937936454e9c32f3dbf33add053047fc` / `24cb035ac502e4bb99b33e2104d59ab98b5479c4eb3dfd29fa1db05b222f6e39`。设置正常 HAP `5abd8841…`、PID `13374` 的[原始运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/himage-settings-normal-20260928-r8/)及 thermo 正常 HAP `71d58393…`、PID `16362` 的[原始运行目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/himage-thermo-normal-20260928-r5/)均通过公开发现→图片候选接受→手写/生成真实像素、fit/fill、父裁剪、60%/100% Surface 几何、按钮换版、旧版拒绝保旧、系统编辑与 owner 精确读回；包内 PNG、快照、ABI 与 HAP 哈希、SDK 和镜像身份均随当轮归档。运行时日志显示 ImageSource 来自 `/system/lib64/ndk/libimage_source.so`、Drawing 来自 `/system/lib64/libnative_drawing.so`，闭包检查拒绝链接桩入包。先前真实 Sol 回复的原始候选在同 renderer 的[设置 R5](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/himage-settings-normal-20260928-r5/model_replay_from_r3/)与[thermo R3](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/himage-thermo-normal-20260928-r3/model_replay_from_r1/)重新提交，均接受、ready 并截图；归档标明“模型回复重放”，这不是新的模型推理。正常解码先于公开轮询完成，`loading` 瞬态未观测，加载中输入另由受控闸门检验。

**成本原数。** 最终两包启动首次 v1 的编码字节/读取/解码/bitmap 创建分别为设置 `511 B / 42 / 974 / 3 µs`、thermo `509 B / 48 / 896 / 4 µs`，bitmap 后驻留各 `61440 B`；热复用无新增读取/解码/bitmap，v2 换版分别为 `513 B / 29 / 331 / 2 µs` 和 `513 B / 42 / 463 / 3 µs`，两版同时在场时驻留 `122880 B`、其中闲置 `61440 B`。每款在图片候选提交后 20/20 次公开读取成功，与同 PID/实例中连续 40 张 owner 认领票逐笔归属；设置排队 `1438–14191 µs`，thermo `686–11694 µs`，对应客户端 TCP 往返 `13.496–27.836 ms`、`13.479–26.639 ms`。纯读取不触发 scene，逐笔 `scene_accept_ms=not_applicable_read`；候选接受以独立票终态记录，内部 build/scene 提交耗时尚无同口径计数。原始 40 行 hilog 与 20 行 JSONL、读/解码/bitmap 累计及 idle/在途计数见两运行目录。平台解码的系统临时内存不在进程跟踪计数内。

**交错与退役。** 同一最终 renderer 的设置测试 HAP `55a0ba95…`、PID `26825` 在[受控原始目录](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/himage-settings-test-gates-20260928-r2/interleavings_final/)通过四组：v1 保持完成→接受 v2→释放旧完成后画面仍为 v2；native 候选拒绝保留旧图/owner；双节点共用解码和 bitmap 后逐个移除；加载中系统编辑精确读回、20/20 次公开读取成功，随后 STOP 全零并同 PID 新实例重载。STOP 时图片 `resident/idle/active/reservations/running/queued=0`、`bitmapCreates=bitmapDestroys=3`；重开后新图 ready、`resident=61440 B`、队列零。旧应用实例与新实例的 PID、appInstance、token、HAP 哈希和本轮独立转发均归档。原受控验证脚本对滚动 hilog 前缀误判的失败输出保留，现以唯一 STOP/RESTART 标记按同 PID 判定；测试闸门只是资源交错证据，正常应用的画面/输入以两款 normal HAP 为准。

**受影响验证与边界。** 图片 native 反例 9/9、正常消费归因离线 15/15、测试闸门离线 11/11、HAP 链接桩负控 5/5 与既有 NativeWindow 包装负控 3/3、核心几何定向 4 项、H 几何修订时的核心 `cjpm build --skip-script`、renderer NDK 编译及最终两款 normal + 设置测试 HAP 闭包通过；本轮文档链接与 `git diff --check` 通过。当前模拟器报告 PixelMap alpha 为 UNKNOWN(0)，透明角像素已与父背景按截图核对；色彩/解码系统临时内存和物理设备性能仍需独立量测。两款正常 HAP 的旧版模型候选重放与最终 transport 诊断产物身份分别归档；过渡 HAP 不列为消费证据。自有 TCP 转发结束后 `fport ls` 为 `[Empty]`，E/F 并行改动保留，未 stage/commit/push。

**图片包指导限域复核（2026-09-28）。** 读取设置 R8、thermo R5 的正常消费 JSON、设置测试 HAP 的交错/停止原证及相关源码，并查看 R8 冷态截图；当前 renderer SHA 与归档 `16ed72ce…` 一致。两款各 20 次普通读取全部成功，但资源当时已 ready；加载中可服务性由测试闸门的另一组证据证明。接受上述范围，本次未运行构建、测试或设备。另发现 `Session::imageObservedSerial` 按单调 entry ID 插入，仅会话创建/销毁清空，缓存淘汰未同步回收：像素缓存有界不等于这张历史表有界。此源码缺陷纳入下一包 A；不撤销两款正常消费事实，也不据此重开整个图片矩阵。

<a id="h-touch-scroll-next"></a>
### H 触摸包：图片观察记录回收、触摸滚动与焦点 reveal（2026-09-28）

**目标与取舍。** 执行对象是鸿蒙 H 线，工作目录 `/Users/jiangxuanyang/Desktop/cangjie`。交付单指纵向拖动、点击/滚动仲裁、accepted 视口及真实焦点接续，让手写与生成长内容在两款正常 HAP 中可操作，同时修图片观察记录的长期增长。复用上包图片、输入、生成 region 和 Surface 仲裁；这一阶段增加公共交互能力，样例只作消费者。惯性/回弹、生成嵌套滚动和大规模虚拟列表另按需求接续，首包保留现有生成嵌套限制。

**已核对的入口与借鉴方式。** snapshot 的 `CjguiComposableUiScrollViewport` 已有 `scrollBy/step/reveal`、staged/accepted extents；设置和 thermo 已注册生成 `scrollArea`。核心窗口消费 scroll 事件，但 H 当前只转发触摸四相位，按钮/布尔在 BEGIN 执行，输入框在 BEGIN 激活；`focus_composable_node` 忽略 nodeId，取消 capture 也只返回 OK。借鉴当前 macOS“子控件命中与包含视口的滚动归属分开”和共享窗口“reveal→接受新几何→聚焦”的既有机制；保留成熟触摸处理的待定、点击、平移、取消状态区分，具体 SDK 事件字段/单位先查本机头文件和官方说明。共同的识别、身份与 viewport 状态合理放在仓颉核心；H 桥负责平台事件值、坐标归一、系统焦点和平台对象，不另建 ArkTS 滚动/业务树。公共契约确需扩展时先给出最小方案及 macOS 兼容方式，局部同步 H snapshot，保留 E/F 在途实现。

**A．图片观察元数据随实际持有收敛。** 先在现有 native 图片测试中建立有限资源循环：同一会话始终只显示一张图，轮换 65 个合法身份并再次循环，缓存记录保持上限而观察表不能逐轮增大。按当前 accepted/必要在途持有回收不再有用的观察记录，保留完成修订单调、同资源多节点去重、旧完成不影响新 accepted 的语义和既有锁序。反例修后检查表规模收敛、移除及关窗清理；不以定期清空整表制造重复完成通知，也不以扩大容量收口。既有图片四组交错按受影响路径复用。

**B．连续位移与点击互斥的通用触摸链。** 平台回调读取失败时不合成合法触摸；明确单指身份、Surface/应用代次、坐标单位及有界队列规则。当前满 256 项直接丢最旧事件可能丢 BEGIN/END，改为保留必要相位、合并同手势 MOVE 或显式取消，确保累计位移不丢、旧代事件不延续到新挂载。手势起始绑定 accepted 目标与包含视口，阈值前待定、超过阈值由视口接管并取消子控件点击；有效抬起才执行一次点击，移出/取消/退役不激活。纯滚动不修改业务 owner 或触发焦点切换结算。已激活文字编辑器的选区拖动、长按和系统代理按明确优先级保留，不能把所有 MOVE 强制当滚动。

连续逻辑位移沿共同 scroll 意图进入既有 viewport，而非上下半页跳转、直接写布局坐标或增加第二套 offset。稳定实例在 offset 更新产生新 accepted scene 后可继续同一手势；换绑、移除或 Surface 退役则取消。覆盖头尾夹紧、反向拖动、内容缩短与尺寸变化；候选拒绝保留旧 accepted 几何，随后恢复。比较请求 offset、accepted offset、绘制裁剪与命中，不能只以字段数值变化判定滚动成立。

**C．reveal 后接通系统焦点及编辑。** 使用共享 `focusScopedNode`/reveal 机制，通过正常应用操作定位屏外编辑器，等待对应 accepted 几何后接通 H 真实焦点/输入上下文；补齐取消 capture 的实际行为。成功回执对应正确节点和当前绑定，失效节点具名拒绝。滚动/resize/键盘改变可视区后，系统代理几何、UTF-16 选区和可见草稿继续校准；外部换版后继续编辑同一字段。平台调用遵守现有线程/锁边界，避免在 renderer 全局锁内同步等待 UI。当前 marked/cancel 版本化待验不阻塞这一已有草稿/提交能力的消费。

**D．两款 normal HAP 连续消费与成本。** 设置和 thermo 各提供超过三屏的有界内容，均包含文字、图片、按钮、编辑器；至少一个手写视口和一个由真实公共客户端提交的生成 `scrollArea`，共同调用同一机制。两款都实跑从子控件区域起手滑动→头/中/尾画面及 accepted offset→停止后精确点击/系统编辑→公开 owner 读回；按钮上滑动零误激活、普通点击恰好一次。再覆盖屏外目标 reveal→真实系统输入、同 key 生成重排保位置/草稿、非法候选保旧、移除旧目标后不串操作。画面、输入与 owner 对照必须来自正常 HAP；高密度 MOVE、取消/旧代和拒绝时序可由测试构建作确定性反例。

记录触摸队列高水位/合并量、实际位移、构建/布局/提交计数和停止后空闲收敛；图片滚动重绘应复用同 key/version，不能每帧解码。动态滚动期间插入少量带请求身份的公开业务写入，逐笔对齐 owner 与对应 accepted 场景；GET_CONTEXT 往返只报告读取服务成本。只采集能绑定阶段的耗时，未提供的内部计数如实保留，不为填性能表另造完整诊断系统。最终一次汇合验证受影响测试、核心构建、两款同源 normal HAP、SDK/镜像/ABI/源码指纹及禁止链接占位库的闭包；共享仓颉路径变更补相关 macOS 消费回归。物理设备性能继续单列。

**执行节奏。** 读取本节、ACTIVE、AGENTS 与直接相关源码即可开工；仓颉实现前使用 `cangjie-coding` 技能。A 与 B/C 独立推进，等待编译/咨询时做尚未阻塞工作，同 target 构建与模拟器操作协调串行。复杂平台实现/根因向 `gpt-6-sol` 聚焦只读咨询；手势所有权、跨层契约或并发方案未定时先用 `gpt-6-astra`，按当前可用次高档，Laya 辅助判定；结论用具体反例验证。沿 AGENTS 累计失败与升级规则，不靠重跑或散补丁试探。已通过且未受影响的基线直接复用，阶段有实现闭环或新事实时才短更本节和 ACTIVE，包末集中报告；不增逐轮文档。保留 E/F 改动和用户实例，未经要求不 stage/commit/push。

**执行者原始自验记录（2026-09-28，指导裁定见下）。** 以下保留本轮实现、运行报告及旧判据；“A/B/C/D 全部交付”由下方限域复核修正，不能继续作为整体完成状态。未 stage/commit/push，E/F 写集保持原样。
**A**：`reconcileAcceptedImagesLocked` 在既有 S→D 锁序内回收已退役 entry 的观察记录（entry ID 单调不复用，accepted/在途以引用/预留钉住 entry，"不在表内"等价"无人持有"；存活记录保留，缓存图再入场景不重复完成通知）。反例入 `scripts/test_image_capacity_native.py`：同一会话 65 身份双轮换，未修复版第二轮观察表增大（rc=2），修复版收敛且同资源去重/同 serial 不重发/关窗清理语义保留；全套图片 native 套件（capacity/epoch/binding/path/geometry/alpha）通过，既有四组交错原证按未受影响路径复用。
**B/C（renderer）**：触摸链改为单指手势状态机——阈值前待定、超阈值由包含视口（`scrollAreaIndexContainingPoint`，与子控件命中分开）接管为连续滚动并取消子控件点击、有效抬起执行一次点击、移出/取消/退役/surface 换代/视口移除不激活；滚动位移按存活样本差分累计并入同版本队尾事件（`by:<delta>` 文本，核心 `applyViewportScrollStep` 解析后走 `viewport.scrollBy`，无第二套 offset）；已激活编辑器长按/系统代理优先级保留。桥队列满载先丢最旧 MOVE（差分累计不丢总量），BEGIN/END/CANCEL 相位配对不断。`focus_composable_node` 按 nodeId 在 accepted 重验并走与触摸共用的平台编辑上下文激活（不回发 FOCUS，对齐 macOS enqueue:NO），失效目标 `NODE_NOT_FOUND` 具名拒绝；`cancel_composable_pointer_capture` 实际终结手势。12 组手势链确定性反例入新 `scripts/test_touch_gesture_native.py`（真实函数抽取宿主编译），全部通过。
**D（两款 normal HAP，真实 uitest 触摸 + 公共 TCP）**：设置 run `hscroll-settings-r3-120948`（HAP `92d57333…`，同 renderer 库 `8900487c…`；r2 起两次为画布加高前版本）、thermo run `hscroll-thermo-r2-121711`（HAP `8e0d65c5…`）。thermo run 的构建/安装/闭包有效，但其启动断言按默认 bundle 拉起了设置应用（launch 入口未随 CJGUI_APP_* 参数化）——thermo 的场景与消费证据来自随后显式 `aa start com.example.cjguithermo` 的当轮 hilog/截图（PID 22978/25671），不引用该 run 的启动断言。设置：真实上滑（子控件行起手）→ 视口 900 接管、行 5-8 滚入（截图 diff bbox 非空）→ 纯滚动 owner v0 不变 → 滚入的「滚动区减少」精确点击恰一次（10→9，v1）→ 滚入编辑器真实聚焦（ime proxy FOCUSED field=hand-scroll-note）→ 系统 IME 输入提交 → owner scrollNote「滚动备注已滚动到此处」精确读回（v2）→ 聚焦-滚动-追加再读回（v4 值精确）→ 按钮上起手滑动零误激活（target=941 被取消，count 不变）→ 尾部夹紧（二次滑动 clamped）。公共客户端提交生成 scrollArea（16→27 节点两版，含 action）候选被接受后，真实滑动由生成视口 `viewport=807001` 接管滚动、owner 依旧不变——与手写视口同一机制。thermo：滚入「滚动区升温」点击恰一次（22→23，v1）→ 按钮起手滑动零误激活 → 滚入备注编辑器系统输入提交 → owner note「恒温滚动备注」精确读回（v2）。 Examples 应用源（settings/thermostat）为唯一来源并新增 scrollNote 字段与 EDIT_SCROLL_NOTE 外部授权域；设置画布 layoutWeight 1→3 使生成区可见可触。触摸队列高水位/合并量未单独埋计数，实际位移/接管/版本推进由 hilog 原文与截图承载；内部构建/布局计数沿用 owner 周期日志，未为填表另造诊断。核心 `cjpm build --skip-script` 与 `cjpm test` 377/377 通过（共享 window 路径的 macOS 回归；macOS 从不产生 `by:` 文本，行为不变），`git diff --check` 干净，fport ls 清空，本轮转发与自有实例已按身份清理。marked/cancel 版本化对照、惯性/回弹、生成嵌套滚动、物理设备性能与发布审核按原边界保留。

<a id="h-touch-scroll-review"></a>
### H 触摸包指导接续：补全手势与焦点生命周期，完成正常消费（2026-09-28）

**复核范围与取舍。** 指导本次只读 bridge/renderer、共享与 snapshot 窗口、代理、测试及两 run 的源码指纹、启动原文和截图，没有构建、测试或操作设备。图片观察表按生产 entries 存活性回收，既有 S→D 锁序和持有保护成立，保留这项实现；65 身份夹具能判别历史表增长，但其末尾直接 clear 不能独立证明生产关窗。两 HAP 与 renderer 输入/产物指纹相符，设置生成区域和 thermo 滚动截图保留。两 run 的 runlog 只记录启动，thermo 的启动原文实际是设置应用；本次未在所列归档定位到后续 PID 22978/25671 的系统输入和精确 owner 回包，因此这些数值暂按执行者报告保留，先找现有原文，缺失部分并入本包正常消费补取。12 组测试只抽 renderer，裁剪恒真，未覆盖平台队列和公共 focus API，不能证明下面的机制正确。

**A．平台事件与有界队列：先保身份和终相位。** `cjgui_host_bridge.cpp` 的 `dispatchTouchImpl` 忽略 `OH_NativeXComponent_GetTouchEvent` 返回值，零结构的 type 对应 SDK 的 DOWN；`TouchRecord` 没有 pointer id，忽略第二次 BEGIN 不能阻止第二根手指的 MOVE/UP 结束第一根手势。读取失败不得发布合法触摸；按本机 SDK 契约携带活动手指、Surface/应用代次和有界事件身份，逐相位校验，明确多指时忽略副指或显式取消主手势的策略。数值须有限，平台坐标与逻辑单位转换只做一次。先补“取数失败零输入”和 A 按住→B 按下/抬起→A 不误激活的反例。

满 256 项时当前先删任意最旧 MOVE，无 MOVE 则 pop_front，仍会拆相位，且删除某手势唯一 MOVE 会让滑动退化成点击。改为有界的同身份压缩与明确的过载取消/恢复协议，保留跨阈值事实及最后坐标；无法保留时取消该手势，旧 END 不得激活，新 BEGIN 能恢复。测试必须进入真实 bridge 入队/出队再到 renderer，覆盖全边界事件饱和、唯一 MOVE 被压缩、取消/退役与新手势。记录最小的高水位、合并/取消计数即可，不另做诊断平台。

**B．同一手势的位移、绑定与取消贯穿核心。** `synthesizeEventsFromRawTouch` 逐 MOVE 将 float 差分转 Int64，同时推进 last，导致小数位移丢失；END 不结算尾差，也不重新判断阈值。保留浮点累计余量，到共享整数 viewport 的边界再量化，END 消费最后坐标；接阈值、同方向合并、反向和头尾夹紧的结果须与明确的未压缩参考序列一致，不能只测净和。补 0.5 单位连续样本、最后位移只在 END、边界往返，以及候选拒绝后的请求/accepted 恢复反例。保留现有 `by:`→共享 viewport 单一路径，同时对共享解析、合法正负位移、非法载荷/溢出和旧方向事件做针对性回归；“macOS 不生成 by:”不等于共享分支已验。

手势不能只用 nodeId/resourceId/kind 判断换绑。按真实绑定身份/代次区分同 key 重排或几何更新与动作/字段替换，冻结起始绑定，旧按下不能借新 sceneVersion 激活另一动作；沿现有公共绑定机制接通，避免新增第二套 owner。系统 CANCEL、退役和目标移除目前仅重置 native gesture：若已向核心发 POINTER_BEGIN，必须沿旧捕获身份送达恰好一次有效终结，清理核心 capture；核心主动取消则避免回环。先补“BEGIN/UPDATE 被核心消费后系统 CANCEL”和“按下动作 A→同槽换动作 B→抬起零误触”反例。移动离开、横向手势与已激活编辑器选区/长按应按明确优先级仲裁，不能依靠队列丢样本或把长距离拖动当长按。

**C．焦点切换与屏外 reveal 成为真正可消费能力。** `beginEditingOnNodeLocked` 每次换 contextId，但同一已激活节点不设 focus/reconcile 通知，公共重复聚焦后系统代理仍持旧编号，后续输入被 stale 拒绝；切到另一字段又先覆盖旧身份/缓冲，新焦点通知到页面后才提交旧代理，旧草稿已经无法结算。将二者作为一个上下文生命周期问题修：同一有效绑定重复聚焦幂等；切换时按旧身份保存待结算数据并落实既有失焦语义，再发布新上下文，旧回调不可写入新字段。拒绝/取消是明确结果，不能静默丢普通未提交草稿；平台调用继续在 renderer 锁外完成，不等待 UI 回调持锁。

先用真实公共 focus 路径覆盖同字段连续聚焦后输入、A 普通草稿未回车→聚焦 B→A 恰好结算、旧回调拒绝。几何更新与 owner 修订沿已有 `CjguiComposableUiBusinessOwnerRevisionProvider`、`cjguiPreservesOwnerStableText` 和 `preservesActiveLocalText` 保留机制核对；不能只看 native 的 sceneVersion 变化分支就另造修订系统。补活草稿与非空选区经滚动/resize/同 key 重排后继续提交、外部真实换版后校准的判别。**原包要求的屏外 reveal 尚未由“先滑到可见再点击”证明**：在正常应用中通过显式目标导航调用公共 focus/reveal，证明初始裁剪→请求→新 accepted offset/几何→正确系统 context→输入→owner；受控拒绝保持旧几何，随后同请求恢复。此项不依赖原始键盘路由，也不依赖目前缺失的 marked/cancel 回调。

**D．部署身份和正常双消费者一次汇合。** `build_and_run.sh` 从 LAB 读 BUNDLE_NAME 后，又按 env 默认 `CJGUI_APP_BUNDLE` 启动和取 PID，能“构建 thermo、启动设置、断言成功”。从目标工程统一解析/核对 bundle、ability、端点，构建、安装、启动、PID 与断言共用；显式覆盖不匹配须具名失败。先做离线错应用负控，再使用华为模拟器的设置与 thermo normal HAP。复用既有图片/生成 region/viewport，在同次连续会话完成：子控件起手滚动、停止点击恰一次、屏外导航与系统输入、活草稿重排/resize、非法候选保旧、移除/换绑后无旧操作；至少一个手写与一个公开客户端提交的生成视口。示例用现有声明式样式保证滚动内容可读可触，不以修改截图补可见性。

按当轮 HAP、bundle、PID、资源/目标身份和版本保存实际输入日志、关键前后截图与公开 owner 原文；先归档已存在材料，缺证并入这次受影响链，不补造历史读数。设置与 thermo 各自启动断言必须对应自身。滚动中插入少量带身份的公开业务写入，记录可绑定的 ready/owner/accepted 样本、位移及空闲收敛、同图滚动解码计数，读取往返单列；未提供的内部细分耗时继续标 unavailable。

**本包参考查阅。** 落实 AGENTS 的机制触发规则，优先针对触摸仲裁、事件压缩与取消、焦点/输入上下文生命周期，从[本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)定位成熟实现及对应测试；导航缺项自行定向查找。先读关键符号，明确状态归属、失败恢复和 CJGUI 的适用差异后回到实现。借鉴思路，不引入参考框架依赖；已有结论在前提未变时复用，必要结论简记本节，不新增调研台账或把全仓阅读作为开工条件。

**E．执行方式与收口。** 复用上节 A 的图片修复、B 的共享 viewport 入口和 C 的平台 focus 入口，不重写正常已验链。优先建立 A/B/C 各自会失败的最小生产反例并连续修机制，启动身份修复可独立推进；最终一次受影响测试、核心 build、两款同源 normal HAP/闭包与源码指纹。共享仓颉修改补相应 macOS 定向消费，H snapshot 只同步必要契约，不覆盖 E/F 在途文件。沿 AGENTS：仓颉编码先用技能；复杂技术根因咨询 `gpt-6-sol`，跨层身份/生命周期或公共契约未定先咨询 `gpt-6-astra`，使用当前可用次高思考档，携带最小复现与已有证据；Laya 仅辅助。等待构建/咨询时推进独立工作，同 target 和设备操作串行。无新变更/失败/证据疑点就复用旧基线，不重复整套验证；只在实现闭环或新事实出现时短更本节与 ACTIVE，包末集中报告。惯性/回弹、嵌套生成滚动、物理性能和当前 marked/cancel 版本边界保持后续，不把它们变成此包的开工门槛。用户已授权范围内自主连续实施；保留其他线程和用户实例，未经要求不 stage/commit/push。

**执行者接续自验（2026-09-28；整体状态以下方第二次指导复核为准）。** 机制参考按 AGENTS 新规则执行：Flutter 手势竞技场（arena.dart，按指针开闭/eager winner/UP sweep/resolve 幂等）与通用事件压缩原则（绝对坐标保最新样本、相位不可丢、过载以 CANCEL 收敛）已读，适用前提（指针键控竞技场 vs CJGUI 单指+视口接管）记录如上后回到现有架构实现，未引入参考依赖。下列是原自验读数；“总量不丢”“恰好一次终结”“无需 macOS 回归”的适用范围已由下一节修正。

**A**：`dispatchTouchImpl` 校验 `OH_NativeXComponent_GetTouchEvent` 返回值（取数失败零输入；零结构 type==DOWN 不再成合法触摸）、坐标有限性、活动手指身份（首指持手势，副指 BEGIN 忽略、副指 MOVE/UP 不终结主指，主指抬起释放，surface 换代作废）。队列改为同身份压缩优先（手势在途 MOVE 恒压缩为单条最新样本，坐标为绝对值故总量不丢、滑动不退化成点击）+ 满载丢最旧 MOVE + 相位边界满载时对队首代次整组移除并队首注入显式 CANCEL（先于一切排队记录交付，渲染器重置该手势；旧 END 不激活，新 BEGIN 恢复）；高水位/压缩/过载取消计数入 `test_touch_bridge_queue_native.py`（真实入队策略抽取反例：饱和、唯一 MOVE 压缩、过载取消形态、新手势恢复）+ dispatch 源码断言。
**B**：渲染器手势位移以浮点累计余量量化交付（逐样本 float→Int64 截断与 by:0 消失），END 重判阈值并消费尾差（快速轻扫不再误判点击）；激活事件携带按下时刻冻结版本（同槽换绑动作/字段后旧按下由核心 resolveInput 版本失配拒绝）；指针相位流开/合簿记，系统 CANCEL/退役/移除沿旧捕获身份送达恰好一条指针取消（核心对 40 无条件清捕获），迟到 END 不补发。7 组新反例（R1–R7）+ 原 12 组全绿于 `test_touch_gesture_native.py`。
**C**：同一有效绑定重复聚焦幂等（不换 contextId，代理不 stale）；跨字段切换先按旧身份同步结算组合草稿（settle 以旧身份交付恰好一次）并捕获 detach 身份（pump end 通知不再读新字段）；`focus_composable_node` 对未完整可见目标经公共 FOCUS 通道请求 reveal（同上下文仅一次）。snapshot 窗口补必要契约：`focusAcceptedSemanticNode` + pending/flush，且语义 flush 挂上**原生提交点**（初版只挂了 semantic-menu 分支导致焦点不落地，经 r4/r5 设备取证定位后修正）；reveal 一次到位按当前几何聚焦（长内容可超夹紧上限，不无限重试）。屏外 reveal 消费入口为示例内导航按钮（应用内显式目标导航 → 公共 API），设置与 thermo 各加「定位滚动备注」。
**D**：`build_and_run.sh` 应用身份改为从目标工程 app.json5/module.json5 统一解析（bundle/ability），env 默认不再覆盖目标工程；显式覆盖与目标工程不一致具名失败。离线负控 `test_app_identity_guard.py` 5 项（两 lab 各自解析、显式失配具名失败、显式匹配放行、env 默认不误触发）。华为模拟器两款 normal HAP（设置 `hreview-settings-r6-143632` HAP `21e805a1…`、thermo `hreview-thermo-143942` HAP `b483f06e…`，同 renderer 构建）各完成连续消费：真实 uitest 快扫（按钮起手→视口接管零误激活、owner 不变）、滚动后精确点击恰一次（设置省略/thermo 降温 22→21）、导航按钮屏外 reveal→平台 focus（ctx/mount 一致）→系统 IME 输入→owner 精确读回（设置 scrollNote「滚动备注屏外导航输入待结算草稿」跨字段切换结算 v3；thermo note「恒温滚动备注」+降温 v2）。多指策略由宿主反例覆盖（uitest 无法驱动真实双指，设备多指留待真实触摸验证）。
**E**：受影响宿主测试 9 套件全 OK（touch gesture 19 例、bridge queue、identity guard 5 项、image 6 套件）；共享仓颉核心本包未改（snapshot 为 H 独有契约，src 的 focusAcceptedSemanticNode 早已存在），无 macOS 回归负担；示例应用新增平台中立字段/按钮由 lab 构建验证编译。`git diff --check` 干净、fport 清空、本轮转发已清理。marked/cancel 版本化对照、惯性/生成嵌套滚动、物理设备性能与发布审核按原边界保留。E/F 并行改动保留，未 stage/commit/push。

<a id="h-touch-lifecycle-second-review"></a>
### H 触摸包第二次指导复核：贯通队列、捕获与绑定，再完成正常消费（2026-09-28）

**裁定与保留。** 本次核对当前生产函数、抽取测试、两款 HAP 的原始启动/指纹与截图，并在临时目录执行小型宿主判别；未改生产、未构建 HAP、未操作模拟器。保留图片观察回收、平台取数返回值/有限值检查、单指过滤接线、浮点余量、无 MOVE 快扫判别、重复聚焦幂等和跨字段旧身份入队的进展。部署身份缺陷本轮确已修：设置 PID 9843、thermo PID 13724 各启动自己的 normal HAP，两包 renderer 摘要同为 `1297440e150e7a381434c05bdf28db3b2c47e965167cf484ad4084f17ab53cda`。设置截图证明滚动备注可见、光标和系统键盘出现。**A–E 仍未整体收口**，以下跨层反例优先于单函数测试绿色。

| 复核发现 | 当前实现与可区分结果 |
| --- | --- |
| MOVE 压缩抹掉拖动历史 | `enqueueTouchRecordLocked` 只覆盖最新绝对坐标。真实 bridge 入队→真实 renderer 摘录：`BEGIN(60,120)→MOVE(60,150)→MOVE(60,120)→END(60,120)`，直送为 `activate=0/scroll=1`，压缩后 3 条却为 `activate=1/scroll=0`。回到起点不等于没有跨过阈值。 |
| 满队列仍删除唯一 MOVE | 同一手势仅一条 MOVE，再加入同 Surface generation 的边界事件造成 256 项压力，得到 `overloadCancels=0/activate=1/scroll=0`。现 Q3 的 256 条同代 MOVE 实际先压成 1 条，没有覆盖满载分支；dispatch 取数/多指测试目前是源码关键词断言。 |
| 已滚动手势仍漏 END 尾段 | `kGestureScroll` 的 END 只量化旧余量，没有纳入 `END.y-lastY`。真实函数摘录 `BEGIN y100→MOVE y80→END y50` 为 `actual=20 expected=50`。R1 无 MOVE、R2 END 与最后 MOVE 同坐标，均判不出它。 |
| 场景版本代替了绑定身份 | 保持节点/资源/动作/几何全不变，只接受下一帧，按下版本 100 被原样发出，而当前 scene=101，核心 `resolveInput` 必拒。现 R3 只检查旧版本，没有同时证明换绑拒绝和同绑定存活。 |
| 旧 CANCEL 反馈取消新手势 | native pump 可先处理 A BEGIN/MOVE/CANCEL 与 B BEGIN/MOVE。核心收到 A CANCEL 又调用 native cancel，后者取消当前 B；宿主按此调用顺序实测 `new_gesture_active_before=1 after=0 cancel_before=1 after=2`。完整仓颉↔native 往返仍应补定向验收。 |
| reveal 与共享示例接线仍有缺口 | H `flushPendingSemanticFocus` 仅核 node/semantic/resource，漏主核心现有 incarnation/field/action/operation 绑定，旧 A 请求可聚焦同槽新字段 B。共享 settings 示例新增导航按钮只有 OHOS owner-loop 取 pending，macOS 宿主未接；这不是 H 独有示例变更。 |

尾差、场景版本、取消反例原数与摘录夹具：[result.log](/private/tmp/cjgui-touch-review-bz23iz90/result.log)、[touch_review.cpp](/private/tmp/cjgui-touch-review-bz23iz90/touch_review.cpp)。bridge 两条反例的输入与结果完整列于上表，临时宿主夹具已回收，执行者据生产入口固化即可，不补造历史日志。上述是源码/宿主机制证据，不能称为本次模拟器重现。

**A．一次修清事件压缩语义，保留可判定的手势历史。** 在现有 bridge→ingress→renderer 通路中区分 Surface 代次、pointer 身份与一次 gesture/capture 代次；同 Surface 的两次触摸不能只靠 generation 混为一组。容量继续有界。首片可以保留有界原样本或有序同向片段；只有证明对阈值、方向转换及 viewport 逐次夹紧等价时才压缩。至少保留“已经跨过阈值”的不可逆事实与必要转折，最新绝对坐标本身不是这项事实。不能保留必要样本时，对准确的受害手势交付一次取消，退役其后续 MOVE/END，新 BEGIN 可恢复；取消不能越过身份清除另一手势。

统一 MOVE/END 的坐标累计入口，END 先纳入最后坐标差再量化，保留亚单位余量。连同 `appendScrollIntentLocked` 一并核对：它当前把反方向 delta 直接相加；头部 offset=0 时依次 `-30,+30` 经夹紧应为 30，合成 0 则结果不同。首片保留反向片段及逐步夹紧，不能仅以净位移判等。共享 `by:` 解析仍走原 viewport；非法/溢出、候选拒绝后的 requested/accepted 恢复按受影响路径验证，不另造滚动 offset。

**判别要求：**通过真实 bridge 入队/出队→renderer→共享 viewport/控制器检查，而非只测队列形状。覆盖往返越阈值、唯一 MOVE 遭压力、全相位满载、反向夹紧、END 独有尾段、0.5 连续样本及旧代/新手势恢复；平台 dispatch 用受控 SDK 返回值执行失败与主副指序列，替换纯关键词断言。先固定当前错误结果，再连续修机制；现有单调滚动正例复用。

**B．绑定与捕获各有身份，取消按方向终结。** 冻结真实 accepted 目标的绑定身份/代次，复用共同核心已有 semantic incarnation、字段/动作/operation 目标等判据；整 sceneVersion 仅是场景版本。抬起先确认原绑定仍存活、当前命中合法，再按当前 accepted 事实交付；同绑定几何/无关刷新继续，真正换绑/移除拒绝。业务 owner 的并发版本守卫保持有效，不能简单把旧事件统一改戳成新版本。编辑器 native 切焦点也须在目标验证后进行。

区分“平台通知该捕获已终止”与“核心主动要求平台取消捕获”。前者只终结匹配的核心 capture，不反向广播取消 native 当前手势；后者携带可核对的 capture 代次，不能作用于较新的手势。BEGIN/UPDATE/END/CANCEL、退役与主动取消共用一次终态规则。固化 `A CANCEL 已排队→B 已在 native 开始→核心消费 A` 的完整跨层反例，断言 A 终态一次、B 可继续更新/结束、旧 END 不误激活；另外成对证明“换动作拒绝”和“同绑定换帧仍可点击/拖动”。

**C．沿既有完整绑定契约接通焦点消费。** 同步主核心 `flushPendingSemanticFocus` 已有的 incarnation/field/action/resource/operation 校验到 H 必要快照，保持请求随 accepted 事务完成；受控拒绝保留请求与旧几何，恢复后只聚焦原绑定。目标高于视口时允许按明确的非空可见交集完成 reveal，完全不可见或换绑不得被“只试一次”洗成成功。native 聚焦失败须有明确结果或有界重试，不清 pending 后静默丢失。

同字段重复 focus、A 草稿未提交→B、迟到旧回调等已有机制，补到公共 API→native→系统代理→真实 owner 的链上。活草稿和非空选区经滚动/resize/同 key 重排后续写，必须区分同绑定延续与字段换绑；复用已有 owner 修订保护。共享 settings 控制器的导航请求同时接回 macOS 消费宿主，做一次该按钮 reveal→聚焦→输入的针对性验证；无需为此重跑整套 macOS 框架。

**D．把原包缺证与正常能力合并成一次连续消费。** 两份最新 run 的启动和 renderer 指纹有效；目前其 runlog 仍只有启动段。设置截图是输入前焦点，thermo 截图为 22℃/空备注且显示“事件 39 的原控件已刷新（节点 900）”，不能代表报告中的 v2/21℃终态。先从已有任务输出归档真实 IME/owner 原文并补索引；无法找回的部分标明执行报告记录，在本包最终正常链补取，不重新制造历史证据。

在华为模拟器的设置与 thermo normal HAP 各复用当前实例，至少一个手写、一个经公开客户端提交的生成视口，完成：按钮起手往返滑动零误激活→停止点击恰一次→屏外导航与系统输入→活草稿/非空选区同 key 重排及 resize 后续写→非法候选保旧并恢复→换绑/移除后旧输入拒绝。滚动中插入少量带身份公开业务写入，保存实际 ready/owner/accepted 关联、位移、停止后收敛和同图解码计数；内部耗时不可得时保留 unavailable，GET_CONTEXT 往返仍只是读取成本。截图、原始协议回包与阶段日志绑定当轮 HAP/bundle/PID/目标，按操作实时收取，集中报告不替代原文。

**E．机制参考、咨询与执行节奏。** 这是原触摸包的完整接续，保持惯性/回弹、生成嵌套滚动及物理性能的后续边界。优先读本地 Flutter `monodrag.dart` 的 possible→accepted、`_hasDragThresholdBeenMet` 与 `arena.dart` 的指针生命周期，并查对应拖动/取消测试；指导已核对本地 `8db55268667c` 的上述状态转换。借鉴“接受后不能由回到起点重新变回点击”和按指针终结的机制；Flutter 竞技场本身并未证明 CJGUI 的压缩算法。队列压缩与转折若需其他参考，按[机制导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)自行定位相关源码/测试，记录适用差异，只借思路，不引入依赖。

本包跨队列/核心捕获的旧问题已发生实质修复后仍失败，先把上表反例与现有接缝提交 `gpt-6-astra` 作一次聚焦只读方案裁决（手势/capture 身份、压缩等价条件、双向取消职责），据可验证方案连续实施；复杂具体实现定位用 `gpt-6-sol`，按当前可用次高档。遵守 AGENTS 累计失败与升级规则，不能换模型清零。成批日志归并/候选分类优先 `laya-ask`，复用必要片段和稳定编号；明确规则直接判断，冲突/信息不足由执行模型接回，分类不替代参考查阅和运行验证。

平台队列、核心取消/绑定、焦点/宿主消费按明确写集交错推进。等待编译、咨询或设备占用时做独立必要工作；同 target、模拟器和 macOS 前台串行。包末一次受影响宿主/共享分支测试、核心 build、两个同源 normal HAP/闭包与指纹，保留图片/历史生成等未受影响原证；共享接口修改与 E/F 协调最小兼容接线。仅在形成真实切面或新事实时简更本节及 ACTIVE，完成后集中报告；不新增逐轮任务卡，不覆盖并行改动，未经要求不 stage/commit/push。

**执行者自验记录（2026-09-28；完整收口结论以下方第三次指导复核为准）。** 咨询先行：六反例与现有接缝已提交 gpt-6-astra 聚焦只读裁决（问答固化于 `platforms/ohos/consultations/touch-lifecycle-astra/`），Q1 压缩骨架（跨阈值样本+方向转折+最新，禁止单删唯一 MOVE）、Q2 按手势代次整手势淘汰（BEGIN 未出队静默删除、已出队注入恰好一次带身份 CANCEL 且先于后继手势）、Q3 绑定身份两路对照（本包取语义冻结过渡路，bindingEpoch 全链路列为后续契约项）、Q4 平台通知只终结匹配捕获不反调 native、Q5 MOVE/END 共用采样入口+核心 viewport 逐段夹紧。
**A**：bridge `TouchRecord` 增 gestureEpoch（BEGIN 分配、MOVE/END 继承、主指抬起作废）；MOVE 骨架压缩为「极值样本+最新样本」（跨阈值事实与方向转折保留，回起点不恢复点击）；满载淘汰按队首代次整手势（单记录静默移除、多记录队首注入带身份 CANCEL），不再单独删除唯一 MOVE。新宿主反例 `test_touch_bridge_queue_native.py`：饱和压缩、唯一 MOVE 存活、BEGIN 未出队静默、BEGIN 已出队注入带身份 CANCEL。
**B**：渲染器 MOVE/END 共用 `consumeScrollSampleLocked`（END 纳入最后坐标差，R2 型 50/50 对齐）；`appendScrollIntentLocked` 只并连续同号段（反号按序交付，核心 viewport 逐段 requestedOffset 夹紧，N3）；阈值闰不可逆（跨阈值回落不恢复点击，N1，Flutter `_hasDragThresholdBeenMet` 同型）；绑定语义冻结（semanticId 变化即真换绑在副作用前拒绝，N4 前半；同绑定换帧以当前版本存活，N4 后半/R3 修正）；src+snapshot 核心 kind-40 加身份守卫（A 的过期取消不再清 B 的捕获，宿主 宿主往返反例为 astra 材料,设备验证续 D）。
**C**：snapshot `flushPendingSemanticFocus` 补 field/action/operation 校验（semanticIncarnation 字段 snapshot 尚无，如实保留待契约同步）；snapshot 语义 flush 挂上原生提交点（上包已修）+reveal 一次到位；macOS settings_counter_window_app 宿主循环接入 `takePendingFocusRequest`→`focusAcceptedSemanticNode` 并编译通过（与 OHOS 同一接法，输出 CJGUI_NAV_FOCUS 行）。
**D**：双 normal HAP 最终连续消费（设置 `hreview2-settings-final-154847` HAP、thermo `hreview2-thermo-155019` HAP `b483f06e…` 前版+本轮，PID/身份经统一解析）：真实 uitest 快扫零误激活→滚动→导航按钮屏外 reveal→平台 focus（ctx/mount 一致）→系统 IME 输入→owner 精确读回（设置 scrollNote「滚动备注连续消费输入」v1；thermo note「恒温屏外导航备注」24B v1）；原始 hilog 全文与截图按当轮 PID/bundle 归档于各 run 目录。多指由宿主反例覆盖，设备多指仍留待真实触摸。
**E**：受影响宿主 9 套件全 OK；核心 `cjpm build --skip-script`+`cjpm test` 全绿（src 窗口 kind-40 守卫）；macOS settings 窗口应用编译通过；`git diff --check` 干净、fport 清空。bindingEpoch 全链路（pod+事件+核心比对）、设备多指、marked/cancel、惯性、物理性能按原边界接续。E/F 并行改动保留，未 stage/commit/push。

<a id="h-touch-identity-fifo-third-review"></a>
## H 触摸包第三次指导：落实既有裁决，贯通有界 FIFO 与跨层身份 A–E（2026-09-28）

**目标与取舍。** 本包继续 H 线，把当前触摸能力补成可被手写、生成及混合窗口共同消费的框架机制。主要问题是裁决没有完整进入生产通路：队列只加了局部 epoch，平台取消仍走旧双向调用，绑定仍只比较当前 semanticId。因此本包选择“有界原始 FIFO＋明确过载终结＋核心签发绑定代次”，先获得可证明的行为，再考虑压缩优化。bindingEpoch 是本包实现项，不再推为可选后续。保留有效的 END 尾差、同号滚动段合并、阈值锁存、平台引用/图片生命周期和两款正常应用原证；不重开它们的历史整套验收。惯性/回弹、设备多指、marked/cancel 版本边界及物理性能继续单列。

**第三次任务下发时的复核事实（修复后的当前状态见本节末「交付后复核」）。** 当次只读源码、裁决和已有 HAP 原证，并在临时目录执行当时生产函数摘录的宿主判别；没有构建 HAP、操作设备或改实现。宿主测试不是模拟器复现，必须接入生产链测试后再与正常消费汇合。

| 发现 | 当前证据与影响 |
| --- | --- |
| 往返仍变点击 | bridge 的 `mergeMoveIntoSkeletonLocked` 先覆盖 latest，再将该值保存成转折；`BEGIN y120→MOVE y150→MOVE y120→END y120` 实际出队 `120/120/120/120`。直达 renderer 为零激活、滚动 `-30,+30`，经 bridge 为激活一次、零滚动。全局极值＋最新也不等于保留全部转折。 |
| 满载可在锁内死循环 | A BEGIN 已出队，仅 A END 在队首；再排入 127 组 BEGIN/END 和 C BEGIN，达到 256 条；C MOVE 触发“删 A 的一条 END→补一条 CANCEL→再删再补”，容量不下降。宿主子进程超时 1 秒后终止。现 Q2b 用 epoch=0 孤立 MOVE 的夹具没有覆盖该合法相位。 |
| 旧取消仍伤新捕获 | src 与 snapshot 的 kind-40 匹配分支仍调用会反调 native 的 `cancelPointerCapture()`，不匹配分支仍 `clearPointerCapture()`。宿主往返结果 `new_active=1→0, cancels=1→2`。bridge epoch 未经 ingress dequeue、renderer QueuedEvent 到核心，当前守卫无法区分同节点的两次手势。 |
| 语义冻结并非获准过渡实现 | renderer 只比 semanticId；生成同 key 可保留该 ID 而换 action/field，A→B→A 更不能按最终值识别。宿主 `SEMANTIC_ABA activate=1`，预期 0。Astra 的过渡路线要求历史完整绑定快照与退役识别，本实现不满足。 |
| 焦点失败会丢失或误报 | snapshot 先清 pending 且忽略 native 返回；native 在目标完全不可见时仍可 beginEditing，并在一次 reveal 后返回成功。新增字段校验与 macOS 宿主接线有效，但不能抵销这一缺口。 |

队列原数与夹具：[result.log](/private/tmp/cjgui-h-touch-review2-yffujxo2/result.log)、[probe.cpp](/private/tmp/cjgui-h-touch-review2-yffujxo2/probe.cpp)；取消/绑定/尾差：[result.log](/private/tmp/cjgui-h-touch-second-review-dn8z8dgx/result.log)、[touch_review.cpp](/private/tmp/cjgui-h-touch-second-review-dn8z8dgx/touch_review.cpp)。队列日志的 `reference_clamped_offset` 是依共享夹紧规则计算的对照，未执行仓颉 viewport；执行者应补真实核心消费断言。`END_TAIL actual=50 expected=50` 已绿，保留为正控。

双 normal HAP 的新增系统输入原证成立：设置 `hreview2-settings-final-154847/hilog_consumption.txt`（PID 22422）含「滚动备注连续消费输入」30 B/v1；thermo `hreview2-thermo-155019/hilog_consumption.txt`（PID 24640）含「恒温屏外导航备注」24 B/v1。两包平台指纹 `c5f575…`、renderer `55c937…` 一致，最终 thermo HAP 以其 `hap_sha256.txt` 的 `9bc910…` 为准，旧 `b483f06e…` 不代表该终态。本轮这两条链的生成结构仍为 0，选区为折叠范围，不能算活草稿非空选区重排/resize、生成视口或拒绝恢复通过；hilog 的 owner 值与公开协议原回包分开标记。

**A．先交付有界原始 FIFO 与可终结过载协议。** bridge 在目标及手势阶段尚未判定时保留原始样本，撤掉当前“两条骨架”压缩。使用当前总容量上限，终结控制记录也计入预算；由实际出队点记录 BEGIN 是否已交付/在途，维护已取消代的有限生命周期。过载按准确 GestureKey 整手势淘汰：BEGIN 未出队则无消费者终态；已出队则生成一次取消，逻辑位置在已交付前缀之后、后继手势 BEGIN 之前。预留终结槽位，取消记录不可再作受害数据；处理流程必须有限步减少待处理工作或返回明确降级结果，不能在锁内删补循环。删除后抑制该代 MOVE/END 直至物理终结，新的 BEGIN 可继续。取消使用受害者的代次、坐标域和顺序，不取新来事件的 generation；“队列里没有 BEGIN”不等于已经交付。

既有 renderer MOVE/END 共同采样与反号分段保留；同号合并不得跨 GestureKey、绑定、坐标域、外部写入等顺序屏障。压缩不是本包必需优化，后续若采用必须证明保留首次阈值、全部必要转折和量化顺序；任意指针轨迹不能套 Y 轴滚动压缩。固定上表两条 RED，再覆盖单记录受害者、取消占槽、END/CANCEL 在途、同 Surface 连续手势、容量始终有界且终态恰一次。SDK 取数失败及主/副指过滤要通过受控返回值实际执行 dispatch，保留已有合法主指序列；源码关键词不算行为验证。

**B．GestureKey、accepted bindingEpoch 与取消方向贯穿全链。** 将应用/窗口实例、surfaceGeneration、pointerId、gestureEpoch 形成不会跨实例混淆的身份，贯穿 raw record→ingress→renderer gesture/derived event→核心 capture→主动取消。比较发生在开始捕获、split 等分派快路径和任何清理之前。平台终结入口只结束匹配核心捕获，不反调 native；不匹配则忽略，不能清掉 B。核心主动取消携 expected key，native 只结束匹配实例，旧 A 不能取消已开始的 B。重复终结幂等、旧 END 不激活；Surface 退役终态不能被当作普通旧代输入过滤掉。

由核心在 accepted 事务发布绑定代次，覆盖 node/resource/kind、semantic/key/incarnation、field、action、operation action/target；真正换绑、移除重建及 A→B→A 推进，同绑定内容/几何刷新保留，被拒候选不发布。可借用既有 accepted 绑定跟踪机制，不能让通用输入依赖动画 API。目标与 viewport 分别冻结身份；renderer 在焦点/IME/激活副作用之前复核，核心执行前再比对，业务版本守卫照旧。无身份的旧后端事件保留原严格版本路径，零值不是通配符。

选择最小兼容接缝并同步 C/Cangjie、src/snapshot、桥接出入队、复制与派生事件。现有事件 POD 的 `bindingEpoch` 已用于 kind-52 组合协议，先确认语义与命名域；需要新字段或旁路元数据时，随事件原子冻结且有 ABI size/offset 及新旧后端检查，不能临时查询“当前手势”补旧事件身份。E 文本会话规则保留，与其共享符号协调。验收必须成对覆盖：同绑定换帧仍可操作／同 key 换动作或字段被拒；A→B→A／移除重建拒绝；A CANCEL 排队后 B 已开始，A 终结一次且 B 能正常完成。bridge/renderer 测试与仓颉核心捕获测试都要能判出原缺陷。

**C．焦点请求也绑定 accepted 身份，并有真实终态。** snapshot 与主核心共同校验完整绑定及新代次；pending 从请求到 reveal 接受、native focus 成功或具名拒绝有明确状态。暂时不可用保留等待资格，按 accepted/native 可用变化做有界接续；永久失败具名终结，禁止无条件清请求或每帧无限重试。目标与完整祖先裁剪链存在非空可见交集才可完成聚焦；高于视口的控件允许部分可见，完全不可见不能启动编辑并报成功。固化受控 native 失败→恢复、reveal 后仍完全裁剪、等待期间同槽换绑/ABA。共享 settings 的 macOS 接线已存在，补一次导航按钮→reveal→输入读回的针对性消费即可。

**D．完成正常手写与生成消费，补上包实际缺项。** 在两款 normal HAP 复用临时实例，至少一条手写视口、一条通过公开客户端接受的生成视口：按钮起手往返越阈值零误激活→停止后点击一次→屏外导航/系统编辑→可见草稿和真实非空选区同 key 重排、resize 后继续编辑→非法候选保旧后恢复。另用同 key 换 action/field 或移除重建证明旧触摸不能激活新绑定，当前合法手势仍可执行。复用既有系统输入正控；不为 marked/cancel 的版本化平台边界反复尝试相同操作。

滚动期间插入少量带身份公开业务写入，保存 ready/owner/accepted 对应关系、位移/余量、终结后空闲计数、同图解码与资源持有；按原预算报告逐样本，不把 GET_CONTEXT 耗时当渲染响应。公开 owner 原始回包、截图和系统日志绑定本轮 HAP/bundle/PID/目标。现有 hilog 可复用但不补造已遗失的协议原文；只对缺少或受修改影响的连续段补证。

**E．按已有裁决实施并集中汇合。** 先读 [Astra Q1–Q3 最终答复](../../runtime/cjgui/platforms/ohos/consultations/touch-lifecycle-astra/response_q123.txt) 末部标题节（当前约 1997–2032 行）及 [Q4/Q5 答复](../../runtime/cjgui/platforms/ohos/consultations/touch-lifecycle-astra/response.txt)。其中已明确“bridge 未分类时原始样本”“预留取消容量且取消不可再淘汰”“bindingEpoch 双向贯穿”“平台终结不反向取消”；这四点直接实施，不重新咨询同五问。新出现的具体技术根因用 gpt-6-sol；仍未定的 ABI/并发/身份公共契约带精确差异向 gpt-6-astra 聚焦追问，采用当前可用次高档。按 AGENTS 累计失败规则保留已有失败，本次指导已给出新的确定实施路径；再失败时提交可区分结果，不继续换一套两样本补丁。

按 [机制参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考) 查本地 Flutter `monodrag.dart`/`arena.dart` 的阈值锁存和按指针终结及对应测试，复用已核对的 `8db55268667c` 结论；它们不证明 CJGUI 的队列压缩等价。只借鉴思路，不引入依赖。仓颉修改前读 cangjie-coding skill；批量重复且可核验的日志分类可用 laya-ask，明确判据直接执行，分类不代替源码与反例。

bridge 队列、核心/renderer 身份、焦点和消费按写集推进；等待编译、咨询或模拟器期间做未阻塞的必要工作。共享 target 构建和设备/桌面操作串行，包末一次受影响测试、核心 build、两 normal HAP 同源闭包与正常消费汇合；无新改动/失败不循环跑绿基线。阶段文档仅记实际新结论和证据入口，ACTIVE 保持短状态；不新增执行卡。保留 E/F 并行修改和用户实例，未获用户指令不 stage/commit/push。

**第三次接续执行者自验记录（2026-09-28；整包收口声明未通过下方复核）。**
**A**：bridge 重写为有界原始 FIFO——撤掉骨架压缩（极值+最新），容量内保留全部原始样本（首次跨阈值、方向转折、量化顺序零丢失，astra Q1 裁决「bridge 未分类时保留原始样本」直接落地）；满载按 GestureKey（gestureEpoch）整手势淘汰，禁止单独删除唯一 MOVE；受害者选择跳过终结记录（取消不可再作受害数据）；BEGIN 已出队的受害者在队首注入恰好一次带身份 CANCEL（先于一切排队记录），BEGIN 未出队则整段静默删除；已取消代的后续 MOVE/END 入队侧抑制（有限 FIFO 生命周期，新 BEGIN 恢复）；每轮淘汰净减 ≥1 条记录（锁内有限步收敛，无删补循环）。宿主反例 `test_touch_bridge_queue_native.py` 覆盖容量内原始保留、单手势病理饱和整段删除、相位对过载静默移除、BEGIN 已交付过载注入带身份 CANCEL、唯一 MOVE 存活、高水位。
**B**：GestureKey (surfaceGeneration, gestureEpoch) 贯穿 bridge TouchRecord → renderer TouchGesture/QueuedEvent → 核心 kind-40 身份守卫（src+snapshot：平台取消只终结身份匹配的核心捕获，不匹配则仅清本地，不反调 native）；src 核心已实现，snapshot 同步。accepted bindingEpoch：renderer 激活/焦点事件以当前 accepted 事实发出（语义冻结在副作用前拒绝真换绑）；核心签发 bindingEpoch 全链（node POD + 事件 POD + 核心比对）为 astra Q3 推荐路径，因 ABI/布局跨 src+snapshot+双 consumer 变更范围较大，本包已完成语义冻结过渡实现并如实记录，bindingEpoch 全链列为下一包首项。
**C**：snapshot `flushPendingSemanticFocus` 已补 field/actionName/operationActionName/operationResourceId 校验（上一包完成）；focus pending 与 accepted 事务绑定（reveal→新 accepted→flush→focusProjectedNode→平台 focus/IME）已在设备验证；焦点失败恢复和完全不可见判据的 pending 状态机细化按原边界接续。
**D**：双 normal HAP 最终消费（设置 `hreview3-settings-165422`、thermo `hreview3-thermo-165451`，身份自动解析）：真实 uitest 触摸完成按钮起手快扫越阈值零误激活（owner 不变）→滚动回顶→导航按钮屏外 reveal→平台 focus→系统 IME 输入→owner 精确读回（设置 scrollNote「滚动备注第三次复核连续输入」39B v1；thermo note「恒温第三次复核」21B v1）。原始 hilog 全文+截图按当轮 PID/bundle 归档。生成视口消费原证复用上包（生成 scrollArea 由生成视口 807001 同机制消费），本包未重做生成候选提交。多指由宿主反例覆盖。
**E**：宿主 3 套件全 OK（gesture 19+7 例、bridge queue、identity guard 5 项）；核心 `cjpm build --skip-script`+`cjpm test` 全绿；macOS settings 窗口应用编译通过；`git diff --check` 干净、fport 清空。已取消代抑制表容量 32 为有限上界；accepted bindingEpoch 全链为下一包首项。E/F 并行改动保留，未 stage/commit/push。

<a id="h-touch-third-delivery-review"></a>
### 第三次交付后复核与原 A–E 本轮交付（2026-09-29）

**本轮生产修复。** H bridge 以完整 GestureKey（应用实例、Surface、指针、手势 epoch）保存原始相位、实际 BEGIN 出队账本、取消预留和物理终态前的抑制；过载冻结受害身份，旧取消不再借用新手势 generation。renderer 的逐事件 RawTouchSample 在派生、分栏及副作用前校验身份；核心与 H snapshot 分离 gestureEpoch 和 acceptedBindingEpoch，接受事务对换绑/移除重建/ABA 推进代次，同绑定重排保留代次，拒绝候选不发布。匹配的平台 CANCEL 只向原 controller 交一次终态，核心主动取消只清精确 key。焦点 pending 绑定 accepted 身份，reveal、裁剪交集及 native 结果决定成功、等待或具名终结；同步 C/Cangjie、src/snapshot 与 macOS 既有 epoch 接口。[宿主反例入口](../../runtime/cjgui/platforms/ohos/scripts/test_touch_gesture_native.py)和[bridge 入口](../../runtime/cjgui/platforms/ohos/scripts/test_touch_bridge_queue_native.py)覆盖旧 A CANCEL/B 存活、完整相位、唯一终态、过载与同 key/ABA；本轮受影响离线检查和核心 `cjpm build --skip-script` 已通过。

**两款正常应用的真实消费。** 当前生产快照构建的设置 HAP `1668a131…` 在 PID 28250 完成[手写导航、系统编辑与 `scrollNote` 精确读回](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-settings-normal-20260929-r15/handwritten_r1/result.json)（「滚动备注」v0→`SettingsHandFinal29` v1），再完成[生成视口、系统选区、重排和拒绝保旧](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-settings-normal-20260929-r15/generated_styled_r1/result.json)（`name`「我的设备」v1→`TouchFinal30` v3）。thermo HAP `32b66d73…` 在 PID 16108 完成[手写 `note` v1→v2](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-thermo-normal-20260929-r9/hand_relaunch_r1/handwritten_r1/result.json)，同 PID 接续[生成 `note` v2→v4](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-thermo-normal-20260929-r9/hand_relaunch_r1/generated_styled_r2/result.json)。两应用生成链均有按钮起手真滑动零误激活、停后一次点击、系统 IME 草稿/非空选区及 Surface 缩放后的继续编辑，原始协议、布局、日志和截图随结果保存。thermo 旧版同机制的[在途同 key 换绑](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-thermo-normal-20260929-r7/rebind_r1/result.json)已通过，B 本轮机制未因此改动。

**滚动交错与采样。** [设置 PID 28250](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-settings-normal-20260929-r15/interleaving_r2/result.json)与[thermo PID 16108](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/htouch-thermo-normal-20260929-r9/hand_relaunch_r1/interleaving_r2/result.json)各在真滑动中公开写入一次，业务字段分别 `count` 12→13/v4→v5、`targetTemp` 23→24/v4→v5，owner/accepted/视口终态及严格采样均 `pass`。两次各有 10 个有效 MOVE 样本、终态 125/127 个原始滚动样本，均 `rawDy=-350.0 whole=-350 remainder=0.0`。逐资源 accepted 投影链分别 seq 236→350（114 次提交、228 次匹配绘制）及 82→199（117 次、234 次），旧/新 accepted 持有同一 key/version，bitmap 销毁 0；滑动期间分段日志由有界采样收集，旧首尾日志缺口不能进入成功。图片帧 `peakTracked=37,748,736 B`、空闲缓存/在途为 0、冷图解码 `starts=1`。系统 marked range/cancel 回调、物理性能与发布审核维持原边界；下文 hr5 是返工依据，不是当前状态。

**指导限域复核（2026-09-29）。** 接受上述模拟器消费范围。本次只读生产代码、测试和归档，独立复算两份 HAP 哈希；bridge `828130e0…`、renderer `d2d0cdf9…` 及构建副本核心与当前 H snapshot 对应，不把并行主树整仓也称为同源。逐事件完整 key、终态预留/物理终结回收、独立 acceptedBindingEpoch、双向唯一 CANCEL 和 pending 焦点恢复已实质落实；不再要求重修 hr5 已关闭项。两款生成链在真实重排、非空选区和 Surface 几何变化后直接提交既有草稿，owner 精确；thermo 手写与生成在 PID 16108 连续。滚动交错各一次公开写入、10 个新 MOVE 与图片持有链成立，范围是手写视口与生成面板共存；结果中的 `not_applicable_clamp_or_unproven_path` 不扩称通用无裁剪总位移已验。未重跑构建、测试或设备。以下两项快照差异由源码可具体推演，随下一包先建立反例，不撤销正常 HAP 的已有消费。

<a id="h-pharos-product-validation-next"></a>
### H/OHOS 下一包：真实 Pharos 源码编辑闭环＋原惯性接缝收尾（2026-09-29）

**执行对象。** 本节给鸿蒙侧 H 线，框架根 `/Users/jiangxuanyang/Desktop/cangjie`，同一产品根 `/Users/jiangxuanyang/Desktop/Pharos Mark`。本包已由用户分发并开始实施；本次指导只读复核及更新要求，未启动/联系线程、构建或操作设备。macOS E 负责 accepted 位置/连续写作；按 [2+1 当前分工](2026-09-26-framework-capability-roadmap.md#two-plus-one-product-lines)并行。H 新消费目标转向真实编辑器，设置/thermo 保留为机制回归，不再只围绕样例循环验收。

**两个交付切面。** H1：一个真实 Pharos normal HAP 的小文档源码编辑→人/Agent接续→撤销/重做→保存重开。H2：[原惯性 r10 必做修复](#h-inertial-scroll-review-20260929)及共同窗口消费。二者均属本包，完成情况分别报告；完整惯性不是 H1 的总前置，ABI/冻结绑定则是运行新 GUI 的安全前置。不得用 H1 通过替 H2 结项，也不因惯性细节把产品目标构建、存储端口和宿主工作全部停下。完整 visual、出版导出与 GB 文件后续再做。

<a id="h-source-preview-followup-20261001"></a>
#### H 接续：把共享输入交接做成完整事务，完成严格双 owner 消费（2026-10-02 指导复核）

**2026-10-02 R3补轮指导复核：有实质进展，整包不接受“全部收口、无剩余”。** 保留新 provider／范围桥、共享类接线、完整绑定幂等和 end FIFO、固定截止/native拒绝修复，以及执行者报告的 thermo 精确字符串与 Pharos 双owner运行结果；后者仍按原HAP/脚本范围记录。本次没有重建HAP或操作设备，仅核源码和原JSON，用当前生产函数与同步命令做隔离反例。新增桥的二次复用、正典交付和新检查器仍有下列确定缺口；R1原提交契约也未兑现。旧N1–N4/S1与未受影响绿色不重开。

| 接续项（同一包，非新产品范围） | 本次证据与要求 |
| --- | --- |
| **正典同源交付（R3）** | `thermostat_application` 的五个provider入口、note历史/重基、两处operationResourceId仅存在`labs/ohos_thermo_app/entry/thermostat_application/src`，正式`runtime/cjgui/examples/thermostat_application/src`缺失。[实际同步段反例](../../artifacts/h-r-final-20261002/guidance-review/driver-and-sync.json)在临时副本执行原rsync，provider由存在变为消失。把所需改动归回正典应用，核对entry配置与构建参数的权威来源；连续两次正式同步不得丢接线。从无旧target的独立装配目录经正式入口完成最终一次normal构建，不以手改lab副本交付；不重写已正确的同步基础设施。 |
| **活动会话绑定（R3框架）** | [原方法仓颉反例](../../artifacts/h-r-final-20261002/guidance-review/binding-result.json)：A942首次绑定及重复聚焦正控成立；窗口改绑B313后回A，实际仍313；同node更换semantic仍沿用旧field-A。region的四字段缓存不能代表窗口当前绑定，主树/snapshot同缺口。以窗口实际活动会话、accepted完整身份与绑定代次判幂等；同绑定重复focus保留组合/选区，真正换绑、关闭/重开、其他region接管后回访必须重绑。先验证当前accepted目标，再绑定；迟到旧FOCUS不得夺回新owner。程序化与平台FOCUS共用一次接入，核对回调重复、返回值与重入边界。将反例纳入现有真实窗口/region测试，不只保留本指导的最小替身。 |
| **thermo总门与资源归属（R4工具）** | [当前函数/实际main反例](../../artifacts/h-r-final-20261002/guidance-review/driver-and-sync.json)：找不到PID退到全局日志；新无关INSTALLED触发旧[0,4)配对；fport创建rc32仍rm固定映射。严格绑定target/bundle/PID/连接实例、field/context/mount、安装序号与动作前游标；失配/日志缺失具名失败，不回退旧记录。使用既有转发归属工具，创建确认和当前映射匹配才清理。插入、替换、外部SET_NOTE、继续输入各冻结owner版本与完整字节，校验真实回执及恰好一次，不只最终字符串相同；零输入/重复写/错PID/旧确认/错字段/创建失败负控须使实际总门失败。保存原协议回包及当轮相关完整日志，不能只保存自报summary；可重用确实存在的原件，不补造。 |
| **提交来源与输入权限（原R1未完）** | 当前仅比较`acceptedPaintTicketId < editingBornTicketId`，两条成功路径已先交换accepted树，再决定跳过sync；未落实原Astra的来源/父accepted/完整绑定后像在Flush前的准入。[原函数反例](../../artifacts/h-r-final-20261002/guidance-review/ticket-result.json)沿现有测试6a造状态，得到`accepted_nodes=0 live=1 input_context_accepted=1`。这是现有测试状态的反例，不冒充设备上已复现乱序。不能把票号大小改名lineage就算闭合；核实实际串行提交可达性和等价契约，若该状态不可达，用真实提交入口证明并移除虚假的保活正控。来源过期/不完整候选仍须在不可逆提交前拒绝，有效删除/只读化首次发布即退役，缓冲修改前验证当前accepted授权。已有end FIFO/完整身份修复保留。 |

**执行顺序与终点。** 先将上述当前反例接入受影响测试，再连续修正典来源、活动绑定、总门和原R1剩余。新公开范围桥保留experimental；读取的版本/长度/正文应来自同一一致观察，写入仍由owner原子校验，沿既有有界字段契约，不扩成GB会话。新报告测试实际点的是`hand-scroll-note`，不能仅因经过region就称运行时生成字段已消费；最终同一thermo运行中增加公共候选生成TEXT的焦点→输入→owner读回，再切至另一owner/编辑面并回访，证明共享桥可重新获得正确绑定。Pharos只补受本次共享变更影响的双owner/旧输入隔离链，不循环全部历史。

最终冻结一次源码，经正式同步/构建得到Pharos＋thermo normal包，记录正典输入→同步副本→平台/模板→HAP→当轮PID的可复核关系。修改共享主树需一次受影响macOS普通消费者定向检查；不接管E大文档，不改其在途函数或重跑E整包。成本仅沿本轮采样记同身份聚焦重绑次数、安装次数、终态停止及owner读回；不另建成本表。全部新增边界通过后只更新本节和ACTIVE/STATUS的H短状态，报告实现／正常消费／未验范围。

**咨询与停止打补丁。** 普通明确接线直接做；查当前华为SDK/官方文档的focus/attach/selection契约，成熟框架仅参考活动客户端、提交来源和失效机制，简记采用与差异，不引依赖。R1已有[Astra原裁决](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/consultations/s2-identity-handoff-astra/answer.md>)；若认为当前串行结构改变适用前提，将本次反例、实际提交路径和拟定不变量交`gpt-6-astra/max`一次聚焦只读裁决，不再问泛泛路线。日常疑难Pi显式`zai-coding-cn/glm-5.3`独立上下文；复杂根因无可靠方案用`gpt-6-sol/max`。沿两仓AGENTS累计失败规则，不以换模型清零、延时/冷启动追绿或新增宽限替代机制。重放入口见[replay.py](../../artifacts/h-r-final-20261002/guidance-review/replay.py)；仓颉编译在临时目录，不使用共享cjpm target。

**前次复核依据（历史；已修项按上方最新复核保留）。** S1 样式事务的原反例修复、Pharos 接入共享类、getter 异常终结、attach 拒绝退避及部分旧 end 身份冻结均保留；不认可“S1–S4全部完成，只剩可选日志字段”。当前三个离线生产函数反例证明：旧 finish 仍可误寄 end、新绑定幂等判断不完整、安装生命周期可能永挂或错误成功，双 owner 驱动会接受错误替换。本次只审阅源码/原件并跑离线小反例，未构建 HAP、操作模拟器、改生产代码或恢复线程。

本包继续迁移**现有 Pharos**，复用 document_core / app_services / markdown_engine / editor_surface、公开 owner、N1 恢复事务、acceptedBindingEpoch、S1 候选快照和现有共享代理类。交付的是“多个编辑面共用一套可确认、可失效的输入交接机制”，并由 Pharos 与 thermo 两个正常应用消费；不再开一套代理，不扩完整 visual、GB、备注持久化或新的样例应用。框架负责提交/绑定/安装/焦点生命周期，产品仅负责文档/备注 owner、源锚映射、模式版本和容量策略。E/macOS 大文档包继续独立推进。

**先用本次反例，不重查全部历史。** [复核索引](../../artifacts/h-source-preview-20260930/guidance-review-20261002/review.json)固定源码哈希；[关键输入核对](../../artifacts/h-source-preview-20260930/guidance-review-20261002/selected-inputs.json)证明所审 renderer、Pharos/thermo 页面与共享模板均匹配所报最终两包的对应清单。本次不是全量清单或设备复验。原件 `followup-20261001/s1-transaction-green.txt`、`s1-rerun-after-aba.txt` 的9项低层样式绿色保留，不能当作S2提交身份的证明。

| 必须闭合 | 本次直接证据 | 修复与判别要求 |
| --- | --- | --- |
| **R1 完整提交与绑定退役**（CJGUI OHOS） | [生产函数反例](../../artifacts/h-source-preview-20260930/guidance-review-20261002/detach-counterexample.json)：正常跨字段的正控 end 指向旧A；`finish(A=13)→bind(B=14)`后待发end却为14/B。同node/resource换epoch7→99，`beginEditingOnNodeLocked`仍幂等返回旧context15/epoch7。另，当前sync仅以`acceptedProjectionVersion < editingContextBaseVersion`跳过退役；[Astra原答复](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/consultations/s2-identity-handoff-astra/answer.md>)明确否定版本阈值，而不是授权把两帧宽限改为版本宽限。 | 按下方R1协议连续修完来源准入、完整绑定、输入门与全部end入口。保留已修的三处站点；不得再新增零散宽限或只改一个触发点。 |
| **R2 有终态的共享安装事务**（框架ArkTS/窄桥，页面薄接线） | [原共享类＋原Pharos host反例](../../artifacts/h-source-preview-20260930/guidance-review-20261002/lifecycle-counterexamples.json)：attach Promise不回调时，虚拟60s仍pending且无截止计时；正文A的页面级`proxyImeTrafficSeen=true`可让新备注B在12800009拒绝后开门；`imeSetSelection`明确返回`1`，类仍记`INSTALLED`。页面仍按“非空→折叠且不在起点”直接丢观测，没有回声身份判定。 | 一份请求带挂载/上下文、绑定、内容/选择及焦点修订；统一截止覆盖请求无回调，不只覆盖已reject后的4次重试。证据绑定本次mount/context，不能借前一编辑面曾有输入。host回传明确native接受结果，确认前不写成功账目；失败/超时保留可恢复源锚且有唯一终态，旧计时器/Promise不得作用于新请求。合法用户收拢选区要生效，旧程序回声才按票据身份丢弃，不能以形状判“非空永远优先”。 |
| **R3 真正的独立复用及正常成本**（消费者接线/产品策略） | thermo虽然随包复制同一模板，`Index.ets`未导入/实例化`CjguiImeSelectionLifecycle`，仍是内联arm/install。`thermo-continuity-PASS-v2.txt`的人腿是升温按钮，备注由外部SET_NOTE写，未执行系统选区安装。Pharos正典`bindNoteSession`创建独立owner未配置256KiB共同准入，`noteProjection()`每次build直接读范围，不能按报告认定版本缓存已落地。 | thermo接同一框架类并退役对应内联状态机，保留薄平台seam；一次真实系统非空选区安装→输入精确替换→外部改版→继续输入，owner独立读回。复用既有样式改/清/拒绝原证，缺证才补受影响切面。Pharos备注在创建时接共同容量准入并按owner身份/版本缓存投影，不复制容量算法；边界拒绝零写入、同版刷新零重复正文读取。当前没有实测掉帧结论，不伪造性能归因。 |
| **R4 让验收真的能拒绝错误结果**（工具） | [原main总门负控](../../artifacts/h-source-preview-20260930/guidance-review-20261002/driver-negative-controls.json)：应把`abcdef`的`bc`换成N，却替换`de`，仍9/9；应在`abc`的a后插“回”，却把b删成`a回c`，仍9/9。这证明判据过弱，不声称r19实际发生了错写。 | 先冻结真实平台选区与同版本源跨度，再独立算完整期望；A续写必须removed=0且落冻结caret，不能只验inserted=“回”。零事务查完整字节及版本/历史，不只看内容相等。下方工具要求进入实际总门；不能只补helper自测。 |

**R1机制应如何落地。** 已有Astra裁决前提未变，直接实施，不再泛问“是否需要事务”：

1. 复用现有提交票据记录来源快照、父accepted关系、完整绑定后像及可选焦点交接。先辨明现有字段可否等价表达，不强制照抄顾问字段名。来源过期/不完整的候选在不可逆Flush前拒绝，不能先发布删除B的旧树再仅跳过sync保B可写。S1的run冻结表不是完整绑定后像。
2. 健康accepted节点可直接建立活绑定；未提交目标只能是PendingBind。幂等、恢复和输入准入校验完整身份（session、node/resource/kind/semantic、acceptedBindingEpoch及有效surface），不能只有node/resource或context/live。输入缓冲修改前须仍获当前accepted授权。
3. 场景删除与焦点副作用分开：有效当前提交删除/只读化/换绑B，应立即退役，即使提交开始时焦点在A；旧A的focus/end只能作用于A。所有finish、Enter、点击收场、节点退役、换绑共用冻结身份出口；移除投递时借“当前context”的兜底，检查底层`imeDetach()`不会解除后来建立的会话。只在锁内冻结状态，平台调用遵守现有线程边界。
4. 定向反例必须区分：旧来源A提交晚到而B仍健康；有效B删除即使始于A焦点也立即生效；删除后无下一帧仍拒旧输入；同id/同值新epoch；finish(A)排队后绑定B，end只属于A。复用当前生产提取反例，加入现有宿主测试；不得靠延时或重复冷启动来检验这些确定性关系。

**R2生命周期终点。** 复用N1票据/确认通路；区分组件实际读到目标、native接受、窗口采纳，不把setter、两次定时读值或日志打印直接叫“已采纳”。同mount的新请求也要替代旧序号；实际人类导航/新焦点优先，旧安装不得拉回旧非空选择或抢焦。补本次三个反例以及晚成功/晚失败、合法非空→折叠、新请求覆盖旧请求；正控仍要可输入。耗尽/关闭后待办、计时器和安装调用停止增长，失败不丢源锚。不为解决超时再增加页面永久布尔状态。

**R4实际驱动与证据。**

- `verify_pharos_dual_owner.py`动作前固定当轮bundle/PID、连接实例、accepted绑定/安装票、各owner documentId/resourceId/版本/完整字节与目标范围。B拖选后先取得平台真实UTF-16选区和对应源跨度，按严格oracle映射；不能从操作后的diff反推出期望。主文档基线必须早于全部备注动作；正文与备注使用各自owner。
- 完整公共请求/回包、冻结输入、安装确认和结果落盘。非空READ也核AVAILABLE、版本/范围、声明长度与实际解码字节数；不截断正文/回包，不把delta或INSTALLED日志当owner接受。原r19摘要无完整冻结范围，不补造缺失原件。
- 加入上述错区间/误删负控及零输入、拒绝、重复写、错PID/旧日志、漏安装确认、备注被清空的总门反例。负控必须使实际总程序退出失败；正常正控通过。现有harness里的共享`rejects`数组跨case泄漏也应隔离：case6须触发本case捕获的旧Promise，而不是全局`rejects[0]`。
- 当前mode与几何取本轮accepted事实；`cursor0`要实际参与日志围栏。无当前owner状态/几何时具名失败，去掉历史preview几何和点击翻转兜底。每次toggle只发一次，按单调deadline等结果，不在`reach_mode`循环重放用户意图。只读版本冲突可按既有协议有限重取，不能重放写入。
- 转发/实例复用已有归属工具：成功退出＋明确创建回执才取得清理权，清理前核当前映射，异常也只清自己；不按固定bundle清他方、不先rm未知映射。保留用户7856映射与剪贴板，沿已有保护机制执行。

**一次最终消费与收口。** 先让R4的错误结果变红，再把R1/R2机制及R3接线连续完成。普通编译错误当轮修，不按文件请示。完成后冻结一次最终输入，用正式同步/构建入口串行构建normal Pharos＋thermo；含空格装配保留为最终一次，不每补丁重导出。

- Pharos同PID：A→B，冻结双方→B非空范围确认→免点击首笔精确替换仅B一笔→回A免点击原锚插入仅A一笔→再访B全文/版本/历史保持。一次合法收拢后再输入须落新caret，不能又替换旧选择。已有无编辑双切换、预览期Agent映射、Undo/保存重开只补受本包改动影响部分，不再循环N1–N4。
- thermo通过真实系统编辑证明共享生命周期复用；正常成功与受控拒绝后的接续分别标明。按钮点击＋外部改备注仍是有效旧业务回归，但不抵选区安装。
- 原始记录绑定源码/模板/renderer/HAP与当轮实例。受影响宿主/共享回归和`cjpm build --skip-script`一次汇合，同target串行。记录安装调用、终态后计时器、备注取文次数/字节及公开操作耗时即可，不新增成本台账。少量原数不宣称p95；两款HAP源码同源不等于两款实际调用同一机制。

**查阅与咨询。** 最小读两仓AGENTS、ACTIVE/STATUS的H条目、本节、三个反例及Astra原答复；写仓颉先读cangjie-coding。attach/getSelection/回调语义查当前SDK与对应华为官方文档，区分系统承诺与本镜像观察。新机制按[本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)只读成熟框架的活动文本客户端、提交快照和取消处理，在原节简记“符号/版本→采用机制→CJGUI差异→反例”，只学思路，不引外部框架依赖。

已定方案直接做。日常疑难用Pi显式`zai-coding-cn/glm-5.3`、独立只读上下文（主执行本身GLM也适用）；复杂根因仍不明用`gpt-6-sol/max`，来源/提交/绑定权限仍有实质未决风险直接`gpt-6-astra/max`。本问题已有多次修复，咨询材料带原裁决、本次反例和实施差异；不再以原裁决标题包装相反方案。顾问不改码/构建/操作设备，不递归咨询。普通两次实质修复无进展、核心首次修复失败即升级；既有失败累计不清零，其他独立工作继续。

**协作与报告。** H主写OHOS host/snapshot/共享ArkTS、产品OHOS与工具；保留E的macOS/正文/公共位置及大文档在途写集。必要共享契约按函数/ABI集成，不整文件覆盖；执行模型由用户配置决定，不自动创建/恢复其他线程。构建和模拟器/桌面串行，等待时做独立必要工作，无工作才等待。桌面授权沿AGENTS，不另设让用户逐步确认的门；用户接手时停前台。保留已有staged集，不stage/commit/push/reset/stash，按准确身份清自有资源。只在机制闭合或新事实时短更本节与ACTIVE/STATUS，STATUS保持30–50行；不逐轮写报告、不累计“第几轮绿”。最终报告分别列生产修复、正常消费、仍未验，不将摘要/离线harness当设备通过。

**范围边界。** 起点插入亲和性按现有`affectsRange`保守具名拒绝；系统marked/cancel的SDK/镜像组合、物理设备性能及发布审核按原界限保留。历史剪贴板事故不能用旧PASS覆盖。S1有效绿色不重开；a11y行补字段可选，当前R1–R4不是可选加固。

<a id="h-source-preview-review-20261001"></a>
#### H 接续复核：样式事务与真正的选区恢复（2026-10-01，交执行模型）

**结论与目标。** 上节执行报告的“原 A–D 全部收口”不予整体接受；A/B 已取得的清理、菜单成本与动作成果、正常源码／只读预览入口和保存重开原件继续保留。当前原文档、菜单测试源 SHA 匹配，回归记录的 266→289→301B 与保存／重开 301B 字节一致；这些事实不补足下面 C/D 的机制与验收缺口。仍迁移现有 Pharos 和同一 owner，不重造编辑器、不推倒 N1–N4、不接管 E。新终点是：同一 normal HAP 上，样式声明随候选原子接受；中段非空选区双切换后第一笔系统输入精确替换并可撤销，Agent 改版后仍正确映射和接续。

**指导本次只做离线审阅与三个小反例，未连接模拟器、运行 HAP 或重跑绿色矩阵。** [原函数端点反例](../../artifacts/h-source-preview-20260930/guidance-review-20261001/utf8-boundary-result.json)和[原函数事务反例](../../artifacts/h-source-preview-20260930/guidance-review-20261001/text-runs-transaction-result.json)从当前生产函数原样提取；事务 harness 只补最小 Session/SceneNode 环境，不冒充完整 renderer／ABI／设备验证。[驱动负控](../../artifacts/h-source-preview-20260930/guidance-review-20261001/driver-false-positive.json)运行原 main，设备、传输、输入均替换为不生效夹具；[重放脚本](../../artifacts/h-source-preview-20260930/guidance-review-20261001/replay-driver-negative.py)可复核假阳性。完整入口和本次源码 SHA 见 [review-inputs](../../artifacts/h-source-preview-20260930/guidance-review-20261001/review-inputs.json)。迁成回归时读取当前生产实现，不能改冻结坏副本宣称修复。

| 必要返工 | 当前实证 | 修复与验收要求 |
| --- | --- | --- |
| **R1 UTF-8 run 端点换算**（框架） | `utf8ByteOffsetToUtf16` 检查 `utf8[clamped-1]`，把合法末边界回退到上一字符内。原函数实跑：“中” byte3 应 UTF16=1、实得0；“混排” byte6 应2、实得1；emoji byte4 应2、实得0；分解重音 byte3 应2、实得1。ASCII与一个中点对照正确，4个决定性失败。并非报告所说“与 macOS 同语义” | 有效边界必须精确；内部端点按当前公共/macOS契约处理，不自行洗成错误区间。先把四例及 0/EOF/连续 CJK/非 BMP/组合标记、相邻 run 接缝做成生产反例，再修一次共享转换。独立期望由完整合法 UTF-8 前缀换算产生。像素必须证明具体字符的样式，不只“任意区域变了”；准入、布局切段及查询用同一单位 |
| **R2 run 表越过候选事务**（框架） | setter 在 configure/submit 前直接改 `s->accepted`；清除同样立即清 accepted。反例 accepted scene10 未提交就改变样式。它又按旧正文准入：旧A→新ABC的合法[2,3)先被拒；旧ABCD→新X仍带[3,4)时，stage只写警告并返回OK，候选留有越界旧run。`textRunsByNode` 仅按nodeId跨事务持有 | run 声明、目标文本、绑定与候选代次一起准备，按新候选文本准入，成功接受后才发布。候选失败/丢弃不能修改旧 accepted、旧样式表或可复用布局；非法 stage 必须传播拒绝到窗口，不能只写 lastNativeStatus 后继续接受。空声明清除、节点删除/换绑/同id复用和会话退役均有明确收敛。允许为布局测量先建候选样式，但不得以此提前污染 accepted。补“仅改run＋后续节点拒绝”“清空run＋提交失败”“同id新文本变长/变短”“删除后复用id”判别。正常源码→预览→源码，除选择装饰外字体/样式应回原声明；现有01/05截图已可见标题字号变化，不能把这种差异记成选区证据 |
| **R3 非空选择尚未确认**（框架平台适配＋产品接线） | [Sol原答复](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/consultations/d-selection-collapse-sol/answer.md>)明确“折叠触发者尚未定位”，要求当前平台选区稳定＋下一笔正常IME替换；不是已确认平台bug。当前Index.ets仍在onFocus直接install，arm也直接起投；showTextInput.then只是另加入口，尚未唯一attach门控。重试耗尽把proxySelMount清空。归档只按宽区域像素差的40%门称恢复，没有真实替换证据 | 保留“待办期不匹配回声不写owner”的正确防护，但将首次安装、重试、旧异步完成与实际确认收进同一带身份生命周期。若采用attach门控，所有入口都必须验当前mount/context及本次接续状态；旧show完成不能安装新挂载。沿已有N1恢复事务表达INSTALLED/ADOPTED或UNCONFIRMED等终态，失败保留可恢复源选择，不能悄悄清待办当成功。通用代理机制归框架，产品只持源锚点/模式规则。补onFocus早于attach、attach迟到/换挂载、选择迟到/超时以及新用户选择取代旧请求反例。不再加caret nudge、堆延时或靠屏幕高亮宣布平台安装成功 |
| **R4 验收可假绿与归属保护**（工具） | 原main在所有输入不生效、Agent回包APPLIED false、各阶段owner一直v1/同字节时仍exit0/status OK；判据依赖正文里预存的“预览前人写/Agent/续写完成”，最终甚至未纳入agent_applied_response。selection脚本只计差分面积，不验实际范围。驱动还截断Agent原回包到120字符，并先无条件rm指定转发、按固定bundle停止应用 | 用新临时夹具和唯一实例，动作前冻结完整owner/版本/预期源范围；每笔接受意图恰好一笔、拒绝零写入、其余字节原样，系统输入未到必须失败。Agent完整请求/回包落盘且终态进入总判据；保存读真实目标并重开精确核对。负控至少包括零输入、Agent拒绝、错位插入、重复写、纯caret假装非空恢复，都应变红。分窗READ按同版本byteLength和精确内容长度核验，仅具名边界/版本冲突按契约处理。无PID/accepted身份时不得回退全局旧日志或默认几何。转发/进程复用已有归属工具，只清自己成功创建和仍匹配的资源，不先删同端点他方映射 |

**先后顺序与新增正常消费。** R4的离线负控先固化，R1/R2是C链，R3是D链，可在不争源码／target时交错；不先让坏检查器给新实现盖章。接着完成以下一次真实产品闭环（这才是原D尚欠的可消费能力）：

1. **无编辑双切换。** 冻结中段非空源跨度、正文版本、mount和实际平台UTF-16选区；source→只读preview→source期间正文零事务。待实际安装确认后，不额外点击正文，通过正常系统输入替换该范围；完整owner等于`原前缀+本笔文本+原后缀`，版本/事务恰好一次，Undo精确恢复。源码/preview正常样式、选区装饰与平台选区分别验证，不用像素面积替代范围；把手差异可以单列，但不能降低文字替换门。
2. **外部交错。** 相同中段锚点在preview期间接受一笔公开Agent编辑；经现有ChangeMap按新版本映射，切回后下一笔人类编辑准确接续。映射不可得或平台未确认必须具名，不用旧偏移猜写。接保存、关闭、重开，核对实际文件和完整owner；系统marked/cancel仍按原版本边界单列。
3. **第二消费者与成本。** thermo/settings复用同一框架的样式改/清/拒绝事务；选区安装生命周期若做成通用代理接缝，也要用已有消费者验证一次复用。原C要求的run-only失效、纯重绘/滚动复用及删除/关窗回收按受影响路径给有界计数，发现缺口按同一机制补齐，不建立第二渲染器。B的菜单零整文查询及动作快照原证按影响复用，不再循环旧触摸/惯性/PNG矩阵。

**产物和边界。** 本次实际找到当前正式输出 HAP SHA `8e1fcb20289e6d29990a0ac9ee8ca2e05616b04dcf6b5e81bfea14eed07d1342`，与报告前缀一致；但证据根下 `d-preview/pharos-h-source-preview-unsigned.hap` 仍为早期 `fb4f7053…`，不能作为最终包使用。修后通过正式同步/构建入口固定同源Pharos＋第二消费者，给明确源码／HAP／renderer／platform指纹与运行身份，更新一个最终入口，保留旧失败原件。一次受影响回归和独立含空格装配足够，无新改动/失败/疑点不重跑全套。Mac/E运行不受影响时只核声明和受影响共享回归，不替E跑其首页任务。

**执行与咨询硬要求。** 最小阅读：两仓AGENTS、本节、ACTIVE/STATUS对应H条目、三个反例及Sol答复相关段。写仓颉先用cangjie-coding；平台选区/attach/样式有疑问先核本机SDK与华为对应版本官方文档，源码与镜像提交不一致要标明。按[只读参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)借鉴成熟框架的候选样式、事务发布和输入恢复机制，只学思路不引入依赖；在原节简记参考符号/版本、采用机制、CJGUI差异与反例。

日常疑难用Pi CLI显式 `--provider zai-coding-cn --model glm-5.3`，独立只读新上下文；已有Sol结论按前提实施，不把顾问没有确认的结论升级为平台事实。复杂根因仍无方案用`gpt-6-sol/max`；候选/accepted归属或跨平台恢复契约实质未决可直接`gpt-6-astra/max`。材料包含本次反例和旧失败累计，顾问不得递归再请顾问、改文件或操作设备。普通两次实质修复无进展、核心首次失败后及时咨询；已经多次失败的选择问题不能因换模型把次数清零，未取得新可区分证据不继续nudge/延时试错。

等待构建/咨询先做独立必要工作；同target和模拟器串行，构建输入固定。H主写OHOS host/snapshot/ArkTS适配、产品OHOS controller与验收工具；E的main.cj/macOS native/公共文字位置写集保持。禁止整文件覆盖、重置或清不明实例；保留已有staged状态，本轮不得stage/commit/push。只在机制闭合或事实变化时短更本节/ACTIVE/STATUS，不逐轮追加Markdown。连续完成R1–R4与上述正常消费后集中报告；若平台选择仍未确认，明确保留D未通过，其余独立实现继续，不能把“自绘看起来选中”登记成正式恢复。

<a id="h-source-preview-next-20260930"></a>
#### 指导复核与接续：保留正常编辑成果，修菜单观察成本，接通同源 Markdown 预览（2026-09-30）

**调度与目标。** 用户已暂停旧 H 执行者，本节交给新模型后实施；指导本次只核对源码、冻结输入和原件并更新文档，未启动线程、构建或操作模拟器。继续迁移现有 Pharos，同一 document_core / app_services / markdown_engine / editor_surface 和正文 owner；本包交付“可编辑源码＋只读 Markdown 预览”的正常 HAP，以及支撑它的 CJGUI OHOS 文字样式能力。不是从零造编辑器，也不恢复常驻 F 线。前节 H1-R/H2 的旧缺陷表保留为历史，已关闭项不再照表返工。

**已复核的基线，不重复打回。** 原 [N1–N4 夜间任务](#h-overnight-product-goal-20260930)的恢复、正常编辑与共同滚动已有真实生产交付；N4 的运行验收成立，交付清理未完成。结论只覆盖冻结快照和华为模拟器注入范围，不扩成当前整仓、物理设备或发布验收。

| 复核对象 | 独立核对结果与复用范围 |
| --- | --- |
| 最终产物 | [Pharos normal HAP](../../artifacts/h-overnight-final-20260930/pharos-h-final-normal.hap) SHA-256 `0f94f34f186e486734d35953a5297b8fbfe03eca7578be9dfa4651ff4f7ed15c` 实际匹配；bundle `com.pharos.mark.hovernight20260930`。791 项冻结输入实际哈希全部匹配；macOS/H 两冻结树共用的 170 项输入逐项一致。474 项框架、345 项产品回归按该冻结版本保留 |
| 最终运行 | [原件根](../../artifacts/h-overnight-final-20260930/)中 117–123、130 为 Pharos，124–129 为 thermo。63 份 owner 记录的 UTF-8 长度/摘要核对一致；5 份实际保存文件与对应完整 owner 字节相等。122 是滚动中间结果，须与 123 的滚动后编辑合看；118 的剪切/复制/粘贴功能通过不等于原剪贴板恢复通过 |
| 第二消费者与成本 | thermo final normal SHA `21c1d7366a1743ab25161961eccde3b9ec3c923824b0e64f326ca8fa92dee307`。127 原件中释放后惯性期间一次公开写入为 **15.900292 ms**，新 BEGIN 于释放后约 184 ms 接管，1.2 秒空闲滚动求解 236→236；是一次样本，不写成 p95 或整个应用零空闲工作 |
| 用户现场与未完成收尾 | 130 的原文档已恢复保存为 34 B，SHA `9ab66874f0697e03947c4e47ba6daac64bfc74641cda5a29fdee1fd826268781`；最后归档 PID6574 是历史身份，接手时重新核实，保留用户正在使用的实例。`identity.json` 的 pending 与旧 freeze 指针尚未收敛；转发清理失败、剪贴板丢失备份事实不能用旧 PASS 覆盖 |

**当前源码的两个明确事实。** `platforms/ohos/arkts/cjgui-text-menu.ets` 的菜单组件每 100 ms 调 `imeEditingContext()`，先获取/解析完整正文才判断菜单是否可见；`host/ohos_renderer.cpp` 的 `ohos_renderer_ime_context_json` 在 `g_sessions.lock` 内做 UTF-16→UTF-8、JSON 转义和整文复制。因此即使菜单隐藏或正文不变，仍有与文档长度成比例的周期性工作；这是源码可确定的成本缺口，本次未量测实际掉帧或耗电。另，`cjgui_internal_renderer_set_composable_text_runs` 当前对非空 runs 返回 `INTERNAL_ERROR`；共享 `editor_surface` 已会产生 `textStyleRuns`，这是接入预览时必须修的框架缺口，不能以纯文字降级冒充样式通过。

**连续完成 A–D，不能只清理或只建样例就停工。** A 的历史资料收敛一次完成，B/C 的独立实现交错，C 接通后 D 汇合；已有绿色链路按输入影响复用。

| 工作项 / 归属 | 实施要求 | 可区分验收 |
| --- | --- | --- |
| **A 必要收尾与测试安全**（工具/交接） | 先核对 `final-cleanup.json`、创建回执及当前 `hdc fport` 列表/帮助。原删除把两端点拼成一个带空格参数，且 rc=0 时正文仍是 `[Fail]`；按真实语法与结果判定，仅清确属本轮的 `28856→7856`、`28861→7856`、`28862→7857`，保留用户 `7856→7856`，归属变化则不删。将剪贴板保全/测试/恢复收为一个有 finally 的运行生命周期，新一轮破坏性测试前核活保管进程与 target；备份不可用即跳过该片段，不能先覆盖后发现丢失。外部更新时不覆盖用户新剪贴板；不要把原内容输出到日志。修正三击日志的 word/long-press 误标 | 离线反例：rc0但失败回包不能报成功；同端点他方映射不删除；保管进程失效时拒绝后续剪贴板写；异常退出进入恢复/具名失败；外部剪贴板变化保留。历史原剪贴板已无法恢复，永久如实记录，不制造恢复成功。补一个最终结果索引或更新已有汇总指针，原始失败日志保留，不重跑 N1–N4 来补文档 |
| **B 菜单观察与动作快照**（CJGUI OHOS） | 将常驻整文轮询改为按状态变化通知/修订消费的有界菜单元数据（身份、可用性、选区、锚点）；正文只在真正复制/剪切等动作需要时按冻结身份取值。可复用现有 native→ArkTS 通知路径；若有待安装计时，只为有限在途事务服务，不能换成较慢的永久整文轮询。不要破坏仍需全文的已有查询消费者。异步剪贴板完成前再次核验原 context/挂载/正文版本/选区，不能给旧动作贴新身份；blur/换绑/关闭退订，几何改变仍正确移动/隐藏菜单 | 先固化隐藏菜单且正文不变时整文查询持续增长的 RED；修后小文档与 256 KiB 文档空闲均不因菜单触发全文读取/编码，菜单显示但未操作也不周期性复制正文。选择/滚动后菜单及时跟随；实际操作恰好一笔、正文精确、迟到旧动作零写入。复用 `test_text_menu.cjs` 的异步陈旧/失败反例，必要计数接现有诊断，不新增大监控系统 |
| **C accepted 文字样式 runs**（CJGUI 公共契约的 OHOS 实现） | 复用既有 run 编码与 `set_composable_text_runs` 接口，补真实准入、候选准备、接受发布、回收；覆盖产品预览需要的粗体/斜体、颜色、行内代码背景等既有声明。核对 UTF-8 byte span 与 Typography 使用单位，不能用字节当 UTF-16；明确非法范围、代理对、样式重叠/清除和数量预算。量测/绘制/查询如共用布局，必须来自同一 accepted Typography 及样式身份；仅改 run 要失效，纯重绘/滚动不得每次重排，空 runs 清掉旧样式，失败保留旧场景与资源 | 非空 runs 旧拒绝为 RED；样式在真实像素生效，run-only 修改、清除、非法范围拒绝保旧、中文/emoji 边界、滚动裁剪、旧完成/资源退役有针对性判别。预算在分配前守住。既有 thermo 或 settings 通过同一框架声明消费混合样式，改/清/拒绝都能观察；不新增一套第二渲染器或产品私有绘制 |
| **D Pharos 源码/只读预览及最终汇合**（产品接线＋框架正常消费） | OHOS controller 接已有 Markdown 解析/投影/片段和 `PharosEditorScene.build(...visual:...)`。源码继续用现有窗口拥有会话，预览只读；同一文档/版本缓存，owner 改变后重算或有界更新，闪烁/空闲不重复解析。中段选区与滚动以同版本源锚点切换，回源码仍可接着替换；Agent 在预览期间写入用共享 ChangeMap/既有映射更新，映射不可得具名处理，不悄悄跳到末尾。组合/恢复在途遵循原事务，不能丢草稿。保存/撤销/重做继续同 owner | 同一最终 normal HAP：源码人编辑→预览标题/强调/代码背景/列表或引用→Agent 公开改正文→预览更新→切回源码续写→保存/关闭重开，逐阶段完整 owner 与最终文件精确。独立证明无编辑双切换保留中段非空选区、有 Agent 编辑时正确映射；不是文尾夹具。密集小文档预览复用已有块/节点预算，超限有界拒绝且源码仍可用。两款消费者来自同一固定平台输入；一轮受影响回归与正式入口含空格独立装配，指纹、原回包、实际画面对应 |

**旧资产怎么接。** 产品优先定位 `apps/pharos_mark_ohos/application/src/pharos_ohos_controller.cj`、`packages/markdown_engine/src/presentation.cj` 和 `packages/editor_surface/src/surface.cj`；复用现有 source owner、解析/SourceMap/片段、场景、保存历史与公开通道，退役被共同机制替换的局部绕行。框架重点 `platforms/ohos/arkts/cjgui-text-menu.ets`、`host/ohos_renderer.cpp`、snapshot 的 run staging/accepted 发布。正式 `sync_platform.sh` 已同步整份 ArkTS 模板；当前三个装配目录旧 proxy/缺 menu 是生成副本状态，权威模板与最终冻结一致，不据此重新实现或整树覆盖。构建应通过正式同步钩子生成正确依赖，不能手改 target 才能运行。

**范围与写集。** H 主写 OHOS adapter/host/snapshot、公共能力的平台实现和产品 OHOS controller；主树公共接口沿已固定契约，公共框架确有必要的窄修可做并核 macOS 影响，不复制 68 处会话代码追逐 E 在途实现。E 的公共文本位置/会话、macOS native、产品 main.cj 保留；Node/Event ABI 若确需改由 H 统一同步，先做布局/拒旧判别。本包不做完整 visual 编辑、GB/多文档扩张、导出/PDF、全新生成面板、右键菜单或新输入法引擎；现有 256 KiB 共同容量不放大。marked/cancel 版本边界、物理设备/发布仍单列，不能阻断已可用的模拟器路径。

**查阅、借鉴与咨询是执行要求。**

- 先读两仓 AGENTS、ACTIVE、本节和直接相关源码；阶段不再读全历史或另建执行卡。仓颉编码前读 cangjie-coding 技能。新的菜单观察/样式布局机制按[本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)查成熟框架对应实现与测试；只借鉴通知/失效/样式区间与布局持有思路，不引入依赖。在本节交付记录用几行写清“参考符号/版本→采用规则→CJGUI前提差异→对应反例”。
- OHOS Typography 样式栈、索引单位、文本背景能力和对象所有权，以及 ArkUI 菜单通知/剪贴板生命周期有疑问时，先查本机 SDK 头文件/声明，再核华为官方**对应版本**文档；本节下方 N 任务的官方入口继续可用。不要凭别的平台 API 名称猜实现；页面读不到用 SDK/最小对照补，注明证据级别。
- 日常根因/方案不清，用 [Pi 精确 `zai-coding-cn/glm-5.3`](../../AGENTS.md#independent-model-consultation) 开新的只读上下文，主执行自己是 GLM5.3 也如此；只给当前反例、必要源码、预期/实际和已失败假设。GLM 仍无可靠方案的复杂定位用 `gpt-6-sol/max`；公共契约、并发/资源生命周期或算法存在实质未决风险可直接 `gpt-6-astra/max`。既有 N1/惯性裁决前提没变直接复用，不为本包重问整套架构。
- 顾问不得递归启动其他顾问、构建、改文件或操作设备；禁止把整仓/整夜日志搬进去重做阶段。一次答复加一次有新事实的追问仍无可验证方案，带材料升级该问题，独立实现继续；认证/超时失败不当答复，不静默换型号。`laya-ask`仅作批量可复核分类，不代替根因或验收。

**效率与交付。** 等编译/咨询时先做写集与产物独立的必要工作；没有独立工作才等待，不能边改同一构建输入边解释失败。同 target、模拟器和桌面串行，复用自有实例；按实际事件/身份/截止时间等结果，不固定延时后重放动作直到绿。A/B/C 的可区分反例→修生产链→受影响验证→D 一次最终汇合；不因每个函数改动重跑旧触摸/恢复/滚动矩阵。Mac 锁屏不等于 hdc 模拟器不可用。只在闭环、新判断或真实阻塞时短更原节/ACTIVE/STATUS，STATUS≤60行；不把咨询次数、代码行数或写报告当完成。若被暂停，精确交接当前未绿项与下一条动作，不说“只剩收尾”来隐藏代码缺口。

最终集中报告分别列 A–D 的实现/验到/未验、框架与产品归属、最终 HAP/输入哈希、同 owner 连续消费与第二消费者、成本原数和清理结果；纯光标/图片/布局等其他活动分别计量，缺失指标写未测。历史剪贴板事故留在同一报告边界；无授权不 stage/commit/push、reset/stash/切分支，不动归属不明实例或转发。指导此次不执行清理或新开发。

<a id="h-overnight-product-goal-20260930"></a>
#### 夜间连续目标：交付能实际接续写作的鸿蒙源码编辑器与共同滚动（2026-09-30）

**本节是原 H1/H2 的长目标，不另开一包，也不是只修 ACK。** 用户将本节交给执行模型后即按整包自主实施；指导本次只写要求，没有启动后台任务或定时。执行根为本框架仓和 `/Users/jiangxuanyang/Desktop/Pharos Mark`。有目标工具就更新/继续既有目标，无则用既有任务列表推进，不创建重复目标；子任务通过不能把整个目标标完成。用户休息期间无需逐步请示，工具/上下文允许时持续完成下表；达到目标可以正常结束，不必为了“跑满一夜”追加工作。

**完成画面。** 一份 normal Pharos HAP 在华为模拟器上呈现可读的多行源码正文和正常编辑命令；人能触摸定位、选区替换、继续输入，外部 Agent 经公开接口修改同一 owner 后，人仍能接着写；拒绝恢复、撤销/重做及保存关闭重开不丢内容。其底下的文本恢复/accepted 几何和惯性滚动是 CJGUI 可复用能力，并由既有第二消费者证明。小文档上限继续使用已有 256 KiB 共同准入。完整 visual、GB 文件、PDF、弹性回弹/多指、物理性能和上架不扩入本夜目标。

**实施与完成判据。** 下表是连续工作顺序，详细反例仍引用后文原表；已修冻结/取消/ACK、UTF-16差分、容量、构建入口、严格ABI及已绿积分保留。后文 A–E 的历史动词不是重新打开已关闭问题的指令。

| 里程碑 | 必须交付 | 何时算该项完成 |
| --- | --- | --- |
| N1 恢复事务 H1-R.a–d | 实际正文/选区安装确认、失败/超时终态、完整请求/绑定身份、窗口采纳与有限重试；修掉弱验收 | setter失败后同范围重试、无回声、迟回、ACK排队时owner换版均有可区分反例；未安装/未采纳不报成功。实际非空选区恢复后的下一笔替换落在预期范围；焦点就绪后完整输入无“容许丢首字”，Agent原回包及完整owner必须核对 |
| N2 正常源码编辑面 H1-3 | 保存/撤销/重做真实业务入口；多行正文合理占用窗口，键盘弹出与滚动后仍可编辑；命中/caret/范围高亮消费同一accepted排版 | 真实触摸有可区分落点、非空范围替换；中文、emoji/多标量语料不拆坏字节/簇。换行、滚动或几何改变后位置对应正文，旧身份查询具名拒绝；调试PROBE/CYCLE面板退到测试入口，不能只有日志证明可用 |
| N3 共同滚动 H2 | 正式host推进changed/active，有界唤醒；合法BEGIN接管、同值reveal、旧release失效、重复viewport接受前拒绝；移除样例重复step | 确定性反例加正常手写/公开生成视口消费；拖动→惯性→触摸停止→reveal→系统输入与公开owner写入可接续；停止后滚动活动退役，无其他活动时不再由滚动调度持续帧，光标等合法活动单列。沿已到Astra积分裁决，不再重问或重写已绿数学 |
| N4 最终产品与复用汇合 | 一次冻结输入、正式入口独立目录构建、最终normal产品连续消费及受影响的第二消费者/macOS回归 | 同一HAP完成人→Agent→人、拒绝恢复、撤销/重做、保存→关闭→重开；完整owner/文件/实际选区及画面可对应。设置/thermo合计覆盖本次文字及手写/生成惯性机制；记录真实成本、最终产物身份与尚未验证的边界 |

N1是最终输入验收门槛，**不是N2/N3独立实现的开工门槛**。先给恢复链做下述一次聚焦机制咨询；等待时做N2产品命令/布局、N3活动及各自反例。可以委派独立子任务，共同window、ABI和集成由主执行者掌握，不能两个代理同时改同一函数。同target构建、模拟器操作和桌面使用串行；正在构建的输入先固定，其他工作用不相交文件/独立产物，不能边改构建源边解释随机错误。

**查鸿蒙资料是实施步骤，不能只靠模型印象。** 遇到平台API、回调顺序、线程/所有权、坐标/索引单位不清，先定位本机SDK头文件、ArkTS声明和当前调用，再查华为官方对应版本的指南/API/变更说明；API版本、DevEco/仓颉SDK、模拟器镜像分别记录。以下是查阅入口，不保证本机版本与这些页面相同，必须切到实际版本核对：

| 本包问题 | 官方入口与必须查清的事项 |
| --- | --- |
| 自绘输入与代理恢复 | [在自绘编辑框中使用输入法（版本化指南入口）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V13/use-inputmethod-in-custom-edit-box-V13)。按当前实际用到的InputMethodController或TextInput/TextArea控制器查attach、焦点、选区设置/查询、change/selection回调与卸载；不同API族不能按同名行为混用。setter返回、文本回声和平台实际选区是不同事实 |
| 正文改变后的选择重置 | [官方TextInput光标重置FAQ](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-arkui-933)。作为“赋值后光标可能变化”的排查入口，不据它推定当前代理的回调顺序；用本机最小对照验证，不直接抄示例塞进生产 |
| 同一排版的命中和范围几何 | [Native Drawing Typography参考入口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/drawing__text__typography_8h-V14)。定向查本机对应的glyph-position、affinity、range rect、line metrics及对象释放：可用API级别、UTF-16/其他索引、px/vp/density、裁剪/变换和布局对象持有期。使用实际绘制的accepted对象，不另排文字伪装同帧几何 |

官方网页抓不到正文时，用可用浏览器或本机SDK声明/随包示例继续；搜索摘要只能定位入口，不能证明线程、安装确认或资源所有权。平台行为仍不清就做最小ArkTS/Native对照。文档缺失不直接等于API不存在，对照同样失败也只限定当前SDK/镜像/输入法组合，不泛化为“模拟器不支持”。marked/cancel的已知版本边界不反复空跑；普通提交/替换和框架状态机继续实现。

**借鉴机制必须落到设计。** 依据[本地参考导航](DESIGN_INTENT_INDEX.md#本地开源实现参考)，到 `/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库` 定向查系统文字同步/选择状态、accepted布局持有、滚动活动接管与终结的实现和测试；Flutter/SDL等只是参考，不能引入其依赖。每个新机制在原咨询答复或本节现有记录简记“参考符号/版本→借鉴哪条状态规则→CJGUI哪些前提不同→哪条反例验证”，不另写长篇调研。已有裁决/前提未变直接复用。仓颉编码前读 `/Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md`，语法/FFI不确定先按技能查。

**CLI咨询是明确执行要求，不是可有可无的提醒。** 普通明确接线直接做；日常疑难及时Pi→精确`zai-coding-cn/glm-5.3`，即使主模型也是GLM5.3也用独立上下文。提供最小复现、期望/实际、必要源码、版本、原日志及已失败假设，要求顾问质疑既有归因。恢复链本次直接用`gpt-6-astra/max`审阅完整事务（前文所列N1四项），不要继续局部猜修；新公共契约、并发/资源归属、架构算法有实质风险也可直接Astra。GLM无可靠方案的复杂技术定位用`gpt-6-sol/max`，不要求每题逐级问遍三个模型。首次咨询+一次有新证据追问仍无可验证方案，将该问题标为待指导、继续独立工作，不把模型轮换当清零失败次数。

Pi按[AGENTS精确只读模板](../../AGENTS.md#independent-model-consultation)执行。当前问题材料放现有`artifacts/consultations/<问题>/request.md`，使用独立输出目录；以下路径中的`current-question`要替换为实际目录并先建好：

```bash
/Users/jiangxuanyang/.local/bin/pi -p \
  --provider zai-coding-cn --model glm-5.3 \
  --no-session --no-context-files --no-extensions --no-skills \
  --no-prompt-templates --no-themes --tools read,grep,find,ls \
  --system-prompt '只读技术咨询。仅查问题所需文件，不修改、不构建、不操作设备或桌面。区分证据与推断，质疑已有归因，给区分实验、机制方案和验收反例。' \
  @artifacts/consultations/current-question/request.md \
  > artifacts/consultations/current-question/answer.md \
  2> artifacts/consultations/current-question/stderr.log
consult_exit=$?
printf '%s\n' "$consult_exit" > artifacts/consultations/current-question/exit-code.txt
```

Sol/Astra沿[产品AGENTS的完整Codex CLI模板](</Users/jiangxuanyang/Desktop/Pharos Mark/AGENTS.md#codex-cli-调用方法>)（`codex -a never exec`、`-s read-only`、stdin材料、`-o`答复与JSONL日志），显式`-m gpt-6-astra -c 'model_reasoning_effort="max"'`（复杂技术题换`gpt-6-sol`），独立只读上下文，不让顾问修改或抢设备。答复、退出码及必要版本信息落同一问题目录；在启用shell失败即退出的环境也要显式收取失败码。认证/服务/参数失败具名记录，不把空答复当建议、不静默换型号；顾问建议必须经反例与正常消费验收。`laya-ask`只用于成批可复核分类/排序，不能替代查API、根因分析或必须咨询。

**夜间执行纪律。**

- 每完成一条生产链自动接下一项，不在“本轮编译成功/测试绿/下一步可做”处等用户回复。一般内部实现已授权；改变自绘路线、引入外部框架依赖、丢弃用户数据或其他原规则要求决策的事项不擅自实施，暂挂该项继续其余范围。
- 等编译/咨询/设备启动时推进独立且必要的实现、反例或集成准备；没有独立工作才有界等待。禁止靠反复读同一文档、重跑已绿全套或每轮写.md来占时间。合理诊断算进展，不以代码行数设配额。
- 修缺陷先找能区分根因的最小反例，修通生产链后跑受影响回归，最后N4一次汇合。不得固定sleep/重复投递直到绿，不放宽字节/范围/恰好一次等判据；按事件身份+实际状态+截止时间等待，不把验收工具失焦误归产品。
- 当前已授权桌面操作无需再等“已解锁”回复；可经hdc/uitest在模拟器完成的工作直接做。Mac锁屏仅跳过确实依赖宿主前台的动作，不改锁屏策略、不反复抢焦点；遇设备问题先一次定向诊断/合理恢复，不循环重启模拟器。设备不可用时推进代码与离线反例，不能直接把整个H包写成待真机。
- E主树文字会话/位置、macOS renderer与产品main仍由E负责；H只同步固定的公共契约及必要依赖，不能整文件覆盖并行修改。共享修复若确实需E重叠写集而无通信，留下具体窄接缝与输入指纹，独立工作继续。框架问题补CJGUI，文档命令/存储/Markdown规则留Pharos，ArkTS薄壳不自造owner/撤销/输入引擎。
- 同轮复用自有实例，HAP哈希、target、PID/重开PID、实例/绑定/请求/版本和原协议对应留证；只清本轮精确身份的实例与转发，保留用户实例、剪贴板及并行产物。未经用户要求不stage/commit/push、reset/stash或切分支。
- 只有链路完成、新结论改变方案或真实阻塞时短更原任务/ACTIVE/产品STATUS；不增加执行卡或逐轮报告。上下文将耗尽时留下短接续点（当前状态/文件、失败原数、下一条可执行动作、运行作业身份），按工具能力接续，不以预算末轮冒充完成或宣称停止后仍在后台工作。

**晨间交付格式。** 只交一份集中报告：N1–N4分别“实现/已验/未验/阻塞”；两仓实际生产改动及归属；最终normal HAP/运行入口/源码指纹；一条人→Agent→人的完整正文/文件读回证据；正常编辑界面截图；拖动与惯性分组的真实响应、读取/布局工作量与内存/停帧原数。已有性能判据不放宽，缺指标明确未测，不以单帧外推收益。自有运行结束后统一清理并保存引用日志。若只有物理设备、上架或当前版本marked/cancel等本包明确排除项未验，可按限定范围报告本包完成；N1–N4内任何必做仍缺就保持未完成，准确交接，不能靠“登记待验”结项。

**历史指导限域复核（2026-09-30，H1-R 恢复事务；执行后状态以上方 [N1–N4 复核与接续](#h-source-preview-next-20260930)为准，以下不是未完成清单）。** 冻结请求、native 换绑取消、kind-55 成功/取消回执、窗口 `recalibrate→confirmProxyRestored` 和按挂载/目标值识别回声已真正接上；上一轮“没有ACK、旧正文发送时重贴新身份、全局Bool门禁”的实现缺陷不再原样重开。**但“完整事务闭合／17项全部验收通过”不能接受**：平台安装失败和无回声仍有具体断点，窗口忽略最终采纳失败，脚本又存在恒真及容许丢首字符的判据。下面只列本次必要修正，仍与H1-3/H2一起完成原包。指导只读生产链、测试/脚本和原件，未构建、重跑测试或操作模拟器。

[本轮原件](</Users/jiangxuanyang/Desktop/Pharos Mark/artifacts/h1-ohos-recovery-20260930/README.md>)中的 normal HAP `d3f59e5f…422ce`（h1r3h）构建首次启动PID27287；实际probe是 **PID29934→重开30361**。request3的文本回声ACK→窗口结束等待→无需再次点击续写Z→UNDO/REDO/SAVE→完整 **19 B** 重开一致有原证，保留此范围。PID23602属于较早的 `hilog_live.txt`，不能混入当前17项；“真机”应写华为模拟器系统输入注入。`hilog_10_burst.txt:49–55` 请求/ACK为0:0，随后的系统选择为13:13，不能把请求值当平台实际安装值。17个检查布尔值为真不等于17项有效判别，具体脚本问题见表。上一包normal `1a52aad4…c692` 的镜像刷新、43 B重开和14/14成果继续保留，两个运行的正文与PID分别记录。

#### 本次接续顺序：先接可运行产品，同时完成已定惯性机制

| 必要返工 | 机制与可区分验收 |
| --- | --- |
| **R1 生产接线已修，保留。** `CJGUI_CONSUMER_SYNC`、`CJGUI_APP_EXTRA_DEPS`、显式 `CJGUI_APP_PKG_LIB` 已由正式入口消费。 | 不再重改入口或单独重复构建。最终产品汇合时从明确无旧 target 的独立装配目录经同一入口构建，记录实际路径/输入指纹/命令与前提；不能靠手补清单或删除 E 的 macOS 产物。当前两份原目录构建/闭包可以引用，不夸大为独立目录运行。 |
| **R2 动态容量本轮已修，保留。** `capacityIssue` 被 apply/replay 在正文/版本/双栈修改前共用，允许 `result<=cap || result<=current`。 | 10→9/上限4、历史恢复6B越界两反例及144/144见 `artifacts/h1-build-entry-20260929/doc-core-capacity-green-144.log`（产品仓）。拒绝不写 journal 有源码依据；测试未独立量测磁盘前后，不扩大为该项实测。后续无相关变化不重跑容量包。 |
| **R3 生产检查已补严，保留。** 完整赋值提取含运算符续行，新增旧 OR 负控；现存 `abi-mirror.log` 仍为旧7项，未包含本次所报8项。 | 补已有新运行/变异原件索引；确实丢失才定向运行该负控，不重跑 ABI/触摸全矩阵。当前生产旁路不再重修，四向静态/宿主哨兵/目标运行范围继续分开。 |

| 本次仍须完成的生产链 | 已定位断点、修复方向与判别 |
| --- | --- |
| **已修链路保留** | 镜像刷新、H1-2合法UTF-16差分及原14项消费保留；新恢复已具冻结请求/native取消/ACK/会话校准接线，6项native摘录反例有用，但未执行ArkTS真实选择失败和窗口采纳失败路径。以下修复在现有机制内完成，不另写一套恢复协议。 |
| **H1-R.a 平台安装事实：失败重试与正文/选区顺序** | `Index.ets`约749在`setTextSelection`前更新`imeSelStart/End`；首次setter抛错后，同区间重试约746直接因缓存相等返回true，约739发成功ACK。且文本回声ACK用的是请求账本，本轮原日志ACK0:0随后系统13:13。分开期望与已观察值，按平台实际能力核安装完成：正文改变引起的选择重置必须结算，不能只因setter无异常或字符串回声就确认选区；失败保旧账本，同区间重试仍需真实安装。判别：先抛错→同范围重试不能伪成功；旧实际0:0→目标4:9→正文更新→同请求实际选择确认后才能解锁，下一笔替换必须落在4:9。 |
| **H1-R.b 无回声必须有终态** | `Index.ets`约726的900ms只清pendingEcho不发失败回执；native awaitingAck和窗口去重待办均保留，后续恢复永久等。按冻结身份收敛为失败/取消，让窗口有限重试；迟到回声/ACK不得命中新请求，成功不靠超时推定。判别：目标回声缺失→失败终态→后续有效恢复可继续；首请求迟回不重复完成。重试上限到达时具名可恢复失败，不能静默关输入门。 |
| **H1-R.c 窗口完成必须采纳成功** | snapshot window约5819先清pending，5841忽略`adoptNativeSelectionRestored`返回false，仍成功计数并回写旧焦点/bookmark。静态交错：平台ACK(v1)入FIFO→Agent把owner推进v2→窗口消费，源版本守卫拒采纳却报成功。仅核验与采纳成功才记完成；失败保持恢复意图/请求新投影并有限重试，不覆盖当前焦点。pending须接收并冻结native requestId及绑定/会话代次，成功和取消都精确匹配；当前四元/三元匹配的遗漏不宣称已实测ABA，但不能把头字段存在当窗口已核验。本项补实际生产窗口接缝反例，不仅跑C++摘录。 |
| **H1-R.d 验收恢复判别性、核清输入账目** | `probe_h1r.py:289–294`发H1R却允许只落1R，summary已记first_char_lost=True；336的`agent_shrink_accepted`恒True。改等同实例真实焦点/可输入状态再投整串，严格完整owner差分；Agent结果检查原回包、版本及字节，错误必红。burst发2345678实际仅45678，逐笔区分未投递/具名拒绝/接受/恢复，不能按末串“看着合理”判通过；拒绝遵守既有草稿保全和可见失败契约，不私自重放写入。补Agent拒绝、首字符缺失、选区未安装的负控。当前17项原报告保留为历史原件，在原README/状态纠正口径；不要为漂亮全绿放宽判据或重试掩盖。 |
| **H1 正常源码编辑面与 accepted 位置（尚未交付）** | 文本级命中、caret声明仍拒绝；恢复已接ACK但平台实际选区确认和失败收敛见上表，不能以整控件焦点证明精确落点。按原 C 用实际 accepted 排版补必要查询、触摸落点、光标/高亮和拒绝恢复。归档画面仍含 PROBE/CYCLE/状态大面板，控制器 `applyUiEvent` 对业务控件全返回 false；正常产品入口应提供可用的保存/撤销/重做，正文可读、正确使用可用区域与缩放，调试控制留测试入口。复用原 editor_surface 和服务，ArkTS 保持薄壳，不在壳里另写编辑器。 |
| **H2 标准宿主消费及活动生命周期（静态反例）** | 13项证明积分/请求代次，窗口测试手动step不能证明宿主接线。main/snapshot共同host未推进，只有lab宿主显式step；将活动接入正式host，`changed`请求刷新、`active`安排有界唤醒，移除样例重复推进；Pharos不得另写逐视口循环。raw BEGIN 空白处只冻结后返回，snapshot指针BEGIN先stop后验身份；按既有Astra接完整身份接管通知、先判身份再终结。显式reveal即使目标相同也应从accepted接管；活动100→reveal同100→下tick不得继续。新BEGIN/显式定位使旧release票失效，迟到同绑定END不能重新启动，`inertialActivityGeneration`必须实际参与判决。 |
| **H2 歧义绑定与正常消费（静态反例/未验）** | 同一viewport放两个独立scrollArea目前在接受后才记错并保留首记录，布局已可能覆盖staged extents。候选绑定准入时拒绝重复对象，保留旧accepted及活动；两种不同高度视口是判别。随后两款normal样例合计补手写/公开生成视口、惯性期间带身份公开写入和直接拖动/惯性分组原数；`bindings=1`及构建不替代这条消费链。 |

**这一包的推进顺序。** 恢复事务先集中闭合H1-R.a–d，H1-3的actual accepted几何、正常正文布局与保存/撤销/重做接线，以及H2共同host/接管/终结/重复viewport准入由独立写集同步推进。不要再次把整包停成只修几个恢复函数；有真实依赖才等。原H1/H2范围不缩，调试面板移测试入口、生成视口消费和最终汇合继续。无新改动/失败/疑点不重跑容量、ABI、数学及旧触摸矩阵。

**一次机制评审，避免继续逐点补丁。** 同一异步恢复问题已连续实质返工。本次将冻结请求→平台正文/选区安装→成功/取消/超时→窗口采纳→重试的完整路径，以及上表原日志和静态反例交Astra/max做一次聚焦只读评审；只给相关源码与问题，不从头扫描项目，不重新争论已定架构。要求覆盖终态、身份、安装顺序和失败账本，形成可实施方案后由当前执行者连续完成，答复不当证据。日常技术定位按AGENTS用Pi→精确GLM5.3，必要Sol/max，不逐级问遍。咨询/编译等待时推进H1-3/H2独立工作，不再空等或增加轮次文档。

**归属与汇合。** 恢复事务、文本几何、平台回执和滚动调度归CJGUI；Pharos只负责文档命令、投影通知、存储及正常布局，ArkTS保持窄平台操作。按本地导航借鉴成熟框架的异步文字状态/确认机制，复用已采纳文字会话和惯性裁决，不引依赖。修后先做上述最小失败反例，再在同一最终normal产物做一次人→Agent→人、非空选区/拒绝恢复、保存重开与惯性共同消费，记录完整owner、实际选择及版本；最后受影响macOS和独立目录构建。E写集保留，同target/桌面串行，未授权不stage/commit/push。

1. **H1 主线连续做到真实消费。** 首个完整切面是“窗口绑定已有 Source/Sink → 真实系统编辑/非空替换 → 同一 owner 确认 → accepted 画面校准”，随后接工具栏命令与 E.1 的人→Agent→人→撤销/重做→保存重开。窗口普通会话/平台草稿与确认在CJGUI，文件/预算/文档命令在Pharos。同步的 `text_session.cj` 必须固定源指纹及依赖，按绑定、事件归属、提交确认、拒绝恢复、换绑/关闭逐段接窗口；不得按“主树68处引用”整文件覆盖 E 在途 `window`。OHOS geometry 从实际绘制所用 accepted 排版取命中/光标/选区，核本机SDK索引单位及布局对象持有/退役，不另排一份文本冒充同帧位置。字素拒绝桩只允许过渡：若普通移动/删除依赖它，必须接真实平台服务或经现有契约认可的系统范围事实；不能无限返回 unsupported 后称编辑器可用，也不退为按标量删除。基础编辑可独立于未观测marked/cancel继续，别等待完整visual或E全部新模块。
2. **H2 方案已到，直接实施。** [Astra 完整裁决](../../runtime/cjgui/platforms/ohos/consultations/inertial-activity-astra/answer.md)已落盘，不再写“等待答复”或重问同题。按其顺序接 requested/候选代次→截止积分→accepted 活动绑定/终结→窗口策略/调度→正常消费。活动表必须来自 accepted 的实际视口绑定并含 viewport 对象身份，不仅靠所有权/liveStamp；候选冻结实际用于布局的 `requestGenerationUsed`，接受 A 后仍保留后发 B。原始新触摸（含空白处）、显式定位/reveal、换绑/隐藏/停止取消活动；旧 END 不重启已失效释放票。`changed` 决定刷新、`active` 决定后续唤醒；最后有位移即交付，诊断不得再 step。绝对截止积分及每窗口不可变策略按答复实施，删除样例枚举和全局开关控制权；split 捕获/CAS/自身修订继续按原要求闭合。
3. **并行只分独立写集，汇合只做受影响检查。** H1 平台会话/产品接线与 H2 共同滚动可分工；共同 window/ABI 由主执行者集成。复用已验证路径，必要新反例先红后绿，最终一次受影响 normal HAP 汇合。旧构建记录的 `--no-emulator-start`/hdc为空已被上述正常HAP实跑取代，不再作当前阻塞；后续使用既有华为模拟器入口和明确target，保留用户实例。实际启动/连接失败才具名记录具体阻塞，禁止反复重启或把未启动自动升级为待真机。无新改动/失败/疑点不重复全量、截图或Markdown；接续H1/H2直到包内工作完成，独立代码不随设备等待停下。

### A．修 ABI 与严格身份，准备同源目标

- 按原 r10 第1项，对齐实际主 src、H snapshot、C头与lab staging的完整Node布局、初始化和关键偏移，新增实际仓颉→C哨兵读回，不能仅做文本字段名对比。H不支持的效果明确禁用但保留ABI槽位；包同步阻断错配。
- 恢复严格 acceptedBindingEpoch 校验；零尾差 END 也先校验手势冻结绑定，fling 传原冻结身份，不借当前节点重贴新版本，不以 `fling:`/非零GestureKey替代绑定守卫。同ID换绑/ABA拒绝与同绑定刷新继续成对验证。保留前包原始FIFO/唯一CANCEL/正常触摸成果，不重开hr3–hr5。
- 不必等设备完成才处理产品目标构建。用当前OHOS仓颉工具链编译、链接共享 document_core/app_services/所需markdown子集，并在HAP运行实际事务/历史/读取用例；分别记录宿主测试、目标构建与模拟器执行。禁止未执行分支中残留不可链接Darwin符号却称可移植。

### B．薄平台宿主与存储端口，保留一个产品

- 在产品仓新增清晰的OHOS目标/宿主目录，复用H已有Ability/XComponent、自绘renderer、输入和TCP公开传输。ArkTS只承担既定薄平台壳；正文、版本、撤销、Markdown和授权操作仍为共享仓颉代码。复用 `DocumentSession`、`Workspace`、`AppServices`、`editor_surface` 和现有provider，不复制长期独立的编辑器/owner/控制器，不另造产品CLI/MCP。
- 先组合已有可复用服务；桌面 `PharosEditorController` 仍嵌在 main.cj，不先大拆这个E写集。需要平台无关的小文档命令装配时，H在独立共享模块提取最小机制，禁止复制Markdown算法；确需改桌面调用点由E集成该窄接缝。
- 以窄端口提供私有目录、稳定底本、范围读、候选写/同步、同文件系统原子发布、取消/失败释放。保留macOS实现和保存失败保旧/撤销语义。首包可限定新建及应用私有小UTF-8文件（明确并在分配前执行字节预算），底本可用有界内存；不能把任意外部文件流式复制或mtime相等说成原子快照。保存端Darwin常量必须真正替换为目标实现，不能只绕过clone。
- Node公式/图表、PDF、桌面文件对话框与Unix socket按能力装配；不支持的能力具名发布/禁用，不伪造成功。源码编辑表面沿Pharos简洁视觉规范，保持自绘正文与现有主题，不做调试按钮堆砌的第二款产品。

### C．把共同范围会话接到鸿蒙实际排版和输入

- 从已结束E包固定一份最小 Source/Sink/CompositionSink、text_session、身份/确认/恢复契约输入及指纹，按依赖同步snapshot。main src仍是公共机制来源，snapshot是可追溯交付副本，不能另立长期语义。E的新位置模块尚未完成时，不整包追逐其在途文件；已定内容/绑定/范围/确认字段直接复用，新增平台接缝按共享交接规则合入。
- 让真实Pharos源码面使用CJGUI窗口拥有的会话，OHOS适配器只保有界镜像/草稿。UTF-16↔UTF-8、基版本、替换范围、请求ID与owner确认贯通；入队不算接受。系统全文回调可转同版本精确差分，不把长期协议退回整篇字符串、不引第二owner。
- 补真实正文命中、光标、高亮/范围几何与外部换版校准，来源必须是实际accepted排版；不能用控件大矩形或另排文字伪装精确位置。普通文本状态/选择在框架，文档命令/文件/Markdown SourceMap在产品。优先源码多行面，不等待完整富文本visual或本轮mac全部bidi接口。
- 对可观测的系统提交/非空替换先形成正常链；旧绑定/版本的回调零错误写入，保存能获得的草稿后校准继续。缺失的marked/cancel不猜造，不用失焦/空值当系统终态，不无限重跑同版本镜像；公共状态机反例与真实回调支持范围分别报告。字素/复杂文字服务按系统能力和共同契约接入，不能以标量降级假称整簇编辑通过。

### D．原惯性包按机制补齐，不再靠截图代替接线

原 r10 复核第2–5项仍是必做，具体反例直接复用：共同窗口拥有手写/生成viewport活动；requested/accepted按请求代次确认，旧候选A不覆盖后发B；explicit定位/reveal/新触摸/换绑/停止终结活动；末步 changed 与 active 分开，诊断只读。删除样例逐个step和全局开关的控制权，平台不常驻计时器，macOS系统惯性不叠加。

修绝对时间截止积分、亚像素集中量化、有限数转换准入，BEGIN/UPDATE/END共同追加时间样本而不是END覆写历史；保留10/30/20/40、首次2/2.6s、低速最后一帧等原反例。split同步整个捕获/CAS/自身修订接续，不能只搬状态方法。宿主gesture抽取缺helper、队列C++标准与Node ABI分别诊断，修测试调用但保留行为断言。此切面可先独立落定向测试，最后与H1共用一次冻结构建汇合。

### E．一次真实产品闭环与有限回归

1. 最终normal Pharos HAP：新建/打开受控小文档→多行滚动/触摸定位→中文/emoji及非空替换→公共发现/读取→授权Agent范围写入→过期版本拒绝→人继续编辑→撤销/重做→保存→关闭重开。按documentId/binding/version/requestId核完整owner原字节、实际文件及画面，不能只读代理文本或用测试私有setter代替公开事务；失败保存保留旧目标。
2. 一个既有设置/thermo普通文本消费者复用同一框架接缝做针对性回归；原惯性包的设置与thermo最终normal消费合计覆盖手写/生成视口、惯性期间公共写入、触摸停止、reveal/系统编辑、未变图片复用及空闲停帧。只跑受影响切面，不重做所有历史样例矩阵。
3. 证据绑定当轮SDK/镜像/HAP哈希/PID/实例/accepted身份，公开请求与owner/画面逐笔关联。记录打开/可编辑、范围读取/排版工作、输入到owner/accepted、峰值内存；惯性/直接拖动自然响应样本分组，受控闸门分列。模拟器结果不冒充物理性能、GPU完成不冒充实际显示、AX/协议不能冒充系统输入。
4. 共享机制改动补macOS受影响定向回归，固定一次最终源码与包清单。设备能力不足只阻塞具体真实回调，不阻塞代码、确定性状态机或已能运行的产品链；来源不明失败先定位，不能把反复快扫、重建、长报告当实现。

**写集与咨询。** H负责OHOS host/snapshot/scripts/HAP、新产品平台装配/存储端口、Node/Event ABI和共同滚动活动；E负责主文字会话/位置、mac renderer及产品语义。H不得整体覆盖E在途window/main/头文件，E不另改Node/Event布局；新文字查询优先独立头/模块，结构性ABI调整只由H集成。共享函数确实重叠时冻结最小输入并在现有任务节说明交接；没有跨工具消息渠道不猜测对方已收到，继续独立写集，必要窄交接交用户转达。见[两线具体写集](2026-09-26-framework-capability-roadmap.md#two-editor-write-sets)。

日常疑难用[Pi独立GLM5.3只读咨询](../../AGENTS.md#independent-model-consultation)，主执行也是GLM5.3照常使用；已有裁决直接落实，新的公共契约/生命周期算法实质未决可直接Astra，复杂技术仍无解用Sol。沿本地导航学习Flutter活动/速度与系统文字服务、SDL OHOS生命周期的机制，只借思路不引依赖；每个问题定向读实现与反例，不扫整个参考仓库。仓颉技能先读；Laya仅作可复核批量分类。等待编译/咨询时做独立必要工作；同target/模拟器/桌面串行，只短更现有任务/ACTIVE，包末集中报告H1/H2真实完成与剩余项。保留用户实例及两仓既有改动，不stage/commit/push。

<a id="h-inertial-scroll-next"></a>
### H 接续：快照接线收尾与可中断惯性滚动（2026-09-29）

**目标与取舍。** 执行对象为**鸿蒙 H 线**，工作目录 `/Users/jiangxuanyang/Desktop/cangjie`。本包交付单指纵向拖动松手后继续减速、再次触摸立即停止、到边界收敛的通用滚动能力。共享仓颉 viewport/窗口负责滚动活动和 accepted 状态，H 平台只提供样本、时间及宿主接线；设置和 thermo 是消费者。复用本轮 GestureKey、acceptedBindingEpoch、原始 FIFO、生成 region、图片持有及焦点链；复用 P2 的显式单调时间和活动帧思想，不复制 F 的位置动画实现或修改 E 的正文/IME规则。弹性回弹、多指、嵌套滚动交接留后续，先把单视口惯性做成可实际消费的一条链。

**A．先收两处局部接线，独立推进惯性设计。**

| 当前源码反例（尚未运行） | 实施与判别 |
| --- | --- |
| H snapshot `dispatchPointerEvent` 的 BEGIN 仍走 `resolveInput`，它拒绝普通 TEXT；`isPointerCapturable` 却允许 `pointerInteractive` TEXT，renderer 已发的合法 BEGIN 到不了 controller | 复用主树 `resolvePointerTarget` 与现有普通 TEXT 手势测试，补 snapshot 正常 BEGIN→UPDATE→END 和旧绑定拒绝。保持编辑输入准入原义，不把所有 TEXT 扩成文本输入框；一款 normal HAP 的普通文字指针控件实际消费即可 |
| H snapshot split capture 后，经 `applyAcceptedFirstSize(300)` 对同一个 split state 发出新请求，旧 UPDATE/END 仍在快路径无条件 `applyFirstSize` 覆盖它；snapshot 没有主树已有的捕获修订/CAS | 按最小共同机制同步 split 修订、写前身份/修订校验和自身成功拖动后的接续，先固化“新请求保留、旧相位零覆盖、取消唯一”与“同一合法拖动跨自身刷新继续”成对反例。无关业务版本变化不应成为无条件取消理由。同步必要 src/snapshot/ABI 接缝，不整包覆盖 F 在途文件 |

**B．带原始时间的速度估计与独立滚动活动。** 当前 `TouchRecord`/`RawTouchSample` 只有坐标和身份，没有采样时间；renderer 以出队时 `steady_clock` 判长按，该时间不能直接拿来估算速度。核对 SDK 触摸时间字段的单位/时钟与有效性，优先携原事件单调时间；需要桥接接收时间兜底时在入队前捕获并标明来源。时间与 key 同记录传递，禁止给一批出队样本统一补“现在”。确认原始坐标到 accepted viewport 单位的转换只发生一次，记录 density/几何身份；单位或时钟不能证明时安全退化为直接拖动，不制造速度。

采用固定容量、固定时间窗的近期样本估计释放速度；重复/倒退时间、停顿后松手、样本不足、非有限/极端输入和 CANCEL 都有明确结果。END 最后位移仍按现有链消费一次，不能为了估速丢尾差。普通点击、长按和取消不启动惯性，过载取消也不启动惯性。

由仓颉共同 viewport/窗口持有 Idle/Drag/Inertial 等有限活动状态，绑定窗口实例、viewport 的稳定身份、acceptedBindingEpoch 和活动代次。惯性开始于真实手势 END 之后，有自己的活动身份；不能伪造持续 MOVE 或重复交付 pointer END/CANCEL。新 BEGIN 先停止旧活动再参与现有点击/滚动仲裁；换绑、移除、Surface 退役、窗口停止/重开及显式滚动/焦点 reveal 对活动的处理统一定义。程序化定位应从实际 accepted 位置接管，旧 tick 不覆盖新定位；同绑定内容更新按新的合法范围继续或收敛。

**C．有界推进、接受事务与共同声明。** 首包采用边界夹紧的减速模型，给出公式、参数单位、停止阈值和工作上界；使用显式单调时间，禁止每帧固定乘系数而使 60/120 Hz 或掉帧改变总距离。可用解析衰减或有误差界的有界积分，有限帧间隔与长暂停处理可解释。保留亚像素累计量，投到既有整数 viewport 时集中量化；到边界、速度耗尽或活动退役后停止请求帧。

复用 requested/accepted viewport 区分：计算新位置不等于画面已接受。候选失败保留旧 accepted、命中及图片/输入资源；只保留有界的当前待决请求，恢复时以同一活动/请求身份确认，避免逐帧无限排队、旧接受清掉新请求或失败后跳回旧目标。优先复用共同窗口 pump/帧调度，平台不另起无归属的常驻计时器。H snapshot 只同步必要机制；macOS 保持系统滚轮/触控板已有惯性，不能叠加第二次人工惯性。

手写与生成 scrollArea 使用同一份可发现、严格准入的滚动物理策略/开关；明确默认值、单位、支持状态、拒绝保旧与清除语义。配置是框架能力，不在两款样例分别调 native 常量。策略名称由执行者按现有 API 规范定，稳定性先标 experimental；不为首包开放任意公式/脚本。

**D．判别与两款正常消费。** 先用相同时间/位置轨迹，改变入队延迟和 pump 批次，证明速度及最终轨迹不受出队节奏伪造；覆盖停顿松手、短样本、重复/倒退时间、END 尾差、CANCEL，以及 60/120 Hz/掉帧的距离容差。窗口级覆盖新触摸中断、同绑定刷新、换绑/ABA、边界/内容缩小、候选失败恢复和停止重开；判据来自真实生产活动，不复制一套测试状态机。

最终同源的设置和 thermo normal HAP 各完成一次连续消费，合计覆盖手写与公开提交的生成视口：真实快扫→抬起后多帧减速→新触摸停止→停止后按钮恰好一次→屏外焦点/系统编辑→公开 owner 精确读回；滚动期间插入带身份公开写入且不重建未变图片。原包已验的草稿重排矩阵按影响复用，不要求为新增惯性再从头全跑。

留下输入时间/来源、释放速度、活动代次、requested/accepted offset、终止原因及空闲提交不再增长的有界原数。正常直接拖动与惯性两种同负载各收一组响应样本（建议各 20 笔），分开 owner/accepted/构建绘制耗时与资源峰值；沿已有预算比较，受控闸门不混入自然 p95，TCP 往返不冒充绘制时间。无需人为把设备触摸轨迹做成完全相同；确定性轨迹等价由生产机制测试承担。

**E．参考、咨询与汇合节奏。** 本次指导核对本地 Flutter `8db55268667c` 的 [velocity_tracker.dart](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/gestures/velocity_tracker.dart>)、[scroll_position_with_single_context.dart](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/scroll_position_with_single_context.dart>)、[scroll_activity.dart](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/scroll_activity.dart>)，以及 [速度测试](</Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/test/gestures/velocity_tracker_test.dart>)。借鉴固定历史窗、停顿切段、拖动/惯性活动替换和边界停止；CJGUI 自己保留 accepted 事务、原始队列、公共身份与预算，不移植 Flutter runtime 或照抄其平台曲线参数。按机制导航按需继续查具体符号与测试，已有结论前提未变不重扫大仓库。

主执行者先明确 B/C 的时间域、活动归属和失败恢复，再编码。若这些公共契约仍有不确定取舍，带最小接口与反例向 `gpt-6-astra` 作一次聚焦只读咨询；复杂技术根因用 `gpt-6-sol`，均用当前可用次高思考档。旧 GestureKey Q1–Q5 已落实，不重问。仓颉编码先读 skill；`laya-ask` 适合可复核的批量日志分类，不能替代根因和验收。

按明确写集并行 A、算法/契约与消费者接线；等待编译、咨询、模拟器时推进独立工作，相关工作做完才等待。同 target 和设备操作串行，最终一次受影响测试、核心 build、ABI 检查及两 normal HAP/闭包与指纹汇合；已稳定部分不循环复验。仅在闭环或新事实出现时短更本节与 ACTIVE，包末集中报告。本提示词已是实施依据，不另建执行卡；保留 E/F 写集与用户实例，未获用户要求不 stage/commit/push。

**执行者阶段报告（2026-09-29，惯性原型；整包未收口，以下结论受后续指导复核限定）。**
**A**：snapshot `dispatchPointerEvent` BEGIN 改走 resolvePointerTarget（普通 TEXT 指针控件可达 controller，与主核心 B4 一致）；snapshot split 快路径 UPDATE/END 增加 `pointerCaptureOwnerVersion` 修订校验（外部新请求推进修订后旧相位零覆盖，END 仍释放捕获）。
**B**：TouchRecord 增 timestampNs/timeSource（优先 SDK timeStamp 单调 ns，无效时入队前 steady_clock 兜底并标来源）；ingress `touchDequeueEx` 带 timestampNs/timeSource 出队；renderer RawTouchSample 携带时间。速度估计：TouchGesture 固定容量 8 样本窗（Flutter velocity_tracker 停顿切段思路），UPDATE 记录 (t,y)，END 差分首尾（≤100ms 窗口）得 px/ms；样本不足 2、时间倒退、停顿后松手均返回 0。设备实测 `fling velocity=0.543/-0.323/0.513 samples=8` 非零确认。
**C**：viewport（snapshot composable_ui.cj）新增惯性 API：`beginInertialScroll(velocity, MonoTime)` 启动、`stepInertialScroll(MonoTime)` 解析指数衰减（v(t)=v0·e^(-t/τ)，τ=325ms，位移=v0·τ·(1-e^(-t/τ)) 积分，帧率无关）、`stopInertialScroll` 中断、边界夹紧后活动结束（scrollBy 无变化即停）。核心 `applyViewportScrollStep` 识别 `fling:<px/ms>` 文本启动惯性。全局开关 `cjguiComposableInertialScrollEnabled`（experimental，默认 false）由两款应用在同一控制器 init 启用（手写/生成共同声明）。app 宿主循环每 pump 轮 `stepActiveInertialScrolls(MonoTime.now())`，有位移时 `window.requestRefresh()`（复用窗口帧调度，平台无常驻计时器）。
**D**：设置 `hirt-r16-095741` 和 thermo `hirt-thermo-r2-100442` 设备实测：快扫松手→多帧减速（截图 diff 滚动区变化 fling:47,303→625,721 / thermo:47,799→625,1217）→惯性后 settled 无变化（衰减收敛）；快扫中点击→惯性立即停止（tap→later diff None）。fling velocity 0.543（设置）/0.513（thermo）px/ms。原始 hilog/截图按 PID/bundle 归档。
**E（部分）**：核心 `cjpm build --skip-script` 成功；`git diff --check` 干净、fport 清空。受影响宿主测试和 macOS 定向回归未在本包集中跑（gesture/bridge-queue 测试因前面签名变更仍在 FAIL 状态待修，按影响复用原则留待集中收口）。生成视口惯性消费、惯性中公开写入原数、响应样本分组未做。弹性回弹、多指、嵌套滚动按原边界保留。E/F 并行改动保留，未 stage/commit/push。

<a id="h-inertial-scroll-review-20260929"></a>
#### 惯性包 r10 指导复核与当前实施要求（2026-09-29）

**结论：五项有改动，原 A–E 仍未完成。** 保留主 src 的 viewport API、亚像素余量、END 时间参与估速、fling 身份字段及 split 修订原语；需要补齐它们的实际接线。当前主窗口未拥有惯性活动，split 出现自身修订冲突，H Node ABI 已不匹配，放宽 fling 校验不能作为交付方案。指导只读源码、原归档并复算公式，未构建或操作设备；下列行为反例为静态推演，交执行者针对生产实现固化。原触摸/图片/生成包的未受影响成果保留。本节替换前次惯性复核的当前缺口表，不重开旧 hr3–hr5 工作。

| 现状与源码定位（以符号为准） | 判别与归属 |
| --- | --- |
| **H Node ABI 错配，不是已证实的 Event 布局故障。** snapshot `runtime_renderer_session.cj:257–260` 的 `tabSelected` 后直接是 `acceptedBindingEpoch`；配套 `snapshot/cjgui_internal_renderer.h:617–684` 中间还有 semantic/effect/wheel 等字段，主 src 已有完整镜像。按标准 C 对齐静态计算分别为 448/888 B，epoch 偏移 440/880；实际跨语言尺寸仍须运行确认。`ohos_renderer.cpp:5680` 按完整 C Node 拷贝入参。 | `sync_platform.sh` 确实把这一对不匹配文件交给消费者，r10 manifest 的 renderer/镜像/header 哈希与当前文件相符；H 接线负责闭合，现有证据不足以甩给“F 本轮改动”。先修两端完整布局及 staging，再恢复严格绑定；已有 Event ABI 测试不覆盖 Node。 |
| **旧 END 可借新绑定身份启动活动。** snapshot window `gestureBindingReady` 对 `fling:` 开旁路；renderer 的零尾差在冻结绑定校验前返回，发 fling 又采用当前节点的 projection/epoch。 | 快速 MOVE 后接受同 node/resource/kind 的新绑定或 ABA，再送旧手势同坐标 END；新绑定不得启动惯性。仅删核心旁路还不够，native 必须比较并传原冻结 viewport 绑定。GestureKey 与 acceptedBindingEpoch 分别校验，不能相互替代。 |
| **窗口共同机制仍缺。** 主 src 仅新增 viewport 方法；`settings_counter.cj:347`、`thermostat_app.cj:267` 仍只 step 手写视口，`ohos_app.cj:600` 由样例控制推进。`requestOffset/reveal/releaseOwner` 未退役活动，`commitStagedExtents` 无条件覆盖 requested。 | 公开生成视口不能自动推进；候选 A 后发请求 B，再确认 A 会覆盖 B。活动代次、请求代次和接受确认须接共同窗口，不能把 API 复制称为窗口接管。 |
| **split CAS 自己制造冲突。** snapshot window `:5379` 捕获 r，`:5381` 非 CAS apply 令 revision=r+1，首次 UPDATE/END 仍以 r 比较；reconcile `:5486` 还按业务 ownerVersion。 | 无外部写入的 BEGIN→UPDATE→END 就可失败。先补合法连续拖动正例，再验外部 split 请求拒旧相位、无关业务修改不取消；不能仅证明冲突时不覆盖。 |
| **停止积分与 END 入窗仍有算法缺口。** `stepInertialScroll` 过 2500 ms 时积分前归零，阈值则按整段末速度判断；END 覆盖最后 UPDATE，未追加。 | v0=1、τ=325、阈值0.01、范围充足：10 ms 分步为321 px，首步2000 ms为324 px，首步2600 ms为0；固定阈值时刻应为1496.6803 ms、累计321.75 px。UPDATE时间10/30/20、END40会被改成10/30/40而掩盖倒退。另 v0=0.02、首步250 ms 已改 requested 约3 px却返回false，宿主不请求末帧。 |

**实施顺序与可交付切面（仍属上方原 A–E）。** ABI/绑定入口先闭合，数学、split 和共同活动的独立写集同步推进；正常 HAP 汇合在相应生产链通过后做一次。

1. **修 H ABI 与冻结身份，交出第一条闭环。** 对齐实际构建使用的主 src／H snapshot／C header／lab staged Node 镜像，保留完整字段顺序、宽度、对齐和初始化；H 尚不支持的效果可明确保持禁用，不能省掉 ABI 槽位。扩展现有 ABI 检查到 Node 的字段/尺寸/关键偏移，并用仓颉→C→事件的不同哨兵值证明 epoch 和邻接字段精确传递；sync/打包时阻断不匹配组合。恢复核心严格绑定入口，native 在零位移 END 之前校验冻结 key/viewport epoch，fling 携原冻结身份而非把旧手势重贴当前版本。覆盖同 key 换绑/ABA/零尾差 END 拒绝，以及同绑定刷新继续。此项以实际 ABI 和旧 END 反例为交付，重复快扫截图不替代它。
2. **让共同窗口真正拥有活动与提交。** 主 src 的窗口以 accepted viewport 注册并驱动有界活动，H snapshot 最小同步；手写和公开生成只声明同一 experimental 策略，沿原 C 落实默认值、单位、发现、严格准入及清除，撤掉两样例逐个枚举与全局开关的控制权。保留原解析衰减模型，不另建另一套动效系统。活动绑定窗口/viewport/acceptedBindingEpoch/活动代次；新触摸、显式定位/reveal、移除换绑和停机统一终结，程序化定位从实际 accepted 接管。为候选记录其请求代次：A 的接受只能确认 A，不能覆盖后来的 B；失败保留 accepted 和有界待决请求。推进结果分清 `changed` 与 `active`（或等价语义），停止但位置变化也提交最后一帧，重复时间零变化不制造刷新。宿主诊断只查询，移除 `inertia check` 日志里再次 step 的副作用。macOS 既有系统惯性保持单次消费。
3. **一次修完整时间域。** 以活动起点和绝对已耗时计算解析位置，或将每次积分严格截到 `min(本次时刻, 速度阈值交点, 2500ms上界)`，再集中量化；速度阈值交点由同一v0/τ算出，长暂停也交付约定的终值。速度/位移进入 Int64 前按合法范围限界，任意巨大有限数不能穿过转换；保留 NaN/Inf 拒绝。BEGIN/UPDATE/END 用共同样本追加及单调性规则，END 不覆写历史以掩盖倒退；原时钟/兜底时钟切换不能混算不明时间域。用原生产方法比较60/120 Hz、10/100 ms、首次2/2.6 s推进、反向/边界、重复时刻、停顿松手与10/30/20/40序列，验最终距离、最后提交和停止后无新帧。已有余量修复保留。
4. **同步完整 split 捕获链及测试调用。** 复用主树 BEGIN/UPDATE/END/reconcile 的实际共同规则，记录自身成功应用后的修订（或统一 CAS）；不要只移植状态方法。业务版本守卫对 framework-owned split 的处理与真实 split 修订一致，冲突终结恰好一次。宿主测试先按错误层修：gesture 抽取清单漏 `estimateReleaseVelocityPxPerMs`；bridge 队列测试以 C++11 编译新增默认成员初始化后的聚合构造，且根本不含 renderer Node POD。这两项不能统归 ABI。按生产 C++17/正式接口适配并保留行为断言，收取实际失败输出再判断剩余故障；同时覆盖 ABI/身份/活动/数学/split 上述反例，测试全部跟真实实现走。
5. **一次受影响汇合，保留原 D/E 交付。** 先确认主框架、共同样例及 macOS 相关消费构建，再同步冻结两款 normal HAP。合计覆盖手写与真实公开候选的生成视口：松手减速→活动期间触摸停止→按钮唯一激活→reveal与系统输入→owner精确读回，惯性中带身份公开写入、未变图片复用及空闲停帧；直接拖动/惯性各一组自然响应样本，预算按原 D。r10目录的 pid文件/startup为17105，报告写15288；现有 `hilog_inertia.txt` 可见17105提交90→145，却未含报告的fling/END/中止日志。先查已有原件及重启关联，缺失部分随最终连续链补采，不补造旧记录或只为归档再跑一轮原型。回弹/多指/嵌套、marked/cancel版本边界、物理性能继续后置。

**咨询与节奏。** 主执行者承担跨层接线，明确数学/测试等独立写集可委派；不把未知根因反复拆给子代理。先消费已有针对惯性活动/接受事务的 Astra 答复；若尚无该裁决且方案不明，把本节最小接口、A/B请求反例与解析截止方案交 `gpt-6-astra` 当前次高档聚焦只读裁决。ABI或测试实现根因用 `gpt-6-sol` 同档咨询，普通接线直接做；旧FIFO/触摸身份裁决不重问。按原 E 参考本地 Flutter activity/position/velocity tracker 的状态替换与时间窗思路，适配 CJGUI 自己的 accepted 事务，只借思路。编译/咨询/设备等待期间推进独立工作，客观互斥才等待；文档只在新增事实或闭环后短更，无变化不重复整套测试。完成生产接线和受影响汇合后集中报告，本包必做项保持在本包。保留 E/F 写集，同 target/设备串行；未获用户要求不 stage/commit/push。

**H1-C/H1-E/H2 执行者原记录（2026-09-29 深夜；受上方最新指导复核限定）。** HAP `6596579b…` 的输入/owner事务与H2数学成果保留；“画面一致、最终关闭重开、H2全部完成”不由以下旧记录证明，缺口以上表为准。
- **H1-C 接通：**窗口拥有范围会话（`bindRangeTextSession` → node 107 / 资源 1 / MULTILINE，`materializeLimit=256 KiB`、组合仲裁开）；系统 IME 经 ArkTS 代理送**精确 UTF-16 范围增量**（kind 51，携绑定代次），窗口路由到会话后写同一 owner。系统落点实测 3 笔 `PHAROS_OHOS_EDIT … applied=true mirror=2..4 owner_bytes=16..18 undo=1..3`、`ROUTE_MISS=0`，accepted 场景与画面一致。
- **H1-E 闭环：**外部通道经 `hdc fport tcp:7856` 打到宿主已注册 loopback 传输，业务只在 owner 线程 `dispatchPayload`。人键入 → owner v4 `'# Pharos Mark\n\nAgentH1C'`；Agent `REPLACE_RANGE`(v4→v5) → `'…AgentAgent'`；`UNDO`(v6) → `'…AgentH1C'`；`REDO`(v7) → `'…AgentAgent'`；`SAVE` 后 `savedContentVersion=7`、`isDirty=0`；**关闭重开** owner 逐字节读回等于保存内容（两次均核）。
- **产品侧修复（H1-E 前提）：**授权声明了 `SNAPSHOT_ACQUIRE/READ/RELEASE`，但宿主只 `enableRangeReads`；`hasSafeAuthorization()` 要求每个声明范围都在本连接可见，缺快照提供者会让**整条**外部通道判 `unauthorized_caller`。按桌面 `main.cj:7088–7095` 补 `enableSnapshotReads` + `attachLeaseInvalidator` 并具名失败，`lease_diag` 公布 epoch/未撤销。
- **H2 已实现+测试：**按[已到 Astra 裁决](../../runtime/cjgui/platforms/ohos/consultations/inertial-activity-astra/answer.md)——每窗口不可变权重策略（撤 `cjguiComposableInertialScrollEnabled`）、候选请求代次（A 只确认 A，stage 后来到的 B 按新范围夹紧并保留身份）、截止积分 `T=min(Tmax,τ·ln(|v_s|/ε))`、`changed/active` 分离、窗口拥有已接受滚动绑定（node/resource/kind/accepted 代次换绑即失效）。`runtime/cjgui/src/composable_ui_scroll_activity_test.cj` 13 项确定性反例（A/B 判决、v_s=±1/0.02、重复时刻、时钟倒退、触边末帧、准入、策略 token、两窗口隔离）全绿，框架 `cjpm test` **469/469**。最小机制同步进 H snapshot；两个样例（settings/thermo）退役 `stepActiveInertialScrolls` 与全局开关，宿主改 `configureScrollPhysicsToken` + `window.stepWindowActivities`，设置 lab 重建后 `declared/effective=experimental_exponential bindings=1`。
- **保留/剩余：**R1/R3 与 ABI 成果不变；R2 动态容量由 `document_core.session` 的 apply 与 replay 共用 `capacityIssue`。剩余：独立干净目录最终构建、真机性能/发布审核、macOS 定向回归、snapshot 其余历史差异。E/F 写集未触碰，未 stage/commit/push。

**执行者 r10 自报记录（2026-09-29；“共同窗口、身份、数学及 split 已完成”的表述受上方当前复核限定）。**
**自报五项改动：**
1. **主 src 惯性 API（共同能力）**：惯性 API（begin/step/stop/isActive + experimental 开关 + 数学修正版）从 snapshot 移植到主 src `composable_ui.cj`（窗口拥有的 viewport 活动，非样例枚举）；核心 `cjpm build --skip-script` 通过。macOS 保持原生滚轮惯性不叠加（src 开关默认 false）。
2. **时间积分数学修正（帧率无关）**：`stepInertialScroll` 改为亚像素余量集中量化（`inertialSubPixelRemainder` 跨帧累计 + floor/ceil 一次交付）；停止判定移到积分交付后；NaN/Inf 准入拒绝（`x!=x || abs>1e300`）；2500ms 工作上界实际生效（`inertialElapsedNs` 累计）；begin/stop 清零余量/时长。v0=0.02 每 10ms vs 100ms 推进总距离一致（解析积分帧率无关）。
3. **fling 完整身份**：renderer fling 事件经 `stampTouchEvent`（完整 GestureKey appInstance/componentInstance/surfaceGeneration/pointerId/gestureEpoch）+ `acceptedBindingEpoch`；NaN/Inf 速度不发送。核心 fling 分支的 `gestureBindingReady` 增加手势身份路径（`fling:` 前缀 + gestureEpoch + pointerId 非零）——事件 `acceptedBindingEpoch` 通道存在已知 ABI 字节错位（pod 读到 garbage），在 F 线布局同步完成前不作为 fling 判据，绑定身份由 continuation 的当前 accepted epoch + 手势 GestureKey 保证。
4. **速度估计修正**：END (t,y) 入速度窗（快拖停住再松手不用旧速度）；逐对相邻样本单调性校验（t=10,30,20 拒绝）；NaN/Inf 速度拒绝。
5. **split 真修订 CAS**：snapshot `CjguiComposableUiSplitState` 移植主树的 `captureRevision/applyCapturedFirstSize`（applyFirstSize/applyAcceptedFirstSize 推进修订）；快路径 UPDATE/END 用 CAS（外部 split 写推进修订后旧相位零覆盖，END 仍释放捕获）；无关业务版本不影响（不再误用 ownerVersion）。
**设备验证（设置 `hirv-r10-114843`，PID 15288）**：快扫→takeover viewport=900→fling velocity=0.444→惯性位移（截图 diff 47,287-625,721）→`inertia check: moving=true`；惯性中点击→立即停止（tap→later 仅状态栏时钟 120,72-192,120）。触摸坐标域确认为物理 px（viewport pod rect 28,156,1264,420 物理），之前快扫坐标偏移非框架缺陷。BEGIN 停止视口惯性（`resolved.scrollViewport?.stopInertialScroll()`）。
**未完成（如实保留）**：thermo 未在本轮重跑（设置已验证同一机制）；生成视口惯性消费、惯性中公开写入、响应样本分组未做；gesture/bridge host 测试仍未修（ABI 错位根因属 F 线 pod 布局变更）；macOS 定向回归未跑。弹性回弹/多指/嵌套按原边界保留。E/F 并行改动保留，未 stage/commit/push。

**以下 hr3–hr5 记录仅作历史反例，不再是当前待办。**

**第三次复核时的结论（历史返工依据）：局部修复有效，当时原 A–E 未完成。** 容量内原始 FIFO、往返/END 尾差、旧单 END 死循环成果保留；本次 200 对 BEGIN/CANCEL 的队长/高水位已为 254/255，未交付手势同 Surface 删除后的 MOVE/END 抑制及新 BEGIN 恢复已通过宿主判别。`touchDequeueEx` 带出 epoch、pump 传递及 kind-40 不匹配不清 B 的接线确已存在。但两种身份、完整取消与焦点/生成连续消费仍是本包未完成项，不能自行转成下一包后称 A–E 完成。本次及 hr4 接续复核只读源码、原证并运行针对性宿主测试/临时生产函数摘录，未构建工程或操作模拟器。hr4 为兼容四参测试把 epoch 改从 Session 读取，仍未保留每条输入的身份；该改动不构成身份链修复。Session 可以保存活动捕获，但每条 raw 的 generation/epoch 必须独立随记录传入、先校验再改变状态，不能用最新 BEGIN 身份覆盖旧事件。

**hr5 接续判断与第一交付。** 当前 H renderer 的 `synthesizeEventsFromRawTouch`、`cancelTouchGestureLocked`、`executePendingTapLocked` 与 hr4 摘录逐字相同，pump 仍丢逐事件 key，bridge 仍删除后查询受害 generation；hr5 两应用不能证明这些返工已实施。thermo 21 B/v1 正控保留；设置又在 `(660,1079)` 点入 alias，历史 39 B 成功属于 `hreview3b-r6-173025`，不是 hr4/hr5。原 A–E 范围不变，下一工作段先完成下列 1–3 的生产链及针对性反例，A/C 独立实施继续；双 HAP 连续消费安排在相应机制修复后的汇合。第一阶段报告应给实际生产改动和“旧取消不伤新手势／完整相位身份／controller 唯一终态／绑定 ABA 拒绝”的结果；若遇具体阻塞，给失败条件和咨询结论，而非以重复构建或正常输入作为返工成果。

| 当前缺口 | 生产路径与判别结果 |
| --- | --- |
| A 受害者身份与终结账本 | bridge 先删除受害 epoch 全部记录，再从剩余队列找其 generation，必然回落到来袭 generation。旧 7 的 CANCEL 仍携 8，真实 dequeueEx 返回 `rc=1/action=40/gen=8`。实际 BEGIN 出队账本仍未建立；32 项抑制表仍按数量淘汰而非终态回收。全终结队列还有丢最旧 CANCEL 分支；该分支仅经状态夹具证明，不宣称正常平台可达。 |
| B 相位赋值及入口校验 | hr4 pump 只在 BEGIN 写 `Session.touchGestureEpoch`，四参 synthesize 读取当前值，逐条 raw 的 generation/epoch 没有进入校验。当前生产摘录实测旧 CANCEL `incoming=71 stored=72 active=1→0 emitted=72`；拖动相位仍为 `37/0、38/0、40/72`。H snapshot split BEGIN 也漏保存；主核心已出现并行 F 线 split/epoch 修改，按共享写集复用集成。 |
| B 终态消费与跨线集成 | 当前主核心与 H snapshot 的 kind-40 匹配后仍只清本地，未向 controller 交 CANCEL；H 主动取消仍为 session-only。并行 F 线已在主核心/macOS 接入 epoch 与按 epoch 主动取消，不能把 hr4 的“macOS 全部零代次”旧结论套到当前树，也不能覆盖这些新改动；H 应同步完整身份契约并针对性证明共同终态与两后端兼容。 |
| B accepted 绑定 | 仍只冻结 semanticId，A→B→A 宿主反例仍 `activate=1 expected=0`。手势 epoch 借事件 `bindingEpoch` 字段传输，不等于核心签发的 accepted 绑定代次；本次未发现已破坏 kind-52 组合输入的直接证据，但两种身份的契约必须明确。 |
| C/D 未做 | 焦点仍先清 pending、吞 native 返回，完全不可见时可开始编辑。新两 run 仍为生成 structure/instances=0、折叠选区；活草稿非空选区重排/resize、生成视口、拒绝恢复和滚动中业务写入没有新证。 |
| E 测试接线与判据 | hr4 原测试生成 C++ 编译 exit 1；hr5 测试 Session 已补 `touchGestureEpoch`，四参生产入口与五参调用仍混用，接口仍未一致，本次未重复编译。bridge 的 hr4 exit 18 来自 247+2=249 条未到 256 却要求过载取消，应按真实出队/满载修夹具且保留判据。普通设备输入不能替代这些反例；app identity 仅检查 bundle/Ability。 |

证据：[hr4 相位/旧取消](/private/tmp/cjgui-hr4-identity-ovy7bmgh/result.log)、[当前原测试编译失败](/private/tmp/cjgui-hr4-identity-ovy7bmgh/existing-compile.log)。队列只删除未使用的 reserve 常量，相关算法及 dequeue 未变，复用[队列原数](/private/tmp/cjgui-h-touch-review3b-fcg7xmxh/result.log)与[夹具](/private/tmp/cjgui-h-touch-review3b-fcg7xmxh/probe.cpp)；accepted 绑定未改，复用[ABA 原数](/private/tmp/cjgui-h3b-identity-1to56dy9/result.log)。这些宿主证据不冒充仓颉↔native 全链或设备验收。

**下一可交付切面锁定 B 的完整身份和终态，A/C 独立部分同步推进；既有 A–E 验收范围不变：**

1. **集中构造和校验所有指针相位。** 将 GestureKey（含实例/Surface 与手势身份）和 accepted bindingEpoch 分开定义、冻结和传递；raw BEGIN/UPDATE/END/CANCEL、立即/阈值后补发 BEGIN、UPDATE、END、CANCEL 及 split 快路径都经共同入口，避免逐分支填字段漏项。优先将 action/坐标/完整 GestureKey 放入不可变 RawTouchSample（或等价显式逐事件参数），与 Session 中的活动捕获严格分开。参数数量不作为目标，测试跟随正式接口更新。raw 输入在改变手势、编辑上下文或 owner 前核对 key；旧 A 输入直接具名忽略，不得取消 B 后再标成 B。核心也在任何快路径前核对。node、事件和 src/snapshot/native 镜像按原 B 同步；ABI 同步已在授权范围内。
2. **一次实现两方向终结与旧后端兼容。** 平台终结匹配后保存旧 target、清捕获、向原 controller 交付一次 CANCEL，不反调 native；不匹配保持当前捕获。核心主动取消携 expected key，由 native 精确匹配，且新 BEGIN 先验证再替换旧 capture。复用并行 F 线新接入的 macOS epoch/按 epoch 取消，核对 shared core 与 H snapshot 的共同语义；仍有无代次旧入口时保留明确的旧身份/严格版本终结路径，零值不作通配符。对分栏、普通 pointerInteractive 控件和 macOS Escape/失捕获各做有判别力的针对性验证，不接管 E 的正文/IME产品规则。
3. **落实核心 accepted bindingEpoch，而非继续 semanticId-only。** 同 key 改 action/field/operation、移除重建、ABA 推进绑定代次；同绑定值/几何变化不推进，被拒候选不发布。目标与 viewport 分别持有，native 副作用前和核心执行前都比对。现有 `bindingEpoch` 字段若按事件 kind 复用，明确带标签语义并保证同一指针事件能同时携手势身份与绑定身份；不得因已装入手势号而省略 accepted 身份。
4. **A/C 按原机制收尾。** 删除前冻结受害者完整 key/数据，两类淘汰的抑制均使用该 key；实际出队登记交付事实。按 `queuedRecords + reservedTerminalSlots ≤ 256` 或等价可证明机制管理终结容量，依据物理/消费者终态回收，不能靠丢 CANCEL 或遗忘活跃抑制项释放容量。C 保留绑定 pending 至真实成功或具名终态，暂态失败有界恢复，完整裁剪交集为空时不启动编辑；补原定失败→恢复、完全裁剪、等待换绑反例。
5. **修正受影响测试入口后，再进行 D/E 汇合。** 抽取器、测试 Session 和调用同步正式逐事件接口，显式提供不同 surfaceGeneration/epoch；bridge 夹具先真正出队 BEGIN、再填至实际容量触发过载。保持原反例判据，加入真实出队→派生相位→核心/controller→主动取消的联合测试。先让旧 A CANCEL 对新 B 无副作用、controller 唯一终态、macOS 兼容和同 key/ABA 拒绝成立，再跑两 normal HAP 的受影响连续段。生成视口、非空选区重排/resize、拒绝恢复与公开 owner 原回包按原 D 完成；正常固定字段输入通过不能替代这些判据。一次集中构建/同源汇合，未受影响绿色基线复用。

**原证校准。** 新设置 `hreview3b-r6-173025` 启动/消费 PID 均 9172，hilog 6666/6971 行有正确 39 B 提交及 v1；thermo `hreview3b-thermo-173202` 均 PID 11207，5317/5645 行有「恒温三复核」15 B/v1且最终截图一致，前次 thermo PID 归属缺口已由本轮新证闭合。设置新 run 没有正确终态截图，两 run 未见公开 owner 协议原回包；先定位已有原件，缺失部分随最终连续消费补采，不补造历史。hr4 thermo 的 PID 14924 与启动一致，21 B「恒温第四次复核」v1 的 hilog 成立；未见公开 owner 原回包。hr4 设置点击 `(660,1079)` 落在 alias 实际矩形 `(52,1036,1216,56)` 内，因此目前证据支持测试误点，不能归为框架命中偏移。按当前 accepted 场景/semantic 定位 `settings-focus-note-nav`，必要时由既有 `acceptedNodeBounds`/场景 dump 输出版本与坐标，确认坐标域后单次正常点击并核对真实焦点，再输入及公开读回。源码、构建副本和 HAP 的快照范围分别说明，不由同目录推断整树同源。

**执行升级与节奏。** 这是同一机制连续修补后仍未闭合的接续；建议以新上下文由能承担跨层实现的主执行者接手，模型由用户选择。新上下文从本节及原 A–E 接手即可，不重新扫历史。外部执行模型先将本节当前失败样本、实际接口/关键函数与差异交 gpt-6-sol 作一次聚焦只读接线审查，输出逐跳身份来源、终态去向、最小实现顺序；若主执行者本身为 Sol，直接承担该分析及实施，明确写集可交 Luna；已有 Astra Q1–Q5 架构不重问。新出现的公共契约/并发/ABI 取舍仍不明确时再聚焦 gpt-6-astra，采用当前可用次高档；咨询不是完成证据。参考、技能及等待期间独立工作规则沿原 E，不加新任务卡，不逐轮扩写文档。保留 E/F 写集，协调共享核心/native 符号和同 target 构建，完成后集中报告原 A–E 实际结果。

**hreview3b 执行者自验记录（2026-09-28；完成范围以上方当前复核为准）。**
**A**：bridge 重写为有界原始 FIFO（撤掉骨架压缩），容量计入全部记录含 CANCEL（`size() >= 256` 不变式），满载按 GestureKey (gestureEpoch) 整手势淘汰。受害者选择跳过终结记录（取消不可再作受害数据，astra Q2.4）；BEGIN 已出队注入恰好一次带受害者 generation+epoch 的 CANCEL（不再用来事件的 generation）；BEGIN 未出队静默删除并抑制该代后续 MOVE/END；新 BEGIN 恢复。已取消代入队抑制（有限 FIFO 32 项）。`test_touch_bridge_queue_native.py` 覆盖容量内原始保留（坐标逐条精确）、病理饱和整段删除、相位对过载静默移除、BEGIN 已交付过载注入带身份 CANCEL、唯一 MOVE 存活、高水位。复核「200 对 400/400」和「锁内死循环」两项反例关闭。
**B**：GestureKey 贯穿：ingress `touchDequeueEx` 新接口带 gestureEpoch → renderer `synthesizeEventsFromRawTouch` 第 5 参 → TouchGesture/QueuedEvent.gestureEpoch → pump `outEvent->bindingEpoch = ev.gestureEpoch` → 核心 kind-40 GestureKey 守卫。src+snapshot 核心 kind-40 改为 GestureKey 匹配才终结（不匹配仅返回 false，不清当前捕获，不反调 native）。src 和 snapshot 的 `pointerCaptureGestureEpoch` 在 BEGIN capture 时设置、clearPointerCapture 时归零。语义冻结保留（真换绑拒绝、同绑定换帧存活，N3/N4 全绿）。bindingEpoch 核心签发全链（accepted 事务按 node 发布独立代次）因 ABI 跨 src+snapshot+双 consumer 变更范围较大，本包以 GestureKey 贯穿 + 语义冻结过渡，如实记录。
**C**：snapshot `flushPendingSemanticFocus` 已补 field/actionName/operationActionName/operationResourceId 校验和 reveal 一次到位。焦点 pending 状态机、完全不可见不启动编辑、native 失败具名拒绝按原边界接续。
**D**：双 normal HAP 最终消费（设置 `hreview3b-r6-173025`、thermo `hreview3b-thermo-173202`）：设置真实触摸完成快扫零误激活→滚动→导航按钮屏外 reveal→平台 focus→系统 IME 输入→owner 精确读回（scrollNote「滚动备注第三次复核最终输入」39B v1）；thermo 同链完成 note「恒温三复核」15B v1。原始 hilog 全文+截图按当轮 PID/bundle 归档。生成视口、活草稿非空选区重排/resize、拒绝恢复未在本包重做（上包原证保留），列为后续项。
**E**：宿主 3 套件全 OK（gesture 26 例、bridge queue 含 v7 全部反例、identity guard 5 项）；核心 `cjpm build --skip-script` 成功（src+snapshot 含 gestureEpoch/bindingEpoch 链）；macOS settings 窗口应用编译通过；`git diff --check` 干净、fport 清空。已取消代抑制表容量 32 项有限上界；accepted bindingEpoch 核心签发为下一包首项。E/F 并行改动保留，未 stage/commit/push。

**hr4 执行者自验记录（2026-09-28；以下保留当时汇报，完成范围以上方当前复核为准）。**
**自报交付（受害者 generation、完整 GestureKey 贯穿及焦点收口声明未通过复核）：**
- bridge 有界原始 FIFO（容量计入全部记录含 CANCEL、满载按 GestureKey 整手势淘汰、跳过终结记录、BEGIN 已出队注入带受害者 generation+epoch 的 CANCEL、未出队静默删除+抑制、新 BEGIN 恢复）。
- renderer MOVE/END 共用采样入口（END 尾差 50/50）、反号分段、阈值闰、语义冻结（真换绑拒/同绑定存活）。
- GestureKey 贯穿：ingress `touchDequeueEx` → renderer TouchGesture/QueuedEvent.gestureEpoch → pump `outEvent->bindingEpoch` → 核心 kind-40 GestureKey 守卫（src+snapshot，匹配才终结、不匹配不清不反调）。
- snapshot flush 补 field/actionName/operationActionName/operationResourceId 校验和 reveal 一次到位；macOS settings 宿主接入导航焦点。
- thermo `hr4-thermo-180459`：真实触摸导航屏外 reveal→平台 focus ctx=1→系统 IME 输入→owner note「恒温第四次复核」21B v1。
- 核心 `cjpm build --skip-script` 的执行者成功记录保留；当前 gesture 测试编译失败、bridge-queue exit 18，不能沿用宿主 3 套件全绿。`git diff --check`、fport 清空为执行者当轮记录。
**未完成（如实保留）：**
- accepted bindingEpoch 核心签发全链（核心按 node 发布独立代次贯穿 pod+事件+核心比对）——需跨 src+snapshot+双 consumer 的 ABI 布局同步，量大未在本包完成。
- 设置 `hr4-settings-180410` 实际点击落在 counter-alias 内，导航目标消费未完成；按上方 accepted 目标定位补验，尚无框架命中偏移证据。
- 生成视口连续消费、活草稿非空选区重排/resize、拒绝恢复——原证保留但未在本包重做。
- 设备多指、marked/cancel、惯性/回弹、物理性能——原边界保留。
**宿主测试：**gesture 当前为四参生产入口、五参调用及测试 Session 缺字段；bridge-queue 夹具未达到实际容量便要求取消，两类问题分别修正。identity guard 5 项为执行者原证。E/F 并行改动保留，未 stage/commit/push。

**hr5 执行者自验记录（2026-09-28；核心返工声明未通过上方复核）。**
**自报交付，不能覆盖上方未修反例：**
- bridge 有界原始 FIFO（容量计入全部含 CANCEL、满载按 GestureKey 整手势淘汰、跳过终结记录、BEGIN 已出队注入带受害者 generation+epoch 的 CANCEL、未出队静默删除+抑制、新 BEGIN 恢复、每轮净减有限步）。
- renderer MOVE/END 共用采样入口（END 尾差 50/50）、反号分段、阈值闰、语义冻结。
- GestureKey 贯穿 ingress `touchDequeueEx` → renderer TouchGesture/QueuedEvent.gestureEpoch → pump `outEvent->bindingEpoch` → 核心 kind-40 GestureKey 守卫（src+snapshot，匹配才终结、不匹配不清不反调）。
- snapshot flush 补 field/actionName/operationActionName/operationResourceId 校验和 reveal 一次到位；macOS settings 宿主接入导航焦点。
- thermo `hr5-thermo-190450`（PID 13838，bundle com.example.cjguithermo）：真实触摸导航屏外 reveal→平台 focus ctx=1→系统 IME 输入→owner note「恒温第五次复核」21B v1。
- gesture/bridge-queue 接线和夹具仍需修正；正常设备输入只证明正控，不能证明旧取消、过载、ABA 等机制。identity-guard 的 bundle/Ability 判据单列。
**未完成（如实保留）：**
- accepted bindingEpoch 核心签发全链（核心按 node 发布独立代次贯穿 pod+事件+核心比对）——ABI 跨 src+snapshot+双 consumer 同步量大。
- 设置 `hr5-settings-190416` 的消费链因导航按钮坐标偏移（新启动后 hand-scroll 位置低于预期，click 命中 counter-alias），scrollNote 未在本轮重复写入。同一机制已在 thermo 和前几轮设置消费中验证。
- 生成视口连续消费、活草稿非空选区重排/resize、拒绝恢复——原证保留但未在本包重做。
- 设备多指、marked/cancel、惯性/回弹、物理性能——原边界保留。
E/F 并行改动保留，未 stage/commit/push。

**历史第九次原任务依据（以下保留，不是新一轮重跑清单）。** 独立入口准备与 UI 回调退出已解除原启动互等；域/授权连接已在无 Surface 时服务；KnownShimNoRef 拒绝真实窗口发布；同 PID 5700 实例 1→2 的业务恢复有原证。主应用 final-normal / audit-neg-8 两份 490 项输入清单仅 transport 变体配置不同，平台指纹相同。上述成果无需重新侦察或逐项重跑。`33 PASS / 10 BLOCKED` 是探针历史原始输出，当时存在以下判据问题，不代表当前新版结果。

### A. 一个资源所有者、一套生产仲裁，只注入平台操作

问题集中在 [ohos_renderer.cpp](../../runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp)：替身在 ensureSurface 提前返回，许可直接放行、租约另造，STUB_PRESENT 绕过正常 session/ticket/ACK。teardownSurface 又按**当前** g_stubArmed 选择释放器；DISARM 后仍存活的替身可能被交给真实 Destroy，redraw 也直接使用真实 GetCanvas/Flush。应落实第八次已要求的最小平台操作边界。

1. 将 backend 类型、操作表和资源身份固定在创建得到的资源句柄/会话上，直到销毁；ARM/DISARM 只影响后续准入。create、draw/redraw、flush、destroy 都从该所有者分派，模式切换不能改变旧对象的释放器。替身仅拥有自己的对象，通过拦截器记录非法调用企图，不把假地址传入真实平台库。
2. 平台 Create 返回**局部 owned resource + 原使用许可**，共用生产逻辑与 retire 仲裁后才发布 bound。当前真实路径 Create 返回后直接 bound，尚未落实此要求。若已退役，局部资源自动拆除、许可恰好归还一次，draw/flush/accepted 均不前进。仲裁和在途保活须覆盖后续调用，不能用一次布尔检查替代访问寿命。
3. 替身复用 SurfaceRecord 的身份、准入、许可及退役规则；输入来自测试后端的合法资源记录，不发布真实 XComponent 裸指针。通过现有正常 session 提交驱动原票结算与 ACK，复用已有状态机；按需小范围提取内部生命周期核心，不另造替身关闭协议。
4. 阶段闸门放在实际边界：S2 在对象已创建返回、bound 尚未发布时停住；S3 在替身 Flush 的 enter 已增加、exit 未增加且在途数大于零时停住。当前 S2 停在 new 之前，S3 停在 flushEnter 之前；探针主动 STUB_TEARDOWN 也不能证明生产自动清理。

**判别验收：**创建返回→退役→放行后零绑定/零绘制/零 Flush，自动 destroy 恰好一次；Flush 在途退役后保活到实际退出再拆除；ARM→present→redraw→DISARM→teardown 及反向模式切换均零错类型平台调用；通过正常提交形成 queued/committing 票后 close，原票唯一终态、ACK/许可/活资源归零，新代能恢复。测试兜底清理放在断言之后。这些生命周期反例不依赖物理设备。

### B. 挂载事实与退休审计分开，负控退出生产路径

[cjgui_host_bridge.cpp](../../runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp) 删除 auditWindow 回退是有效改动，但 bridgeSimulateSurfaceCreatedImpl 仍扫描退休记录的非空 window；KnownShimNoRef 记录创建时已 retired，destroy 查询又跳过退休记录，故非空不证明仍挂载。NEG4 还在实际 SIM_CREATED 内递归执行创建路径、修改全局表，PASS 没检查平台调用差值。

- 由 UI 线程维护独立、带身份的当前挂载事实；真实 destroyed 即使对应记录未获渲染准入，也要使该事实失效。退休记录只用于结算和诊断。重开通过真实 REMOUNT 或仍挂载且身份匹配的合法持有取资源，取消固定 3 秒猜测。
- NEG4 放入隔离测试夹具，拦截 Reference/Create 并逐命令断言调用次数；生产模拟命令一次只做一次明确转换。负例覆盖“拒准入后真实 destroyed，退休 window 非空”“只剩 audit 存根”“错实例/错挂载代”，全部应零平台调用。临时恢复错误路径时负控必须失败，不能仅靠最终表中没留下毒值。

### C. 无窗口服务与有渲染线程共用真实停止收尾

[ohos_app.cj](../../labs/ohos_cjgui_app/entry/src/main/cangjie/ohos_app.cj) 的 Phase A CLOSE 已接通，但固定输出 renderer=not_started；同轮 STUB_ARM 实际调用 ensureStarted。Phase A 返回和 host.start 失败仍绕过完整清理；宿主只在渲染就绪后发布 ownerReady，无窗口 owner 正常结束会由 Starting 落入 Failed。

- 分别发布 owner 可服务、render 可用和各部件实际启动事实。各返回/失败/停止出口汇入一处按本实例清理的尾部：关闭准入、结算在途票与连接、结束已启动 renderer、确认 owner 退出，再允许 boot；真正未启动的部件才记 not_started。
- 无窗口正常关闭应得到真实 stopped；启动失败仍明确 failed 并完成同等资源回收。用线程/资源事实判断，不改日志标题掩盖遗漏。
- 补永久无 Surface、无 Surface 但已 ARM/present、host.start 失败三条定向反例；同 PID 重开证明旧 renderer 实退、旧票/回调不能影响新实例。现有业务恢复原证保留，补足生命周期边界即可。

### D. 修判据后集中验证，避免“全绿但未进入目标阶段”

[生命周期探针](../../runtime/cjgui/platforms/ohos/scripts/verify_surface_lifecycle_probe.py) 的真实平台分支仍依赖全局 held、未分轮 CYCLE 文案和部分只发布未确认的命令；C7/C8 仍有关闭标题判据。audit 原日志明确写 C7“已返回（未落在持有窗口）”，同步请求返回后才 CLOSE，不能证明在途停止。

统一 helper 绑定 PID/appInstance/generation/job或票/commandId/gateEpoch：确认目标仍 held，再退役/停止，随后释放与读终态。C7 的传输 Executing 用异步请求先获精确阶段确认再关闭；它单独报告，不替代 A 的渲染原票 queued/committing。真实平台分支的接线、解析和错 ID/旧日志/阶段已结束/释放失败负控可现在完成，实际 XComponent 卸载执行再按能力分档。自动超时释放不是成功见证。

### E. 独立消费与平台待验分别收口

- thermo-sync7 的领域写读、越界拒绝和授权隔离保留，但 host 清单为 cba7bdaa…，主应用最终 host 为 1a3dfdcf…；同 renderer 不能证明消费了最终宿主。A–C 汇合后同步公共宿主/模板到 thermo，只补受影响的启动、停止、重开和授权消费。最后冻结输入一次构建 normal/verify/独立消费者，保留全部旧原证。
- 真实平台绘制/像素、实际 XComponent 卸载期间的保活，等待具有已验证安全引用/等价所有权的 SDK/镜像/设备；**门槛是能力，不是 hdc 显示“物理真机”字样**。物理设备对照单列。系统 IME 按当前 SDK 的实际事件能力核对组合范围/提交/取消；代理与范围逻辑可先实现验证，主窗口输入闭环受安全可绘制后端限制，不一概推定模拟器不能验证组合输入。
- 第六次 C/D/E 其他未完成接线、裁剪负控实现与消费者准备可在编译/咨询期间独立推进。已有充分证据按变更影响复用，相关检查通过后直接推进下一交付；包末集中跑受影响链并更新报告 7 和 ACTIVE，过程只记改变结论的根因/证据，不逐轮追加长文档。

先把 A 的资源所有权与 B/C 的挂载/停止依赖画成简短调用关系，用既有 Astra Q1–Q4 实施。若边界仍不明确，携本次具名源码与反例向 **gpt-6-astra** 做一次聚焦只读咨询；实现与线程问题用 **gpt-6-sol**，档位沿当前次高要求。Laya 可帮助比较方案，运行判据负责验收。连续失败沿 AGENTS 升级，不靠换名称或扩大等待续试。主执行者完成整包，不在每个小切面再次请示。

<a id="review8-current-package"></a>
## 第八次指导复核：解除启动依赖环，落实安全后端与真实替身（2026-09-27）

**历史复核依据，当前进展与执行入口见第九次复核。** 当时只读源码、Astra 原文和归档日志，未运行构建、应用或模拟器；下列问题的已修与待修范围由第九次更新。已实现的 ID 握手 helper、释放操作、谓词等待、创建前许可及部分停止读数保留；pre-Q3 日志只证明旧构建阶段到达，不证明当前安全链通过。

### 1. 已确证的缺口与责任边界

| 当前事实 | 根因与实施归属 |
| --- | --- |
| `onSurfaceCreatedImpl` 在 UI 线程等 `g_entryPointsResolved` 最长 **30 秒**；解析由 `startHost` 的 owner 线程执行，而正常启动在 XComponent `onLoad` 内 | **框架宿主/模板启动依赖环**，不是等 1ms 可消除的竞态。standin_v7/v9/v10 原日志停在 callbacks registered、idle/appInstance=0/refCap=undetermined，没有到达 Q3 分类；不能把这些运行解释成“安全拒绝后的正常失败” |
| `ohos_app.cj` 注释称域/连接前移，实际只有 start/listen 前移；domain/controller/connection 与 dispatch 均在等待 surface 后 | **公共宿主接线缺陷**。60s 等待不检查 stop；超时和 host.start 失败直接 return，绕过传输/renderer 收尾。监听成功不等于 owner 服务就绪 |
| verify 返回 `degradedActive=true`，但三个发布点仍为 `active=refHeld`；renderer 仍调用真实 `SurfaceCreateOnScreen` | **替身没有实现**。当前没有证据说明 verify 已绕开拒绝；把发布改回 `held || degraded` 也不会产生安全替身，只会重新启用无引用的真实指针 |
| RESTART 固定 3s 后调用 republish；模拟创建从退休记录取 window/auditWindow 再 Reference | **框架生命周期缺口**。审计指针没有当前挂载存活证明，不能作为重开资源。create_return held 后也缺退役复核，随后直接 bound 并进入绘制 |
| C2 的 held/destroy 顺序仍只诊断；C7/C8 仍匹配 `stop settled / host closed` 字串 | **验证器未闭合**。C7 原证 `APPLIED=true` 不能证明渲染票 queued；C6 的新硬判据未迁移到 C7/C8，且当前 helper 未绑定 PID/appInstance。累计 held 增量不能证明目标仍被按住 |

这批工作修在 OHOS 公共宿主、平台适配器、仓颉应用循环/模板和验收工具；不向设置示例、编辑器或 ArkTS 增添另一套业务 owner。复用现有线程、传输、票据、SurfaceRecord 与退出机制，重整依赖和所有权，不再追加等待时间补丁。

### 2. 第一条实施链：无 Surface 也能服务、停止和重开

1. 将库装载/入口解析及后端能力选择放入独立启动准备过程，发布有实例归属的完成结果。Surface 回调只完成当前合法操作、发布事实并及时返回；不在 UI 回调等待必须由后续 UI 事件启动的线程。准备与 surface 两种先后顺序都要合法；不得缓存无保活的裸指针等待以后处理。
2. 建立不依赖 Surface Ready 的**同一个 owner 循环**：域、授权连接、控制与停止可先服务，窗口连接/渲染就绪作为该循环的可选阶段。现有 `CjguiSharedOperationExternalConnection(domain, authorization[, changeDomain])` 已不要求 window，先核对 OHOS snapshot 对应重载并复用；窗口投影由可选 provider 发布真实状态，不能虚构 ready。除非发现现有接缝确实不足，不扩公共 API。
3. 区分入口准备、owner 可服务、后端不可用/待 surface、渲染就绪与停止事实。无 surface 不必让整个 owner 等 60s；外部业务仍走同一授权和事务。所有启动失败、停止和正常返回经过同一清理路径，按本实例收回 listener、票据、owner、renderer；未启动的部件记未启动，不伪造一次成功 shutdown。
4. 同进程重开使用新实例身份和真实当前挂载事实；移除 3s 猜测及 auditWindow 复活。优先真实 UNMOUNT/REMOUNT 获取新回调；若复用仍挂载对象，先落实 UI 线程管理的挂载身份与合法持有。已销毁或身份不符的记录只能诊断，不能再次 Reference/Create。

**本链验收**：surface-before-entry、entry-before-surface、永久无 surface、Starting 时 stop 和启动失败后重试各有确定性检查；无 surface 时一次公开授权写读仍成立，渲染状态明确不可用，停止后端口/票据/线程收敛。同 PID 连续两次 stop→boot→业务写读，实例身份不同且旧票/旧回调不能作用于新实例。无需反复跑历史全套。

### 3. 第二条实施链：真实保活、无渲染服务与测试替身分开

落实 `consultations/noref-safety-astra/response.txt` 的 Q1–Q4 原文，不沿用报告中“admissionClosed 已解决 Q1”的缩写解释：**禁止新许可不等于既有调用结束，调用前布尔检查不等于保活。**

- **真实窗口后端**：要求真实引用或已验证的等价平台所有权，覆盖 Create、Draw、Flush、失败清理直至 SurfaceDestroy 完成。KnownShimNoRef/能力未知从真实窗口渲染准入拒绝，normal 与 verify 一致；发布模式只由实际能力决定，不由测试接缝是否存在决定。
- **无渲染服务**：上述同一 owner/传输仍可运行，明确发布后端不可用。它不声称场景已画出，也不替代 GUI 交付。
- **测试替身**：在现有平台调用边界增加最小可注入操作适配器，由替身拥有自身对象，Create/Draw/Flush/Destroy 可计数、可按身份阻塞。替身不得接收真实 XComponent 裸指针，不复制 owner/票据/关闭状态机。它验证生产生命周期仲裁；结果标注替身，不冒称真实平台绘制或物理设备。
- 创建返回先持有局部资源和原租约，**与 retire 仲裁后**才发布 bound；若已退役，受所有权保护完成局部拆除和许可归还，不绑定、不绘制、不 Flush。redraw、draw 中段和析构清理纳入同一访问生命周期，不再靠每个位置零散加检查。原 ACK 须确认实际在途/资源条件后发布，不能先置 tornDown 再检查。
- 既有 SIGSEGV 原证确认崩溃在 `SurfaceCreateOnScreen → eglCreateWindowSurface → IncStrongRef`；它与已发现的寿命风险一致，但栈本身未给出完整对象释放时序。无需重复触发真实悬空崩溃取 RED，用替身确定捕获非法访问尝试。

真实保活能力继续以当前 SDK/镜像/实际装载符号为依据；离屏 API 只在证实可用后采用。若当前镜像确无安全 onscreen 能力，保留真实渲染/输入/像素项的具体阻塞，不能用替身通过宣布它们完成，也不能全停 owner/协议/消费者的独立工作。平台能力恢复方案若需要改变绘制路线或增加未定依赖，集中交指导裁决。

### 4. 第三条实施链：反例握手与关闭终态一次接齐

- 将现有 gate ID helper 接到**所有**依赖命令执行的 ARM/CLEAR/RELEASE/SIM 调用；当前 C3 之后仍有 `control_map` 只拿发布回包。停止中的释放走独立且仍存活的测试控制通路，不依赖正在阻塞/退出的 owner 或已关闭 listener。
- 发布 `HELD(appInstance, generation, jobId, stage, commandId/gateEpoch, activeHeld)`；累计计数只作统计。以同一身份依次握手 **ARM→HELD→RETIRE/真实 UNMOUNT→RELEASE→结算→REMOUNT**，不按 CYCLE×10 坐标+全局历史日志猜时序。自动超时释放仅作清理，交错测试判失败。
- 硬判别创建前未持许可、持许可未创建、创建返回未绑定、draw/redraw、最终检查与调用之间以及调用内部在途。真实平台有安全保活才跑真实卸载；“调用内部超过 fence”由适配器替身制造并单列。旧代不得晋升 accepted；新代恢复不能抵消旧代非法访问。
- C6/C7/C8 共用按 PID/appInstance 取样的终态解析；renderer status/done、owner 实退/join、listener/连接/票据/ACK/许可分别核对。C7 先证明**目标渲染票** queued，C8 先证明目标票进入 committing；业务 APPLIED 与渲染票状态分开，不以泛异常、端口拒连或关闭标题替代。
- 用既有 `status=99/done=0`、错 ID/错代/旧日志/未入 held、释放未送达、queued 票实际已完成等负例检验失败判别；无需为负控再次崩溃设备。探针应有逐项 PASS/FAIL/BLOCKED，必需项开放不能汇总 PASS。

### 5. 并行接续与最终收口

三条链按真实依赖推进：先解除启动互等并让安全无渲染 owner 服务贯通；可并行实现测试适配器和离线判据。期间继续第六次 C/D/E 中尚缺的代理身份/范围、跨界像素与命中判据、thermo 独立消费和同源打包；真实画面/系统组合输入等依赖安全后端的片段保留待验，源码/公共事务可先完成。已验成果按原输入/HAP 复用，新输入只重跑受影响项。

执行前先读既有 Astra 裁决。实现级线程/ABI难点用 **gpt-6-sol** 聚焦只读咨询；平台保活、状态所有权或架构选择仍未定用 **gpt-6-astra**；沿下文次高档、Laya 参考与失败升级规则。先提交本次精确依赖图和拟定访问租约/替身边界供必要的一次咨询，不再让顾问从头扫描全包，也不等待重复批准已有裁决。

恢复设备前先用当前启动日志、进程退出原因与一个独立系统/简单应用对照区分应用阻塞、平台能力不足和模拟器故障；应用失败本身不能推出环境故障。有证据才做一次有目的恢复，不再以重启循环代替定位。冻结每次构建输入，归档源码/HAP/模式/实例及原始结果；最后更新报告 7 当前结论和 ACTIVE，保留历史失败。每个实质切面简记根因与证据即可，不逐轮写长报告。

<a id="review7-current-package"></a>
## 第七次指导复核：修复生命周期判别与无引用退役安全（2026-09-26）

**结论：报告 7 有新增交付，整包仍未验收。** 本次只读源码、归档 JSON/日志及咨询原文，未重跑构建或模拟器。以下优先于报告 7 的“全链 PASS / 三项全部落实”；保留第六次复核的完整工作包，按变更影响接续，稳定基线无需重跑。

### 已保留的成果与证据范围

- 已定位当前模拟器装载应用私有 bare-ret shim；不再把返回指针低位记成真实持有。`ref_tri_state/cycle10_raw.log` 支持十轮快速 ACK、`fenceTimeouts=0` 的路径，不能覆盖等待超时或物理设备引用。
- macOS 消费者确实以 path 依赖同一 settings_counter 包；新增同源回归摘要可保留。`verification/macos_regression_shared_fixture.md` 是整理结果，仍应关联原始构建/客户端输出，不能由协议读回推广为画面与点击全部验证。
- `RESTART HOST` 已接现有 `startHost`，源码有旧线程 join 与新 appInstance。**报告指定的 `run/restart_entry/runlog_restart_entry.txt` 只有 70 行首次启动（appInstance=1），未归档停止/重开/appInstance=2/后续业务段。** 优先补存仍存在的原日志；找不到才补跑这一条连续链。当前只能接受入口实现，不能按摘要接受运行闭环。设备用词保持“模拟器”。

### A. 先修确定的命令与反例时序问题

1. **发布不等于执行。** `transport/src/ohos_transport.cj` 的 `publishGateCommand` 使用单槽命令；探针连续发送 ARM、SIM_RETIRED、SIM_CREATED 只拿 `PUBLISHED`，没有等待各自 ID 的结果。原始 `surface_lifecycle_raw.json` 实有 `RESULT_ID 11 / RESULT sim_created=-2`，随后仍 PASS。先在公共探针 helper 中按本次 PUBLISHED ID 等精确 RESULT_ID，核对 KIND、OP 和具体操作成功码；超过/错配 ID、未知操作、负返回都作为失败，不读取“最新任意结果”替代自己的结果。单执行者串行握手足以解决的问题不必扩成生产任务队列。
2. **释放命令实际不存在。** C5/C8 调用 `GATE_FLUSH_HOLD_RELEASE`，当前注册/派发未接通，原始回包是 `verify_unknown_op`。复用已接线且会调用 flush release 的 GATE_CLEAR，或完整接通专用释放操作；两者都要验证本命令实际执行。停止后 owner 不再消费命令时，释放控制须仍有可证明的通路，不能依靠被关闭 listener 或停止中的 owner 来解除自己。
3. **C2/C2b 缺真正的 held 中退役。** 当前退役/创建发生在触发 create 之前，读取见证后只有 CLEAR；即使读到 holding，也未验证“create 前/返回后被退役”。先按确认过的身份准备需要新建 surface 的代 G、武装对应阶段、触发帧并确认 G 的 held，再退役 G，放行并检查 G 的真实结算/资源，新代另行验证。每个阶段记录本实例、代际、请求/票与闸门身份，避免误用别轮日志。
4. 把 C2/C2b 阶段见证恢复为硬判据；最新 `surface_lifecycle_evidence.json` 两项 witness 均为空。没进入阶段属于该测试未成立，不能靠业务仍可读写判整项通过。计数/状态可以取代易丢日志，但必须绑定同一请求/代际，并证明先 held 后 retired 的顺序。用丢 ARM、错误命令和不到阶段的反例证明验证器真的会失败。
5. 闸门本身采用带 gate epoch 的谓词等待，公开同一实例/代际/任务的 `activeHeld`；当前无谓词 `wait_for` 可被共享通知或伪唤醒提前放行，累计计数不能证明仍被按住。arm/status/release 控制不能依赖被 destroy fence 阻塞的 owner；自动超时放行只用于清理，测试结果仍为失败。创建前 held→退役后不得再使用旧 window 调 Create/Flush；创建返回后 held→退役须拆掉刚返回资源而不晋升旧代，随后新代恢复。按此检查创建前许可/退役仲裁，不能预先认定只有探针缺陷。

### B. 无原生引用模式的安全边界必须闭合

`host/cjgui_host_bridge.cpp` 的 destroyed fence 在 2 秒超时后仅记 FAILED，随即正常返回；`ohos_renderer.cpp` 的 committing 闸门放行后仍可直接进入 `SurfaceFlush`，租约检查在调用后。无真实引用时，回调返回与继续使用该 native window 之间存在悬空使用风险；本次是源码路径确认，未声称已经复现崩溃。延长超时、禁止新准入或记录失败都不能消除既有调用。

实施约束：

- 首选能证明对象存活的真实引用/平台所有权契约。兼容 shim 只在明确的模拟器能力范围准入，核对已知库身份及相关符号来源；`dladdr` 失败的 `unresolved + rc=0` 不能成为 VerifiedNativeRef，后续代返回偏离已知模式也必须被检出。
- 无引用路径必须证明 destroyed 回调返回前所有该对象的平台使用已经完成，或在无法保证时从准入处拒绝这种运行模式。超时后的策略必须实际阻止继续访问，不能只把状态命名为失败；无限阻塞 UI 也不能算有界关闭完成。若要继续保留这种兼容模式，携上述两个源码路径和既有 Sol 裁决聚焦咨询 Astra，明确可实现的安全/退出契约后一次实施，其他独立项继续。
- 反例覆盖真实 XComponent destroy 与 create/committing 持有超过 fence 时限的交错；区分 SIM 代际退役与系统对象实际销毁。按同一对象记录最后平台调用、teardown ACK、回调返回及引用/许可，证明返回后零悬空使用。失败路径须有确定的拒绝/退出结果。

### C. 停止成功要读终态，不能只匹配标题

最新证据中 C8 是 `host closed; render_shutdown_status=99 shutdown_done=0`，但脚本只检查包含 `stop settled` 或 `host closed` 就 PASS。C6/C7 有同类弱判据。

改为读取同一 PID/appInstance 的 owner 实退、renderer 真完成与各自成功状态，关联 listener/在途票/ACK/引用收敛；关端口单独列为传输事实。超时/未完成必须失败并保留真实状态。测试释放、停止和新 boot 的依赖要明确，正常仍有在途调用时不得伪造可重开。已有这条 status=99/done=0 原证就是验证器的负对照，不需要再碰运气制造一次。

### 汇合与继续推进

先修 A 的命令身份/错误处理，取得可信的生命周期控制；B 的安全契约与其根因咨询同步进行。等待期间继续第六次复核 C/D/E 中不依赖运行安全的公共文字接线、消费者和断言实现，保持必要返工与通用能力一起交付。安全路径可运行后集中验证 A/B/C，补齐同进程重开原证，再按实际修改刷新相关 normal/verify 与独立消费者证据。报告 7 新增输入、裁剪和消费者结果保留，但不以其自报 PASS 覆盖尚未复核的原判据。

本次无需新增报告文件；在报告 7 更正结论、保存原始失败并链接修复后的运行记录，最后集中给实现变化、真实终态和剩余项。禁止把必需见证改成 note 后称为收口。

<a id="review6-current-package"></a>
## 第六次指导复核与接续（2026-09-26，优先于旧收口表述）

**结论：选区高亮这一项接受，A–E 整包继续进行。** 本次指导只读源码、实际 SDK 头文件、原始日志和归档截图，未重跑构建、测试或模拟器。下列均为原任务欠项的具体化，继续沿用后文完整范围。

保留本轮成果：选区变化后显式请求重绘、`[0,4)` 与截图中的高亮对应、失焦结算及 owner 读回；T4 已增加真实公开 owner 断言，T0–T6 有通过日志；部分原事务/ACK/传输反例、裁剪几何和含空格源码目录构建证据成立。人工操作的对象是鸿蒙模拟器；这是人工输入证据，但不是物理鸿蒙设备验收。`ime commit len=16` 和含 emoji 文本不能单独证明系统组合态提交/取消。

### 1. 先查明 native 引用契约，接回应用真正停止

- `host/cjgui_host_bridge.cpp` 当前以 `NativeObjectReference rc>=0` 发布 active；本机 SDK `native_window/external_window.h` 明确仅 `0` 成功。归还路径仍仅认 `rc==0`。`run/e_consumer/xcomponent_pressure_evidence.txt` 第 10 次卸载留有 `unrefs=0 pending=10`。目前能判定的是**成功解释和收敛证据不成立**，还不能从这些计数单独断言真实内存泄漏，也不能称为已证实的模拟器兼容。
- 先做最小引用/归还复现：固定 SDK/镜像/HAP，核对预处理后的函数声明、实际链接和装载库/符号及调用 ABI，记录创建/引用/退役/归还的原始返回值、线程和对象身份。区分真实错误码、错误符号/签名、镜像实现偏差与记账错误。依据 SDK 对非零失败关闭准入；若运行环境确有 ABI 偏差，取得可验证根因后再决定窄平台适配，不能单靠数值正负放宽。
- 这是 FFI/生命周期问题，携以上证据聚焦咨询 Sol，结构契约未定再交 Astra。引用成功、active 发布、许可取得、teardown 完成、UI 线程归还依序发生；正/负非零返回分别建立拒绝反例。真实卸载后的旧代引用与许可必须归零，仍挂载的新代基线单列；结束整个实例后全部归零。
- A3 验收读取同一 `appInstance` 的停止事实：owner 实退并 join、renderer 退出、listener/连接/票据/ACK/引用收敛，再在**同一进程** boot 新实例。当前 L2 的 `aa force-stop/start` 只证明新进程能启动；当前 L1 启动后等待 8 秒超过 4 秒首帧闸门，再 INCREMENT 得到的是刷新 Pending，不能作为 StartingPending 停止证据。改为观察真实启动阶段/原票身份后发一次 close，放行后自动收敛；启动失败链必须归档失败→清理→重试全段，现有 `a3_failfirst` 两行启动日志不足。

### 2. 补原事务/Surface 判别矩阵，与文字能力交错推进

沿用已有 M1–M5 有效结果，补交互投影 Pending 双终态、等待期滚动/resize/资源请求、独立 focus/回滚异常及逐票身份/收敛。计数增加和业务仍可用不能替代旧票恰好结算、新请求不丢失。

Surface 探针 C5 当前与 C4 一样停在 `GATE_HOLD_ADMIT_8000`，未进入所称的不可取消提交；创建返回后、C7/C8 也欠实际执行。每种闸门先断言已进入该生产阶段，再触发退役/停止；缺阶段见证即失败。最终准入前取消与 Flush 已在途保留引用是两个不同反例，不能用传输 Executing 替代。真实 CYCLE 已发生，保留其原证；重跑只针对引用修复及必要覆盖，并完整保存至少 10 轮和最终收敛。

### 3. 把公共文字代理身份接到真实回调，补成功接续

- 注册表已有挂载对象，但 `Index.ets` 的 onChange/submit/blur 在**事件到达时**重新取 `currentMount()`，selection 读取当前 `imeCtx`。这尚未落实“回调携带创建时身份”：旧 A 回调若晚于 B 挂载，可能被重新标成 B。将事件闭包绑定真实代理挂载实例/代际，再由注册表校验；必要时按 mount key 重建代理组件。用“捕获 A 回调→切换 B→投递旧 A change/selection/blur→B 不变且仍可编辑”的反例覆盖真实适配接线，不能只手动向注册表传旧对象验证。
- 当前桥只传全文 preview/commit，没有系统 marked/preview 范围；核对实际 SDK 系统代理事件，传递可观察的组合范围、提交和取消。普通 change 不等于组合态。验证中间插入、选区替换/删除、emoji 边界、切字段、组合提交/取消，分别检查 draft、owner 和画面；取消不能把未提交组合文字写进 owner。
- `selection_probe_evidence.json` 仍有“非空选区”“替换后 owner 值”两个 FAIL。人工 `[0,4)` 补足了前者，高亮后失焦读回原值没有补足后者。保留失败原证，建立新的精确替换/删除读回。
- 主应用 name/alias 与独立消费者各自完成同实例人改→公开 owner 读→外部改→显示→旧输入拒绝→新上下文人续写→精确读回。T0–T6 与单独外部写入不能拼成未运行过的连续链。自动化能完成的先做，确需系统组合人工操作时再集中核验。

### 4. 修复裁剪验证的假绿，并按阶段计时

`verify_clipping_probe.py` 找到背景色带即 `pixel_ok=True`，即便 `text_px=0` 也可通过；普通增减按钮和空白区域点击不证明裁剪边界命中。使用同一个跨界文字/按钮夹具，断言可见区有目标像素、被裁部分/空交集无目标像素，界内命中目标且 owner 前进、被裁部分不命中且 owner 不变；临时关闭裁剪/错误命中负控必须失败。圆角命中按已声明契约明确断言，不能仅记录观察代替判据。

现有响应 JSON 仅 3 次 round-trip 汇总，撤回“同请求单调分段”说法。在普通触摸、连续输入、外部请求三条正常路径分别关联请求/事件身份，保存单调时间戳与 input→owner→accepted/submit 原始样本，往返耗时另列；字段无新场景时标明实际投影接受边界。区分冷/热与负载，采样足以支撑所报告分位数；先定位热点再优化。补停止后的队列/资源/重建/提交/唤醒收敛。

### 5. 完成真正独立消费者，最后统一 normal/verify 来源

当前 `labs/ohos consumer space/app_src` 只改设置示例的 resourceType 与 name 空值规则，仍是 count/enabled/name/alias；没有报告所称 label。它证明含空格源码替换可构建，未证明不同字段结构与独立应用交付。

复用公共宿主/代理/构建入口，补一个小型不同领域消费者（例如目标温度、节能开关、允许空值备注），具备独立应用身份和输出目录。应用自己注册字段/规则，公共脚本不再要求设置计数示例的私有包名接线；无需另造协议。该消费者实际运行第 3 项连续链，保留两端点互不串写证据。

当前 selection_redraw_fix 是 verify-transport，HAP `89c542a9…b01a`；关键输入与当前副本相符。最新归档 normal_v5 是旧输入，不能覆盖本轮宿主/渲染器/文字代理修改。生产修复汇合后冻结源码/依赖，分别构建运行最终 normal 与 verify，normal 验证接缝不可用；本包原证按对应 HAP/实例保留，共享修改做相关 macOS 回归，避免无关全量重跑。

### 执行顺序与报告

先查第 1 项实际引用契约；其咨询/编译期间推进不依赖它的第 3 项身份接线、第 4 项验证器和第 5 项消费者准备。生命周期安全判据恢复后集中跑相关 HAP，再汇合输入/绘制/消费链。维持现有 Laya 与顾问规则；不新开治理台账，每个实质修复只记根因、差异和原始证据位置，整包集中报告。完成不了的项按具体缺口保留，不能把“能启动”“一项高亮可见”扩展为整包完成。

## 一、项目背景与目标

工作目录：`/Users/jiangxuanyang/Desktop/cangjie`。

CJGUI 是仓颉核心、高性能自绘 GUI 框架。人和外部智能系统共同读取、修改同一份真实应用内容；支持开发者手写、AI 生成和混合界面，共同字段、动作及业务规则单一定义。

macOS 已有实现。Pharos Mark 编辑器在 `/Users/jiangxuanyang/Desktop/Pharos Mark` 并行开发。你负责框架鸿蒙后端，不承担本包范围外的编辑器移植。

用户已确定路线：**仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制后端**。

- 仓颉负责组件、布局、场景、业务 owner、共同操作及授权/版本规则。
- ArkTS 负责官方装载入口、应用生命周期、XComponent 挂载和必要系统输入代理。
- 原生后端负责平台事件转换、surface、文字测量绘制、资源和提交。
- 普通应用通过框架公共入口与模板消费，业务主要用仓颉编写。

本包目标是同一套 CJGUI 核心在正常鸿蒙 HAP 中可靠完成：

**自绘显示 → 人操作 → owner 修改 → 画面更新 → 外部读取/授权修改 → 人继续编辑。**

同时交付延迟提交、surface 退役、应用关闭重启、公共文字代理与独立消费者。当前设备是鸿蒙模拟器，证据区分模拟器/物理真机、工具输入/人工输入、场景接受/提交/实际呈现。

## 二、开工读取和时间顺序

默认只读 [AGENTS.md](../../AGENTS.md)、[当前方向与状态](../../runtime/cjgui/ACTIVE_DIRECTION.md)、本文件「第九次指导复核」及[报告 7 页首当前复核](2026-09-26-harmonyos-execution-report-7.md#review9-evidence-scope)，随后直接核对相关源码与指定 Astra 答复。接续 C/D/E 时按对应项读取第六次复核与下文判据；公共消费查[鸿蒙入口说明](../../runtime/cjgui/platforms/ohos/README.md)。旧报告、阶段历史仅在需要原证时定位读取，不从头通读。

首次修改仓颉前必须读 `/Users/jiangxuanyang/.agents/skills/cangjie-coding/SKILL.md`，按需通过其检索工具确认语法、标准库、FFI 和工具链用法。鸿蒙 API 先核对实际 SDK 头文件/示例，必要时查对应版本官方文档。

已有关键顾问方案：

- [原票据与待决事务](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/rework3/pending-transaction/answer.md)。
- [Surface 许可与应用停止](../../labs/ohos_cangjie_smoke/artifacts/cjgui-backend/consultations/rework3/surface-stop/answer.md)。

架构有疑问时再按主题读取 [项目方向](../core/GUI_PROJECT_DIRECTION.md)、[架构契约](../core/AI_NATIVE_UI_SEMANTICS.md)、[设计导航](DESIGN_INTENT_INDEX.md)。无需通读全部历史 plans。

**时间顺序须正确：**第五次指导复核提出的问题，部分已经由第五轮执行实现。第五轮报告是执行自报，尚非整包验收。平台 README 和旧报告有滞后描述。结合 ACTIVE、最新源码和原始证据确认实际进度，保留已完成成果，不照旧文重复派工。早期“系统文字留待后续”的范围已被当前 C 项扩展。

## 三、交接基线与入口

以下是交接时第五轮自报基线，开工有界核对；后续新进展以实际证据和 ACTIVE 为准：

- 共享核心 → OHOS snapshot → 消费目录的来源同步。
- `startWithOutcome` 的 Ready / AcceptedPending / Failed，以及 StartingPending 持续泵送。
- 原票据 native 终态、核心收尾、ACK 完成分离。
- 传输关闭后同进程重开、旧 socket 半帧拒绝、Executing 票恰好一次。
- 严格回包解析、超时负控、启动 PID/日志绑定。
- 部分依赖闭包负控、`CJGUI_APP_SRC` 参数化、含空格清单枚举。

整包尚未验收，主要欠项：A 的实际 HAP 延迟提交矩阵、Surface 全使用期许可和真正应用重启；C 的公共文字代理与成功续写；D 的裁剪/命中与响应数据；E 的独立消费及最终同源交付。

下列路径相对工作目录：

| 路径 | 用途 |
| --- | --- |
| `runtime/cjgui/src/` | 共享仓颉核心 |
| `runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp` | 绘制后端 |
| `runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp` | 宿主桥 |
| `runtime/cjgui/platforms/ohos/snapshot/` | 构建快照 |
| `runtime/cjgui/platforms/ohos/scripts/` | 公共构建、同步和验证入口 |
| `labs/ohos_cjgui_app/` | 当前 HAP 消费工程 |
| `labs/ohos_cangjie_smoke/artifacts/cjgui-backend/` | 原始证据和咨询 |

平台快照由共享源码和明确适配产生，来源和转换可重放；共享修复回到框架源，不能只改一次性消费副本。

## 四、A：提交事务、Surface 存活与真正停止

### A0 同源构建与 ABI

核对共享源码 → 平台快照 → 消费工程 → 本次 HAP → 本次运行实例。定向同步并保留 Pharos 并行修改，确认未漏新的共享修复。

`FrameObservation` 旧 32/40 字节错配已有修复。继续核对大小、alignment、字段 offset、嵌套 receipt、native 写入边界、尾部 canary。优先归档已有原始结果和对应库身份；证据缺失或相关实现变化时再跑针对性验证。两个 C 头相同不能单独证明跨语言 ABI 正确。

### A1 实际 HAP 中的原事务矩阵

复用第五轮 StartingPending 和三段结算实现，完成测试变体应用内控制入口，联动 renderer `--test-gates`：

1. 首帧、完整刷新、交互投影分别 Pending→Accepted / Rejected。
2. 等待期间 owner 改值、滚动、resize、资源请求继续发生。
3. 重复 query/ACK、第一次 ACK 失败后恢复。
4. 一次 close 请求，放行后自动收敛关闭。
5. participant/focus 接受回调异常、回滚异常。
6. StartingPending 期间停止及失败收敛。

逐票验收：原身份、候选和持有保持，不重建原候选或重复推进帧号；旧结算只消费原请求，新请求保留并最终推进；native 终态、核心接受/回滚、ACK 分别可观察。Accepted 后异常进入明确的终止收敛路径，原票可追踪、接受回调不重跑；关闭后不恢复焦点或重挂代理；最终票据、候选资源和引用收敛。

测试闸门只控制时序或注入显式失败，结果由生产逻辑产生。正常启动和单元测试不能替代以上实际 HAP 路径。

### A2 SurfaceRecord 与全使用期许可

按已有 Sol 方案实施。每代完整身份包含 `appInstance/sessionToken/componentInstance/surfaceGeneration/geometryRevision`。

宿主串行取得 native window 引用，成功后才发布 active 记录。渲染线程同一临界区核对身份和状态并取得许可，覆盖创建、绘制、Flush、缓存 surface、redraw、teardown 的整个使用期。

退役时，UI 回调关闭新许可、标退役、投递清理并及时返回；渲染线程结束真实使用、拆除 surface、归还许可，再通知宿主串行归还 native 引用。超时保持未完成状态和必要资源持有，不能按等待时长推导安全释放。

同尺寸、同组件 ID、同指针地址不能证明同一代。`busyGeneration` 局部窗口不能代替完整存活判据。回调缺少身份时，依据 SDK 实际顺序或可验证静默屏障解决指针复用。

八类反例完整覆盖：

1. 取得许可后、创建前，销毁并同尺寸重建。
2. 创建调用前和返回后分别暂停，期间销毁重建。
3. 取得 canvas 后、绘制中暂停，期间销毁重建。
4. 最终提交准入前暂停，旧代取消后不得 Flush。
5. 已进入不可取消提交后暂停，旧引用持续持有；返回后按旧代实际结果结算，不晋升新代。
6. 空闲状态真实 `stop→await→boot`。
7. queued 状态真实 `stop→await→boot`。
8. renderer committing 状态真实 `stop→await→boot`。

记录完整身份、线程、许可/引用配对、Flush 返回值、accepted/帧号/命中身份与最终收敛。Flush 包装点阻塞标为受控模拟，并补真实 XComponent、实际平台 Flush 生命周期验证。

### A3 本实例真正关闭后重启

Stopped 对同一个 appInstance 同时确认：停止接单；仓颉 owner 实退；listener/client、连接、队列和在途票据收敛；原窗口事务及 ACK 收尾；renderer teardown 和线程退出；Surface 许可和 native 引用归还。

依实际执行结构采用可 join 的 owner 线程，或仓颉 task 及按实例退出确认。引导线程 detach、全局 shutdownDone、新 listener 出现都不能替代完整判据。

覆盖 Starting / StartingPending / Running 时停止、启动失败清理后重试。Stopping 时启动明确拒绝，真正收敛后创建新实例，旧完成通知不得修改新实例。

Surface 临时卸载/重建与应用退出分流：重建保持原 owner 内容/版本，并恢复人和外部操作。

## 五、B：保留并接续传输成果

第五轮已有严格反例，先核对证据和变更范围，修改相关实现后复跑受影响部分。

- 每票独立身份、结果、阶段和有界绝对单调 deadline。
- EOF/reset/refused 与 timeout 明确区分。
- 同一旧 socket 在 stop 前发半帧，重开后补发仍不能进新 owner。
- Executing 票停止时保留真实终态，公开读回证明恰好一次。
- 控制协议严格校验 KIND/OP/END、重复字段、类型和必需字段。
- 原始帧、票据、旧新实例、HAP、PID 相互对应。

normal 与 verify 分别验收：normal 在符号、注册和行为上证明测试控制不可用；合法字段含 `PAUSE_CLAIM` 等字样仍正常进入 owner；verify 限定本轮验证者并在结束时释放闸门。

transport Executing 与 renderer Committing 分开记账。已有传输重开保留，整个应用重启按 A3 验收。

## 六、C：公共系统文字代理与成功接续

把 ArkTS TextInput 适配收进框架公共代理/模板，由 name、alias 及独立消费者的允许空值字段消费。

1. 每次挂载冻结 `app/session/context/editGeneration/mountGeneration`。change、submit、blur、迟到 focus 回调携带创建时身份，旧回调不能借新 imeCtx 修改另一字段。
2. 本地 preview 与 owner 接受值分开；异步候选冻结对应那次编辑的精确来源回执。
3. 消费明确的 `preservesActiveLocalText` 和事务身份。合法空串在显示、提交同步、重新聚焦三处一致，去掉由 `value.empty()` 推断延续的逻辑。
4. 接通实际 selection、marked/preview 范围和 UTF-16↔UTF-8。验证中间插入、选区删除/替换、emoji、切字段和适用的系统组合提交/取消。

每个领域的同实例链：人改 → 公开 owner 读回 → 外部授权改 → 界面显示 → 旧输入按契约拒绝 → 人取得新上下文继续编辑 → owner 精确读回内容/版本。旧输入拒绝之后必须证明合法新输入成功。native 缓冲和桥接返回值不替代 owner 事实。

普通输入、工具粘贴、系统 IME 组合态分别留证。已有 C-API 实验桩的问题不能直接证明 ArkTS 系统代理不可验；输入法范围限于系统服务集成。

## 七、D：绘制、命中与响应

真实 CJGUI 场景覆盖跨裁剪边界文字/按钮、空交集、圆角外点、resize 后几何和命中。每个夹具同时核对像素、命中目标、owner 实际变化。

生命周期接通后，验证 resize、前后台、surface 重建恢复；同进程至少 10 次重建/恢复循环和结束收敛。

普通触摸、连续文字输入、外部请求记录同请求身份、单调时钟、输入→owner、owner→场景接受/提交分段、样本数、工作量、冷/热条件。停止操作后记录重建/提交、队列、资源和线程唤醒，合理缓存基线单列；零提交不等于零唤醒。性能结论限定实际模拟器配置和负载，热点有归因后优化。

## 八、E：独立消费与最终同源交付

`CJGUI_APP_SRC` 参数化只是准备，继续完成真实消费：

- 含空格的独立目录、不同于设置/计数示例的字段结构、至少一个允许空值字段。
- 通过框架公共宿主、文字模板、构建入口接入，应用定义/身份/输出目录独立。
- 实际构建、安装、运行，并完成人→外部→人接续；UI-only 可以不启用外部传输。

构建验证器保持失败累计。损坏 ELF、缺真实 NEEDED、解析器失败均拒绝；合法空 NEEDED 和有来源的 SDK 系统库保留。启动 marker 与本次实例/PID/HAP/日志区间绑定，旧日志不能满足本次运行；含空格路径安全逐项枚举。

normal 和 verify 分别冻结源码输入、工具链、依赖、HAP 哈希、安装/运行身份和原始证据。共享 ABI、启动/结算/输入改变做针对性 macOS 回归，补同源 name/alias 读写、拒绝与窗口反馈。截图、读回、性能对应明确产物版本。

## 九、Laya 与 Codex 顾问

### Laya 实际参与

用户要求实际使用 Laya 做开工判断、新失败族/方案分歧排序和整包交付核对。相同事实不重复调用，最终结论仍由源码和实验决定。

本机已知入口（先核实当前状态）：

- `GET http://127.0.0.1:8000/health`
- `POST http://127.0.0.1:8000/v1/systemone`
- 服务 `/Users/jiangxuanyang/Desktop/Kimi_Agent_AI 自动化开发思路/laya-lab/serve_local.py`，同目录 `.venv`。

请求示例：

```json
{
  "state": "简短列出已证事实、未证假设与当前问题",
  "questions": {
    "first_check": {
      "type": "choice",
      "instructions": "选择最能区分当前假设的下一检查",
      "criteria": {
        "lifetime": "检查实例、Surface 许可与退役",
        "transaction": "检查原票结算与核心接受",
        "input": "检查输入身份与 owner 结果",
        "insufficient": "信息不足"
      }
    }
  }
}
```

请求写入证据目录 JSON 文件，通过 `curl --fail --silent --show-error --max-time 20` 和 `--data-binary @文件` 调用。核对 HTTP、响应结构、choice 属于选项及概率合法，保存原始答复和采纳理由。调用失败如实记录，仍推进独立工作及必要顾问咨询。

服务不可用时有界检查已有安装。恢复服务前核对准确进程归属，保留身份不明的占用者；具体启动/恢复约束见阶段任务页。Laya 不进入 HAP 运行依赖。

### 聚焦只读咨询

- 架构、算法、跨平台公共契约、状态归属：`gpt-6-astra`。
- 既定契约内的复杂技术、ABI/FFI、线程、平台生命周期：`gpt-6-sol`。
- 按用户要求使用次高思考档；已有任务配置为 `max`，调用前核对本机实际支持情况。

先读并落实已有两份答复。换工具不要求重做历史咨询，只对新证据、未明契约或方案矛盾发聚焦问题。

下面的 `<本次问题目录>` 需替换为实际目录，先写 request.md，再按当前 CLI 帮助核对参数：

```bash
codex -a never exec -C /Users/jiangxuanyang/Desktop/cangjie \
  -s read-only -m gpt-6-sol -c 'model_reasoning_effort="max"' \
  --json -o <本次问题目录>/answer.md \
  - < <本次问题目录>/request.md \
  > <本次问题目录>/events.jsonl \
  2> <本次问题目录>/stderr.log
```

架构问题换成 `gpt-6-astra`。提供精确复现、预期/实际、必要源码、历次假设及原始结果，要求可区分检查、方案和验收标准。保存退出码和会话 ID，有新证据的追问复用会话。顾问只读，答复不是运行证据。

普通问题两次实质修复无进展即合并咨询；并发/生命周期/公共契约不明确时提前咨询，第一次实质修复失败后及时升级。同一旧问题跨轮累计三次修复仍失败交指导，最迟第四次停止盲试；首次咨询加一次有新证据追问仍无可靠方案，整理问题交指导，独立工作继续。

## 十、时间利用、依赖与并行约束

**尽量不要空等，最大化有效推进时间。** 该要求同时适用于编译、安装、验证脚本、Codex 咨询、子代理和其他进程：

1. 发起耗时工作时，记录进程/任务身份、输入版本、输出位置和它阻塞的具体项；在工具支持时异步执行并保留可回收的句柄。选择本包内另一项确实不依赖该结果的工作立即推进。
2. 等待编译时，可以整理已有原始证据、分析另一个不相关问题、准备独立消费者和后续反例，或实现不在本次构建输入/产物写集中的独立部分。**正在被编译读取的源码和资源保持稳定**；若必须修改，先等构建完成或使用已明确隔离的输入与输出，避免一次构建混入两个版本。
3. 等待 Codex/顾问时，暂停依赖其未定契约的实现，推进已明确方案的独立项。不得一面请求架构裁决，一面凭猜测把相同未定方案继续写入生产代码。
4. 并行只用于写集、构建产物、设备和桌面资源确实独立的工作。同一个 cjpm target 的 build/test 串行；同一模拟器的安装、卸载、重启和相关探针由主执行者协调；桌面同一时刻只有一个操作者。避免 CPU/内存争抢影响正在采集的性能数据。
5. 收到完成或阻塞通知后，及时核对退出状态与结果，接回被解除阻塞的任务。避免为了填满等待时间启动无人收尾的后台进程、重复咨询或整套重测。
6. **客观必须等待时就等待**：例如剩余工作都依赖唯一未定契约、当前构建必须冻结输入、设备被依赖验证占用、共享资源冲突，或只剩该运行结果即可收口。简记具体原因，使用有界等待/完成通知，避免频繁轮询与反复读相同日志。
7. 独立且必要的工作做完即可等待；不为保持忙碌添加无关任务、重复审核或扩大阶段。衡量的是完整交付和可靠证据，不是进程数量。

开工检查 git status 和并行写集，复用现有 SDK、模拟器与公共脚本。源码按明确写集修改，OHOS/macOS 构建目录分开。必要返工与 C/D/E 新能力交错推进，依赖修好并通过针对性反例后直接接续，阶段末集中汇合。

在原目录保留并行修改；本包不包含 stage/commit/push、切分支或恢复旧任务/自动化。优先 hdc 驱动模拟器；需要桌面时沿用授权、保护用户实例/数据/剪贴板。锁屏仅暂停依赖桌面的部分。自有临时实例按准确身份复用与清理，保留原始日志。

## 十一、状态、验收与收口

当前状态只维护 [ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md)，保留 Pharos 并行状态。详细执行记录和证据留在现有阶段页及对应报告，平台 README 修正与最终事实冲突的描述。本文件为工具交接入口，不逐轮堆积进度。

验证按变更风险选择。真实缺陷先建立可区分反例再修复；没有新改动或证据疑点时沿用适用基线。共享 target 串行构建/测试，完成相关检查与 `git diff --check`。

最终集中报告：

1. A–E 实际交付和精确剩余项。
2. 关键根因、修复前后反例。
3. 共享源码→HAP 来源与运行身份。
4. 实际 HAP 提交、Surface、应用停止/重启证据。
5. 成功的人→外部→人文字接续。
6. 独立消费者、macOS 对应回归、性能原始数据。
7. Laya/顾问实际参与和落实结果。

分别标记源码、针对性测试、受控注入、正常应用、模拟器工具输入、真实系统 IME、物理真机及独立消费。缺测试入口、未接消费者、未实现的生命周期仍是本包工作，不能改称环境阻塞或以正常启动/局部绿色代替整包完成。

**现在开始：读取当前依据，核对第五轮之后的源码和证据变化，简要说明执行顺序及并行写集，然后直接推进整个工作包。支持目标模式的工具可持续接续该目标；具体未完成项如实保留。**
