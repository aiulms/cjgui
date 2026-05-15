# P1 Renderer 可见窗口 NSApplication Shared-Application Creation Feasibility 下一边界决策

## 当前阶段出口

Shared-application creation feasibility preflight 已选择 A 路线：不直接调用 `sharedApplication`，先新增 internal value-style feasibility owner。

## 下一主线

当前唯一 next opening 转为：

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation`

## 下一段只允许实现的问题

- 是否能把 shared application singleton access still blocked 固定为 runtime internal value facts。
- 是否能明确 `sharedApplication` call still blocked，不把 feasibility 误读为 creation。
- 是否能保留 main-thread affinity、headless fail-closed、bounded run loop、auto-close 与 teardown / non-user-visible mode prerequisite。
- 是否能继续证明 activation、activation policy mutation、event loop、native visible order、production drawable 与 render 均仍 blocked。

## 不自动继承的权限

- 不授权 `sharedApplication` call。
- 不授权 `NSApplication` creation。
- 不授权 activation。
- 不授权 activation policy mutation。
- 不授权 AppKit event loop。
- 不授权 native visible order implementation。
- 不授权 production drawable acquisition。
- 不授权 color attachment、encoder、draw、GPU submission 或 render。
- 不授权 renderer state write、public API、public C ABI 或 build config integration。

## 设计意图出口自检

- 下一 opening 是 value boundary implementation，不是 native AppKit call。
- 已保留 upstream / downstream 指向：上游为 creation / activation scope value boundary；downstream 为 future shared-application native guard / policy gate。
- Same-shape Boundary Brake：下一段仍必须证明不是 application-ready / visible-ready / drawable-ready / render-ready wrapper。
