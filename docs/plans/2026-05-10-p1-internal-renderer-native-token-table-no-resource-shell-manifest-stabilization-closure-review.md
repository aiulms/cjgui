# P1 内部渲染器 native token table no-resource shell 清单稳定化复核

日期：2026-05-10

状态：manifest stabilization closure / stop after manifest

## 封账结论

[native token table no-resource shell manifest](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-10-p1-renderer-native-token-table-no-resource-shell-manifest.md) 已封账。

当前 canonical endpoint：

`CjguiInternalRendererNoNativeTokenTableShellReadiness`

当前 default draft：

`cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`

## 固定现实

- 本轮新增 internal-only owner `runtime/cjgui/src/runtime_renderer_native_token_table_shell.cj`。
- 本轮新增四个 no-resource token shell callable。
- 本轮 route 是 classification shell，不是 issue / revoke shell。
- 本轮没有实现 mutable token table。
- 本轮没有创建 resource object table。
- 本轮没有绑定 native object。
- 本轮没有保存 raw pointer，也没有返回 native pointer / handle。
- 本轮没有修改 `runtime/cjgui/cjpm.toml`。
- 本轮没有修改 smoke native files。
- 本轮没有把 token shell facts 暴露为 public API。

## 固定边界

- 未新增 public API / diagnostics。
- 未调用 resource callable。
- 未创建 native object、native handle、raw pointer 或 native pointer return。
- 未新增 global mutable native table。
- 未调用 retain / release / destroy。
- 未导入 Cocoa / Metal / QuartzCore。
- 未调用 AppKit / Metal。
- 未提交 GPU work，未执行 render，未写 renderer state。
- 未修改 `runtime/cjgui/src/runtime_state.cj`。
- 未创建 backend-ready truth。

## 同形边界刹车

不得把 token table shell、token classification、capacity facts、token ownership hardening 或 smoke evidence 包装成 resource table permission、native handle permission、native object permission、Metal / AppKit permission、backend-ready permission、public API permission、receipt、record 或 publication。Token table shell 只定义 bridge-local no-resource token mechanics，不证明 resource exists。

## 后续入口

已由 `P1 internal Renderer native token table no-resource issue/revoke preflight decision` 接续；当前全局后续入口转为 `P1 internal Renderer platform object native callable preflight decision`。

下一轮若进入该入口，必须先确认 issue / revoke 是否能在 no resource binding、no pointer、fixed capacity、generation / epoch、main-thread confinement、fail-closed classification 与 no public surface 约束下实现；不得直接创建 resource object table、native object、native handle、raw pointer、Metal / AppKit resource、public API 或 backend-ready truth。

## 设计意图出口自检

- 本轮是否改变主题状态：是，native token table no-resource shell first implementation 已完成 manifest 封账。
- 本轮是否改变 canonical tail / endpoint：是，tail 转为 `CjguiInternalRendererNoNativeTokenTableShellReadiness` / `cjguiInternalExecuteDefaultRendererNativeTokenTableShellDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 固定为 `runtime_renderer_native_token_table_shell.cj`；truth 固定为 invalid token、capacity、enabled flag 与 token classification observed facts；stop-line 不变。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer native token table no-resource issue/revoke preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md`、`docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`、`docs/plans/topic-manifests/macos-bridge-verification-smoke.md`。
