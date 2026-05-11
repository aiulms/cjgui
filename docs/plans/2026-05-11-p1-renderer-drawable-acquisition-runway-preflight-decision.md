# Drawable acquisition 路线预检结论

## 上游证据

本轮从 `CjguiInternalRendererNoMetalDeviceLayerBindingReadiness` / `cjguiInternalExecuteDefaultRendererMetalDeviceLayerBindingDraft()` 接续。上游已经固定 token-backed `MTLDevice` lifecycle、token-backed `CAMetalLayer.device` bind / unbind、drawable acquisition still blocked、command queue still blocked、no public surface、no renderer state write 与 no backend-ready truth facts。

GitNexus impact 对上游 endpoint 与 default draft 均返回近期新增 symbol 未索引 / not found，affected count 为 0，risk 记为 UNKNOWN。本轮按源码读取、`cjpm build`、native probe 与 forbidden scan 兜底。

## 路线判断

本轮选择 A/B，不进入 C：

- A：新增 drawable acquisition planning internal owner，只表达 no-acquire planning facts。
- B：新增 drawable availability / still-blocked internal owner，复用既有 fail-closed C ABI 观察 `drawable acquisition still blocked` 与 `command queue still blocked`。
- C：暂不执行 token-local `nextDrawable` acquisition feasibility。

选择 A/B 的原因是 `nextDrawable` 依赖稳定 layer / device / display 环境。当前还没有 command queue、command buffer、present、drawable cleanup 与 headless / CI-like shell 稳定性证据；如果此时直接调用 `nextDrawable`，容易把 availability facts 误包装成 drawable-ready 或 render-ready truth。

## 批准写集

- 允许新增 [runtime_renderer_drawable_acquisition_planning.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_acquisition_planning.cj)。
- 允许新增 [runtime_renderer_drawable_availability.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_availability.cj)。
- 允许新增 [verify_native_bridge_drawable_acquisition_planning.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_drawable_acquisition_planning.sh)。
- 不修改 production native `.h` / `.m`。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。

## 继续保持的停止线

本轮不调用 `nextDrawable`，不获取 drawable，不调用 `present` / `presentDrawable`，不创建 command queue / command buffer / encoder，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 Metal device layer binding tail 推进到 drawable acquisition planning / availability A/B。
- 本轮是否改变 canonical tail / endpoint：是，预期 tail 转为 `CjguiInternalRendererNoDrawableAvailabilityReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，新增 planning / availability owner；truth 限 no-acquire / still-blocked facts；stop-line 继续禁止 `nextDrawable`、present、command queue / buffer、GPU work、render、state write 与 public API。
- 本轮是否改变唯一 next opening：是，若 A/B 完成，转为 `P1 internal Renderer drawable acquisition first implementation recovery/preflight decision`。
- 是否同步 topic manifest：需要同步。
- 已同步哪些 topic manifest：本文件创建时声明需同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
