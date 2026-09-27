# CJGUI 鸿蒙后端：无上下文执行工具交接

更新日期：2026-09-27。用户已授权接续实施。本文件将当前整包任务整理为新工具可直接执行的交接说明，不另立阶段或维护第二份进度账。唯一当前状态仍见 [ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md)，详细历史和原始判据见[阶段任务页](2026-09-25-harmonyos-backend-first-chain-prompt.md#review5-current-package)。

**执行要求：必要返工与新框架能力一起推进，持续完成整个工作包。等待编译、Codex 咨询、子代理或其他进程时，优先推进真实独立、尚未阻塞的任务；客观依赖或资源互斥使其他工作无法安全推进时，才等待。** 具体操作规则见第十节。

<a id="review9-current-package"></a>
## 第九次指导复核：统一资源生命周期，完成当前可达项（2026-09-27）

**当前结论：**第九次 A–E、接续入口、TCP 归属返工、[系统输入消费包](#h-input-consumption-next)及[运行时生成式界面双消费者包](#h-generated-consumption-next)按各自证据范围收口；真实引用、绘制、输入接续、同 PID 重开及两款 normal HAP 的生成控件消费已在华为模拟器验证。当前 SDK/镜像/输入法组合的 marked/cancel 回调仍待版本化对照。下一包接续[共享图片资源与鸿蒙实际绘制](#h-image-resource-next)；下方既有结果与历史 A–E 用作复用依据，按新改动影响验证。

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
### H 线下一包：共享图片资源与鸿蒙实际绘制（2026-09-27）

**目标与实际缺口。** 执行对象鸿蒙 H 线，目录 `/Users/jiangxuanyang/Desktop/cangjie`。现在两领域已能消费生成字段和动作，但 `platforms/ohos/host/ohos_renderer.cpp` 的 `set_composable_scene_node` 仍拒绝图片节点，`prepare_composable_image_resource` 与状态查询仍直接返回错误，故正常应用不能复用公共图片能力。优先补共享资源的实际平台消费；更复杂效果、滑动/长列表等后续按实需接续。F 正在做 PNG 剪贴板/拖放的通用交换，H 本包做声明图片到鸿蒙显示，两者复用相同资源身份，互不等待。E 的编辑器插图与持久化仍归产品。

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
