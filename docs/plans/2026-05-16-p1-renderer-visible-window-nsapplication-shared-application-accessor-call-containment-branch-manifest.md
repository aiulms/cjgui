# P1 Renderer 可见窗口 NSApplication Shared-Application Accessor Call Containment 分支清单

状态：manifest / docs-only branch closure / no runtime truth

## 阶段摘要

本 manifest 封账 `P1 internal Renderer visible-window production harness NSApplication shared-application accessor call containment branch closure / next accessor call decision`。当前 branch sealed 为 no-call containment endpoint；actual application singleton accessor call 继续 blocked。

## 当前 endpoint

- Runtime owner：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyDraft()`
- Runtime input：`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentReadiness`
- Upstream manifest：[containment stop-line reconciliation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-accessor-call-containment-stop-line-reconciliation-manifest.md)

## 事实边界

只承认 containment policy readiness 足够封住 current no-call branch。当前 facts 仍是 actual accessor call blocked、no singleton accessor call、singleton creation blocked、main-thread gate required、bounded run loop required、auto-close required、teardown before visible required、non-user-visible required、application side effect blocked、activation policy mutation blocked、activation blocked、event loop blocked、native visible order blocked、production drawable blocked、render blocked、no pointer / handle / `Class` / `id` return、no public surface、no renderer state write 与 no backend-ready truth。

## 下游

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application cleanup / headless safety preflight decision`

该 opening 只允许 cleanup co-ownership、headless fail-closed、CI artifact policy、main-thread ownership 与 teardown proof 的 internal value boundary preflight。

## GitNexus 结果

GitNexus 对当前 endpoint / default draft 返回 not found / UNKNOWN / 0 impacted，`context` 也未找到当前 symbol。该结果只说明近期新增符号未被索引覆盖，不能作为安全证明；本阶段以 source reading、manifest reachability、forbidden scan、protected path scan 与 `detect-changes` 兜底。

## 设计意图出口自检

- 本 manifest 已同步 current branch closure、truth、stop-line 与 next opening。
- topic manifest / README / tracker / design intent index 需要同步本 manifest。
- Same-shape Boundary Brake：本 manifest 不授权 actual accessor call、application-ready、visible-ready、drawable-ready、backend-ready、render-ready、GPU submission、renderer state write 或 public API。
