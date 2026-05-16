# Cangjie GUI Runtime Area

日期：2026-04-26

状态：experimental skeleton only

本目录用于承载未来正式 GUI runtime 的极窄骨架讨论与占位文件。它不是稳定 public API，不代表 runtime 已经实现，也不代表任何应用可以依赖这里的接口。

最新 Renderer visible-window `NSApplication` shared-application external preexisting singleton source witness payload schema preflight 已完成 value-only owner 封账：[witness payload schema preflight manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-16-p1-renderer-visible-window-nsapplication-shared-application-external-preexisting-singleton-source-witness-payload-schema-preflight-manifest.md)。当前 endpoint 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightReadiness` / `cjguiInternalExecuteDefaultRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessPayloadSchemaPreflightDraft()`；runtime input 是 `CjguiInternalRendererVisibleWindowNsApplicationSharedApplicationExternalPreexistingSingletonSourceWitnessAdmissionPolicyPreflightReadiness`。该阶段只定义 external source witness payload schema preflight，不授权 production singleton owner implementation、actual accessor production call site、native C ABI、activation、event loop、cleanup execution、visible order、drawable、render、public API、`runtime_state.cj` write 或 `cjpm.toml` change。当前唯一 next opening 是 `P1 internal Renderer visible-window production harness NSApplication shared-application external preexisting singleton source witness payload validation preflight decision`。

## 与 `labs/` 的边界

- `labs/macos_bridge_smoke` 继续是实验室 smoke / guard。
- 本目录不复用 smoke 目录结构。
- 本目录不迁移 smoke C ABI。
- 本目录不依赖 smoke build script。
- 本目录不把 smoke diagnostics、auto-close、clear-color render path 或 `last_error` 语义升格为 runtime contract。

## 当前范围

当前只允许 minimal app/window lifecycle skeleton：

- app lifecycle owner 边界。
- window lifecycle owner 边界。
- platform adapter / core runtime 边界。
- error strategy placeholder。

当前不包含：

- build config / package config。
- public C ABI / public runtime API。
- real app lifecycle implementation。
- real window lifecycle implementation。
- event loop implementation。
- handle table / generation implementation。
- Renderer / Scene / Widget / Layout / DSL。
- command-list hash / pixel diff / baseline / offscreen renderer。
- semantic tree / Action Router。

## 验证定位

现有 smoke guard 仍属于 `labs/macos_bridge_smoke`。本目录不会把 smoke harness 升级为正式 runtime test framework。
