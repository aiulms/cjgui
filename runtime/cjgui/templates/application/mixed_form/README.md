# mixed-form starter（Linux 建项入口）

Linux 普通开发者起始应用：手写区域与运行时生成区域共用既有通知领域中一个
`CjguiSharedEditableFormDomain` owner、一份字段声明和一组动作。生成区域不是生成代码
后重新编译，而是由独立客户端按公开 catalog 提交结构，窗口下一帧消费。

## 建项

```bash
runtime/cjgui/platforms/linux/scripts/create_linux_application.sh mixed-form \
  /abs/path/to/new-application --framework /abs/path/to/runtime/cjgui
```

`ui-only` 仍是默认的轻量入口；`mixed-form` 是显式 opt-in。建项只复制 `src/`、
`client.py`、Linux 清单和 `run.sh`，不带 target、`.cjgui`、旧交付或本机路径。

## 构建与启动

```bash
cd /abs/path/to/new-application
export CJGUI_CANGJIE_TOOLCHAIN=/abs/path/to/cangjie/envsetup.sh
./run.sh              # build + run
./run.sh build        # build only
./run.sh run          # reuse the existing receipt
./run.sh package DEST # write a self-contained preview .tar.gz
./run.sh clean        # retire this application's private target
```

`run.sh` 复用框架的 `platforms/linux/scripts/run_linux_application.sh`，通过
`platforms/linux/framework-sources.txt` 构建；输出在 `.cjgui/linux`，可用
`CJGUI_LINUX_OUTPUT` 指定。GUI 需要可用的 `DISPLAY`。启动后 stdout 打印
`CJGUI_MIXED_READY`、`CJGUI_MIXED_DESCRIPTOR` 与 `CJGUI_MIXED_PROTOCOL`。

## 独立客户端

```bash
python3 client.py DESCRIPTOR inspect    # 公开 catalog
python3 client.py DESCRIPTOR create     # 提交文本/整数/布尔/动作结构
python3 client.py DESCRIPTOR read       # 结构、字段、动作与实例
python3 client.py DESCRIPTOR reorder    # 运行中重排已有节点
python3 client.py DESCRIPTOR reject     # 非法字段绑定必须被拒
```

外部改值复用公共 `client.py` 的 `invoke`（`EDIT_DRAFT_TEXT` / `EDIT_DRAFT_BOOLEAN` /
`APPLY_DRAFT`），与手写输入和生成按钮进入同一 owner。客户端只使用当前 descriptor，
不持有第二份业务状态。

## 依赖与源码

- 框架：`cjgui`（含实验性 generated UI 适配器）；准确清单以框架内
  `platforms/linux/framework-sources.txt` 的 64 行为准，其中包含
  `composable_ui_generated_form_binding.cj`、`composable_ui_generated_range_session.cj`、
  `composable_ui_generated_region.cj`、`composable_ui_slider.cj`、`composable_ui_collection_selection.cj`、
  `composable_ui_generated_region_diag.cj`、`native_text_typography.cj`；
- 公共协议：`shared_operation_core` 与 `client.py`；
- 业务 provider：`examples/notification_threshold_application`（只消费，不复制定义）；
- 平台：X11 + Vulkan 自绘宿主，llvmpipe 可运行；不引入外部 GUI 依赖。

本模板不承诺 Wayland、完整 IME 或真实模型生成；外部客户端与模型调用需分别标记。
