# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed evidence probe preflight next-boundary decision

状态：next-boundary / scan-only first slice selected

## 当前封账点

`CJGUI-owned NSApplication singleton lifecycle main-thread and headless fail-closed evidence probe preflight` 已形成 internal-only readiness：

- Stage 68 main-thread / headless fail-closed value boundary 已被消费。
- main-thread confinement evidence probe preflight 已固定。
- headless / CI fail-closed evidence probe preflight 已固定。
- no singleton creation during evidence probe 已固定。
- no application singleton accessor call during evidence probe 已固定。
- no native bridge expansion 已固定。
- production singleton owner implementation 仍 deferred。
- cleanup / teardown execution 仍 false。
- production singleton ownership truth 仍为 false。
- no activation / event-loop / visible / drawable / render stop-line 仍保持。

## 下一边界

下一阶段可以继续在 owned-mode planning / scan-only evidence probe first slice 范围内推进。

下一阶段应聚焦：

- main-thread confinement evidence owner 的 first slice。
- headless / CI fail-closed evidence owner 的 first slice。
- no singleton creation / no application accessor call guard。
- no native C ABI expansion guard。
- teardown / cleanup responsibility carry-forward。
- activation、activation policy mutation、event loop、bounded pump、visible order、drawable / render 的 deferred guard。
- no public API / no public C ABI / no renderer state write。

下一阶段仍不能进入 production singleton owner implementation、cleanup / teardown execution 或 native accessor call implementation。

## Stop-line

如果下一阶段要从 scan-only evidence probe first slice 进入 production singleton owner implementation、cleanup / teardown execution、application singleton accessor call implementation、activation policy mutation、activation、event loop、visible order、drawable、render、state write、public API / C ABI 或 `runtime_state.cj` / `cjpm.toml` 修改，必须停止并请求人工。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe first slice / scan-only no-singleton owner decision`
