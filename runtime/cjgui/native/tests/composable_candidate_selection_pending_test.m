// Separate fault-injection fixture. Normal production projection tests are
// compiled without this flag. Actual Metal/AppKit preparation and receipts
// still run; only the existing Present hold and ACK transport are controlled.
#define CJGUI_INTERNAL_TESTING 1
#define CJGUI_CANDIDATE_NO_MAIN 1
#import "composable_candidate_selection_projection_test.m"
int main(void) {
    @autoreleasepool {
        id<MTLDevice> device=MTLCreateSystemDefaultDevice();
        if (!device) return 77;
        TestPrivateCandidateTarget(device,3);
        TestPrivateCandidateTarget(device,4);
        fprintf(stderr,"candidate pending failures=%d\n",failures);
        return failures ? 1 : 0;
    }
}
