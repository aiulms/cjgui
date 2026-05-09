# P1 内部渲染器 native bridge no-resource runtime FFI call owner 复核

日期：2026-05-09

状态：implementation closure / no public API / no resource callable

## 完成内容

本轮新增 [runtime_renderer_native_bridge_no_resource_call.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/runtime_renderer_native_bridge_no_resource_call.cj)。

新增 canonical endpoint：

`CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness`

新增 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`

唯一 runtime input：

`CjguiInternalRendererNoNativeBridgePackageConfigLinkReadiness`

## 实际语义

owner 在 internal-only default draft 中调用四个 no-resource C ABI：

- `cjgui_native_bridge_surface_version`
- `cjgui_native_bridge_surface_capabilities`
- `cjgui_native_bridge_status_ok`
- `cjgui_native_bridge_no_resource_admission`

调用结果被脱水为 internal facts：

- surface version observed。
- capabilities observed。
- status ok observed。
- no-resource admission observed。
- unexpected result fail-closed。

## Probe 更新

更新 [verify_native_bridge_no_resource_call_probe.sh](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/native/scripts/verify_native_bridge_no_resource_call_probe.sh)，新增对 runtime call owner 源码的检查：

- 确认 owner 文件存在。
- 确认四个 no-resource C ABI 在 owner 中被调用。
- 确认 endpoint 与 default draft 存在。
- 继续通过 temporary `cjpm` package 实际调用 C ABI。

该 probe 不执行主包 owner，也不把 probe success 解释成 public API、resource callable、native object 或 backend ready。

## 边界

- 未修改 `runtime/cjgui/cjpm.toml`。
- 未修改 production native C ABI 行为。
- 未修改 smoke native files。
- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未创建 backend-ready truth。

## 验证摘要

- GitNexus impact：上游两个 target 均 `UNKNOWN / not found`，按近期新增 owner 未索引记录；未收到 HIGH / CRITICAL。
- 临时主包副本 build：加入 actual call owner 后 `cjpm build --skip-script` 通过。
- 早期 `cjpm build --target-dir /tmp/cjgui-renderer-native-bridge-no-resource-runtime-call-owner-early-target --skip-script` 通过。
- 早期 no-resource call probe 通过，并输出 `runtime_owner_call_source_observed=true`。

## 设计意图出口自检

- 本轮是否改变主题状态：是，actual internal no-resource runtime FFI call owner 已落地。
- 本轮是否改变 canonical tail / endpoint：是，新增 `CjguiInternalRendererNoNativeBridgeNoResourceRuntimeCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeNoResourceRuntimeCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，新增 owner；truth 为四个 no-resource C ABI observed facts；stop-line 继续禁止 public API、resource callable、native object、Metal / AppKit、renderer state write 与 backend-ready truth。
- 本轮是否改变唯一 next opening：是，转入 no-resource runtime FFI call owner next-boundary decision。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
