# 公共文字排版（实验性，macOS）

在现有任务板构建目录运行：`./run.sh --typography`。默认任务板入口不变。
页面复用原任务字段、规则、生成区域和外部连接；排版开关只保存展示参数。

```cangjie
let paragraph = CjguiComposableUiNamedStyle("paragraph", theme.body)
let style = paragraph.localStyle(letterSpacing: Some(1.5), lineHeight: Some(32.0))
// 同一 style 可传给只读文字、按钮、单行或多行输入。
```

两项均为逻辑点。`letterSpacing` 接到系统字形排版，范围为 `(-1000,1000)`；
`lineHeight` 为绝对行框高度，范围为 `(0,1000)`，`0` 使用自然行高。
手写声明的非法值沿用 Style 的归零规则。过紧行框允许字形重叠，字体不会被压缩。
命名样式未覆盖的值继承原声明；显式 `Some(0.0)` 恢复默认。
主题和交互 paint 覆盖保留这两个排版事实。

生成式使用同名属性及同一单位。因既有协议无小数类型，数值采用有界 STRING 十进制，
最多 3 位小数；不接受指数、NaN、空白前缀或越界值。缺省继承命名样式，空串或 `0` 清除覆盖。
非法候选被拒绝并保留上一份已接受结构。

```text
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor letterSpacing 1.5
PROPERTY 1 titleEditor lineHeight 32
```

字距先参与字形布局和换行，再应用只读 `textMaxLines` / `textOverflow`。
末行省略只改变绘制，完整字符串、owner 值与语义值保留。
style runs 可覆盖字体和 paint，继承节点字距与段落行高；自然行高由 TextKit 决定。
混合字号的自动节点高度仍沿用现有标量测量契约，宜声明足够的行高或固定高度；
本页未声明通用富文本自动高度支持。

本轮实际接通 macOS 的同步/异步测量、自绘及既有编辑几何；保留旧 native 测量入口。
其他后端继续各自既有入口，未在本轮验收，也不要求同步冻结快照。
实际 VoiceOver、完整 IME 和旧大文件性能矩阵不属于本页的自动化结论。
