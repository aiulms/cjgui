# P1 Minimal Runtime Skeleton Surface Phase Closure / Compaction Preflight

日期：2026-04-26

性质：docs-only / phase closure / compaction preflight / no implementation

状态：完成；不批准直接实现

范围：复核 minimal runtime skeleton 的 app lifecycle、window lifecycle、platform adapter、error strategy 四条 comment-only surface 是否已经足以封账，并判断下一条 opening 是否应转向 runtime build / package boundary。本轮不修改 `runtime/`，不修改 `labs/macos_bridge_smoke/`，不写 runtime 代码，不创建 package / build config，不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 1. 本轮依据

本轮重点依据最近四条 runtime surface closure：

- [P1 app lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-app-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 window lifecycle surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-window-lifecycle-surface-comment-only-refinement-closure-review.md)
- [P1 platform adapter surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-platform-adapter-surface-comment-only-refinement-closure-review.md)
- [P1 error strategy surface comment-only refinement closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-error-strategy-surface-comment-only-refinement-closure-review.md)

同时依据：

- [P1 minimal app/window lifecycle runtime skeleton closure review](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-app-window-lifecycle-runtime-skeleton-closure-review.md)
- [P1 minimal runtime skeleton closure / app-window lifecycle surface review preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-minimal-runtime-skeleton-closure-app-window-lifecycle-surface-review-preflight.md)
- [P1 smoke-to-runtime boundary preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-smoke-to-runtime-boundary-preflight.md)
- [P1 red-team risk intake / runtime guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-red-team-risk-intake-runtime-guardrails-preflight.md)
- [P1 self-drawn platform reduction / IME / accessibility guardrails preflight](/Users/jiangxuanyang/Desktop/cangjie/docs/plans/2026-04-26-p1-self-drawn-platform-reduction-ime-accessibility-guardrails-preflight.md)
- [GUI project direction](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_PROJECT_DIRECTION.md)
- [GUI governance](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [GUI risk ledger](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_RISK_LEDGER.md)
- [AI code quality governance](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI development constitution](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_DEVELOPMENT_CONSTITUTION.md)

当前 runtime skeleton 只读确认：

- [runtime/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/README.md)
- [runtime/cjgui/README.md](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/README.md)
- [runtime/cjgui/src/app_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/app_lifecycle.cj)
- [runtime/cjgui/src/window_lifecycle.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/window_lifecycle.cj)
- [runtime/cjgui/src/platform_adapter.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/platform_adapter.cj)
- [runtime/cjgui/src/error.cj](/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/src/error.cj)

## 2. 当前 Minimal Runtime Skeleton Surface Phase 是否可以收束

结论：可以收束。

理由：

- minimal runtime skeleton 已经从 `labs/` 独立出来，且没有迁移 smoke code。
- 四条核心 surface 已经分别完成 comment-only refinement 和 closure。
- 每条 surface 都明确了 owner、relation、future slots、stop-line 和未实现边界。
- `.cj` 文件仍保持 comment-only，没有制造未经验证的仓颉语法事实。
- 没有 package / build config，因此没有把 skeleton 伪装成可编译 runtime。
- smoke guard 仍只作为旧链路 guard，不是正式 runtime test framework。

本阶段可以封账为：

> minimal runtime skeleton surface 已经足够支撑下一条 build / package boundary 讨论，但仍不能代表 runtime implementation。

## 3. 四条 Comment-only Surface 是否足够封账

结论：足够封账，且不建议继续拆更多 comment-only surface。

已经封账的四条 surface：

- app lifecycle：冻结 future app lifecycle owner、platform adapter relation、`run` / `shutdown` / `request quit` / queue / drain future slot、no platform runloop truth、no global tick。
- window lifecycle：冻结 future window lifecycle owner、app lifecycle relation、platform adapter relation、create / request close / destroy / release future slot、stale message、single-window first slice、handle table / generation future trigger。
- platform adapter：冻结 adapter owner、app / window relation、platform object ownership stays internal、dehydrated facts to core、forbidden facts to core、main-thread ownership boundary、smoke bridge non-migration、no platform runloop truth in core。
- error strategy：冻结 error strategy owner、app / window / adapter relation、smoke `last_error` non-migration、structured / call-associated / non-global / concurrency-safe future errors、minimum classification vocabulary、fail-closed policy、diagnostics not state truth。

继续拆更多 comment-only surface 的收益已经下降：

- owner 和 stop-line 已经足够清楚。
- 再拆 surface 容易加重治理反噬和上下文过载。
- 下一步真正阻塞的是 build / package boundary，而不是更多注释边界。
- 继续写 comment-only `.cj` 会逐渐接近“文档代替实现”的风险。

因此本轮建议结束 surface expansion。

## 4. 当前阶段冻结为 Truth 的边界

当前阶段 truth 仅限以下内容：

- `runtime/` 是未来正式 runtime 的实验期 skeleton 区域，不是 `labs/macos_bridge_smoke` 的扩写。
- `labs/macos_bridge_smoke` 继续是 smoke / lab evidence / guard，不是正式 runtime。
- smoke code、smoke C ABI、smoke build script、smoke diagnostics、auto-close、clear-color render path、screenshot / frame hash diagnostics 和 smoke `last_error` 不直接迁移为 runtime contract。
- `runtime/cjgui` 当前只包含 comment-only surface，不定义 public runtime API，也不定义 public C ABI。
- app lifecycle、window lifecycle、platform adapter、error strategy 各自有独立 conceptual owner。
- platform objects 可以由 future platform adapter 内部持有，但不得泄露到 core public surface。
- core runtime 不得持有 `NSRunLoop`、`NSEvent`、`dispatch_main`、Objective-C callback truth、native handle 或 raw platform event object。
- core 未来只能消费脱水 lifecycle / window / failure / queue / future input / future redraw facts。
- 默认不允许 global tick / blind redraw / frame scheduler。
- Text / Input / IME / Accessibility、Renderer / Scene / Widget / Layout / DSL、semantic tree / Action Router 仍关闭。
- diagnostics 只是 evidence / closure review 辅助材料，不能成为第二状态真相源。

这些 truth 是当前阶段的压缩结论，不等于新增能力。

## 5. 明确仍未实现的内容

当前仍未实现：

- runtime package / build entry。
- 非注释仓颉 runtime syntax。
- public runtime API。
- public C ABI。
- app lifecycle implementation。
- window lifecycle implementation。
- platform adapter implementation。
- error strategy implementation。
- error enum、Result type 或 exception-like mechanism。
- main-thread queue / drain。
- event loop。
- window create / request close / destroy / release。
- handle table / generation。
- multi-window、target update、async UI message targeting。
- platform object hiding enforcement。
- runtime tests。
- Renderer / Scene / Widget / Layout / DSL。
- Dirty Rect / invalidation / global tick / frame scheduler。
- Text / Input / IME / Accessibility。
- semantic tree / Action Router。
- command-list hash / pixel diff / baseline / offscreen renderer。

## 6. Residual Risks

残留风险：

- 没有 build / package boundary，后续无法做 Cangjie build check。
- 没有 module layout / package owner，非注释仓颉语法还不能安全出现。
- 没有 public / internal API 边界，任何函数签名都可能过早固化。
- 没有 runtime test strategy，smoke guard 仍只保护旧链路。
- 没有真实 platform adapter，平台对象隐藏仍只是文档纪律。
- 没有 handle table / generation，future async target message 仍不能打开。
- 没有 structured error model，错误分类仍只是语义边界。
- 治理文档数量已经很高，继续拆 surface 会加剧上下文过载。

这些风险不阻塞本轮 phase closure，但会决定下一步必须先冻结 build / package boundary。

## 7. 是否创建 `CJGUI_TRUTH_MANIFEST.md`

结论：当前不创建。

原因：

- 本轮只是 phase closure / compaction preflight，不是 governance manifest execution card。
- 当前可以先把最小 truth snapshot 写在本 preflight 和 tracker 中。
- 直接创建 `CJGUI_TRUTH_MANIFEST.md` 会改变治理结构，应另开 `P1 governance compaction / truth manifest preflight`。
- manifest 只能压缩已有决策，不能发明新架构能力，也不能取代当前 execution card 的局部 authority。

登记 future opening：

> `P1 governance compaction / truth manifest preflight`

但不作为下一步默认 opening。

## 8. 是否进入真实 Runtime Implementation

结论：不进入。

原因：

- 当前没有 build / package boundary。
- 当前没有允许非注释仓颉语法的 execution card。
- 当前没有 module owner、package entry、build entry 或 test entry。
- 当前 public / internal API 边界未冻结。
- 当前 Cangjie syntax / package layout 需要按本地官方文档或 CangjieSkills 查证。
- 直接实现会把 comment-only surface 误升级为 runtime truth。

任何真实 runtime implementation 前，至少需要先完成 runtime build / package boundary preflight 和受限 execution card。

## 9. 下一步：Build / Package Boundary 还是继续 Surface 文档

推荐下一步：

> `P1 runtime build/package boundary preflight`

不建议继续拆更多 surface 文档。

原因：

- app/window/platform/error 四条 surface 已经足够清楚。
- 当前真正缺口是“什么时候、以什么 package / module / build entry 允许第一行非注释仓颉语法出现”。
- build / package boundary 应先于任何可编译 skeleton、函数签名或 runtime behavior。
- 继续 surface 文档会增加治理负担，但不能让 skeleton 更接近可验证代码。

## 10. Runtime Build / Package Boundary Preflight 应回答什么

下一篇 `P1 runtime build/package boundary preflight` 至少应回答：

- package owner 是谁。
- package / module 名称是否使用 `runtime/cjgui`。
- 是否允许创建 `cjpm.toml` 或其他 build config。
- build entry 和 test entry 是否存在；如果存在，最小文件路径是什么。
- 当前是否允许非注释仓颉语法；如果允许，最多允许什么。
- 是否允许定义 internal-only 函数签名；是否仍禁止 public runtime API。
- 是否允许保留 comment-only `.cj` 并只创建 package metadata。
- 可编译 skeleton 的最小范围是什么。
- build output / cache 应写到哪里，是否允许进入仓库。
- 验证命令应使用 `cjc`、`cjpm` 还是现有 smoke guard。
- 何时必须读取 CangjieSkills、本地官方文档或现有 smoke demo。
- 如何避免 package boundary 反向打开 app lifecycle、window lifecycle、platform adapter 或 error strategy implementation。
- smoke guard 和 future runtime build check 的关系是什么。
- 不支持的内容如何 fail closed，而不是创造假 API。

## 11. Build / Package Boundary 是否应先于非注释仓颉语法

结论：应该。

在 build / package boundary 冻结前，不应写非注释仓颉 runtime code。

原因：

- 没有 package owner，就没有语法 truth 的落点。
- 没有 build entry，就不能验证非注释仓颉语法。
- 没有 module boundary，函数签名容易被误读为 public API。
- 没有测试 / build command，AI 只能靠记忆判断仓颉语法，违背代码质量治理。
- 当前 `.cj` comment-only 状态本身就是 stop-line。

## 12. 为什么当前 Cangjie Build Check 不适用

当前 Cangjie build check 不适用，因为：

- `runtime/cjgui/src/*.cj` 全部仍为 comment-only surface。
- 当前没有 runtime package / build entry。
- 当前没有 `cjpm.toml` 或等价 build config。
- 当前不允许为验证而创建 build config。
- 当前没有任何被批准的非注释仓颉 syntax 或函数签名。

当前应继续记录：

```text
Cangjie build check not applicable yet: comment-only runtime surface, no package/build entry by design.
```

## 13. 什么时候才允许推进到可编译 Skeleton

只有满足以下条件时，才允许从 comment-only skeleton 推进到可编译 skeleton：

- 完成 `P1 runtime build/package boundary preflight`。
- 完成对应 execution card。
- execution card 明确允许创建 package / build config。
- execution card 明确允许哪几处 `.cj` 文件写入非注释仓颉语法。
- execution card 明确 public / internal API 边界。
- 执行前按需查证 CangjieSkills、本地官方文档或现有 smoke demo。
- 执行后能运行指定 `cjc` / `cjpm` / smoke guard / static check 命令。
- closure review 记录 build command、exit code、未做项和 stop-line。

在这些条件满足前，runtime skeleton 继续保持 comment-only。

## 14. 本轮 Stop-line

本轮强制保持：

- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/runtime/`。
- 不修改 `/Users/jiangxuanyang/Desktop/cangjie/labs/macos_bridge_smoke/`。
- 不写 runtime 代码。
- 不新增 package / build config。
- 不定义 public runtime API。
- 不定义 public C ABI。
- 不实现 app lifecycle / window lifecycle / platform adapter / error strategy。
- 不定义 error enum / Result type。
- 不迁移 smoke code / smoke C ABI / smoke `last_error`。
- 不实现 handle table / generation。
- 不暴露 AppKit / Metal / Objective-C platform objects。
- 不实现 Renderer / Scene / Widget / Layout / DSL。
- 不实现 Dirty Rect / global tick / frame scheduler。
- 不实现 Text / Input / IME / Accessibility。
- 不实现 semantic tree / Action Router。
- 不实现 command-list hash / pixel diff / baseline / offscreen renderer。
- 不创建 `CJGUI_TRUTH_MANIFEST.md`。

## 15. 结论

当前 minimal runtime skeleton surface phase 可以收束。

app lifecycle、window lifecycle、platform adapter、error strategy 四条 comment-only surface 已经足够封账，不建议继续拆更多 comment-only runtime surface。

不建议直接进入真实 runtime implementation。

下一步推荐 docs-only：

> `P1 runtime build/package boundary preflight`

该 opening 只应冻结 package owner、build entry、module boundary、是否允许非注释仓颉语法、最小可编译 skeleton 范围、验证命令以及 CangjieSkills / 本地官方文档查证边界；不自动开启 runtime implementation。
