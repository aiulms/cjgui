# HarmonyOS 后端优先链：第二次指导复核后执行报告（2026-09-25）

依据：`docs/plans/2026-09-25-harmonyos-backend-first-chain-prompt.md` §「第二次指导复核与当前完整工作包」（A–E）。
本轮集中交付以下内容，未逐小步停工；原首轮执行报告保留为历史证据。

## 1. 产物身份（本轮）

| 项 | 值 |
| --- | --- |
| 正常构建 run | `run_20260925_174710` |
| HAP sha256（正常路径） | `c7fa95d96faf5822035e71323dfcdadb2b12b0d9cd9591f1bd78f07f5d3a5d33` |
| 源码清单 | `source_manifest_run_20260925_174710.txt`（462 项） |
| 启动断言 | owner 起链 / 场景提交 / 仓颉入口装载 三项全绿（清缓冲后新实例） |
| 构建管线 | `scripts/build_and_run.sh`（同步→渲染器→hvigor→重链不变量→闭包校验→安装→启动断言→manifest） |

负对照构建产物（同源码，用于证明闸门有效，不代表交付物）：
`CJGUI_NEGATIVE_NO_START=1` 一轮的 HAP sha256 = `33ee5cfff2ab2b1448c3f7f9f296cb646037570cd7792cfe2c1fd3d6ef9cbea5`。

## 2. 工作包 C：通用文字代理与双字段接续（本轮收口）

新增端到端脚本 `runtime/cjgui/platforms/ohos/scripts/verify_ime_proxy_chain.sh`，人类侧全部经
`hdc uitest` 真实触摸/输入驱动，断言只读应用自身日志、接受场景投影与外部客户端读回。

证据：`verification/ime_proxy_chain_evidence.txt`、`verification/human_external_human_evidence.json`、
截图 `t7_h_local_draft_before_external.jpeg` / `t7_h_local_draft_alive_after_external.jpeg` /
`t7_final_owner_value.jpeg` / `t8_owner_value_after_submit.jpeg`。

**结果：PASS（21 项断言）**

| 用例 | 断言 | 结果 |
| --- | --- | --- |
| T0 | owner 起链、首帧提交（nodes=12） | OK |
| T1 | 失焦结算文本 = 草稿；`settled=1`（组合预览确被折入）；投影版本前进 | OK |
| T2 | 再聚焦同字段：新上下文 ctx=2、缓冲为已提交值 | OK |
| T3 | 失焦后追加编辑再次结算 | OK |
| T4 | 系统键盘回车提交 rc=0；提交长度 len=8（输入确实到达代理）；读回 match=1 | OK |
| T5 | 负对照：迟到提交 rc=1 | OK |
| T6 | 负对照：结束后无活会话 state=closed | OK |
| T7 | 人→外部→人（框架 blur 路径）：草稿按失焦语义结算、owner 报告「未应用」、投影回到 owner 的外部值 | OK |
| T8 | 人→外部→人（ArkTS 提交路径）：上下文编号仍活 → 传输层 rc=0；owner 层仍裁决未应用 | OK |

本轮修复的关键缺陷（此前会让字段持续显示被拒草稿）：

```cpp
// runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp（绘制编辑视图）
if (sess.editorRetired && !node.value.empty()) break;
```

语义：逻辑编辑已结束（retired）时，本地缓冲只用于补核心「本地文字延续」窗口内的空投影；
一旦 accepted 已给出该节点的值，那就是 owner 的裁决（含本地编辑被拒、owner 保留外部值），
不得再被本地缓冲遮盖。T7 的最终截图与 `accepted node=24 value=外部改写` 是修复后证据；
修复前同场景卡片显示 `我的设备人写`。

同时固定下来的两条时序事实（写进脚本注释，避免后人误判）：

1. **`accepted value` 为空 ≠ 业务空值。** 核心在 `preservesActiveLocalText` 为真时把 native 值置空，
   约定由原生编辑器绘制该节点可见文本；因此 T1 结算后的 `accepted node=24 value=` 是空的而字段显示正常。
2. **`uitest uiInput inputText` 实为经剪贴板粘贴**，必须等系统键盘先弹出（点击字段后约 2–3s）才会落到代理上；
   点得太快会静默丢失输入，脚本因此对 T1/T3 做一次整体重试。

系统 IME 单独验收的边界如实记录：本轮的组合预览证据来自「代理 onChange → 预览缓冲 → 失焦按可见值结算」
（`settled=1`）。真实系统键盘/候选构成的组合态尚未单独取证，见 §5 欠项。

## 3. 工作包 B：传输的有界与重开隔离（本轮补反例）

新增 `scripts/verify_transport_reopen.py`，证据 `verification/transport_reopen_evidence.txt`。

**结果：PASS（10 项断言）**

| 用例 | 断言 | 结果 |
| --- | --- | --- |
| B1 | 12 条连接滴流（上限 8）：超限被关闭；额度释放后正常请求仍可应用 | OK |
| B2 | 无换行 header（20 字节 > MAX_HEADER_BYTES=16）：连接被拒（EOF） | OK |
| B3 | 暂停认领后两批各 8 票：服务端超时结算 8/8 + 8/8；暂停期间无业务写入；恢复后正常应用 | OK |
| B4 | 半帧连接（只发长度头）到期清理；不影响后续正常请求 | OK |

**驱动手段的更正（重要）**：模拟器上 `hdc shell` 是 `uid=2000(shell)`，
`kill -STOP <app pid>` 返回 `Operation not permitted`，`su` 不存在，**无法从外部暂停应用进程**。
因此按任务页「测试宏和可控闸门是本包实施工作」，在传输层加了一个明确的**验证闸门**：

