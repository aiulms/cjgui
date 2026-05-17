# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe preflight

状态：preflight / internal readiness owner / no production singleton truth

## Preflight 范围

本 preflight 只把 Stage 68 的 main-thread / headless fail-closed value boundary 转换成后续 evidence probe first slice 的 admission facts。

允许范围：

- 读取 Stage 68 readiness。
- 固定 main-thread confinement evidence probe preflight。
- 固定 headless / CI fail-closed evidence probe preflight。
- 继续要求 no singleton creation during probe。
- 继续要求 no application singleton accessor call during probe。
- 继续要求 no native bridge expansion。
- 继续要求 artifact / diagnostics non-publication。

不允许范围：

- 不调用 application singleton accessor。
- 不创建或激活 `NSApplication`。
- 不执行 cleanup / teardown。
- 不新增 native bridge C ABI。
- 不修改 `runtime_state.cj` 或 `cjpm.toml`。
- 不进入 visible order、drawable、render 或 GPU submission。

## Runtime endpoint

Canonical endpoint：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightReadiness`

Default draft：

`cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedEvidenceProbePreflightDraft()`

Runtime input：

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleMainThreadHeadlessFailClosedValueBoundaryReadiness`

## Preflight 结论

本阶段可以封账，因为它没有执行 probe first slice，只形成 no-singleton evidence probe 前置 owner：

- main-thread creation / cleanup confinement 继续 carry forward。
- headless / CI fail-closed before singleton creation 继续 carry forward。
- production singleton ownership truth 仍 false。
- production singleton implementation 仍 blocked。
- application singleton accessor call 仍 false。
- cleanup / teardown execution 仍 false。
- readiness 仍 dehydrated。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe first slice / scan-only no-singleton owner decision`
