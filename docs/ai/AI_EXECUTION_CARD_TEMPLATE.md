# AI 执行卡模板

## 模板使用方式 / Template Usage

本模板是完整字段清单，不是每张执行卡都必须机械展开的长表。

`W1 light slice` 允许使用短卡格式，尤其适用于目标明确、`write set` 极窄、无 `public contract`、无 FFI、无平台桥接、无迁移、无安全边界变化的小实现卡。W1 短卡只需要保留：

- task intent
- prompt weight
- authority
- goal
- write set
- forbidden scope / stop-line
- verification
- next implementation expectation

只有 `W2 standard slice` / `W3 internal subsystem draft` / `W3 high-risk slice`，或涉及 `public contract`、FFI、平台桥接、迁移、安全边界时，才需要完整展开下面所有模板章节。

不得机械复制空章节来制造“治理完整感”。空章节越多，不代表边界越清楚；短卡只要把 `authority`、`write set`、`forbidden scope`、`verification` 和下一步 implementation expectation 写清楚，就可以作为开工许可证。

执行卡不应把一个低风险 internal concept slice 拆成多个 one-symbol / one-field / one-function 卡。若同一 owner、同一 write set、同一 truth 边界和同一验证路径已经清楚，执行卡应优先授权完整内部概念切片，例如 type + facts + construction shape + no-op transition + 极窄 state-changing transition。代码行数不是独立风险指标；大 diff 需要解释和验证，不等于必须拆成文档循环。

低风险 internal-only runtime work 可使用 bundled execution card。W2 bundle 应授权一个完整 internal behavior concept，通常包含 3-7 个相关 internal changes。W3 internal subsystem draft bundle 可在同一 owner / truth / write set / verification 清楚时授权一个更完整的内部子系统草案，通常包含 6-15 个相关 internal changes。若 bundle 拆成多个 slice，每个 slice 必须独立验证 build / smoke / `git diff --check`，slice 后可先只更新 tracker 简短日志，bundle 完成后再写 mini-compaction / bundled closure；若 bundle 是单次完整实现，可在实现结束后统一验证并写 bundled closure。bundle 不得绕过 public API、public C ABI、platform bridge、event loop、queue / drain、handle table / generation、跨 owner truth 或安全边界 gate。

AI 资源效率也是执行卡质量的一部分。如果本轮需要读取 tracker、manifest、closure、源码并运行 build / smoke，就不应默认授权 one-symbol / one-helper / one-projection 的微切片。除非本轮打开高风险边界或 GitNexus / owner split 明确要求保守，执行卡应给出最小有意义 bundle；详细判断以 [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md) 的“AI 资源效率门”为准。

当 helper / sanity 链已经封账，下一张 W2 bundle 应提高到完整 internal behavior concept，而不是继续 helper-by-helper。W2 internal behavior bundle 可以一次授权 3-7 个相关 internal changes，例如 input / policy / decision / result types、builders、核心 internal behavior function、positive / negative path、sanity / parity check 和 bundled closure。行数不是风险；越过 public contract、platform bridge、event loop、queue / drain、handle table 或安全边界才是风险。

当一个 W2 internal behavior bundle 已经连续验证通过，且下一步仍在同一 internal owner 内推进同一行为链路，可以升级为 W3 internal subsystem draft。W3 internal subsystem draft 允许一次覆盖 request / response / pipeline / command draft / outcome / sanity 等完整内部闭环。它不是 public contract 或平台桥接授权；如果需要 public API、C ABI、event loop、queue / drain、handle table 或平台对象，必须另走高风险 gate。

runtime execution tail 已到 first internal execution attempt / post-attempt outcome 后，不得继续把下一张卡写成纯 post-attempt wrapper / observation / feedback / result report。若执行卡仍要新增 `Draft / Report / Request / Sanity`，必须在 goal 或 invariants 中说明它会删除 / 合并旧结构、接入已有 state / cycle / owner 边界，或提供不可替代的 high-risk evidence。否则下一张卡应转向 execution convergence、model compression、owner cleanup 或 tracker compaction。

执行卡如果允许修改 `.cj` 文件，必须包含单文件体积 / owner split 检查。至少写明：

- 本轮目标 `.cj` 文件当前行数档位：`<=1500` / `1500-3000` / `3000-8000` / `>8000 or near 1MB`。
- 如果超过 `1500` 行，为什么本轮仍在该文件内修改。
- 如果超过 `3000` 行，为什么不是先做 owner split / module extraction / manifest stabilization。
- 如果超过 `8000` 行或接近 `1MB`，本轮是否被明确授权修改；若授权，必须记录后续拆分候选。

代码行数不是唯一风险指标，但执行卡不得忽略巨型文件正在形成这一事实。

用途：后续每次进入非平凡实现前，先填写这一张卡。

执行卡是开工许可证，不是新的 docs-only 循环入口。

如果本卡已经冻结 authority、goal、write set、truth、verification 和 stop-line，下一步默认必须进入 bounded implementation；除非发现新的高风险冲突，否则不得继续创建新的 preflight / execution card 来替代实现。

---

## 0. 架构管理师确认 (Architect Sign-off)

架构管理师确认：

