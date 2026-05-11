# Drawable acquisition first implementation recovery 清单

## 固定尾点

- Endpoint：`CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`
- Default draft：`cjguiInternalExecuteDefaultRendererDrawableAcquisitionRecoveryDraft()`
- Runtime input：`CjguiInternalRendererNoDrawableAvailabilityReadiness`
- Upstream fixed input：`CjguiInternalRendererNoDrawableAvailabilityReadiness`

## Owner 文件

- [runtime_renderer_drawable_acquisition_recovery.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_recovery.cj)

## 实际路线

本轮实际完成 A：

- A：recovery/preflight only，固定 no-acquire blocker facts。

本轮未进入 B/C：

- 没有调用 `nextDrawable`。
- 没有获取 drawable。
- 没有创建 drawable token table。
- 没有执行 no-present acquisition feasibility。

## Probe

- [verify_native_bridge_drawable_acquisition_recovery.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_recovery.sh)

Probe 复核 token-backed `NSView` / `CAMetalLayer` / `MTLDevice` attach-bind-cleanup 路径，并固定：

- `drawable_acquisition_recovery=-150`
- `command_queue_still_blocked=-129`
- `visible_window_evidence=false`
- `display_backed_layer_evidence=false`
- `next_drawable_called=false`
- `present_called=false`
- `command_buffer_created=false`
- `gpu_work_submitted=false`

## 固定事实

- Drawable availability 上游已被接受。
- `nextDrawable` first implementation 当前被环境 / visibility / non-blocking 证据缺口阻断。
- Current production bridge 无可见 `NSWindow` / `NSApplication` 创建路径。
- Token-backed layer / device binding cleanup 可回零，但不证明 display-backed drawable availability。
- Command queue 仍 blocked。
- Present 仍 forbidden。
- Recovery facts 只作为 internal dehydrated facts，不是 backend-ready truth。

## 上游与下游指向

上游固定：

- [Drawable acquisition 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-acquisition-runway-manifest.md)
- [Metal device binding runway 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-metal-device-binding-runway-manifest.md)
- [CAMetalLayer runtime attachment FFI call owner 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-runtime-attachment-ffi-call-owner-manifest.md)
- [CAMetalLayer NSView attachment 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-cametallayer-nsview-attachment-manifest.md)
- [Real drawable implementation admission 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-06-p1-renderer-real-drawable-implementation-admission-manifest.md)
- [Real drawable first implementation slice 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-08-p1-renderer-real-drawable-first-implementation-slice-manifest.md)
- [Native token issue/revoke 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-issue-revoke-manifest.md)
- [Native bridge teardown admission implementation 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-bridge-teardown-callable-implementation-manifest.md)

下游唯一接续：

- `P1 internal Renderer drawable acquisition environment/window visibility planning decision`

该入口已由 [drawable environment / window visibility planning manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-environment-window-visibility-manifest.md) 接续。当前下游 canonical endpoint 是 `CjguiInternalRendererNoDrawableEnvironmentVisibilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableEnvironmentVisibilityDraft()`；该接续仍不调用 `nextDrawable`，只固定 window visibility、main-thread run loop、display backing 与 no-present planning facts。

这些 upstream / downstream 指向只帮助导航，不改变 runtime truth；任何 visible window、display-backed layer、run loop 或 `nextDrawable` feasibility 都必须另开阶段证明。

## 停止线

不调用 `nextDrawable`，不获取 drawable，不调用 `present` / `presentDrawable`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不修改 smoke native files，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`，不把 recovery facts 解释成 drawable-ready 或 backend-ready truth。

## 唯一后续入口

`P1 internal Renderer drawable acquisition environment/window visibility planning decision`

该入口已完成接续，当前推荐下一步转为 `P1 internal Renderer drawable visible-window acquisition probe recovery/preflight decision`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition first implementation 已封账为 recovery / preflight only。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 recovery owner 与 recovery probe；truth 限环境 / visibility / non-blocking blocker facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，唯一 next opening 为 `P1 internal Renderer drawable acquisition environment/window visibility planning decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
