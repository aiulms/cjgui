# P1 Renderer 可见窗口 NSApplication Shared-Application Preexisting Harness 下一边界决策

状态：next-boundary decision / human input required / no automatic creation

## 下一主线

当前唯一 next opening：

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe external preexisting singleton harness or throwaway creation approval decision`

## 下一段只允许判断的问题

- 是否存在外部提供的、同进程、preexisting `NSApplication` singleton harness。
- 该 harness 是否能证明 singleton 不是由 isolated actual accessor call probe 创建。
- 若没有外部 harness，是否由人工明确批准 isolated throwaway creation probe。

## 当前不能自动做的事

- 不能为了观察 non-null accessor result 自动创建 `NSApplication`。
- 不能把 `labs/macos_bridge_smoke` 的 creation / activation / run loop 行为搬入
  production runtime 或 Renderer harness。
- 不能新增 production `sharedApplication` call site。
- 不能新增 public API、production public C ABI、runtime state write 或 artifact
  publication。

## 进入条件

继续 no-create branch 时，只能补充 source / probe / manifest 证据，不能推进到
non-null result claim。

若要实际观察 accessor non-null result，必须先满足其一：

- 外部 preexisting singleton harness 已就绪，且本 probe 不创建 singleton。
- 人工明确批准 isolated throwaway creation probe，并重新列明 no activation、no
  activation policy mutation、no event loop、no visible order、no drawable、no
  render、no public API、no production C ABI、no runtime state write 与 no
  `cjpm.toml` change。

## Same-shape Boundary Brake

当前 harness decision 不是 application-ready、accessor-ready、visible-ready、
drawable-ready、render-ready、backend-ready、renderer state write、receipt、record
或 publication wrapper。
