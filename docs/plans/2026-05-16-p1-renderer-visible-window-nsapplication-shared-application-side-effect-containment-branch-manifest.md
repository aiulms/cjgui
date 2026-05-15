# P1 Renderer 可见窗口 NSApplication Shared-Application Side-Effect Containment 分支清单

状态：manifest / docs-only branch closure / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application side-effect containment branch closure / next application singleton accessor decision`。当前 branch sealed 为 side-effect containment evidence endpoint；actual application singleton accessor call 继续 blocked。

## 当前 endpoint

- Branch decision：[side-effect containment branch closure decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-side-effect-containment-branch-closure-next-application-singleton-accessor-decision.md)
- Branch closure：[side-effect containment branch closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-side-effect-containment-branch-closure-review.md)
- Branch next-boundary：[side-effect containment branch next-boundary decision](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-side-effect-containment-branch-next-boundary-decision.md)
- Manifest closure：[side-effect containment branch manifest stabilization closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-internal-renderer-visible-window-nsapplication-shared-application-side-effect-containment-branch-manifest-stabilization-closure-review.md)
- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationSideEffectContainmentEvidenceDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationHeadlessArtifactPolicyEvidenceReadiness`
- Upstream manifest：[side-effect containment stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-side-effect-containment-evidence-owner-stop-line-reconciliation-manifest.md)

## 事实边界

只承认 side-effect containment evidence readiness 足够封住 current evidence branch。当前 facts 仍是 side-effect containment evidence、accessor-call containment carry-forward、headless artifact policy evidence、actual accessor call blocked、no singleton accessor call、singleton creation blocked、actual teardown execution blocked、actual event loop blocked、bounded pump blocked、activation policy mutation blocked、activation blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public diagnostics、no public surface、no renderer state write 与 no backend-ready truth。

## 下游

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application singleton accessor admission preflight decision`

该 opening 只允许 fail-closed admission preflight，不允许 actual application singleton accessor call。

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 与拟新增 admission endpoint 返回 not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 已同步 current branch closure、truth、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 actual accessor call、application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write、public diagnostics 或 public API。
