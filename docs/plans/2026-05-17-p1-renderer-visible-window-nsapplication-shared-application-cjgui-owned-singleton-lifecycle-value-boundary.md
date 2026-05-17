# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle value boundary

状态：value boundary / internal-only / production owner blocked

## 输入

本 value boundary 消费：

- Stage 66 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness`。
- route C owned mode recovery route。
- hosted mode evidence absent / unavailable carry-forward。

本阶段不消费 external owner source witness evidence，也不把 isolated throwaway / accessor probe evidence 升级为 hosted owner truth 或 production ownership truth。

## Admission 条件

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecycleValueBoundaryReadiness` 只有在以下条件同时成立时才可认为 ready：

- CJGUI-owned lifecycle preflight readiness 已保留。
- owned mode recovery route 已保留。
- teardown / cleanup responsibility owner requirement 已固定。
- cleanup-before-production-singleton-implementation requirement 已固定。
- main-thread cleanup、cleanup idempotency、cleanup before visible order、cleanup before drawable/render 已固定。
- headless / CI fail-closed 已 carry-forward。
- cleanup execution、activation、activation policy mutation、AppKit event loop、bounded pump、visible order、drawable / render 均 deferred。
- artifact / public diagnostics 不发布。
- public API、production public C ABI、renderer state、runtime state 与 cjpm 配置均不修改。
- hosted owner truth、source readiness truth、production singleton ownership truth、production implementation、production actual accessor call site 与新 application singleton accessor call 仍为 false / blocked。

## 非目标

本 value boundary 不实现 production singleton owner；不执行 cleanup / teardown；不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不启动 event loop 或 bounded pump；不创建 visible window；不 visible order；不触碰 drawable、render pass、encoder、draw、commit、present 或 GPU submission；不新增 public API / public C ABI；不写 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## Probe 约束

Owner probe 必须确认：

- owner file 存在并包含 value boundary、teardown / cleanup responsibility、main-thread cleanup、headless fail-closed、cleanup execution deferred 与 all production stop-line false / deferred facts。
- owner file 没有 `foreign func`、public declaration 或 production native surface。
- owner file / native bridge diff 没有 activation、event-loop、visible-window、drawable、render、commit、present、public C ABI token。
- `runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未进入 diff。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle main-thread and headless fail-closed value boundary / internal readiness owner decision`
