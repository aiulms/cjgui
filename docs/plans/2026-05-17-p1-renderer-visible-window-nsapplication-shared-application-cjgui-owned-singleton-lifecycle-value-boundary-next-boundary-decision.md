# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle value boundary next-boundary decision

状态：next-boundary / main-thread and headless fail-closed boundary selected

## 当前封账点

`CJGUI-owned NSApplication singleton lifecycle value boundary / teardown-cleanup responsibility owner` 已形成 internal-only readiness：

- CJGUI-owned lifecycle preflight 已被消费。
- teardown / cleanup responsibility owner requirement 已固定。
- cleanup before production singleton implementation 已固定。
- cleanup execution 仍 deferred。
- production singleton ownership truth 仍为 false。
- production singleton implementation 仍 blocked。
- production actual accessor call site 仍 blocked。
- no activation / event-loop / visible / drawable / render stop-line 仍保持。

## 下一边界

下一阶段可以继续在 owned-mode planning / value-boundary / readiness owner 范围内推进，不需要停回 external witness route。

下一阶段应聚焦：

- main-thread creation / cleanup confinement 的可审计 owner facts。
- headless / CI fail-closed 的 value boundary。
- teardown / cleanup responsibility carry-forward。
- activation、activation policy mutation、event loop、bounded pump、visible order、drawable / render 的 deferred guard。
- no public API / no public C ABI / no renderer state write。

下一阶段仍不能进入 actual production singleton owner implementation 或 cleanup / teardown execution。

## Stop-line

如果下一阶段要从 owned-mode planning 进入 production singleton owner implementation、cleanup / teardown execution、activation policy mutation、activation、event loop、visible order、drawable、render、state write、public API / C ABI 或 `runtime_state.cj` / `cjpm.toml` 修改，必须停止并请求人工。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread and headless fail-closed value boundary / internal readiness owner decision`
