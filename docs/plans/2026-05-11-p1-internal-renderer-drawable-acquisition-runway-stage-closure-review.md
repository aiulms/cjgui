# Drawable acquisition 路线阶段收束复核

## 实际路线

本轮完成 A/B，未进入 C。

- A：新增 drawable acquisition planning owner，接受 Metal device layer binding evidence，并固定 main-thread drawable gate、no-present path、command queue / buffer before render prerequisite 与 no-`nextDrawable` facts。
- B：新增 drawable availability owner，调用既有 fail-closed callable，观察 drawable acquisition 与 command queue 仍 blocked。
- C：未执行 `nextDrawable`，未获取 drawable，未创建 token-local drawable table，也未做 immediate-release feasibility。

## 实际写集

- 新增 [runtime_renderer_drawable_acquisition_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_planning.cj)。
- 新增 [runtime_renderer_drawable_availability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_availability.cj)。
- 新增 [verify_native_bridge_drawable_acquisition_planning.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_planning.sh)。
- 新增本阶段 preflight、closure、next-boundary、manifest 与 manifest closure 文档。

本轮没有修改 production native `.h` / `.m`、`runtime/cjgui/cjpm.toml`、smoke native files 或 `runtime_state.cj`。

## 当前事实

- Canonical endpoint 固定为 `CjguiInternalRendererNoDrawableAvailabilityReadiness` / `cjguiInternalExecuteDefaultRendererDrawableAvailabilityDraft()`。
- Planning owner runtime input 是 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness`。
- Availability owner runtime input 是 `CjguiInternalRendererNoDrawableAcquisitionPlanningReadiness`。
- Probe 观察 `drawable_acquisition_still_blocked=-150`、`command_queue_still_blocked=-129`、`binding_main_thread_required=-141`。
- Probe 明确输出 `next_drawable_called=false`、`present_called=false`、`command_buffer_created=false`、`gpu_work_submitted=false`。

## 验证摘要

- [verify_native_bridge_drawable_acquisition_planning.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_planning.sh) 已通过。
- 既有回归探针已通过：Metal device binding / create-destroy / availability，CAMetalLayer runtime attachment / attach-detach / create-destroy / object table / allocation / no-attach，NSView runtime call / create-destroy / object table / feasibility / no-object creation，AppKit import / class / main-thread，teardown，token issue-revoke，no-resource call，isolated FFI，package link，cjpm package link，skeleton compile，symbol probe，cjpm boundary。
- `cjpm build --target-dir /tmp/cjgui-renderer-drawable-acquisition-runway-target --skip-script` 已通过，只有既有 unused warning。
- `labs/macos_bridge_smoke/scripts/verify_auto_close.sh` 已通过。
- `git diff --check`、runtime/native/script/docs whitespace check、Markdown absolute link check、README / tracker / plans README / runtime README reachability、中文标题正文抽查均已通过。
- Protected path scan 确认 `runtime/cjgui/src/runtime_state.cj` 仍为 `10065` 行。
- Comment-aware public declaration scan 仍只允许 `cjguiExperimentalQueueSubmitShellReady(): Bool`。
- Native forbidden scan 确认 production bridge 没有 `nextDrawable`、present、command queue / buffer / encoder、GPU submission、render、pointer return 或 public API。
- GitNexus `detect_changes(scope=unstaged)` 记录为 low，affected processes 为 0。

## 停止线复核

本轮没有调用 `nextDrawable`，没有 present，未创建 command queue / command buffer / encoder，未提交 GPU work，未执行 render，未写 renderer state，未触碰 `runtime_state.cj`，未返回 pointer / handle / `id` / `Class`，未新增 public API / diagnostics。

## 下游接续

本 closure 的唯一后续入口已由 [Drawable acquisition first implementation recovery 阶段复核](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-11-p1-internal-renderer-drawable-acquisition-first-implementation-recovery-closure-review.md) 接续。下游新增 `CjguiInternalRendererNoDrawableAcquisitionRecoveryReadiness`，但仍保持 no-`nextDrawable`、no-present、no-command-queue、no-render 与 no-state-write stop-line。

## 设计意图出口自检

- 本轮是否改变主题状态：是，drawable acquisition route 已从 next opening 进入 A/B 封账。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoDrawableAvailabilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增两个 owner 与一个 probe；truth 限 no-acquire / still-blocked dehydrated facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
