# CJGUI 共享文档窗口

这是正常 macOS 文档窗口：文档内容、版本、选区与撤销仍由
`CjguiTextDocumentWorkspace` 持有；窗口和外部连接只是同一 owner 的投影与入口。
它使用框架拥有的 [macOS 应用宿主](../../MACOS_APPLICATION_HOST.md)，不再依赖其他 example 的 launcher，也不声明 native finish FFI。

## 普通文件编辑

在完整源码仓中，以已有 UTF-8 文件启动正常窗口；`CJGUI_ROOT` 指向 `runtime/cjgui`。
此入口持续运行，使用窗口“保存”和“关闭”；只有需要外部协作时才传 `--with-connection`。

```zsh
zsh "$CJGUI_ROOT/examples/shared_document_window_app/run.sh" \
  --file "/absolute/path/to/document.txt" --with-connection
```

聚焦正文后，⌘A、键盘扩选和 ⌘C／⌘X／⌘V 使用系统选区与剪贴板。
⌘Z／⇧⌘Z、工具栏及菜单中的撤销／重做都进入现有 workspace 历史；保存写入同一正文，
关闭沿应用的正常决策。窗口、外部操作与保存不各自维护第二份正文或 Undo 栈。
单行 `cjguiComposableTextInput` 的 Return 由输入代理消费，不写入换行；本文档的多行编辑器
仍由 TextKit 按 Return 插入换行。系统组字进行中的 Enter/Esc 归文本服务。
短文档的 Unicode、换行、剪切粘贴、声明 Undo／Redo、外改后直接续写和精确保存已完成
macOS 正常消费验证；这不扩展为大文件性能、完整输入法或其他平台的验收。

### 退出前处理未保存内容

`--file` 只绑定说明文档。退出和本窗口关闭使用同一应用策略：说明文档按真实
`CjguiTextDocumentFileBinding.persistedState(snapshot, path)` 判断。已保存内容可直接关闭；
脏内容可保存到原绑定路径、明确放弃或取消。没有文件路径时只能明确放弃或取消；未绑定的新路径
只允许创建不存在的文件，已有目标仍由文件绑定的冲突保护拒绝。绑定到另一文档或路径时不显示可用保存，
也不会把当前正文写到该文件。

内置笔记文档 v0 是未修改模板。笔记有编辑版本时没有独立文件保存入口，只能取消关闭或明确放弃，
不会借说明文档路径保存。取消会保留 workspace 正文和版本，让原窗口继续编辑；保存失败保留当前窗口。
这些决定都读取现有 workspace 快照和文件绑定状态，不额外缓存第二份正文或撤销历史。

外部先发现目标并读取实际正文的 `documentVersion` 与 `byteLength`。
READ_RANGE 的 UTF-8 字节范围和 REPLACE_RANGE 的 CAS 都使用该正文版本。
例如只改变选区时，GET_CONTEXT 的聚合 VERSION 可能从 0 变为 2，正文仍为 v0；
不能用聚合 2 读取或替换 v0 正文。窗口交互投影里的选区为 UTF-16，不能直接充当 UTF-8
范围。外改成功后继续在原焦点输入，应以接受后的正文与选区为基线；冲突不得靠重放编辑救回。
连接只授予应用声明的资源／动作，不提供默认远程系统剪贴板权限。

## 运行时打开、关闭与重开

窗口底部“打开/关闭文档”行使用同一个 `CjguiTextDocumentWorkspace` 生命周期入口，不重启窗口、
不替换 endpoint。`--open-extra PATH` 可重复，把应用已授权的路径排入队列；每次“打开”在运行时
读取/创建该路径并分配新的业务 resourceId。队列为空时，“打开”重开最近关闭的文件；没有最近文件
时创建新的内存文档。关闭当前文档前按该文档自己的文件绑定判断未保存状态：保存、明确放弃或取消；
取消保留正文、版本和继续编辑入口。

同一路径关闭后再次打开是**新的实例**，即使正文版本再次为 0。旧 resourceId 在本 endpoint
生存期内退休，不再登记或复用；旧目标写入返回 `document_closed`，不会命中新文档。关闭 A 不改变
B 的正文、版本或保留目标；最后一份文档关闭后是合法空状态，仍可再次打开。每份文档的文件绑定只
跟随该文档，切换/打开另一文件不会改写其他文档的保存目标。

公开客户端从 `GET_CHANGES` 的 `document_opened`（或新的 `GET_CONTEXT`）取得准确新 ID，
不按标题、路径或列表位置猜测。应用只为实际打开的新文档向现有连接授予既有读写动作；Undo/Redo
等历史动作仍不对外声明。详细边界见 [typed document client](../../shared_operation_core/DOCUMENT_CLIENT.md)。

