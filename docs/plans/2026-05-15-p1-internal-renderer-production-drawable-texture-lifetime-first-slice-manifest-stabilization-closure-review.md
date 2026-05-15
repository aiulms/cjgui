# 生产 drawable texture lifetime 第一切片清单稳定化封账

## 封账结论

本轮已将 production drawable texture lifetime first slice 固定为 docs-only A 路线：刷新 blocker，不新增 production implementation。

这不是回退 no-submit milestone。No-submit branch 的 pipeline / shader / vertex / draw input facts 继续有效；只是 display 链仍缺 production drawable lifetime 的窗口、run loop、display backing、token table 与 cleanup co-ownership 证据。

## 已新增文档

- [preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-preflight-decision.md)
- [closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-internal-renderer-production-drawable-texture-lifetime-first-slice-stage-closure-review.md)
- [next-boundary](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-next-boundary-decision.md)
- [manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-production-drawable-texture-lifetime-first-slice-manifest.md)

## 已同步入口

- [README.md](/Users/jiangxuanyang/Desktop/cangjie/README.md)
- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [docs/plans/README.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md)
- [renderer-implementation-admission-chain.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [renderer-backend-readiness-real-backend-runway.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [macos-bridge-verification-smoke.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)

## 验证口径

本轮未修改 `.cj`、production native `.h/.m`、native scripts、`runtime/cjgui/cjpm.toml` 或 smoke native files，因此验证以 docs-only 扫描为主。

若后续 recovery 重新打开 production implementation，必须重新运行完整 build/probe 回归，并先证明 visible-window / run loop / cleanup 证据稳定。

## 当时唯一后续入口

`P1 internal Renderer drawable texture lifetime implementation recovery decision`

## 下游已接续

已由 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer visible-window production harness preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。first slice manifest 已稳定为 docs-only blocker refresh。
- 本轮是否改变 canonical tail / endpoint：否。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加 recovery-first 事实；stop-line 继续禁止 production `nextDrawable` 与 color attachment。
- 本轮是否改变唯一 next opening：是，当时转为 drawable texture lifetime implementation recovery decision；后续已由 recovery decision 接续并转为 visible-window production harness preflight decision。
- 是否同步 topic manifest：已同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
