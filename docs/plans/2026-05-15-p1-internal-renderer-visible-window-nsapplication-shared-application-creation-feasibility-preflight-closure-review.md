# P1 Renderer 可见窗口 NSApplication Shared-Application Creation Feasibility 预检封账

## 封账结论

`NSApplication` shared-application creation feasibility preflight 已完成，结论是只允许进入 internal value-style owner，不允许直接调用 `sharedApplication`。

## 已确认事实

- 上游 `NSApplication` creation / activation scope readiness 只证明 creation / activation 仍 blocked。
- `sharedApplication` 不是 no-side-effect fact，不能借当前 scope facts 直接进入 production AppKit singleton call。
- 下一段需要把 shared application singleton access policy、main-thread affinity、headless fail-closed、bounded run loop、auto-close、teardown / non-user-visible mode 与 no-activation proof 固定为 value facts。

## 保持的停止线

仍不创建 `NSApplication`，不调用 `sharedApplication`，不 activation，不修改 activation policy，不运行 AppKit event loop，不做 native visible order implementation，不调用 production `nextDrawable`，不配置 color attachment，不创建 encoder，不 draw，不提交 GPU work，不执行 render，不写 renderer state，不扩 public API。

## 验证分类

本阶段为 docs-only preflight；不需要 build / smoke。后续 implementation owner 必须按代码变更验证基线运行 build、owner probe、相关 regression probe、auto-close smoke、forbidden scan、protected path scan 与 GitNexus detect-changes。

## 下一入口

`P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation`