```cangjie
// entry/ohos_transport/src/ohos_transport.cj
var claimPaused: Bool = false        // BridgeContext
if (c.claimPaused) { unlock; return None }   // claimNext
// serveFrame: payload.contains("PAUSE_CLAIM") / ("RESUME_CLAIM") → 切换开关
```

使用与正常交换相同的帧语法（`CONTROL PAUSE_CLAIM` / `CONTROL RESUME_CLAIM`），只切换认领开关，不触碰业务。
**移除条件已写在源码注释里**：B 节反例验证通过并归档后即可删除该字段与 serveFrame 的控制帧分支。

## 4. 工作包 A / D 的源码现状（前几轮已完成，本轮只读核对）

核对结论：任务页 A/D 所列**源码缺陷均已修复**，本轮未再改动这些路径。

- A1 状态码判别：`waitFor()` 已由 Bool 改为状态码；4 个调用方（measure 2108/ext 2117/2143、caret 2823、present 2404）
  均显式 `!= OK` 判别并记录失败窗口。
- A2 UAF：队列/渲染线程/等待者共享 `std::shared_ptr<WaitableJob>`（`JobRef`），超时只结束等待、不释放工作线程仍访问的对象；
  `acquireCommitPermission()` 在同一临界区完成「确认未取消 → 转入 Committing」，未取得许可不得 Flush。
- A3 PENDING 票据：present 超时返回 PENDING 时，把 job/候选节点/投影版本存入 `g_pending[slot]`（2405–2421），
  共享所有权 + 票据身份，owner 在下一次 present 一次性 commit/rollback。
- A4 lease：`cjgui_ohos_ingress.h` 提供 `leaseValid(generation)`；ingress 快照不再以裸 window 作为保护依据。
- A5 关闭：`cjgui_host_bridge.cpp` 的 `StopHost`/`AppShutdown` 调 `requestAppStopFn()`（真实停止入口）；
  owner 循环在轮间安全边界退出，依次 requestStop → awaitClosed(2000) → host.close → `ohos_renderer_shutdown_render_thread()`
  → `cjgui_ohos_renderer_shutdown_done()`。
- D 裁剪：`effectiveClips()` 统一解析（`clipConstraintCount` 1..4 → clipN，否则用**单 clip 字段**而非 clip0）；
  零尺寸 → 返回 false，**既不可见也不可命中**；`pointInsideClips()`（命中）与 `applyClipChain()`（绘制）共用同一解析，
  圆角按半径判定与 `ClipRoundRect` 一致；hitTest 路径（1262）确实调用 `pointInsideClips`。

## 5. 精确欠项（未完成，逐条可核查）

1. **A 的受控反例未跑**：queued 超时、最后取消点交错、Flush 内超时后最终结算、旧 lease 取得后销毁同尺寸重建、
   measure/caret OK 与失败两侧、空闲/queued/committing 三时机 `stop→await→同进程 boot`。
   源码返工已就位，但**缺受控测试入口驱动这些状态**（当前只能观察正常路径）。
2. **D 的夹具未做**：跨边界/空交集/圆角/尺寸变化的像素 + 命中断言；真实 resize/前后台/恢复基线、
   `input→owner→accepted/submit` 单调时钟、周期唤醒与资源收敛。源码裁剪语义已统一，夹具未建。
3. **E 未收口**：`ohos_transport.cj` 仍在 `labs/` 内（`platforms/ohos/` 只有 snapshot/host/scripts），
   公共平台入口尚未真正收敛；最终产物未与安装指纹/日志/截图/消费者冻结绑定；
   实际 ELF 闭包集合与 ZIP 路径精确匹配的复核未重做。
4. **macOS name/alias 同源回归**：`macos_regression_evidence.md` 仍为旧计数操作，名称字段原始读写与拒绝未补。
5. **系统 IME 真实组合态**：真实键盘/候选形成的组合过程与提交/取消未单独取证（程序化 `inputText` 已记录其对应路径）。
6. **Astra/Sol 聚焦咨询**未发起；本轮未改动 pending 公共契约与 lease 方案，故该项未触发。

## 6. 工具调用记录

**Laya（实际调用，POST /v1/systemone）**：判定「测试闸门放协议控制帧还是 UI 按钮经 NAPI」。

- `gate`：choice = ui_button，概率 0.4996 / 0.5004，**confidence = 0.0** → 对方案选择**无区分度**，
  不作为依据；实际采用协议控制帧，理由是外部客户端可在同一脚本内确定时序、不依赖屏幕坐标。
- `residual`：noul = **0.9872** → 高置信认为「测试闸门残留在生产源码构成长期维护风险」。
  据此已在源码注释中写明**移除条件**并在本报告 §3 登记。

按规则，Laya 输出只作辅助，不作为状态机已运行或闸门有效的证据；上述结论均由设备实测日志支撑。

## 7. 工作区状态

本轮改动文件（未 stage / 未 commit / 未 push，等指示）：

- `labs/ohos_cjgui_app/entry/ohos_transport/src/ohos_transport.cj`（验证闸门：claimPaused + 控制帧）
- `runtime/cjgui/platforms/ohos/scripts/verify_ime_proxy_chain.sh`（新增，C 端到端）
- `runtime/cjgui/platforms/ohos/scripts/verify_transport_reopen.py`（新增，B 反例）
- `labs/ohos_cjgui_app/entry/src/main/ets/pages/Index.ets`、`runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp`
  （本轮之前的 IME 代理 / editorRetired / hit=0 修复，已随本轮构建验证）

历史规则冲突记录：`AGENTS.md` 要求「未经用户要求不 stage、commit、push」，故本轮只交付不提交。
