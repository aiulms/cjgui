# 公共多样式只读文本（Experimental）

macOS Apple Silicon / Cangjie 1.1.3。`cjguiComposableText(..., textStyleRuns: ...)` 沿用已有 run 声明；自动宽高、首行基线、换行、最大行数和末行省略使用与自绘相同的 attributed TextKit 属性及布局。完整业务值和 AX 文本不被截短，本能力不扩展为富文本编辑器。

```cangjie
let note = cjguiComposableText(20, "description", "normal BIG 中文",
    CjguiComposableUiStyle(fontSize: 14.0, growX: 1, textMaxLines: 2, textOverflow: "ellipsis"),
    textStyleRuns: [CjguiComposableUiTextStyleRun(7, 10, 36.0, 0, "monospace", 1.0, 0.3, 0.2, 1.0)])
```

范围使用 UTF-8 字节边界，拒绝标量内部偏移、NUL、非有限字号/颜色或无效范围。沿用既有 2048 run / 文本预算；字形和 emoji 换行交由系统文字服务处理。自定义 `CjguiComposableUiTextMeasurer` 需同时实现可选 `CjguiComposableUiStyledTextMeasurer.measureStyled` 才能测量混合字体/字号；否则返回 `styled_text_measurer_unsupported`，普通文本保持旧行为。其他平台的默认实现及生成片段消费返回不支持。

## 生成声明

公共 form catalog 的 label 使用 `styledTextStyleProperties()`，自定义 label catalog 可显式复用此属性组。仅 TEXT/label 消费 `textRuns`，输入控件保持既有编辑路径。

```python
from cjgui_generated_client import GeneratedTextStyleRun, styled_text_runs_property
spans = styled_text_runs_property("normal BIG 中文", [
    GeneratedTextStyleRun(7, 10, font_size=36, font_weight=0,
                          font_resource="app-mono", font_version=1, color="#F27340")])
```

v1 wire 每项 `start:end:size:weight:fontKey:fontVersion:color`，以分号分隔；最多 64 项、16384 字节，正文最多 65536 字节，仍受 catalog 的正文长度限制。`base:0` 继承基础字体，size=0 / weight=-1 / color=inherit 继承基础样式。字体只引用应用已注册的 key/version，不接收文件路径或原生 family ID。非法范围或过期字体拒绝整份候选，已接受树、owner 字节和版本保留。

## 排版与资源

复用有界共同测量缓存、prepared layout 和异步 job；冻结输入持有原字体代际，完成、取消与配额沿用原通道。几何身份包含正文、范围、字体代际/字号/字重、宽高、字距、行高、行数/省略、缩放和外观；纯颜色/选择背景不参与测量几何身份。Mac 被动 TEXT 配色候选共享已接受几何，以作用域内临时颜色绘制并在 finally 恢复。输入代理的布局生命周期保持原契约。

字体文件从同一已打开描述符分块有界读取，并核对读取前后身份、大小及变化；保留配额按实际字节计。窗口销毁退役自己的 overlay、AX 节点引用和布局缓存；其他窗口及在途冻结 job 的代际租约继续有效。原生租约获取使用明确的 ARC retained 返回契约，弱注册表查询的临时引用在局部作用域内结束；最后持有者结束不依赖进程退出或调用者排空外层 autoreleasepool。

## 正常消费

包外 mixed-form 的 `./run.sh --styled-text` 使用同一 `assets/styled-description.tsv` 供手写控制器与独立 `client.py DESCRIPTOR styled-generate` 消费，不固定说明高度。`styled-color`、`styled-size`、`styled-font-current` 更新同一声明。`打开字体对照窗` 使用同一 MacApplication 和字体 owner；`结束字体核对` 先开系统字体观察窗，再请求正常关闭字体窗口并退役注册 owner；点击 `查看资源结果` 读真实计数。说明资产按运行脚本或 app 内 Resources 相对定位，不依赖构建目录。

本轮实际数字、源身份、连续操作、资源结果与未验边界见 E 当前交付证据。固定原生段落的准备/绘制成本不等于端到端帧时或 GPU 收益。真实 VoiceOver、其他平台与富文本编辑不计作已验范围。
