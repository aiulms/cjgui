// Exact multiline height is a role-specific TextKit query. This test links the
// current production renderer and compares its scalar ABI with the same
// prepared stack used by the scene drawing path, including the insertion line.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

#include <stdio.h>

static NSString *repeatedLines(NSUInteger count) {
    NSMutableString *value = [NSMutableString string];
    for (NSUInteger index = 0; index < count; index++) {
        [value appendFormat:@"%lu 负载正文 行 🙂 0123456789\n", (unsigned long)index];
    }
    return value;
}

static BOOL checkHeightStyle(uint64_t token, NSString *value, uint32_t contentWidth,
                             uint32_t fontWeight, uint32_t fontFamily, const char *name) {
    uint32_t actual = 0;
    uint64_t started = CjguiMonotonicMicros();
    CjguiInternalRendererStatus status =
        cjgui_internal_renderer_measure_composable_multiline_natural_height(
            token, value.UTF8String, 13.0, fontWeight, fontFamily, contentWidth, &actual);
    uint64_t elapsed = CjguiMonotonicMicros() - started;
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode source = {0};
    source.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_MULTILINE_TEXT_INPUT;
    source.width = contentWidth + 14;
    source.height = 2000000;
    source.fontSize = 13.0;
    source.fontWeight = fontWeight;
    source.fontFamily = fontFamily;
    source.textAlpha = 1.0;
    node.node = source;
    CjguiPreparedTextNodeLayout *prepared = CjguiPrepareTextNodeLayout(node, value, 1.0);
    if (!prepared) return NO;
    [prepared.layoutManager ensureLayoutForTextContainer:prepared.container];
    NSRect used = [prepared.layoutManager usedRectForTextContainer:prepared.container];
    NSRect extra = prepared.layoutManager.extraLineFragmentRect;
    NSFont *font = CjguiComposableFontForStyle(13.0, fontWeight, fontFamily);
    CGFloat expectedHeight = MAX(1.0, font.ascender - font.descender + font.leading);
    expectedHeight = MAX(expectedHeight, NSMaxY(used));
    if (prepared.layoutManager.extraLineFragmentTextContainer == prepared.container &&
        !NSIsEmptyRect(extra)) expectedHeight = MAX(expectedHeight, NSMaxY(extra));
    uint32_t expected = (uint32_t)ceil(expectedHeight);
    BOOL complete = value.length == 0 || prepared.layoutManager.firstUnlaidCharacterIndex >= value.length;
    BOOL pass = status == CJGUI_INTERNAL_RENDERER_OK && actual == expected && complete;
    printf("NATURAL_HEIGHT case=%s utf16=%lu width=%u status=%d height=%u prepared=%u usedMaxY=%.3f extraMaxY=%.3f complete=%d elapsed_us=%llu pass=%d\n",
        name, (unsigned long)value.length, contentWidth, status, actual, expected,
        NSMaxY(used), NSMaxY(extra), complete, (unsigned long long)elapsed, pass);
    return pass;
}

static BOOL checkHeight(uint64_t token, NSString *value, uint32_t contentWidth, const char *name) {
    return checkHeightStyle(token, value, contentWidth, 0, 0, name);
}

int main(void) {
    @autoreleasepool {
        CJGuiInternalSession *session = [CJGuiInternalSession new];
        session.view = [CJGuiInternalMetalView new];
        uint64_t token = CjguiAllocateSession(session);
        if (!token) return 2;
        NSArray<NSString *> *values = @[
            @"", @"\n", @"abc\n", @"a\r\nb\r\n", @"中🙂e\u0301 שלום\txyz\u2028末尾",
            @"many ordinary words near a wrapping boundary are here and continue across lines"
        ];
        const char *names[] = {"empty", "newline", "trailing-newline", "crlf", "unicode-bidi-tab", "word-wrap"};
        BOOL pass = YES;
        for (NSUInteger index = 0; index < values.count; index++) {
            pass &= checkHeight(token, values[index], 72, names[index]);
            pass &= checkHeight(token, values[index], 320, names[index]);
        }
        pass &= checkHeightStyle(token, @"中🙂e\u0301 שלום\txyz\u2028末尾", 72, 1, 1, "unicode-monospaced-bold");
        CjguiInternalRendererTextMeasurement legacy = {0};
        CjguiInternalRendererStatus legacyStatus = cjgui_internal_renderer_measure_composable_text(
            token, values[5].UTF8String, 13.0, 0, 0, 72, &legacy);
        uint32_t wordHeight = 0;
        CjguiInternalRendererStatus wordStatus =
            cjgui_internal_renderer_measure_composable_multiline_natural_height(
                token, values[5].UTF8String, 13.0, 0, 0, 72, &wordHeight);
        printf("NATURAL_HEIGHT_ROLE_DIFFERENCE legacy_status=%d legacy_char_height=%u word_status=%d word_height=%u\n",
            legacyStatus, legacy.height, wordStatus, wordHeight);
        pass &= legacyStatus == CJGUI_INTERNAL_RENDERER_OK && wordStatus == CJGUI_INTERNAL_RENDERER_OK;
        pass &= checkHeight(token, repeatedLines(365), 320, "365-lines");
        pass &= checkHeight(token, repeatedLines(366), 320, "366-lines");
        pass &= checkHeight(token, repeatedLines(3700), 320, "3700-lines");
        NSMutableString *longLine = [NSMutableString stringWithCapacity:100000];
        for (NSUInteger index = 0; index < 10000; index++) [longLine appendString:@"abcdefghij"];
        pass &= checkHeight(token, longLine, 320, "100k-one-paragraph");
        session.forcedComposableMeasurementFailures = 1;
        uint32_t failedHeight = UINT32_MAX;
        CjguiInternalRendererStatus failed =
            cjgui_internal_renderer_measure_composable_multiline_natural_height(
                token, "failure then recovery", 13.0, 0, 0, 320, &failedHeight);
        BOOL rejected = failed == CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR && failedHeight == 0;
        BOOL recovered = checkHeight(token, @"failure then recovery", 320, "recovery");
        printf("NATURAL_HEIGHT_FAILURE rejected=%d recovered=%d\n", rejected, recovered);
        pass &= rejected && recovered;
        CjguiReleaseSession(token);
        return pass ? 0 : 1;
    }
}
