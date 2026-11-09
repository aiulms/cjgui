package cjgui

@Test
func animationTerminalSpringStartsAtExactTargetWhenAlreadyAtRest(): Unit {
    let animation = CjguiComposableUiScalarAnimation.sprung(0.0001, 0.0, 0.0, velocity: 0.0001).getOrThrow()
    @Assert(animation.isActive(), false)
    @Assert(animation.isCompleted(), true)
    @Assert(animation.presented(), 0.0)
    @Assert(animation.velocity(), 0.0)
    @Assert(animation.advanceTo(100.0), 0.0)
}

@Test
func animationTerminalPointStepsRetuneAndRebaseWithoutResidual(): Unit {
    var slots = 0.0
    for (_ in 0..58) {
        slots += 1.0 / 58.0
    }
    let animation = CjguiComposableUiScalarAnimation
        .retuned(-slots * 58.0, -58.0, 0.0, 100.0,
            CjguiComposableUiAnimationSpec.spring(stiffness: 500.0, dampingRatio: 1.0))
        .getOrThrow()
    @Assert(animation.isActive(), false)
    let rebased = animation.translated(58.0).getOrThrow()
    @Assert(rebased.target(), 0.0)
    @Assert(rebased.presented(), 0.0)
    @Assert(rebased.advanceTo(200.0), 0.0)
}

@Test
func animationTerminalSpringKeepsMotionOutsideRestTolerance(): Unit {
    let animation = CjguiComposableUiScalarAnimation.sprung(0.0001, 0.0, 0.0, velocity: 1.0).getOrThrow()
    @Assert(animation.isActive(), true)
    @Assert(animation.isCompleted(), false)
    @Assert(animation.presented(), 0.0001)
    @Assert(animation.velocity(), 1.0)
}