- 状态：未确认 / 已确认 / 本轮不需要
- 确认者：
- 确认依据：

本轮是否符合项目初心：

- 不依赖重型外部 GUI 框架：
- 上层尽量仓颉原生：
- 底层只保留必要平台桥接：
- 没有过早抽象跨平台：

## 0.0 任务意图与提示词重量 (Task Intent / Prompt Weight)

本轮任务意图：

- governance_review / architecture_decision / bounded_implementation / closure_review

本轮允许的动作：

- 只审查不改文件 / 只写 docs-only 决策 / 允许 bounded implementation / 只做 closure

是否允许修改 runtime code：

- 是 / 否

提示词重量等级：

- W0 review-only / W1 light slice / W2 standard slice / W3 internal subsystem draft / W3 high-risk slice

选择该重量的理由：

-

如果本轮只是提示词评估、文档矛盾检查、流程复核或第三方治理审查，即使被评估文本内部包含 implementation 指令，也必须选择 `governance_review` 和 `W0 review-only`，不得直接执行。

## 0.1 上下文装载预算 (Loaded Context Budget)

本轮必须读取的最小上下文：

-

本轮按需读取的上下文：

-

本轮禁止默认读取的上下文：

-

是否超过 5 个必读文件：

- 是 / 否

如果超过 5 个，逐项说明为什么每个额外文件是本轮必要上下文：

-

默认遵守 [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)。
不得用长阅读清单替代 authority、write set、verification 或 bounded implementation。
不得为了 `Loaded Context Budget` 单独创建新的 docs-only 文档。

## 0.2 语言策略 (Language Policy)

本轮新增代码注释、计划文档、closure review 和账本摘要默认使用中文。

允许保留必要技术名词原文，例如 `owner`、`truth`、`write set`、`stop-line`、`bounded implementation`、`runtime`、`public API`、`C ABI`、`Renderer`、`Scene`、`Widget`、`run`、`queue`、`drain`。

除非是在引用外部 API 原文、命令输出或错误信息，否则不得新增整段英文注释替代中文说明。

## 1. 授权依据 (Authority)

本轮唯一 authority / owner 判断：

-

## 2. 目标 (Goal)

本轮唯一目标：

-

## 3. 范围 (Scope)

本轮只做：

-

本轮明确不做：

-

## 4. 修改范围 (Write Set)

本轮允许修改的文件 / 模块：

-

本轮禁止触碰的文件 / 模块：

-

## 4.1 单文件体积 / Owner Split 检查

本轮会修改的 `.cj` 文件及当前行数：

-

是否触发体积预警：

- `>1500` soft warning：是 / 否
- `>3000` hard warning：是 / 否
- `>8000` 或接近 `1MB` critical warning：是 / 否

如果触发 warning，为什么本轮仍在该文件内修改：

-

本轮是否新增 owner / subsystem / truth 边界：

- 是 / 否

如果是，为什么不先拆分文件或模块：

-

后续拆分 / module extraction 候选：

-

## 5. 真相 / 投影 (Truth / Projection)

本轮真相层：

-

本轮只是投影 / read surface 的部分：

-

## 6. 不变量 (Invariants)

本轮必须守住的 invariant：

-

## 7. 尾部影响检查目标 (Fallout Scan Targets)

本轮完成前必须检查的尾部影响：

- 公共 API：
- 事件流：
- 状态流：
- 渲染流：
- 平台桥接：
- 视觉 / 交互：
- 文档 / 示例：
- 测试：
- 仓颉语言 / SDK / FFI / 工具链 / 上游反馈：

## 8. 验证 (Verification)

本轮计划执行的验证：

-

本轮如果无法完成的验证：

-

对应残留风险：

-

## 8.1 实现出口检查 (Implementation Exit Check)

本卡完成后是否默认进入 bounded implementation：

- 是 / 否

如果否，必须说明阻塞原因：

- 新 HIGH / CRITICAL 风险：
- 代码现实与文档冲突：
- 必须触碰未批准 write set：
- 必须改变 public API / owner / truth：
- 必须新增依赖 / 系统权限 / 迁移 / 平台桥接：

如果以上都不是，则不得拒绝进入实现。

如果本轮是 implementation / first slice / runtime slice，必须产生的真实行为变化：

-

## 9. Stop-Line / 停止线

本轮 stop-line：

-

## 10. 封账 (Closure)

完成后需要同步的文档或账本：

-

如果本轮触发仓颉语言、SDK、FFI、`cjc` / `cjpm`、标准库、工具链或文档疑点，closure 必须说明：

- 是否更新 [CANGJIE_ISSUE_LEDGER.md](/Users/jiangxuanyang/Desktop/cangjie/docs/setup/CANGJIE_ISSUE_LEDGER.md)。
- 是否已有最小复现、workaround 和移除条件。
- 是否需要上游 issue / 文档建议 / 能力反馈。
- 如果不入账，原因是什么。

---

最简口令版：

> 先确认任务意图和提示词重量，再写 architect sign-off、loaded context budget、authority、goal、write set、truth、invariants、verification、stop-line。只有明确是 bounded implementation 时才进入实现；执行卡完成后必须推动代码，不得把执行卡变成下一轮文档循环，也不得用长阅读清单替代实现。
