# P1 Renderer visible-window NSApplication shared-application CJGUI-owned singleton lifecycle preflight

状态：preflight / internal-only / production owner blocked

## 输入

本 preflight 消费：

- Stage 64 evidence-intake gate 的 evidence absent 结论。
- Stage 65 external owner source witness route unavailable recovery 结论。
- `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessTruthRecoveryFalseBranchDownstreamReadiness`。
- 用户路线 C：长期保留 hosted / owned 双模式设计。

Hosted mode 当前缺少 external owner source witness evidence packet，保持 `evidence_absent=true` 与 `current_route_available=false`。Owned mode 是当前 recovery route，但仅进入 preflight / readiness。

## Admission 条件

`CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationCjguiOwnedSingletonLifecyclePreflightReadiness` 只有在以下条件同时成立时才可认为 preflight ready：

- external witness recovery false branch downstream 已保留。
- route C 双模式选择已消费。
- hosted mode evidence absent / unavailable 已明确记录。
- isolated throwaway / accessor probe evidence 没有升级为 hosted owner truth 或 production ownership truth。
- owned mode 被选为当前 recovery route。
- main-thread creation、headless fail-closed、cleanup responsibility before implementation 已固定。
- activation、activation policy mutation、AppKit event loop、bounded run-loop pump、visible order、drawable / render 均 deferred。
- artifact / public diagnostics 不发布。
- public API、production public C ABI、renderer state、runtime state 与 cjpm 配置均不修改。
- production singleton ownership truth、production implementation、production actual accessor call site 仍为 false / blocked。

## 非目标

本 preflight 不实现 production singleton owner；不调用 application singleton accessor；不创建或激活 `NSApplication`；不修改 activation policy；不启动 event loop 或 bounded pump；不创建 visible window；不 visible order；不触碰 drawable、render pass、encoder、draw、commit、present 或 GPU submission；不新增 public API / public C ABI；不写 `runtime_state.cj` 或 `runtime/cjgui/cjpm.toml`。

## Probe 约束

Owner probe 必须确认：

- owner file 存在并包含 route C、hosted evidence absent、owned mode recovery、main-thread、headless、cleanup、deferred activation / event-loop / visible / drawable / render facts。
- owner file 没有 `foreign func`、public declaration 或 production native surface。
- owner file / native bridge diff 没有 activation、event-loop、visible-window、drawable、render、commit、present、public C ABI token。
- `runtime_state.cj` 与 `runtime/cjgui/cjpm.toml` 未进入 diff。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application CJGUI-owned singleton lifecycle value boundary / teardown-cleanup responsibility owner decision`
