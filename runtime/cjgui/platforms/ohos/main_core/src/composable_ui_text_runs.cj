package cjgui

import std.collection.*
import std.convert.*

/// Experimental opt-in: actual attributed line metrics, including the style's
/// maxLines/overflow. Existing custom measurers keep the plain-text interface.
public interface CjguiComposableUiStyledTextMeasurer {
    func measureStyled(value: String, style: CjguiComposableUiStyle,
        runs: Array<CjguiComposableUiTextStyleRun>, maximumWidth: Int64): CjguiComposableUiTextMeasurement
}

func cjguiTextRunsAffectMetrics(style: CjguiComposableUiStyle,
    runs: Array<CjguiComposableUiTextStyleRun>): Bool {
    for (run in runs) {
        if (!run.isSelectionBackground() && (run.fontSize != style.fontSize ||
            run.fontWeight != style.fontWeight || composableFontFamilyCode(run.fontFamily) !=
            composableFontFamilyCode(style.fontFamily))) { return true }
    }
    return false
}

// Only font/range attributes enter geometry and preparation identity. Keep the
// original order: an ordinary later run may reset an earlier font choice.
func cjguiTextRunsGeometryKey(style: CjguiComposableUiStyle,
    runs: Array<CjguiComposableUiTextStyleRun>): String {
    let builder = StringBuilder()
    builder.append("styled-v1:${style.textMaxLines}:${style.textOverflow}|")
    for (run in runs) {
        if (!run.isSelectionBackground()) {
            builder.append("${run.start}:${run.end}:${run.fontSize}:${run.fontWeight}:")
            builder.append("${composableFontFamilyCode(run.fontFamily)};")
        }
    }
    return builder.toString()
}

func cjguiTextRunsMeasurementWire(runs: Array<CjguiComposableUiTextStyleRun>): String {
    let builder = StringBuilder()
    var first = true
    for (run in runs) {
        if (!run.isSelectionBackground()) {
            if (!first) { builder.append(";") }
            first = false
            builder.append("${run.start}:${run.end}:${run.fontSize}:${run.fontWeight}:")
            builder.append("${composableFontFamilyCode(run.fontFamily)}:0:0:0:1:0:0:0:0:0")
        }
    }
    return builder.toString()
}

func cjguiOrdinaryTextRunsRejection(value: String,
    runs: Array<CjguiComposableUiTextStyleRun>): ?String {
    if (runs.isEmpty()) { return None }
    if (runs.size > 2048) { return Some("text_style_runs_budget_exceeded") }
    let bytes = value.toArray()
    for (byte in bytes) { if (byte == 0) { return Some("text_style_runs_nul_source") } }
    for (run in runs) {
        if (run.isSelectionBackground()) { continue }
        if (run.start < 0 || run.end <= run.start || run.end > bytes.size ||
            (run.start < bytes.size && (bytes[run.start] & 0xC0) == 0x80) ||
            (run.end < bytes.size && (bytes[run.end] & 0xC0) == 0x80)) {
            return Some("text_style_run_utf8_range_invalid")
        }
        if (!CjguiComposableUiEffectValidation.isFinite(run.fontSize) || run.fontSize < 0.0 ||
            run.fontSize > 144.0 || run.fontWeight < 0 || run.fontWeight > 1000) {
            return Some("text_style_run_font_invalid")
        }
        for (component in [run.red, run.green, run.blue, run.alpha, run.backgroundRed,
            run.backgroundGreen, run.backgroundBlue, run.backgroundAlpha]) {
            if (!CjguiComposableUiEffectValidation.isFinite(component) || component < 0.0 || component > 1.0) {
                return Some("text_style_run_color_invalid")
            }
        }
    }
    return None
}

class CjguiDecodedTextRuns {
    let runs: Array<CjguiComposableUiTextStyleRun>
    let reason: String
    init(runs: Array<CjguiComposableUiTextStyleRun>, reason!: String = "") {
        this.runs = runs
        this.reason = reason
    }
}

