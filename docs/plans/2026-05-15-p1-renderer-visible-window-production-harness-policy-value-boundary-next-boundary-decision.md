# Renderer visible-window production harness policy value boundary 下一边界裁定

## 本轮裁定

本轮选择 A：当前 policy value boundary 已足够封账，下一步进入 native implementation preflight decision。

唯一后续入口：

`P1 internal Renderer visible-window production harness native implementation preflight decision`

## 裁定理由

`runtime_renderer_visible_window_production_harness.cj` 已把 production visible-window harness 的 owner / truth / stop-line 固定为内部值事实：

- production visible `NSWindow` ownership policy。
- bounded run loop policy。
- display-backed `CAMetalLayer` prerequisite。
- token-backed `NSView` / `CAMetalLayer` / `MTLDevice` alignment policy。
- cleanup co-ownership policy。
- headless / CI-like fail-closed policy。
- no native `NSWindow` harness。
- no production `nextDrawable` / drawable acquire。
- no color attachment / encoder / draw / `commit` / `present` / GPU submission / render。

继续新增 policy receipt / record / publication wrapper 会回到 thin wrapper。下一个有效动作不是继续包装 readiness，而是先对 native harness 是否可打开做 preflight。

## 下一阶段允许范围

下一阶段只允许写 docs-only preflight / decision / reconciliation，除非 preflight 明确批准 implementation 写集。默认仍不得修改 production native bridge、不得创建 native `NSWindow` harness、不得调用 production `nextDrawable`。

## 下一阶段必须回答

- production native `NSWindow` harness 是否可以打开。
- 若可以打开，写集是否仍限于 production native `.h/.m` 的极窄 C ABI。
- 是否需要先补 bridge-local token ownership / bounded run loop / teardown co-ownership 的更窄 preflight。
- 是否需要新增 native probe，还是只能先做 docs-only recovery。
- 哪些 stop-line 仍继续禁止：`nextDrawable`、color attachment、encoder、draw、`commit`、`present`、GPU submission、renderer state write 与 public API。

## 本轮拒绝路线

拒绝 B：直接实现 native `NSWindow` harness。

原因是当前用户明确要求本轮只做 visible-window production harness policy value boundary，不进入 native `NSWindow` harness；本轮 owner 也只提供 policy readiness，不是 implementation admission。

拒绝 C：直接恢复 production drawable acquire / classify / release。

原因是 production drawable lifetime 仍等待 native harness preflight，且 production `nextDrawable` 仍是硬 stop-line。

拒绝 D：继续新增 policy wrapper。

原因是当前 endpoint 已足够表达 policy facts，再包一层 receipt / record / publication 不能解除 display chain blocker。

## 设计意图出口自检

- 本轮是否改变主题状态：是。policy value boundary 已完成，下一步进入 native implementation preflight decision。
- 本轮是否改变 canonical tail / endpoint：否。本裁定复用本阶段新增 endpoint。
- 本轮是否改变 owner / truth / stop-line：是。truth 固定下一步必须先 preflight，stop-line 不放宽。
- 本轮是否改变唯一 next opening：是。唯一后续入口转为 `P1 internal Renderer visible-window production harness native implementation preflight decision`。
- 是否同步 topic manifest：需要同步。
