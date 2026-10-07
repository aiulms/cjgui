package cjgui

/// Experimental macOS application entry scope. Its private ticket covers the
/// ordinary loop and the consumer's actual tail cleanup. Window close may
/// request AppKit stop, but the launcher cannot return ahead of this scope.
/// This adds no cross-platform application terminal or text-session contract.
@When[os == "macOS"]
public func cjguiRunMacosApplication(body: () -> Int64): Int64 {
    let ticket = unsafe { cjgui_internal_renderer_acquire_application_cleanup() }
    if (ticket == 0u64) {
        return 1
    }
    try {
        return body()
    } finally {
        // Final export owns sampler shutdown. An output failure is a named
        // failed diagnostic, never an inferred successful footer.
        let _ = unsafe { cjgui_internal_renderer_finalize_owner_trace() }
        let _ = unsafe { cjgui_internal_renderer_complete_application_cleanup(ticket) }
    }
}

@When[os != "macOS"]
public func cjguiRunMacosApplication(body: () -> Int64): Int64 {
    return body()
}
