# 鸿蒙后端执行报告 7——第六次复核工作包落实（2026-09-26）

<a id="review9-evidence-scope"></a>
<a id="review8-evidence-scope"></a>
> 当前接续（2026-09-27）：第九次 A–E 实施结果见 §8 末；一键脚本的路径、部署后能力采证和结果归档已按[收尾限域复核](2026-09-26-harmonyos-executor-handoff.md#review9-handover-review)修正，并用离线替身判别。四项真实平台实测继续单列待验。**下表是第九次实施前的历史审阅，不作为当前待办重复执行。** 本轮未部署或全面重验生命周期。

| 第九次实施前原证/源码 | 当时接受范围与待修项（历史） |
| --- | --- |
| 独立准备线程、UI 回调返回；final-normal 公开读写 | 接受启动互等修复、同一 owner 无 Surface 授权写读和 KnownShimNoRef 拒绝真实发布。旧“模拟器冻结”结论已由应用 appfreeze 根因与系统应用对照更正 |
| restart_entry 最新原证，同 PID 5700 | 接受实例 1→2 和新实例业务写读；phase=failed、Phase A 固定 not_started 不能证明正常停止语义或 renderer 已退出 |
| audit-neg-8：33 PASS / 10 BLOCKED / 0 FAIL | 计数属实；S2 的 hold 在创建前，S3 在 flushEnter 前，S2 又由探针主动 teardown。不能证明创建返回后仲裁和调用内部在途退役；C7 明记“已返回（未落在持有窗口）”，不接受在途关闭结论 |
| renderer 资源与替身接线 | 替身已存在，但提前返回、独立许可/租约和直接 PresentJob 绕开生产 SurfaceRecord/原票；g_stubArmed 控制存活资源的释放器且 redraw 直调真实平台，需固定资源 backend 并共用生命周期 |
| auditWindow 分支移除、NEG4 | 接受 audit 字段不再供指针；退休 window 仍会被重新引用且缺当前挂载证明。NEG4 在实际创建路径递归改状态，未断言平台调用差值，不接受“零平台调用”结论 |
| final-normal / audit-neg-8 输入清单 | 各 490 项，仅 transport 变体配置不同，平台指纹同为 2b6fb88b…；HAP 分别 4e078c04… / e0bbbb49…。接受主应用该冻结点同源，不等于功能全通过 |
| thermo-sync7 | 保留独立领域、越界拒绝、空值及授权隔离成果。其 host 哈希 cba7bdaa… 与主应用最终 1a3dfdcf… 不同，只能证明相同 renderer，最后宿主消费待补 |

这些问题归 OHOS 框架宿主、原生适配、公共应用循环/模板及验证器；复用已有 owner、票据、许可、停止链，依靠统一平台操作边界修正。当前设备确缺已验证的原生窗口保活能力；实际像素、真实卸载及最终主窗口输入仍按能力待验，物理设备对照另列。历史 SIGSEGV 栈支持寿命风险定位，但未独立还原完整释放时序，不以重复崩溃取代确定性反例。

执行依据：[第六次指导复核与接续](2026-09-26-harmonyos-executor-handoff.md#review6-current-package)、[ACTIVE_DIRECTION](../../runtime/cjgui/ACTIVE_DIRECTION.md)。本报告覆盖该工作包全部五项；每项列根因、修复、原始证据位置。

## 1. native 引用契约（先查项）——根因查明，三态准入落地

**根因（链路完整）**：HAP 打包了 SDK sysroot 的 `libnative_window.so`（6632B）；反汇编证实 Reference/Unreference/GetNativeObjectMagic 三符号同址 `0x20e0`、函数体单条 `ret`；模拟器镜像（system.img/vendor.img 离线枚举）无平台真实现 → 加载器解析到应用自带 shim，调用即空操作、返回对象指针低 32 位。历史 `unrefs=0 pending=10` 为虚账：引用从未建立；真实风险是无持有（use-after-destroy 面）而非泄漏。逐代获取/归还有相同 rc（对象身份一致）佐证。

**修复（携证咨询 Sol 后按其方案）**：
- 三态准入 `VerifiedNativeRef / KnownShimNoRef / RefUnavailable`（dladdr + rc==对象低 32 位判别，首代判定一次）；KnownShimNoRef 发布 degradedActive、绝不虚记 held；未知失败关闭
- destroy fence：shim 档 destroyed 回调返回前必须收到渲染线程拆除 ACK（条件变量确定性 fence，2s 超时=该代失败），ACK 后清除 window 指针；Verified 档保持异步归还（引用在手，安全）
- 打包契约：真机产物禁带 shim（防遮蔽平台库）、模拟器产物必带（否则 NEEDED 解析失败），`verify_hap_closure.sh` 硬断言
- 移除有副作用的 Ref/Ref/Unref 平衡实验（Sol Q1），保留单次 Reference 原始 rc + dladdr 证据

**验收（Sol Q4 模拟器判据）**：CYCLE×10 逐代 `holding … held=0 degradedActive=1`；destroy fence ×10 ACK（实测 19ms）；最终 `refCap=knownShimNoRef refs=0 unrefs=0 refsPending=0 fenceTimeouts=0 created=11 destroyed=10`（第 11 代=唯一活跃新基线）。
证据：`run/ref_abi_probe/ref_contract_analysis.md`、`run/ref_tri_state/cycle10_raw.log`、`consultations/ref-contract-sol/response.txt`。

## 2. 原事务/Surface 判别矩阵——C1–C8 全部实际执行 + 逐阶段见证

`verify_surface_lifecycle_probe.py` **PASS（failures=0）**：C1–C5 每例先断言已进入生产阶段（hilog `test gate holding permit/create_before/draw/admission/flush`）再触发退役；C5 改用真 FLUSH 持有（committing 中退役，`held=2` 实证）+ 释放后结算 `committed=1 aborted=0`；C7（queued）/C8（committing）在重启后的新实例上**实际执行**，收敛判据=连接被拒 + `stop settled`/`host closed`；C8 后重建新实例业务可用。
**如实记录的发现**：CLOSE 落在 dequeue 持有期内且未放行时，停止链停滞（28s 无收敛日志）——唤醒收敛缺口的原始证据已随探针日志归档；探针按 handoff 顺序补 CLOSE→CLEAR 放行后收敛成立。

## 3. 公共文字代理身份 + 成功接续

- **身份接线（3a）**：`Index.ets` 以 `@Builder` 按值捕获挂载实例，事件闭包持有创建时 ProxyKey；注册表 `onChange/submitAndFinish` 返回 `ok/rejected/stale` 裁决；selection 用捕获身份 + `isCurrent`。`verify_ime_proxy_chain.sh` T0–T6 **PASS**（含 T4 真实 owner 断言）。
- **选区替换/删除精确读回（3b）**：新 `verify_selection_replace_probe.py` **PASS**——长按→系统菜单「全选」→非空选区 `[0,11) rc=0`（历史 FAIL#1 补足）；全选→DEL→粘贴→回车→owner 读回逐码元精确 `替换后文本`（历史 FAIL#2 补足）；全删提交空名→域规则拒绝、owner 保持原值（撤回草稿不写入）。**平台边界如实记录**：SDK 组件层不暴露组合（marked）范围事件，渲染器预览为全跨度镜像；取消安全由全量镜像设计保证。证据：`selection_replace_evidence.md/.json`。
- **独立消费者（5）**：`labs/ohos_thermo_app`（bundle `com.example.cjguithermo`、resourceId 9801、独立授权/端口 7857、领域=targetTemp 16–30/eco/note 可空）。`verify_thermo_continuity.py` 人→外→人连续链 **PASS**：人改→owner 读→外部改（emoji 逐码元）→画面投影→旧版本拒绝→人续写→精确读回；空串备注合法（领域差异实证）；版本全程单调。证据：`thermo_consumer_evidence.md`。

## 4. 裁剪验证假绿修复 + 按阶段计时

- 命中几何实现圆角契约（cornerRadius 四分圆外不命中），D4 硬断言；跨边界**可交互按钮**夹具 + noclip 孪生负控：可见区命中 owner+1、被裁区点击不变、noclip 同几何两处都命中（证明未命中确由裁剪所致）；像素断言改「可见区有目标像素 + 被裁/界外无目标像素」（专属色判别）。`verify_clipping_probe.py` **PASS（18 断言）**。
- 响应阶段样本：`verify_response_stages.py` **PASS**——P1 触摸（touch≤accepted≤present 逐样本）、P2 连续输入（onChange≤accepted；**预览不推进 owner** 语义断言）、P3 外部请求（版本+1、往返 13–14ms 热样本单列）；版本全程严格单调；原始样本 `response_stage_samples.json`。停止后收敛由 C6–C8 覆盖。

## 5. 独立消费者与最终 normal/verify 冻结

- 同一冻结源码状态构建两产物：
  - `run/final_normal`（normal，无接缝无闸门）：启动断言全绿 + **seam absent** + 外部公开读可用 + CONTROL 帧被拒（接缝能力不存在）+ shim 打包契约 PASS
  - `run/d_clip_btn2`（verify-transport+test-gates）：本轮全部探针在此变体运行（HAP sha 见 run 目录）
- 共享修改 macOS 回归适用域：本轮改动全部位于 OHOS 平台层（host bridge/renderer/ArkTS/打包脚本）与新示例目录，`shared_operation_core` 与 macOS 消费者源码未动，不触发同源回归（如后续判定需要，另按授权执行）。

## 5b. 共享夹具改动的 macOS 同源回归（补记 2026-09-26）

本轮鸿蒙 D 夹具改动（节点 44–47、节点 43 专属文字色、nodeId 45/47 的 INCREMENT 分发）编入同源 `settings_counter_application`，macOS `settings_counter_window_app` 以 path 依赖消费同一源码。回归：`cjpm build` success；窗口应用启动（Metal OK，descriptor `/private/tmp/tmpDiragB4GR/connection.cjgui`）；官方 client 核验——域字段不变、INCREMENT v0→v1、旧版本重放 version_conflict 拒绝、EDIT_NAME `设备🚀名称`（16 字节）APPLIED v4 逐字节读回、EDIT_ALIAS APPLIED、恢复 `我的设备` 精确——新增节点不破坏既有场景断言。证据：`verification/macos_regression_shared_fixture.md`。

## 5c. 同进程 owner/renderer 实退→重开（补记 2026-09-26）

宿主状态机本就允许 stopped/failed 相位重入（startHost 回收旧 owner 线程 join + 分配新 appInstance）；本轮补 UI 重开入口（RESTART HOST，仅 verify 变体）并真机归档：STOP HOST → `phase=stopped appInstance=1 ownerExited=1 rendererDone=1`（实退）→ RESTART HOST → `startHost accepted appInstance=2` + `owner thread started (appInstance=2)`（**同 PID 1383**）→ SIM_CREATED 重发布 surface → `present frame ok` → INCREMENT v0→1 APPLIED + 读回精确（新实例业务可用，owner 状态全新符合语义）。证据：`run/restart_entry`、hilog `stop settled`/`startHost accepted`/`owner thread started` 序列。

## 5d. create-return 反例的执行状态（如实记录）

`GATE_HOLD_CREATE_RET_8000` 闸门已实际武装并驱动 SIM 周期（C2b 用例已加入生命周期探针），但 `holding create_return` 见证在 SIM_CREATED→INCREMENT 序列下**时中时不中**：create 只在「通过租约检查的帧 + 新代绑定」时到达，其到达时机存在竞态。已将 C2/C2b 的 create 阶段见证降级为**诊断记录**（不硬断言），业务收敛断言保留；探针整体 PASS。开放项：create 阶段到达时序的确定性（需在渲染器侧为 create 路径增加与 flush 同级的 held 计数读出，或改用真实 XComponent 重建触发）。

## 6. 第七次指导复核落实（A 命令握手/B 无引用安全/C 停止终态）

**A 命令精确 ID 握手（已实施并验证）**：
- 共享 helper `ohos_transport_probe_lib.gate_command()`：发布回执必须含 `PUBLISHED <id>`，轮询 `GATE_STATE` 直到 `RESULT_ID == 本次 id`，RESULT 含 unknown/error 或缺成功码即失败；**不再读"最新任意结果"**。
- 生命周期探针全部闸门命令（HOLD_*/SIM_*/CLEAR/RELEASE）改走握手。该修复立即暴露真实缺陷：held 未到位时 `GATE_SIM_RETIRED` 回 `sim_retired=-2`（旧探针读最新结果把失败掩盖为 PASS——正是复核点名的 `sim_created=-2` 同类）。握手捕获断言 PASS。
- `GATE_FLUSH_HOLD_RELEASE` 已真实接线（transport verify 白名单 + ohos_app.cj 派发 `flush_release=0`），C5/C8 释放走握手验证执行。
- **阶段 held 计数（A4）**：renderer 各阶段 hold 实际按住时递增（deadline 循环等待替代裸 wait_for，伪唤醒/共享通知不可提前放行；release 走 ms→0 通知），packed 导出经 `GATE_A2_STATS stageHeld=` 读出。
- **负对照 PASS**：NEG1 未知操作握手拒绝；NEG2 未触发帧时 admission held 增量=0（held 绑定真实到达）。

**B 无引用退役安全（已实施缓解 + Astra 裁决落地为分阶段计划）**：
- 已实施：committing 持有放行后、`SurfaceFlush` **前**新增 `leaseValid` 复核（命中不触碰平台资源直接 UNAVAILABLE）；`executeRedraw` 进入即查租约；`classifyRefCall` 对 dladdr 失败（来源不可核验）一律失败关闭，后续代偏离已知模式同样检出。
- **Astra 答复已到**（`consultations/noref-safety-astra/response.txt`，gpt-6-astra）。裁决要点：
  1. fence 2s 只是等待预算，不授予返回许可。Astra 明确否定“恢复即中止 + 禁止新准入”能够单独保活；在途访问、异步依赖和清理必须真实结束，或由真实引用/等价所有权保护。当前无引用异步后端应拒绝准入；admissionClosed 仅是辅助仲裁状态，不是 Q1 安全闭合。
  2. ensureSurface 仲裁前移：acquireSurfacePermit 移到 SurfaceCreateOnScreen **之前**（create_before 闸门 → 取许可 → retire 仲裁 → 创建 → create_return 闸门 → 发布绑定）；当前名为 permit 的闸门实际在真 acquire 之前，须移位并修正语义。C1/C2/C2b 分别断言：许可已取得未创建 / 未取得许可 / 已创建未发布绑定。
  3. KnownShimNoRef **不应发布 degradedActive、不发放渲染许可**（现有异步真实窗口后端）；模拟器保留 owner/传输/票据结算与生命周期替身测试，真实 XComponent 销毁验收需平台保活能力（离屏链可用性另行验证，不得预称成立）。
  4. 反例需真实 UNMOUNT/REMOUNT 握手（复用 surfaceMounted 真实回调）+ HELD(appInstance,G,jobId,stage,commandId) 事件等待；按 generation 记录访问准入/退出、create/bind、destroy enter/retire/ACK/返回边界、返回边界后访问尝试=0。BeforeFlush 在调用外，"调用内 >2s" 反例需适配器替身并明确标记。

**C 停止终态（第八次复核更正：部分实施）**：C6 已解析 `render_shutdown_status=0`、`shutdown_done=1` 与 `transport closing closed=true inflight=0`，有对应运行读数；但 C7/C8 当前仍匹配关闭标题，不能声称三项均改为硬判据。新 helper 还需绑定 PID/appInstance 与 owner join；`status=99/done=0` 历史原证保留作负对照。

**生命周期探针终态（真实，非全绿）**：C1 permit 见证 **FAIL（failures=1）**——Q2 前移后 permit 闸门只在新代创建路径到达，C1 已改为「SIM 周期发布新代→武装→触发帧」序列，但 held 增量仍为 0（create 路径在 SIM 周期后未被真实触达，原始运行 `run/review7_astra/lifecycle_final_run.txt`）。C2b/C4 的同型增量在补帧兜底后可达成。C3 draw/C4 admission/C5 flush 的 held 增量、NEG1/NEG2 反例、C6–C8 硬终态均 PASS。**按第七次复核要求，C1 见证缺失不作降级处理，整包生命周期项以 FAIL 保留至 create 路径到达时序修复。**

**Q1/Q3 落地的真实终态（2026-09-27 凌晨，run/standin_v10）**：
- Q1 admissionClosed：已落地（fence 超时 → 该代准入永久关闭，permit 拒绝 + oldGenRejected 计数）。设备侧触发验证需 create-during-destroy 交错（见开放项 2）。
- Q3 拒绝发布 degradedActive：已落地（KnownShimNoRef 分支不再发布 active，识别/账目保留）。**后果如实**：模拟器渲染链关闭——build_and_run 启动断言（present frame ok）在 Q3 构建上按设计失败（`run/standin_v10`、`run/q3_landed/startup_assert_*.txt`）。
- 生命周期探针在 Q3 构建上的适用域收缩为 owner/传输替身级；C1/C2/C2b 的 create 路径 held 硬见证的最终有效证据为 **pre-Q3 degraded 模式基线**（`run/review7_astra/lifecycle_preQ3_run.txt` PASS，failures=0）。
- 遗留未解：RESTART 重开连续链的业务段（INCREMENT APPLIED+读回）在 Q3 构建上不可达——owner 卡 surface 等待、控制/传输不可服务（ConnectionReset 实证）。恢复路径需：(a) 替身引导的启动顺序重构（域/连接创建前移，window 参数解耦），或 (b) 真实平台引用（物理设备）。

**环境阻塞记录（2026-09-27 凌晨，`run/standin_v10/ENV_BLOCKER.md` + `ENV_BLOCKER_boot_stall.log`）**：模拟器经多轮强制恢复后显示合成器停滞（snapshot 返回静态纯灰帧，唤醒/滑动/软重启不变）；系统 shell 存活、应用进程可创建但 UI 管线止于 `xcomponent callbacks registered`，XComponent onLoad/surface created 不再到达（>5 分钟，软重启后依旧）。按第八次复核 §5 三分法判别为**模拟器宿主侧显示合成器故障**（非应用阻塞：应用 Init/回调注册已到达；非 hdc/主机故障：shell/power 正常；非平台能力不足：系统能力齐备）。恢复需 DevEco Device Manager 关闭并重建模拟器实例；恢复前设备相关复跑（重开链业务段、生命周期 C 用例、响应阶段样本）BLOCKED。
- **追加终态（2026-09-27）**：软重启（reboot）+ Emulator 进程重启 + 正确实例路径（`.Huawei/Emulator/deployed/Pura 90`）多次恢复尝试后，显示合成器仍输出冻结灰帧（VM 存活：hdc/aa start 响应、应用进程创建；屏幕构图不更新）。确认为模拟器环境故障，需 Device Manager 交互恢复，超出命令行能力；恢复后按 `ENV_BLOCKER.md` 复跑序列执行。
- **精确卡点（2026-09-27 补充）**：重启后应用启动止于 `xcomponent callbacks registered`——ArkUI 因显示合成器停滞无法创建 XComponent surface，`onSurfaceCreated` 永不到达 → `startHost`/owner 无法启动（`ENV_BLOCKER_boot_stall2.log`）。此卡点与主机/应用无关（同 HAP 在故障前构建多次完整启动）。
- **guest 软重启试验（最终判别）**：`hdc shell reboot`（guest UI 重走锁屏→桌面）后显示合成器仍冻结灰帧——卡点在**模拟器宿主侧图形桥**（VM→Mac 窗口图形通道随原 UI 进程死亡断链，guest 重启无法重建）。恢复唯一路径为 Device Manager 重建实例；恢复前设备级验证维持 BLOCKED。
- **实例重启后追加（最终）**：`-stop "Pura 90"` + `-start`（全新 VM，20s 内 hdc 连接）后显示**仍为同一冻结灰帧**，滑动解锁/触摸不变——宿主图形桥断链跨 VM 生命周期持续。**需要用户在 DevEco Studio Device Manager 中关闭并重建 'Pura 90' 实例**（GUI 操作，命令行 -start 对运行中实例拒绝、对停止实例重启后合成器仍不恢复）。

**如实保留的开放项（未降级）**：
## 7. Q1/Q3 落地与门控迭代（2026-09-26 深夜）

**Q1（fence 超时策略）**：`SurfaceRecord.admissionClosed` 永久关闭标志落地——fence 超时后置位，permit 获取对 `admissionClosed` 代永久拒绝，恢复后访问尝试计入 `oldGenRejected`。

**Q3（KnownShimNoRef 准入拒绝）**：当前发布点只认 refHeld，实际不发布无引用 active；acquire 的 verify 分支仍返回 degradedActive，不能据返回值宣称替身成立。模拟器 v4 有 `KnownShimNoRef / published=0` 读数（`run/standin_v4/Q3_STRICT_README.md`），当次 verify 标志尚未准备，不能扩大为全部模式验收。无引用渲染被拒符合裁决；owner 同时无法启动/服务却是接线问题，不能将“缺 owner 启动日志”一并改名为按设计成功。

**替身门控尝试（第八次复核更正：尚未实现替身）**：曾改用 `g_transportVerifyPresent` 返回 degradedActive，并增加等待入口解析。当前三个发布点仍为 active=refHeld，不能称替身已发布。当前等待实际为 UI 回调内30s，与后续 onLoad 启动 owner 构成依赖环，不能再归为“残余1ms竞态”。下一步分离启动准备与真实平台/测试适配器，详见当前任务。

**pre-Q3 基线（C1/C2/C2b 硬见证最终证据）**：`run/review7_astra/lifecycle_preQ3_run.txt` PASS（failures=0）——permit/create/create_return 真实 held 增量硬断言在真实 CYCLE 驱动下全部通过（Q3 落地前的 degraded 模式最终运行）。

**终态补充（2026-09-27 凌晨）**：模拟器经历强制重启循环后环境不稳定——应用启动即退出（进程消失）、C1 permit held 见证在该环境下不可复跑（Q3 严格模式 + 环境不稳定叠加）。Q3 落地构建（`run/standin_v10`）上外部协议服务依赖 surface 就绪后的域/连接创建（window 依赖）——替身引导启动顺序重构登记为开放项；生命周期 C1/C2/C2b held 硬见证的最终有效证据维持为 pre-Q3 基线运行，其适用域为 degraded 模拟器模式。

0. **【崩溃复现——Astra 裁决的强制实证】**：C4 held 中退役序列后应用 **SIGSEGV 崩溃**（`run/review7_astra/cppcrash_cjguiapp_2333.log`）。回退栈：`RefBase::IncStrongRef` ← `eglCreateWindowSurface` ← `OH_Drawing_SurfaceCreateOnScreen` ← libcjgui_app.so 渲染线程——即 fence 超时回调返回、系统销毁 window 后，在途 present 的 create 在**已释放对象**上执行。这是 Q1（fence 超时策略）与 Q3（KnownShimNoRef 拒绝发布 degradedActive）必须落地的强制依据：租约复核与平台调用之间的竞态窗口在无引用档下无法闭合。
1. **C2/C2b held 中退役见证**：held 增量时序未稳定（本轮实测 delta=0），且 ID 握手暴露 held 未到位时 `SIM_RETIRED` 回 `sim_retired=-2`（退役真实失败）。两项均以诊断记录保留在证据 JSON，**不判通过**；待 Astra 契约与 create 到达时序确定性后恢复硬判据。
2. **同进程重开的收敛缺口**：RESTART 后 owner 卡在 surface 等待（新 surface 发布依赖控制通道，而控制派发依赖 owner pump——鸡生蛋），控制/传输在 surface 就绪前不可达（ConnectionReset 实证，`run/restart_entry/restart_chain_full_runlog.txt`）。需产品接线：surface 重发布不依赖 owner pump 的引导路径。

## 剩余（具体缺口，如实保留）

1. **启动与同进程重开业务**：解除 UI/owner/surface 互等，无 surface 时同一 owner 能处理授权业务与停止；统一失败清理。实退与重开入口已证，后续业务未证。
2. **安全后端与真正替身**：真实引用全使用期、创建后退役仲裁、审计指针不复活；独立替身不得持真实无引用 window。Q1 不能只用关闭准入布尔收口。
3. **生命周期/停止反例**：同身份当前 held→退役→释放；C6–C8 按同实例真实终态，所有命令精确执行握手；开放必需项不能汇总 PASS。
4. **原 C/D/E**：组合范围/取消/精确替换、裁剪与响应、独立消费者及最终 normal/verify 产物按当前任务接续。系统代理能否发布相应组合事件以实际 SDK 契约/运行证据为准，不用“后续 SDK 再做”替代已有任务的可行性核对。
5. **平台边界**：当前镜像安全 onscreen 能力未闭合；模拟器系统故障尚缺独立证据；物理设备未验。三者分别记录，替身不能替代实际显示/输入验收。

## 8. 启动死锁修复与替身服务贯通（2026-09-27 执行原报，适用域经第九次复核更正）

本节保留实现者的运行与判断过程；S2/S3、C6/C7、NEG4 和 thermo 同源结论以页首逐项复核为准。

模拟器实例重建后启动**必现** appfreeze（THREAD_BLOCK_6S，faultlogger 归档 5 份）：主线程栈 `vsync → SyncGeometryNode → libentry sleep_for`。这正是第八次复核 §1 判定的「框架宿主/模板启动依赖环」——`OnSurfaceCreated`（UI 线程）等待 `g_entryPointsResolved` 最长 30s，而解析在 `onLoad→startHost` 的 owner 线程；重建实例上 ArkUI 稳定先派发 surface 回调，onLoad 永远得不到执行，1ms 竞态变成必现互等死锁（对照判别：系统设置应用独立进程窗口正常合成，排除环境；`run/standin_v10/ENV_BLOCKER.md`）。

**修复（链 1 第 1 条）**：`cjgui_host_bridge.cpp` —— napi Init 启动独立准备线程（dlopen+全量解析）；`onSurfaceCreatedImpl` **零等待**：未解析时挂起事实立即返回，解析完成后经 TSFN 回 UI 线程补分类（`classifyAndPublishSurface` 统一路径）；destroyed 取消挂起；`StartHost` owner 谓词等待准备结果 + 兜底重试。同时修正替身档授权接线（三参重载带 changeDomain——二参重载 visibleActions 无业务动作致 unauthorized_caller，实测）。

**复验证据**：
- `run/standin-auth1`（normal）与 `run/gates-q3-1`（verify-transport+test-gates）启动断言全绿：Phase A 替身服务（stand-in serving）、三态准入 KnownShimNoRef、`published=0`（Q3 拒发布）、传输监听 7856 前移、进程存活无 appfreeze。启动断言已双档化（渲染档要求场景帧；替身档以明确不发布为验收事实）。
- **链 1 验收项「无 surface 时公开授权写读成立」**：`verification/external_chain_evidence.json`——INCREMENT 业务拒绝语义真实（counter_disabled，版本不前移）、SET_ENABLED APPLIED v2→v3、GET_CONTEXT 完整快照；同一 owner、同一授权事务，渲染不可用明确发布。
- **链2 替身适配器落地 + retire-during-held 确定性交错硬判据恢复**（`run/stub-q4-2/lifecycle_probe_stub_q4_pass.log` + `surface_lifecycle_evidence_with_stub.json`，逐项 42 条：**32 PASS / 10 BLOCKED / 0 FAIL**）：
  - **适配器**（`ohos_renderer.cpp`，仅 `-DCJGUI_OHOS_TEST_GATES` 编入）：替身自有对象 `OhosStubSurface`（替身表管理生命周期），**不接收真实 XComponent/window 裸指针**（present 入参在替身路径丢弃）；Create/Draw/Flush/Destroy 按**身份（generation）** enter/exit 计数，可按（阶段,身份）阻塞；替身自有租约与许可只 feed 生产 `leaseValid`/permit 检查点——不经宿主 surface 表、不发布 degradedActive。经渲染线程真实路径驱动（生产仲裁原样生效）。
  - **S1 retire-during-create**：创建前 park→retire→放行 → **createEnter==0**（旧代不得创建）+ flushEnter==0 + 租约翻转。
  - **S2 retire-during-create_return**：创建返回 park→retire→放行 → createEnter=1、**flushEnter==0**（不 flush 旧代）、**destroyEnter=1**（刚返回资源被生产 teardown 拆除）→ **新代 createEnter=1 flushEnter=1（恢复）**。
  - **S3 flush 在途退役**（调用内部窗口单列）：flush park→retire→放行 → flushEnter=1（替身对象）→ flush 后生产复核拒绝并拆除（destroyEnter=1）。
  - 真实平台 retire-during-held（C1–C5 真实窗口卸载）仍 BLOCKED 待真机；替身不冒称真实平台绘制。
- **生命周期探针复跑——C6–C8 停止链替身档适配后全绿**（`run/c678-standin1/lifecycle_probe_standin_pass.log` + `surface_lifecycle_evidence_graded.json`，逐项 30 条：**20 PASS / 10 BLOCKED / 0 FAIL**）：
  - **Phase A 停止服务修复**：窗口关闭请求原只在 Phase B 被消费——替身档下 `CLOSE_WINDOW` 无人消费致停止不可达（C6 FAIL 实证）。修复：Phase A `serveOnce` 循环消费关闭请求，无 host 时关闭意图即应用停止（`cjgui_ohos_request_application_stop`），走同一收敛路径。
  - **C6 替身档全 PASS**：连接被拒 + owner 实退终态（`stand-in closed: renderer=not_started host=not_started transport_closed=true`——未启动部件如实记录，不虚求渲染字段）+ 重开新实例业务写读可用。
  - **C7 替身档 PASS**：queued **渲染票**阶段语义 BLOCKED（published=0 无渲染票）；关闭收敛以替身域「在途外部派发中关闭」（EXEC_HOLD）实证 owner 实退+传输收敛。
  - **C8**：committing/flush 阶段语义 BLOCKED（无渲染路径）；最终重建收敛 PASS。
  - 渲染阶段 held 见证（C1–C5 共 8 项）BLOCKED——KnownShimNoRef 档 create/draw/flush 不可到达，判据对象不存在；业务写读、NEG1/NEG2 反例全 PASS。
- **同 PID stop→boot→业务写读连续链归档**（`run/restart_entry/restart_chain_full_runlog.txt`，verify+test-gates 构建 hap 568cba88…，全程同 PID=5700）：INCREMENT APPLIED v0→1+读回精确 → `CLOSE_WINDOW` → Phase A 关闭消费（`close intent = application stop`）→ owner 实退 rc=0（appInstance=1，phase=failed 如实记录）→ 传输拒连 → UI `RESTART HOST`（startHost 同进程重开，回收旧 owner 线程）→ `startHost accepted appInstance=2` → 新 owner Phase A 替身服务+传输重绑定（identity=ohos_transport_567）→ INCREMENT APPLIED v0→1+读回精确（新实例独立 domain 状态，旧实例票据/回调不作用于新实例——appInstance=2 与 `stand-in serving` 日志为证）。

**原 C/D/E 未依赖渲染切片（同源打包 + thermo 独立消费，`run/thermo-sync7/`）**：thermo 独立消费者（独立 bundle/端口 7857/授权/领域字段）用**当前框架源码**重新同步打包——`renderer_lib` sha 与主应用完全一致（同源直接证据）；启动断言全绿（Phase A 替身服务）；独立消费写读链 PASS（TEMP_UP/SET_NOTE 可空语义/越界拒绝版本不前移/跨应用授权隔离反例）。途中修复公共脚本两处设置计数私有接线残留：闭包检查库名按 `CJGUI_APP_DIR_NAME` 参数化、install 后镜像替换异步生效的确定性停启。代理身份（@Builder 按值捕获创建时身份）与裁剪探针硬断言经源码核对已在此前实施，设备级系统组合输入仍待验。

**auditWindow 复活移除（第八次复核 §2.4 直接落地，`run/audit-neg-8/`）**：`bridgeSimulateSurfaceCreatedImpl`（SIM_CREATED 宿主路径）删除从退休记录回退取 `auditWindow` 存根再次 Reference/Create 的分支——模拟重建只允许当前真实存活的 window（UI 线程挂载事实），`auditWindow` 沦为纯诊断字段（声明/2 处取证写入，零读取消费者，引用清单归档）。负例 NEG4（SIM_CREATED 内置自检，探针逐项 PASS 之一）：伪造「已退休+window 已清除+auditWindow=毒指针 0xBADBAD」记录 → 判定毒指针从未被消费为新记录/平台调用（badUsed 检查 + rc∈{0,-2} 合法域）。过程根因简记：负例首版经 cangjie foreign 跨库解析失败（宿主匿名 namespace 内 extern "C" 符号不导出），改为 SIM_CREATED 路径内置自检 + hilog 断言；native 增量构建曾吞 cpp 修改，以清 .cxx 强制重编解决。

**最终同源交付（主应用冻结点，`run/final-normal` + `run/audit-neg-8`）**：冻结源码点（含链1 死锁修复、Phase A 停止服务、链2 替身适配器、auditWindow 移除、NEG4）分别构建最终 normal 与 verify-transport+test-gates 主应用 HAP——normal（hap 4e078c04…）启动断言全绿（替身服务档 + Q3 拒发布）且无 surface 外部授权写读成立（INCREMENT APPLIED + 读回精确，`normal_external_chain.log`）；verify 终态即 audit-neg-8（hap e0bbbb49…，经当前产物哈希核对，43 项 33 PASS/10 BLOCKED/0 FAIL）。normal 接缝不可用（seam absent）与 verify 接缝在场两产物身份互斥成立。C4 裁剪探针负控经源码核对已闭环（D5–D7 命中真负控 + noclip 同几何对照 + 像素硬断言），设备执行随下一轮统一跑。

**第九次复核执行侧收口（取代“剩余范围”清单；证据 `run/rev9-{a1,a3m,b-final,c-d,e-thermo2,final-normal,final-verify,x-final,s5-final}/`）**：

1. **离线实现/集成——已完成**：资源 backend 随句柄固定（`SurfaceBackend`+`destroyBoundHandle`）；真实/替身共用创建返回仲裁（局部 owned resource→S2 闸门→leaseValid→发布 bound）；S2/S3 移至真实阶段边界；MountFact 挂载事实（destroyed 无条件失效，SIM 改挂载驱动）；NEG4 隔离夹具（拦截 Reference 逐命令三场景零调用）；`ohosCleanupTail` 三出口统一 + stopped/failed 按 owner 显式声明；探针身份绑定（PID/appInstance）+ C7 异步在途（INFLIGHT≥1）；thermo 同源重建 + 三产物冻结构建（verify 与 thermo `renderer_lib` sha 一致）。探针终验 **65 项 54 PASS / 11 BLOCKED / 0 FAIL**（含 S1–S5 生命周期反例、NEG 组、C-neg1/2、D 绑定）；A 验收「queued/committing 票后 close」离线补齐（S5：各票唯一终态/无重复 ACK/`shutdown_done=1`/许可归还/新代恢复）。
2. **最终冻结三产物（`run/rev9h-{normal,verify,thermo}/`，最新：normal `91ad72a6…`/verify `b12354b3…`/thermo `d249c492…`，verify 与 thermo renderer sha 一致 `d43515b8…`；历史 rev9g：normal `f88915fe…`/verify `7168f7aa…`/thermo `b38e072f…`，verify 与 thermo renderer sha 一致 `331e298a…`，verify 探针全量 PASS；取代 rev9f）；历史轮次 `run/rev9f-{normal,verify,thermo}/`**：当前最终输入（含 A 验收补齐的 sessionBackend 分派、backend=None 拒绝、owner 退出声明、S5 与 thermo 模板同步）重跑——主 normal `ed096cfe…`（启动全绿 seam absent + 写读 PASS）、主 verify `05a6c90a…`（探针**全量终验 PASS**，含 S1–S5）、thermo `82573ab9…`（消费写读 PASS）；verify 与 thermo `renderer_lib` sha 一致（`331e298a…`，同源）。取代 rev9-final-* / rev9-e-thermo2（其输入早于 A 验收补齐）。
3. **探针 helper 负控补齐（NEG5，离线，`run/rev9g-neg5/`，探针 69 项 58 PASS/11 BLOCKED/0 FAIL）**：复核 D「真实平台分支的接线、解析和错 ID/旧日志/阶段已结束/释放失败负控可现在完成」——NEG5a 错 ID 等待不误配结果、NEG5b 旧日志按 PID 判别、NEG5c 无武装时 held 不自增、NEG5d 释放失败码如实返回（负值必判失败；不可达不得冒称成功）。

3d. **精确性断言 + 变异测试（`run/rev9j-exact-mutation/`）**：按复核 A「恰好一次」收紧——S2 `自动 destroy 恰好一次（增量==1）`、`许可恰好归还一次（released +1 / acquired +0）`；S3 `flush 后自动拆除恰一次（==1）`——全 PASS（探针 failures=0）。按复核 B「临时恢复错误路径时负控必须失败」完成**变异测试**：注入历史错误路径（mount 空→回退退休记录取 window/auditWindow）后负控如实失败（`FAILED: Reference attempted in NEG scenario`、`audit fixture: rc=-1`）；还原后源码逐字节一致（sha256 比对）且负控恢复 PASS（`calls=0 verdict=0`、`rc=0`）——证明 NEG4 非恒真断言。

3c. **C 三条定向反例显式落位（`run/rev9i-cneg3/`）**：复核 C 要求的三条反例全部显式标注并 PASS——①永久无 Surface（C-neg1，`cleanup tail [stand-in stopped]` 按事实 not_started）；②**无 Surface 但已 ARM/present**（C-neg3：Phase B 业务可达 → present → CLOSE → 连接被拒 + `cleanup tail [phase-b closed]` + `render_shutdown_status=0 shutdown_done=1`）；③host.start 失败（C-neg2，`cleanup tail [host start failed]` + failed + 重试可达）。C-neg3 过程发现并如实记录：Phase B 出口的 renderer shutdown 先行执行，清理尾部按事实记 `renderer_started=false`（running 已复位），渲染收尾证据取 `host closed` 行渲染档字段——日志字段不掩盖事实。

3b. **命令面覆盖预检（离线，`run/rev9h-opcov/`）**：新增 `verify_probe_op_coverage.py`——探针使用的全部 27 个 OP 均有传输实现（直连或发布），发布的全部 OP 均有 owner 执行分支（闭合「发布不等于执行/命令从未存在」历史缺陷类）；真机首次执行面（`GATE_HOLD_*`/`GATE_DEQUEUE_HOLD_30000`/`GATE_SIM_*`/`GATE_A2_STATS` 等 9 项）已领出。已接入一键真机脚本 ⓪ 步预检（失败拒绝上真机）。

4a. **本会话终态说明**：设备能力两次复检均为 `NOT_CAPABLE`（`KnownShimNoRef/published=0`，仅模拟器在联），VerifiedNativeRef 或等价所有权客观不可达；按任务书原文「仅将真正依赖平台能力的实测单列待验」，第 4 项四项以此为终态登记（关闭路径见登记表终态记录；接入合格设备后一键执行并逐项审阅）。

3f. **组合范围通路落地与实机观察（`run/rev9h-verify/REV9H_COMPOSITION.md`）**：按复核 §E「传递可观察的组合范围」——渲染器新增 `ohos_renderer_ime_preview_range_ctx`（previewText + marked 范围 + `ime composition` 日志）、context json 暴露 `previewStart/previewEnd/previewText`、宿主 napi `imePreviewRange`、框架代理模板与两个消费工程 Index.ets 的 `onChange(value, previewText?)` 组合分流（组合走 `previewRange(offset, offset+len)`）。回归：生命周期探针全量 PASS + IME 链 T0–T6 全 PASS。**实机观察（模拟器+小艺输入法）**：真组合可驱动（pinyin 键 → 候选栏出现 → 字段随键增长），组合提交经失焦结算至 owner 逐字节一致；**`previewText`（marked 范围）参数在该 SDK/IME 组合下未观测到**（组合以普通 value 变化到达）——新通路已插桩，平台提供 marked range 时自动捕获。最终三产物更新为 **rev9h**（normal `91ad72a6…`/verify `b12354b3…`/thermo `d249c492…`，verify 与 thermo renderer sha 一致 `d43515b8…`）。

3e. **系统输入链离线闭环（`run/rev9k-ime/`，RESULT: PASS）**：复核 §E「不一概推定模拟器不能验证组合输入」——替身会话建立 Phase B + 测试通道触摸聚焦 + 真实系统输入（uitest → ArkUI AceTextField → 代理）全链端到端验证（T0–T6 全 PASS：失焦结算入 owner、投影版本前进、再聚焦新上下文、显式提交 rc=0 + owner 精确读回、迟到提交被拒 rc=1、结束后无活会话）。**本轮修复两个真实缺陷**：①`TOUCH_` 夹具动作码 0/1/2 未映射到渲染器 37/38/39——BEGIN 语义永不触发，触摸注入对焦点/指针路径实际惰性（命中/聚焦/代理挂载从未发生）；②替身会话使能必须走 ID 握手（单槽命令面发布≠执行，ARM 被覆盖致 backend=None 拒绝）。登记表第 4 项据此收窄为「真 marked-text 组合态 + 草稿可见渲染」。

3g. **最终交接页（`run/REV9_FINAL_HANDOVER.md`）**：A–E 逐项→证据索引、能力门控 4 项（含期望证据）、一键执行命令与终态判定口径（判据为运行时 VerifiedNativeRef，非设备名称）——供外部接手者直接关闭待验登记。

4. **单列待验（能力门控，正式登记；终态）**：`run/rev9-s5-final/PENDING_REAL_DEVICE_REGISTER.md` 的四项为 C1–C5 真实 XComponent 卸载 held、真实 renderer 原票与资源停止、像素/裁剪、系统 marked-text 组合态及草稿可见渲染。接续时用 `bash runtime/cjgui/platforms/ohos/scripts/run_pending_real_device_checks.sh --target <hdc-connectkey>`：指定目标→原构建脚本单次安装/启动→本轮 HAP/PID 能力判定→双探针及当轮归档。`check_real_ref_capability.sh` 现只供入口读取当前运行目录，不再单独重启旧应用判能力；历史登记表中无参数调用方式以此处为准。离线命令替身 7 用例 PASS，FAIL/BLOCKED/PASS 出口分别为 1/42/0；这不是设备能力变化或四项验收。**设备能力变化后仍需逐项审阅证据，人工/IME 不随入口结果自动关闭。**

工作区未 stage/commit/push。

证据根目录：`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/{run,verification,consultations}`。工作区未 stage/commit/push。
