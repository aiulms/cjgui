# CJGUI 共享文档窗口

这是正常 macOS 文档窗口：文档内容、版本、选区与撤销仍由
`CjguiTextDocumentWorkspace` 持有；窗口和外部连接只是同一 owner 的投影与入口。
它使用框架拥有的 [macOS 应用宿主](../../MACOS_APPLICATION_HOST.md)，不再依赖其他 example 的 launcher，也不声明 native finish FFI。
启动带连接的短时实际窗口：

```zsh
cd /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/examples/shared_document_window_app
zsh run.sh --with-connection --measurement-warmup-ms 0 --measurement-duration-ms 5000
```

同一进程多窗口入口保留旧单窗口兼容：`--multi-window` 会打开两个绑定同一说明文档、但拥有各自焦点/选区/滚动上下文的视图，以及一个独立笔记视图。连接由 `CjguiMacosApplication` 持有；关闭一个窗口不会关闭其余窗口或 descriptor。每个窗口 target 都绑定其 application owner 与单调 generation，因此跨应用、旧 generation 和已关闭 target 都不能命中后来存活的窗口。

```zsh
zsh run.sh --multi-window --with-connection --measurement-warmup-ms 0 --measurement-duration-ms 5000
```

短时运行结束会输出文档 owner 的版本和每个窗口的 build/submit 标量。说明文档发生外部 CAS 时，两个说明视图应从 `BUILD 1 SUBMIT 1` 变为 `BUILD 2 SUBMIT 2`；独立笔记窗口保持 `BUILD 1 SUBMIT 1`。这证明相关投影更新而非全局强制重建，仍不把一次提交表述为人眼已看到像素。

应用打印的私有 descriptor 才是外部调用入口。单窗口 consumer 可以按需读取它的
进度或交互投影；多窗口 consumer 则必须先枚举，再精确读取一个 live target，绝不
默认选择“第一个窗口”：

```zsh
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" get --target 7101
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" observe --target 7101 --turns 2
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" window-targets
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" window-context "$WINDOW_TARGET"
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" window-progress "$WINDOW_TARGET"
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" window-interaction "$WINDOW_TARGET"
```

`GET_WINDOW_PROGRESS` 和 `GET_WINDOW_INTERACTION` 是同一观察权限下的两种定向读取。
进度读取只包含 session/scene/frame 标量，可用于 `wait-window --target`；交互读取才含
focus、可选 UTF-16 selection 和 active layer。多窗口调用必须带上从 `window-targets`
取得的 target，响应也回显 `WINDOW_TARGET`；关闭 A 后，A 的三种定向读取都会返回
`unknown_window_target`，而 `GET_WINDOW_CONTEXT B` 仍读取 B。带 `IDS` 的窄交互授权
不会输出这些全局窗口标识，而会得到 `unauthorized_resource`；不要把“没有正文”当作
可以泄露焦点或选区身份的理由。

`--close-first-window-after-ms 1..60000` 是多窗口 acceptance 的受控运行参数：它只在
应用内部走既有 controller close 决策，用来让另一个公开 client 验证旧 target 拒绝与
同胞 target 存活；它不为外部连接增加关闭或其他 mutation 动作。

文档快照的 `VERSION`、资源内容与可选 `STREAM_ID` 在 workspace 的同一 owner 读取
边界产生。`observe` 的 initial/resync 结果若有 `STREAM_ID` 可安全继续增量 cursor；
旧 provider 没有该字段时，公开 client 会报告 `snapshot_identity_unavailable` 并退化为
每轮完整 resync，而不把旧缓存标成 `no_change`。
