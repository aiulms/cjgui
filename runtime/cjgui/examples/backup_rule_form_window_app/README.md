# 共同编辑备份规则表单

这是正常的 macOS `CJGUIBackupRuleForm.app` 消费者。它使用框架的
`CjguiSharedEditingFormWindow`，并直接消费 `backup_rule_application` 的同一份领域状态；
原生 `NSTextField` / checkbox 只报告输入 intent，已应用值、草稿、选区、校验和版本均由
仓颉领域投影回窗口。

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/backup_rule_form_window_app
zsh run.sh
```

启动后只输出一次私有 descriptor 路径。公开客户端先 `describe`/`get`，再按实际发现的
field resource、`draftFieldVersion`、`draftVersion` 和 `baseAppliedConfigVersion` 调用编辑或
应用动作；不要猜 socket 路径或把 UI 文本当作真相。关闭窗口会释放 renderer session，并
关闭该实例 descriptor/socket。

此样例只更新运行中的备份规则配置，不保存备份文件或数据库，也不宣称完整 IME/富文本
编辑器支持。
