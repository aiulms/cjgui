# P1 设计意图导航出口协议

日期：2026-05-06

状态：docs-only / navigation governance / no runtime truth

## 文件定位

本协议补齐 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 与 [topic-manifests](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/README.md) 的出口机制：阶段包、硬边界、blocker / recovery 或 milestone 完成后，如何判断是否需要同步 topic manifest，何时开阶段性 reconciliation scan，以及如何避免设计意图地图过期。

自动化执行期间还必须遵守 [P1 自动化文档预算治理](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-automation-documentation-budget-governance.md)。自动化窗口应以工程阶段包为目标；普通推进只写 automation report，阶段边界才写 compact manifest，只有 authority / truth / stop-line 扩张、public surface、protected path、production native call site、GPU / renderer state 等硬边界才写完整封账包。

本协议不是 runtime truth，不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，不改变当前 Renderer 技术路线，不授予 implementation permission。

本文不定义当前 Renderer next opening；当前唯一 next opening 以 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)、对应 topic manifest 与最新 automation report / compact manifest 为准。本文只约束导航出口方式，不改变技术路线。

## 轻量出口

普通 automation report 只做轻量出口记录：写清当前 tail、stop-line、验证结果、next route，以及 topic manifest 是否延后到下一阶段包边界。不要为了普通推进单独生成出口文档。

阶段包、硬边界、blocker / recovery 或 milestone 完成后，再自检本轮是否改变以下任一项：

- 主题当前状态。
- canonical tail / canonical endpoint。
- owner file。
- default draft。
- runtime input。
- current truth。
- stop-line。
- Same-shape Boundary Brake。
- current / 唯一 next opening。
- future radar / forbidden / deferred 结论。
- public allowlist。
- protected path policy。
- docs language / owner comment governance。

若任一项发生变化，先按 [P1 自动化文档预算治理](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-automation-documentation-budget-governance.md) 判断本轮是否只是普通推进、是否到达阶段包边界、是否触发硬边界或 blocker / recovery。普通推进可把 topic manifest 同步延后到下一次阶段包边界；阶段包边界、路线切换、硬边界或 blocker / recovery 应同步对应 `docs/plans/topic-manifests/<topic>.md`，若为保持执行窗口推进而暂缓，必须在 report / compact manifest 中写清延后理由和接续点。若主题不存在，在本轮 compact manifest、closure 或 automation report 中执行以下三选一：

- 新建 topic manifest。
- 把它作为 future radar 接入最接近的 topic manifest。
- 在 closure 中明确说明为何暂不建 manifest。

如果本轮没有改变主题状态、tail、owner、truth、stop-line 或 next opening，也可以不更新 topic manifest。普通推进只需在 automation report 中写明“topic manifest 延后到下一阶段包边界同步”，避免后续执行者误以为漏同步。

## 可复制的自检模板

后续 closure review、manifest stabilization、milestone closure、阶段性 reconciliation 或 automation report 可直接复制以下模板。普通推进可压缩为一段，不必为模板单独新建文档，也不要求完整条目齐全：

```text
设计意图出口自检：
- 本轮是否改变主题状态：是 / 否
- 本轮是否改变 canonical tail / endpoint：是 / 否
- 本轮是否改变 owner / truth / stop-line：是 / 否
- 本轮是否改变唯一 next opening：是 / 否
- 是否需要同步 topic manifest：是 / 否
- 已同步的 topic manifest：<path 或 none>
- 若未同步，理由：<reason；普通推进可写“延后到下一阶段包边界同步”>
```

## 阶段出口

每完成以下任一节点，建议开 docs-only reconciliation scan 或 compact manifest：

- branch milestone manifest。
- long chain manifest stabilization。
- 某条 Renderer / Runtime / AI-native 主线完成一个工程阶段包。
- `docs/plans/` 新增约 10 到 20 份普通 report，或用户明确感觉文档密度过高。
- README / GUI_TASK_TRACKER / topic manifest 的 next opening 出现不一致。
- 执行 AI 开始重复发明已有设计、遗漏 stop-line 或连续生成同构 blocker / value-boundary 文档。
- 用户明确感觉“文档太多、方向开始埋了”。

阶段 reconciliation scan 只允许：

- 检查 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)。
- 检查对应 topic manifest。
- 检查最新原文 manifest / closure。
- 修断链。
- 修状态滞后。
- 标记 superseded / deferred / forbidden。
- 纠正 next opening 不一致。
- 补缺失 topic manifest。

阶段 reconciliation scan 不允许：

- runtime code 修改。
- 技术路线变更。
- 新 implementation permission。
- 目录搬家。
- 删除历史文档。
- 改写旧 closure 结论。

## 同构文档刹车

如果连续两轮只是在重复同一个 stop-line、同一个 evidence absent、同一个 no-accessor / no-bridge-expansion 或同一个 value boundary 改名，不应继续生成同构 wrapper 或完整封账包。自动化应合并为 compact manifest、切换到真正新的证据路线，或按 blocker / recovery 明确请求人工决策。

## 周期出口

高频推进期间，建议每周、每完成一个工程阶段包，或每新增 10 到 20 份 plans，做一次 docs-only navigation reconciliation / compact manifest。

如果进入低频维护，不按时间强制，只在主题状态变化、用户要求或发现导航滞后时做。

当前不是自动归类系统。topic manifest 是人工 / AI 维护的设计意图地图。文件名匹配只能做辅助，因为 owner、truth、stop-line、forbidden / deferred 结论属于架构语义，不能完全自动判断。

未来可以引入半自动脚本检查未被 topic manifest 引用的新文档，但最终归类必须由 AI / 人确认。脚本不得自动改变主题状态、next opening 或 runtime truth。

## 与文档语言和 owner 注释治理的关系

本协议继承 [文档语言与 owner 注释风格护栏](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)：新增或修改 Markdown 必须使用中文正文和中文章节标题；英文只用于代码符号、文件路径、API 名称、工具命令和固定治理术语。

后续新增 `.cj` owner 文件仍需文件头维护注释，覆盖 Owner / Truth / Stop-line / Same-shape Boundary Brake。本协议只记录导航出口规则，不修改 runtime owner 注释。

## 本文档自身停止线

以下停止线只描述本文档作为 docs-only 治理协议时的自我约束，不是 Renderer 自动化阶段包的全局禁止清单。执行 AI 不应把本节误读为“所有后续任务都不能改 `.cj` / native / probe”。

- 本文档自身变更不修改任何 `.cj`。
- 本文档自身变更不新建 runtime owner。
- 本文档自身变更不运行 `cjpm build` / smoke。
- 本文档自身变更不触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 不移动、重命名或删除历史 plans 文档。
- 本文档自身变更不改变 Renderer 当前 next opening。
- 不把导航协议写成 runtime truth。
- 本文档自身变更不扩 public API。

## 后续维护规则

- 每个阶段包边界、硬边界或 blocker / recovery 主题状态变化都应有对应 topic manifest 同步；若为了减少阻塞暂缓同步，必须在 compact manifest / closure / automation report 中解释未同步理由和下一次同步触发点。
- 阶段 reconciliation scan 只修导航，不改技术路线。
- 周期出口是软规则，不制造机械负担；真正触发条件是主题状态变化、硬边界、导航滞后、同构文档膨胀或用户明确要求。
