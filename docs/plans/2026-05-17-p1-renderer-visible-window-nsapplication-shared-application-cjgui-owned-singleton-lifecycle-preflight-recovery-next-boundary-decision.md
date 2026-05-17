# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle preflight recovery next-boundary decision

状态：next-boundary / owned-mode value boundary selected

## 当前封账点

`CJGUI-owned NSApplication singleton lifecycle preflight / recovery` 已形成 internal-only readiness：

- hosted / owned 双模式路线 C 已被记录。
- hosted mode evidence absent / unavailable。
- owned mode 是当前 recovery route。
- production singleton ownership truth 仍为 false。
- production singleton implementation 仍 blocked。
- production actual accessor call site 仍 blocked。
- no activation / event-loop / visible / drawable / render stop-line 仍保持。

## 下一边界

下一阶段可以进入 owned-mode planning / value-boundary / readiness owner 范围，不需要再停在 external witness approval / human evidence intake。

下一阶段应聚焦：

- teardown / cleanup responsibility owner 的 value boundary。
- main-thread creation requirement 的可审计 owner facts。
- headless / CI fail-closed requirement 的 carry-forward。
- activation、activation policy mutation、event loop、bounded pump、visible order、drawable / render 的 deferred guard。
- artifact / public diagnostics non-publication。
- no public API / no public C ABI / no renderer state write。

下一阶段仍不能进入 actual production singleton owner implementation。

## Stop-line

如果下一阶段要从 owned-mode planning 进入 production singleton owner implementation、activation policy mutation、activation、event loop、visible order、drawable、render、state write、public API / C ABI 或 `runtime_state.cj` / `cjpm.toml` 修改，必须停止并请求人工。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle value boundary / teardown-cleanup responsibility owner decision`
