只读聚焦机制咨询。任务是当前 CJGUI 自绘鸿蒙文本编辑面的选择工具栏（复制、剪切、粘贴、全选），用户实际正常界面只有蓝色双端 handle，没有菜单。不要改文件、构建或操作设备；不扫描整包。
已知：系统 IME 采用 opacity(0) TextArea，focusOnTouch(false)/HitTestMode.None/selectionMenuHidden(true)，因为代理排版几何不能覆盖自绘正文。不能直接启用代理菜单造成漂移。native 已有同一次 OH_Drawing Typography Paint/Flush 的 PaintedSelectionHandles（start/end可见性、坐标、text、context、ticket、binding、geometryRevision）。普通 owned text 走 editorEnqueueTextCommit 精确增量；generic explicit-submit field 走 preview draft、Enter提交。恢复事务已闭合，禁止新 owner 或新业务编辑协议。
计划：imeEditingContext JSON 增加只读菜单几何与资格；框架 arkts 公共 CjguiTextSelectionMenu 只显示工具栏，按当前真实可见端点定位。宿主薄壳 inject 当前 mount 和 install 回调，沿原 TextArea 更新 imeText 与安装落点。复制/剪切使用系统 pasteboard.setData(PasteData)，剪切必须写入成功后才修改文本。粘贴使用真正 PasteButton 的 SUCCESS 临时授权，再 getData。异步返回捕获 original text/context/generation/selection；native 私有 imeMenuCommand 在 g_sessions.lock 下精确比较 expected whole visible text + context generation + selection，拒绝迟到命令，不变 owner；replace 沿现有 editorCommitPlainChangeLocked/generic preview，不添加业务owner。全选也沿现有 selection event，并推送平台安装。composition、恢复进行中、拖动中、surface/context retired 无资格。不要让菜单抢 IME焦点造成finish。
请质疑此方案，特别是：native 编辑事件与 postimage/caret 顺序；generic draft 显示；ArkUI PasteButton 安全样式/定位/焦点规则；surfaceDensity 与逻辑坐标位置。给可区分反例及最小可靠修法。若已验证架构可行，具体建议最小函数。
必要源码：
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp (PaintedSelectionHandles, publishPaintedLayout, editorEnqueueTextCommit, editorCommitPlainChangeLocked, ime_context_json, ime_set_selection_ctx)
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/cjgui_host_bridge.cpp (ImeEditingContext, ImePreviewText, ImeSetSelection)
/Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/arkts/cjgui-text-proxy.ets
/Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets (proxyTextInput, onProxyCaret, armProxySelection)
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/component/paste_button.d.ts
/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/api/@ohos.pasteboard.d.ts
参考只借鉴：/Users/jiangxuanyang/Desktop/仓颉GUI 开发工具仓库/flutter/packages/flutter/lib/src/widgets/text_selection.dart (handlePaste asyncrace), editable_text.dart (copy/cut/paste), test/widgets/editable_text_test.dart。
官方已尝试打开V14 PasteButton/pasteboard页面超时，当前官方pastebutton指南仅JS壳；本地SDK声明为可靠版本依据。不得把咨询答复当设备证据。
