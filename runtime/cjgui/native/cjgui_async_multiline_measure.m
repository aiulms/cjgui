#import "cjgui_async_multiline_measure.h"

#include <math.h>
#include <pthread.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

enum {
    kCjguiAsyncMeasureSlotCount = 4,
    kCjguiAsyncMeasureMaxJobBytes = 128 * 1024,
    kCjguiAsyncMeasureMaxReservedBytes = 256 * 1024,
    kCjguiAsyncMeasureSmallTextMaxJobBytes = 4 * 1024,
    kCjguiAsyncMeasureSmallTextReservedBytes = 4 * 1024,
    kCjguiAsyncMeasureGenericReservedBytes =
        kCjguiAsyncMeasureMaxReservedBytes - kCjguiAsyncMeasureSmallTextReservedBytes,
    kCjguiAsyncMeasureGenericSlotCount = kCjguiAsyncMeasureSlotCount - 1,
    kCjguiAsyncMeasureHandleSlotBits = 8
};

@interface CjguiAsyncMultilineMeasureJob : NSObject
@property(nonatomic) uint64_t generation;
@property(nonatomic) CjguiAsyncMultilineMeasureHandle handle;
@property(nonatomic, strong) NSData *inputBytes;
@property(nonatomic, strong) NSFont *fontSnapshot;
@property(nonatomic) size_t reservedInputBytes;
@property(nonatomic) CGFloat contentWidth;
@property(nonatomic) BOOL ordinaryText;
@property(nonatomic) BOOL smallTextLane;
@property(nonatomic) BOOL layoutStarted;
@property(nonatomic) uint64_t workerStartedNs;
@property(nonatomic) uint64_t queueWaitNs;
@property(nonatomic) uint64_t serviceNs;
@property(nonatomic) uint64_t serviceStartNs;
@property(nonatomic) uint64_t serviceEndNs;
@property(nonatomic) uint64_t activeWallNs;
@property(nonatomic) CjguiAsyncTextMetrics metrics;
@property(nonatomic) uint64_t admittedNs;
@property(nonatomic) BOOL workerLive;
@property(nonatomic) BOOL consumerLive;
@property(nonatomic) BOOL cancelled;
@property(nonatomic) BOOL completed;
@property(nonatomic) BOOL ready;
@property(nonatomic) uint32_t height;
@property(nonatomic) CjguiAsyncMultilineMeasureFailure failure;
@property(nonatomic) CjguiAsyncMultilineMeasureStatus terminalStatus;
@end

@implementation CjguiAsyncMultilineMeasureJob
@end

typedef struct {
    __strong CjguiAsyncMultilineMeasureJob *job;
    uint64_t generation;
    uint64_t retiredGeneration;
    CjguiAsyncMultilineMeasureReleaseDisposition retiredDisposition;
    CjguiAsyncMultilineMeasureStatus retiredStatus;
    BOOL preparing;
    BOOL preparationCancelled;
    BOOL preparingSmallTextLane;
    size_t preparingReservedInputBytes;
} CjguiAsyncMultilineMeasureSlot;

static pthread_mutex_t gCjguiAsyncMeasureLock = PTHREAD_MUTEX_INITIALIZER;
static CjguiAsyncMultilineMeasureSlot gCjguiAsyncMeasureSlots[kCjguiAsyncMeasureSlotCount];
static size_t gCjguiAsyncMeasureReservedBytes = 0;
static uint64_t gCjguiAsyncMeasureNextGeneration = 1;
static uint64_t gCjguiAsyncMeasureLayoutJobsStarted = 0;
static uint64_t gCjguiAsyncMeasureLayoutJobsCompleted = 0;
static size_t gCjguiAsyncMeasureGenericReservedBytes = 0;
static size_t gCjguiAsyncMeasureSmallTextReservedBytes = 0;
static dispatch_queue_t gCjguiAsyncMeasureGenericQueue;
static dispatch_queue_t gCjguiAsyncMeasureSmallTextQueue;
static dispatch_once_t gCjguiAsyncMeasureQueuesOnce;

static uint64_t CjguiAsyncMeasureNow(void) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    return (uint64_t)now.tv_sec * 1000000000ull + (uint64_t)now.tv_nsec;
}

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
static pthread_cond_t gCjguiAsyncMeasureTestGateCondition = PTHREAD_COND_INITIALIZER;
static BOOL gCjguiAsyncMeasureTestGateClosed = NO;
static BOOL gCjguiAsyncMeasureTestWorkerAtGate = NO;
static CjguiAsyncMultilineMeasureHandle gCjguiAsyncMeasureTestWorkerGateHandle = 0;
static uint64_t gCjguiAsyncMeasureTestPreparedInputCopies = 0;
static size_t gCjguiAsyncMeasureTestPreparedInputBytes = 0;
static uint64_t gCjguiAsyncMeasureTestPreparedFontCopies = 0;
static uint64_t gCjguiAsyncMeasureTestPreparedJobs = 0;
static BOOL gCjguiAsyncMeasureTestPrepareGateClosed = NO;
static BOOL gCjguiAsyncMeasureTestPrepareAtGate = NO;
static CjguiAsyncMultilineMeasureHandle gCjguiAsyncMeasureTestPreparingHandle = 0;
static BOOL gCjguiAsyncMeasureTestFailNextPrepareAfterCopy = NO;
#endif

