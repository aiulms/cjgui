# 鸿蒙后端第五轮执行报告（来源断点闭合 + A1 主路径 + B 补强 + E 判别）

2026-09-26。执行自报。依据任务页「第五次指导复核与当前完整工作包」；环境为模拟器。

## 已实现并验证（源码、快照、消费目录、HAP 同版本）

### 来源断点闭合（复核首要项）

- 两轮快照重放：第一轮把共享核心的 ACK 重试/ACK 检查/close 意图/discard 重试/几何接缝/最内层命中修复重放进 `platforms/ohos/snapshot`（此前 HAP 确实消费旧逻辑）；第二轮把本轮 A1 新路径同样重放。平台差异为零（快照与共享逐字一致），Pharos 输入/事件并行修改（几何接缝、命中修复）完整保留。
- 链验证不止指纹：`snapshot ↔ labs/entry/cjgui/src ↔ source_manifest` 逐文件 sha256 一致（`composable_ui_window.cj=58e5cb4d…`、`macos_application_host.cj=52e3b616…`），normal/verify 两变体真机启动断言全过。平台指纹 `45880852a316…ba`。

### A1 主路径（实现 + 207 用例 + 真机消费）

- **首帧 StartingPending host 持有**：新增 `startWithOutcome(): StartReady | StartAcceptedPending | StartFailed` 与 `isStartingPending()`。首帧 PENDING 不再落入 `start_refresh_failed` discard（那会使 native 票据变孤儿）；会话与原事务保留，宿主把窗口留在泵送集合，由前置结算门推进到 Ready/失败。macOS application host 两处调用点迁移（仅 StartFailed 失败），`isWindowStartingPending()` 透出受理状态；兼容入口 `start()` 语义=已打开。失败/单次 close/Starting 时 stop 留在同一实例状态机（close 意图与 discard 重试为既有路径）。
- **settlePendingPresent 三态分离**：事务新增 `acceptanceStarted/coreSettled/ackCompleted/settlementFault`。native 终态观察（settled）、核心收尾（try/catch 包裹 acceptance/rollback；`acceptanceStarted` 一旦落账绝不重跑同一回调，防重复 participant/focus）、ACK 完成三者分开。Accepted 后异常/返回假 → **不可回滚终止收敛**：保留原票与候选持有（阻止新候选）、命名故障（`present_acceptance_exception/incomplete`）逐轮报告、唯一出路显式 close/discard；Rejected 回滚异常同样按原票收尾（`present_rollback_exception`）。ACK 只重试原票；ACK 成功不清票，清票以 `coreSettled` 为准。
- macOS `cjpm test` 207/207 通过（A1 改动后全量）；normal/verify HAP 真机启动、场景提交、入口装载断言全过。

### B 探针补强（B.1–B.4 全项，双探针真机 PASS）

- 独立严格解析器 `ohos_transport_probe_lib.parse_control_frame_strict`：协议行/KIND/OP/END/键名/重复键/空值全查；ERROR 帧剥除成功键。业务终态解析 `parse_business_terminal_strict`：实测词表 SNAPSHOT/RESULT/ERROR，RESULT 强制 APPLIED/CONFLICT/VERSION_AFTER 合法。
- B.1：拒绝证据只认 EOF/reset/refused；`socket.timeout` 一律记失败；探针内置「仅超时不判拒绝」负控自检。
- B.2：旧 socket 半帧补发——stop 前**同一条**旧连接发送可辨识 INCREMENT 帧前半部，Closed/boot 后补余帧，实测 EOF（对端关闭），操作未应用、版本不变；新连接新请求成功。
- B.3：committing 探针改为 EXEC_HOLD **先于** RESUME（消除认领竞态）；新增 `TICKETS` 取证 op（transport 登记执行中票据，接缝未注册不登记——普通产物无路径），在生产 stop 裁决前采样到目标票 `PHASE executing`（ID+阶段入证据）；客户端拿到完整严格解析的 `KIND RESULT / APPLIED true / VERSION_AFTER=v0+1`（删除「不含 outcome_unknown 即通过」旧断言）；公开 owner 读回恰好 +1；注明该层为 transport 票据提交、renderer Flush/Committing 不在其内。
- B.4：两探针统一绝对单调 deadline + 有界读取；原始请求/回包逐条归档（`transport_reopen_raw.json` / `transport_committing_raw.json`），证据 JSON 关联 token/旧新实例身份/目标票 ID。
- 运行：reopen PASS（HAP `15293eb0…` 系列，`b5_verify2`）；committing PASS（v=2→3、count=12→13）。

