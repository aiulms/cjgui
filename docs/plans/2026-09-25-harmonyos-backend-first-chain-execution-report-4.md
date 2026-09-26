# 鸿蒙后端第四轮执行报告（A0/A1/B 收口 + A2/A3 传输级反例 + E.1 失败判别）

2026-09-26。执行自报。依据任务页「第四次指导复核与当前完整工作包」；环境为模拟器（非物理真机）。

## 本轮已验证（源码、产物、运行证据同版本）

### A0 共享 ABI 单一来源

- `CjguiInternalRendererFrameObservation` 统一为 40 字节（`ticketId`）：C 头 `_Static_assert(sizeof==40)`；共享 `runtime_renderer_session.cj` 以 snapshot 为基合并回共享核心并保留 Pharos 的 4 个诊断 foreign（cancel_composition/window_number/probe_image_texture/declare_input_caret）。
- 仓颉侧 canary 双测试（`runtime_renderer_abi_layout_canary_test.cj`：`sizeOf==40`；`present_clear` 无效会话直传 `inout wrapper.observation` 断言尾部哨兵不变），macOS `cjpm test` 207 用例无失败；同源 macOS 库 get/INCREMENT/读回通过。
- 鸿蒙 snapshot 指纹 `bdf17c48713ff452…` 已重建，`FINGERPRINT.txt` 与 README 再同步步骤可重现；`sync_platform.sh`/`sync_sources.sh` 均指向框架自有 snapshot。

### B 传输验证修正 + 真正关闭后同进程重开（本轮收口）

- `verify_transport_gate.py` 三修正于 normal 变体全绿（`transport_gate_evidence.txt`，run `normal_final`）：合法值 `EDIT_NAME PAUSE_CLAIM` 经 `name_changed` 进入 owner 且公开读回 `PAUSE_CLAIM`；半帧超期限 `eof` 收场、alive-timeout 记失败；SETTLE 只证"排队取消完成"。
- **重开链根因修复**（此前 GET_CONTEXT 超时的直接原因）：
  1. SETTLE 控制处理器跑在本帧自己的连接 worker 里，同步 `awaitClosed` 恒假（连接计数含自身）——改为分离线程：等本帧连接终结 → 生产 `awaitClosed` → 生产 `requestProductionBoot`，结果经新 listener 的 `BOOT_STATE` 读回（旧实例 CLOSED 证据不丢）。
  2. `listen()` 从不显式关闭监听 fd，同端口重开 `bind` 必然受旧 fd 影响——监听 socket 关闭与 `acceptExited` 移入 `finally`，任何退出路径保证关闭判据可见且 fd 释放。
- `verify_transport_reopen_v2.py` 连续两轮 PASS（run `reopen_v12`，HAP `4c01f91f…`）：4 张 Pending 全部 `closed_not_executed`、无客户端未定；SETTLE_HOLD 800ms 关闭窗口内连接被拒；生产 `awaitClosed` 判定 CLOSED=true；同进程 BOOT 新身份 `ohos_transport_1000`≠`ohos_transport_1`；重开后业务可用、owner 值保留、取消票未重复应用（v=0/count=10）；半帧补发不进新 owner；新身份 INCREMENT 应用。hilog 时间线（`reopen_hilog_timeline.txt`）显示第二轮 generation 单调推进 1000→2000，同端口重绑稳定。

### A2/A3 传输级三态停止反例（新增）

- 机制：`VerificationSeam.setExecutionHoldFor`（未注册产物恒 0，无触发路径）；owner 循环在 claimNext 与 dispatch 之间读剩余保持毫秒。
- **queued 态**：reopen_v12——4 张排队票取消、不应用、额度回收。
- **committing 态**：新探针 `verify_transport_committing_probe.py` PASS（run `commit_v1`，HAP `f6003748…`）：票据进入 Executing（INFLIGHT=1、dispatch 推迟 1200ms）→ SETTLE 停止落在窗口内 → Executing 票**不**被取消，owner 到期放行按真实终态（Done）结算，客户端拿到真实回包（非 outcome_unknown）→ `awaitClosed` 等在途归零 → CLOSED=true → 同进程 BOOT 新身份 → 读回版本恰好 +1、计数恰好 +1（提交不丢、不取消、不重复）。
- **收敛后空闲 boot 段**：两次 probe 的 `awaitClosed→boot` 均在零票据零连接下完成。