static void CjguiAsyncMeasureQueuesEnsure(void) {
    dispatch_once(&gCjguiAsyncMeasureQueuesOnce, ^{
        dispatch_queue_attr_t attributes = dispatch_queue_attr_make_with_qos_class(
            DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
        gCjguiAsyncMeasureGenericQueue = dispatch_queue_create(
            "org.cjgui.async-multiline-measure", attributes);
        gCjguiAsyncMeasureSmallTextQueue = dispatch_queue_create(
            "org.cjgui.async-text-measure-small", attributes);
    });
}

static dispatch_queue_t CjguiAsyncMeasureQueueForJob(CjguiAsyncMultilineMeasureJob *job) {
    CjguiAsyncMeasureQueuesEnsure();
    return job.smallTextLane ? gCjguiAsyncMeasureSmallTextQueue
                             : gCjguiAsyncMeasureGenericQueue;
}

static CjguiAsyncMultilineMeasureHandle CjguiAsyncMeasureMakeHandle(uint64_t generation,
                                                                     NSUInteger slotIndex) {
    return (generation << kCjguiAsyncMeasureHandleSlotBits) | (uint64_t)(slotIndex + 1);
}

static BOOL CjguiAsyncMeasureDecodeHandle(CjguiAsyncMultilineMeasureHandle handle,
                                          NSUInteger *outIndex, uint64_t *outGeneration) {
    NSUInteger encodedIndex = (NSUInteger)(handle & ((1u << kCjguiAsyncMeasureHandleSlotBits) - 1u));
    uint64_t generation = handle >> kCjguiAsyncMeasureHandleSlotBits;
    if (encodedIndex == 0 || encodedIndex > kCjguiAsyncMeasureSlotCount || generation == 0) return NO;
    *outIndex = encodedIndex - 1;
    *outGeneration = generation;
    return YES;
}

static CjguiAsyncMultilineMeasureJob *CjguiAsyncMeasureLookupLocked(
    CjguiAsyncMultilineMeasureHandle handle, NSUInteger *outIndex, BOOL *outRetired) {
    NSUInteger index = 0;
    uint64_t generation = 0;
    if (!CjguiAsyncMeasureDecodeHandle(handle, &index, &generation)) return nil;
    if (outIndex) *outIndex = index;
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[index];
    if (slot->job && slot->generation == generation && slot->job.generation == generation &&
        slot->job.handle == handle) {
        if (outRetired) *outRetired = NO;
        return slot->job;
    }
    if (outRetired) *outRetired = slot->retiredGeneration == generation;
    return nil;
}

static void CjguiAsyncMeasureReleaseReservationBytesLocked(BOOL smallTextLane,
                                                            size_t byteCount) {
    if (byteCount <= gCjguiAsyncMeasureReservedBytes) {
        gCjguiAsyncMeasureReservedBytes -= byteCount;
    } else {
        gCjguiAsyncMeasureReservedBytes = 0;
    }
    if (smallTextLane) {
        if (byteCount <= gCjguiAsyncMeasureSmallTextReservedBytes) {
            gCjguiAsyncMeasureSmallTextReservedBytes -= byteCount;
        } else {
            gCjguiAsyncMeasureSmallTextReservedBytes = 0;
        }
    } else {
        if (byteCount <= gCjguiAsyncMeasureGenericReservedBytes) {
            gCjguiAsyncMeasureGenericReservedBytes -= byteCount;
        } else {
            gCjguiAsyncMeasureGenericReservedBytes = 0;
        }
    }
}

static void CjguiAsyncMeasureRollbackReservation(NSUInteger index, uint64_t generation) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[index];
    if (slot->preparing && slot->generation == generation) {
        CjguiAsyncMeasureReleaseReservationBytesLocked(slot->preparingSmallTextLane,
            slot->preparingReservedInputBytes);
        slot->preparing = NO;
        slot->preparationCancelled = NO;
        slot->preparingSmallTextLane = NO;
        slot->preparingReservedInputBytes = 0;
        slot->retiredGeneration = generation;
        slot->retiredDisposition = CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED;
        slot->retiredStatus = CJGUI_ASYNC_MEASURE_CANCELLED;
    }
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

static void CjguiAsyncMeasureRetireIfUnownedLocked(NSUInteger index,
                                                    CjguiAsyncMultilineMeasureJob *job) {
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[index];
    if (slot->job != job || job.consumerLive || job.workerLive) return;
    slot->retiredGeneration = job.generation;
    slot->retiredDisposition = job.cancelled
        ? CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED
        : CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED;
    slot->retiredStatus = job.terminalStatus;
    CjguiAsyncMeasureReleaseReservationBytesLocked(job.smallTextLane,
        job.reservedInputBytes);
    slot->job = nil;
}

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
static void CjguiAsyncMeasureTestWorkerGate(CjguiAsyncMultilineMeasureHandle handle) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    if (gCjguiAsyncMeasureTestGateClosed) {
        gCjguiAsyncMeasureTestWorkerAtGate = YES;
        gCjguiAsyncMeasureTestWorkerGateHandle = handle;
        pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
        while (gCjguiAsyncMeasureTestGateClosed) {
            pthread_cond_wait(&gCjguiAsyncMeasureTestGateCondition, &gCjguiAsyncMeasureLock);
        }
        gCjguiAsyncMeasureTestWorkerAtGate = NO;
        pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
    }
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

#endif

static void CjguiAsyncMeasureClearWorkerInputs(CjguiAsyncMultilineMeasureJob *job) {
    job.inputBytes = nil;
    job.fontSnapshot = nil;
}

static void CjguiAsyncMeasureSetServiceStart(CjguiAsyncMultilineMeasureJob *job,
                                             uint64_t serviceStartNs) {
#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    job.serviceStartNs = serviceStartNs;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
#else
    job.serviceStartNs = serviceStartNs;
#endif
}

static void CjguiAsyncMeasureTraceCompletion(CjguiAsyncMultilineMeasureJob *job,
                                              uint64_t completedNs,
                                              CjguiAsyncMultilineMeasureFailure failure) {
    if (!getenv("CJGUI_TEXT_PREPARE_TRACE") || !job.layoutStarted) return;
    uint64_t workerNs = completedNs - job.workerStartedNs;
    fprintf(stderr, "CJGUI_SCALAR_PREPARE handle=%llu kind=%s lane=%s bytes=%zu main=%d admitted_ns=%llu started_ns=%llu service_start_ns=%llu service_end_ns=%llu completed_ns=%llu service_ns=%llu active_wall_ns=%llu queue_wait_ns=%llu worker_ns=%llu total_ns=%llu terminal=%d failure=%d\n",
        (unsigned long long)job.handle, job.ordinaryText ? "text" : "multiline",
        job.smallTextLane ? "small" : "generic",
        job.reservedInputBytes, [NSThread isMainThread] ? 1 : 0,
        (unsigned long long)job.admittedNs, (unsigned long long)job.workerStartedNs,
        (unsigned long long)job.serviceStartNs, (unsigned long long)job.serviceEndNs,
        (unsigned long long)completedNs, (unsigned long long)job.serviceNs,
        (unsigned long long)job.activeWallNs, (unsigned long long)job.queueWaitNs,
        (unsigned long long)workerNs,
        (unsigned long long)(completedNs - job.admittedNs),
        (int)job.terminalStatus, (int)failure);
}

static void CjguiAsyncMeasurePerformOrdinaryText(
    CjguiAsyncMultilineMeasureJob *job, CjguiAsyncTextMetrics *outMetrics,
    CjguiAsyncMultilineMeasureFailure *outFailure) {
    memset(outMetrics, 0, sizeof(*outMetrics));
    *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    BOOL serviceActive = NO;
    uint64_t serviceStartNs = 0;
    @autoreleasepool {
        @try {
            NSString *value = [[NSString alloc] initWithBytes:job.inputBytes.bytes
                length:job.inputBytes.length encoding:NSUTF8StringEncoding];
            if (!value) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INVALID_UTF8;
                return;
            }
            NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
            paragraph.lineBreakMode = NSLineBreakByWordWrapping;
            NSDictionary *attributes = @{NSFontAttributeName: job.fontSnapshot,
                                         NSParagraphStyleAttributeName: paragraph};
            CGFloat width = job.contentWidth > 0.0
                ? job.contentWidth : CGFLOAT_MAX / 4.0;
            serviceStartNs = CjguiAsyncMeasureNow();
            CjguiAsyncMeasureSetServiceStart(job, serviceStartNs);
            serviceActive = YES;
            NSRect bounds = [value boundingRectWithSize:NSMakeSize(width, CGFLOAT_MAX / 4.0)
                options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                attributes:attributes];
            job.serviceEndNs = CjguiAsyncMeasureNow();
            job.serviceNs += job.serviceEndNs - serviceStartNs;
            serviceActive = NO;
            if (!isfinite(bounds.size.width) || !isfinite(bounds.size.height)) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INVALID_HEIGHT;
                return;
            }
            CGFloat lineHeight = MAX(1.0, job.fontSnapshot.ascender -
                job.fontSnapshot.descender + job.fontSnapshot.leading);
            if (!isfinite(lineHeight)) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INVALID_HEIGHT;
                return;
            }
            outMetrics->width = (uint32_t)MIN(UINT32_MAX,
                MAX(0.0, ceil(bounds.size.width)));
            outMetrics->height = (uint32_t)MIN(UINT32_MAX,
                MAX(lineHeight, ceil(bounds.size.height)));
            outMetrics->lineHeight = (uint32_t)MIN(UINT32_MAX, ceil(lineHeight));
            outMetrics->baseline = (uint32_t)MIN(UINT32_MAX,
                MAX(0.0, ceil(job.fontSnapshot.ascender)));
        } @catch (__unused NSException *exception) {
            if (serviceActive) {
                job.serviceEndNs = CjguiAsyncMeasureNow();
                job.serviceNs += job.serviceEndNs - serviceStartNs;
            }
            *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_TEXTKIT_EXCEPTION;
        }
    }
}

