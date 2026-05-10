# P1 内部渲染器 native token table implementation 清单稳定化复核

日期：2026-05-10

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native token table implementation manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-implementation-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeTokenTableImplementationReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_token_table_implementation.cj`。
- 本轮路线是 value boundary，不是 native token table implementation。
- 本轮没有新增 production native token C ABI。
- 本轮没有实现 token table。
- 本轮没有新增 global mutable native table。
- 本轮没有保存 raw pointer。
- 本轮没有绑定 native object。
- 本轮没有修改 production native `.h` / `.m`。
- 本轮没有修改 scripts。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有把 token table implementation facts 暴露到 public API。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未创建 resource object table。
- 未新增 module-level mutable runtime state。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 AppKit / Metal。
- 未调用 retain / release / destroy。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未修改 smoke native files。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 token table implementation value boundary、bridge-local table shell policy、no-pointer entry policy、generation / slot / epoch policy、capacity failure policy、resource creation admission facts 或 smoke evidence 包装成 native table implementation permission、resource creation permission、native object permission、native handle permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。

## 后续入口

原定入口 `P1 internal Renderer native token table no-resource shell first implementation preflight decision` 已由 [native token table no-resource shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-manifest.md) 接续。

当前唯一后续入口：

`P1 internal Renderer native token table no-resource issue/revoke preflight decision`

下一轮若进入该入口，必须先确认 issue / revoke shell 是否可以在 no-resource、no-pointer、no-native-object-binding、no-public-surface、fail-closed、fixed capacity、generation / epoch 和 bridge-local owner 约束下实现；不得直接创建 resource object table、native object、native handle、raw pointer、Metal / AppKit resource、public API 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table implementation value boundary 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeTokenTableImplementationReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableImplementationDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_implementation.cj`；truth 固定为 token table implementation intent、bridge-local table shell policy、no-pointer table entry policy、generation / slot / epoch policy、capacity failure classification 与 no-native-token-table-implementation readiness facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource shell first implementation preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