### E.1 构建失败判别（本轮收口）

- `build_and_run.sh`：断言函数逐项收集失败，修复 `{ f1; f2; } || ASSERT_FAILED=1` 中 f1 失败被 f2 成功覆盖的掩蔽；断言日志新增 `launch_ts`，与 run_id/HAP sha/PID/日志起点绑定。
- 新负控 `CJGUI_NEGATIVE_SEAM_ONLY=1`：仅接缝日志、缺 owner/present/入口装载时，真实断言函数必须拒绝（实测 `neg_seam`：NEGATIVE-CONTROL OK）。
- `verify_hap_closure.sh`：成员列表读取失败即拒绝；每成员提取失败 → `BROKEN`；ELF 解析失败（readobj 失败或输出缺 `Format:`/`NeededLibraries [`）→ `BROKEN`，不再 `continue` 吞没或藏在 process substitution。NDK static-pie stub 的合法空 NEEDED 不误报（实测踩到 libEGL.so 后修正）。
- 负控与正样例归档（`verification/`）：完好 HAP PASS（`closure_intact_pass.txt`）；破坏 `libcjgui.so` 的 HAP 精确点名 BROKEN+FAIL（`closure_damaged_fail.txt`）；`CJGUI_EXTRA_REQUIRED_LIBS=libnope.so` → MISS+FAIL；`CJGUI_NEGATIVE_NO_START=1` → 全项 FAIL+NEGATIVE-CONTROL OK（run `neg_nostart`）。

### normal 变体回归

- 本轮共享 transport 修改（listen finally、execution hold）在普通产物编译并通过全部启动/变体断言（run `normal_final`，HAP `2538415e…`，`seam absent`），gate 全套 PASS。

## 已实现但未达验收（缺口与依赖）

- **A1 §5 注入反例矩阵**：现有测试闸门只有 flush/dequeue 时序（`CJGUI_OHOS_TEST_GATES`）。首帧/完整刷新/交互投影分别 Pending→Accepted/Rejected、等待期改 owner/滚动、重复 query/ACK、participant/focus 抛错、ACK 失败重试等逐票断言未建。结算门/ACK 检查/close 意图消费点的实现已入共享核心（macOS 侧 207 用例通过）。
- **A2 渲染器级 SurfaceRecord**：retired-lease 拒绝与 `busyGeneration` 提交窗口已在宿主渲染器；按 Sol 方案的每代记录（appInstance/sessionToken/componentInstance/surfaceGeneration/geometryRevision 五元键）、许可/引用配对逐项记录与 8 类闸门反例未建。依赖宿主 surface destroy 回调可注入时序。
- **A3 渲染器级**：当前重启为传输层（owner 不退出、渲染线程存续）。Starting/StartingPending 态 stop、启动失败可重试、按实例 owner 退出确认（`g_appThread.detach()` 不能证明本实例退出）未实现。
- **C**：应用已有 name+alias 双字段（node 24/25）与第三轮人→外部→人证据；仍缺：selection/marked 范围 UTF-16/UTF-8 接通的选区替换、中间插入、emoji/组合读回、`preservesActiveLocalText=false` 空值三处一致性、代理抽为框架公共模板。系统 IME 组合态受模拟器 inputmethod C-API `Set*` 编译桩限制，相应验收单列。
- **D**：裁剪/命中像素双反例（跨边界、空交集、圆角外点、resize）、真实 resize/前后台、同请求单调时钟阶段采样、空闲唤醒开销未建。
- **E.3/E.4**：公共构建入口已参数化（LAB_ROOT/APP_SRC），但独立目录消费者（应用字段结构不同）未实际构建运行；源清单一致性只证明原目录输入匹配。

## 版本对应

| 产物 | HAP sha256 | run |
| --- | --- | --- |
| verify-transport（重开两轮） | `4c01f91f7c77…1818f` | reopen_v12 |
| verify-transport（committing 反例） | `f600374843a7…dad5` | commit_v1 |
| normal（gate 全套+启动断言） | `2538415eb82a…a477` | normal_final |

证据目录：`labs/ohos_cangjie_smoke/artifacts/cjgui-backend/run/{reopen_v12,commit_v1,normal_final,neg_seam,neg_nostart}` 与 `verification/{transport_reopen_evidence.json,transport_committing_evidence.json,transport_gate_evidence.txt,closure_*.txt}`。