static void CjguiAsyncMeasurePerformMultiline(CjguiAsyncMultilineMeasureJob *job,
                                              CjguiAsyncTextMetrics *outMetrics,
                                              CjguiAsyncMultilineMeasureFailure *outFailure) {
    memset(outMetrics, 0, sizeof(*outMetrics));
    *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    @autoreleasepool {
        @try {
            NSString *value = [[NSString alloc] initWithBytes:job.inputBytes.bytes
                length:job.inputBytes.length encoding:NSUTF8StringEncoding];
            if (!value) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INVALID_UTF8;
                return;
            }
            NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
            paragraph.lineBreakMode = NSLineBreakByWordWrapping;
            NSTextStorage *storage = [[NSTextStorage alloc] initWithString:value
                attributes:@{NSFontAttributeName: job.fontSnapshot,
                             NSParagraphStyleAttributeName: paragraph}];
            NSLayoutManager *layout = [NSLayoutManager new];
            layout.backgroundLayoutEnabled = NO;
            [storage addLayoutManager:layout];
            NSTextContainer *container = [[NSTextContainer alloc]
                initWithSize:NSMakeSize(job.contentWidth, CGFLOAT_MAX / 4.0)];
            container.widthTracksTextView = NO;
            container.lineFragmentPadding = 0.0;
            [layout addTextContainer:container];
            [layout ensureLayoutForTextContainer:container];
            if (value.length > 0 && layout.firstUnlaidCharacterIndex < value.length) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INCOMPLETE_LAYOUT;
                return;
            }
            CGFloat lineHeight = MAX(1.0, job.fontSnapshot.ascender - job.fontSnapshot.descender +
                                             job.fontSnapshot.leading);
            CGFloat height = MAX(lineHeight, NSMaxY([layout usedRectForTextContainer:container]));
            if (layout.extraLineFragmentTextContainer == container &&
                !NSIsEmptyRect(layout.extraLineFragmentRect)) {
                height = MAX(height, NSMaxY(layout.extraLineFragmentRect));
            }
            if (!isfinite(height) || height < 0.0 || height > UINT32_MAX) {
                *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_INVALID_HEIGHT;
                return;
            }
            outMetrics->height = (uint32_t)ceil(height);
        } @catch (__unused NSException *exception) {
            *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_TEXTKIT_EXCEPTION;
        }
    }
}

