# Drawable 可见窗口 probe 清单稳定化封账

## 封账范围

本 closure 固定 [Drawable 可见窗口 probe 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md) 的 owner、endpoint、probe、truth 与 stop-line。

## 稳定化结论

- Canonical endpoint：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableVisibleWindowProbeDraft()`
- Owner：[runtime_renderer_drawable_visible_window_probe.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_visible_window_probe.cj)
- Probe：[verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)
- Actual route：A，isolated visible-window environment probe。
- 下游接续：[Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- 当前唯一后续入口：`P1 internal Renderer command queue creation planning preflight decision`

## 验证摘要

最终验证执行记录在本轮收尾汇总中。本 closure 的语义结论不依赖伪造成功：若后续任一 full regression / forbidden scan 失败，本清单只保留为已实现但未完全放行的 recovery evidence，不升级为 drawable acquisition permission。

## 仍未获得的权限

- 没有 `nextDrawable` permission。
- 没有 present permission。
- 没有 command queue / command buffer / encoder permission。
- 没有 GPU submission 或 render permission。
- 没有 renderer state write permission。
- 没有 public API / diagnostics permission。
- 没有 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable visible-window probe 清单已稳定化。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 isolated visible-window probe owner；truth 只限 environment evidence；stop-line 继续禁止 drawable acquisition / present / command queue / GPU / render / state write。
- 本轮是否改变唯一 next opening：是；该 closure 当时转向 `P1 internal Renderer drawable no-present acquisition recovery/preflight decision`，现已由 no-present acquisition stage 接续，当前唯一 next opening 为 `P1 internal Renderer command queue creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
