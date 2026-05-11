# Drawable no-present acquisition 清单稳定化封账

日期：2026-05-11

## 稳定化内容

- 固定 manifest：[Drawable no-present acquisition 清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-drawable-no-present-acquisition-manifest.md)
- 固定 owner：[runtime_renderer_drawable_no_present_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_no_present_acquisition.cj)
- 固定 probe：[verify_native_bridge_drawable_no_present_acquisition.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_no_present_acquisition.sh)
- 固定 endpoint：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`
- 固定 default draft：`cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft()`
- 固定 runtime input：`CjguiInternalRendererNoDrawableVisibleWindowProbeReadiness`

## 证据口径

本 manifest 只承认 isolated visible-window no-present `nextDrawable` acquisition facts：

- bounded `nextDrawable` return observed。
- drawable acquired observed。
- drawable not saved / not returned observed。
- no present observed。
- no command queue / command buffer / encoder observed。
- no GPU submission / render observed。
- cleanup observed。

## 不改变的边界

- 不新增 production drawable C ABI。
- 不新增 drawable token table。
- 不创建 command queue / command buffer / encoder。
- 不 present。
- 不提交 GPU work。
- 不执行 render。
- 不写 renderer state。
- 不触碰 `runtime_state.cj`。
- 不新增 public API / diagnostics。
- 不返回 native pointer / handle / `id` / `Class`。
- 不把 no-present acquisition facts 包装成 backend-ready truth。

## 下游已接续

- 已由 [Command queue creation 路线封账清单](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-renderer-command-queue-creation-runway-manifest.md) 接续。
- 下游只承认 token-backed `MTLCommandQueue` create / destroy 与 runtime-local call facts。
- 下游仍不创建 command buffer，不调用 `commandBuffer`，不创建 encoder，不 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable no-present acquisition manifest 已稳定化。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 固定为 `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 no-present acquisition value owner；truth 只限 isolated acquisition facts；stop-line 不放宽。
- 本轮是否改变唯一 next opening：是，唯一 next opening 固定为 `P1 internal Renderer command queue creation planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
