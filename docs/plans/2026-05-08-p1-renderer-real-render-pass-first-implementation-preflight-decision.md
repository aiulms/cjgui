# 渲染器真实 render pass 第一刀实现预检

日期：2026-05-08

状态：docs-only preflight / no runtime truth

## 文件定位

本文件执行 `P1 internal Renderer real render pass first implementation preflight decision`。目标是在 real command buffer shell 分支封账后，判断是否可以打开 real render pass 第一实现切片 runway。它不是 implementation，不新增 runtime owner，不创建真实 render pass descriptor，不创建 attachment / texture view，不创建 encoder，不调用 `renderCommandEncoder` / `endEncoding`。

## 预检判断

`CjguiInternalRendererNoRealCommandBufferShellReadiness` 足够作为 real render pass planning 的上游 endpoint。该 endpoint 已明确 no concrete command buffer object、no command buffer factory invocation、no commit、no presentation、no drawable acquisition、no encoding object、no render pass object、no pipeline object、no draw call、no work submit、no native resource stored、no pointer-like resource、no render execution、no state mutation 与 no public diagnostics。

real render pass 第一实现切片可以打开，但只能是 internal owner shell / dehydrated render pass result facts。

默认 owner candidate 固定为：

- `runtime/cjgui/src/runtime_renderer_render_pass_real.cj`

runtime input candidate 只消费：

- `CjguiInternalRendererNoRealCommandBufferShellReadiness`

输出 truth candidate 只允许：

- real render pass shell intent。
- render pass descriptor admission shell。
- attachment denial proof。
- encoder denial proof。
- render pass teardown / failure classification。
- no-real-render-pass-shell readiness facts。

## 第一切片范围

若进入 implementation，第一刀必须保持极窄：

- 只新增一个 internal-only owner shell。
- 只形成 dehydrated facts。
- 不创建真实 render pass descriptor。
- 不创建 attachment object、texture、texture view 或 drawable relation。
- 不创建 encoder，不调用 `renderCommandEncoder` 或 `endEncoding`。
- 不创建或提交 command buffer，不调用 `commandBuffer`、`commit`、`present` 或 `nextDrawable`。
- 不绑定 pipeline、buffer、texture、sampler 或 resource。
- 不修改 native bridge / Objective-C / Metal / AppKit / FFI。
- 不新增 C ABI / public API。

## 候选结论

候选 A 胜出：`P1 internal Renderer real render pass first implementation slice bundle`。

选择理由：

- 上游 command buffer shell endpoint 已提供足够 fail-closed / no-permission evidence，可作为 render pass planning evidence。
- 第一刀可以完全停留在 owner-local shell facts，不需要 native bridge write-set。
- render pass lifecycle manifest 与 implementation admission manifest 可作为 vocabulary evidence，但不能升格为 runtime truth。

候选 B 暂缓：command buffer shell hardening。当前没有证据显示 command buffer shell facts 不足。

候选 C 暂缓：native bridge render pass write-set preflight。当前第一刀不需要触碰 native bridge / Metal / AppKit / FFI。

候选 D 拒绝：direct render pass descriptor / attachment / encoder / command buffer / commit / GPU / render / state write / public API。

## 同形边界刹车

不得把 `CjguiInternalRendererNoRealCommandBufferShellReadiness`、render pass lifecycle manifest、render pass implementation admission manifest、command submission manifest、render execution manifest、state write manifest 或 smoke evidence 包装成 render-pass-ready permission、encoder-ready permission、GPU-submission permission、render permission、renderer-state-write permission、receipt、record 或 publication。

若选择 implementation，新增 owner 必须提供 render pass shell / descriptor admission shell / attachment denial proof / encoder denial proof / teardown failure classification 语义，而不是 thin wrapper。

## 停止线

- no real render pass descriptor creation。
- no attachment / texture view。
- no encoder creation。
- no `renderCommandEncoder`。
- no `endEncoding`。
- no real command buffer creation。
- no `commandBuffer`。
- no `commit`。
- no `present`。
- no `nextDrawable`。
- no pipeline / buffer / texture / resource binding。
- no GPU submission。
- no render execution。
- no renderer state write。
- no `runtime_state.cj` modification。
- no module-level `var`。
- no native bridge / Objective-C / Metal / AppKit / FFI modification。
- no C ABI / FFI declaration。
- no native handle / raw pointer。
- no retain / release / destroy。
- no public diagnostics / API。

## 设计意图出口自检

- 本轮是否改变主题状态：是，从 command buffer branch closure completed 推进到 real render pass first implementation preflight completed。
- 本轮是否改变 canonical tail / endpoint：否，preflight 只选择下一步，不新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：是，确定下一刀 owner candidate、runtime input candidate、truth candidate 与更窄 stop-line。
- 本轮是否改变唯一 next opening：是，转为 `P1 internal Renderer real render pass first implementation slice bundle`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`docs/plans/topic-manifests/renderer-implementation-admission-chain.md` 与 `docs/plans/topic-manifests/renderer-backend-readiness-real-backend-runway.md`。

## 唯一后续入口

`P1 internal Renderer real render pass first implementation slice bundle`
