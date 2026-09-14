# 纯 core 列表消费者

这是迁移后 101 条窗口列表的第二个普通消费者。它只依赖
`cjgui_shared_operation_core`：`cjpm.toml` 没有 renderer、AppKit、Metal 或 FFI
链接项。它持有自己的四条列表数据和授权范围，但由同一个
`CjguiSharedOperationList` 领域实现、通用 descriptor 与 v2 socket transport
处理。

外部调用方可读所有记录（`GET_CONTEXT`），但只有 `SET_MARKED` 对稳定 ID
`7127` 有写权限。`7199` 的标题和 `7127` 相同，却不在写 scope 中；显示文本
不是授权身份。

## 构建和验收

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/shared_operation_second_consumer
source /Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh
zsh build.sh
zsh test.sh
```

验收会启动两个实际独立的无窗口进程，经其各自 `0600` descriptor 调用同一个
公开通用客户端 `../../shared_operation_core/client.py`。它验证动态发现、分片
frame、写后读回、越权目标、错误 capability、旧版本冲突和正常关闭清理。

描述符每次启动都位于独有 `0700` 目录。不要猜测 socket 路径或将 capability
另行记录到日志；已获授权调用方只应接收 descriptor。