static void CjguiAsyncMeasureRunJob(CjguiAsyncMultilineMeasureJob *job,
                                   NSUInteger slotIndex) {
    uint64_t callbackEntryNs = CjguiAsyncMeasureNow();
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    job.queueWaitNs = callbackEntryNs >= job.admittedNs
        ? callbackEntryNs - job.admittedNs : 0;
    if (job.cancelled || !job.consumerLive) {
        BOOL wasStarted = job.layoutStarted;
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        CjguiAsyncMeasureClearWorkerInputs(job);
        pthread_mutex_lock(&gCjguiAsyncMeasureLock);
        if (wasStarted) gCjguiAsyncMeasureLayoutJobsCompleted += 1;
        job.completed = YES;
        job.terminalStatus = CJGUI_ASYNC_MEASURE_CANCELLED;
        job.workerLive = NO;
        CjguiAsyncMeasureRetireIfUnownedLocked(slotIndex, job);
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        uint64_t completedNs = CjguiAsyncMeasureNow();
        if (wasStarted) job.activeWallNs = completedNs - callbackEntryNs;
        CjguiAsyncMeasureTraceCompletion(job, completedNs,
            CJGUI_ASYNC_MEASURE_FAILURE_NONE);
        return;
    }
    if (!job.layoutStarted) {
        job.layoutStarted = YES;
        job.workerStartedNs = callbackEntryNs;
        gCjguiAsyncMeasureLayoutJobsStarted += 1;
    }
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
    if (!job.smallTextLane) CjguiAsyncMeasureTestWorkerGate(job.handle);
#endif

    CjguiAsyncTextMetrics metrics = {0};
    CjguiAsyncMultilineMeasureFailure failure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    BOOL cancelledBeforeService = job.cancelled || !job.consumerLive;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    if (!cancelledBeforeService) {
        if (job.ordinaryText) {
            CjguiAsyncMeasurePerformOrdinaryText(job, &metrics, &failure);
        } else {
            uint64_t serviceStartNs = CjguiAsyncMeasureNow();
            CjguiAsyncMeasureSetServiceStart(job, serviceStartNs);
            CjguiAsyncMeasurePerformMultiline(job, &metrics, &failure);
            job.serviceEndNs = CjguiAsyncMeasureNow();
            job.serviceNs = job.serviceEndNs - serviceStartNs;
        }
    }

    // The worker owns the copied input and font through Foundation return and
    // autorelease-pool teardown. Drop those references before returning budget.
    CjguiAsyncMeasureClearWorkerInputs(job);
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureLayoutJobsCompleted += 1;
    job.completed = YES;
    job.workerLive = NO;
    if (job.cancelled || !job.consumerLive) {
        job.terminalStatus = CJGUI_ASYNC_MEASURE_CANCELLED;
    } else if (failure != CJGUI_ASYNC_MEASURE_FAILURE_NONE) {
        job.failure = failure;
        job.terminalStatus = CJGUI_ASYNC_MEASURE_FAILED;
    } else {
        job.height = metrics.height;
        job.metrics = metrics;
        job.ready = YES;
        job.terminalStatus = CJGUI_ASYNC_MEASURE_READY;
    }
    CjguiAsyncMeasureRetireIfUnownedLocked(slotIndex, job);
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    uint64_t completedNs = CjguiAsyncMeasureNow();
    job.activeWallNs = completedNs - callbackEntryNs;
    CjguiAsyncMeasureTraceCompletion(job, completedNs, failure);
}

