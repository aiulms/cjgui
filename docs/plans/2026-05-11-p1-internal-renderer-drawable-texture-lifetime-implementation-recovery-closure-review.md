# Drawable texture lifetime 实现恢复复核

日期：2026-05-11

## 本轮完成

本轮完成 docs-only recovery decision：

- 读取 production drawable texture lifetime planning manifest / closure。
- 读取 render pass descriptor color attachment recovery manifest / closure。
- 读取 drawable no-present acquisition 与 visible-window probe manifest。
- 读取 command queue / command buffer runtime call manifest。
- 读取 render pass descriptor create / destroy manifest。
- 读取 Metal device binding 与 `CAMetalLayer` runtime attachment manifest。
- 固定路线选择：暂停 production drawable lifetime implementation，转向 render command encoder no-submit planning。

## 关键判断

Production drawable lifetime blocker 不是 renderer 失败，而是 display / drawable 环境证据不足：

- isolated visible-window no-present probe 已经证明当前机器可观察 drawable。
- 该 probe 没有改变 production runtime window semantics。
- production runtime 仍缺 visible window ownership、bounded run loop harness、drawable token table、release / cleanup classification、descriptor / drawable / layer / device cleanup co-ownership。
- 因此不能把 isolated drawable evidence 升级成 production drawable texture lifetime truth。

## 路线收口

本轮选择 B：

- production drawable lifetime 暂停。
- visible-window production harness 作为独立恢复 / 实验分支保留。
- 主线下一步转向 render command encoder no-submit planning preflight。

该下一步只允许规划 encoder 前置条件，不能创建 encoder，不能配置 drawable texture，不能 `draw` / `commit` / `present`。

## 未实现内容

- 未新增 production drawable acquire / classify / release C ABI。
- 未调用 production `nextDrawable`。
- 未新增 drawable token table。
- 未配置 color attachment。
- 未创建 render command encoder。
- 未创建 command buffer / encoder。
- 未 `draw` / `commit` / `present`。
- 未提交 GPU work。
- 未执行 render。
- 未写 renderer state。
- 未新增 public API / diagnostics。
- 未修改 `runtime/cjgui/cjpm.toml`。
- 未触碰 `runtime_state.cj`。

## GitNexus 记录

上游 endpoint / default draft impact 均返回 `UNKNOWN` / not found / impactedCount `0`；未出现 HIGH / CRITICAL 风险输出。本轮只修改 docs / index / manifests，未修改 `.cj` owner、production native 或 native scripts，因此按 docs-only 验证要求执行静态检查。

## 设计意图出口自检

- 本轮是否改变主题状态：是，production drawable texture lifetime 从 planning tail 转入 recovery decision tail。
- 本轮是否改变 canonical tail / endpoint：否，runtime endpoint 仍是 `CjguiInternalRendererNoDrawableTextureLifetimePlanningReadiness`。
- 本轮是否改变 owner / truth / stop-line：是，truth 变为“production drawable lifetime 暂停；visible-window harness 独立；encoder no-submit planning 可先行但不得创建 encoder”；stop-line 未放宽。
- 本轮是否改变唯一 next opening：是，当时唯一 next opening 改为 `P1 internal Renderer render command encoder no-submit planning preflight decision`；现已由 no-submit planning 接续，当前最新后续入口是 `P1 internal Renderer render command encoder creation blocker reconciliation decision`。
- 是否同步 topic manifest：是。
- 已同步哪些 topic manifest：`renderer-implementation-admission-chain.md`、`renderer-backend-readiness-real-backend-runway.md`、`macos-bridge-verification-smoke.md`。

## 唯一后续入口

当时唯一后续入口为：

`P1 internal Renderer render command encoder no-submit planning preflight decision`

当前已接续至：

`P1 internal Renderer render command encoder creation blocker reconciliation decision`
