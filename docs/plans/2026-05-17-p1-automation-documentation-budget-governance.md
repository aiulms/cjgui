# P1 自动化文档预算治理

日期：2026-05-17

状态：docs-only / automation governance / documentation budget / no runtime truth

## 文件定位

本文件补充 [P1 设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)，用于约束自动化执行期间的文档产量。目标不是降低安全性，而是避免把安全边界写成机械流水账。

本文件不是 runtime truth，不改变 Renderer 当前 technical next opening，不授权 production native implementation、public API、public C ABI、renderer state write、`runtime_state.cj` 修改或 `runtime/cjgui/cjpm.toml` 修改。

## 核心判断

文档的职责是帮助复核、导航和保存不可丢失的架构判断。文档不应成为每个微小步骤的仪式成本。

自动化执行必须继续保留：

- stop-line。
- owner / truth / endpoint / runtime input。
- 验证证据。
- GitNexus 覆盖缺口。
- protected path 与 public surface 自检。
- 唯一 next opening。

但普通阶段不再默认生成 decision、closure、next-boundary、manifest、manifest closure 五件套。

## 文档预算分档

### D0：无新增治理文档

适用场景：

- 只做缺失链接修复、final newline 修复、错别字修复或 report 可达性修复。
- 没有改变 endpoint、truth、stop-line、next opening、owner 或验证结论。
- 现有 automation report 已足够承载本轮结果。

要求：

- 可直接在最终报告中说明修复内容和验证结果。
- 不新增同构 blocker 文档。
- 不扩写 topic manifest。

### D1：普通自动化阶段

适用场景：

- internal value owner、owner probe、no-op / no-accessor / no-bridge-expansion facts。
- 不扩大 authority，不改 public surface，不改 protected path。
- 只是把已批准 runway 内的一步落成可验证 facts。

允许文档：

- 只新增一份 `automation-stage-report-N.md` 作为本阶段原文记录。
- 可做最小导航指针更新：`GUI_TASK_TRACKER.md` 的 latest report / next opening、必要的 README 最新入口、必要的 DESIGN_INTENT_INDEX 最新摘要。此类更新只允许替换最新指针或短摘要，不允许堆叠逐轮长流水。

该 report 必须包含：

- 完成内容。
- endpoint / default draft / runtime input。
- stop-line。
- 验证结果。
- GitNexus 结果或覆盖缺口。
- 唯一 next opening。
- 是否需要人工介入。

默认不新增独立治理文档：

- preflight decision。
- closure review。
- next-boundary decision。
- manifest。
- manifest closure。

D1 的关键是“少造新文档”，不是“禁止维护最新入口”。如果不更新 tracker 会导致新自动化线程丢失唯一 next opening，应做最小指针更新。

### D2：阶段小封账

适用场景：

- 3 到 5 个连续 D1 阶段形成一个清晰小里程碑。
- 一个 probe / owner / runtime call 小链条完成，后续需要稳定入口。
- README、tracker 或 topic manifest 已经难以只靠 report 表达当前状态。

允许文档：

- 一份 automation report。
- 一份 compact manifest。

compact manifest 应只写：

- 当前 tail。
- current truth。
- stop-line。
- 验证摘要。
- 唯一 next opening。
- upstream / downstream 关键链接。

不再额外拆 closure、next-boundary、manifest closure，除非触发 D3。

### D3：硬边界完整封账包

只有以下情况才允许完整五件套：

- authority / truth / stop-line 明确扩张。
- 新增或改变 public API / public C ABI。
- 修改 `runtime_state.cj`、`runtime/cjgui/cjpm.toml` 或其他 protected path。
- 首次引入新的 production native call site 权限族，或把原本 evidence-only / probe-only / no-op 路线升级为 production truth。
- 首次打开新的 `NSApplication.sharedApplication`、visible `NSWindow`、`nextDrawable`、`present`、`commit`、render encoder、draw、GPU submission 或 renderer state write 权限族。
- GitNexus / source review 判断存在 HIGH / CRITICAL 或同等高风险。
- 用户明确要求人工审计级封账。

允许文档：

