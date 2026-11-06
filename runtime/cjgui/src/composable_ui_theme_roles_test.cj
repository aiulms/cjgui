package cjgui

@Test
func themeRolesCarrySelectionFocusAndDisabledWithoutChangingGeometry(): Unit {
    let theme = CjguiComposableUiTheme.warmPaper()
    let bound = theme.navigationRow().boundStyle(growX: Some(1), fixedHeight: Some(32))
    let selected = bound.interaction.resolve(bound.style, CjguiComposableUiInteractionState.SELECTED)
    let focusedHover = bound.interaction.resolve(bound.style,
        CjguiComposableUiInteractionState.SELECTED | CjguiComposableUiInteractionState.FOCUSED |
        CjguiComposableUiInteractionState.HOVER)
    @Assert(focusedHover.background.red, selected.background.red)
    @Assert(focusedHover.borderWidth, 2)
    @Assert(focusedHover.fixedHeight, 32)
    @Assert(focusedHover.growX, 1)
    @Assert(focusedHover.alignX, CJGUI_COMPOSABLE_UI_ALIGN_STRETCH)
    let disabled = bound.interaction.resolve(bound.style,
        CjguiComposableUiInteractionState.SELECTED | CjguiComposableUiInteractionState.DISABLED)
    @Assert(disabled.borderWidth, 1)
    @Assert(disabled.textColor.red != selected.textColor.red, true)
}

@Test
func themeRoleCatalogCanBeSharedWithGeneratedNodesAndAnotherPalette(): Unit {
    for (theme in [CjguiComposableUiTheme.warmPaper(), CjguiComposableUiTheme.beaconDark()]) {
        let catalog = CjguiComposableUiNamedStyleCatalog()
        for (role in theme.namedStyles()) { @Assert(catalog.register(role), true) }
        @Assert(catalog.forName("navigation").isSome(), true)
        @Assert(catalog.forName("input").isSome(), true)
        @Assert(catalog.forName("error").isSome(), true)
        @Assert(catalog.forName("quiet_action").isSome(), true)
        @Assert(theme.actionStyle(primary: true).base.fixedHeight, 32)
        @Assert(theme.itemRow().base.growX, 1)
        @Assert(theme.feedbackStyle(CjguiComposableUiFeedbackKind.EMPTY).base.fixedHeight, 0)
        @Assert(theme.feedbackStyle(CjguiComposableUiFeedbackKind.ERROR).base.textMaxLines, 0)
    }
}

@Test
func themeRolesAdaptExistingFeedbackBuilders(): Unit {
    let theme = CjguiComposableUiTheme.warmPaper()
    let status = CjguiStatusMessageStyle.themed(theme, CJGUI_STATUS_ERROR)
    @Assert(status.container.fixedHeight, 0)
    @Assert(status.actionInteraction.focused.border.isSome(), true)
    let content = CjguiContentStateStyle.themed(theme, CJGUI_CONTENT_EMPTY)
    @Assert(content.container.fixedHeight, 0)
    let node = CjguiContentFeedback.build(83001, "empty-search", 83002, 83003, 83004,
        CjguiContentStateSpec(CJGUI_CONTENT_EMPTY, emptyReason: CJGUI_EMPTY_NO_MATCH), style: content)
    @Assert(CjguiComposableUiLayoutEngine.layout(node, CjguiComposableUiRect(0, 0, 280, 300), 1).isValid(), true)
}
