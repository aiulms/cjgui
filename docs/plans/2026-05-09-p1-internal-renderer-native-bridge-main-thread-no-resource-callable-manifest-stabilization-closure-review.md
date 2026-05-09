# P1 内部渲染器 native bridge main-thread no-resource callable 清单稳定化复核

日期：2026-05-09

状态：manifest stabilization closure / stop after manifest

## 封账结论

[main-thread no-resource callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-main-thread-no-resource-callable-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`

## 固定现实

- production native skeleton 新增 `cjgui_native_bridge_is_main_thread`。
- implementation 使用 `pthread_main_np()`。
- runtime owner 已存在，并只调用该 no-resource main-thread query。
- `runtime/cjgui/cjpm.toml` 未修改。
- production `.m` 未正式接入主包 package config。
- probe 已观察 `main_thread_query_observed=true` 与 `main_thread_observed=true`。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未导入 Foundation / Cocoa / Metal / QuartzCore。
- 未调用 AppKit / Metal。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 main-thread no-resource callable、pthread query、probe success、runtime owner facts、no-resource runtime FFI call owner 或 smoke evidence 包装成 native object permission、AppKit permission、Metal permission、backend-ready permission、public API permission、resource callable permission、receipt、record 或 publication。

## 后续入口

`P1 internal Renderer native bridge native token callable preflight decision`

下一轮若进入该入口，必须重新评估 token 是否保持 opaque/dehydrated、是否完全不返回 native handle / pointer、是否仍 no-resource；不得直接进入 native handle allocation、destroy callback、resource callable、AppKit / Metal 或 public API。

## 下游接续

该入口已由 [native token callable manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-09-p1-renderer-native-bridge-native-token-callable-manifest.md) 接续。当前全局唯一后续入口已经转为 `P1 internal Renderer native token table ownership hardening preflight decision`；本 closure 仍只作为 main-thread classification evidence，不是 token table、native handle、native object、resource callable 或 backend-ready permission。

## 设计意图出口自检

- 本轮是否改变主题状态：是，main-thread no-resource callable 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeBridgeMainThreadCallReadiness` / `cjguiInternalExecuteDefaultRendererNativeBridgeMainThreadCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_bridge_main_thread_call.cj`；truth 固定为 current-thread classification facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native bridge native token callable preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
