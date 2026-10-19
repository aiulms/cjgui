#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
static int failed;
#define COST_CHECK(c,n) do { BOOL ok=(c);fprintf(stderr,"owner_turn_cost case=%s result=%s\n",n,ok?"PASS":"FAIL");if(!ok)failed++; } while(0)
static void pair(uint64_t turn,uint64_t start,uint64_t end,uint64_t idle) {
    CjguiOwnerTurnCostObserve(144,0,turn,start,101,0);
    CjguiOwnerTurnCostObserve(400,0,turn,start+1,101,idle);
    CjguiOwnerTurnCostObserve(145,0,turn,end,101,0);
}
int main(void) { @autoreleasepool {
    setenv("CJGUI_OWNER_TURN_COST","1",1);
    COST_CHECK(CjguiOwnerTurnCostEnabled(),"explicit_opt_in");
    if (getenv("CJGUI_COST_EXPORT_FULL_CONTROL")) {
        for (uint64_t i=0;i<CJGUI_OWNER_TURN_COST_CAPACITY;i++) pair(i+1,i*100000,i*100000+50000,10000);
        uint8_t terminal=cjgui_internal_renderer_finalize_owner_trace();
        COST_CHECK(terminal==2 && gCjguiOwnerTurnCostExported && gCjguiOwnerTurnCostExportSucceeded,
            "full_fixed_capacity_pipe_export_finishes_inside_cleanup");
        return failed?1:0;
    }
    if (getenv("CJGUI_COST_EXPORT_FAILURE_CONTROL")) {
        pair(1,100,20100,5000);
        if (!freopen("/dev/null","r",stdout)) return 2;
        uint8_t terminal=cjgui_internal_renderer_finalize_owner_trace();
        COST_CHECK(terminal==3 && gCjguiOwnerTurnCostExported && !gCjguiOwnerTurnCostExportSucceeded,
            "actual_output_failure_is_failed_cleanup_without_replay");
        return failed?1:0;
    }
    pair(1,100,20100,5000);
    COST_CHECK(gCjguiOwnerTurnCostComplete==1 && gCjguiOwnerTurnCosts[0].session==0 &&
        gCjguiOwnerTurnCostWorkSum==15000 && gCjguiOwnerTurnCostOver16==0,"whole_unbound_startup_kept_with_actual_credit");
    pair(2,1000000,21000000,1000000);
    COST_CHECK(gCjguiOwnerTurnCostComplete==2 && gCjguiOwnerTurnCostOver16==1 &&
        gCjguiOwnerTurnCostMaxWork==19000000,"over16_and_max_not_hidden_by_retention");
    CjguiOwnerTurnCostObserve(145,0,2,22000000,101,0);
    COST_CHECK(gCjguiOwnerTurnCostUnpaired==1 && gCjguiOwnerTurnCostComplete==2,"duplicate_end_not_counted_twice");
    CjguiOwnerTurnCostObserve(144,1,3,100,101,0);
    CjguiOwnerTurnCostObserve(145,1,3,10000,101,0);
    COST_CHECK(gCjguiOwnerTurnCostUnknownIdle==1 && !gCjguiOwnerTurnCosts[2].idleKnown,"missing_credit_unknown_not_zero");
    pair(4,100,10000,20000);
    COST_CHECK(gCjguiOwnerTurnCostUnknownIdle==2 && !gCjguiOwnerTurnCosts[3].idleKnown,"excess_credit_unknown_not_clamped");
    CjguiOwnerTurnCostObserve(144,1,5,100,101,0);
    CjguiOwnerTurnCostObserve(144,1,6,200,101,0);
    CjguiOwnerTurnCostObserve(400,0,5,201,101,0);
    COST_CHECK(gCjguiOwnerTurnCostAbandoned==1 && gCjguiOwnerTurnCostUnpaired==2,"old_round_credit_refused");
    CjguiOwnerTurnCostObserve(400,0,6,202,101,0);
    CjguiOwnerTurnCostObserve(145,1,6,300,202,0);
    COST_CHECK(gCjguiOwnerTurnCosts[4].beginTid==101 && gCjguiOwnerTurnCosts[4].endTid==202,
        "thread_migration_retained_without_cpu_subtraction");
    uint64_t rows=gCjguiOwnerTurnCostRows;
    gCjguiOwnerTurnCostRows=CJGUI_OWNER_TURN_COST_CAPACITY;
    pair(7,100,40000100,0);
    COST_CHECK(gCjguiOwnerTurnCostLost==1 && gCjguiOwnerTurnCostRows==CJGUI_OWNER_TURN_COST_CAPACITY &&
        gCjguiOwnerTurnCostOver16==2 && gCjguiOwnerTurnCostMaxWork==40000000,
        "fixed_storage_overflow_keeps_slow_counts_max_and_loss");
    // Export only populated fixture rows; the loss counter remains truthful.
    gCjguiOwnerTurnCostRows=rows;
    // The normal application cleanup ticket may release AppKit only after
    // diagnostics have reached their terminal. Cost export cannot rely on a
    // later process-exit hook with a potentially backpressured output pipe.
    (void)cjgui_internal_renderer_finalize_owner_trace();
    COST_CHECK(gCjguiOwnerTurnCostExported,"actual_cleanup_finalizes_cost_before_application_release");
    fprintf(stderr,"owner_turn_cost failures=%d scope=synthetic_metric_contract_not_performance\n",failed);
    return failed?1:0;
} }
