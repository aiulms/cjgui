#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

@interface ColdTextPrepWindow : NSWindow
@property(nonatomic, strong) NSResponder *recordedResponder;
@end
@implementation ColdTextPrepWindow
- (NSResponder *)firstResponder { return self.recordedResponder; }
- (BOOL)makeFirstResponder:(NSResponder *)responder { self.recordedResponder = responder; return YES; }
- (BOOL)isKeyWindow { return NO; }
- (BOOL)isVisible { return NO; }
- (CGFloat)backingScaleFactor { return 2.0; }
@end

@interface ColdTextPrepOverlay : CJGuiInternalComposableSceneOverlay
@property(nonatomic, strong) ColdTextPrepWindow *recordedWindow;
@end
@implementation ColdTextPrepOverlay
- (NSWindow *)window { return self.recordedWindow; }
@end

static int failures;
#define CHECK(c, label) do { \
    BOOL ok = (c); \
    fprintf(stderr, "cold_text_prepare case=%s result=%s\n", label, ok ? "PASS" : "FAIL"); \
    if (!ok) failures++; \
} while (0)

static CjguiInternalRendererStatus fillAcceptedInput(uint64_t token, uint64_t preparationId,
                                                     uint64_t projectionVersion) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 501; raw.resourceId = 1; raw.projectionVersion = projectionVersion;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    raw.isInteractive = 1; raw.width = 680; raw.height = 915;
    raw.clipWidth = 680; raw.clipHeight = 689; raw.fontSize = 18;
    raw.fontWeight = 400; raw.textAlpha = 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = 501;
    return cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &raw, &geometry,
        "", "accepted input 🙂", "accepted-input", "binding-501", "", "", "accepted input", "");
}

static CjguiInternalRendererStatus fillColdTextWithRuns(uint64_t token, uint64_t preparationId,
    uint64_t projectionVersion, NSString *body, const char *runs) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 777; raw.resourceId = 7; raw.projectionVersion = projectionVersion;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 680; raw.height = 8000; raw.clipWidth = 680; raw.clipHeight = 689;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = 777;
    return cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &raw, &geometry,
        "", body.UTF8String, "cold-text", "binding-777", "", "", "cold text", runs ?: "");
}

static CjguiInternalRendererStatus fillColdTextAtWidth(uint64_t token, uint64_t preparationId,
    uint64_t projectionVersion, NSString *body, double width) {
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 777; raw.resourceId = 7; raw.projectionVersion = projectionVersion;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = width; raw.height = 8000; raw.clipWidth = width; raw.clipHeight = 689;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = 777;
    return cjgui_internal_renderer_prepare_composable_node(token, preparationId, 0, &raw, &geometry,
        "", body.UTF8String, "cold-text", "binding-777", "", "", "cold text", "");
}

static CjguiInternalRendererStatus fillColdText(uint64_t token, uint64_t preparationId,
                                                uint64_t projectionVersion, NSString *body) {
    return fillColdTextWithRuns(token, preparationId, projectionVersion, body, "");
}

static BOOL closeRect(NSRect a, NSRect b) {
    return fabs(NSMinX(a) - NSMinX(b)) < 0.01 && fabs(NSMinY(a) - NSMinY(b)) < 0.01 &&
        fabs(NSWidth(a) - NSWidth(b)) < 0.01 && fabs(NSHeight(a) - NSHeight(b)) < 0.01;
}

