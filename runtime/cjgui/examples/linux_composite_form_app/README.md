# Linux 普通应用组合消费者

这是一个可复用的 Linux 普通应用示例：同一份仓颉 UI 代码包含圆角/渐变外观、
可滚动图文表单、两张本地图片、字段编辑，以及一个由人和独立客户端共同读写的
共享 owner。默认离线运行；只有程序自己启动的私有 Unix socket 可被外部调用。

## 构建与运行

要求仓库已构建 Linux native sidecar，且 `CJGUI_CANGJIE_TOOLCHAIN` 指向仓颉
`envsetup.sh` 或工具链目录：

```sh
export CJGUI_CANGJIE_TOOLCHAIN=/path/to/cangjie/envsetup.sh
cd runtime/cjgui/examples/linux_composite_form_app
./run.sh build
./run.sh run
./run.sh clean
```

`run.sh` 复用框架的 `platforms/linux/scripts/run_linux_application.sh`，不维护
第二套构建、源闭包或清理逻辑。输出在 `.cjgui/linux`；启动后 stdout 会打印：

- `CJGUI_COMPOSITE_READY`
- `CJGUI_COMPOSITE_DESCRIPTOR <私有 descriptor 路径>`
- `CJGUI_COMPOSITE_PROTOCOL CJGUI_SHARED_OPERATION/2`

## 外部客户端

使用同一个 descriptor 和公共 `client.py`，不需要业务专用协议：

```sh
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" --json get
python3 ../../shared_operation_core/client.py "$DESCRIPTOR" --json \
  invoke 0 SET_NOTES --target 1000 --arg notes=STRING:外部写入
```

授权只覆盖验收所需的 `GET_CONTEXT`、`SET_NOTES`、`SET_MARKED` 与 `SELECT`；
外部修改进入与手写窗口相同的 `CjguiSharedOperationList`，下一帧投影会刷新，
stdout 会打印 `CJGUI_COMPOSITE_EXTERNAL ...` 回执。

## 覆盖的框架能力

- `CjguiComposableUiLinearGradient` 2–4 个色标（本示例使用 3 个）由 Linux
  自绘后端按顶点色精确绘制；
- `cornerRadius` / `cornerRadii` 的圆角填充与描边；
- `clipsContent` 的圆角子树裁剪同时作用于图片、文字与背景；
- 公共 `cjguiComposableScrollArea` + `CjguiComposableUiScrollViewport` 的滚轮、
  窄窗布局与滚动后点击；
- 公共文本输入、按钮和共享操作 owner。

本示例只消费 Linux 已有的 X11/Vulkan 自绘实现，不引入外部 GUI 依赖，也不
替代 `ui-only` 轻量模板。
