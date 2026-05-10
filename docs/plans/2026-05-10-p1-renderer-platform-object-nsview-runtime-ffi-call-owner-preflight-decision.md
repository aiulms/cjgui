# P1 内部渲染器 platform object NSView runtime FFI call owner 预检决策

日期：2026-05-10

状态：preflight decision / 允许极窄 first slice

## 预检结论

本轮选择 A：`P1 internal Renderer platform object NSView runtime FFI call owner first implementation bundle`。

选择理由：

- 上游 `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness` 已封账，production native bridge 已有固定容量、main-thread confined 的 `NSView` create / classify / destroy C ABI。
- 仓颉侧 `CPointer<UInt64>` out-token 语法已在 `runtime_renderer_platform_object_nsview_create_destroy.cj` 中编译通过，调用点使用 `inout createdToken`，不是本轮猜测。
- 同一 package 内已经存在 `cjgui_native_bridge_nsview_*` foreign declarations；本轮不得重复声明同名 C ABI，避免 duplicate symbol / declaration 风险。
- package config 仍未修改；真实主包 link 仍靠 script-managed route / runtime-adjacent probe 复核，不把 `runtime/cjgui/cjpm.toml` 解释成已集成。
- 新 owner 只允许 internal facts，不返回 token，不写 renderer state，不扩 public API。

## 本轮允许路线

本轮允许新增：

- `runtime/cjgui/src/runtime_renderer_platform_object_nsview_runtime_call.cj`
- `runtime/cjgui/native/scripts/verify_native_bridge_nsview_runtime_call.sh`
- 本阶段 closure、next-boundary、manifest 与 manifest closure。

新 owner 只消费：

`CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`

建议 endpoint：

`CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`

建议 default draft：

`cjguiInternalExecuteDefaultRendererPlatformObjectNsViewRuntimeCallDraft()`

## FFI 语法判断

本轮不新增重复 `foreign func` declaration。原因是上游 owner 已在同 package 声明：

- `cjgui_native_bridge_nsview_create(outToken: CPointer<UInt64>): Int32`
- `cjgui_native_bridge_nsview_destroy(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_token_classify(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_table_occupied_count(): UInt32`
- `cjgui_native_bridge_nsview_double_destroy_classify(token: UInt64): Int32`
- `cjgui_native_bridge_nsview_destroy_requires_main_thread(): Int32`

这些 declarations 与 `inout createdToken` 调用已经通过主包 `cjpm build --skip-script`，因此 out pointer 语法稳定到足以进入 runtime owner。

## Link 判断

当前 `runtime/cjgui/cjpm.toml` 仍未接入 production native object / static archive。主包 build 可编译 internal owner，但真实 C ABI 执行仍通过 script-managed package link / runtime-adjacent probe 复核。

因此本轮必须新增 runtime-adjacent verification script，观察：

- create 成功并输出 opaque token。
- classify valid。
- occupied count `0 -> 1 -> 0`。
- destroy 成功。
- destroyed / stale classification。
- double destroy fail-closed。
- invalid token fail-closed。
- destroy requires main thread classification。

如果 probe 不稳定，必须停到 recovery，不得伪造 manifest。

## 停止线

- 不新增 public API / diagnostics。
- 不修改 `runtime/cjgui/cjpm.toml`。
- 不修改 smoke native files。
- 不触碰 `runtime/cjgui/src/runtime_state.cj`。
- 不创建 `NSWindow` / `NSApplication` / `CALayer` / `CAMetalLayer`。
- 不导入 Metal / QuartzCore。
- 不返回 `Class` / `id` / pointer / handle。
- token 只允许函数局部使用，不跨函数持久化，不写 renderer state。
- 不把 runtime internal token facts 解释成 backend-ready、render permission、Metal layer permission 或 renderer state write permission。

## GitNexus 影响记录

- `CjguiInternalRendererNoPlatformObjectNsViewCreateDestroyReadiness`：GitNexus 返回 not found / `UNKNOWN` / impacted count `0`。
- `cjguiInternalExecuteDefaultRendererPlatformObjectNsViewCreateDestroyDraft`：GitNexus 返回 not found / `UNKNOWN` / impacted count `0`。

该结果按近期新增 owner 尚未索引处理。本轮用源码阅读、主包 build、runtime-adjacent probe、public declaration scan、native forbidden scan、protected path scan 与 GitNexus detect changes 兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，允许从 token-backed `NSView` create/destroy first slice 进入 runtime FFI call owner first slice。
- 本轮是否改变 canonical tail / endpoint：预期是，若实现通过将转为 `CjguiInternalRendererNoPlatformObjectNsViewRuntimeCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：预期是，新增 runtime call owner；truth 限定为 internal runtime FFI call facts；stop-line 继续禁止 public / pointer / window / layer / Metal / renderer state / backend-ready。
- 本轮是否改变唯一 next opening：预期是，若实现通过转为 `P1 internal Renderer platform object NSView renderer backend shell integration preflight decision`。
- 是否同步 topic manifest：本轮结束时必须同步。
- 已同步哪些 topic manifest：待 closure 固定。
