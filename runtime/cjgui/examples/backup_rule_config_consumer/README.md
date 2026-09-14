# 备份规则无窗口消费者

这个普通可执行包复用 `../backup_rule_application/` 中的同一份应用领域；它不链接
renderer、AppKit、Metal 或任何 FFI。该领域明确分开已应用配置、原始草稿、草稿所基
于的已应用版本、草稿/字段版本、焦点和校验错误。窗口样例也直接消费这份领域，因而
没有第二套 `BackupRuleDomain` 或 native 草稿真相。

外部从 descriptor 动态发现以下通用表单动作：`EDIT_DRAFT_TEXT`、
`EDIT_DRAFT_BOOLEAN`、`APPLY_DRAFT`、`CANCEL_DRAFT`。编辑动作只可写显式授权的字段
资源；`--grant-apply` 才把应用/取消及遗留兼容动作授予调用者。有效草稿一次原子应用；
空值、越界或旧字段版本保留原始草稿并如实拒绝。`--human-label` 仍通过同一个领域分派
器更新已应用标签，供无窗口启动场景使用。

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/backup_rule_config_consumer
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
zsh build.sh
zsh test.sh
```

测试启动两个真实独立进程，仅经各自 `0600` descriptor 和公开通用客户端操作。它验
证字段级读写、字段旧版本拒绝、显式授权应用与未获授权应用、应用读回、实例隔离及正
常清理。它不是实际备份、数据库或跨机器身份系统。
