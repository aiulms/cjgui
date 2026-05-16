# P1 Renderer 可见窗口 NSApplication Shared-Application 隔离 Actual Accessor Call Probe First Slice 下一边界决策

状态：next-boundary decision / preexisting singleton gap / human decision required

## 下一主线

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe preexisting-application harness decision`

## 下一段只允许判断的问题

- 是否继续保持 no-create fail-closed evidence branch。
- 是否存在不创建 `NSApplication` 的 preexisting singleton harness 可以复用。
- 若必须观察 actual accessor non-null result，是否需要人工另行批准 throwaway isolated creation probe。

## 当前不能自动做的事

- 不能为了得到 non-null result 而调用会创建 singleton 的 accessor path。
- 不能创建或激活 `NSApplication`。
- 不能修改 activation policy。
- 不能启动 AppKit event loop / bounded pump。
- 不能创建 `NSWindow`、visible order、drawable 或 renderer resource。
- 不能把 probe classification 写入 runtime state、artifact publication、public diagnostics 或 public API。
- 不能新增 production public C ABI 或修改 `cjpm.toml`。

## 进入条件

若下一段继续 no-create branch，只能补充更强的 source / probe / manifest 证据。

若下一段要实际观察 accessor non-null result，必须先满足其一：

- 外部 harness 已有 preexisting `NSApplication` singleton，且不会由本 probe 创建。
- 人工明确批准 isolated throwaway creation probe，并重新列明 no activation、no activation policy mutation、no event loop、no visible order、no drawable、no render、no public API、no production C ABI、no runtime_state write 与 no cjpm change。

## Same-shape Boundary Brake

当前 first slice 不是 application-ready、accessor-ready、visible-ready、drawable-ready、render-ready、backend-ready、renderer state write、receipt、record 或 publication wrapper。