公开生命周期动作为 experimental：`OPEN_DOCUMENT` 无参数、无目标，只消费应用已排队的路径，
不接收调用方任意文件路径；成功后的准确新 ID 从 `document_opened` 变更取得。`CLOSE_DOCUMENT`
必须带一个显式目标与相应文档版本，可选 `decision`：干净文档可直接关闭；脏文档缺少决定时返回
`unsaved_decision_required` 并保留文档，`save` 经该文档自己的绑定保存成功后才关闭，`discard`
才明确放弃，`cancel` 无副作用。未知、已退休或未授权目标按名拒绝，绝不改关当前选择。退休文档的
动态授权随正文/历史/文件关联一起移除，B 和静态授权策略保持不变。

一份活文档只拥有一份 `CjguiTextDocumentFileBinding`：工作区在读取文件或挂接前先 claim，第二次
活借用返回 `binding_in_use`；退休时释放并清除该绑定的可信基线，磁盘文件不动，之后复用从新目标
文件开始。

2026-11-02 正常窗口验收：初始 A/B，运行中打开 C（新的 7200）；A 真实键入、取消一次关闭后继续、
保存并关闭；B 正文/版本不变；重开 A 得 7201，外部写入成功后继续真实键入；再关闭/重开得 7202，
旧 7201 写入返回 `document_closed`，新 7202 外部写入与真实键入均成功；关闭全部文档后从空状态重开
C 得 7203 并继续编辑；正常关窗 exit 0、descriptor 清理。原始记录见
`work/macos-dynamic-documents-20261102/`。

## Typed document client

外部短文档 consumer 可用随 SDK 导出的 [typed document client说明](../../shared_operation_core/DOCUMENT_CLIENT.md)
和本目录的 `client.py`。从当前应用上下文选择真实 `text_document` 资源 ID，再为每个文档分别
取得目标快照；不要猜资源 ID，也不要把 `GET_CONTEXT` 聚合版本当作文档版本。

SDK 可放在仓库外、路径含空格的目录中。下面的命令从包内consumer调用公开样例；在SDK外运行自己的
caller时也可直接传同一个 `--sdk-root`，不需要 `PYTHONPATH` 或仓库源码路径：

```zsh
SDK_ROOT="/path/with spaces/Public Document SDK"
python3 "$SDK_ROOT/consumers/shared_document_window_app/client.py" \
  --sdk-root "$SDK_ROOT" --descriptor "$DESCRIPTOR" --resource-id "$RESOURCE_ID"
```

样例用同一个显式目标版本做一次有界读取，可选以该目标提交一次 `--start`／`--end`／`--text` 修改，
范围单位为 UTF-8 字节。它输出结构化结果，不自动刷新目标或重发；若要观察后续状态，由调用者明确
开始一次新操作。Undo／Redo、文件保存和关闭仍由普通应用窗口执行。

macOS 的公共预览滑块通过 AX 发布“预览字节上限”、整数当前值及 128..512 范围。AX 增减和键盘箭头都进入既有 NAVIGATE，使用同一 owner 和 32 步长；边界不产生额外业务版本。native 只读取接受后的声明，不另存业务值。可见预览说明随同一值更新。首帧可能为 Preparing，本消费者沿正常宿主泵送有界推进到实际首帧，再报告 WINDOW_READY。

本簇实际验证 AX 增减、owner 精确读回、可见反馈、键盘续接和正常关闭。真实 VoiceOver 未由人工验证，不能将 AX 查询或动作当作旁白通过；其他平台未验。构建来源和原始证据见 [E 当前结果](../../../../artifacts/e-astra-mechanisms-20261005/caret-regression/searchable-panel-current/RESULT.md)。

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
SDK_ROOT="/path/with spaces/Public Document SDK"
CLIENT="$SDK_ROOT/framework/cjgui/shared_operation_core/client.py"
python3 "$CLIENT" "$DESCRIPTOR" get
# Choose RESOURCE_ID from the current GET_CONTEXT output; do not reuse an old id.
python3 "$CLIENT" "$DESCRIPTOR" get --target "$RESOURCE_ID"
python3 "$CLIENT" "$DESCRIPTOR" observe --target "$RESOURCE_ID" --turns 2
python3 "$CLIENT" "$DESCRIPTOR" window-targets
python3 "$CLIENT" "$DESCRIPTOR" window-context "$WINDOW_TARGET"
python3 "$CLIENT" "$DESCRIPTOR" window-progress "$WINDOW_TARGET"
python3 "$CLIENT" "$DESCRIPTOR" window-interaction "$WINDOW_TARGET"
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