### E 判别与身份绑定

- **E.2**：`launch_id`（uuidgen）与 `launch_ts` 在启动**之前**落账，与 PID/HAP/日志区间同入断言日志；启动断言新增 marker-PID 绑定（hilog 行第 3 列 == 本轮 PID，实测 `normal_v5` pid=13314 通过）。新负控 `CJGUI_NEGATIVE_STALE_LOG=1`：不清缓冲、不启动，旧实例 marker 因 PID 绑定不符被拒（实测 NEGATIVE-CONTROL OK）。bash 3.2 全角字符吞变量名问题以 `${var}` 修除（项目已知坑）。
- **E.1 追加负控与全量解析**：缺真实 NEEDED 依赖负控（移除 `libcjgui_ohos_transport.so` → MISS + `UNSAT libcjgui_app.so -> …` FAIL）；NEEDED 解析放宽覆盖全部实际条目（`.so`/`.so.N`，不限 `lib*.so`）；新增 ELF 架构校验（Arch: aarch64）与 LoadName 身份校验（无 SONAME 合法；`libc++.so`→`libc++_shared.so` 为打包决策的已记录顶替例外）。三态归档：intact PASS / damaged BROKEN+FAIL / missing-dep UNSAT+FAIL（`closure_*_v2.txt`）。
- **E.3 部分**：`sync_platform.sh` 应用源码目录参数化（`CJGUI_APP_SRC`，默认共享示例）；`source_manifest.sh` 全部枚举改 `find -print0 | sort -z | read -d ''`，含空格路径实测（假目录 `x.ts` 哈希完整；真实 lab 480 项与部署清单一致）。顺带修复可选目录不存在时 `set -e` 中止清单的问题。

### 回归

- normal 变体（`normal_v5`，HAP `160391c0…`）启动断言（含 PID 绑定）+ gate 全套 PASS；verify 变体（`b5_verify2`）五项 marker + 两强化探针 PASS。

## 未完成（如实列明，非"补测试"性质缺口）

- **A1 §5 注入反例矩阵进实际 HAP**：首帧/完整刷新/交互投影 Pending→Accepted/Rejected、等待期改 owner/滚动、重复 query/ACK、participant/focus 抛错、ACK 失败恢复——本轮已交付其依赖的生产路径（三态分离、StartingPending），但强制注入的测试闸门（renderer `--test-gates` 首帧 PENDING 强制 + 核心回调异常注入）未建，上述路径目前由单测覆盖结构、真机覆盖正常路径。
- **A2**：SurfaceRecord 五元身份 + RAII 使用许可（创建/绘制/Flush/缓存/redraw/teardown 全程）与 8 类闸门反例未实现；现 renderer 仅有 retired-lease 拒绝与 busyGeneration 提交窗口。
- **A3**：渲染器级 Stopped 全收敛判定（本实例 owner 实退/窗口事务 ACK/renderer teardown/surface 许可/传输收敛合并确认）、Starting 时 stop、启动失败可重试未实现；当前重开仍为传输层（owner/renderer 存续）。
- **C**：ArkTS 文字代理模板、挂载身份冻结、`preservesActiveLocalText` 替换 `value.empty()` 推断、空值三处一致、selection/marked UTF-16/8、emoji/切字段、人→外→人续写（alias 字段已在应用，桥接证据为第三轮）。
- **D**：跨边界/空交集/圆角外点/resize 像素与命中双反例、前后台、同请求单调分段耗时、空闲收敛数据。
- **E.3 剩余**：含空格独立目录的不同字段结构消费者实际构建运行（`CJGUI_APP_SRC` 参数化已备，消费样例未建）。

## 版本对应

| 产物 | HAP sha256 | run |
| --- | --- | --- |
| verify（强化双探针） | `569b4659…/15293eb0…`（同源连续部署） | b5_verify / b5_verify2 |
| normal（PID 绑定 + gate 全套） | `160391c0…79` | normal_v5 |
| A1 链首次部署 | `d13bec66…85` | a1_chain_v1 |

负控记录：`neg_stale`（旧 marker 拒绝）、`neg_seam`/`neg_nostart`（沿用）、closure 三态（v2 归档）。
