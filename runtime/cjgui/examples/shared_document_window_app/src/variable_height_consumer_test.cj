package cjgui_shared_document_window_app

import cjgui.*
import std.unittest.*
import std.unittest.testmacro.*

@Test
func longDocumentPreviewIsBoundedBeforeLayoutMeasurement(): Unit {
    let longBody = "🙂" * 10000
    let result = cjguiExperimentalDocumentPreview(longBody)
    let preview = result.preview
    @Assert(result.isAvailable, true)
    @Assert(result.isTruncated, true)
    @Assert(result.reason, "ok")
    @Assert(result.stability, "experimental")
    @Assert(result.platform, "macOS")
    @Assert(preview.size < longBody.size, true)
    @Assert(preview.size <= 512, true)
    @Assert(preview.endsWith("…"), true)
}

@Test
func previewDropsComposedSequencesAtExactBudgetBoundaries(): Unit {
    let combining = "a" * 506 + "é"
    let zwj = "a" * 159 + "👩‍💻"
    let zwjAtByteBudget = "a" * 500 + "👩‍💻"
    let hangul = "a" * 505 + "한"
    let indic = "a" * 505 + "\u{0915}\u{094D}\u{200D}\u{0937}"
    let combiningPreview = cjguiExperimentalDocumentPreview(combining).preview
    let zwjPreview = cjguiExperimentalDocumentPreview(zwj).preview
    let zwjBudgetPreview = cjguiExperimentalDocumentPreview(zwjAtByteBudget).preview
    let hangulPreview = cjguiExperimentalDocumentPreview(hangul).preview
    let indicPreview = cjguiExperimentalDocumentPreview(indic).preview
    @Assert(combiningPreview.size <= 512, true)
    @Assert(zwjPreview.size <= 512, true)
    @Assert(zwjBudgetPreview.size <= 512, true)
    @Assert(hangulPreview.size <= 512, true)
    @Assert(indicPreview.size <= 512, true)
    @Assert(combiningPreview.endsWith("é…"), false)
    @Assert(zwjPreview.endsWith("👩‍…"), false)
    @Assert(zwjPreview.endsWith("👩…"), false)
    @Assert(zwjPreview.endsWith("👩‍💻"), true)
    @Assert(zwjBudgetPreview.endsWith("…"), true)
    @Assert(zwjBudgetPreview.endsWith("👩…"), false)
    @Assert(zwjBudgetPreview.endsWith("👩‍…"), false)
    @Assert(hangulPreview.endsWith("ᄒ…"), false)
    @Assert(indicPreview.endsWith("क…"), false)
}

@Test
func previewDoesNotAccumulateAnOverlongComposedCluster(): Unit {
    let hugeCluster = "e" + "́" * 1000
    let preview = cjguiExperimentalDocumentPreview(hugeCluster).preview
    @Assert(preview.size <= 512, true)
    @Assert(preview, "…")
}

@Test
func previewMarksAndDropsAnIncompleteScanWindowTail(): Unit {
    // The combining mark would fall outside the scalar-safe 2 KiB window.
    // The public wrapper must not expose the base without its mark as a
    // partial composed sequence; it conservatively emits an ellipsis.
    let result = cjguiExperimentalDocumentPreview("a" * 2047 + "é")
    @Assert(result.isAvailable, true)
    @Assert(result.isTruncated, true)
    @Assert(result.preview.size <= 512, true)
    @Assert(result.preview.endsWith("e…"), false)
    @Assert(result.preview.endsWith("…"), true)
}

@Test
func previewReservesItsMarkerWithoutSplittingAComposedSequence(): Unit {
    // 157 three-byte CJK clusters + this 39-byte ZWJ cluster reaches 510
    // bytes. The following ASCII bytes require a marker. Reserving the
    // marker after an initial 512-byte native prefix would otherwise expose
    // a dangling `woman + ZWJ` scalar sequence.
    let longZwJCluster = "👩‍👩‍👩‍👩‍👩‍👩"
    let result = cjguiExperimentalDocumentPreview("中" * 157 + longZwJCluster + "xxx")
    @Assert(result.isAvailable, true)
    @Assert(result.isTruncated, true)
    @Assert(result.preview.size <= 512, true)
    @Assert(result.preview.endsWith("👩…"), false)
    @Assert(result.preview.endsWith("👩‍…"), false)
    @Assert(result.preview.endsWith("…"), true)
}
