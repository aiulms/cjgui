package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@Test
func preparationDependencyKeepsAdvisoryProgressWithoutDiscardingOriginalFrame(): Unit {
    @Assert(cjguiRetainedPreparationDeclarationMatches(12, 13, Some(11), Some(11)))
    @Assert(cjguiRetainedPreparationDeclarationMatches(12, 214, Some(11), Some(11)))
}

@Test
func preparationDependencyInvalidatesOnRealDependencyEvenWithEqualUiRevision(): Unit {
    @Assert(!cjguiRetainedPreparationDeclarationMatches(12, 12, Some(11), Some(12)))
    @Assert(!cjguiRetainedPreparationDeclarationMatches(12, 13, Some(11), Some(12)))
}

@Test
func preparationDependencyPreservesStrictLegacyAndRejectsUnprovedIdentity(): Unit {
    @Assert(cjguiRetainedPreparationDeclarationMatches(12, 12, None, None))
    @Assert(!cjguiRetainedPreparationDeclarationMatches(12, 13, None, None))
    @Assert(!cjguiRetainedPreparationDeclarationMatches(12, 12, Some(11), None))
    @Assert(!cjguiRetainedPreparationDeclarationMatches(12, 12, Some(-1), Some(-1)))
}
