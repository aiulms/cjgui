# AI Action Protocol Experiment

最后更新：2026-04-26

性质：long-term architecture note / protocol experiment archive / no implementation

状态：生效中；不批准当前实现

## 1. 文档定位

本文件记录一次 AI Action Router 指令格式选型实验的结论。

它服务于长期方向：

- UI 框架未来可能提供 semantic provider。
- AI / Agent 未来可能通过 Action Router 请求操作 UI。
- Action Router 必须是 zero-trust gateway，不能成为 AI 绕过应用 owner 的后门。

本文件只记录协议方向和风险判断，不批准：

- 当前实现 semantic tree。
- 当前实现 Action Router。
- 当前实现 AI runtime。
- 当前设计 IPC server。
- 当前修改 P1 runtime lifecycle 主线。

## 2. 背景

未来 AI 操作 UI 时，不能只靠屏幕坐标或截图猜测。

更合理的长期模型是：

```text
Semantic Snapshot / Delta
-> AI reads current UI semantics
-> AI emits Action Command
-> parser builds typed ActionRequest
-> Action Gateway validates
-> application owner decides
```

这里的关键问题是：AI 应该用什么格式表达 Action Command。

候选格式至少包括：

- RPN / reverse polish notation。
- JSON。
- Lisp-style S-expression。

## 3. 实验设计概要

实验使用同一道复杂 UI 操作题，让三个 AI 模型分别用三种格式输出指令流：

- 千问 3.5。
- DeepSeek-v4 轻量版。
- Gemini 3.1。

候选格式：

1. RPN：基于隐式栈的后缀表达式。
2. JSON：主流数据序列化格式。
3. Lisp-style S-expression：显式括号树结构。

实验关注：

- AI 是否能稳定表达作用域。
- 是否容易遗漏上下文。
- token 成本是否可接受。
- 指令是否容易被 parser / gateway 拦截。
- 是否容易产生危险的全局寻址或误操作。

说明：本实验是架构探索性实验，不是正式 benchmark。它足以登记方向和风险，不足以直接冻结完整 Action Router 公共协议。

## 4. 实验观察

### 4.1 RPN

观察结果：

- 多个模型在隐式栈操作中出现顺序错误。
- `DUP` / `SWAP` / parent context 之类操作容易让上下文错位。
- 模型在复杂嵌套任务中倾向于放弃 RPN 规则，退回前缀调用或全局寻址。

结论：

> RPN 不适合作为 AI-authored UI action command 格式。

原因：

- 隐式栈对 AI 生成不友好。
- 审计成本高。
- 错误位置不直观。
- 作用域无法被语法结构自然保护。

### 4.2 JSON

观察结果：

- JSON 对普通结构化数据友好。
- 但在复杂嵌套 UI 操作中，模型容易遗漏 `target_context`、scope、generation、parent constraint 等字段。
- JSON 的作用域往往依赖字段约定，而不是语法形状本身。
- 字段可选性越多，AI 越容易偷懒或退化到全局寻址。

结论：

> JSON 不应作为复杂 AI-authored UI action DSL 的默认首选。

但这不是全局否决 JSON。

JSON 未来仍可能适合：

- debug dump。
- semantic snapshot export。
- IPC envelope。
- log / audit record。
- 普通配置或工具数据。

当前不应写成“禁止 JSON”。更准确的规则是：不要把 JSON 当作复杂 AI-authored action command 的默认 DSL。

### 4.3 Lisp-style S-expression

观察结果：

- 括号结构天然表达嵌套作用域。
- 父子关系、局部 scope、动作参数更容易被一起包住。
- AI 输出更短，token 成本更低。
- parser 可以在语法层先失败关闭。
- 作用域结构更利于审计和人工阅读。

示意：

```lisp
(with-scope (panel mission-detail)
  (invoke (button mission.release)
    :expected-generation 42
    :confirm true))
```

结论：

> Lisp-style S-expression 是未来 AI-authored Action Command 的 preferred north-star candidate。

## 5. 当前协议口径

本项目当前采用以下口径：

- RPN rejected。
- JSON not preferred for complex AI-authored action DSL。
- S-expression is the preferred north-star candidate for future AI-authored Action Commands。

但这不是完整协议冻结。

未来正式 Action Router protocol preflight 仍必须回答：

- grammar 是什么。
- symbol allowlist 是什么。
- action id 如何绑定 semantic node。
- scope / generation / visibility / stability 如何表达。
- 参数类型如何校验。
- action result 如何返回。
- snapshot / delta / action / audit record 是否使用同一格式。
- IPC envelope 是否与 action command 语法分离。

## 6. 分层边界

必须区分四层：

```text
AI-authored surface syntax
-> parsed AST
-> typed ActionRequest
-> owner-controlled event / action gateway
```

S-expression 只适合作为 AI-friendly authoring syntax。

它不应直接成为 runtime 内部状态，也不应绕过 typed AST / ActionRequest。

正确路径：

1. AI 输出 S-expression action command。
2. parser 检查语法。
3. parser 生成受限 AST。
4. validator 检查 allowlist、scope、node id、generation、visibility、stability、参数类型。
5. Action Gateway 将请求交给应用 owner。
6. 应用 owner 决定 accept / reject / defer / needs confirmation。

## 7. 安全铁律

S-expression 在本项目中必须是 data grammar，不是 executable Lisp。

禁止：

- `eval`。
- macro。
- user-defined function。
- arbitrary symbol execution。
- runtime reflection execution。
- 通过 symbol 拼接调用内部函数。
- AI action 绕过 app owner 直接改状态。
- AI action 直接改 renderer / scene cache / semantic tree。

允许：

- 解析成受限 AST。
- 使用固定 allowlist。
- 进行结构化 validation。
- 失败时 fail closed。
- 返回可审计 ActionResult。

## 8. 与现有 AI-native UI 方向的关系

本文件补充 [AI_NATIVE_UI_SEMANTICS.md](/Users/jiangxuanyang/Desktop/cangjie/docs/core/AI_NATIVE_UI_SEMANTICS.md)。

现有原则不变：

- semantic tree 不能成为第二真相源。
- Action Router 不能只是回调转发器。
- AI action 必须经过 owner / gateway。
- AI action 和 mouse / keyboard event 未来应进入同一 owner-controlled queue，而不是开后门。
- 默认轻量路径不启动 AI server。

本文件只新增一个长期候选：

> 当未来需要 AI-authored action command surface syntax 时，优先从 Lisp-style S-expression 开始 preflight。

## 9. 与当前 P1 Runtime 的关系

当前 P1 runtime 线不受本实验影响。

继续保持：

- 不实现 semantic tree。
- 不实现 Action Router。
- 不实现 AI runtime。
- 不设计 IPC server。
- 不进入 public runtime API。
- 不改变 window / app lifecycle 当前 next opening。

本实验只登记为 future semantic / action-router preflight 输入。

## 10. Future Opening

未来可登记：

> `P1 AI action protocol S-expression preflight`

该 preflight 应在满足以下条件后再打开：

- 已经有 Element / Scene / event owner 的基本边界。
- 已经有 semantic projection 的最小设计。
- 已经明确 Action Router 不绕过应用 owner。
- 已经需要 AI-authored action command，而不是只做语义读取。

本 future opening 不自动开启。
