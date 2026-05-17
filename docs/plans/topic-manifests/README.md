# 主题 manifest 导航

状态：docs-only / topic navigation / no runtime truth

## 文件定位

本目录保存 `docs/plans/` 的主题级导航 manifest。它们用于把分散在历史 preflight、manifest、closure review 和 milestone 里的设计意图压缩为可维护入口。

这些文件不替代 [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)，不替代具体原文，不改变 Renderer 当前 next opening，也不授予 runtime implementation permission。

## 完成 gate / closure 后的出口自检

每轮 gate、closure、manifest 或 milestone 完成后，应按 [设计意图导航出口协议](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-design-intent-navigation-exit-protocol.md) 执行出口自检。

自动化执行期间还应按 [P1 自动化文档预算治理](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-17-p1-automation-documentation-budget-governance.md) 节流同步：D1 普通阶段不要求每轮改 topic manifest，可在下一份 D2 compact manifest 或 D3 hard gate 中批量接入；D3 hard gate、D4 路线切换、public surface / protected path / stop-line 扩张仍必须同步。

D2 / D3 / D4 若改变以下任一项，就必须同步对应 topic manifest；D1 普通阶段可在 automation report 中说明延后同步：

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

topic manifest 不要求每轮机械更新；但 D2 / D3 / D4 若改变状态、tail、stop-line 或 next opening，就必须更新。若 D1 判断不需要同步，automation report 应写明“延后到下一 D2 / D3 同步”。

## 主题入口

- [Renderer backend readiness / real backend runway](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md)
- [Renderer implementation admission chain](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/renderer-implementation-admission-chain.md)
- [Runtime / Queue / Action Router](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/runtime-queue-action-router.md)
- [macOS bridge / verification / smoke](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/macos-bridge-verification-smoke.md)
- [AI-native semantic / action gateway](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/ai-native-semantic-action-gateway.md)
- [Foreign surface / pluggable browser engine intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/foreign-surface-browser-engine-intake.md)
- [Docs language / comment governance](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/topic-manifests/docs-language-comment-governance.md)

## 关键原文集合

下列原文是本目录当前覆盖的主题锚点。维护者更新主题状态时，应优先更新对应 topic manifest，而不是扩写本 README 成长列表。

- [renderer backend readiness branch milestone](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-renderer-backend-readiness-branch-milestone-manifest.md)
- [renderer native resource bridge manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-renderer-native-resource-bridge-manifest.md)
- [renderer draw call implementation admission manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-draw-call-implementation-admission-manifest.md)
- [renderer render execution implementation preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-render-execution-implementation-preflight-decision.md)
- [renderer render execution implementation admission closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-internal-renderer-render-execution-implementation-admission-value-boundary-closure-review.md)
- [runtime internal tail milestone](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-runtime-internal-tail-milestone-manifest.md)
- [Action Router manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-30-p1-action-router-manifest.md)
- [experimental public submit shell milestone](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-01-p1-experimental-public-submit-shell-milestone-manifest.md)
- [macOS bridge smoke closure](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p0-macos-bridge-smoke-closure-review.md)
- [automated GUI verification preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-25-p1-automated-gui-verification-preflight.md)
- [Scene / Renderer input manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-scene-renderer-input-manifest.md)
- [RenderCommand material / batching hint manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-02-p1-render-command-material-batching-hint-manifest.md)
- [AI-native operability / foreign surface intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-04-p1-ai-native-operability-foreign-surface-risk-intake.md)
- [AI-native generated UI / semantic UI spec north-star intake](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-ai-native-generated-ui-semantic-spec-north-star-intake.md)
- [AI Action Protocol workflow / EDN-like grammar correction note](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-ai-action-protocol-workflow-edn-like-grammar-correction-note.md)
- [doc language guard stabilization](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-05-p1-doc-language-comment-style-guard-stabilization.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)

## 维护备注

- 新主题出现时，优先新增一个 topic manifest，并从 [DESIGN_INTENT_INDEX.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/DESIGN_INTENT_INDEX.md) 链入。
- 主题状态变化时，只同步主题摘要、关键原文链、当前 endpoint 和禁止误读点。
- 每轮 closure / automation report 若不需要同步 topic manifest，应记录“设计意图出口自检”并说明理由；D1 阶段可延后到下一 D2 / D3。
- 不移动历史 plans，不重排目录结构，不把 topic manifest 变成新的 runtime truth。