static CjguiAsyncMultilineMeasureStatus CjguiAsyncMeasureBegin(
    const uint8_t *utf8Bytes, size_t byteLength, NSFont *fontSnapshot,
    double contentWidth, BOOL ordinaryText, CjguiAsyncMultilineMeasureHandle *outHandle) {
    if (outHandle) *outHandle = 0;
    if (!outHandle || (byteLength > 0 && !utf8Bytes) || !fontSnapshot ||
        !isfinite(contentWidth) || contentWidth < 0.0 ||
        (ordinaryText ? contentWidth > UINT32_MAX : (contentWidth == 0.0 || contentWidth > 1000000.0))) {
        return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    }
    if (byteLength > kCjguiAsyncMeasureMaxJobBytes) return CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY;

    BOOL smallTextLane = ordinaryText &&
        byteLength <= kCjguiAsyncMeasureSmallTextMaxJobBytes;
    // Reserve bounded capacity and a generation before allocating or copying.
    // A preparing slot is occupied and charged exactly like a live job, but
    // cancellation cannot return that charge until its preparer drops refs.
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    NSUInteger slotIndex = NSNotFound;
    NSUInteger slotStart = smallTextLane ? kCjguiAsyncMeasureGenericSlotCount : 0;
    NSUInteger slotEnd = smallTextLane ? kCjguiAsyncMeasureSlotCount : kCjguiAsyncMeasureGenericSlotCount;
    for (NSUInteger index = slotStart; index < slotEnd; index++) {
        if (!gCjguiAsyncMeasureSlots[index].job && !gCjguiAsyncMeasureSlots[index].preparing) {
            slotIndex = index;
            break;
        }
    }
    size_t laneReserved = smallTextLane
        ? gCjguiAsyncMeasureSmallTextReservedBytes
        : gCjguiAsyncMeasureGenericReservedBytes;
    size_t laneLimit = smallTextLane
        ? kCjguiAsyncMeasureSmallTextReservedBytes
        : kCjguiAsyncMeasureGenericReservedBytes;
    size_t totalRemaining = kCjguiAsyncMeasureMaxReservedBytes -
        gCjguiAsyncMeasureReservedBytes;
    if (slotIndex == NSNotFound || byteLength > laneLimit - laneReserved ||
        byteLength > totalRemaining ||
        gCjguiAsyncMeasureNextGeneration > (UINT64_MAX >> kCjguiAsyncMeasureHandleSlotBits)) {
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY;
    }

    uint64_t generation = gCjguiAsyncMeasureNextGeneration++;
    CjguiAsyncMultilineMeasureHandle handle = CjguiAsyncMeasureMakeHandle(generation, slotIndex);
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[slotIndex];
    slot->generation = generation;
    slot->retiredGeneration = 0;
    slot->preparing = YES;
    slot->preparationCancelled = NO;
    slot->preparingSmallTextLane = smallTextLane;
    slot->preparingReservedInputBytes = byteLength;
    gCjguiAsyncMeasureReservedBytes += byteLength;
    if (smallTextLane) gCjguiAsyncMeasureSmallTextReservedBytes += byteLength;
    else gCjguiAsyncMeasureGenericReservedBytes += byteLength;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);

    __strong NSData *input = nil;
    __strong NSFont *font = nil;
    __strong CjguiAsyncMultilineMeasureJob *job = nil;
    BOOL committed = NO;
    CjguiAsyncMultilineMeasureStatus preparationStatus = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    @autoreleasepool {
        @try {
            input = [[NSData alloc] initWithBytes:utf8Bytes length:byteLength];
#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
            if (input) {
                pthread_mutex_lock(&gCjguiAsyncMeasureLock);
                gCjguiAsyncMeasureTestPreparedInputCopies += 1;
                gCjguiAsyncMeasureTestPreparedInputBytes += input.length;
                BOOL failAfterCopy = gCjguiAsyncMeasureTestFailNextPrepareAfterCopy;
                gCjguiAsyncMeasureTestFailNextPrepareAfterCopy = NO;
                pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
                if (failAfterCopy) input = nil;
            }
#endif
            if (input) font = [fontSnapshot copy];
            if (input && font) {
                job = [CjguiAsyncMultilineMeasureJob new];
            }
        } @catch (__unused NSException *exception) {
            input = nil;
            font = nil;
            job = nil;
        }
#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
        if (font) {
            pthread_mutex_lock(&gCjguiAsyncMeasureLock);
            gCjguiAsyncMeasureTestPreparedFontCopies += 1;
            pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        }
        if (job) {
            pthread_mutex_lock(&gCjguiAsyncMeasureLock);
            gCjguiAsyncMeasureTestPreparedJobs += 1;
            pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        }
#endif
        if (input && font && job) {
            job.inputBytes = input;
            job.fontSnapshot = font;
            job.reservedInputBytes = byteLength;
            job.contentWidth = contentWidth;
            job.ordinaryText = ordinaryText;
            job.smallTextLane = smallTextLane;
            job.workerLive = YES;
            job.consumerLive = YES;
            job.terminalStatus = CJGUI_ASYNC_MEASURE_PENDING;
            job.generation = generation;
            job.handle = handle;
            job.admittedNs = CjguiAsyncMeasureNow();

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
            pthread_mutex_lock(&gCjguiAsyncMeasureLock);
            if (gCjguiAsyncMeasureTestPrepareGateClosed) {
                gCjguiAsyncMeasureTestPrepareAtGate = YES;
                gCjguiAsyncMeasureTestPreparingHandle = handle;
                pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
                while (gCjguiAsyncMeasureTestPrepareGateClosed) {
                    pthread_cond_wait(&gCjguiAsyncMeasureTestGateCondition,
                        &gCjguiAsyncMeasureLock);
                }
                gCjguiAsyncMeasureTestPrepareAtGate = NO;
                gCjguiAsyncMeasureTestPreparingHandle = 0;
                pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
            }
            pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
#endif
            pthread_mutex_lock(&gCjguiAsyncMeasureLock);
            slot = &gCjguiAsyncMeasureSlots[slotIndex];
            if (slot->preparing && slot->generation == generation &&
                !slot->preparationCancelled) {
                slot->job = job;
                slot->preparing = NO;
                slot->preparationCancelled = NO;
                slot->preparingSmallTextLane = NO;
                slot->preparingReservedInputBytes = 0;
                *outHandle = handle;
                committed = YES;
                preparationStatus = CJGUI_ASYNC_MEASURE_STARTED;
            } else if (slot->preparing && slot->generation == generation &&
                slot->preparationCancelled) {
                preparationStatus = CJGUI_ASYNC_MEASURE_CANCELLED;
            } else {
                preparationStatus = CJGUI_ASYNC_MEASURE_DEFERRED_CAPACITY;
            }
            pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        }

        if (!committed) {
            if (!input || !font || !job) preparationStatus = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
            if (job) {
                job.inputBytes = nil;
                job.fontSnapshot = nil;
            }
            job = nil;
            font = nil;
            input = nil;
        }
    }

    if (!committed) {
        CjguiAsyncMeasureRollbackReservation(slotIndex, generation);
        return preparationStatus;
    }
    input = nil;
    font = nil;

    dispatch_async(CjguiAsyncMeasureQueueForJob(job), ^{
        CjguiAsyncMeasureRunJob(job, slotIndex);
    });
    return CJGUI_ASYNC_MEASURE_STARTED;
}

CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasureBegin(
    const uint8_t *utf8Bytes, size_t byteLength, NSFont *fontSnapshot,
    double contentWidth, CjguiAsyncMultilineMeasureHandle *outHandle) {
    return CjguiAsyncMeasureBegin(utf8Bytes, byteLength, fontSnapshot, contentWidth, NO, outHandle);
}

CjguiAsyncMultilineMeasureStatus CjguiAsyncTextMetricsBegin(
    const uint8_t *utf8Bytes, size_t byteLength, NSFont *fontSnapshot,
    double maximumWidth, CjguiAsyncMultilineMeasureHandle *outHandle) {
    return CjguiAsyncMeasureBegin(utf8Bytes, byteLength, fontSnapshot, maximumWidth, YES, outHandle);
}

CjguiAsyncMultilineMeasureStatus CjguiAsyncTextMetricsPoll(
    CjguiAsyncMultilineMeasureHandle handle, CjguiAsyncTextMetrics *outMetrics,
    CjguiAsyncMultilineMeasureFailure *outFailure) {
    if (outMetrics) memset(outMetrics, 0, sizeof(*outMetrics));
    if (outFailure) *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    if (!outMetrics || !outFailure) return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureJob *job = CjguiAsyncMeasureLookupLocked(handle, NULL, NULL);
    CjguiAsyncMultilineMeasureStatus status = CJGUI_ASYNC_MEASURE_STALE_HANDLE;
    if (job) {
        if (!job.ordinaryText) status = CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
        else if (job.cancelled || !job.consumerLive) status = CJGUI_ASYNC_MEASURE_CANCELLED;
        else if (!job.completed) status = CJGUI_ASYNC_MEASURE_PENDING;
        else {
            status = job.terminalStatus;
            *outFailure = job.failure;
            if (job.ready) *outMetrics = job.metrics;
        }
    }
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return status;
}

CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasurePoll(
    CjguiAsyncMultilineMeasureHandle handle, uint32_t *outHeight,
    CjguiAsyncMultilineMeasureFailure *outFailure) {
    if (outHeight) *outHeight = 0;
    if (outFailure) *outFailure = CJGUI_ASYNC_MEASURE_FAILURE_NONE;
    if (!outHeight || !outFailure) return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureJob *job = CjguiAsyncMeasureLookupLocked(handle, NULL, NULL);
    if (!job) {
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_STALE_HANDLE;
    }
    if (job.ordinaryText) {
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    }
    if (job.cancelled || !job.consumerLive) {
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_CANCELLED;
    }
    if (!job.completed) {
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_PENDING;
    }
    if (job.terminalStatus == CJGUI_ASYNC_MEASURE_FAILED) {
        *outFailure = job.failure;
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_FAILED;
    }
    if (job.ready) {
        *outHeight = job.height;
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_READY;
    }
    CjguiAsyncMultilineMeasureStatus status = job.terminalStatus;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return status;
}

CjguiAsyncMultilineMeasureStatus CjguiAsyncMultilineMeasureRelease(
    CjguiAsyncMultilineMeasureHandle handle,
    CjguiAsyncMultilineMeasureReleaseDisposition disposition) {
    if (disposition != CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED &&
        disposition != CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) {
        return CJGUI_ASYNC_MEASURE_INVALID_ARGUMENT;
    }
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    NSUInteger slotIndex = NSNotFound;
    BOOL retired = NO;
    CjguiAsyncMultilineMeasureJob *job = CjguiAsyncMeasureLookupLocked(handle, &slotIndex, &retired);
    if (!job) {
        if (retired && disposition == gCjguiAsyncMeasureSlots[slotIndex].retiredDisposition) {
            CjguiAsyncMultilineMeasureStatus status = gCjguiAsyncMeasureSlots[slotIndex].retiredStatus;
            pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
            return status;
        }
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return CJGUI_ASYNC_MEASURE_STALE_HANDLE;
    }
    if (disposition == CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED && !job.ready) {
        CjguiAsyncMultilineMeasureStatus status = job.completed
            ? job.terminalStatus : CJGUI_ASYNC_MEASURE_NOT_READY;
        pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
        return status;
    }
    if (disposition == CJGUI_ASYNC_MEASURE_RELEASE_ABANDONED) {
        job.cancelled = YES;
        job.terminalStatus = CJGUI_ASYNC_MEASURE_CANCELLED;
    }
    job.consumerLive = NO;
    CjguiAsyncMultilineMeasureStatus status = disposition == CJGUI_ASYNC_MEASURE_RELEASE_CONSUMED
        ? CJGUI_ASYNC_MEASURE_READY : CJGUI_ASYNC_MEASURE_CANCELLED;
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[slotIndex];
    slot->retiredGeneration = job.generation;
    slot->retiredDisposition = disposition;
    slot->retiredStatus = status;
    CjguiAsyncMeasureRetireIfUnownedLocked(slotIndex, job);
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return status;
}

