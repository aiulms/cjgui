# P1 渲染器 CAMetalLayer no-attach 类可见性与 runtime 调用下一阶段选择

日期：2026-05-11

状态：next-boundary decision / 进入 allocation without attachment 预检

## 本轮选择

选择 A：

`P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`

选择理由：

- `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness` 已固定 QuartzCore import available、`CAMetalLayer` class available、no-attach admission、allocation still blocked 与 device binding still blocked facts。
- no-attach probe 已覆盖符号存在、可调用、no allocation、no attachment、no Metal、no drawable、no pointer return。
- 当前只证明 production bridge 可看见 `CAMetalLayer` class 并在 runtime internal owner 中读取 no-attach facts，不证明可以创建或 attach layer。
- 下一阶段自然应先评估 main-thread immediate-release allocation feasibility，而不是直接 token table 或 attach/detach。

## 拒绝路线

- 拒绝直接进入 token-backed `CAMetalLayer` table。
- 拒绝直接 attach 到 token-backed `NSView`。
- 拒绝创建 / 查询 `MTLDevice`、command queue、drawable 或 command buffer。
- 拒绝设置 `NSView.layer` / `wantsLayer`。
- 拒绝 public API / diagnostics。
- 拒绝 renderer state write 或触碰 `runtime_state.cj`。

## 下一阶段边界

下一阶段只能判断是否允许创建一个 `CAMetalLayer` 后立即释放 / 清理，且必须 main-thread、no attach、no Metal device、no drawable、no pointer return。若 allocation 需要 `NSView.layer` / `wantsLayer` / Metal device / pointer surface，必须停止。

## 设计意图出口自检

- 本轮是否改变主题状态：是，no-attach class/runtime FFI call owner 已封账，下一阶段转入 allocation without attachment 预检。
- 本轮是否改变 canonical tail / endpoint：是，当前 tail 为 `CjguiInternalRendererNoCAMetalLayerNoAttachCallReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，owner 为 `runtime_renderer_cametallayer_no_attach_call.cj`；truth 仅限 no-attach observed facts；stop-line 继续禁止 layer allocation / attachment、Metal、drawable、state write、public API。
- 本轮是否改变唯一 next opening：是，固定为 `P1 internal Renderer CAMetalLayer allocation without attachment preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。
