package cjgui_mixed_form_starter

import cjgui.*
import std.env.*

// Same-binary declaration/resource check, separate from GUI and native worker tests.
func checkFontResources(): Int64 {
    let fonts = CjguiFontResourceRegistry()
    try {
        let spec = CjguiFontResourceSpec.systemFamily("check-body", 1, "Georgia")
        let a = fonts.register(spec)
        let b = fonts.register(spec)
        let bundled = fonts.register(CjguiFontResourceSpec.file("check-bundle", 1, "Lilex-Regular.ttf"))
        if (cjguiFontResourceSupportVersion() != 1u32 || !a.isReady() || !bundled.isReady() || a.fontFamily != b
            .fontFamily || a.fontFamily == bundled.fontFamily ||
            CjguiComposableUiStyle(fontFamily: a.fontFamily).fontFamily != a.fontFamily) {
            return 1
        }
        let replacement = fonts.replace(CjguiFontResourceSpec.file("check-bundle", 2, "missing-preview-font.ttf"))
        if (replacement.state != "fallback_missing_file" || bundled.isRegistered()) {
            return 2
        }
        var refused = false
        try {
            let _ = fonts.register(CjguiFontResourceSpec.systemFamily("check-body", 1, "Times"))
        } catch (_: Exception) {
            refused = true
        }
        if (!refused) {
            return 3
        }
        let catalog = CjguiGeneratedUiCapabilityCatalog()
        if (!catalog.registerFontResource(a) || !catalog.registerFontResource(replacement) ||
            catalog.fontResourceFor("check-bundle", 1).isSome() || catalog.fontResourceFor("check-bundle", 2).isNone()) {
            return 4
        }
        getStdOut().writeln(
            "FONT_RESOURCE_CHECK stable_identity=true ready=${a.resolvedFamily},${bundled.resolvedFamily} missing=${replacement.state} conflict_refused=true")
        getStdOut().flush()
    } finally {
        fonts.close()
    }
    if (cjguiFontResourceDiagnostics()[0] != 0u64) {
        return 5
    }
    return 0
}
