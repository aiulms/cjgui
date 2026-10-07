#import "cjgui_async_multiline_measure.h"
#import "cjgui_composable_font_snapshot.h"

#include <dispatch/dispatch.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

static uint64_t CjguiScalarBridgeNow(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

// The managed candidate calls this on the owning AppKit thread. It snapshots
// the same font choice used by the painter, then Begin copies the bytes/font
// into a private TextKit graph. Poll and Release use the measure module's C ABI.
static int32_t CjguiAsyncComposableScalarBegin(
    const char *utf8, uint64_t byteLength, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, uint32_t contentWidth,
    BOOL ordinaryText, uint64_t *outHandle) {
    if (!outHandle || (byteLength > 0 && !utf8) || byteLength > SIZE_MAX ||
        !isfinite(fontSize) || fontSize <= 0.0 || (!ordinaryText && contentWidth == 0)) {
        if (outHandle) *outHandle = 0;
        return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    }
    // The Cangjie owner thread can differ from AppKit's main thread. Only
    // immutable font selection crosses this dispatch; layout itself is the
    // bounded private worker job and never holds the main queue.
    __block NSFont *font = nil;
    uint64_t enteredNs = CjguiScalarBridgeNow();
    __block uint64_t mainEnterNs = 0, mainExitNs = 0;
    void (^snapshot)(void) = ^{
        mainEnterNs = CjguiScalarBridgeNow();
        font = CjguiComposableFontSnapshotForStyle(fontSize, fontWeight, fontFamily);
        mainExitNs = CjguiScalarBridgeNow();
    };
    if ([NSThread isMainThread]) {
        snapshot();
    } else {
        dispatch_sync(dispatch_get_main_queue(), snapshot);
    }
    int32_t status = ordinaryText
        ? CjguiAsyncTextMetricsBegin((const uint8_t *)utf8, (size_t)byteLength, font, (double)contentWidth, outHandle)
        : CjguiAsyncMultilineMeasureBegin((const uint8_t *)utf8, (size_t)byteLength, font, (double)contentWidth, outHandle);
    if (getenv("CJGUI_TEXT_PREPARE_TRACE")) {
        fprintf(stderr, "CJGUI_SCALAR_ADMIT handle=%llu kind=%s bytes=%llu width=%u status=%d entered_ns=%llu returned_ns=%llu main_service_ns=%llu main_wait_ns=%llu\n",
            (unsigned long long)*outHandle, ordinaryText ? "text" : "multiline",
            (unsigned long long)byteLength, contentWidth, status,
            (unsigned long long)enteredNs, (unsigned long long)CjguiScalarBridgeNow(),
            (unsigned long long)(mainExitNs - mainEnterNs), (unsigned long long)(mainEnterNs - enteredNs));
    }
    return status;
}

int32_t cjgui_async_composable_multiline_begin(
    const char *utf8, uint64_t byteLength, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, uint32_t contentWidth, uint64_t *outHandle) {
    return CjguiAsyncComposableScalarBegin(utf8, byteLength, fontSize, fontWeight,
        fontFamily, contentWidth, NO, outHandle);
}

int32_t cjgui_async_composable_text_metrics_begin(
    const char *utf8, uint64_t byteLength, double fontSize,
    uint32_t fontWeight, uint32_t fontFamily, uint32_t maximumWidth, uint64_t *outHandle) {
    return CjguiAsyncComposableScalarBegin(utf8, byteLength, fontSize, fontWeight,
        fontFamily, maximumWidth, YES, outHandle);
}
