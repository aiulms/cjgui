# Pipeline state no-draw planning 后续边界判断

日期：2026-05-12

状态：next-boundary decision

## 判断

Pipeline state no-draw planning owner 已足够固定 shader/library/function requirement、pipeline descriptor requirement、pipeline state create deferred、encoder binding blocked、draw blocked 与 GPU submission blocked facts。

下一步不应直接创建 pipeline state，也不应进入 encoder binding。更安全的窄口是先拆 pipeline descriptor no-draw planning，确认 descriptor token / lifecycle / cleanup 是否能作为后续 pipeline state create / destroy 的前置合同。

## 候选比较

- A：`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`。推荐。继续 no-draw，只评估 descriptor planning / token / lifecycle 合同。
- B：`P1 internal Renderer pipeline state create/destroy no-draw preflight decision`。暂缓。缺 shader/library/function 与 descriptor lifecycle 证据。
- C：`P1 internal Renderer pipeline shader library no-draw preflight decision`。可作为后续分支，但当前 descriptor 合同更先阻塞 pipeline state creation。
- D：拒绝 direct encoder binding / draw / commit / present / GPU submission / render。

## 唯一后续入口

`P1 internal Renderer pipeline descriptor no-draw planning preflight decision`

## 下游接续

该入口已由 [pipeline descriptor no-draw manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-13-p1-renderer-pipeline-descriptor-no-draw-manifest.md) 接续并封账。当前最新 runtime tail 已迁移到 `CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft()`；唯一 next opening 已更新为 `P1 internal Renderer shader library no-draw planning preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，pipeline no-draw planning 后续边界已固定。
- 本轮是否改变 canonical tail / endpoint：否，仍以 `CjguiInternalRendererNoPipelineStateNoDrawPlanningReadiness` 为当前 tail。
- 本轮是否改变 owner / truth / stop-line：否，truth 仍为 no-draw planning facts；stop-line 仍禁止 encoder / draw / submit / render。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer pipeline descriptor no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