static NSUInteger findSoftWrapCharacterIndex(NSLayoutManager *layout, NSString *body) {
    __block NSUInteger result = NSNotFound;
    NSUInteger glyphCount = layout.numberOfGlyphs;
    if (glyphCount == 0) return result;
    [layout enumerateLineFragmentsForGlyphRange:NSMakeRange(0, glyphCount)
        usingBlock:^(NSRect lineRect, NSRect usedRect, NSTextContainer *container, NSRange glyphRange, BOOL *stop) {
        (void)lineRect; (void)usedRect; (void)container;
        NSRange characters = [layout characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
        NSUInteger start = characters.location;
        if (start > 0 && start < body.length && [body characterAtIndex:start - 1] != '\n' &&
            [body characterAtIndex:start - 1] != '\r') {
            result = start;
            *stop = YES;
        }
    }];
    return result;
}

static BOOL insertionPointsMatch(NSLayoutManager *candidate, NSLayoutManager *oracle,
    NSUInteger characterIndex, BOOL alternatePositions, NSString *graphName, NSString *fixtureName) {
    NSUInteger candidateCount = 0, oracleCount = 0;
    CGFloat *candidatePositions = NULL, *oraclePositions = NULL;
    NSUInteger *candidateIndexes = NULL, *oracleIndexes = NULL;
    CjguiInternalRendererStatus candidateStatus = CjguiReadLineInsertionPointsEx(candidate,
        characterIndex, alternatePositions, &candidateCount, &candidatePositions, &candidateIndexes);
    CjguiInternalRendererStatus oracleStatus = CjguiReadLineInsertionPointsEx(oracle,
        characterIndex, alternatePositions, &oracleCount, &oraclePositions, &oracleIndexes);
    BOOL matches = candidateStatus == CJGUI_INTERNAL_RENDERER_OK &&
        oracleStatus == CJGUI_INTERNAL_RENDERER_OK && candidateCount == oracleCount;
    NSUInteger firstDifferent = NSNotFound;
    NSUInteger commonCount = MIN(candidateCount, oracleCount);
    for (NSUInteger i = 0; matches && i < commonCount; i++) {
        if (candidateIndexes[i] != oracleIndexes[i] ||
            fabs(candidatePositions[i] - oraclePositions[i]) >= 0.01) {
            matches = NO;
            firstDifferent = i;
        }
    }
    if (!matches) {
        fprintf(stderr, "COLD_TEXT_INSERTION_DIFF fixture=%s graph=%s mode=%s char=%lu "
            "candidate_status=%d count=%lu oracle_status=%d count=%lu first_diff=%s",
            fixtureName.UTF8String, graphName.UTF8String,
            alternatePositions ? "primary_alternates" : "primary_only", (unsigned long)characterIndex,
            candidateStatus, (unsigned long)candidateCount, oracleStatus, (unsigned long)oracleCount,
            firstDifferent == NSNotFound ? "none" : "present");
        if (firstDifferent != NSNotFound)
            fprintf(stderr, " index=%lu candidate=(%lu,%.6f) oracle=(%lu,%.6f)",
                (unsigned long)firstDifferent, (unsigned long)candidateIndexes[firstDifferent],
                candidatePositions[firstDifferent], (unsigned long)oracleIndexes[firstDifferent],
                oraclePositions[firstDifferent]);
        fprintf(stderr, "\n");
    }
    free(candidatePositions); free(candidateIndexes);
    free(oraclePositions); free(oracleIndexes);
    return matches;
}

static BOOL comparePositionMapping(NSLayoutManager *candidate, NSTextContainer *candidateContainer,
    NSLayoutManager *oracle, NSTextContainer *oracleContainer, NSString *body, NSUInteger characterIndex,
    NSString *graphName, NSString *fixtureName, NSString *sampleName) {
    if (characterIndex >= body.length) return NO;
    NSRange composed = [body rangeOfComposedCharacterSequenceAtIndex:characterIndex];
    NSRange candidateGlyphs = [candidate glyphRangeForCharacterRange:composed actualCharacterRange:NULL];
    NSRange oracleGlyphs = [oracle glyphRangeForCharacterRange:composed actualCharacterRange:NULL];
    if (candidateGlyphs.length == 0 || oracleGlyphs.length == 0) return NO;
    NSRect candidateGlyphRect = [candidate boundingRectForGlyphRange:candidateGlyphs
        inTextContainer:candidateContainer];
    NSRect oracleGlyphRect = [oracle boundingRectForGlyphRange:oracleGlyphs inTextContainer:oracleContainer];
    NSRect candidateLineRect = [candidate lineFragmentRectForGlyphAtIndex:candidateGlyphs.location
        effectiveRange:NULL];
    NSRect oracleLineRect = [oracle lineFragmentRectForGlyphAtIndex:oracleGlyphs.location
        effectiveRange:NULL];
    BOOL primaryMatch = insertionPointsMatch(candidate, oracle, characterIndex, NO, graphName, fixtureName);
    BOOL primaryAndAlternateMatch = insertionPointsMatch(candidate, oracle, characterIndex, YES,
        graphName, fixtureName);
    BOOL rangeMatch = NSEqualRanges(candidateGlyphs, oracleGlyphs);
    BOOL glyphRectMatch = closeRect(candidateGlyphRect, oracleGlyphRect);
    BOOL lineRectMatch = closeRect(candidateLineRect, oracleLineRect);
    BOOL matches = rangeMatch && glyphRectMatch && lineRectMatch && primaryMatch && primaryAndAlternateMatch;
    fprintf(stderr, "COLD_TEXT_POSITION fixture=%s graph=%s sample=%s char=%lu glyph=%lu:%lu "
        "glyphRect=(%.3f,%.3f,%.3f,%.3f) lineRect=(%.3f,%.3f,%.3f,%.3f) "
        "range=%s glyphRectMatch=%s lineRectMatch=%s primary=%s alternateSet=%s result=%s\n",
        fixtureName.UTF8String, graphName.UTF8String,
        sampleName.UTF8String, (unsigned long)characterIndex, (unsigned long)candidateGlyphs.location,
        (unsigned long)candidateGlyphs.length, NSMinX(candidateGlyphRect), NSMinY(candidateGlyphRect),
        NSWidth(candidateGlyphRect), NSHeight(candidateGlyphRect), NSMinX(candidateLineRect),
        NSMinY(candidateLineRect), NSWidth(candidateLineRect), NSHeight(candidateLineRect),
        rangeMatch ? "match" : "DIFF", glyphRectMatch ? "match" : "DIFF",
        lineRectMatch ? "match" : "DIFF",
        primaryMatch ? "match" : "DIFF", primaryAndAlternateMatch ? "match" : "DIFF",
        matches ? "PASS" : "DIFF");
    return matches;
}

static BOOL compareSampledPositionMapping(CjguiPreparedTextNodeLayout *candidateSource,
    CjguiPreparedTextNodeLayout *candidatePainter, CjguiPreparedTextNodeLayout *mainThreadOracle,
    NSString *body, NSString *fixtureName) {
    NSUInteger softWrap = findSoftWrapCharacterIndex(mainThreadOracle.layoutManager, body);
    if (softWrap == NSNotFound) {
        fprintf(stderr, "COLD_TEXT_POSITION fixture=%s soft_wrap=NOT_FOUND result=FAIL\n",
            fixtureName.UTF8String);
        return NO;
    }
    NSUInteger rawIndexes[] = {0, body.length / 2, body.length - 1, softWrap};
    NSString *sampleNames[] = {@"head", @"middle", @"tail", @"soft_wrap"};
    BOOL allMatch = YES;
    for (NSUInteger sample = 0; sample < sizeof(rawIndexes) / sizeof(rawIndexes[0]); sample++) {
        NSUInteger index = rawIndexes[sample];
        if (index >= body.length) index = body.length - 1;
        index = [body rangeOfComposedCharacterSequenceAtIndex:index].location;
        allMatch = comparePositionMapping(candidateSource.layoutManager, candidateSource.container,
            mainThreadOracle.layoutManager, mainThreadOracle.container, body, index, @"source", fixtureName,
            sampleNames[sample]) && allMatch;
        allMatch = comparePositionMapping(candidatePainter.layoutManager, candidatePainter.container,
            mainThreadOracle.layoutManager, mainThreadOracle.container, body, index, @"painter", fixtureName,
            sampleNames[sample]) && allMatch;
    }
    fprintf(stderr, "COLD_TEXT_POSITION_SUMMARY fixture=%s soft_wrap_char=%lu samples=4 result=%s\n",
        fixtureName.UTF8String, (unsigned long)softWrap, allMatch ? "PASS" : "FAIL");
    return allMatch;
}

static BOOL makeSession(CJGuiInternalSession **outSession, uint64_t *outToken) {
    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!ctx || !device) return NO;
    ctx.view = [[CJGuiInternalMetalView alloc] initWithFrame:NSMakeRect(0, 0, 680, 689)
        device:device commandQueue:[device newCommandQueue]];
    ColdTextPrepOverlay *overlay = [[ColdTextPrepOverlay alloc] initWithFrame:ctx.view.bounds session:ctx];
    overlay.recordedWindow = [[ColdTextPrepWindow alloc] initWithContentRect:ctx.view.bounds
        styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
    overlay.recordedWindow.releasedWhenClosed = NO;
    overlay.recordedWindow.contentView = overlay;
    ctx.window = overlay.recordedWindow;
    ctx.composableSceneOverlay = overlay;
    ctx.composableNodes = [NSMutableArray array];
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneNode *accepted = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode oldRaw = {0};
    oldRaw.nodeId = 501; oldRaw.resourceId = 1; oldRaw.projectionVersion = 1;
    oldRaw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    oldRaw.isInteractive = 1; oldRaw.width = 680; oldRaw.height = 915;
    oldRaw.clipWidth = 680; oldRaw.clipHeight = 689; oldRaw.fontSize = 18;
    oldRaw.fontWeight = 400; oldRaw.textAlpha = 1;
    accepted.node = oldRaw; accepted.value = @"accepted input 🙂";
    accepted.semanticId = @"accepted-input"; accepted.semanticBindingKey = @"binding-501";
    ctx.stagedComposableNodes = [NSMutableArray arrayWithObject:accepted];
    ctx.stagedComposableSceneVersion = 1;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 1;
    uint64_t token = CjguiAllocateSession(ctx);
    if (!token) return NO;
    ctx.view.sessionToken = token;
    if (CjguiCommitComposableSceneOnMain(token) != CJGUI_INTERNAL_RENDERER_OK) return NO;
    [overlay setNodesFromProjection:ctx.view.composableNodes];
    *outSession = ctx; *outToken = token;
    return YES;
}

static BOOL installAcceptedColdTextScene(CJGuiInternalSession *ctx, NSString *body) {
    if (!ctx || !body) return NO;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 777; raw.resourceId = 7; raw.projectionVersion = 2;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 680; raw.height = 8000; raw.clipWidth = 680; raw.clipHeight = 689;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = 777;
    node.node = raw; node.geometry = geometry; node.value = body;
    node.semanticId = @"cold-text"; node.semanticBindingKey = @"binding-777";
    ctx.stagedComposableNodes = [NSMutableArray arrayWithObject:node];
    ctx.stagedComposableSceneVersion = 2;
    ctx.stagedComposableDataTransferItems = [NSMutableArray array];
    ctx.stagedComposableDataTransferVersion = 2;
    return CjguiCommitComposableSceneOnMain(ctx.rendererSessionToken) == CJGUI_INTERNAL_RENDERER_OK;
}

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
        CjguiTextPreparationTestCloseWorkerGate();
        CJGuiInternalSession *ctx = nil; uint64_t token = 0;
        if (!makeSession(&ctx, &token)) return 2;

        NSMutableString *oneParagraph = [NSMutableString stringWithCapacity:16384];
        for (NSUInteger i = 0; i < 16384; i++) [oneParagraph appendString:@"a"];
        const uint64_t preparationId = 71;
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token, preparationId, 1, 2, 1) ==
            CJGUI_INTERNAL_RENDERER_OK && fillColdText(token, preparationId, 2, oneParagraph) ==
            CJGUI_INTERNAL_RENDERER_OK, "begin_real_cold_16k_scene_preparation");

        uint32_t ready = 0;
        uint64_t phase0StartedMicros = CjguiMonotonicMicros();
        CjguiInternalRendererStatus status = cjgui_internal_renderer_advance_composable_preparation(
            token, preparationId, 0, &ready);
        uint64_t phase0ServiceMicros = CjguiMonotonicMicros() - phase0StartedMicros;
        CjguiComposablePreparation *preparation = ctx.composablePreparation;
        CjguiTextPreparationWorkerJob *asciiJob = preparation.textLayoutJob;
        CjguiTextPreparationWorkerInput *asciiInput = asciiJob.input;
        CJGuiInternalComposableSceneNode *candidateNode = preparation.nodes.firstObject;
        uint64_t extentCalls = candidateNode.testTextExtentMeasurementCount;
        fprintf(stderr, "COLD_TEXT_PHASE0 status=%d ready=%u utf16=%lu extent_calls=%llu phase=%lu\n",
            status, ready, (unsigned long)oneParagraph.length,
            (unsigned long long)extentCalls, (unsigned long)preparation.phase);
        BOOL reachedGate = CjguiTextPreparationTestWaitForWorkerGate(3000);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready && extentCalls == 0 && reachedGate,
            "phase0_yields_without_sync_full_textkit_extent");
        fprintf(stderr, "COLD_TEXT_TIMING case=ascii16k phase0_service_us=%llu full_owner_turn=not_measured first_present=not_measured\n",
            (unsigned long long)phase0ServiceMicros);
        CJGuiInternalSession *ctx2 = nil; uint64_t token2 = 0;
        if (!makeSession(&ctx2, &token2)) return 2;
        const uint64_t shortPreparationId = 76;
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token2, shortPreparationId, 1, 7, 1) ==
            CJGUI_INTERNAL_RENDERER_OK && fillColdText(token2, shortPreparationId, 7, @"short synchronous control") ==
            CJGUI_INTERNAL_RENDERER_OK, "begin_short_text_negative_control");
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token2, shortPreparationId, 0, &ready);
        CjguiComposablePreparation *shortPreparation = ctx2.composablePreparation;
        CJGuiInternalComposableSceneNode *shortNode = shortPreparation.nodes.firstObject;
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && shortPreparation.textLayoutJob == nil &&
            shortNode.testTextExtentMeasurementCount == 1 && shortPreparation.phase == 1,
            "short_text_stays_on_existing_synchronous_layout_path");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token2, shortPreparationId);
        CjguiRetireComposablePreparationUnit(ctx2);
        CjguiRetireComposablePreparationUnit(ctx2);
        NSMutableString *multilineUnicode = [NSMutableString stringWithCapacity:4096];
        for (NSUInteger i = 0; i < 128; i++) [multilineUnicode appendString:@"界🙂 mixed line\n"];
        const uint64_t preparationId2 = 72;
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token2, preparationId2, 1, 3, 1) ==
            CJGUI_INTERNAL_RENDERER_OK && fillColdTextAtWidth(token2, preparationId2, 3, multilineUnicode, 120) ==
            CJGUI_INTERNAL_RENDERER_OK, "begin_real_multiline_unicode_candidate");
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token2, preparationId2, 0, &ready);
        CjguiTextPreparationWorkerJob *multilineJob = ctx2.composablePreparation.textLayoutJob;
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready &&
            ctx2.composablePreparation.nodes.firstObject.testTextExtentMeasurementCount == 0,
            "multiline_unicode_enters_worker_without_sync_extent");
        BOOL twoSlotsOccupied = NO;
        for (NSUInteger attempt = 0; attempt < 300; attempt++) {
            pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
            twoSlotsOccupied = gCjguiTextPreparationWorkerSlots[0] != nil &&
                gCjguiTextPreparationWorkerSlots[1] != nil &&
                gCjguiTextPreparationWorkerSlots[0].workerLive &&
                gCjguiTextPreparationWorkerSlots[1].workerLive;
            pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
            if (twoSlotsOccupied) break;
            struct timespec delay = {.tv_sec = 0, .tv_nsec = 1000000L}; nanosleep(&delay, NULL);
        }
        CHECK(twoSlotsOccupied, "worker_slots_charge_until_worker_exit");

        CJGuiInternalSession *ctx3 = nil; uint64_t token3 = 0;
        if (!makeSession(&ctx3, &token3)) return 2;
        NSMutableString *thirdBody = [NSMutableString stringWithCapacity:2048];
        for (NSUInteger i = 0; i < 128; i++) [thirdBody appendString:@"capacity line text\n"];
        const uint64_t preparationId3 = 73;
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token3, preparationId3, 1, 4, 1) ==
            CJGUI_INTERNAL_RENDERER_OK && fillColdText(token3, preparationId3, 4, thirdBody) ==
            CJGUI_INTERNAL_RENDERER_OK, "begin_waiting_capacity_candidate");
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token3, preparationId3, 0, &ready);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && !ready &&
            ctx3.composablePreparation.textLayoutWaitTicket != 0 &&
            ctx3.composablePreparation.textLayoutJob == nil,
            "full_worker_capacity_keeps_third_candidate_waiting");

        CjguiTextPreparationTestOpenWorkerGate();
        CHECK(CjguiTextPreparationTestWaitForFinished(10000), "both_preparation_workers_finish_before_adoption");

        BOOL adoptedAscii = NO;
        uint64_t asciiAdoptionPollMicros = 0;
        for (NSUInteger attempt = 0; attempt < 10000; attempt++) {
            uint64_t pollStarted = CjguiMonotonicMicros();
            ready = 0;
            status = cjgui_internal_renderer_advance_composable_preparation(token, preparationId, 0, &ready);
            uint64_t pollElapsed = CjguiMonotonicMicros() - pollStarted;
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (preparation.phase == 2) { adoptedAscii = YES; asciiAdoptionPollMicros = pollElapsed; break; }
            struct timespec delay = {.tv_sec = 0, .tv_nsec = 1000000L}; nanosleep(&delay, NULL);
        }
        NSRect asciiOracleRect = [oneParagraph boundingRectWithSize:
            NSMakeSize(NSWidth(asciiInput.textRect), CGFLOAT_MAX / 4.0)
            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
            attributes:asciiInput.extentAttributes];
        BOOL asciiGeometryMatches = adoptedAscii && candidateNode.textMeasureValid &&
            fabs(candidateNode.textMeasuredExtent.height - asciiOracleRect.size.height) < 0.01 &&
            preparation.sourceLayout.layoutManager.firstUnlaidCharacterIndex >= oneParagraph.length &&
            preparation.painter.layoutManager.firstUnlaidCharacterIndex >= oneParagraph.length;
        CHECK(asciiGeometryMatches, "ascii16k_extent_matches_oracle_and_both_graphs_are_complete");
        CjguiPreparedTextNodeLayout *asciiMainOracle = CjguiPrepareTextNodeLayout(candidateNode,
            oneParagraph, asciiInput.scale, nil, ctx);
        if (asciiMainOracle)
            [asciiMainOracle.layoutManager ensureLayoutForTextContainer:asciiMainOracle.container];
        BOOL asciiPositionMappingMatches = asciiMainOracle && adoptedAscii && compareSampledPositionMapping(
            preparation.sourceLayout, preparation.painter, asciiMainOracle, oneParagraph, @"ascii16k");
        CHECK(asciiPositionMappingMatches, "ascii16k_source_and_painter_position_mapping_matches_sync_oracle");
        fprintf(stderr, "COLD_TEXT_TIMING case=ascii16k phase0_us=%llu worker_us=%llu adoption_poll_us=%llu extent_h=%.3f oracle_h=%.3f source_first_unlaid=%lu painter_first_unlaid=%lu\n",
            (unsigned long long)phase0ServiceMicros,
            (unsigned long long)(asciiJob.workerCompletedMicros - asciiJob.workerStartedMicros),
            (unsigned long long)asciiAdoptionPollMicros,
            candidateNode.textMeasuredExtent.height, asciiOracleRect.size.height,
            (unsigned long)preparation.sourceLayout.layoutManager.firstUnlaidCharacterIndex,
            (unsigned long)preparation.painter.layoutManager.firstUnlaidCharacterIndex);
        NSUInteger asciiTileBefore = preparation.tileCursor;
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token, preparationId, 0, &ready);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && preparation.tileCursor > asciiTileBefore &&
            candidateNode.testTextExtentMeasurementCount == 0 &&
            preparation.painter.layoutManager.firstUnlaidCharacterIndex >= oneParagraph.length,
            "ascii16k_tile_uses_transferred_complete_painter_without_second_extent");

        BOOL adoptedMultiline = NO;
        uint64_t multilineAdoptionPollMicros = 0;
        for (NSUInteger attempt = 0; attempt < 10000; attempt++) {
            uint64_t pollStarted = CjguiMonotonicMicros();
            ready = 0;
            status = cjgui_internal_renderer_advance_composable_preparation(token2, preparationId2, 0, &ready);
            uint64_t pollElapsed = CjguiMonotonicMicros() - pollStarted;
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (ctx2.composablePreparation.phase == 2) {
                adoptedMultiline = YES; multilineAdoptionPollMicros = pollElapsed; break;
            }
            struct timespec delay = {.tv_sec = 0, .tv_nsec = 1000000L}; nanosleep(&delay, NULL);
        }
        CjguiComposablePreparation *preparedMultiline = ctx2.composablePreparation;
        CJGuiInternalComposableSceneNode *multilineNode = preparedMultiline.nodes.firstObject;
        NSFont *oracleFont = CjguiComposableFont(multilineNode);
        NSMutableParagraphStyle *oracleParagraph = [NSMutableParagraphStyle new];
        oracleParagraph.lineBreakMode = NSLineBreakByWordWrapping;
        oracleParagraph.lineBreakStrategy = NSLineBreakStrategyPushOut;
        NSDictionary *oracleAttributes = @{NSFontAttributeName: oracleFont,
            NSParagraphStyleAttributeName: oracleParagraph};
        CGFloat oracleHeight = [multilineUnicode boundingRectWithSize:NSMakeSize(
            NSWidth(preparedMultiline.sourceLayout.textRect), CGFLOAT_MAX / 4.0)
            options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
            attributes:oracleAttributes].size.height;
        BOOL geometryMatches = adoptedMultiline && multilineNode.textMeasureValid &&
            fabs(multilineNode.textMeasuredExtent.height - oracleHeight) < 0.01 &&
            preparedMultiline.sourceLayout.layoutManager.firstUnlaidCharacterIndex >= multilineUnicode.length &&
            preparedMultiline.painter.layoutManager.firstUnlaidCharacterIndex >= multilineUnicode.length;
        CHECK(geometryMatches, "multiline_unicode_extent_matches_geometry_oracle_and_both_graphs_complete");
        CjguiPreparedTextNodeLayout *unicodeMainOracle = CjguiPrepareTextNodeLayout(multilineNode,
            multilineUnicode, preparedMultiline.scale, nil, ctx2);
        if (unicodeMainOracle)
            [unicodeMainOracle.layoutManager ensureLayoutForTextContainer:unicodeMainOracle.container];
        BOOL unicodePositionMappingMatches = unicodeMainOracle && adoptedMultiline && compareSampledPositionMapping(
            preparedMultiline.sourceLayout, preparedMultiline.painter, unicodeMainOracle,
            multilineUnicode, @"multiline_unicode");
        CHECK(unicodePositionMappingMatches,
            "multiline_unicode_source_and_painter_position_mapping_matches_sync_oracle");
        fprintf(stderr, "COLD_TEXT_TIMING case=multiline_unicode worker_us=%llu adoption_poll_us=%llu extent_h=%.3f oracle_h=%.3f source_first_unlaid=%lu painter_first_unlaid=%lu\n",
            (unsigned long long)(multilineJob.workerCompletedMicros - multilineJob.workerStartedMicros),
            (unsigned long long)multilineAdoptionPollMicros,
            multilineNode.textMeasuredExtent.height, oracleHeight,
            (unsigned long)preparedMultiline.sourceLayout.layoutManager.firstUnlaidCharacterIndex,
            (unsigned long)preparedMultiline.painter.layoutManager.firstUnlaidCharacterIndex);
        NSUInteger tileCursorBefore = preparedMultiline.tileCursor;
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token2, preparationId2, 0, &ready);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && preparedMultiline.tileCursor > tileCursorBefore &&
            multilineNode.testTextExtentMeasurementCount == 0 &&
            preparedMultiline.painter.layoutManager.firstUnlaidCharacterIndex >= multilineUnicode.length,
            "adopted_painter_tiles_without_second_full_extent_layout");

        BOOL thirdStarted = NO;
        for (NSUInteger attempt = 0; attempt < 10000; attempt++) {
            ready = 0;
            status = cjgui_internal_renderer_advance_composable_preparation(token3, preparationId3, 0, &ready);
            if (status != CJGUI_INTERNAL_RENDERER_OK) break;
            if (ctx3.composablePreparation.textLayoutJob != nil) { thirdStarted = YES; break; }
            struct timespec delay = {.tv_sec = 0, .tv_nsec = 1000000L}; nanosleep(&delay, NULL);
        }
        CHECK(thirdStarted, "waiting_candidate_admitted_after_real_worker_retirement");

        if (ctx2.composablePreparation)
            (void)cjgui_internal_renderer_cancel_composable_preparation(token2, preparationId2);
        if (ctx3.composablePreparation)
            (void)cjgui_internal_renderer_cancel_composable_preparation(token3, preparationId3);
        CHECK(CjguiTextPreparationTestWaitForFinished(10000), "third_worker_retires_before_graph_discard_probe");
        for (NSUInteger attempt = 0; attempt < 4; attempt++) {
            CjguiRetireComposablePreparationUnit(ctx2);
            CjguiRetireComposablePreparationUnit(ctx3);
        }

        CJGuiInternalSession *ctx4 = nil; uint64_t token4 = 0;
        if (!makeSession(&ctx4, &token4)) return 2;
        NSMutableString *discardBody = [NSMutableString stringWithCapacity:1200];
        for (NSUInteger i = 0; i < 128; i++) [discardBody appendString:@"discard graph line\n"];
        const uint64_t preparationId4 = 74;
        CHECK(cjgui_internal_renderer_begin_composable_preparation(token4, preparationId4, 1, 5, 1) ==
            CJGUI_INTERNAL_RENDERER_OK && fillColdText(token4, preparationId4, 5, discardBody) ==
            CJGUI_INTERNAL_RENDERER_OK, "begin_worker_graph_retirement_probe");
        CjguiTextPreparationTestClosePublicationGate();
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token4, preparationId4, 0, &ready);
        BOOL reachedPublication = CjguiTextPreparationTestWaitForPublicationGate(10000);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && reachedPublication &&
            gCjguiTextPreparationTestWeakSourceLayout != nil &&
            gCjguiTextPreparationTestWeakPainter != nil,
            "worker_built_both_graphs_before_candidate_publication");
        ctx4.composableSceneVersion = 2;
        uint32_t staleReady = 0;
        CjguiInternalRendererStatus staleStatus = cjgui_internal_renderer_advance_composable_preparation(
            token4, preparationId4, 0, &staleReady);
        ctx4.composableSceneVersion = 1;
        CHECK(staleStatus == CJGUI_INTERNAL_RENDERER_SCENE_STALE && !staleReady,
            "scene_version_change_rejects_built_worker_graph_before_adoption");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token4, preparationId4);
        pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
        BOOL graphJobStillCharged = NO;
        CjguiTextPreparationWorkerJob *graphJob = nil;
        for (NSUInteger index = 0; index < CjguiTextPreparationWorkerSlotCount; index++) {
            CjguiTextPreparationWorkerJob *candidate = gCjguiTextPreparationWorkerSlots[index];
            if (candidate && candidate.input.preparationId == preparationId4) {
                graphJob = candidate;
                graphJobStillCharged = candidate.workerLive && candidate.cancelled &&
                    candidate.reservedBytes > 0;
            }
        }
        pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
        CHECK(graphJobStillCharged, "cancel_keeps_built_graph_charge_until_worker_drops_locals");
        CjguiTextPreparationTestOpenPublicationGate();
        CHECK(CjguiTextPreparationTestWaitForFinished(10000), "cancelled_graph_worker_exits");
        pthread_mutex_lock(&gCjguiTextPreparationWorkerLock);
        BOOL graphsDroppedBeforeSlotRelease = gCjguiTextPreparationTestDiscardedGraphsReleased &&
            gCjguiTextPreparationTestWeakSourceLayout == nil &&
            gCjguiTextPreparationTestWeakPainter == nil && graphJob.reservedBytes == 0;
        pthread_mutex_unlock(&gCjguiTextPreparationWorkerLock);
        CHECK(graphsDroppedBeforeSlotRelease,
            "cancel_drops_both_private_graphs_before_releasing_resource_charge");
        CjguiRetireComposablePreparationUnit(ctx4);
        CjguiRetireComposablePreparationUnit(ctx4);

        CHECK(installAcceptedColdTextScene(ctx4, oneParagraph),
            "install_accepted_long_text_with_real_prepared_layout_and_tiles");
        CJGuiInternalComposableSceneNode *acceptedLongNode = ctx4.composableNodes.firstObject;
        CjguiPreparedTextNodeLayout *acceptedLongLayout = acceptedLongNode.preparedTextLayout;
        uint64_t acceptedMeasureCalls = acceptedLongNode.testTextExtentMeasurementCount;
        const uint64_t warmPreparationId = 77;
        const char *selectionOnlyRun = "0:4:18:400:0:1:0:0:1:1:1:1:0:1:1";
        CHECK(acceptedLongLayout != nil && acceptedLongNode.textTextureByteCount > 0 &&
            cjgui_internal_renderer_begin_composable_preparation(token4, warmPreparationId, 2, 3, 1) ==
                CJGUI_INTERNAL_RENDERER_OK &&
            fillColdTextWithRuns(token4, warmPreparationId, 3, oneParagraph, selectionOnlyRun) ==
                CJGUI_INTERNAL_RENDERER_OK,
            "begin_long_text_selection_only_candidate_from_accepted_scene");
        ready = 0;
        status = cjgui_internal_renderer_advance_composable_preparation(token4, warmPreparationId, 0, &ready);
        CjguiComposablePreparation *warmPreparation = ctx4.composablePreparation;
        CJGuiInternalComposableSceneNode *warmNode = warmPreparation.nodes.firstObject;
        fprintf(stderr, "COLD_TEXT_WARM status=%d worker=%d same_layout=%d measure_calls=%llu\n",
            status, warmPreparation.textLayoutJob != nil,
            warmNode.preparedTextLayout == acceptedLongLayout,
            (unsigned long long)warmNode.testTextExtentMeasurementCount);
        CHECK(status == CJGUI_INTERNAL_RENDERER_OK && warmPreparation.textLayoutJob == nil &&
            warmNode.preparedTextLayout == acceptedLongLayout &&
            warmNode.testTextExtentMeasurementCount == acceptedMeasureCalls && warmPreparation.nodeCursor == 1,
            "accepted_long_text_reuses_layout_and_tiles_without_new_worker_or_measurement");
        (void)cjgui_internal_renderer_cancel_composable_preparation(token4, warmPreparationId);
        CjguiRetireComposablePreparationUnit(ctx4);
        CjguiRetireComposablePreparationUnit(ctx4);

        (void)cjgui_internal_renderer_destroy(token);
        (void)cjgui_internal_renderer_destroy(token2);
        (void)cjgui_internal_renderer_destroy(token3);
        (void)cjgui_internal_renderer_destroy(token4);
    }
    return failures ? 1 : 0;
}
