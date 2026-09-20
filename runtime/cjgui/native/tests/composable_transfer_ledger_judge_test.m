// Test-only acceptance for the transfer-retention judge boundary cases.
//
// Builds the renderer with -DCJGUI_INTERNAL_TESTING and drives the real
// CjguiTransferLedgerJudge through one observation at a time:
//
//   1. fill at the capacity edge (id == CAPACITY) is observed, not dropped;
//   2. fill + release at that id is balanced (verdict 0);
//   3. a placeholder release never masks a filled-but-unreleased observation;
//   4. a double release is reported as its own verdict;
//   5. an out-of-range observation invalidates the whole judge instead of
//      being silently ignored (the old <CAPACITY loop bug).
//
// The normal lifecycle run and the single-id negative control use this same
// judge, so these cases describe the exact verdict vocabulary the probe relies
// on: 0 pass, 1 filled-not-released, 2 double release, 3 capacity overflow.
#import <Foundation/Foundation.h>
#include <stdio.h>

#define LEDGER_CAPACITY 4096ul

extern int cjgui_internal_renderer_test_transfer_lifecycle_verify(void);
extern void cjgui_internal_renderer_test_transfer_ledger_reset(void);
extern int cjgui_internal_renderer_test_transfer_ledger_record(unsigned long long observationId, int operation);

enum {
    LEDGER_OP_INIT = 0,
    LEDGER_OP_FILL = 1,
    LEDGER_OP_RELEASE = 2,
    LEDGER_OP_PLACEHOLDER_RELEASE = 3
};

static int gFailures = 0;

static void expectJudge(const char *label, int expected) {
    int verdict = cjgui_internal_renderer_test_transfer_lifecycle_verify();
    int ok = verdict == expected;
    if (!ok) gFailures += 1;
    printf("CJGUI_LEDGER_JUDGE case=%s expected=%d actual=%d %s\n", label, expected, verdict,
           ok ? "ok" : "MISMATCH");
}

int main(void) {
    @autoreleasepool {
        int rangeStatus = 0;
        // 1. Capacity edge: the last admissible observation id is recorded and
        //    a filled-but-unreleased object there is reported.
        cjgui_internal_renderer_test_transfer_ledger_reset();
        rangeStatus = cjgui_internal_renderer_test_transfer_ledger_record(LEDGER_CAPACITY, LEDGER_OP_FILL);
        printf("CJGUI_LEDGER_JUDGE case=capacity_edge_recorded range_status=%d %s\n", rangeStatus,
               rangeStatus == 0 ? "ok" : "MISMATCH");
        if (rangeStatus != 0) gFailures += 1;
        expectJudge("capacity_edge_filled_not_released", 1);

        // 2. Same edge with a release: balanced.
        cjgui_internal_renderer_test_transfer_ledger_reset();
        (void)cjgui_internal_renderer_test_transfer_ledger_record(LEDGER_CAPACITY, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(LEDGER_CAPACITY, LEDGER_OP_RELEASE);
        expectJudge("capacity_edge_balanced", 0);

        // 3. A placeholder release must not hide a filled-but-unreleased item.
        cjgui_internal_renderer_test_transfer_ledger_reset();
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_INIT);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_PLACEHOLDER_RELEASE);
        expectJudge("placeholder_release_does_not_mask_filled_leak", 1);

        // 4. Double release has its own verdict.
        cjgui_internal_renderer_test_transfer_ledger_reset();
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_RELEASE);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(7, LEDGER_OP_RELEASE);
        expectJudge("double_release", 2);

        // 5. Out-of-range observation invalidates the judge (never silently
        //    ignored, never written out of bounds).
        cjgui_internal_renderer_test_transfer_ledger_reset();
        rangeStatus = cjgui_internal_renderer_test_transfer_ledger_record(LEDGER_CAPACITY + 1, LEDGER_OP_FILL);
        printf("CJGUI_LEDGER_JUDGE case=out_of_range_recorded range_status=%d %s\n", rangeStatus,
               rangeStatus == 3 ? "ok" : "MISMATCH");
        if (rangeStatus != 3) gFailures += 1;
        expectJudge("out_of_range_invalidates", 3);

        // 6. A single-id leak is the only thing the negative control reports:
        //    balanced observations around it stay clean, and the leaked id is
        //    the one named by verdict 1.
        cjgui_internal_renderer_test_transfer_ledger_reset();
        (void)cjgui_internal_renderer_test_transfer_ledger_record(1, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(1, LEDGER_OP_RELEASE);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(2, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(2, LEDGER_OP_RELEASE);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(3, LEDGER_OP_FILL);
        expectJudge("single_id_leak", 1);
        cjgui_internal_renderer_test_transfer_ledger_reset();
        (void)cjgui_internal_renderer_test_transfer_ledger_record(3, LEDGER_OP_FILL);
        (void)cjgui_internal_renderer_test_transfer_ledger_record(3, LEDGER_OP_RELEASE);
        expectJudge("single_id_leak_released", 0);

        printf("CJGUI_LEDGER_JUDGE failures=%d %s\n", gFailures, gFailures == 0 ? "PASSED" : "FAILED");
        return gFailures == 0 ? 0 : 1;
    }
}
