## 一、证据（直接来自指定文件与产物，非推断）

**E-1 接受链路完好（result.json）**
- `candidate_matches_accepted_structure: true`，`status=accepted`，`owner_unchanged_during_structure_submit: true`；语义 id 801001–808001 全部分配。
- 候选自身内禀高度非零且自洽：panel `fixedHeight 226`、viewport `340×220`、content 328。
- bounds 内部算术逐点吻合 vp：trigger y554 → row1 y608（+46+8）→ row2 y682（+66+8）→ row3 y756 → editor y830。gap/高度完全按声明值叠加，说明生成结构的测量与布局数学是健康的。

**E-2 布局是 vp 单位（settings_counter.cj 注释自证）**
「N2 密度修复后布局单位是 vp（模拟器窗口实测 377x487 vp）」。thermo panel x=28 恰等于其 root padding 28，panel 宽 321 = 377−2×28，证实实例 bounds 为表面相对 vp 坐标。

**E-3 两个消费方的关键差异（两份 buildUi 对照）**
- settings：title(24) → mixed(16) → **`root.add(generatedRegion.buildNode())` 直接插入** → handScroll(150) → cardBox；头部与视口已按 vp 收紧。
- thermo：title(52) → cardBox(高≈550：24×2 padding + 84+72+64+56+72+84 + 5×14 gap) → handScroll(420) → **最后**另包一层无 fixedHeight 的 `generatedBox`。52/84/420/28/18 全是 settings 收紧前的像素时代量级，thermo 从未做过 N2-V 同等改造。

**E-4 机制非缺陷（settings 为绿对照）**
同一 host、同一 SUBMIT/准入、同一 scroll 意图通道，settings 的公开生成视口当前可消费。共享机制与准入实现没有被本问题证伪的点。

## 二、可确定的根因

**放置顺序 + 旧像素量级，而非共享 scroll/惯性机制，也非生成结构本身。** 表面高 487vp；thermo 在 generatedBox 之前的栈消耗——即使按最有利的测量读法（见下）——至少 28+52+18+18+420+18 = **554vp**，panel 顶 554 > 487，全部实例几何性 `visible=false`。候选作者给的 340×220 本身就是 vp 量级（340 < 377），错不在候选。

## 三、554 的算术解释与仍需区分的假设

关键恒等式：按文件完全叠加，generatedBox 应在 **28+52+18+550+18+420+18 = 1104vp**；实测 554 = 1104 − 550（恰为 cardBox 高）。

- **H1（首选推断）**：无 fixedHeight 的 vertical 容器在窗口栈中测量高度为 0（cardBox 贡献 0，children 仍从 y98 起布局）。由此可推出：generatedBox 自身也贡献 0——**额外包装层不是 off-screen 的原因**（对原假设中「generatedBox 影响内禀高度导致屏外」这一支应予否定：有无包装层，panel 都落在同一槽位 554）。但 H1 有一个反向推论：若重排后仍保留 0 高包装层在兄弟之前，后续兄弟会与生成 panel **重叠**——settings 直接 `add(buildNode())` 正是绕开了这一点。
- **H2（备选）**：产物所用的 canonical source 与本工作树 buildUi 有差异（card 实际更小）。

区分实验（只读、可立即对 PID 14568 做）：用同一实例回读端点读 thermo **手写节点** bounds——若 thermo-hand-scroll ≈ y116..536 且与 card 子件（98..648）重叠，H1 成立；若 hand-scroll 在 y666，H2 成立，先核对 canonical source 谱系再动工作树。两读法下最小修法相同，决策不被阻塞。

## 四、最小可实施布局方案（仅动 thermo buildUi）

1. **必改**：把生成区移到 title 之后、cardBox/handScroll 之前，并按 settings 同款直接 `root.add(generatedRegion.buildNode())`，删除 generatedBox 包装（H1 语义下保留 0 高包装层会导致与后续 card 重叠）。结果：panel 98..324，viewport 98..318，trigger 98..144——全部在 487vp 内、可触。
2. **建议（让手写视口与生成区同屏）**：N2-V 同款收紧——heading 52→24、root padding 28→12、gap 18→10、handScroll 420→150。预算：12+24+10+226+10+150 = 432 ≤ 487，余 55vp。手写内容 ≈840vp 仍 > 3×150，三屏滚动语义保留。card 维持在折叠线下方（settings 亦如此），可后续独立处理。
3. 不动：候选结构、惯性积分、SCROLL 意图通道、准入/owner、visible 判据、ArkTS 窄宿主。

## 五、验收与反例（falsifiers）

- **正例**：重排后回读 viewport `visible=true` 且 y<487；trigger 中心 (198vp, 121vp) → 屏幕 ≈(693px, 121×3.5+137≈560px)；点按后 owner TEMP_UP 版本前进。viewport 需滚 328−220 = **108vp = 378px** 到底，editor（content 相对 276..328）随后全显，点按经 focus 请求 → 系统输入 → EDIT_TEXT 写 owner note。
- **注意**：重排后 editor 初始 `visible=false` 是**合法的**（在 viewport 裁剪线下），不得当失败；判据是滚动后可见 + 可聚焦。
- **负控**：修复后点旧位置（y554 区）必须无命中——证明是几何移动而非放宽命中。
- **反例出口**：若重排后 panel y<487 仍 `visible=false` → 放置根因被证伪，转查表面高度/可见性上报；若公开几何换算的点按在 settings 有效而 thermo 无效 → 单位/原点假设错，非布局；若生成 viewport 拖动不动而同 app 手写 scrollArea 可滚 → 才是共享通道问题（现有证据均反对走到这一步）。

## 六、前提与单位边界

- 布局单位 vp；px = vp×3.5；bounds 为表面相对坐标，注入触摸需加表面原点（y +137px；x 原点未在本轮给出，建议用 settings 已知有效点按标定一次）。
- viewport 宽 340 > root 内容宽 321，会向右溢出父容器 19vp 但仍在 377vp 表面内——现状可接受，不强制改候选。
- H1 若经区分实验证实，则「无 fixedHeight 的 vertical 不占栈高」是本布局引擎的既有语义，最小方案必须遵守（包装层要么删、要么给显式 fixedHeight），不得当框架缺陷去修。
