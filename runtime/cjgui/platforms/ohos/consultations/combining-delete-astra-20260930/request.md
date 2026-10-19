只读聚焦机制咨询，不修改、不构建、不操作桌面/设备。不要扫描整个夜间整包，不启动执行任务。你是新公共平台删除意图/同 owner 恢复边界的审阅者，请质疑 GLM 建议。

# 只读聚焦咨询：正常 OHOS TextArea 的组合重音退格与 CJGUI 簇契约
不修改、不构建、不操作设备或桌面。不重新盘点 H 夜间任务。只查下列必要源码；质疑执行者的初步归因。

实际反例：最终 normal Pharos HAP sha256 1a1ee8b05743e7c438806b7187ec2df874becc24ebce175a4ca6a50f7db353ca，bundle com.pharos.mark.hovernight20260930，PID23435。公开同版本完整 owner 与 UTF8 读回已确认。真实 UITest 输入一次 H1R、ENTER2054、一次中文e\u0301👨‍👩‍👧‍👦👍🏽🇨🇳；首串和换行全接收；DEL2055 分别整体删除旗帜、肤色、家庭组合。下一次 DEL2055 对 e+U0301 只删除了重音，owner v10 26B 为 '# Pharos Mark\n\nH1R\n中文e'。严格期望删除 e+重音，25B。原始末次读回见 combining-red.raw.json。未重发输入，无实现修复尝试。

用户门槛：中文/emoji/多码点退格不切半个字符或簇；系统输入法只做系统集成，不能自研引擎/候选/词库；CJGUI 通用机制，ArkTS 薄壳，不造第二 owner/protocol；不能把平台机制未知当绿色或降低判据。

事实：产品隐藏代理刚从 TextInput 改 TextArea，NEW_LINE。onChange+previewText 交 CjguiTextProxyRegistry/native；尚未截获 onWillDelete/onDidDelete（未查其精确语义）。现行 OHOS native cjgui_internal_renderer_grapheme_cluster_range 是具名 UNSUPPORTED stub，mac 使用 CFString 组合字符范围；snapshot text_session plain DeleteBackward 没有服务会具名拒绝，但平台 onChange 路径可合法按 UTF16 delta 接受。SDK unicode/ubrk.h+libicu.so 实际存在、dynsym ubrk_open/close/preceding/following/isBoundary/u_strFromUTF8/u_strToUTF8 均导出。SDK getLineInstance 是断行不是字符；intl Segmenter 未找到。华为官方 ICU4C URL此次抓取timeout，不能当内容已查；本机头为对应 SDK 声明。

必要源码：
- /Users/jiangxuanyang/Desktop/Pharos Mark/apps/pharos_mark_ohos/entry/src/main/ets/pages/Index.ets（代理 TextArea 与 onChange/restore；只看有关函数）
- /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/（find 定位 CjguiTextProxyRegistry.ets 与 bridge text proxy receive）
- /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/snapshot/src/text_session.cj（platform commit arbitration、plain intent）
- /Users/jiangxuanyang/Desktop/cangjie/runtime/cjgui/platforms/ohos/host/ohos_renderer.cpp（grapheme stub）
- SDK /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/component/text_area.d.ts（onWillDelete/onDidDelete 精确语义）
- SDK native/sysroot/usr/include/unicode/ubrk.h，unicode/uvernum.h

请给：1 可区分的平台行为/框架遗漏/代理差分误归因；2 不更改平台事实、更不发明 IME 的最小满足簇契约路径（系统 ICU 窄服务 + 真实删除 intent 是否合理，不能默默扩删平台明确替换范围）；3 精确回调顺序与身份/restore/同版本 owner 仲裁是否需要新契约裁决；4 RED 反例及正常系统输入验证。若没有可靠方案明确说未决，不能给启发式推断键盘删除。

GLM 答复（待审阅）见同目录 ../combining-delete-glm-20260930/answer.md。关键建议：不能在 kind51 已表达的值差提交后默默加宽范围；若平台 onWillDelete 可取消，取消那一笔平台删除、让真实 DeleteBackward/Forward 意图交现有 CjguiTextSession，同 version owner 仲裁一次写入、既有 restore 安装。未决是平台回调触发/取消精确语义、身份与 selection ownership。最小 callback 对照实验正准备中，系统 ICU 72.1 CLI probe 已在SDK编译成功，尚未设备执行。

补充精确点：CJGUI mac 主线在 src/composable_ui_window.cj 3697–3750 已把 native 文本键盘事件 dispatch 到 session.handlePlainIntent；OHOS snapshot 尚无该调用方。原 kind51 native editorEnqueueTextCommit 的 UTF16 差分必须保留，不能手写另一个 owner 或私有编辑协议。对 selected nonempty explicit span 如何处理；preview/composition 与被 owner 变更后的 proxy text/selection 不得当最新正文使用。

要求可实施、可区分的方案：
1. onWillDelete callback 已表达 deleteOffset/direction/deleteValue，如何最小准确识别 collapsed directional cluster deletion 及平台已给明确非空选择的删除？native 查询需要验证哪些代理/accepted/owner版本、selection和绑定身份，不能用 onChange 差分猜意图。
2. native+window 接线选择：复用既有 native event/route，或同步 core intent通道？列出确切文件/接口形状与当前约束；不得只说镜像mac而没有 OHOS 字段/关联版本。正常共享 TextInput/TextArea 消费方式应在 CJGUI registry/native，不让产品写通用分簇。
3. 取消平台后，异步 owner 事务失败/owner换版/输入交错时怎么终态恢复？怎样保证仅一笔撤销单元、restore实际确认和 stale mount不写新field。既有 N1恢复裁决已落地，请复用，不重新重写。
4. 系统 ICU root UBRK_CHARACTER narrow ABI 的 bounds/invalidUTF8/内字节offset/字符串持有释放/服务不可用如何定义兼容mac，不向公众泄露对象或引依赖。
5. 最小生产RED/同一 final正常HAP systeminput验收，及哪些平台实验是方案前提。不要把顾问答复当运行证据，不要求额外人工审批。

可参考成熟框架（只借思路）：Flutter text_boundary.dart CharacterBoundary，editable_text.dart _characterBoundary 与 delete intent action；不能引flutter包依赖。
