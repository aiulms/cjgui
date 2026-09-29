package cjgui

import std.collection.*

private func ohosRevealClips(inner: CjguiComposableUiRect, outer: CjguiComposableUiRect): ArrayList<CjguiComposableUiRevealClip> {
    let clips = ArrayList<CjguiComposableUiRevealClip>()
    clips.add(CjguiComposableUiRevealClip(inner, 0))
    clips.add(CjguiComposableUiRevealClip(outer, 1))
    return clips
}

@Test
func ohosRevealPlanReplacesIncompatiblePendingInnerRequest(): Unit {
    let target = CjguiComposableUiRect(0, 192, 100, 24)
    let clips = ohosRevealClips(CjguiComposableUiRect(0, 192, 100, 200), CjguiComposableUiRect(0, 0, 100, 120))
    let accepted = ArrayList<Int64>([0, 0])
    let maximum = ArrayList<Int64>([760, 992])
    let preferred = ArrayList<Int64>([100, 0])
    let plan = CjguiComposableUiRevealPlanner.plan(target, clips, accepted, maximum, preferredOffsets: Some(preferred))
    @Assert(plan.isReachable(), true)
    @Assert(plan.offsets[0], 0)
    @Assert(plan.offsets[1], 100)
}

@Test
func ohosRevealPlanKeepsFeasiblePendingInnerRequest(): Unit {
    let target = CjguiComposableUiRect(0, 192, 100, 24)
    let clips = ohosRevealClips(CjguiComposableUiRect(0, 24, 100, 200), CjguiComposableUiRect(0, 0, 100, 120))
    let accepted = ArrayList<Int64>([0, 0])
    let maximum = ArrayList<Int64>([760, 992])
    let preferred = ArrayList<Int64>([100, 0])
    let plan = CjguiComposableUiRevealPlanner.plan(target, clips, accepted, maximum, preferredOffsets: Some(preferred))
    @Assert(plan.isReachable(), true)
    @Assert(plan.offsets[0], 100)
    @Assert(plan.offsets[1], 0)
}

@Test
func ohosRevealPlanLeavesRequestsUntouchedWhenClipIsUnreachable(): Unit {
    let target = CjguiComposableUiRect(0, 192, 100, 24)
    let clips = ohosRevealClips(CjguiComposableUiRect(0, 192, 100, 200), CjguiComposableUiRect(0, 0, 100, 0))
    let accepted = ArrayList<Int64>([0, 0])
    let maximum = ArrayList<Int64>([760, 992])
    let preferred = ArrayList<Int64>([100, 0])
    let plan = CjguiComposableUiRevealPlanner.plan(target, clips, accepted, maximum, preferredOffsets: Some(preferred))
    @Assert(plan.isReachable(), false)
    @Assert(plan.offsets.size, 0)
}
