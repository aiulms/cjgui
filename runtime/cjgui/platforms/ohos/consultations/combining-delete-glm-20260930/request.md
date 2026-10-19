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