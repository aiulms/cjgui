# CJGUI 治理 Skill 化计划

最后更新：2026-04-27

性质：skillization plan / governance packaging
状态：草案
范围：用于规划如何把 CJGUI 的治理文档提炼成可复用、可触发、低上下文负担的 AI skill。

## 0. 背景

CJGUI 当前已经形成一套项目治理机制：

- docs-only gate
- preflight
- execution card
- bounded implementation
- closure review
- owner / truth / projection
- stop-line
- fallout scan
- verification bundle

这些机制已经能保护底层系统边界，但也带来了新的问题：

- 文档多，AI 容易一次性读取过量。
- 执行 AI 容易把读文档当作推进。
- 架构 AI 容易输出过长阅读清单。
- 规则分散在多个文档里，触发条件不够产品化。

参考 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) 后，本项目后续可以把治理能力提炼成 skill。

但 skill 的目标不是复制所有文档，而是把流程变成可触发动作。

## 1. Skill 化原则

### 1.1 Skill 是流程，不是知识库

skill 只应包含：

- 何时触发。
- 必须读哪些最小入口。
- 要按什么步骤行动。
- 什么时候暂停。
- 什么时候进入实现。
- 完成前怎么验证。

skill 不应复制完整治理文档、历史计划文档或参考仓库内容。

### 1.2 项目文档仍是真相源

未来 skill 只能引用项目文档。

真相源是：

- [GUI_TASK_TRACKER.md](/Users/jiangxuanyang/Desktop/cangjie/GUI_TASK_TRACKER.md)
- [GUI_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/GUI_GOVERNANCE.md)
- [AI_CODE_QUALITY_GOVERNANCE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_CODE_QUALITY_GOVERNANCE.md)
- [AI_EXECUTION_CARD_TEMPLATE.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/AI_EXECUTION_CARD_TEMPLATE.md)
- [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md)

skill 不得覆盖这些文档。

### 1.3 先少量 skill，后续再拆

不一次性做大型 skill pack。

先做一个最小 `cjgui-governance` skill，验证有效后再拆成多个小 skill。

## 2. 推荐 skill 拆分

### 2.1 第一阶段：一个总 skill

名称：

- `cjgui-governance`

触发场景：

- 用户要求继续推进 CJGUI。
- AI 准备改 CJGUI 代码。
- AI 准备创建 preflight / execution card / closure review。
- AI 不确定当前 next opening。
- AI 被要求 review CJGUI 改动。

职责：

- 先读取最小入口。
- 找到当前 active / next opening。
- 检查是否需要 execution card。
- 如果边界清楚，提醒进入 bounded implementation。
- 执行后要求 verification bundle 和 closure。
- 避免读取过量上下文。

### 2.2 第二阶段：拆成小 skill

如果总 skill 变重，再拆成：

- `cjgui-orient`：定位当前阶段、next opening、stop-line。
- `cjgui-bounded-implementation`：进入代码切片，检查 write set、truth、verification、Docs Exit Rule。
- `cjgui-closure-review`：封账实现结果，更新 tracker。
- `cjgui-cangjie-toolchain-check`：处理仓颉语法、`cjpm`、`cjc`、FFI、SDK workaround。

## 3. 最小 skill 草案结构

未来可以放在：

```text
.agents/skills/cjgui-governance/SKILL.md
```

建议结构：

```text
---
name: cjgui-governance
description: Use when working on the CJGUI Cangjie GUI runtime project. Helps load minimal context, identify current opening, enforce bounded implementation, verification, and closure.
---

# CJGUI Governance

## When to Use

- Any CJGUI code implementation.
- Any CJGUI preflight / execution card / closure review.
- Any CJGUI review or handoff.

## Minimal Context

Read:

- README.md
- GUI_TASK_TRACKER.md current active / next opening
- docs/ai/AI_DEVELOPMENT_CONSTITUTION.md
- current execution card if present

Read only when triggered:

- docs/core/GUI_GOVERNANCE.md
- docs/ai/AI_CODE_QUALITY_GOVERNANCE.md
- docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md
- docs/setup/BUILD_FROM_ZERO.md
- docs/setup/CANGJIE_ISSUE_LEDGER.md

## Workflow

1. Identify current opening.
2. Identify authority / write set / stop-line.
3. If boundary is clear, enter bounded implementation.
4. Do not create more docs-only work unless a pause condition is triggered.
5. Verify with build / smoke / relevant check.
6. Summarize fallout scan and closure needs.

## Red Flags

- Reading all plans by default.
- Treating comment-only as implementation.
- Creating a new preflight after boundary is already clear.
- Touching files outside write set.
- Opening public API / C ABI / platform bridge without approval.
```

## 4. 暂不立刻创建真实 skill 的原因

当前先不急着创建 `.agents/skills/cjgui-governance/SKILL.md`。

原因：

- 需要先让 [CJGUI_CONTEXT_LOADING_POLICY.md](/Users/jiangxuanyang/Desktop/cangjie/docs/ai/CJGUI_CONTEXT_LOADING_POLICY.md) 稳定一两轮。
- 需要观察架构 AI 是否能遵守 `Loaded Context Budget`。
- 需要确认 skill 触发不会让 AI 每轮反而多读一层。
- 当前项目仍以项目文档和 tracker 为真相源。

推荐下一步：

1. 先用文档规则跑 2 到 3 个 code-bearing bounded slice。
2. 如果阅读清单明显变短，再创建 `cjgui-governance` skill。
3. 如果总 skill 变重，再拆成 4 个小 skill。

## 5. 不做什么

- 不把所有历史 plans 打包进 skill。
- 不把参考仓库源码打包进 skill。
- 不把 skill 变成第二个 tracker。
- 不让 skill 覆盖当前 execution card。
- 不让 skill 绕过 Docs Exit Rule。

## 6. 一句话目标

> 把 CJGUI 治理从“很多文档”提炼成“少量触发式工作流”，让 AI 更快进入正确的小切片实现。
