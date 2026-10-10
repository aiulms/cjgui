// H 连续写作包 A 的离线反例：键盘遮挡在 reveal 规划里必须是**键盘以上的
// 可见区**这一个矩形。
//
// planner 的 clip 语义是「目标必须落在矩形内」。2026-10-07 设备首轮探针实测到
// 的旧实现把**键盘区域本身**当 clip，于是变成「caret 必须在键盘里」——每帧
// `plan=reveal_unreachable`、永不滚动，caret 停在键盘之下（原件：
// artifacts/h-continuous-write-20261007/a-keyboard/probe-1、probe-2）。本文件把
// 正确形状与旧形状的判别固定下来：撤回修复（或再写成键盘区域）即翻红。
//
// 另固定 caller 的取整规则：caret 底沿是浮点，底边必须 ceil（514.0 若是被截成
// 513，只滚 11 而不是 12，最后 1vp 留在键盘下——设备实测）。
package cjgui

import std.collection.*

@Test
func revealKeyboardOcclusionMustBeVisibleRegionAboveIt(): Unit {
    let viewportClip = CjguiComposableUiVisualRect(0.0, 45.0, 377.0, 668.0)
    let keyboardTopVp = 502.0
    // 正确形状：底边 = 键盘顶、覆盖其上全部空间（宽度足够覆盖 caret 横带）。
    let aboveKeyboard = CjguiComposableUiVisualRect(0.0, keyboardTopVp - 1000000.0, 1000000.0, 1000000.0)
    let clips = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(viewportClip, 0),
        CjguiComposableUiRevealClip(aboveKeyboard, 0)
    ])
    let offsets = ArrayList<Int64>([11])
    let maximums = ArrayList<Int64>([1299])

    // caret 完全在键盘之上：已可见，规划出同 offset（幂等）。
    let caretAbove = CjguiComposableUiVisualRect(22.0, 400.0, 333.0, 21.0)
    let visible = CjguiComposableUiRevealPlanner.plan(caretAbove, clips, offsets, maximums)
    @Assert(visible.reason, "reveal_visible")
    @Assert(visible.offsets[0], 11)

    // caret 底 514 越过键盘顶 502：底沿 ceil → 需要 12 的位移（不是 11）。
    let caretBelow = CjguiComposableUiVisualRect(22.0, 493.0, 333.0, 21.0)
    let need = CjguiComposableUiRevealPlanner.plan(caretBelow, clips, offsets, maximums)
    @Assert(need.reason, "reveal_requested")
    @Assert(need.offsets[0], 23)

    // 旧形状（键盘区域本身当 clip）：正确输入也只得到 unreachable。
    let keyboardRegion = CjguiComposableUiVisualRect(0.0, keyboardTopVp, 1000000.0, 1000000.0)
    let badClips = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(viewportClip, 0),
        CjguiComposableUiRevealClip(keyboardRegion, 0)
    ])
    let badVisible = CjguiComposableUiRevealPlanner.plan(caretAbove, badClips, offsets, maximums)
    @Assert(badVisible.reason, "reveal_unreachable")
    let badBelow = CjguiComposableUiRevealPlanner.plan(caretBelow, badClips, offsets, maximums)
    @Assert(badBelow.reason, "reveal_unreachable")
}

// 键盘收起（无遮挡 clip）时，同一 caret 仍是幂等可见——键盘可视区变化的两端
// 都必须有确定解，避免「收键盘后反而滚走」。
@Test
func revealWithoutKeyboardKeepsCaretIdempotent(): Unit {
    let viewportClip = CjguiComposableUiVisualRect(0.0, 45.0, 377.0, 668.0)
    let clips = ArrayList<CjguiComposableUiRevealClip>([
        CjguiComposableUiRevealClip(viewportClip, 0)
    ])
    let offsets = ArrayList<Int64>([11])
    let maximums = ArrayList<Int64>([1299])
    let caret = CjguiComposableUiVisualRect(22.0, 600.0, 333.0, 21.0)
    let plan = CjguiComposableUiRevealPlanner.plan(caret, clips, offsets, maximums)
    @Assert(plan.reason, "reveal_visible")
    @Assert(plan.offsets[0], 11)
}
