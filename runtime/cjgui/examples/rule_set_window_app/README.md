# CJGUI 规则集编辑器

这是可用预览的正常 macOS 应用：左侧分页显示任意数量的规则，右侧编辑当前规则的草稿。新增、删除、撤销、重做、保存和应用草稿都经由同一份 `CjguiRuleSetEditingDomain`；窗口行号只是视口位置，不是记录 ID。它使用框架拥有的 [macOS 应用宿主](../../MACOS_APPLICATION_HOST.md)，不再编译 sample launcher 或声明 finish FFI。

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/rule_set_window_app
zsh run.sh --save-as /tmp/rules.cjgui-rules
```

用 `--open PATH` 重新打开已有文件。启动时会打印一次私有 descriptor 路径；获授权的外部客户端必须先发现 descriptor，再读上下文、读取变化或调用声明的动作。桌面锁屏时不把脚本写文件当成 GUI 验收。

仅验证普通 bundle 构建与签名而不启动窗口：`zsh run.sh --build-only`。保存写入已应用的规则集；草稿要先“应用草稿”，或使用“取消并重载”明确放弃。关闭未保存窗口会丢弃内存内容，启动参数不会覆盖已经存在的另存为目标。重启后的重复请求保证不延续，调用方应通过 `GET_CONTEXT`/`GET_CHANGES` 读回确认结果。

该正常应用的 descriptor 明确授予 `GET_WINDOW_PROGRESS` 与
`GET_WINDOW_INTERACTION` 两个不同动作，均为 `ALL` scope。前者仅含会话、场景、
提交和帧进度，适用于 `wait-window`；后者才含焦点、可选 UTF-16 选区和顶层 layer。
先通过 `python3 ../../shared_operation_core/client.py "$DESCRIPTOR" get` 动态读取
`ACTION`/`AUTH_SCOPE`，再按需运行 `window-interaction`；不要把旧的进度读取授权当作
交互信息授权。规则集快照同时携带由同一 owner 读取边界产生的 `STREAM_ID`，可作为
`observe` 的初始 cursor 身份。
