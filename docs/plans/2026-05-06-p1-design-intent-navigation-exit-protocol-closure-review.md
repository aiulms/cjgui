# P1 设计意图导航出口协议封账复核

日期：2026-05-06

状态：docs-only / navigation governance closure / no runtime truth

## 收口结论

本轮完成 `P1 docs plans design intent navigation exit protocol bundle implementation`，新增设计意图导航出口协议：

- [2026-05-06-p1-design-intent-navigation-exit-protocol.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md)

该协议补齐即时出口、阶段出口和周期出口，要求每轮 gate / closure / manifest / milestone 完成后判断是否需要同步 topic manifest，并在需要时更新设计意图地图。

## 三层出口已建立

即时出口用于每轮完成后自检主题状态、canonical tail / endpoint、owner、default draft、runtime input、current truth、stop-line、Same-shape Boundary Brake、唯一 next opening、future radar / forbidden / deferred、public allowlist、protected path policy 和 docs governance 是否变化。

阶段出口用于 branch milestone、long chain stabilization、主线推进 5 到 10 轮、plans 增长 30 到 50 份、next opening 不一致、重复发明设计或用户感觉方向被埋时，开 docs-only reconciliation scan。

周期出口是软规则：高频推进期间每周或每新增 30 到 50 份 plans 做一次 docs-only navigation reconciliation；低频维护时只在主题变化、导航滞后或用户要求时做。

## 同步范围

本轮同步了以下导航入口：

- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [topic-manifests README](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/README.md)
- [docs language / comment governance topic manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/docs-language-comment-governance.md)
- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)

## 非自动归类结论

当前不是自动归类系统。topic manifest 是人工 / AI 维护的设计意图地图。文件名匹配只能辅助发现候选文档，不能自动判断 owner、truth、stop-line、forbidden / deferred 结论或 next opening。

未来若引入半自动脚本，只能检查未引用文档、断链或明显滞后；最终归类仍必须由 AI / 人确认。

## Renderer 路线保持

本轮不改变当前 Renderer next opening：

`P1 internal Renderer render execution implementation admission closure / next render execution implementation decision`

本轮不批准 render、GPU submission、command buffer、encoder、draw call、resource binding、renderer state write、public API 或 C ABI expansion。

## 设计意图出口自检

```text
设计意图出口自检：
- 本轮是否改变主题状态：是
- 本轮是否改变 canonical tail / endpoint：否
- 本轮是否改变 owner / truth / stop-line：否
- 本轮是否改变唯一 next opening：否
- 是否需要同步 topic manifest：是
- 已同步的 topic manifest：docs/plans/topic-manifests/docs-language-comment-governance.md
- 若未同步，理由：none
```

## 本轮停止线

- 未修改任何 `.cj`。
- 未新建 runtime owner。
- 未运行 `cjpm build` / smoke。
- 未触碰 `runtime_state.cj`、`runtime/cjgui/cjpm.toml`、smoke、harness、native bridge、entry、AGENTS / CLAUDE / CANGJIE_ISSUE_LEDGER。
- 未移动、重命名或删除历史 plans 文档。
- 未改变 Renderer 当前 next opening。
- 未把导航协议写成 runtime truth。
- 未扩 public API。

## 验证结果

本轮已按 docs-only 方式验证：

- `git diff --check`：通过。
- 新 exit protocol / closure no-index whitespace check：通过。
- Markdown absolute link missing target check：通过，范围限定 project docs scope，避开 `reference_repos/`。
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 能找到“出口机制”：通过。
- [topic-manifests README](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/README.md) 能找到“出口自检”：通过。
- README / GUI_TASK_TRACKER / docs/plans README / runtime README reachability 能找到 exit protocol 或设计意图导航出口说明：通过。
- Markdown 中文标题与中文正文抽查：通过。
- forbidden check：无 tracked `.cj` diff，无 protected path diff/status，`runtime_state.cj` 行数仍为 `10065`。
- public declaration scan：仍只能有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- GitNexus `detect_changes(scope=unstaged, repo=/Users/jiangxuanyang/Desktop/cangjie)`：low risk，affected processes 为空。

## 后续入口

保持本轮开始前的 Renderer 当前 next opening：

`P1 internal Renderer render execution implementation admission closure / next render execution implementation decision`
