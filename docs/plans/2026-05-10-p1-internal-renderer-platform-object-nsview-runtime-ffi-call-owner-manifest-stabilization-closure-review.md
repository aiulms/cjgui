# P1 内部渲染器 platform object NSView runtime FFI call owner 清单稳定化封账

日期：2026-05-10

状态：manifest stabilization closure / 已封账

## 稳定化结论

本轮 manifest stabilization 固定了 `NSView` runtime FFI call owner first slice 的 owner、runtime input、endpoint、default draft、observed facts、probe route 与 stop-line。

当前 canonical tail：

`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`

该 tail 只证明 runtime internal owner 可以在 internal-only 范围内调用 production native 的 token-backed `NSView` create / classify / destroy C ABI，并把局部生命周期观察脱水为 facts。它不是 renderer backend ready，不是 render permission，不是 public API，不是 pointer / handle surface。

## 封账内容

- Runtime owner 已固定为 [runtime_renderer_platform_object_nsview_runtime_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj)。
- Verification probe 已固定为 [verify_native_bridge_nsview_runtime_call.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh)。
- Manifest 已固定为 [NSView runtime FFI call owner manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-platform-object-nsview-runtime-ffi-call-owner-manifest.md)。
- README、tracker、plans README、runtime README、设计意图索引与 topic manifest 已同步。

## 保留风险

- `runtime/cjgui/cjpm.toml` 仍未接入 production native bridge object / archive；当前 runtime execution evidence 依赖 script-managed / runtime-adjacent probe。
- GitNexus 对本阶段上游新符号仍返回 not found / `UNKNOWN`，按近期新增 owner 未索引记录，最终以源码、build、probe 与 scans 兜底。
- 下一阶段如果要把 `NSView` token 接入 renderer backend shell，必须先做 docs-only preflight，不得直接创建 layer / Metal resource 或写 renderer state。

## Same-shape Brake

不得把本 manifest、runtime call owner、runtime-adjacent probe、`NSView` token、package link evidence 或 AppKit evidence 包装成：

- public API permission
- pointer / handle / `id` / `Class` permission
- `NSWindow` / `NSApplication` / layer permission
- Metal / QuartzCore permission
- GPU submission permission
- render execution permission
- renderer state write permission
- backend-ready truth
- receipt / record / publication wrapper

## 设计意图出口自检

- 本轮是否改变主题状态：是，runtime internal `NSView` FFI call owner first slice 已 manifest stabilization。
- 本轮是否改变 canonical tail / endpoint：是，固定 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner、truth 与 stop-line 均已在 manifest 固定。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