- preflight / decision。
- closure review。
- next-boundary decision。
- manifest。
- manifest closure。
- automation report。

要求：

- 写清楚为什么本轮不是 D1 / D2。
- 写清楚新增权限的最小范围。
- 写清楚仍禁止什么。

如果某个权限族已经经过 D3 封账，后续仍在同一批准范围内补 owner、probe、回归验证、internal facts 或小修复，不自动再次升级为 D3；应按 D1 / D2 处理。只有权限范围、truth、stop-line 或 side effect 面扩大时，才重新进入 D3。

### D4：blocker / recovery

适用场景：

- 发现证据缺口、环境缺口、GitNexus 覆盖缺口或路线不可行。
- 需要把主线切到 recovery / alternative route。

允许文档：

- 一份 blocker / recovery decision 或 automation report。
- 若路线真正切换，再补一份 compact manifest。

禁止：

- 连续生成多个同构 blocker 文档。
- 为同一个缺口重复生成 preflight、closure、next-boundary、manifest、manifest closure。

## 同构文档刹车

如果连续两轮只是在重复以下内容：

- 同一个 stop-line。
- 同一个 no-accessor / no-bridge-expansion。
- 同一个 evidence absent。
- 同一个 next opening 卡点。
- 同一个 value boundary 事实改名。

自动化必须停止制造新同构文档，并在下一轮三选一：

- 合并为一个 D2 compact manifest。
- 进入真正新的证据路线。
- 明确标记 blocker 并请求人工决策。

## 索引更新节流

索引仍要可达，但不再要求每个 D1 阶段扩写所有导航文件。

规则：

- `GUI_TASK_TRACKER.md` 只保留最新 tail、关键 blocker、当前 next opening 和最近一个 milestone。
- `docs/plans/README.md` 只保留最新 automation report 和必要的阶段摘要，不逐条堆叠所有 D1。
- `DESIGN_INTENT_INDEX.md` 只记录主题级状态和关键里程碑，不复制每个 report 的 truth 全文。
- topic manifest 只在 D2 / D3 / D4 路线切换时同步；D1 阶段可在下一个 compact manifest 中批量接入。
- 本规则不要求立即清理历史长列表；历史长列表可以保留为档案。新的自动化阶段不得继续扩写同样的长流水。

如果自动化不确定是否需要同步 topic manifest，优先选择：

- 不扩写长流水。
- 在 automation report 中写明“本轮按 D1 执行，topic manifest 延后到下一 D2 / D3 同步”。

## 验证预算不降低

减少文档不等于减少验证。

代码 / native / script 有变更时，仍需按风险运行：

- 对相关符号做 GitNexus impact；未索引要记录 UNKNOWN / not found，并用源码、build、probe、scan 兜底。
- `git diff --check`。
- 相关 build / probe / smoke。
- public declaration scan。
- protected path scan。
- forbidden native / bridge / renderer-state scan。
- `gitnexus detect-changes --repo cangjie-live-codelattice --scope unstaged` 或对应范围。

docs-only 阶段可不跑 build / smoke，但必须说明理由。

## 自动化执行口径

自动化线程应按“阶段包”推进，而不是按单个文档推进。

默认策略：

- 1 小时内尽量连续推进同一阶段包。
- 普通阶段按 D1 只写 report。
- 每 3 到 5 个 D1 或到达清晰 milestone 后写 D2 compact manifest。
- 只有触发硬边界才进入 D3。
- blocker 只写一次 D4，不重复造同构文档。
- 每轮结束必须让 tracker 或最新 report 至少有一个可靠入口能指向下一轮唯一 next opening；否则新自动化线程会丢上下文。

自动化不应因为没有完整五件套就停止。真正需要停止的情况是：

- 硬边界需要人工选择。
- 验证失败且不能自动恢复。
- GitNexus / source review 给出 HIGH / CRITICAL 且需要用户确认。
- 用户明确要求停。

## 本轮停止线

- 不修改 `.cj`。
- 不修改 native source / native scripts。
- 不修改 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不新增 runtime owner。
- 不新增 public API / public C ABI。
- 不 stage / commit / push。
- 不把本文档解释为任何 implementation permission。
