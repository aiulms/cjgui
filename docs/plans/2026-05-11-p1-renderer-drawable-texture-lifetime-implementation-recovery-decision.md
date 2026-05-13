# Drawable texture lifetime 实现恢复决策

日期：2026-05-11

## 本轮结论

本轮选择 B：production drawable texture lifetime 暂停，下一步转向 `P1 internal Renderer render command encoder no-submit planning preflight decision`。

该入口已由 render command encoder no-submit planning 与 blocker reconciliation 阶段接续；当前最新后续入口是 `P1 internal Renderer pipeline state no-draw planning preflight decision`。

本轮不选择 A 作为主线下一步。visible-window production harness 仍是 production drawable lifetime 的真实缺口，但它应该作为独立实验 / recovery 分支推进，不能继续污染 production bridge 的 drawable texture lifetime 合同。

本轮不选择 C。当前证据不足以打开 production drawable acquire / classify / release first slice。

本轮不进入 D。证据没有互相冲突，而是指向同一个缺口：isolated visible-window no-present drawable 可观察，但 production drawable texture lifetime ownership 尚未成立。

## 缺口复核

Production drawable lifetime 当前缺少以下事实：

- 缺 visible `NSWindow` ownership：production runtime 没有可见窗口所有权合同，现有 evidence 只来自 isolated probe。
- 缺 bounded run loop production harness：现有 bounded run loop 只在 isolated visible-window probe 内成立，不是 production runtime harness。
- 缺 display-backed layer ownership：production bridge 可以 token-backed attach layer / bind device，但没有把 display backing 与 drawable acquisition lifetime 纳入 production owner。
- 缺 drawable token table：production native 没有 drawable token-local acquire / classify / release table。
- 缺 release / cleanup semantics：没有 valid / released / stale / double release fail-closed 分类，也没有 cleanup 后 drawable / layer / device / view 的共同归零证明。
- 缺 descriptor / drawable co-ownership：`MTLRenderPassDescriptor` token lifecycle 已存在，但 descriptor 与 drawable texture、layer、device 的共同所有权仍未封账。

这些缺口阻塞 color attachment implementation，也阻塞任何 production `nextDrawable` acquire / release C ABI。

## 与 command buffer / encoder no-submit 的关系

这些缺口不阻塞继续做 render command encoder no-submit planning，但会阻塞真实 encoder creation：

- 已有 `MTLCommandQueue` 与 `MTLCommandBuffer` token-backed lifecycle facts，可作为 no-submit planning 上游。
- 已有 `MTLRenderPassDescriptor` create / destroy facts，可作为 descriptor lifecycle 上游。
- 但没有 drawable texture lifetime，因此不能配置 color attachment，也不能创建真实 render command encoder。
- 下一步若进入 encoder 方向，只能先写 no-submit planning / admission facts，固定 encoder 的前置条件、stop-line 与 failure classification。

因此本轮选择把 visible-window production harness 作为独立恢复分支，把主线 next opening 转向 render command encoder no-submit planning preflight。

## 禁止事项

本轮不新增 production drawable acquire / classify / release C ABI，不调用 production `nextDrawable`，不新增 drawable token table，不配置 `colorAttachments[0]`，不创建 render command encoder，不 draw，不调用 `commit` / `present`，不提交 GPU work，不执行 render，不写 renderer state，不触碰 `runtime_state.cj`，不修改 `runtime/cjgui/cjpm.toml`，不新增 public API / diagnostics，不返回 native pointer / handle / `id` / `Class`。

## GitNexus 记录

对上游 endpoint / default draft 运行 impact：

- `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`：当前索引返回 not found / impactedCount `0` / risk `UNKNOWN`。
- `cjguiInternalExecuteDefaultRendererDrawableTextureLifetimePlanningDraft`：当前索引返回 not found / impactedCount `0` / risk `UNKNOWN`。

该结果符合近期新增 owner 未索引状态；本轮为 docs-only，使用源码阅读、manifest 复核与静态扫描兜底。

## 设计意图出口自检

- 本轮是否改变主题状态：是，production drawable texture lifetime 从 planning facts 进入 implementation recovery decision。
- 本轮是否改变 canonical tail / endpoint：否，runtime canonical tail 仍是 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 明确为 production drawable lifetime 暂停，visible-window harness 独立化，主线转向 encoder no-submit planning；stop-line 继续禁止 production `nextDrawable` acquire / release、color attachment、encoder creation、commit、present、GPU submission、render、public API 与 renderer state write。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 改为 `P1 internal Renderer render command encoder no-submit planning preflight decision`；现已由 no-submit planning 与 blocker reconciliation 接续，当前最新后续入口是 `P1 internal Renderer pipeline state no-draw planning preflight decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 唯一后续入口

当时唯一后续入口为：

`P1 internal Renderer render command encoder no-submit planning preflight decision`

当前已接续至：

`P1 internal Renderer pipeline state no-draw planning preflight decision`
