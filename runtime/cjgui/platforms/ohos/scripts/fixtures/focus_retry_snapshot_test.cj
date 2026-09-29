package cjgui

@Test
func ohosCheckedFocusGeometryRaceGetsBoundedRetry(): Unit {
    @Assert(cjguiFocusNativeFailureIsRetryable(CJGUI_INTERNAL_RENDERER_GEOMETRY_EMPTY), true)
    @Assert(cjguiFocusNativeFailureIsRetryable(CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR), false)
    var attempts: Int64 = 0
    while (cjguiFocusRetryAllowed(attempts, false)) {
        attempts = cjguiFocusNextAttemptCount(attempts, false)
    }
    @Assert(attempts, 3)
    @Assert(cjguiFocusRetryAllowed(attempts, false), false)
    @Assert(cjguiFocusNextAttemptCount(attempts, true), 0)
}
