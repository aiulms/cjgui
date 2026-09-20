package cjgui

/// Compile-and-run public-contract RED for command declarations that survive
/// dynamic component numbering.  It intentionally uses no test-only native
/// symbol: a normal consumer must be able to describe a menu item without a
/// renderer handle or an application callback.
main(args: Array<String>): Int64 {
    let target = CjguiComposableUiNodeReference.scoped(CjguiComposableUiIdentityScope("editor"), "save")
    let command = CjguiComposableUiCommand(
        "document.save",
        target,
        "Save",
        CjguiComposableUiShortcut("s"),
        "File",
        1,
        false,
        true
    )
    if (!command.isValid() || !command.targetReference.isValid() || command.displayName != "Save" ||
        command.menuGroup != "File" || command.menuSection != 1 || command.isEnabled || !command.isChecked ||
        !command.hasShortcut()) {
        return 1
    }
    println("CJGUI_COMMAND_MENU_CONTRACT stable_target=true title=true group=true disabled=true checked=true")
    return 0
}
