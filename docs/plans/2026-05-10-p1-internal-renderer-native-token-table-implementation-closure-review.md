# P1 内部渲染器 native token table implementation value boundary 复核

日期：2026-05-10

状态：value boundary closure / implementation shell deferred

## 本轮实际路线

本轮选择 A：新增 internal value owner，不修改 production native `.h` / `.m`，不实现 token table。

新增 owner：

`runtime/cjgui/src/runtime_renderer_native_token_table_implementation.cj`

新增 endpoint：

`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`

新增 default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`

唯一 runtime input：

`CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`

## 固定语义

本轮只新增以下 internal facts：

- native token table implementation intent。
- bridge-local table shell policy。
- no-pointer table entry policy。
- generation / slot / epoch policy。
- capacity / allocation failure classification。
- no-native-token-table-implementation readiness facts。

这些 facts 只说明 token table shell implementation 的前置边界已固定，不说明 token table exists。

## 未进入实现

- 未修改 `runtime/cjgui/native/cjgui_native_bridge.h`。
- 未修改 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 未新增 native token C ABI。
- 未实现 token table。
- 未新增 global mutable native table。
- 未新增 module-level mutable runtime state。
- 未保存 raw pointer。
- 未返回 native pointer。
- 未绑定 native object。
- 未调用 retain / release / destroy。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 smoke native files。

## 同形边界刹车

不得把 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` 包装成 native token table implementation permission、resource object table permission、native object permission、native handle permission、resource creation permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## GitNexus impact 记录

编辑 runtime owner 前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeResourceCreationAdmissionReadiness`：UNKNOWN / not found，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeResourceCreationAdmissionDraft`：UNKNOWN / not found，`impactedCount=0`。

未出现 HIGH / CRITICAL 风险；近期新增 owner 未索引风险由源码、build、probe 与 forbidden scan 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table implementation value boundary 已落地。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_implementation.cj`；truth 固定为 table shell policy、no-pointer entry、generation / slot / epoch 与 capacity failure facts；stop-line 继续禁止 actual table、native object、pointer、public API 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource shell first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
