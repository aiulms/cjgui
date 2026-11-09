# 能力定位与检索

从当前应用依赖查询；未建项时使用用户明确选定的框架包。
脚本直接读该版本文件，不联网、不使用另一份固定 API 数据库，也不修改 SDK。

```sh
python3 "$SKILL/scripts/lookup.py" --app "$APP" --query "工作会话保存" --query "文本输入事件"
python3 "$SKILL/scripts/lookup.py" --framework "$FRAMEWORK" --query "CjguiComposableUiController" --max-results 2
```

每个独立意图/符号使用一个 `--query`；默认每项 3 个结果。中文使用原短语和双字片段召回，
同一短语按覆盖的字符位置计分，重叠片段不重复加分；精确符号和相关公开声明仍优先定位。
路由只帮助定位文件，不让总标题压过具体命中段落；同一文档可返回多个相关段落。
结果有实际路径、行号、文件 SHA 和短片段。`snippet_scope` 标明声明头或段落，
`snippet_truncated` 仅表示这段内容被 12 行/1600 字符上限截断；文件前后还有上下文另用 has_more_context_before/after 表示。
这是文本定位，非仓颉语义解析或“可直接调用”的保证；阅读对应类/函数的完整签名与同版契约后使用。
结果没有当前运行或编译验证；文件更新后下一次查询即读取新内容，不按日期沿用旧答案。
多条 CJGUI 依赖时脚本拒绝任选一个；按 identify 的来源报告和实际构建选择包。
`coverage` 报告实际搜索到的文档/源码数量及 templates 是否存在；根指南或模板缺失会主动提示，
不依赖查询是否触发主题路由。每项 `routes_not_present` 另列缺少的相关路由文档。
`found` 仅表示找到了声明或文档文本，即使同时缺指南/模板也会返回；不表示包的开发资料完整。
只有 src 的 captured 包仍可查询声明，但缺少契约/示例会明确提示；不能静默拿另一版文档补成当前包已交付。

| 任务 | 同版公开入口/查询词 |
| --- | --- |
| 新建简单本地工具 | `templates/macos_application/ui_only`；创建器 `ui-only` |
| 字段、事件、controller | `FIELD_CONTROLS.md`；查询具体字段构造器、`CjguiComposableUiController`、`TEXT_CHANGED`、`INTEGER_CHANGED` |
| 布局、窄窗、滚动 | `LAYOUT_PRIMITIVES.md`；`contentBounds`、`growY`、`CjguiComposableUiScrollViewport` |
| 主题、角色和交互态 | `STYLE_ROLES.md`；`CjguiComposableUiTheme`、`boundStyle` |
| 本地工作会话保存 | `templates/macos_application/ui_only/WORK_SESSION.md`；`CjguiComposableUiWorkSession` |
| 同 owner 的手写/生成投影 | `templates/macos_application/mixed_form/README.md`；`shared_operation_core/GENERATED_EDITING.md` |
| 窗口/打包配置 | `MACOS_APPLICATION_HOST.md`；`CjguiMacosApplicationWindowConfiguration`，生成应用根的 `cjgui_macos_app.sh` |
| 观察布局与状态 | `LAYOUT_PRIMITIVES.md`；`diagnosticSnapshot`；按同版 command-surface/mixed-form 示例接 Inspector |

路径相对实际 `FRAMEWORK`，旧包可能缺少入口；查询未命中时先缩短关键词或用精确符号，
再读相关同版文档/模板。当前搜索只覆盖根公开 Markdown、templates、shared_operation_core 文档及 `src` 声明文本，
不遍历 native、测试、历史或平台副本；因此未命中不证明框架不支持。
没有脚本执行能力时按此表直接查对应文件。缺少可用声明/契约才做有界验证并保留查询缺口，避免反复猜测。
