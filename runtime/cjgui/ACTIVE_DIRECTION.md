# CJGUI 当前方向与实施状态

更新：2026-09-26。目标：仓颉核心、macOS 首平台、高性能自绘/GPU GUI 框架；人和外部系统操作同一份内容，支持手写、生成及混合界面，共同信息单一定义。

## 当前阶段与执行状态

[长文本增量更新与完整样式绑定](../../docs/plans/2026-09-23-incremental-text-style-binding-milestone.md) **已通过指导验收，以页末「指导验收结论（2026-09-24，本阶段收口）」的适用域和保留边界为准**。原始任务、裁决与逐轮记录是历史证据，不再是待执行清单。[交接说明](../../docs/plans/2026-09-19-external-executor-handoff-prompt.md) 已同步。

执行任务 **「CJGUI 文字性能与阶段收口」**（`01a0d1c8-6610-7cd2-8946-773000f9b226`）由 GPT-6 Sol / xhigh 主执行、GPT-6 Luna / high 配合，该包实施与验收已完成，该任务没有新的实施指派。指导任务 `01a08f0f-e1ce-71c1-9a6e-4eee08308d61`。旧执行任务及30分钟自动化保持暂停。

**当前框架并行实施包：鸿蒙后端基础链收口与系统文字接入。** 当前完整接续见[交接文档第六次指导复核](../../docs/plans/2026-09-26-harmonyos-executor-handoff.md#review6-current-package)，其余原判据沿用[阶段任务页第五次复核](../../docs/plans/2026-09-25-harmonyos-backend-first-chain-prompt.md#review5-current-package)。路线保持仓颉核心 + ArkTS 薄壳 + XComponent + 原生绘制后端。用户安排的外部执行 AI 负责实施，必要返工与通用文字/独立消费能力交错推进；旧执行任务和30分钟自动化继续暂停。

**指导复核状态：整包进行中，未通过验收（2026-09-26）。** 已核对[第六轮报告](../../docs/plans/2026-09-26-harmonyos-execution-report-6.md)、相关源码、实际 SDK 头文件、原日志与归档截图；本次未重跑构建、测试或模拟器。第六轮“高亮已证→整包完成”的自报结论已更正。

**当前接受范围：**选区变化触发重绘、人工操作模拟器所得 `[0,4)` 与可见高亮、失焦结算和 owner 读回有对应证据；T4 增加真实 owner 断言，T0–T6 有通过日志。保留原事务/ACK/传输的局部反例、Surface 退役机制、裁剪几何、含空格源码输入的构建运行成果，详细适用域见交接文档。高亮不等于选区替换或系统组合提交/取消，模拟器人工输入不等于物理鸿蒙设备。extend_libs 的构建问题已随编译修复解除，不再列作环境阻塞。

**具体欠项：**

- **A 引用/停止与原事务：**查清 NativeObjectReference 非零返回与实际 SDK/装载 ABI 的冲突；真实 CYCLE 原证 `unrefs=0 pending=10` 尚未收敛。补原票矩阵缺口、创建返回/不可取消 Flush 反例、Starting 停止和同进程真实 owner/renderer 退出后重开；force-stop/start 与传输 Executing 各保留自身范围。
- **C 公共输入：**真实回调捕获创建时挂载身份（当前页面仍取 currentMount/imeCtx）；系统 marked/preview 范围与提交/取消；选区替换/删除；name/alias 和独立消费者的完整人→外部→人成功接续。保留 selection_probe 两个历史 FAIL，人工高亮只补足非空选区部分。
- **D 绘制/响应：**跨裁剪文字/按钮的像素与命中负控；当前背景色带即可通过的断言需修。三类输入的逐请求单调阶段样本、停止后唤醒/资源收敛仍欠，3 次 round-trip 不作分段时延。
- **E 实际消费：**不同字段结构、独立应用身份/输出的消费者与本实例实际输入链；当前仅设置示例的规则变体。最终 normal/verify 冻结同一生产输入并分别验证，旧 normal_v5 不覆盖最新宿主/文字改动。

**接续顺序：**先定位引用契约；等待咨询/构建时推进独立的代理接线、验证器及消费者准备。依赖安全判据恢复后汇合 HAP 验证，共享修改做相关 macOS 回归。物理鸿蒙设备对照仍是环境未验边界，不阻塞可在模拟器完成的原任务。阶段外新能力在本包验收后结合编辑器需要选择，当前不另开新包。

Pharos Mark 在 `/Users/jiangxuanyang/Desktop/Pharos Mark` 独立推进 macOS 编辑器，以产品检验框架；其事实只见 [STATUS](</Users/jiangxuanyang/Desktop/Pharos Mark/STATUS.md>)。2026-09-26 对异步保存预算末轮的第二次指导复核已更新 [当前完整工作包](</Users/jiangxuanyang/Desktop/Pharos Mark/docs/IMPLEMENTATION_PLAN.md#current-package>)。保存三段与写入优化保留，继续补完整SaveTicket、独立取消、恢复日志尾部和实际owner预算；`--external`已接共享连接，旧入口统一、空RANGE及旧版本业务动作仍欠。框架命中已从面积改为几何包含，但等矩形/非祖先遮挡仍错；需正式层级/绘制顺序，复用既有B2 Astra契约实现accepted排版几何、TEXT捕获及两消费者。A0恢复长期encodingCoverage/DOC-09语义，C2真实长文响应、D生成面板与E交付继续并行。本次仅静态/证据审阅和文档更新，未重跑产品验证；“框架60”只指shared_operation_core范围。鸿蒙并行实施包保持上述范围，共享接口变化协调写入与对应回归。

## 已接受的交付

- **样式与输入**：聚焦优化限定真实输入，候选资源/scratch 与失焦预算拒绝保持旧资源；命名样式整组绑定、生成页签标题、真实标题切换/STYLES/局部像素和两模板消费均有对应证据。
- **增量文字与绘制**：局部属性、字体、选区/锚点和可见资源复用；离屏修改后滚动见新内容并可继续编辑。多行单片/多片共用 TextKit 准备；同几何 ASCII/Unicode 分片的 scene 平面逐字节相等，一字节变造被检出。准备失败与合法空 inset 的 native 边界、普通窗口自然高度测量失败保留 accepted 并恢复均通过。
- **正常同进程双窗**：27 热样本 A 同步段 p95=22.014ms，B owner/accepted 观察上界 p95=25.269/42.433ms；全行改写另有单次对照。实际 auto-height 消费者为 3700 行、102490 UTF-16 / 161690 UTF-8，不用固定/填满高度绕开测量：27 热样本 A p95=68.947ms，B owner/accepted 观察上界 p95=72.008/88.995ms，满足本负载 100/150ms 预算；冷预热 243.822ms 另列。
- **连续性与回归**：关闭 A 后，同实例 B 的逐字工具输入进入真实 owner 并精确读回；独立聚焦/失焦/再聚焦链通过。最后的 scope-remap exit109 已定位为探针漏传命令 focusScope：空 scope 拒绝、正确 scope 接受、旧场景排队前与新场景均有焦点、旧事件拒绝、新 Cmd-K 应用、Tab 到正确兄弟均通过。重开图片复用应用缓存，新 session 解码 0、提交/完成帧 1，旧代不得推进计数。最终完整 controller 探针 exit0，日志 `/private/tmp/cjgui-sol-scope-remap-focused-both.log`；本次只改探针/构建脚本，未改产品代码。
- **同源交付**：`/private/tmp/cjgui-sol-autoheight-final-export-20260924`，83 项（75 identical/8 rewritten），指纹 `fe0544e304b2101240d424500f589c38f280148052a9b26dd9b0158b27c2274d`。指导读取源码/原始日志并重新逐文件比对；性能分位数已重算，未重跑产品测试。最终探针修改后产品导出仍一致。工作区尚未 stage/commit/push，此为本地预览交付。

## 保留边界与下一步

- 新能力只解决已解析内容宽度的 multiline 自然高度。无约束 preferredWidth、普通 TEXT 的旧测量路径仍可能昂贵；旧四指标测量 API 保持原语义。编辑器的大文档应按范围取数、视口布局及增量索引设计，不能把 GB 文件交给一个要求立即精确全文高度的普通字段。
- 一次 tail 局部刷新曾出现额外 raster，随后多次通过但首因未定位；保留原始失败和分段观测。重遇或新生产变化触及该路径时继续定位，不把连续绿色当作已修复。
- 证据分别标记 native 受控探针、正常应用、公开客户端和 CGEvent/AX 工具输入。人工物理输入、系统 IME/VoiceOver、显示器实际呈现、整体峰值内存、GB/真机性能和发布不由本阶段结果覆盖。

具体历史、源码版本及日志索引只见阶段页。阶段接续结合编辑器的实际需求及[设计导航](../../docs/plans/DESIGN_INTENT_INDEX.md)，审视组件布局、自绘/GPU、文字输入、资源调度、语义动作与普通开发者接入六条主线。
