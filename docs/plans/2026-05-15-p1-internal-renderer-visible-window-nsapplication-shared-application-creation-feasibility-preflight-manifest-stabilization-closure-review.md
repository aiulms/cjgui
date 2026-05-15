# P1 Renderer 可见窗口 NSApplication Shared-Application Creation Feasibility 预检 Manifest 稳定化封账

## 稳定化结论

Shared-application creation feasibility preflight manifest 已稳定：当前阶段只改变文档中的下一入口和 stop-line，不新增 runtime owner、native C ABI、`foreign func` 或 public API。

## 一致性检查

- 上游仍是 `CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`。
- 当前 manifest 明确 `sharedApplication` call still blocked。
- 当前唯一下一入口是 value boundary implementation，不是 AppKit singleton call。
- report-6 的 Metal smoke 复核仍只用于环境分类，不扩大 runtime permission。

## 保持的边界

不创建 `NSApplication`，不调用 `sharedApplication`，不 activation，不修改 activation policy，不运行 event loop，不做 visible order，不获取 production drawable，不创建 encoder，不 draw，不 `commit` / `present`，不提交 GPU work，不写 renderer state，不扩 public API。

## 下一步

进入 `P1 internal Renderer visible-window production harness NSApplication shared-application creation feasibility value boundary bundle implementation`。