#ifdef CJGUI_ASYNC_MULTILINE_MEASURE_TESTING
void CjguiAsyncMultilineMeasureTestCloseWorkerGate(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureTestGateClosed = YES;
    gCjguiAsyncMeasureTestWorkerAtGate = NO;
    gCjguiAsyncMeasureTestWorkerGateHandle = 0;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

int CjguiAsyncMultilineMeasureTestWaitForWorkerGate(uint32_t timeoutMs) {
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += timeoutMs / 1000;
    deadline.tv_nsec += (long)(timeoutMs % 1000) * 1000000l;
    if (deadline.tv_nsec >= 1000000000l) {
        deadline.tv_sec += 1;
        deadline.tv_nsec -= 1000000000l;
    }
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    int result = 0;
    while (!gCjguiAsyncMeasureTestWorkerAtGate && result == 0) {
        result = pthread_cond_timedwait(&gCjguiAsyncMeasureTestGateCondition,
            &gCjguiAsyncMeasureLock, &deadline);
    }
    BOOL reached = gCjguiAsyncMeasureTestWorkerAtGate;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return reached ? 1 : 0;
}

uint64_t CjguiAsyncMultilineMeasureTestWorkerGateHandle(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureHandle handle = gCjguiAsyncMeasureTestWorkerGateHandle;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return handle;
}

void CjguiAsyncMultilineMeasureTestOpenWorkerGate(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureTestGateClosed = NO;
    pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

void CjguiAsyncMultilineMeasureTestClosePrepareGate(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureTestPrepareGateClosed = YES;
    gCjguiAsyncMeasureTestPrepareAtGate = NO;
    gCjguiAsyncMeasureTestPreparingHandle = 0;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

int CjguiAsyncMultilineMeasureTestWaitForPrepareGate(uint32_t timeoutMs) {
    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += timeoutMs / 1000;
    deadline.tv_nsec += (long)(timeoutMs % 1000) * 1000000l;
    if (deadline.tv_nsec >= 1000000000l) {
        deadline.tv_sec += 1;
        deadline.tv_nsec -= 1000000000l;
    }
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    int result = 0;
    while (!gCjguiAsyncMeasureTestPrepareAtGate && result == 0) {
        result = pthread_cond_timedwait(&gCjguiAsyncMeasureTestGateCondition,
            &gCjguiAsyncMeasureLock, &deadline);
    }
    BOOL reached = gCjguiAsyncMeasureTestPrepareAtGate;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return reached ? 1 : 0;
}

uint64_t CjguiAsyncMultilineMeasureTestPreparingHandle(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureHandle handle = gCjguiAsyncMeasureTestPreparingHandle;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return handle;
}

int CjguiAsyncMultilineMeasureTestCancelPreparing(
    CjguiAsyncMultilineMeasureHandle handle) {
    NSUInteger index = NSNotFound;
    uint64_t generation = 0;
    if (!CjguiAsyncMeasureDecodeHandle(handle, &index, &generation)) return 0;
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureSlot *slot = &gCjguiAsyncMeasureSlots[index];
    BOOL cancelled = slot->preparing && slot->generation == generation;
    if (cancelled) slot->preparationCancelled = YES;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return cancelled ? 1 : 0;
}

void CjguiAsyncMultilineMeasureTestOpenPrepareGate(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureTestPrepareGateClosed = NO;
    pthread_cond_broadcast(&gCjguiAsyncMeasureTestGateCondition);
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

void CjguiAsyncMultilineMeasureTestFailNextPrepareAfterCopy(void) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    gCjguiAsyncMeasureTestFailNextPrepareAfterCopy = YES;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}

uint64_t CjguiAsyncMultilineMeasureTestServiceStartNs(
    CjguiAsyncMultilineMeasureHandle handle) {
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    CjguiAsyncMultilineMeasureJob *job = CjguiAsyncMeasureLookupLocked(
        handle, NULL, NULL);
    uint64_t serviceStartNs = job ? job.serviceStartNs : 0;
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
    return serviceStartNs;
}

void CjguiAsyncMultilineMeasureTestGetStats(CjguiAsyncMultilineMeasureTestStats *outStats) {
    if (!outStats) return;
    pthread_mutex_lock(&gCjguiAsyncMeasureLock);
    memset(outStats, 0, sizeof(*outStats));
    outStats->reservedInputBytes = gCjguiAsyncMeasureReservedBytes;
    outStats->genericReservedInputBytes = gCjguiAsyncMeasureGenericReservedBytes;
    outStats->smallTextReservedInputBytes = gCjguiAsyncMeasureSmallTextReservedBytes;
    outStats->preparedInputCopies = gCjguiAsyncMeasureTestPreparedInputCopies;
    outStats->preparedInputBytes = gCjguiAsyncMeasureTestPreparedInputBytes;
    outStats->preparedFontCopies = gCjguiAsyncMeasureTestPreparedFontCopies;
    outStats->preparedJobs = gCjguiAsyncMeasureTestPreparedJobs;
    outStats->layoutJobsStarted = gCjguiAsyncMeasureLayoutJobsStarted;
    outStats->layoutJobsCompleted = gCjguiAsyncMeasureLayoutJobsCompleted;
    for (NSUInteger index = 0; index < kCjguiAsyncMeasureSlotCount; index++) {
        if (gCjguiAsyncMeasureSlots[index].job || gCjguiAsyncMeasureSlots[index].preparing) {
            outStats->occupiedSlots += 1;
            if (index < kCjguiAsyncMeasureGenericSlotCount) outStats->genericSlots += 1;
            else outStats->smallTextSlots += 1;
        }
    }
    pthread_mutex_unlock(&gCjguiAsyncMeasureLock);
}
#endif
