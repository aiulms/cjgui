# 共同操作窗口样例

这是 macOS `CJGUISharedOperation.app` 的实验性窗口样例。它仍以八行视口投影
101 条稳定 ID 记录；窗口输入和已授权外部调用都落到 core 内同一个
`CjguiSharedOperationList.execute...` 领域处理器。窗口包链接 renderer，但共享
契约与 socket transport 不链接 AppKit、Metal 或 renderer。

启动后输出一次 descriptor 路径。不要猜测 socket 路径，也不要复用已关闭实例的
descriptor。用公开的、无业务分支的 v2 客户端发现及调用动作：

```zsh
python3 ../../shared_operation_core/client.py /private/.../connection.cjgui describe
python3 ../../shared_operation_core/client.py /private/.../connection.cjgui --fragment-bytes 7 get
python3 ../../shared_operation_core/client.py /private/.../connection.cjgui \
  invoke 0 SET_MARKED --target 1077 --target 1088 --arg isMarked=BOOLEAN:true
```

此应用仅授权 `GET_CONTEXT` 读取 101 条记录，及 `SET_MARKED` 原子写入 `1077`、
`1088`；同样带“远程验收候选”文字的 `1094` 没有写权限。`SELECT`、`TOGGLE`
仅由窗口内的受信任人类入口使用。所有外部写入携带刚读到的版本，旧版本返回
`CONFLICT true` 而不覆盖较新的窗口输入。

本阶段已在重新构建的 bundle 上实机复核：人类勾选得到 v1，外部把屏外 1077 写为
v2，滚动到该行观察到 checkbox on；人类再改回 off 得 v3，旧 v1 写返回冲突且读回
仍为 off。关闭窗口后该实例的 descriptor/socket 与进程均不存在。此证据不等同于
发布或第三方模型提供方接入。
