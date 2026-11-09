package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// AppKit creation belongs to the normal launcher main-thread process, not the
// Cangjie test worker. The bundled production probe covers Host lifecycle;
// this test retains only the owner-independent scalar contract.
@Test
func macosApplicationWindowConfigurationRejectsMissingTitleOrGeometry(): Unit {
    let usable = CjguiMacosApplicationWindowConfiguration("独立应用", 720u32, 480u32)
    let missingTitle = CjguiMacosApplicationWindowConfiguration("", 720u32, 480u32)
    let missingWidth = CjguiMacosApplicationWindowConfiguration("独立应用", 0u32, 480u32)

    @Assert(usable.isValid(), true)
    @Assert(missingTitle.isValid(), false)
    @Assert(missingWidth.isValid(), false)
}

@Test
func macosApplicationWindowIdentifierHasNoNativeHandleAndRejectsInvalidGenerations(): Unit {
    let live = CjguiMacosApplicationWindowIdentifier("application_2", "window-2-g7", 7)
    let missingValue = CjguiMacosApplicationWindowIdentifier("application_2", "", 7)
    let missingGeneration = CjguiMacosApplicationWindowIdentifier("application_2", "window-2-g0", 0)

    @Assert(live.isValid(), true)
    @Assert(live.applicationIdentifier, "application_2")
    @Assert(live.value, "window-2-g7")
    @Assert(live.generation, 7)
    @Assert(live.belongsTo("application_2"), true)
    @Assert(live.belongsTo("application_3"), false)
    @Assert(missingValue.isValid(), false)
    @Assert(missingGeneration.isValid(), false)
}

@Test
func macosApplicationsAllocateDistinctOwnersBeforeAnyNativeWindowStarts(): Unit {
    let first = CjguiMacosApplication()
    let second = CjguiMacosApplication()

    @Assert(first.applicationIdentifier().size > 0, true)
    @Assert(second.applicationIdentifier().size > 0, true)
    @Assert(first.applicationIdentifier() == second.applicationIdentifier(), false)
}