// One versioned, bounded transport onto the existing run declaration. Both
// catalog admission and construction use this parser and the same validator.
func cjguiDecodeGeneratedTextRuns(value: String, wire: String, base: CjguiComposableUiStyle,
    resolve: (String, Int64) -> ?CjguiFontResourceReference): CjguiDecodedTextRuns {
    let empty = Array<CjguiComposableUiTextStyleRun>()
    if (wire.isEmpty()) { return CjguiDecodedTextRuns(empty) }
    if (wire.size > 16384 || value.size > 65536) {
        return CjguiDecodedTextRuns(empty, reason: "text_runs_budget_exceeded")
    }
    for (byte in wire.toArray()) {
        if (byte <= 32 || byte >= 127) { return CjguiDecodedTextRuns(empty, reason: "text_runs_encoding_invalid") }
    }
    if (wire.startsWith(";") || wire.endsWith(";") || wire.contains(";;") || wire.contains("::")) {
        return CjguiDecodedTextRuns(empty, reason: "text_runs_encoding_invalid")
    }
    let items = wire.split(";")
    if (items.size > 64) { return CjguiDecodedTextRuns(empty, reason: "text_runs_count_exceeded") }
    let decoded = ArrayList<CjguiComposableUiTextStyleRun>()
    for (item in items) {
        if (item.startsWith(":") || item.endsWith(":")) { return CjguiDecodedTextRuns(empty, reason: "text_runs_encoding_invalid") }
        let parts = item.split(":")
        if (parts.size != 7) { return CjguiDecodedTextRuns(empty, reason: "text_runs_encoding_invalid") }
        let start = Int64.tryParse(parts[0])
        let end = Int64.tryParse(parts[1])
        let size = Float64.tryParse(parts[2])
        let weight = Int64.tryParse(parts[3])
        let version = Int64.tryParse(parts[5])
        if (start.isNone() || end.isNone() || size.isNone() || weight.isNone() || version.isNone() ||
            !CjguiComposableUiEffectValidation.isFinite(size.getOrThrow()) || size.getOrThrow() < 0.0 ||
            size.getOrThrow() > 144.0 || weight.getOrThrow() < -1 || weight.getOrThrow() > 1000) {
            return CjguiDecodedTextRuns(empty, reason: "text_runs_attribute_invalid")
        }
        var family = base.fontFamily
        if (parts[4] != "base" || version.getOrThrow() != 0) {
            if (version.getOrThrow() < 1 || version.getOrThrow() > 1000000) {
                return CjguiDecodedTextRuns(empty, reason: "text_runs_font_reference_invalid")
            }
            let resource = resolve(parts[4], version.getOrThrow())
            if (resource.isNone()) {
                return CjguiDecodedTextRuns(empty, reason: "text_runs_font_unavailable_or_version_mismatch")
            }
            family = resource.getOrThrow().fontFamily
        }
        let color = if (parts[6] == "inherit") { Some(base.textColor) }
            else { cjguiComposableUiParseColorToken(parts[6]) }
        if (color.isNone()) { return CjguiDecodedTextRuns(empty, reason: "text_runs_color_invalid") }
        let c = color.getOrThrow()
        decoded.add(CjguiComposableUiTextStyleRun(start.getOrThrow(), end.getOrThrow(),
            if (size.getOrThrow() == 0.0) { base.fontSize } else { size.getOrThrow() },
            if (weight.getOrThrow() == -1) { base.fontWeight } else { weight.getOrThrow() },
            family, c.red, c.green, c.blue, c.alpha))
    }
    let runs = decoded.toArray()
    if (let Some(issue) <- cjguiOrdinaryTextRunsRejection(value, runs)) {
        return CjguiDecodedTextRuns(empty, reason: issue)
    }
    return CjguiDecodedTextRuns(runs)
}
