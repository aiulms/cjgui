# P1 内部渲染器 native bridge teardown callable value owner 复核

日期：2026-05-10

状态：value boundary closure / no native callable implementation

## 本轮完成

新增 internal runtime owner：

- [runtime_renderer_native_bridge_teardown_callable.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_teardown_callable.cj)

新增 endpoint：

- `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness`

新增 default draft：

- `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`

唯一 runtime input：

- `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`

## 固定 truth

本轮只固定以下 internal facts：

- native bridge teardown callable intent。
- no-destroy callable policy。
- revoke-before-destroy callable policy。
- double-destroy / dangling-token classification policy。
- main-thread destroy callable gate policy。
- no-native-bridge-teardown-callable readiness facts。

这些 facts 只说明 future destroy callable 的安全边界已经被 value owner 固定，不说明 native teardown callable 已经实现。

## 未做事项

- 未修改 `runtime/cjgui/native/cjgui_native_bridge.h`。
- 未修改 `runtime/cjgui/native/cjgui_native_bridge.m`。
- 未新增 `cjgui_native_bridge_teardown_admission` 等 native callable。
- 未修改 native probe scripts。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 smoke native files。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未实现 token table。
- 未调用 retain / release / destroy。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未新增 public API / diagnostics。

## GitNexus 结果

编辑 runtime symbol 前已对上游入口运行 impact：

- `CjguiInternalRendererNoNativeTokenTableOwnershipReadiness`：`UNKNOWN / not found`，`impactedCount=0`。
- `cjguiInternalExecuteDefaultRendererNativeTokenTableOwnershipDraft`：`UNKNOWN / not found`，`impactedCount=0`。

按近期新增 owner 未索引记录处理；本轮继续用源码、build、probe、scan 与最终 `detect_changes` 兜底。没有 HIGH / CRITICAL risk。

## 边界确认

当前 owner 中的 `Destroy` / `Teardown` 词汇只用于 policy 与 classification，不调用 destroy，不执行 native lifecycle mutation，也不接入 production native bridge。

`main-thread destroy callable gate` 只消费上游 main-thread confinement policy 的事实链，不调度主线程，不调用 AppKit / Metal / Objective-C。

## 设计意图出口自检

- 本轮是否改变主题状态：是，teardown callable planning value boundary 已落地。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeTeardownCallableReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeTeardownCallableDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_teardown_callable.cj`；truth 固定为 no-destroy callable policy、revoke-before-destroy callable policy、double-destroy / dangling-token classification policy、main-thread destroy callable gate policy 与 no-native-bridge-teardown-callable readiness facts；stop-line 继续禁止 actual destroy、token table、resource callable、native object、Metal / AppKit、public API、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：待 next-boundary decision 固定。
- 是否同步 topic manifest：待 manifest stabilization 同步。
- 已同步哪些 topic manifest：待 manifest stabilization 记录。
