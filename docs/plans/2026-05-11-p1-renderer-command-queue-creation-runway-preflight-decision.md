# MTLCommandQueue 创建路线预检结论

日期：2026-05-11

## 上游固定

- Runtime input：`CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`
- 上游 owner：[runtime_renderer_drawable_no_present_acquisition.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_drawable_no_present_acquisition.cj)
- 上游 default draft：`cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft()`
- 上游事实：isolated visible-window no-present drawable acquisition 已证明 `nextDrawable` 可在 bounded probe 中返回，但没有 present、command queue、command buffer、encoder、GPU submission、render 或 renderer state write。

## GitNexus 影响记录

- `CjguiInternalRendererNoDrawableNoPresentAcquisitionReadiness`：`UNKNOWN` / target not found / impactedCount `0`。
- `cjguiInternalExecuteDefaultRendererDrawableNoPresentAcquisitionDraft`：`UNKNOWN` / target not found / impactedCount `0`。
- `cjgui_native_bridge_surface_capabilities`：`UNKNOWN` / target not found / impactedCount `0`。
- `cjgui_native_bridge_metal_device_destroy`：`UNKNOWN` / target not found / impactedCount `0`。
- 判定：相关 runtime owner 与 native C ABI 属于近期新增符号，GitNexus 当前索引未覆盖；未出现 HIGH / CRITICAL 输出。本轮必须用源码、probe、`cjpm build` 与 forbidden scan 兜底。

## 预检判断

本阶段可以打开 `MTLCommandQueue` creation runway，并允许进入 token-backed create / destroy 与 runtime internal FFI call owner。理由如下：

- 上游已有 token-backed `MTLDevice` create / destroy 与 layer binding cleanup 事实。
- `MTLCommandQueue` 可以从 token-backed device 局部创建，并由固定容量 native table 持有。
- Queue token 可继续使用 opaque integer policy，不返回 pointer / handle / `id` / `Class`。
- Queue create / destroy 可以 main-thread confined，并对 invalid / stale / double destroy fail-closed。
- Device destroy 必须在 bound queue destroy 后才能成功，避免 queue 成为悬挂第二状态源。
- 本阶段不需要 command buffer、encoder、commit、present、drawable present、GPU submission、render 或 renderer state write。

## 路线选择

选择 B/C：

`P1 internal Renderer command queue token-backed create/destroy and runtime FFI call owner bundle`

本阶段实际允许：

- 新增 production native command queue C ABI。
- 新增固定容量很小的 queue token table。
- 新增 command queue create / destroy / classify / occupied count / double destroy / main-thread gate / command-buffer-still-blocked facts。
- 新增 runtime owner 调用 queue create → classify → destroy → double destroy，并只生成 internal dehydrated facts。
- 新增 probe 覆盖 native create / destroy 与 runtime-adjacent FFI call path。

拒绝路线：

- command buffer creation。
- `commandBuffer` 调用。
- encoder creation。
- `commit` / `present`。
- GPU submission / render。
- public API / public diagnostics。
- renderer state write。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 drawable no-present acquisition facts 推进到 command queue token-backed create / destroy 与 runtime internal call facts。
- 本轮是否改变 canonical tail / endpoint：预检选择后将变更为 `CjguiInternalRendererNoCommandQueueRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：将新增 command queue native lifecycle owner 与 runtime call owner；truth 仅限 queue token lifecycle 与 local runtime call facts；stop-line 继续禁止 command buffer、commit、present、GPU work、render、state write、public API。
- 本轮是否改变唯一 next opening：若 B/C 封账，唯一后续入口转为 `P1 internal Renderer command buffer creation planning preflight decision`。
- 是否同步 topic manifest：需要。
- 已同步哪些 topic manifest：本预检要求同步 `renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
