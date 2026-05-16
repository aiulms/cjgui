# P1 Renderer 可见窗口 NSApplication Shared-Application Actual Accessor Side-Effect Audit 分支清单

状态：manifest / docs-only branch closure / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor side-effect audit branch closure / next actual accessor call decision`。当前 branch sealed 为 actual accessor side-effect audit endpoint；actual application singleton accessor call 继续 blocked。

## 当前 endpoint

- Branch decision：[actual accessor side-effect audit branch closure decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-closure-next-actual-call-preflight-decision.md)
- Branch closure：[actual accessor side-effect audit branch closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-closure-review.md)
- Branch next-boundary：[actual accessor side-effect audit branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-next-boundary-decision.md)
- Manifest closure：[actual accessor side-effect audit branch manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-branch-manifest-stabilization-closure-review.md)
- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationActualAccessorSideEffectAuditDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSingletonAccessorAdmissionReadiness`
- Upstream manifest：[actual accessor side-effect audit stop-line manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-actual-accessor-side-effect-audit-stop-line-reconciliation-manifest.md)

## 事实边界

只承认 actual accessor side-effect audit readiness 足够封住 current audit branch。当前 facts 仍是 actual accessor side-effect audit required、application singleton lifecycle side-effect risk classified、main-thread audit before accessor call required、headless fail-closed audit required、teardown-before-visible audit required、artifact / diagnostics non-publication audit required、rollback / cleanup evidence required、actual accessor call blocked、no singleton accessor call、singleton creation blocked、actual teardown execution blocked、actual event loop blocked、bounded pump blocked、artifact write blocked、artifact publication blocked、public diagnostics blocked、activation policy mutation blocked、activation blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public surface、no renderer state write 与 no backend-ready truth。

## 下游

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application actual accessor call preflight guard preflight decision`

该 opening 只允许 no-call preflight guard preflight，不允许 actual application singleton accessor call。

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 与拟新增 preflight guard endpoint 返回 not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 已同步 current branch closure、truth、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 actual accessor call、application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write、public diagnostics 或 public API。
