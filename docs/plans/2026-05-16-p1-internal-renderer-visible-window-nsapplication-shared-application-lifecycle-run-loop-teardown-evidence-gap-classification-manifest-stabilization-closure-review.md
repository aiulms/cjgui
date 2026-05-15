# P1 internal Renderer visible-window NSApplication shared-application lifecycle / run-loop / teardown evidence gap classification manifest stabilization closure review

状态：docs-only / manifest stabilization closure / no runtime implementation

## 稳定化结论

lifecycle / run-loop / teardown evidence gap classification manifest 已封账。当前 canonical endpoint、default draft 与 runtime input 不变：

- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyReadiness`
- `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCleanupHeadlessSafetyDraft()`
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationAccessorCallContainmentPolicyReadiness`

本阶段没有新增 runtime truth，只把下一步 evidence owner preflight 的入口从 cleanup / headless safety stop-line 后方拆出来。

## 同步要求

README、GUI task tracker、plans README、runtime README、DESIGN_INTENT_INDEX 与 renderer / macOS bridge topic manifests 必须把当前唯一 next opening 同步为：

`P1 internal Renderer visible-window production harness NSApplication shared-application lifecycle evidence owner preflight decision`

## 边界

不新增 `.cj`、native bridge、script、probe、public API、public C ABI、diagnostics 或 renderer state write。不修改 `runtime/cjgui/cjpm.toml`，不触碰 `runtime/cjgui/src/runtime_state.cj`。
