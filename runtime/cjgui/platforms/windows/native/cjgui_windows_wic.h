#ifndef CJGUI_WINDOWS_WIC_H
#define CJGUI_WINDOWS_WIC_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum CjguiWindowsWicStatus {
    CJGUI_WINDOWS_WIC_OK = 0,
    CJGUI_WINDOWS_WIC_INVALID_PNG = 1,
    CJGUI_WINDOWS_WIC_DIMENSION_EXCEEDED = 2,
    CJGUI_WINDOWS_WIC_BUDGET_EXCEEDED = 3,
    CJGUI_WINDOWS_WIC_OUTPUT_TOO_SMALL = 4,
    CJGUI_WINDOWS_WIC_DECODE_FAILED = 5
} CjguiWindowsWicStatus;

/*
 * Decode one PNG frame to tightly packed straight-alpha RGBA8 using the
 * Windows Imaging Component. IHDR dimensions and caller budgets are checked
 * before a WIC decoder or pixel buffer is created. The caller owns output and
 * keeps both input and output buffers alive for this synchronous call only.
 */
int32_t cjgui_windows_wic_decode_png_rgba8(
    const uint8_t *png_bytes,
    uint64_t png_length,
    uint64_t maximum_encoded_bytes,
    uint32_t maximum_width,
    uint32_t maximum_height,
    uint64_t maximum_decoded_bytes,
    uint8_t *output_rgba,
    uint64_t output_capacity,
    uint32_t *output_width,
    uint32_t *output_height,
    uint64_t *output_bytes);

#ifdef __cplusplus
}
#endif

#endif
