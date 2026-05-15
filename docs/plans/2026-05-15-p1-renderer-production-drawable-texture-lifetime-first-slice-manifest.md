# 生产 drawable texture lifetime 第一切片清单

## 清单状态

状态：docs-only / blocker refresh / no production drawable lifetime implementation

本清单固定 production drawable texture lifetime first slice 的 A 路线封账结果：本轮只刷新 blocker，不实现 token-backed drawable acquire / classify / release。

## 上游

- no-submit branch milestone：[2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-no-submit-render-pipeline-branch-milestone-manifest.md)
- 旧 planning tail：`CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`
- isolated evidence：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness` 与 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`

## 当前 endpoint

本轮未新增 endpoint。

Drawable lifetime planning tail 仍是 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness` / `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft()`。

No-submit milestone tail 仍是 `CjguiInternalRendererNoDrawInputBundleReadiness` / `cjguiInternalExecuteDefaultRendererDrawInputBundleDraft()`。

## runtime owner

本轮未新增 runtime owner。

明确未新增：

- `runtime_renderer_drawable_texture_lifetime_first_slice_planning.cj`
- `runtime_renderer_drawable_texture_lifetime.cj`
- `runtime_renderer_drawable_texture_lifetime_runtime_call.cj`

## native callable

本轮未新增 production native callable。

明确未新增：

- drawable acquire callable
- drawable classify callable
- drawable release callable
- drawable double-release classify callable
- drawable occupied count callable

## 当前 truth

- first slice implementation 仍 blocked。
- isolated visible-window no-present acquisition 仍是 probe evidence。
- production visible-window ownership 尚未建立。
- production bounded run loop / display-backed layer ownership 尚未建立。
- production drawable token table 尚未建立。
- production drawable release / stale / double release fail-closed classification 尚未建立。
- descriptor / drawable / layer / device / view cleanup co-ownership 尚未证明。

## stop-line

- 不调用 production `nextDrawable`。
- 不 present。
- 不创建 command buffer / encoder。
- 不调用 `commit`。
- 不提交 GPU work。
- 不执行 render。
- 不配置 render pass descriptor color attachment。
- 不新增 public API / diagnostics。
- 不返回 pointer / handle / `id` / `Class`。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。

## 当时唯一后续入口

`P1 internal Renderer drawable texture lifetime implementation recovery decision`

## 下游已接续

已由 [drawable texture lifetime implementation recovery manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-15-p1-renderer-drawable-texture-lifetime-implementation-recovery-manifest.md) 接续。当前唯一后续入口转为：

`P1 internal Renderer visible-window production harness preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是。production drawable texture lifetime first slice 已封为 blocker refresh。
- 本轮是否改变 canonical tail / endpoint：否。没有新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 增加 first-slice blocked facts；stop-line 保持 no production `nextDrawable`。
- 本轮是否改变唯一 next opening：是。当时转为 drawable texture lifetime implementation recovery decision；后续已由 recovery decision 接续并转为 visible-window production harness preflight decision。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
