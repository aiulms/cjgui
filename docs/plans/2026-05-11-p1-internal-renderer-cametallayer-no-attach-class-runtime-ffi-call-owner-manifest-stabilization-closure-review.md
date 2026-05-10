# P1 内部渲染器 CAMetalLayer no-attach 类可见性与 runtime 调用清单稳定化封账

日期：2026-05-11

状态：manifest stabilization closure / no-attach A 路线封账

## 封账结论

`P1 internal Renderer CAMetalLayer platform layer runway macro bundle` 本轮只完成 A 路线并封账。`CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` 成为最新 canonical tail。B / C / D 未进入，后续必须从 allocation without attachment preflight 重新开 gate。

## 已固定内容

- Production bridge 允许 QuartzCore import，但仅用于 no-attach class availability。
- `CAMetalLayer` class lookup 只返回 integer classification，不返回 `Class` / `id` / pointer / handle。
- Runtime internal owner 调用 no-attach C ABI 并脱水为 facts。
- Probe 固定 no allocation、no attachment、no Metal、no drawable、no pointer return。
- `runtime/cjgui/cjpm.toml` 未修改。
- `runtime_state.cj` 未触碰。
- public declaration allowlist 不变。

## 不足与未进入项

- 未证明 `CAMetalLayer` allocation 可行。
- 未证明 token-backed `CAMetalLayer` table 可行。
- 未证明 `CAMetalLayer` attach / detach 可行。
- 未证明 Metal device binding、drawable acquisition、render 或 GPU submission 可行。
- 未证明 backend ready。

## 后续入口

唯一 next opening：

`P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`

## 设计意图出口自检

- 本轮是否改变主题状态：是，macro bundle 从 attachment planning 推进到 no-attach class/runtime FFI call owner A 路线封账。
- 本轮是否改变 canonical tail / endpoint：是，最新 tail 为 `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` / `cjguiInternalExecuteDefaultRendererCAMetalLayerNoAttachCallDraft()`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_cametallayer_no_attach_call.cj`；truth 仅限 QuartzCore import、`CAMetalLayer` class available、no-attach admission、allocation still blocked、device binding still blocked facts；stop-line 继续禁止 layer allocation / attachment、Metal、drawable、state write、public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
