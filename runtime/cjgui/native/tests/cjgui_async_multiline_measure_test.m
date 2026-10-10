#define CJGUI_ASYNC_MULTILINE_MEASURE_TESTING 1
#import "../cjgui_async_multiline_measure.h"

#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <CoreFoundation/CoreFoundation.h>

#define CHECK(expr, label) do { \
    if (!(expr)) { \
        fprintf(stderr, "ASYNC_MULTILINE_MEASURE FAIL: %s\n", label); \
        return 1; \
    } \
} while (0)

static uint64_t monotonicNs(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

static NSString *strictString(const uint8_t *bytes, size_t length) {
    return [[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding];
}

static uint32_t mainThreadHeight(NSString *value, NSFont *font, double width, BOOL *complete) {
    @autoreleasepool {
        NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
        paragraph.lineBreakMode = NSLineBreakByWordWrapping;
        NSTextStorage *storage = [[NSTextStorage alloc] initWithString:value
            attributes:@{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph}];
        NSLayoutManager *layout = [NSLayoutManager new];
        layout.backgroundLayoutEnabled = NO;
        NSTextContainer *container = [[NSTextContainer alloc]
            initWithSize:NSMakeSize(width, CGFLOAT_MAX / 4.0)];
        container.widthTracksTextView = NO;
        container.lineFragmentPadding = 0.0;
        [storage addLayoutManager:layout];
        [layout addTextContainer:container];
        [layout ensureLayoutForTextContainer:container];
        *complete = value.length == 0 || layout.firstUnlaidCharacterIndex >= value.length;
        CGFloat lineHeight = MAX(1.0, font.ascender - font.descender + font.leading);
        CGFloat height = MAX(lineHeight, NSMaxY([layout usedRectForTextContainer:container]));
        if (layout.extraLineFragmentTextContainer == container &&
            !NSIsEmptyRect(layout.extraLineFragmentRect)) {
            height = MAX(height, NSMaxY(layout.extraLineFragmentRect));
        }
        return isfinite(height) && height >= 0.0 && height <= UINT32_MAX
            ? (uint32_t)ceil(height) : 0;
    }
}

static CjguiAsyncTextMetrics mainThreadMetrics(NSString *value, NSFont *font, double width) {
    CjguiAsyncTextMetrics metrics = {0};
    @autoreleasepool {
        NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
        paragraph.lineBreakMode = NSLineBreakByWordWrapping;
        NSRect bounds = [value boundingRectWithSize:NSMakeSize(width, CGFLOAT_MAX / 4.0)
            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
            attributes:@{NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph}];
        CGFloat lineHeight = MAX(1.0, font.ascender - font.descender + font.leading);
        metrics.width = (uint32_t)MIN(UINT32_MAX, MAX(0.0, ceil(bounds.size.width)));
        metrics.height = (uint32_t)MIN(UINT32_MAX,
            MAX(lineHeight, ceil(bounds.size.height)));
        metrics.lineHeight = (uint32_t)MIN(UINT32_MAX, ceil(lineHeight));
        metrics.baseline = (uint32_t)MIN(UINT32_MAX, MAX(0.0, ceil(font.ascender)));
    }
    return metrics;
}

static BOOL textMetricsEqual(CjguiAsyncTextMetrics a, CjguiAsyncTextMetrics b) {
    return a.width == b.width && a.height == b.height &&
        a.lineHeight == b.lineHeight && a.baseline == b.baseline;
}

static int pollTextMetricsReady(CjguiAsyncMultilineMeasureHandle handle,
                                CjguiAsyncTextMetrics *metrics,
                                CjguiAsyncMultilineMeasureFailure *failure,
                                uint32_t timeoutMs);

typedef struct {
    const uint8_t *bytes;
    size_t length;
    __strong NSFont *font;
    CjguiAsyncMultilineMeasureHandle handle;
    CjguiAsyncMultilineMeasureStatus status;
} BeginThreadArgs;

static void *beginTextMetricsOnThread(void *rawArgs) {
    BeginThreadArgs *args = rawArgs;
    @autoreleasepool {
        args->status = CjguiAsyncTextMetricsBegin(args->bytes, args->length,
            args->font, 320.0, &args->handle);
    }
    return NULL;
}

static NSString *repeatedTextLines(NSString *body, NSString *separator,
                                   NSUInteger count, BOOL trailingSeparator) {
    NSMutableString *value = [NSMutableString string];
    for (NSUInteger i = 0; i < count; i++) {
        [value appendString:body];
        if (i + 1 < count || trailingSeparator) [value appendString:separator];
    }
    return value;
}

static int verifyTextMetricsOracle(NSString *value, NSFont *font, double width,
                                   const char *label) {
    CjguiAsyncTextMetrics expected = mainThreadMetrics(value, font, width);
    NSData *bytes = [value dataUsingEncoding:NSUTF8StringEncoding];
    CjguiAsyncTextMetrics actual = {0};
    CjguiAsyncMultilineMeasureFailure failure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    CjguiAsyncMultilineMeasureHandle handle = 0;
    if (CjguiAsyncTextMetricsBegin(bytes.bytes, bytes.length, font, width, &handle) !=
        CJGUI_ASYNC_MEASURE_STARTED) {
        fprintf(stderr, "TEXT_METRICS_MATRIX FAIL label=%s begin\n", label);
        return 0;
    }
    if (!pollTextMetricsReady(handle, &actual, &failure, 10000)) {
        fprintf(stderr, "TEXT_METRICS_MATRIX FAIL label=%s status/failure=%d/%d\n",
            label, CjguiAsyncTextMetricsPoll(handle, &actual, &failure), failure);
        CjguiAsyncMultilineMeasureRelease(handle, CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED);
        return 0;
    }
    BOOL matches = textMetricsEqual(expected, actual);
    if (!matches) {
        fprintf(stderr,
            "TEXT_METRICS_MATRIX RED label=%s bytes=%lu utf16=%lu width=%.4g font=%.4g expected=%u,%u,%u,%u actual=%u,%u,%u,%u\n",
            label, (unsigned long)bytes.length, (unsigned long)value.length, width,
            font.pointSize, expected.width, expected.height, expected.lineHeight,
            expected.baseline, actual.width, actual.height, actual.lineHeight, actual.baseline);
    }
    CjguiAsyncMultilineMeasureRelease(handle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED);
    return matches ? 1 : 0;
}

static int pollReady(CjguiAsyncMultilineMeasureHandle handle, uint32_t *height,
                     CjguiAsyncMultilineMeasureFailure *failure, uint32_t timeoutMs) {
    uint64_t deadline = monotonicNs() + (uint64_t)timeoutMs * 1000000ull;
    for (;;) {
        CjguiAsyncMultilineMeasureStatus status =
            CjguiAsyncMultilineMeasurePoll(handle, height, failure);
        if (status == CJGUI_ASYNC_MEASURE_READY) return 1;
        if (status != CJGUI_ASYNC_MEASURE_PENDING || monotonicNs() >= deadline) return 0;
        struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
        nanosleep(&pause, NULL);
    }
}

static int pollTextMetricsReady(CjguiAsyncMultilineMeasureHandle handle,
                                CjguiAsyncTextMetrics *metrics,
                                CjguiAsyncMultilineMeasureFailure *failure,
                                uint32_t timeoutMs) {
    uint64_t deadline = monotonicNs() + (uint64_t)timeoutMs * 1000000ull;
    for (;;) {
        CjguiAsyncMultilineMeasureStatus status =
            CjguiAsyncTextMetricsPoll(handle, metrics, failure);
        if (status == CJGUI_ASYNC_MEASURE_READY) return 1;
        if (status != CJGUI_ASYNC_MEASURE_PENDING) {
            fprintf(stderr, "TEXT_METRICS poll_terminal status=%d failure=%d\n", status, *failure);
            return 0;
        }
        if (monotonicNs() >= deadline) {
            fprintf(stderr, "TEXT_METRICS poll_timeout status=%d failure=%d\n", status, *failure);
            return 0;
        }
        struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
        nanosleep(&pause, NULL);
    }
}

static void getStats(CjguiAsyncMultilineMeasureTestStats *stats) {
    memset(stats, 0, sizeof(*stats));
    CjguiAsyncMultilineMeasureTestGetStats(stats);
}

static int runUnicode72KiBWorkerDiagnostic(NSFont *font) {
    NSMutableString *unicode = [NSMutableString stringWithCapacity:120000];
    for (NSUInteger i = 0; i < 2048; i++) [unicode appendString:@"中🙂e\u0301👩‍💻 אבג\tline\r\n"];
    NSData *bytes = [unicode dataUsingEncoding:NSUTF8StringEncoding];
    CjguiAsyncMultilineMeasureTestStats before = {0}, after = {0};
    getStats(&before);
    CjguiAsyncMultilineMeasureHandle handle = 0;
    CjguiAsyncMultilineMeasureStatus begin = CjguiAsyncTextMetricsBegin(
        bytes.bytes, bytes.length, font, 320.0, &handle);
    fprintf(stderr, "TEXT_METRICS_DIAG begin=%d utf8_bytes=%lu utf16_units=%lu main=%d\n",
        (int)begin, (unsigned long)bytes.length, (unsigned long)unicode.length,
        [NSThread isMainThread] ? 1 : 0);
    if (begin != CJGUI_ASYNC_MEASURE_STARTED) return 2;

    CjguiAsyncTextMetrics metrics = {0};
    CjguiAsyncMultilineMeasureFailure failure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    CjguiAsyncMultilineMeasureStatus current = CJGUI_ASYNC_MEASURE_PENDING;
    uint64_t deadline = monotonicNs() + 15000000000ull;
    do {
        current = CjguiAsyncTextMetricsPoll(handle, &metrics, &failure);
        if (current != CJGUI_ASYNC_MEASURE_PENDING) break;
        struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
        nanosleep(&pause, NULL);
    } while (monotonicNs() < deadline);
    getStats(&after);
    fprintf(stderr, "TEXT_METRICS_DIAG phase=nanosleep status=%d failure=%d started_delta=%llu completed_delta=%llu\n",
        (int)current, (int)failure,
        (unsigned long long)(after.layoutJobsStarted - before.layoutJobsStarted),
        (unsigned long long)(after.layoutJobsCompleted - before.layoutJobsCompleted));

    if (current == CJGUI_ASYNC_MEASURE_PENDING) {
        deadline = monotonicNs() + 5000000000ull;
        do {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.001, true);
            current = CjguiAsyncTextMetricsPoll(handle, &metrics, &failure);
            if (current != CJGUI_ASYNC_MEASURE_PENDING) break;
        } while (monotonicNs() < deadline);
        getStats(&after);
        fprintf(stderr, "TEXT_METRICS_DIAG phase=main_runloop status=%d failure=%d started_delta=%llu completed_delta=%llu\n",
            (int)current, (int)failure,
            (unsigned long long)(after.layoutJobsStarted - before.layoutJobsStarted),
            (unsigned long long)(after.layoutJobsCompleted - before.layoutJobsCompleted));
    }

    CjguiAsyncMultilineMeasureStatus release = current == CJGUI_ASYNC_MEASURE_READY
        ? CjguiAsyncMultilineMeasureRelease(handle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED)
        : CjguiAsyncMultilineMeasureRelease(handle, CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED);
    fprintf(stderr, "TEXT_METRICS_DIAG terminal_status=%d release=%d\n", (int)current, (int)release);
    return 0;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSFont *font = [NSFont systemFontOfSize:13.0];
        CHECK(font != nil, "font snapshot exists");
        if (argc > 1 && strcmp(argv[1], "--unicode-72k-worker-diag") == 0)
            return runUnicode72KiBWorkerDiagnostic(font);

        CjguiAsyncMultilineMeasureTestCloseWorkerGate();
        NSMutableData *ascii = [NSMutableData dataWithLength:16384];
        memset(ascii.mutableBytes, 'a', ascii.length);
        NSString *asciiString = strictString(ascii.bytes, ascii.length);
        BOOL asciiComplete = NO;
        uint32_t asciiExpected = mainThreadHeight(asciiString, font, 320.0, &asciiComplete);
        CHECK(asciiComplete && asciiExpected > 0, "ASCII main-thread oracle complete");
        CjguiAsyncMultilineMeasureHandle asciiHandle = 0;
        CHECK(CjguiAsyncMultilineMeasureBegin(ascii.bytes, ascii.length, font, 320.0,
            &asciiHandle) == CJGUI_ASYNC_MEASURE_STARTED, "16 KiB begin owns input");
        CHECK(CjguiAsyncMultilineMeasureTestWaitForWorkerGate(3000), "worker reaches deterministic gate");
        uint32_t height = 0;
        CjguiAsyncMultilineMeasureFailure failure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
        CHECK(CjguiAsyncMultilineMeasurePoll(asciiHandle, &height, &failure) == CJGUI_ASYNC_MEASURE_PENDING,
            "first poll is nonblocking pending");
        memset(ascii.mutableBytes, 'z', ascii.length);
        CjguiAsyncMultilineMeasureTestOpenWorkerGate();
        CHECK(pollReady(asciiHandle, &height, &failure, 10000), "ASCII worker completes");
        CHECK(height == asciiExpected, "16 KiB copied input has exact main-thread height");
        for (int i = 0; i < 4; i++) {
            uint32_t repeatedHeight = 0;
            CjguiAsyncMultilineMeasureFailure repeatedFailure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
            CHECK(CjguiAsyncMultilineMeasurePoll(asciiHandle, &repeatedHeight, &repeatedFailure) ==
                    CJGUI_ASYNC_MEASURE_READY && repeatedHeight == height &&
                    repeatedFailure == CJGUI_ASYNC_MEASURE_FAILURE_NONE,
                "repeated ready poll is stable");
        }
        CHECK(CjguiAsyncMultilineMeasureRelease(asciiHandle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) ==
                CJGUI_ASYNC_MEASURE_READY, "consume ready result");
        CHECK(CjguiAsyncMultilineMeasureRelease(asciiHandle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) ==
                CJGUI_ASYNC_MEASURE_READY, "same-generation release is idempotent");

        // Keep byte count, font and width fixed while changing only paragraph
        // structure. This checks that the worker returns real TextKit geometry
        // for both one wrapped paragraph and thousands of explicit lines.
        NSMutableData *newlineBytes = [NSMutableData dataWithLength:16384];
        memset(newlineBytes.mutableBytes, 'a', newlineBytes.length);
        for (NSUInteger i = 1; i < newlineBytes.length; i += 2)
            ((uint8_t *)newlineBytes.mutableBytes)[i] = '\n';
        NSString *newlineString = strictString(newlineBytes.bytes, newlineBytes.length);
        BOOL newlineComplete = NO;
        uint32_t newlineExpected = mainThreadHeight(newlineString, font, 320.0, &newlineComplete);
        CHECK(newlineString.length == asciiString.length && newlineComplete && newlineExpected > asciiExpected,
            "same-byte newline control has distinct complete main-thread height");
        CjguiAsyncMultilineMeasureHandle newlineHandle = 0;
        CHECK(CjguiAsyncMultilineMeasureBegin(newlineBytes.bytes, newlineBytes.length, font, 320.0,
            &newlineHandle) == CJGUI_ASYNC_MEASURE_STARTED, "same-byte newline control begins");
        CHECK(pollReady(newlineHandle, &height, &failure, 10000), "newline control worker completes");
        CHECK(height == newlineExpected, "newline worker height exactly matches main-thread oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(newlineHandle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) ==
                CJGUI_ASYNC_MEASURE_READY, "consume newline control result");

        // Ordinary TEXT must return all four scalar fields from the same
        // private worker and exactly match the former synchronous oracle.
        CjguiAsyncTextMetrics asciiMetricExpected = mainThreadMetrics(asciiString, font, 320.0);
        NSData *asciiMetricsBytes = [asciiString dataUsingEncoding:NSUTF8StringEncoding];
        CjguiAsyncTextMetrics asciiMetrics = {0};
        CjguiAsyncMultilineMeasureHandle asciiMetricsHandle = 0;
        CHECK(asciiMetricsBytes.length == 16384, "ordinary TEXT oracle/input bytes agree");
        CHECK(CjguiAsyncTextMetricsBegin(asciiMetricsBytes.bytes, asciiMetricsBytes.length, font, 320.0,
            &asciiMetricsHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "ordinary TEXT metrics admits the same 16 KiB paragraph");
        CHECK(pollTextMetricsReady(asciiMetricsHandle, &asciiMetrics, &failure, 10000),
            "ordinary TEXT metrics worker completes");
        BOOL asciiMetricMatch = asciiMetrics.width == asciiMetricExpected.width &&
            asciiMetrics.height == asciiMetricExpected.height &&
            asciiMetrics.lineHeight == asciiMetricExpected.lineHeight &&
            asciiMetrics.baseline == asciiMetricExpected.baseline;
        if (!asciiMetricMatch) {
            fprintf(stderr, "TEXT_METRICS ascii expected=%u,%u,%u,%u actual=%u,%u,%u,%u\n",
                asciiMetricExpected.width, asciiMetricExpected.height,
                asciiMetricExpected.lineHeight, asciiMetricExpected.baseline,
                asciiMetrics.width, asciiMetrics.height, asciiMetrics.lineHeight,
                asciiMetrics.baseline);
        }
        CHECK(asciiMetricMatch, "all ordinary TEXT scalars match synchronous paragraph oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(asciiMetricsHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "consume ordinary TEXT result");

        CjguiAsyncTextMetrics asciiUnconstrainedExpected = mainThreadMetrics(
            asciiString, font, CGFLOAT_MAX / 4.0);
        CjguiAsyncTextMetrics asciiUnconstrainedMetrics = {0};
        CjguiAsyncMultilineMeasureHandle asciiUnconstrainedHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(asciiMetricsBytes.bytes, asciiMetricsBytes.length,
            font, 0.0, &asciiUnconstrainedHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "ordinary TEXT width zero retains legacy unconstrained semantics");
        CHECK(pollTextMetricsReady(asciiUnconstrainedHandle, &asciiUnconstrainedMetrics,
            &failure, 10000), "unconstrained ordinary TEXT worker completes");
        CHECK(asciiUnconstrainedMetrics.width == asciiUnconstrainedExpected.width &&
            asciiUnconstrainedMetrics.height == asciiUnconstrainedExpected.height &&
            asciiUnconstrainedMetrics.lineHeight == asciiUnconstrainedExpected.lineHeight &&
            asciiUnconstrainedMetrics.baseline == asciiUnconstrainedExpected.baseline,
            "unconstrained ordinary TEXT scalars match legacy oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(asciiUnconstrainedHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "consume unconstrained ordinary TEXT result");

        CjguiAsyncTextMetrics newlineMetricExpected = mainThreadMetrics(newlineString, font, 320.0);
        CjguiAsyncTextMetrics newlineMetrics = {0};
        CjguiAsyncMultilineMeasureHandle newlineMetricsHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(newlineBytes.bytes, newlineBytes.length, font, 320.0,
            &newlineMetricsHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "ordinary TEXT newline control shares scalar worker");
        CHECK(pollTextMetricsReady(newlineMetricsHandle, &newlineMetrics, &failure, 10000),
            "ordinary TEXT newline metrics worker completes");
        CHECK(newlineMetrics.width == newlineMetricExpected.width &&
            newlineMetrics.height == newlineMetricExpected.height &&
            newlineMetrics.lineHeight == newlineMetricExpected.lineHeight &&
            newlineMetrics.baseline == newlineMetricExpected.baseline,
            "all ordinary TEXT newline scalars match synchronous oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(newlineMetricsHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "consume ordinary TEXT newline result");

        NSMutableString *unicode = [NSMutableString stringWithCapacity:12000];
        for (NSUInteger i = 0; i < 2048; i++) [unicode appendString:@"中🙂e\u0301👩‍💻 אבג\tline\r\n"];
        NSData *unicodeBytes = [unicode dataUsingEncoding:NSUTF8StringEncoding];
        BOOL unicodeComplete = NO;
        uint32_t unicodeExpected = mainThreadHeight(unicode, font, 320.0, &unicodeComplete);
        CHECK(unicodeBytes.length > 16384 && unicode.length > 16384,
            "Unicode fixture includes multi-byte, combining, ZWJ, bidi, tab and CRLF");
        CHECK(unicodeComplete && unicodeExpected > 0, "Unicode main-thread oracle complete");
        CjguiAsyncMultilineMeasureHandle unicodeHandle = 0;
        CHECK(CjguiAsyncMultilineMeasureBegin(unicodeBytes.bytes, unicodeBytes.length, font, 320.0,
            &unicodeHandle) == CJGUI_ASYNC_MEASURE_STARTED, "Unicode begin");
        CHECK(pollReady(unicodeHandle, &height, &failure, 15000), "Unicode worker completes");
        CHECK(height == unicodeExpected, "Unicode worker height exactly matches main thread");
        CHECK(CjguiAsyncMultilineMeasureRelease(unicodeHandle, CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) ==
                CJGUI_ASYNC_MEASURE_READY, "consume Unicode result");
        NSMutableString *unicodeMetricsValue = [NSMutableString stringWithCapacity:5000];
        for (NSUInteger i = 0; i < 128; i++)
            [unicodeMetricsValue appendString:@"中🙂e\u0301👩‍💻 אבג\tline\r\n"];
        NSData *unicodeMetricsBytes = [unicodeMetricsValue dataUsingEncoding:NSUTF8StringEncoding];
        CHECK(unicodeMetricsBytes.length > 1024 && unicodeMetricsValue.length > 1024,
            "Unicode scalar fixture is large enough for long TEXT worker admission");
        CjguiAsyncTextMetrics unicodeMetricExpected = mainThreadMetrics(unicodeMetricsValue, font, 320.0);
        CjguiAsyncTextMetrics unicodeMetrics = {0};
        CjguiAsyncMultilineMeasureHandle unicodeMetricsHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(unicodeMetricsBytes.bytes, unicodeMetricsBytes.length, font, 320.0,
            &unicodeMetricsHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "ordinary TEXT admits Unicode scalar measurement");
        CHECK(pollTextMetricsReady(unicodeMetricsHandle, &unicodeMetrics, &failure, 15000),
            "ordinary TEXT Unicode worker completes");
        CHECK(unicodeMetrics.width == unicodeMetricExpected.width &&
            unicodeMetrics.height == unicodeMetricExpected.height &&
            unicodeMetrics.lineHeight == unicodeMetricExpected.lineHeight &&
            unicodeMetrics.baseline == unicodeMetricExpected.baseline,
            "Unicode ZWJ/bidi/combining metrics match synchronous oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(unicodeMetricsHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "consume ordinary TEXT Unicode metrics");

        // Cover Foundation paragraph controls through the complete-string
        // oracle after restoring single-call ordinary TEXT layout.
        struct SeparatorCase { const char *name; NSString *separator; };
        const struct SeparatorCase separators[] = {
            {"lf", @"\n"}, {"cr", @"\r"}, {"crlf", @"\r\n"},
            {"paragraph_separator", @"\u2029"}, {"line_separator", @"\u2028"}
        };
        for (NSUInteger sep = 0; sep < sizeof(separators) / sizeof(separators[0]); sep++) {
            NSString *value = repeatedTextLines(@"中🙂e\u0301👩‍💻 אבג\ttab",
                separators[sep].separator, 2, YES);
            CHECK(verifyTextMetricsOracle(value, font, 320.0, separators[sep].name),
                "complete ordinary string matches the scalar oracle for each paragraph separator");
        }
        const struct { const char *name; NSString *value; } ordinaryEdgeCases[] = {
            {"empty_text", @""}, {"crlf_only_text", @"\r\n"},
            {"trailing_empty_text", @"a\r\n"},
            {"consecutive_empty_text", @"a\r\n\r\nb"}
        };
        for (NSUInteger edge = 0; edge < sizeof(ordinaryEdgeCases) / sizeof(ordinaryEdgeCases[0]); edge++) {
            CHECK(verifyTextMetricsOracle(ordinaryEdgeCases[edge].value, font, 320.0,
                ordinaryEdgeCases[edge].name),
                "complete ordinary string preserves empty and trailing paragraphs");
        }

        // The generic lane is deterministically held at worker entry while a
        // protected small TEXT job completes on its independent serial lane.
        CjguiAsyncMultilineMeasureTestStats progressBefore = {0};
        CjguiAsyncMultilineMeasureTestStats stats = {0};
        getStats(&progressBefore);
        NSString *progressValue = repeatedTextLines(
            @"中🙂e\u0301👩‍💻 אבג\tline", @"\r\n", 512, YES);
        NSData *progressBytes = [progressValue dataUsingEncoding:NSUTF8StringEncoding];
        CjguiAsyncTextMetrics progressExpected = mainThreadMetrics(progressValue, font, 320.0);
        CjguiAsyncTextMetrics progressActual = {0};
        CjguiAsyncMultilineMeasureHandle progressHandle = 0;
        CjguiAsyncMultilineMeasureHandle shortHandle = 0;
        static const uint8_t shortProgressBytes[] = "fast ascii";
        CjguiAsyncTextMetrics shortExpected = mainThreadMetrics(
            strictString(shortProgressBytes, sizeof(shortProgressBytes) - 1), font, 320.0);
        CjguiAsyncTextMetrics shortActual = {0};
        CjguiAsyncMultilineMeasureTestCloseWorkerGate();
        CHECK(CjguiAsyncTextMetricsBegin(progressBytes.bytes, progressBytes.length,
            font, 320.0, &progressHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "large ordinary TEXT enters the generic lane");
        CHECK(CjguiAsyncMultilineMeasureTestWaitForWorkerGate(5000),
            "generic ordinary job is started and held before its opaque measurement");
        CHECK(CjguiAsyncMultilineMeasureTestWorkerGateHandle() == progressHandle,
            "worker gate identifies the generic ordinary handle");
        getStats(&stats);
        CHECK(stats.genericSlots == progressBefore.genericSlots + 1 &&
            stats.smallTextSlots == progressBefore.smallTextSlots &&
            stats.genericReservedInputBytes == progressBefore.genericReservedInputBytes +
                progressBytes.length &&
            stats.layoutJobsStarted == progressBefore.layoutJobsStarted + 1 &&
            stats.layoutJobsCompleted == progressBefore.layoutJobsCompleted,
            "generic lane retains its slot and full input reservation while gated");
        CHECK(CjguiAsyncTextMetricsBegin(shortProgressBytes,
            sizeof(shortProgressBytes) - 1, font, 320.0, &shortHandle) ==
                CJGUI_ASYNC_MEASURE_STARTED,
            "short ordinary TEXT is admitted on the protected lane");
        CHECK(pollTextMetricsReady(shortHandle, &shortActual, &failure, 5000),
            "short ordinary result reaches READY while generic lane is gated");
        CHECK(textMetricsEqual(shortActual, shortExpected),
            "short lane result matches complete NSString oracle");
        CHECK(CjguiAsyncTextMetricsPoll(progressHandle, &progressActual, &failure) ==
            CJGUI_ASYNC_MEASURE_PENDING,
            "generic ordinary result stays unpublished until its measurement runs");
        getStats(&stats);
        CHECK(stats.occupiedSlots == progressBefore.occupiedSlots + 2 &&
            stats.genericSlots == progressBefore.genericSlots + 1 &&
            stats.smallTextSlots == progressBefore.smallTextSlots + 1 &&
            stats.genericReservedInputBytes == progressBefore.genericReservedInputBytes +
                progressBytes.length &&
            stats.smallTextReservedInputBytes ==
                progressBefore.smallTextReservedInputBytes + sizeof(shortProgressBytes) - 1 &&
            stats.layoutJobsStarted == progressBefore.layoutJobsStarted + 2 &&
            stats.layoutJobsCompleted == progressBefore.layoutJobsCompleted + 1,
            "independent lane completion keeps generic input charged until terminal");
        CHECK(CjguiAsyncMultilineMeasureRelease(shortHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "release small-lane result");
        CjguiAsyncMultilineMeasureTestOpenWorkerGate();
        CHECK(pollTextMetricsReady(progressHandle, &progressActual, &failure, 15000),
            "generic ordinary measurement resumes and completes");
        CHECK(textMetricsEqual(progressActual, progressExpected),
            "complete generic ordinary result matches full-string oracle");
        CHECK(CjguiAsyncMultilineMeasureRelease(progressHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "release generic result");
        getStats(&stats);
        CHECK(stats.occupiedSlots == progressBefore.occupiedSlots &&
            stats.reservedInputBytes == progressBefore.reservedInputBytes &&
            stats.genericReservedInputBytes == progressBefore.genericReservedInputBytes &&
            stats.smallTextReservedInputBytes == progressBefore.smallTextReservedInputBytes &&
            stats.layoutJobsStarted == progressBefore.layoutJobsStarted + 2 &&
            stats.layoutJobsCompleted == progressBefore.layoutJobsCompleted + 2,
            "both lanes release slots and byte reservations after actual completion");

        const uint8_t invalidUtf8[] = {0xc0, 0xaf};
        CjguiAsyncMultilineMeasureHandle invalidHandle = 0;
        CjguiAsyncTextMetrics invalidMetrics = {0};
        CHECK(CjguiAsyncTextMetricsBegin(invalidUtf8, sizeof(invalidUtf8), font, 320.0,
            &invalidHandle) == CJGUI_ASYNC_MEASURE_STARTED, "invalid UTF-8 copied as a job");
        uint64_t invalidDeadline = monotonicNs() + 5000000000ull;
        CjguiAsyncMultilineMeasureStatus invalidStatus;
        do {
            invalidStatus = CjguiAsyncTextMetricsPoll(invalidHandle, &invalidMetrics, &failure);
            if (invalidStatus == CJGUI_ASYNC_MEASURE_PENDING) {
                struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
                nanosleep(&pause, NULL);
            }
        } while (invalidStatus == CJGUI_ASYNC_MEASURE_PENDING && monotonicNs() < invalidDeadline);
        CHECK(invalidStatus == CJGUI_ASYNC_MEASURE_FAILED &&
            failure == CJGUI_ASYNC_MEASURE_FAILURE_INVALID_UTF8,
            "invalid UTF-8 reaches a named asynchronous failure");
        CHECK(CjguiAsyncMultilineMeasureRelease(invalidHandle, CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) ==
                CJGUI_ASYNC_MEASURE_CANCELLED, "abandon failed ordinary result after named failure");

        // Hold a real Begin after its outside-lock preparation. The slot and
        // byte charge must block competing admission, and cancellation must
        // wait for the preparer to drop all refs before returning capacity.
        static const uint8_t preparingBytes[] = "preparing ordinary text";
        BeginThreadArgs preparingArgs = {
            .bytes = preparingBytes,
            .length = sizeof(preparingBytes) - 1,
            .font = font,
            .handle = 0,
            .status = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT
        };
        CjguiAsyncMultilineMeasureTestStats beforePrepare = {0};
        getStats(&beforePrepare);
        CjguiAsyncMultilineMeasureTestClosePrepareGate();
        pthread_t preparingThread;
        CHECK(pthread_create(&preparingThread, NULL, beginTextMetricsOnThread,
            &preparingArgs) == 0, "create concurrent preparing caller");
        CHECK(CjguiAsyncMultilineMeasureTestWaitForPrepareGate(5000),
            "Begin reaches the outside-lock preparation gate");
        CjguiAsyncMultilineMeasureHandle preparingHandle =
            CjguiAsyncMultilineMeasureTestPreparingHandle();
        CHECK(preparingHandle != 0,
            "preparation gate exposes only its provisional private generation");
        CjguiAsyncMultilineMeasureTestStats duringPrepare = {0};
        getStats(&duringPrepare);
        CHECK(duringPrepare.occupiedSlots == beforePrepare.occupiedSlots + 1 &&
            duringPrepare.smallTextSlots == beforePrepare.smallTextSlots + 1 &&
            duringPrepare.smallTextReservedInputBytes ==
                beforePrepare.smallTextReservedInputBytes + sizeof(preparingBytes) - 1 &&
            duringPrepare.preparedInputCopies == beforePrepare.preparedInputCopies + 1 &&
            duringPrepare.preparedInputBytes == beforePrepare.preparedInputBytes + sizeof(preparingBytes) - 1 &&
            duringPrepare.preparedFontCopies == beforePrepare.preparedFontCopies + 1 &&
            duringPrepare.preparedJobs == beforePrepare.preparedJobs + 1,
            "preparing reservation is charged while all expensive preparation runs outside the lock");
        CjguiAsyncMultilineMeasureHandle competingHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(preparingBytes, sizeof(preparingBytes) - 1,
            font, 320.0, &competingHandle) == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY &&
            competingHandle == 0,
            "another small request cannot overtake the occupied preparing slot");
        CjguiAsyncMultilineMeasureTestStats afterCompetingReject = {0};
        getStats(&afterCompetingReject);
        CHECK(afterCompetingReject.preparedInputCopies == duringPrepare.preparedInputCopies &&
            afterCompetingReject.preparedInputBytes == duringPrepare.preparedInputBytes &&
            afterCompetingReject.preparedFontCopies == duringPrepare.preparedFontCopies &&
            afterCompetingReject.preparedJobs == duringPrepare.preparedJobs,
            "capacity reject performs zero input/font/job preparation");
        CHECK(CjguiAsyncMultilineMeasureTestCancelPreparing(preparingHandle),
            "cancel marks the exact in-flight preparation generation");
        CjguiAsyncMultilineMeasureTestStats stillPreparing = {0};
        getStats(&stillPreparing);
        CHECK(stillPreparing.occupiedSlots == duringPrepare.occupiedSlots &&
            stillPreparing.reservedInputBytes == duringPrepare.reservedInputBytes &&
            stillPreparing.smallTextReservedInputBytes == duringPrepare.smallTextReservedInputBytes,
            "cancellation does not release capacity while preparation refs remain live");
        CjguiAsyncMultilineMeasureTestOpenPrepareGate();
        CHECK(pthread_join(preparingThread, NULL) == 0,
            "cancelled preparer exits after its private gate opens");
        CHECK(preparingArgs.status == CJGUI_ASYNC_MEASURE_CANCELLED &&
            preparingArgs.handle == 0,
            "cancelled preparation never publishes an output handle");
        CjguiAsyncMultilineMeasureTestStats afterPrepareCancel = {0};
        getStats(&afterPrepareCancel);
        CHECK(afterPrepareCancel.occupiedSlots == beforePrepare.occupiedSlots &&
            afterPrepareCancel.reservedInputBytes == beforePrepare.reservedInputBytes &&
            afterPrepareCancel.smallTextReservedInputBytes == beforePrepare.smallTextReservedInputBytes,
            "cancelled preparation returns capacity only after preparer cleanup");
        CHECK(CjguiAsyncMultilineMeasureRelease(preparingHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) == CJGUI_ASYNC_MEASURE_CANCELLED,
            "late provisional generation is retired as cancelled");
        CjguiAsyncMultilineMeasureHandle afterPrepareReplacement = 0;
        CHECK(CjguiAsyncTextMetricsBegin(preparingBytes, sizeof(preparingBytes) - 1,
            font, 320.0, &afterPrepareReplacement) == CJGUI_ASYNC_MEASURE_STARTED,
            "replacement generation can reserve the released short slot");
        CHECK(CjguiAsyncMultilineMeasureRelease(preparingHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) == CJGUI_ASYNC_MEASURE_STALE_HANDLE,
            "late cancellation of retired preparation cannot target replacement generation");
        CjguiAsyncTextMetrics replacementMetrics = {0};
        CHECK(pollTextMetricsReady(afterPrepareReplacement, &replacementMetrics,
            &failure, 5000), "replacement generation completes after cancelled prep");
        CHECK(CjguiAsyncMultilineMeasureRelease(afterPrepareReplacement,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "replacement generation releases normally");

        CjguiAsyncMultilineMeasureTestStats beforePrepareFailure = {0};
        getStats(&beforePrepareFailure);
        CjguiAsyncMultilineMeasureTestFailNextPrepareAfterCopy();
        CjguiAsyncMultilineMeasureHandle failedPreparationHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(preparingBytes, sizeof(preparingBytes) - 1,
            font, 320.0, &failedPreparationHandle) == CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT &&
            failedPreparationHandle == 0,
            "injected post-copy preparation failure returns without a handle");
        CjguiAsyncMultilineMeasureTestStats afterPrepareFailure = {0};
        getStats(&afterPrepareFailure);
        CHECK(afterPrepareFailure.occupiedSlots == beforePrepareFailure.occupiedSlots &&
            afterPrepareFailure.reservedInputBytes == beforePrepareFailure.reservedInputBytes &&
            afterPrepareFailure.smallTextReservedInputBytes ==
                beforePrepareFailure.smallTextReservedInputBytes &&
            afterPrepareFailure.preparedInputCopies == beforePrepareFailure.preparedInputCopies + 1 &&
            afterPrepareFailure.preparedInputBytes ==
                beforePrepareFailure.preparedInputBytes + sizeof(preparingBytes) - 1 &&
            afterPrepareFailure.preparedFontCopies == beforePrepareFailure.preparedFontCopies &&
            afterPrepareFailure.preparedJobs == beforePrepareFailure.preparedJobs,
            "failed preparation rolls back reservation after the copied NSData is released");

        // Generic capacity is 3 slots / 252 KiB. A 4 KiB ordinary-text lane
        // keeps the fourth slot and bytes available even when generic is full.
        CjguiAsyncMultilineMeasureTestStats capacityBefore = {0};
        getStats(&capacityBefore);
        CjguiAsyncMultilineMeasureTestCloseWorkerGate();
        enum { GENERIC_LARGE_BYTES = 128 * 1024,
               GENERIC_MEDIUM_BYTES = 120 * 1024,
               GENERIC_SMALL_BYTES = 4 * 1024,
               SMALL_LANE_BYTES = 4 * 1024 };
        uint8_t *capacityText = malloc(GENERIC_LARGE_BYTES);
        uint8_t *smallLaneText = malloc(SMALL_LANE_BYTES);
        CHECK(capacityText != NULL && smallLaneText != NULL,
            "lane-capacity fixture allocation");
        memset(capacityText, 'x', GENERIC_LARGE_BYTES);
        memset(smallLaneText, 's', SMALL_LANE_BYTES);
        CjguiAsyncMultilineMeasureHandle genericHandles[3] = {0};
        CHECK(CjguiAsyncTextMetricsBegin(capacityText, GENERIC_LARGE_BYTES, font,
            320.0, &genericHandles[0]) == CJGUI_ASYNC_MEASURE_STARTED,
            "128 KiB ordinary TEXT occupies one generic slot");
        CHECK(CjguiAsyncMultilineMeasureTestWaitForWorkerGate(3000),
            "generic capacity owner reaches worker gate");
        CjguiAsyncMultilineMeasureHandle second128KiB = 0;
        CHECK(CjguiAsyncMultilineMeasureBegin(capacityText, GENERIC_LARGE_BYTES,
            font, 320.0, &second128KiB) == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY &&
            second128KiB == 0,
            "two 128 KiB generic requests cannot exceed the reserved 252 KiB budget");
        CjguiAsyncMultilineMeasureTestStats afterSecond128KiB = {0};
        getStats(&afterSecond128KiB);
        fprintf(stderr,
            "CAPACITY_BYTE_REJECT prepared_input_bytes_delta=%zu copies_delta=%llu font_copies_delta=%llu jobs_delta=%llu\n",
            afterSecond128KiB.preparedInputBytes - capacityBefore.preparedInputBytes,
            (unsigned long long)(afterSecond128KiB.preparedInputCopies -
                capacityBefore.preparedInputCopies),
            (unsigned long long)(afterSecond128KiB.preparedFontCopies -
                capacityBefore.preparedFontCopies),
            (unsigned long long)(afterSecond128KiB.preparedJobs -
                capacityBefore.preparedJobs));
        CHECK(afterSecond128KiB.preparedInputBytes ==
                capacityBefore.preparedInputBytes + GENERIC_LARGE_BYTES &&
            afterSecond128KiB.preparedInputCopies == capacityBefore.preparedInputCopies + 1 &&
            afterSecond128KiB.preparedFontCopies == capacityBefore.preparedFontCopies + 1 &&
            afterSecond128KiB.preparedJobs == capacityBefore.preparedJobs + 1,
            "byte-budget rejection avoids copying or preparing the rejected second 128 KiB input");
        CHECK(CjguiAsyncMultilineMeasureBegin(capacityText, GENERIC_MEDIUM_BYTES,
            font, 320.0, &genericHandles[1]) == CJGUI_ASYNC_MEASURE_STARTED,
            "120 KiB generic request fits the remaining reserved budget");
        CHECK(CjguiAsyncMultilineMeasureBegin(capacityText, GENERIC_SMALL_BYTES,
            font, 320.0, &genericHandles[2]) == CJGUI_ASYNC_MEASURE_STARTED,
            "third generic job fills the 252 KiB and third generic slot");
        CjguiAsyncMultilineMeasureHandle genericOverflow = 0;
        CjguiAsyncMultilineMeasureTestStats beforeFullReject = {0}, afterFullReject = {0};
        getStats(&beforeFullReject);
        CHECK(CjguiAsyncMultilineMeasureBegin(capacityText, GENERIC_LARGE_BYTES, font, 320.0,
            &genericOverflow) == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY &&
            genericOverflow == 0,
            "128 KiB generic request defers while three slots and 252 KiB are full");
        getStats(&afterFullReject);
        fprintf(stderr,
            "CAPACITY_FULL_REJECT generic_slots=%u generic_reserved=%zu input_bytes_delta=%zu copies_delta=%llu font_copies_delta=%llu jobs_delta=%llu\n",
            beforeFullReject.genericSlots, beforeFullReject.genericReservedInputBytes,
            afterFullReject.preparedInputBytes - beforeFullReject.preparedInputBytes,
            (unsigned long long)(afterFullReject.preparedInputCopies -
                beforeFullReject.preparedInputCopies),
            (unsigned long long)(afterFullReject.preparedFontCopies -
                beforeFullReject.preparedFontCopies),
            (unsigned long long)(afterFullReject.preparedJobs -
                beforeFullReject.preparedJobs));
        if (afterFullReject.preparedInputBytes != beforeFullReject.preparedInputBytes ||
            afterFullReject.preparedInputCopies != beforeFullReject.preparedInputCopies ||
            afterFullReject.preparedFontCopies != beforeFullReject.preparedFontCopies ||
            afterFullReject.preparedJobs != beforeFullReject.preparedJobs) {
            for (NSUInteger i = 0; i < 3; i++) {
                CjguiAsyncMultilineMeasureRelease(genericHandles[i],
                    CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED);
            }
            CjguiAsyncMultilineMeasureTestOpenWorkerGate();
            uint64_t redDrainDeadline = monotonicNs() + 15000000000ull;
            do {
                getStats(&stats);
                if (stats.genericSlots == 0) break;
                struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
                nanosleep(&pause, NULL);
            } while (monotonicNs() < redDrainDeadline);
            fprintf(stderr,
                "ASYNC_MULTILINE_MEASURE RED: a capacity-rejected 128KiB input was copied and prepared before slot/budget admission\n");
            return 1;
        }

        CjguiAsyncMultilineMeasureHandle smallHandle = 0;
        CHECK(CjguiAsyncTextMetricsBegin(smallLaneText, SMALL_LANE_BYTES, font,
            320.0, &smallHandle) == CJGUI_ASYNC_MEASURE_STARTED,
            "reserved 4 KiB small lane admits while generic resources are full");
        CjguiAsyncTextMetrics smallExpected = mainThreadMetrics(
            strictString(smallLaneText, SMALL_LANE_BYTES), font, 320.0);
        CjguiAsyncTextMetrics smallActual = {0};
        CHECK(pollTextMetricsReady(smallHandle, &smallActual, &failure, 10000),
            "reserved small lane completes while generic lane is gated");
        CHECK(textMetricsEqual(smallActual, smallExpected),
            "small lane preserves exact full-string geometry");
        CjguiAsyncMultilineMeasureHandle extraSmall = 0;
        CHECK(CjguiAsyncTextMetricsBegin(shortProgressBytes, sizeof(shortProgressBytes) - 1,
            font, 320.0, &extraSmall) == CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY &&
            extraSmall == 0,
            "small lane remains bounded to one slot and 4 KiB reservation");
        getStats(&stats);
        CHECK(stats.occupiedSlots == 4 && stats.genericSlots == 3 &&
            stats.smallTextSlots == 1 &&
            stats.genericReservedInputBytes == 252 * 1024 &&
            stats.smallTextReservedInputBytes == 4 * 1024 &&
            stats.reservedInputBytes == 256 * 1024,
            "lane stats show exact 3+1 slots and 252+4 KiB reservations");
        for (NSUInteger i = 0; i < 3; i++) {
            CHECK(CjguiAsyncMultilineMeasureRelease(genericHandles[i],
                CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) == CJGUI_ASYNC_MEASURE_CANCELLED,
                "generic cancellation revokes publication without releasing active capacity");
        }
        CHECK(CjguiAsyncTextMetricsPoll(genericHandles[0], &asciiMetrics, &failure) ==
            CJGUI_ASYNC_MEASURE_CANCELLED,
            "cancelled running generic ordinary result cannot publish READY");
        getStats(&stats);
        CHECK(stats.genericSlots == 3 && stats.smallTextSlots == 1 &&
            stats.genericReservedInputBytes == 252 * 1024 &&
            stats.smallTextReservedInputBytes == 4 * 1024,
            "cancelled generic capacity remains reserved until worker cleanup");
        CjguiAsyncMultilineMeasureTestOpenWorkerGate();
        uint64_t drainDeadline = monotonicNs() + 15000000000ull;
        do {
            getStats(&stats);
            if (stats.genericSlots == 0) break;
            struct timespec pause = {.tv_sec = 0, .tv_nsec = 1000000};
            nanosleep(&pause, NULL);
        } while (monotonicNs() < drainDeadline);
        CHECK(stats.genericSlots == 0 && stats.smallTextSlots == 1 &&
            stats.genericReservedInputBytes == 0 &&
            stats.smallTextReservedInputBytes == 4 * 1024,
            "generic reservations return only after cancellation cleanup completes");
        CHECK(CjguiAsyncMultilineMeasureRelease(smallHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "small-lane READY result releases normally");
        getStats(&stats);
        CHECK(stats.occupiedSlots == 0 && stats.reservedInputBytes == 0 &&
            stats.genericReservedInputBytes == 0 && stats.smallTextReservedInputBytes == 0,
            "all lane capacity returns to zero after true terminal release");
        CjguiAsyncMultilineMeasureHandle replacement = 0;
        static const uint8_t replacementBytes[] = "reuse";
        CHECK(CjguiAsyncTextMetricsBegin(replacementBytes, sizeof(replacementBytes) - 1,
            font, 320.0, &replacement) == CJGUI_ASYNC_MEASURE_STARTED,
            "released short slot can be reused with a new generation");
        CHECK(CjguiAsyncMultilineMeasureRelease(smallHandle,
            CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) == CJGUI_ASYNC_MEASURE_STALE_HANDLE,
            "old small-lane generation cannot cancel its replacement");
        CHECK(pollTextMetricsReady(replacement, &smallActual, &failure, 5000),
            "replacement small-lane job completes");
        CHECK(CjguiAsyncMultilineMeasureRelease(replacement,
            CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED) == CJGUI_ASYNC_MEASURE_READY,
            "replacement small-lane result releases normally");
        free(capacityText);
        free(smallLaneText);

        getStats(&stats);
        CHECK(stats.occupiedSlots == 0 && stats.reservedInputBytes == 0,
            "all worker and consumer references drain");
        printf("ASYNC_MULTILINE_MEASURE PASS slots=%u reserved_bytes=%zu layouts_started=%llu layouts_completed=%llu ascii_height=%u newline_height=%u unicode_height=%u\n",
            stats.occupiedSlots, stats.reservedInputBytes,
            (unsigned long long)stats.layoutJobsStarted,
            (unsigned long long)stats.layoutJobsCompleted, asciiExpected, newlineExpected, unicodeExpected);
    }
    return 0;
}
