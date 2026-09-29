// The normal renderer must read an advancing caret clock even though its
// TESTING-only interval probe clock is intentionally compiled out.
#import "../cjgui_internal_renderer.m"

#include <stdio.h>
#include <unistd.h>

int main(void) {
    @autoreleasepool {
        CJGuiInternalComposableSceneOverlay *overlay =
            [[CJGuiInternalComposableSceneOverlay alloc] initWithFrame:NSZeroRect session:nil];
        uint64_t first = [overlay caretBlinkNowMicros];
        usleep(2000);
        uint64_t second = [overlay caretBlinkNowMicros];
        if (first == 0 || second <= first) {
            fprintf(stderr, "caret blink release clock did not advance: %llu -> %llu\n",
                    (unsigned long long)first, (unsigned long long)second);
            return 1;
        }
        puts("caret blink release clock advanced");
    }
    return 0;
}
