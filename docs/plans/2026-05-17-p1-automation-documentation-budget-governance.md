# P1 自动化文档预算治理

日期：2026-05-17

状态：docs-only / automation governance / execution-first / no runtime truth

## 文件定位

本文件补充 [P1 设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)，用于给自动化执行设置“少写文档、多推工程证据”的默认口径。

它不是 runtime truth，不授权 production native implementation、public API、public C ABI、renderer state write、`runtime_state.cj` 修改或 `runtime/cjgui/cjpm.toml` 修改。

## 核心口径

自动化窗口的目标是推进一个可复核的工程阶段包，不是完成一个小 owner、一个小 probe 或一份 report 后停止。

默认策略：

- 在当前 stop-line 内自主推进，直到形成阶段包、时间接近结束，或遇到硬边界。
- `next opening` 是路线种子，不是微步骤牢笼；如果它过窄或已经同构，自动化应在同一 stop-line 内选择更有证据增量的相邻落刀点。
- 先执行、验证、再写压缩文档；不要先写多层预检文档再落代码。
- 文档服务工程记忆，不反过来切碎执行节奏；留痕必须有，但默认写成阶段摘要，不写成每个微动作的流水账。
- 一个自动化时间窗口默认产出一个阶段 report；窗口内连续完成多个相邻小切片时，应合并写在同一 report 中，而不是每个小切片单独停止。
- 能用一份 report 讲清的普通推进，不拆成多份 decision / closure / manifest。
- 若连续两轮都只是在证明同一组 no-accessor / no-bridge / no-runtime-execution facts，下一轮必须换证据路线或写 blocker / recovery，不继续包壳。

工程阶段包通常应该有真实增量，例如 owner + probe、native / runtime-adjacent evidence、build / link 支撑、failure classification、环境约束验证、回归验证范围扩大，或能消除 blocker 的 source / probe / build 证据。单个小文件或单份 report 通常不算完整阶段包。

## 上下文加载

新线程默认只读最小入口：

- `AGENTS.md`
- `README.md`
- `GUI_TASK_TRACKER.md`
- 本治理文档
- `docs/plans/DESIGN_INTENT_INDEX.md`
- 必要时再读 `docs/plans/README.md` 的最新段落和对应 topic manifest

不要为了“熟悉环境”全量阅读历史 plans。只有遇到冲突、缺证据、越边界或需要追溯 owner / truth / stop-line 时，才读取具体 manifest / closure 原文。

README、tracker、runtime README、DESIGN_INTENT_INDEX 中的长历史块是 archive / evidence map，不是自动化默认必读清单。新线程应先抓当前 tail、当前 stop-line、当前 next route、最近 report / compact manifest；历史长链只在判断冲突、风险或路线来源时按需追溯。

## 文档预算

普通推进：

- 写一份 `automation-stage-report-N.md`，可覆盖一个时间窗口内的多个相邻小切片。
- 最小同步 README / tracker / plans README / DESIGN_INTENT_INDEX 的 latest report 与 next opening。
- topic manifest 可延后到下一阶段包边界。

阶段包边界：

- 写一份 compact manifest，记录 tail、truth、stop-line、验证摘要、下一条 route 和关键链接。
- 批量同步 topic manifest，避免逐轮长流水。
- 如果当前 next opening 只是 `topic navigation reconciliation` 或同类文档整理，而没有真实路线冲突、硬边界、blocker 或用户明确要求，自动化可以把它作为同一时间窗口内的 housekeeping：做最小一致性检查，写入本轮 report / compact manifest，然后继续选择下一条工程证据路线，不应只完成 housekeeping 就停止。

硬边界或用户要求人工审计：

- 才写完整 decision / closure / next-boundary / manifest / manifest closure。

如果普通推进已经写了 report，不要再为了同一结论补同构 decision / closure / next-boundary / manifest。只有当路线、truth、owner、stop-line、public surface 或 protected path 真的发生阶段性变化时，才升级文档形态。

## 自主推进与硬边界

硬边界以外，若仍在当前 stop-line 内，默认允许自动化继续推进，不需要把“继续”解释成人工批准。

必须停下并要求明确 decision / approval 的硬边界：

- 修改 `runtime/cjgui/src/runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。
- 新增或改变对外稳定 public API / public C ABI。
- 未被当前路线和 stop-line 批准的 production native bridge callable surface 扩张。若当前阶段已经明确允许 internal / probe / route-scoped native bridge callable 增量，可在同一 stop-line 内继续推进，但必须用 probe / scan / report 留痕。
- 新增 production `NSApplication.sharedApplication` actual accessor call site，或把 isolated / probe evidence 升级为 production singleton ownership truth。
- visible `NSWindow` / visible order。
- `nextDrawable`。
- render encoder / draw / commit / present / GPU submission。
- renderer state write。
- GitNexus / source review 出现 HIGH / CRITICAL 或同等高风险。

## 停止条件

自动化不应因普通小步骤完成而停。合理停止条件只有：

- 时间窗口接近结束。
- 已完成一个可复核阶段包。
- 下一步越过硬边界且当前文档未批准。
- 验证失败且不能自动恢复。
- 没有新证据路线，必须进入 blocker / recovery。
- 用户明确要求停止。

若停止，report 只需写清：完成了什么、为什么停、下一条 route、是否需要人工介入。

## 验证底线

减少文档不等于减少验证。代码、native 或 script 有变更时，仍需按风险运行 GitNexus impact / detect-changes、`git diff --check`、相关 build / probe / smoke、public declaration scan、protected path scan 与 forbidden scan。GitNexus 返回 UNKNOWN / not found 时，不能当作安全证明，必须用源码、build、probe、scan 兜底并写入 report。

docs-only 阶段可不跑 build / smoke，但必须说明理由。

验证按风险分层，不要求每轮机械跑满：

- docs-only：`git diff --check`、链接 / reachability、public allowlist、protected path、GitNexus detect-changes。
- runtime owner / script / probe：focused owner probe 或新增 probe、`cjpm build --skip-script`、public / protected / forbidden scans、GitNexus impact / detect-changes。
- native bridge / platform object / Metal-AppKit 相关：新增或受影响 native probe、相关回归 probe、skeleton / symbol / package-link 边界脚本、build、必要 smoke。
- 阶段包或 hard boundary 前：扩大回归范围，记录环境不可用与代码 blocker 的区别。
