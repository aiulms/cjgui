package cjgui_shared_document_window_app

import cjgui.*
import std.unittest.*
import std.unittest.testmacro.*

@When[os == "macOS"]
@Test
func failedGuardSavePreservesExternalDiskAndDirtyOwnerForCancel(): Unit {
    cjguiMacosOwnerTest({ => failedGuardSavePreservesExternalDiskAndDirtyOwnerForCancelBody() })
}

@When[os == "macOS"]
@Test
func canceledWindowCloseRetainsCardEditorOwnerAcrossDifferentSelection(): Unit {
    cjguiMacosOwnerTest({ => canceledWindowCloseRetainsCardEditorOwnerAcrossDifferentSelectionBody() })
}
