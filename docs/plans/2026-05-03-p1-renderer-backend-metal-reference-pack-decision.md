# P1 Renderer backend / Metal reference pack decision

日期：2026-05-03

状态：docs-only reference-pack decision

## Purpose

本 decision 判断是否需要建立一个“小而硬”的 Renderer backend / Metal / AppKit 官方参考包，为未来 backend-readiness preflight 提供依据。

当前 renderer packet owner-truth milestone 已封账：

- [2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-renderer-packet-owner-truth-milestone-manifest.md)
- [2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-05-03-p1-internal-renderer-packet-owner-truth-milestone-stabilization-closure-review.md)

Current canonical packet truth 仍是：

- `CjguiInternalRendererPacketOrderingHardeningResult`
- `cjguiInternalExecuteDefaultRendererPacketOrderingHardeningDraft()`

当前 integration / backend-readiness evidence 暂不足。不批准 `runtime_renderer_packet_integration.cj`、post-normalization handoff wrapper、backend readiness wrapper、command buffer、render execution 或 renderer state write。

## Why Reference Pack Now

现在需要 reference pack，因为 packet truth 已经从 Scene / Renderer input、RenderCommand shape、material / batching hint、validation、normalization 推进并封账到 ordering / material grouping hardening endpoint。

继续直接寻找 integration / backend-readiness runtime owner 会面临两个风险：

- downstream owner / consumer / gate / integration evidence 仍不足，容易继续生成 receipt / record / publication / readiness thin wrapper。
- backend / Metal / AppKit 相关 lifecycle、resource ownership、frame pacing、drawable timing、scale / color space 事实尚未用官方资料固定，过早 preflight 容易把 value vocabulary 误读成 backend permission。

因此下一步应先建立小型官方参考包，为未来 backend-readiness preflight 提供硬依据。Reference pack 只服务未来 preflight，不批准 implementation。

## Reference Scope

Reference pack 范围必须小而硬，优先官方资料，只收集未来 backend preflight 必要依据。

Primary official scope：

- Metal command buffer / render command encoder / render pass lifecycle。
- `CAMetalLayer` drawable lifecycle。
- AppKit `NSView` / layer-backed view / resize lifecycle。
- frame pacing / display refresh / drawable acquisition timing。
- Retina scale factor / color space / backing scale。
- resource ownership：device / layer / command queue / drawable / render pass 谁拥有、谁释放。

Secondary context only：

- Flutter / Impeller 的 DisplayList 与 backend 分层。
- Chromium compositor / Skia 的 paint record / compositor 分层。
- Zed / GPUI 的自绘 + GPU 路线。

Secondary context 只能帮助识别架构问题清单，不能替代 Apple 官方资料，也不能作为打开 backend implementation 的证据。

## Explicit Non-goals

本 decision 不做大规模调研，不做架构重论证，不实现 backend，不写 runtime code。

本阶段仍只服务 renderer backend-readiness evidence，不引入：

- Text / IME / Accessibility。
- dirty-region / diff / patch / incremental render。
- Widget / Layout / ECS。
- backend packet。
- command buffer。
- render execution。
- renderer state write。
- platform resource owner boundary implementation。

## Candidate Comparison

### A. P1 internal Renderer backend / Metal reference pack bundle implementation

选择。

理由：

- 它保持 docs-only，只创建 reference pack，记录官方资料、要点、未来 preflight 问题清单。
- 它能补齐 backend-readiness 前最缺的 platform lifecycle / resource ownership / frame pacing evidence。
- 它不会创建 runtime owner、backend wrapper、command buffer 或 platform object。

### B. Backend-readiness preflight

暂缓。

Backend-readiness preflight 需要先依赖 reference pack 固定官方事实。当前直接 preflight 仍容易把 packet owner-truth milestone 误读成 backend readiness。

### C. Backend / Metal implementation

拒绝。

当前不批准 Metal / AppKit implementation、CAMetalLayer owner、MTLDevice、command queue、command buffer、render pass、draw call 或 renderer state write。

### D. Command buffer / render execution / renderer state write

拒绝。

这些属于真实 backend execution runway，不是 reference decision 范围。

### E. Platform resource owner boundary implementation

暂缓。

需要 reference pack 后再评估 platform lifecycle、ownership、release、threading 与 artifact policy。

### F. Dirty-region / Widget / Layout / Text / IME / Accessibility

暂缓。

P1 当前仍固定 full DisplayList / command list rebuild。UI system 与 incremental render 需要独立 owner truth。

### G. Public surface expansion

拒绝。

public allowlist 不变，仍只有 `cjguiExperimentalQueueSubmitShellReady(): Bool`。

### H. Consolidation

暂缓。

只有发现明确 duplicate / low-value helper / self-wrapping evidence 时才选择。当前缺口是 backend reference evidence，不是 runtime consolidation evidence。

## Same-shape Boundary Brake

Same-shape Boundary Brake 在本轮通过 reference-pack decision 生效：

- 本轮不是新增 runtime boundary。
- 不允许用 “reference pack” 名义创建 backend wrapper。
- 不允许新增 backend-readiness wrapper、platform-resource readiness wrapper、command-buffer readiness wrapper。
- 不允许把 packet owner-truth milestone 解释成 backend readiness、Metal implementation permission 或 render permission。

如果选择下一阶段 A，下一轮也必须 docs-only，只创建 reference pack，不写 runtime code。

Backend-readiness、platform resource owner boundary、command buffer、render execution、renderer state write 必须等 reference pack 后再做 docs-only preflight。

## Stop-line

继续禁止：

- no runtime code in this decision round。
- no `.cj` modifications。
- no backend / Metal / AppKit implementation。
- no CAMetalLayer / MTLDevice / command buffer。
- no native handle / raw pointer / platform object。
- no renderer state write。
- no render execution / draw call。
- no GPU batching / draw-call merge。
- no sorting side effect。
- no packet mutation。
- no dirty-region / diff / patch / incremental render。
- no Widget / Layout / Text / IME / Accessibility / ECS implementation。
- no public surface expansion。
- no `cjguiExperimentalQueueSubmitShellReady(): Bool` signature change。
- no `runtime_state.cj` touch。
- no `runtime/cjgui/cjpm.toml` change。
- no smoke / harness / native bridge / entry modifications。

## Decision

最终 next opening：

`P1 internal Renderer backend / Metal reference pack bundle implementation`

下一轮应保持 docs-only，创建小型 reference pack，记录官方资料、关键要点和未来 backend-readiness preflight question list。它不批准 backend implementation、Metal / AppKit implementation、CAMetalLayer / MTLDevice / command buffer、platform resource、renderer state write、render execution、draw call、public surface expansion、dirty-region 或 UI system implementation。
