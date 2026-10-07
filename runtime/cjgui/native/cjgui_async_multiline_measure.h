#ifndef CJGUI_ASYNC_MULTILINE_MEASURE_H
#define CJGUI_ASYNC_MULTILINE_MEASURE_H

#import <AppKit/AppKit.h>
#include <stddef.h>
#include <stdint.h>

typedef uint64_t CjguiAsyncMultilineMeasureHandle;

// Private scalar ABI; no TextKit object crosses the worker boundary.
typedef struct {
    uint32_t width;
    uint32_t height;
    uint32_t lineHeight;
    uint32_t baseline;
} CjguiAsyncTextMetrics;

typedef enum {
    CJGUI_ASYNC_MEASURE_STARTED = 0,
    CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY = 1,
    CJGUI_ASYNC_MEASURE_PENDING = 2,
    CJGUI_ASYNC_MEASURE_READY = 3,
    CJGUI_ASYNC_MEASURE_FAILED = 4,
    CJGUI_ASYNC_MEASURE_CANCELLED = 5,
    CJGUI_ASYNC_MEASURE_STALE_HANDLE = 6,
    CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT = 7,
    CJGUI_ASYNC_MEASURE_NOT_READY = 8
} CjguiAsyncMultilineMeasureStatus;

typedef enum {
    CJGUI_ASYNC_MEASURE_FAILURE_NONE = 0,
    CJGUI_ASYNC_MEASURE_FAILURE_INVALID_UTF8 = 1,
    CJGUI_ASYNC_MEASURE_FAILURE_INCOMPLETE_LAYOUT = 2,
    CJGUI_ASYNC_MEASURE_FAILURE_INVALID_HEIGHT = 3,
    CJGUI_ASYNC_MEASURE_FAILURE_TEXTKIT_EXCEPTION = 4
} CjguiAsyncMultilineMeasureFailure;

typedef enum {
    CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED = 0,
    CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED = 1
} CjguiAsyncMultilineMeasureReleaseDisposition;

// The caller resolves the font on its owning thread. This function copies the
// UTF-8 bytes and retains a copied, immutable font snapshot before returning.
CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasureBegin(
    const uint8_t *utf8Bytes, size_t byteLength, NSFont *fontSnapshot,
    double contentWidth, CjguiAsyncMultilineMeasureHandle *outHandle);

// Ordinary TEXT uses bounded serial lanes with generation-safe release.
// Small ordinary inputs have isolated queue and admission capacity. A zero
// maximumWidth preserves the synchronous API's unconstrained width.
CjguiAsyncMultilineMeasureStatus CjguiAsyncTextMetricsBegin(
    const uint8_t *utf8Bytes, size_t byteLength, NSFont *fontSnapshot,
    double maximumWidth, CjguiAsyncMultilineMeasureHandle *outHandle);
CjguiAsyncMultilineMeasureStatus CjguiAsyncTextMetricsPoll(
    CjguiAsyncMultilineMeasureHandle handle, CjguiAsyncTextMetrics *outMetrics,
    CjguiAsyncMultilineMeasureFailure *outFailure);

// Poll never waits. Ready is stable until the caller releases the handle.
CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasurePoll(
    CjguiAsyncMultilineMeasureHandle handle, uint32_t *outHeight,
    CjguiAsyncMultilineMeasureFailure *outFailure);

// Abandoned revokes publication immediately. Running work retains its slot and
// copied inputs until the active layout call and worker autorelease pool return.
// Repeating release for the same live generation is idempotent.
CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasureRelease(
    CjguiAsyncMultilineMeasureHandle handle,
    CjguiAsyncMultilineMeasureReleaseDisposition disposition);

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
typedef struct {
    uint32_t occupiedSlots;
    uint32_t genericSlots;
    uint32_t smallTextSlots;
    size_t reservedInputBytes;
    size_t genericReservedInputBytes;
    size_t smallTextReservedInputBytes;
    uint64_t preparedInputCopies;
    size_t preparedInputBytes;
    uint64_t preparedFontCopies;
    uint64_t preparedJobs;
    uint64_t layoutJobsStarted;
    uint64_t layoutJobsCompleted;
} CjguiAsyncMultilineMeasureTestStats;

void CjguiAsyncMultilineMeasureTestCloseWorkerGate(void);
int CjguiAsyncMultilineMeasureTestWaitForWorkerGate(uint32_t timeoutMs);
uint64_t CjguiAsyncMultilineMeasureTestWorkerGateHandle(void);
void CjguiAsyncMultilineMeasureTestOpenWorkerGate(void);
void CjguiAsyncMultilineMeasureTestClosePrepareGate(void);
int CjguiAsyncMultilineMeasureTestWaitForPrepareGate(uint32_t timeoutMs);
uint64_t CjguiAsyncMultilineMeasureTestPreparingHandle(void);
int CjguiAsyncMultilineMeasureTestCancelPreparing(
    CjguiAsyncMultilineMeasureHandle handle);
void CjguiAsyncMultilineMeasureTestOpenPrepareGate(void);
void CjguiAsyncMultilineMeasureTestFailNextPrepareAfterCopy(void);
uint64_t CjguiAsyncMultilineMeasureTestServiceStartNs(
    CjguiAsyncMultilineMeasureHandle handle);
void CjguiAsyncMultilineMeasureTestGetStats(CjguiAsyncMultilineMeasureTestStats *outStats);
#endif

#endif
