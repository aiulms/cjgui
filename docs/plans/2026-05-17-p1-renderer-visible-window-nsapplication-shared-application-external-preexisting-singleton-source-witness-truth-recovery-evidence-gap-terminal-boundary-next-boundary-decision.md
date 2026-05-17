# P1 Renderer visible-window NSApplication shared-application source witness truth recovery evidence-gap terminal boundary next-boundary decision

状态：next-boundary / external evidence intake required

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application external owner source witness evidence intake / human-provided source evidence decision`

## 原因

当前 source witness truth recovery runway 已经到达 terminal boundary。继续新增 value boundary、false-branch downstream 或 recovery wrapper 只会重复同一 evidence gap，不能产生 source witness truth。

下一步只有在外部 owner 提供 source evidence 时才有意义。该 evidence 必须能证明：

- preexisting `NSApplication` singleton 在 Renderer 之前由外部 owner 持有；
- observation 发生在 main thread；
- source lifetime 覆盖 Renderer harness 使用窗口；
- cleanup / teardown ownership 明确属于外部 owner；
- Renderer 未创建 singleton，也未在 production path 调用 application singleton accessor；
- headless / CI-like 场景保持 fail-closed；
- 不发布 artifact、public diagnostics、native identity、pointer、handle、`id` 或 `Class`。

## 允许范围

- 可以接收并审计外部 owner source witness evidence packet。
- 可以做 docs-only evidence intake / acceptance decision。
- 可以在 evidence 仍不足时保持 terminal blocker。
- 可以同步 manifest / tracker / topic manifests。

## 禁止范围

不允许 production singleton owner implementation、application singleton accessor production call site、native C ABI、activation、event loop、cleanup execution、visible order、drawable、render、renderer state write、public API、production C ABI、`runtime_state.cj` write 或 `cjpm.toml` change。
