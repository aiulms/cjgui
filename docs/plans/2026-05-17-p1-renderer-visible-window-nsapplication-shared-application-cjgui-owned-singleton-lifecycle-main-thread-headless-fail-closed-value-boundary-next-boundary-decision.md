# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle main-thread headless fail-closed value boundary next-boundary decision

状态：next-boundary / evidence probe preflight selected

## 当前封账点

`CJGUI-owned NSApplication singleton lifecycle main-thread and headless fail-closed value boundary` 已形成 internal-only readiness：

- CJGUI-owned lifecycle value boundary 已被消费。
- main-thread creation / cleanup confinement requirement 已固定。
- headless environment detection 与 headless / CI fail-closed before singleton creation 已固定。
- background-thread application singleton creation 与 headless application singleton creation 均 false。
- production singleton owner implementation 仍 deferred。
- application singleton accessor call 仍 false。
- cleanup / teardown execution 仍 false。
- production singleton ownership truth 仍为 false。
- no activation / event-loop / visible / drawable / render stop-line 仍保持。

## 下一边界

下一阶段可以继续在 owned-mode planning / internal evidence probe preflight 范围内推进，不需要停回 external witness route。

下一阶段应聚焦：

- main-thread confinement evidence probe 的 preflight facts。
- headless / CI fail-closed evidence probe 的 preflight facts。
- no singleton creation / no application accessor call guard。
- teardown / cleanup responsibility carry-forward。
- activation、activation policy mutation、event loop、bounded pump、visible order、drawable / render 的 deferred guard。
- no public API / no public C ABI / no renderer state write。

下一阶段仍不能进入 actual production singleton owner implementation、cleanup / teardown execution 或 native accessor call implementation。

## Stop-line

如果下一阶段要从 owned-mode planning / no-singleton evidence probe preflight 进入 production singleton owner implementation、cleanup / teardown execution、application singleton accessor call implementation、activation policy mutation、activation、event loop、visible order、drawable、render、state write、public API / C ABI 或 `runtime_state.cj` / `cjpm.toml` 修改，必须停止并请求人工。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread confinement and headless fail-closed evidence probe preflight / no-singleton-creation decision`
