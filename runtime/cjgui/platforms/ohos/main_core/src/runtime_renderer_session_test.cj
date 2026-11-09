package cjgui

import std.unittest.*
import std.unittest.testmacro.*

// Keep the historical internal-ABI boundary probe in the runtime package,
// never in an application consumer. This preserves the exact 2046-byte
// incomplete-window behavior while the public sample remains FFI-free.
foreign func cjgui_internal_renderer_composed_prefix_utf8_length(
    utf8: CString, inputBytes: UInt64, maxOutputBytes: UInt64,
    maxClusters: UInt64, inputComplete: UInt8, outPrefixBytes: CPointer<UInt64>
): Int32

@Test
func internalComposedPrefixDropsIncompleteWindowTail(): Unit {
    let input = "a" * 2046 + "Z"
    var prefixBytes: UInt64 = 0u64
    var status: Int32 = -1
    unsafe {
        let nativeInput = LibC.mallocCString(input)
        try (inputResource = nativeInput.asResource()) {
            status = cjgui_internal_renderer_composed_prefix_utf8_length(
                inputResource.value, UInt64(input.size), 2048u64, 2048u64, 0u8, inout prefixBytes
            )
        }
    }
    @Assert(status, 0)
    @Assert(prefixBytes, 2046u64)
}

@Test
func experimentalDocumentPreviewRejectsInvalidBounds(): Unit {
    let result = cjguiExperimentalDocumentPreview("text", maxBytes: 3, maxClusters: 160)
    @Assert(result.isAvailable, false)
    @Assert(result.reason, "invalid_argument")
}
