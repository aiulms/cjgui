package cjgui

import std.unittest.*
import std.unittest.testmacro.*

@Test
func macosWindowStateSeparatesTransitionFromActualFullscreen(): Unit {
    let entering = CjguiMacosApplicationWindowState([0u64, 1u64, 7u64, 0u64, 1u64,
        980u64, 620u64, 0u64, 99u64, 1960u64, 1240u64])
    @Assert(entering.isFullScreen, false)
    @Assert(entering.isEnteringFullScreen, true)
    @Assert(entering.isExitingFullScreen, false)
    @Assert(entering.contentWidth, 980)
    @Assert(entering.drawableWidth, 1960u64)
    @Assert(entering.stateRevision, 7u64)
    let failed = CjguiMacosApplicationWindowState([1u64, 0u64, 8u64, 0u64, 1u64,
        980u64, 620u64, 2u64, 99u64, 1960u64, 1240u64])
    @Assert(failed.isFullScreen, true)
    @Assert(failed.isEnteringFullScreen, false)
    @Assert(failed.fullScreenFailure, "exit_failed")
}

@Test
func macosWindowStateRejectsForeignOrClosedApplicationIdentity(): Unit {
    let application = CjguiMacosApplication()
    let otherIdentity = CjguiMacosApplicationWindowIdentifier("other-app", "main", 1)
    @Assert(application.windowState(otherIdentity).isNone(), true)
    @Assert(application.requestFullScreen(otherIdentity, true), false)
    application.close()
    @Assert(application.windowState(otherIdentity).isNone(), true)
    @Assert(application.requestFullScreen(otherIdentity, false), false)
}
