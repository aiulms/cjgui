# P1 Renderer 可见窗口 NSApplication Shared-Application Feasibility Value Boundary Manifest 稳定化封账

## 稳定化结论

Shared-application feasibility value boundary manifest 已稳定。当前 canonical endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationFeasibilityReadiness`，default draft 是 `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationFeasibilityDraft()`。

## 一致性检查

- Runtime owner 只消费 `CjguiInternalRendererVisibleWindowNsApplicationCreationActivationScopeReadiness`。
- Owner probe 已确认 application singleton accessor call、application creation、activation policy mutation、activation、event loop、native visible order、public API、renderer state write 与 backend-ready truth 均未打开。
- `runtime/cjgui/cjpm.toml` 与 `runtime/cjgui/src/runtime_state.cj` 未修改。
- public declaration allowlist 未扩展。

## 保持的边界

不创建 `NSApplication`，不调用 application singleton accessor，不 activation，不修改 activation policy，不运行 event loop，不做 visible order，不获取 production drawable，不创建 encoder，不 draw，不 `commit` / `present`，不提交 GPU work，不写 renderer state，不扩 public API。

## 下一步

进入 `P1 internal Renderer visible-window production harness NSApplication shared-application native guard preflight decision`。该入口仍必须先做 docs-only preflight。
