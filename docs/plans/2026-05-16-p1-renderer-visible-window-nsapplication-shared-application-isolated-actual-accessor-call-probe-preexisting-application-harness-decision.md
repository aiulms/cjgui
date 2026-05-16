# P1 Renderer 可见窗口 NSApplication Shared-Application Preexisting Harness 决策

状态：decision / docs-only / no reusable preexisting singleton harness found

## 决策

选择 A：保持 no-create fail-closed evidence branch，不自动打开 throwaway
`NSApplication` creation probe。

本轮只封账 preexisting-application harness decision。当前仓库没有可直接复用的
同进程 preexisting `NSApplication` singleton harness。`labs/macos_bridge_smoke`
包含 `sharedApplication`、activation policy mutation、activation、visible order 和
AppKit run loop 行为，因此只能继续作为 smoke / feasibility evidence，不能被搬进
Renderer production harness 的 isolated actual accessor call probe。

## 决策依据

- 当前 canonical endpoint 保持
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceReadiness`。
- 当前 default draft 保持
  `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationIsolatedActualAccessorCallProbeEvidenceDraft()`。
- 当前 runtime input 保持
  `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationActualAccessorCallPreflightGuardReadiness`。
- 上一段 first slice probe 已证明 no-create guard 生效：当前 automation 环境
  `preexisting_application_present=false`，因此 `accessor_call_attempted=false`、
  `application_created=false`、`classification=-240`。
- Focused source scan 发现 smoke harness 可创建 / 激活 / run `NSApplication`，
  但没有发现可复用的、同进程、不会由本 probe 创建 singleton 的 production harness。
- GitNexus impact / context 对最新 endpoint 仍返回 not found / `UNKNOWN`；
  该结果只说明图未覆盖新增符号，不能作为安全证明。

## 不进入实现的内容

- 不创建 `NSApplication`。
- 不调用会创建 singleton 的 accessor path。
- 不 activation。
- 不修改 activation policy。
- 不启动 AppKit event loop 或 bounded pump。
- 不创建 `NSWindow`、visible order、drawable 或 renderer resource。
- 不写 artifact，不发布 diagnostics。
- 不返回 pointer / handle / `id` / `Class`。
- 不新增 public API 或 production public C ABI。
- 不写 `runtime/cjgui/src/runtime_state.cj`。
- 不修改 `runtime/cjgui/cjpm.toml`。

## 后续进入条件

后续若要观察 accessor non-null result，必须满足其一：

- 外部提供已经拥有 preexisting `NSApplication` singleton 的同进程 harness，并证明
  singleton 不是由 isolated actual accessor call probe 创建。
- 人工明确批准 isolated throwaway creation probe，并重新列明 no activation、
  no activation policy mutation、no AppKit event loop、no bounded pump、no visible
  order、no drawable、no render、no artifact publication、no public API、
  no production public C ABI、no runtime state write 与 no `cjpm.toml` change。

## 当前唯一 next opening

`P1 internal Renderer visible-window production harness NSApplication shared-application isolated actual accessor call probe external preexisting singleton harness or throwaway creation approval decision`

## Same-shape Boundary Brake

本决策不是 application-ready、accessor-ready、visible-ready、drawable-ready、
render-ready、backend-ready、renderer state write、receipt、record 或 publication
wrapper。
