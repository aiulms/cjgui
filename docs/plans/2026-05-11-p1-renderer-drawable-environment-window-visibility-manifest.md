# Drawable 环境与窗口可见性清单

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`
- Upstream fixed input：`CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`

## Owner 文件

- [runtime_renderer_drawable_environment_visibility.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_environment_visibility.cj)

## 实际路线

本轮实际完成 A：

- A：environment / window visibility planning value boundary。

本轮未进入 B/C：

- 没有创建 isolated `NSWindow`。
- 没有调用 `nextDrawable`。
- 没有获取 drawable。
- 没有执行 no-present acquisition feasibility。

## Probe

- [verify_native_bridge_drawable_visible_window_environment.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_visible_window_environment.sh)

Probe 只做 planning consistency，固定：

- `drawable_environment_visibility_route=planning_only`
- `isolated_visible_window_probe_executed=false`
- `production_window_created=false`
- `visible_window_required=true`
- `main_thread_run_loop_required=true`
- `display_backed_layer_required=true`
- `bounded_no_present_probe_required=true`
- `next_drawable_called=false`
- `present_called=false`
- `command_buffer_created=false`
- `gpu_work_submitted=false`

## 固定事实

- Drawable recovery 上游已被接受。
- 可见 `NSWindow` / display-backed `CAMetalLayer` / bounded run loop 仍是 `nextDrawable` 前置证据。
- Production runtime 默认不创建 window。
- Isolated visible-window probe 如果后续新增，只能作为环境证据，不是 production runtime truth。
- `nextDrawable` 当前仍 blocked。
- Command queue 仍 blocked。
- Present 仍 forbidden。
- Environment facts 只作为 internal dehydrated facts，不是 backend-ready truth。

## 上游与下游指向

上游固定：

- [Drawable acquisition first implementation recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-first-implementation-manifest.md)
- [Drawable acquisition 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md)
- [Metal device binding 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)
- [Real drawable implementation admission 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)
- [Real drawable first implementation slice 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)

已接续下游：

- [Drawable 可见窗口 probe 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-visible-window-acquisition-probe-manifest.md)
- [render pass descriptor color attachment recovery 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-render-pass-descriptor-color-attachment-recovery-manifest.md)，只作为 environment prerequisite / blocker 证据，不升级为 production drawable texture lifecycle truth。
- [production drawable texture lifetime 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-production-drawable-texture-lifetime-manifest.md)，只作为 production visible window semantics 与 display-backed layer ownership 缺口证据，不升级为 production `nextDrawable` 或 drawable texture lifetime implementation truth。

当前唯一接续：

- `P1 internal Renderer drawable no-present acquisition recovery/preflight decision`

这些 upstream / downstream 指向只帮助导航，不改变 runtime truth；任何 visible window、display-backed layer、bounded run loop 或 no-present `nextDrawable` feasibility 都必须另开阶段证明。

## 停止线

不调用 `nextDrawable`，不获取 drawable，不调用 `present` / `presentDrawable`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 environment facts 解释成 drawable-ready 或 backend-ready truth。

## 唯一后续入口

`P1 internal Renderer drawable no-present acquisition recovery/preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition environment / window visibility planning 已封账。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning owner 与 planning consistency probe；truth 限 visible window / bounded run loop / display backing 前置需求 facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
