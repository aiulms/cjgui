# 公共字体资源（experimental，macOS）

应用通过一个 `CjguiFontResourceRegistry` 声明系统字体族或随包字体。旧 `system`、`monospaced`、`system-italic`、`monospaced-italic` 和默认行为保持兼容；直接传入其他旧字符串仍沿旧规则归 system。选择实际字体须使用已解析的资源引用：

```cangjie
let fonts = CjguiFontResourceRegistry()
let body = fonts.register(CjguiFontResourceSpec.systemFamily("body", 1, "Georgia"))
let code = fonts.register(CjguiFontResourceSpec.file("code", 1, "Lilex-Regular.ttf"))
let style = CjguiComposableUiStyle(fontFamily: body.fontFamily, fontSize: 17.0)
let catalog = CjguiGeneratedUiCapabilityCatalog()
let _ = catalog.registerFontResource(body)
let _ = catalog.registerFontResource(code)
// 原应用/窗口正常关闭后，在同一资源 owner 的 finally 中：
fonts.close()
```

同一引用可用于 label/button、单行/多行字段、`CjguiComposableUiTextStyleRun.fontFamily` 和现有测量器。字距、绝对行高、换行、省略、光标命中及系统输入仍走原 TextKit/输入链。完整正文和语义值不变。资源选择只指定主字体，中文、emoji等缺字由系统 fallback 提供；不是自研 shaper 或字体覆盖保证。单个字体文件的可用字重由该字体及系统匹配决定，不伪造额外字体面。fallback 只接受上述四种旧模式，其他值明确拒绝声明。

`reference.key/version` 是应用资源身份，`state` 和 `resolvedFamily` 是实际解析事实；`fontFamily` 是框架生成的值引用，不是 native 对象或地址。`ready` 表示资源可用；缺失族/文件、无效字体或容量不足分别为 `fallback_missing_family`、`fallback_missing_file`、`fallback_invalid_font`、`fallback_capacity`。其测量和绘制都使用声明的同一 fallback，绝不只在绘制阶段偷偷换字体。后端失败另报 `fallback_backend_failure`。`cjguiFontResourceSupportVersion()` 在 Mac 为1，未支持平台为0并返回 `unsupported_fallback`；本轮没有为其他平台增加原生字体适配。

生成目录在原 capabilities 中发布 `FONT_RESOURCE key version state u8:familyUtf8Hex|u8:nameUtf8Hex`，Python typed client 提供 `font_resources` / `font_resource(key, version)`。文本节点的 `fontResource` 与 `fontVersion` 必须成对引用已登记资源；生成声明不能提交系统族或文件路径。不匹配/已撤回资源拒绝整个新候选。普通刷新继续使用已接受结构冻结的引用；资源换版不使旧场景突然重新解析。

注册一次，重复相同声明复用结果；`replace(spec)` 要求更高版本，`withdraw(key)` 撤回目录准入；撤回后再次声明同 key 也必须用更高版本。旧已接受节点、样式 runs、准备输入和异步测量任务持有原代 lease，完成/退休前不失效；关闭 registry 只释放其注册引用，不抢先销毁在途资源。一个 registry 通常由应用持有，多窗口共享时在所有消费窗口关闭后 `close()`，关闭幂等。渲染仍持有已复制的实际字体/排版资源，原有 GPU 完成退休契约保留。

Mac 使用 CoreText/CGFont 加载不可变资源，不注册进全进程字体名空间。选择缓存按不可复用的代次及字号/字重索引；共同布局/测量键、native 光栅键和 runs 已含同一字体引用。增加字体不会改写旧引用的几何；换版获得新代，自然失效相关缓存。这里借鉴本地 GPUI 的“注册后失效”和在途旧代可完成原则，采用 CJGUI 既有快照与引用，不引入 GPUI 依赖或另一套排版系统。

当前有界约束：每 registry 最多256个逻辑 key 历史，native 最多128个活动注册/256个存活代；单文件≤16MiB、注册代持有字体文件总计≤32MiB，每代最多64个字号/字重快照；字体族名≤4096 UTF-8字节且不含ASCII控制字符，声明不支持的元数据明确回退。文件按应用声明一次读取，不每帧解析。资源路径沿用现有图片应用资源定位（当前目录存在则取该文件，否则取 bundle Resources）；生成方始终只能引用 key/version。普通 runner 的 `CJGUI_MACOS_APP_RESOURCES` 同时携带字体和许可证。

mixed-form 的 `--fonts` 薄接公共组合：手写 Georgia、同字段生成 Lilex、同 owner 的只读多行投影和样式 run；“字体换版／缺失回退”更换资源声明，`client.py DESCRIPTOR font-switch --font-resource preview-mono` 引用目录中的当前版本。默认不传 `--fonts` 的消费者不加载资源。内置 Lilex Regular 为未修改的 SIL OFL 1.1 字体夹具，版权、来源和许可证在 `resources/fonts/`，App携带 OFL.txt。

`cjguiFontResourceDiagnostics()` 只返回活动注册、存活注册代、注册文件字节、快照构造次数和注册次数，不是 RSS、全部系统字体内存或端到端延迟。实际 VoiceOver、其他平台、完整 IME、旧 GiB 和严格呈现性能不由字体接入自动证明。
