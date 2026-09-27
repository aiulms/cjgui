// Native pixel probe for P4 isolated effect groups.
//
// Expected values below are calculated from the declared sRGB component
// formulas, independently of the Metal shader. The drawable is BGRA8Unorm;
// samples are taken well inside fully covered pixels, so the tolerance is two
// code values (one quantization step plus resolve/intermediate rounding).
#import "../native/cjgui_internal_renderer.h"
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>

static const double kBgR = 0.20, kBgG = 0.40, kBgB = 0.60;
static const int kTolerance = 2;

static int require(int ok, const char *name) {
    if (!ok) fprintf(stderr, "effect group probe: failed %s\n", name);
    return ok;
}

static uint8_t q(double component) {
    return (uint8_t)(component * 255.0 + 0.5);
}

static int sample_pixel_with_rgba_clear(uint64_t session, uint32_t x, uint32_t y,
        double clearR, double clearG, double clearB, double clearAlpha, uint8_t outBGRA[4]);

static int pixel_is_with_clear(uint64_t session, uint32_t x, uint32_t y, double clearAlpha,
                    double r, double g, double b, double a, const char *name) {
    // A transparent target must begin with premultiplied black. A nonzero RGB
    // clear with alpha zero would inject an invalid straight-color fringe into
    // the fixed-function blend result.
    double clearRGB = clearAlpha == 0.0 ? 0.0 : 0.20;
    CjguiInternalRendererClearColor clear = {clearRGB, clearAlpha == 0.0 ? 0.0 : 0.40,
                                              clearAlpha == 0.0 ? 0.0 : 0.60, clearAlpha};
    CjguiInternalRendererFrameObservation frame = {0};
    uint8_t actualB = 0, actualG = 0, actualR = 0, actualA = 0;
    if (cjgui_internal_renderer_test_request_composable_drawable_pixel(session, x, y) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_present_clear(session, &clear, &frame) != CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_test_composable_drawable_pixel(session, &actualB, &actualG, &actualR, &actualA) != CJGUI_INTERNAL_RENDERER_OK) {
        fprintf(stderr, "effect group probe: readback failed %s\n", name);
        return 0;
    }
    int er = q(r), eg = q(g), eb = q(b), ea = q(a);
    int ok = abs((int)actualR-er) <= kTolerance && abs((int)actualG-eg) <= kTolerance &&
             abs((int)actualB-eb) <= kTolerance && abs((int)actualA-ea) <= kTolerance;
    if (!ok) fprintf(stderr,
        "effect group probe: failed %s actual BGRA=%u,%u,%u,%u expected=%d,%d,%d,%d tol=%d\n",
        name, actualB, actualG, actualR, actualA, eb, eg, er, ea, kTolerance);
    return ok;
}

static int pixel_is_with_rgba_clear(uint64_t session, uint32_t x, uint32_t y,
        double clearR,double clearG,double clearB,double clearA,
        double r,double g,double b,double a,const char *name) {
    uint8_t actual[4]={0};
    if (!sample_pixel_with_rgba_clear(session,x,y,clearR,clearG,clearB,clearA,actual)) {
        fprintf(stderr,"effect group probe: readback failed %s\n",name);
        return 0;
    }
    int er=q(r),eg=q(g),eb=q(b),ea=q(a);
    int ok=abs((int)actual[2]-er)<=kTolerance && abs((int)actual[1]-eg)<=kTolerance &&
           abs((int)actual[0]-eb)<=kTolerance && abs((int)actual[3]-ea)<=kTolerance;
    if (!ok) fprintf(stderr,
        "effect group probe: failed %s actual BGRA=%u,%u,%u,%u expected=%d,%d,%d,%d tol=%d\n",
        name,actual[0],actual[1],actual[2],actual[3],eb,eg,er,ea,kTolerance);
    return ok;
}

static int sample_pixel_with_rgba_clear(uint64_t session, uint32_t x, uint32_t y,
        double clearR, double clearG, double clearB, double clearAlpha, uint8_t outBGRA[4]) {
    CjguiInternalRendererClearColor clear = {clearR,clearG,clearB,clearAlpha};
    CjguiInternalRendererFrameObservation frame = {0};
    if (cjgui_internal_renderer_test_request_composable_drawable_pixel(session,x,y)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_present_clear(session,&clear,&frame)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_test_composable_drawable_pixel(session,&outBGRA[0],&outBGRA[1],
                                                               &outBGRA[2],&outBGRA[3])!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    return 1;
}

static int sample_pixel_with_clear(uint64_t session, uint32_t x, uint32_t y,
        double clearAlpha, uint8_t outBGRA[4]) {
    double clearRGB = clearAlpha == 0.0 ? 0.0 : 0.20;
    return sample_pixel_with_rgba_clear(session,x,y,clearRGB,
        clearAlpha == 0.0 ? 0.0 : 0.40,clearAlpha == 0.0 ? 0.0 : 0.60,clearAlpha,outBGRA);
}

static int pixel_is(uint64_t session, uint32_t x, uint32_t y,
                    double r, double g, double b, double a, const char *name) {
    return pixel_is_with_clear(session,x,y,1.0,r,g,b,a,name);
}

static CjguiInternalRendererComposableNode rect(uint64_t version, uint64_t id,
        double x, double y, double w, double h, double r, double g, double b, double a) {
    CjguiInternalRendererComposableNode n = {0};
    n.nodeId = id; n.projectionVersion = version;
    n.x=x; n.y=y; n.width=w; n.height=h;
    n.clipX=x; n.clipY=y; n.clipWidth=w; n.clipHeight=h;
    n.clipConstraintCount=1; n.clip0X=0; n.clip0Y=0; n.clip0Width=420; n.clip0Height=180;
    n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    n.fillRed=r; n.fillGreen=g; n.fillBlue=b; n.fillAlpha=a;
    return n;
}

static CjguiInternalRendererComposableNode group(uint64_t version, uint64_t id,
        double x, double y, double w, double h, uint32_t count, double opacity, uint32_t blend) {
    CjguiInternalRendererComposableNode n = rect(version,id,x,y,w,h,0,0,0,0);
    n.effectGroupPresent=1; n.effectGroupSubtreeCount=count;
    n.effectGroupOpacity=opacity; n.effectGroupBlendMode=blend;
    return n;
}

static void set_mask(CjguiInternalRendererComposableNode *n,
                     double a0, double a1, double p0, double p1) {
    n->effectMaskPresent=1; n->effectMaskStopCount=2;
    n->effectMaskStartX=0; n->effectMaskStartY=0.5;
    n->effectMaskEndX=1; n->effectMaskEndY=0.5;
    n->effectMaskStop0Position=p0; n->effectMaskStop0Alpha=a0;
    n->effectMaskStop1Position=p1; n->effectMaskStop1Alpha=a1;
}

static void set_backdrop_blur(CjguiInternalRendererComposableNode *n,
                              uint32_t radiusPoints, uint32_t fallbackCode) {
    n->effectBackdropBlurRadiusPoints=radiusPoints;
    n->effectBackdropBlurFallback=fallbackCode;
}

static void gaussian_kernel(uint32_t radiusPoints, double *weights,
                            int *outReach, int capacity) {
    double sigma=(double)radiusPoints*0.5;
    int reach=(int)ceil(3.0*sigma);
    if (reach*2+1>capacity) reach=(capacity-1)/2;
    double sum=0.0;
    for (int d=-reach;d<=reach;d++) {
        double value=exp(-((double)d*(double)d)/(2.0*sigma*sigma));
        weights[d+reach]=value;
        sum+=value;
    }
    for (int i=0;i<reach*2+1;i++) weights[i]/=sum;
    *outReach=reach;
}

// Independent scalar oracle for a vertical, high-contrast painter boundary.
// The foreground sibling paints [0, edgeX); the opaque clear is visible to its
// right. The separable horizontal/vertical sums implement the documented
// discrete Gaussian, with samples clamped only to the drawable bounds.
static void backdrop_step_oracle(uint32_t x, uint32_t y, uint32_t width, uint32_t height,
        uint32_t edgeX, uint32_t radiusPoints, const double clearRGB[3],
        const double leftRGB[3], double outRGB[3]) {
    double weights[129]={0};
    int reach=0;
    gaussian_kernel(radiusPoints,weights,&reach,129);
    for (int channel=0;channel<3;channel++) outRGB[channel]=0.0;
    for (int dy=-reach;dy<=reach;dy++) {
        int sy=(int)y+dy;
        if (sy<0) sy=0;
        if (sy>=(int)height) sy=(int)height-1;
        (void)sy; // Source is constant along Y; retain the explicit Y clamp.
        for (int dx=-reach;dx<=reach;dx++) {
            int sx=(int)x+dx;
            if (sx<0) sx=0;
            if (sx>=(int)width) sx=(int)width-1;
            const double *sample=(uint32_t)sx<edgeX?leftRGB:clearRGB;
            double weight=weights[dy+reach]*weights[dx+reach];
            for (int channel=0;channel<3;channel++) outRGB[channel]+=sample[channel]*weight;
        }
    }
}

static int pixel_matches_oracle(uint64_t session, uint32_t x, uint32_t y,
        const double rgb[3], double clearR, double clearG, double clearB, const char *name) {
    uint8_t actual[4]={0};
    if (!sample_pixel_with_rgba_clear(session,x,y,clearR,clearG,clearB,1.0,actual)) {
        fprintf(stderr,"effect group probe: readback failed %s\n",name);
        return 0;
    }
    int er=q(rgb[0]),eg=q(rgb[1]),eb=q(rgb[2]);
    int ok=abs((int)actual[2]-er)<=kTolerance && abs((int)actual[1]-eg)<=kTolerance &&
           abs((int)actual[0]-eb)<=kTolerance && abs((int)actual[3]-255)<=kTolerance;
    if (!ok) fprintf(stderr,
        "effect group probe: failed %s actual BGRA=%u,%u,%u,%u expected=%d,%d,%d,255 tol=%d\n",
        name,actual[0],actual[1],actual[2],actual[3],eb,eg,er,kTolerance);
    return ok;
}

static int bgra_close(const uint8_t a[4],const uint8_t b[4],int tolerance) {
    for (int channel=0;channel<4;channel++)
        if (abs((int)a[channel]-(int)b[channel])>tolerance) return 0;
    return 1;
}

static CjguiInternalRendererStatus stage_status(uint64_t session, uint64_t version,
                 CjguiInternalRendererComposableNode *nodes, uint32_t count) {
    // Mirror one AppKit turn: temporary Foundation arrays created while a
    // candidate is staged must not outlive its scene transaction in the probe.
    @autoreleasepool {
        CjguiInternalRendererFrameObservation frame = {0};
        CjguiInternalRendererStatus status=cjgui_internal_renderer_configure_composable_scene(session,version,count);
        if (status!=CJGUI_INTERNAL_RENDERER_OK) return status;
        for (uint32_t i=0;i<count;i++) {
            char label[40]; snprintf(label,sizeof(label),"effect-group-%u",i);
            status=cjgui_internal_renderer_set_composable_scene_node(session,i,&nodes[i],label,"","","",0);
            if (status!=CJGUI_INTERNAL_RENDERER_OK) return status;
        }
        return cjgui_internal_renderer_present_composable_scene(session,&frame);
    }
}

static int stage(uint64_t session, uint64_t version,
                 CjguiInternalRendererComposableNode *nodes, uint32_t count) {
    return stage_status(session,version,nodes,count)==CJGUI_INTERNAL_RENDERER_OK;
}

static int effect_stats(uint64_t session, CjguiInternalRendererEffectStats *stats, const char *name) {
    // A weak-ledger observation must not create a long-lived autorelease hold
    // on the very target whose release this probe is checking.
    @autoreleasepool {
        if (!require(cjgui_internal_renderer_test_composable_effect_stats(session,stats)==CJGUI_INTERNAL_RENDERER_OK,name)) return 0;
        printf("EFFECT_STATS {\"phase\":\"%s\",\"targetAllocations\":%llu,\"targetReuses\":%llu,"
               "\"targetCurrentBytes\":%llu,\"targetPeakBytes\":%llu,\"contentRedraws\":%llu,"
               "\"offscreenPasses\":%llu,\"compositeDraws\":%llu,"
               "\"backdropPrefixPasses\":%llu,\"backdropHorizontalPasses\":%llu,"
               "\"backdropVerticalPasses\":%llu,\"backdropCacheHits\":%llu,"
               "\"backdropFallbacks\":%llu}\n",
               name,
               (unsigned long long)stats->targetAllocations,
               (unsigned long long)stats->targetReuses,
               (unsigned long long)stats->targetCurrentBytes,
               (unsigned long long)stats->targetPeakBytes,
               (unsigned long long)stats->contentRedraws,
               (unsigned long long)stats->offscreenPasses,
               (unsigned long long)stats->compositeDraws,
               (unsigned long long)stats->backdropPrefixPasses,
               (unsigned long long)stats->backdropHorizontalPasses,
               (unsigned long long)stats->backdropVerticalPasses,
               (unsigned long long)stats->backdropCacheHits,
               (unsigned long long)stats->backdropFallbacks);
        return 1;
    }
}

static int verify_isolation_and_nesting(uint64_t session) {
    CjguiInternalRendererComposableNode n[4];
    // Base background is opaque. Two opaque children overlap. Correct group
    // opacity composites blue over green first, then applies 0.5 once.
    n[0]=rect(10,100,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(10,101,50,40,180,100,3,0.5,0);
    n[2]=rect(10,102,80,60,100,60,0,1,0,1);
    n[3]=rect(10,103,120,60,100,60,0,0,1,1);
    if (!require(stage(session,10,n,4),"stage_group_isolation")) return 0;
    // At (150,80), group result is blue: .5*blue + .5*background.
    if (!require(pixel_is(session,150,80,0.10,0.20,0.80,1,"group_opacity_after_overlap"),"group_pixel")) return 0;
    // Per-node alpha would expose green and produce approximately
    // (0.05,0.35,0.65), clearly outside the two-code tolerance.

    // Nested groups: inner blue is half transparent over the outer group's
    // transparent target; outer opacity halves that result once more.
    n[0]=rect(11,110,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(11,111,50,40,180,100,3,0.5,0);
    n[2]=group(11,112,100,50,100,80,2,0.5,0);
    n[3]=rect(11,113,120,60,60,40,0,0,1,1);
    if (!require(stage(session,11,n,4),"stage_nested_groups")) return 0;
    // Effective blue coverage is 0.25; opaque parent backdrop remains.
    return require(pixel_is(session,140,80,0.15,0.30,0.70,1,"nested_group_opacity_multiplies_once_per_boundary"),"nested_pixel");
}

static int verify_blend_and_order(uint64_t session) {
    CjguiInternalRendererComposableNode n[4];
    const double sr=.8, sg=.3, sb=.1, sa=.5;
    n[0]=rect(20,200,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(20,201,80,50,180,80,2,1,0);
    n[2]=rect(20,202,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,20,n,3),"stage_normal_half_alpha")) return 0;
    // Source-over: straight source C,a over opaque B gives C*a+B*(1-a).
    if (!require(pixel_is(session,140,80,.5,.35,.35,1,"normal_source_over_half_alpha"),"normal_pixel")) return 0;

    n[0]=rect(21,210,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(21,211,80,50,180,80,2,1,1);
    n[2]=rect(21,212,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,21,n,3),"stage_multiply_half_alpha")) return 0;
    // P4 multiply formula with premultiplied S=(.4,.15,.05), a=.5 and b=1:
    // S*(1-b)+B*(1-a)+S*B = (.18,.26,.33), output alpha=1.
    if (!require(pixel_is(session,140,80,.18,.26,.33,1,"multiply_premultiplied_formula"),"multiply_pixel")) return 0;

    // Repeat both blend modes with a genuinely translucent parent pixel. The
    // scene clear is transparent and the root background has alpha=.5, so
    // the multiply equation exercises b<1 and checks output alpha as well.
    n[0]=rect(24,240,0,0,420,180,.2,.4,.6,.5);
    n[1]=group(24,241,80,50,180,80,2,1,0);
    n[2]=rect(24,242,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,24,n,3),"stage_normal_translucent_background")) return 0;
    if (!require(pixel_is_with_clear(session,140,80,0,.45,.25,.20,.75,"normal_over_translucent_background"),"normal_translucent_parent_pixel")) return 0;
    n[0]=rect(25,250,0,0,420,180,.2,.4,.6,.5);
    n[1]=group(25,251,80,50,180,80,2,1,1);
    n[2]=rect(25,252,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,25,n,3),"stage_multiply_translucent_background")) return 0;
    // S=(.4,.15,.05), a=.5; B=(.1,.2,.3), b=.5:
    // S*(1-b)+B*(1-a)+S*B=(.29,.205,.19), alpha=.75.
    if (!require(pixel_is_with_clear(session,140,80,0,.29,.205,.19,.75,"multiply_over_translucent_background"),"multiply_translucent_parent_pixel")) return 0;

    // Negative control: exchange painter order of two half-alpha sources in
    // normal mode. Their colors commute only for opaque coverage; these do not.
    n[0]=rect(22,220,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(22,221,80,50,180,80,3,1,0);
    n[2]=rect(22,222,100,60,100,60,.9,.1,.1,.5);
    n[3]=rect(22,223,100,60,100,60,.1,.8,.2,.5);
    if (!require(stage(session,22,n,4),"stage_order_forward")) return 0;
    if (!require(pixel_is(session,140,80,.325,.525,.275,1,"normal_order_forward"),"forward_pixel")) return 0;
    n[0]=rect(23,230,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(23,231,80,50,180,80,3,1,0);
    n[2]=rect(23,232,100,60,100,60,.1,.8,.2,.5);
    n[3]=rect(23,233,100,60,100,60,.9,.1,.1,.5);
    if (!require(stage(session,23,n,4),"stage_order_reversed")) return 0;
    return require(pixel_is(session,140,80,.525,.35,.25,1,"normal_order_reversed_negative_control"),"reverse_pixel");
}

static int verify_mask_domain_and_motion(uint64_t session) {
    CjguiInternalRendererComposableNode n[4];
    n[0]=rect(30,300,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(30,301,50,40,200,100,2,1,0);
    set_mask(&n[1],0,1,.25,.75);
    n[2]=rect(30,302,50,40,200,100,1,0,0,1);
    if (!require(stage(session,30,n,3),"stage_mask_ramp")) return 0;
    if (!require(pixel_is(session,60,90,kBgR,kBgG,kBgB,1,"mask_alpha_zero"),"mask_zero")) return 0;
    if (!require(pixel_is(session,150,90,.60,.20,.30,1,"mask_alpha_half"),"mask_half")) return 0;
    if (!require(pixel_is(session,240,90,1,0,0,1,"mask_alpha_one"),"mask_one")) return 0;
    // The same group's mask has zero alpha outside its layout domain even if
    // a child extends beyond it.
    n[0]=rect(31,310,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(31,311,80,40,100,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(31,312,60,60,180,60,1,0,0,1);
    if (!require(stage(session,31,n,3),"stage_mask_domain")) return 0;
    if (!require(pixel_is(session,70,80,kBgR,kBgG,kBgB,1,"mask_domain_outside"),"domain_outside")) return 0;
    if (!require(pixel_is(session,100,80,1,0,0,1,"mask_domain_inside"),"mask_domain_inside_pixel")) return 0;

    // Duplicate positions are right-continuous: the last stop at t=.5 wins.
    // A zero-width interval must not be smoothed into an invented ramp.
    n[0]=rect(32,320,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(32,321,50,40,200,100,2,1,0);
    n[1].effectMaskPresent=1; n[1].effectMaskStopCount=3;
    n[1].effectMaskStartX=0; n[1].effectMaskStartY=.5;
    n[1].effectMaskEndX=1; n[1].effectMaskEndY=.5;
    n[1].effectMaskStop0Position=0; n[1].effectMaskStop0Alpha=0;
    n[1].effectMaskStop1Position=.5; n[1].effectMaskStop1Alpha=0;
    n[1].effectMaskStop2Position=.5; n[1].effectMaskStop2Alpha=1;
    n[2]=rect(32,322,50,40,200,100,1,0,0,1);
    if (!require(stage(session,32,n,3),"stage_duplicate_mask_stop")) return 0;
    if (!require(pixel_is(session,145,90,kBgR,kBgG,kBgB,1,"duplicate_stop_before"),"duplicate_before")) return 0;
    if (!require(pixel_is(session,155,90,1,0,0,1,"duplicate_stop_after"),"duplicate_after")) return 0;

    // Moving the whole accepted group moves its mask and output together.
    n[0]=rect(33,330,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(33,331,100,40,100,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(33,332,100,40,100,100,1,0,0,1);
    if (!require(stage(session,33,n,3),"stage_group_moved")) return 0;
    return require(pixel_is(session,70,80,kBgR,kBgG,kBgB,1,"old_group_location_cleared") &&
                   pixel_is(session,150,80,1,0,0,1,"new_group_location_painted"),"move_pixels");
}

static int verify_clip_resize_and_rejection(uint64_t session) {
    CjguiInternalRendererComposableNode n[4];
    CjguiInternalRendererEffectStats acceptedA={0}, rejectedB={0}, recoveredB={0};
    n[0]=rect(40,400,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(40,401,60,40,200,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(40,402,60,40,200,100,1,0,0,1);
    // Ancestor clipping is represented by the child's clip constraint; group
    // output must not leak to the clipped half.
    n[2].clipConstraintCount=2;
    n[2].clip1X=60; n[2].clip1Y=40; n[2].clip1Width=80; n[2].clip1Height=100;
    if (!require(stage(session,40,n,3),"stage_ancestor_clip")) return 0;
    if (!require(pixel_is(session,100,80,1,0,0,1,"inside_ancestor_clip"),"clip_inside")) return 0;
    if (!require(pixel_is(session,180,80,kBgR,kBgG,kBgB,1,"outside_ancestor_clip"),"clip_outside")) return 0;

    // The native resize seam drives normal AppKit resize invalidation. The
    // accepted group remains drawable at its original interior point.
    uint64_t resizeVersion=0;
    if (!require(cjgui_internal_renderer_test_resize_composable_window(session,&resizeVersion)==CJGUI_INTERNAL_RENDERER_OK && resizeVersion>0,
                 "normal_window_resize")) return 0;
    if (!require(pixel_is(session,100,80,1,0,0,1,"accepted_pixels_after_resize"),"resize_pixel")) return 0;

    // Accepted A is a red group. Candidate B is blue and is rejected at the
    // real present boundary; the old accepted pixel must remain red. Then a
    // legal B is presented and replaces it. This distinguishes rollback from
    // stale drawable success because the final assertion must become blue.
    n[0]=rect(41,410,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(41,411,60,40,200,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(41,412,60,40,200,100,1,0,0,1);
    if (!require(stage(session,41,n,3),"stage_accepted_a")) return 0;
    if (!effect_stats(session,&acceptedA,"accepted_a_effect_stats")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_present_failures(session,1)==CJGUI_INTERNAL_RENDERER_OK,
                 "inject_candidate_rejection")) return 0;
    n[0]=rect(42,420,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(42,421,60,40,200,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(42,422,60,40,200,100,0,0,1,1);
    if (!require(cjgui_internal_renderer_configure_composable_scene(session,42,3)==CJGUI_INTERNAL_RENDERER_OK,
                 "configure_rejected_b")) return 0;
    for (uint32_t i=0;i<3;i++) {
        char label[40]; snprintf(label,sizeof(label),"rejected-b-%u",i);
        if (!require(cjgui_internal_renderer_set_composable_scene_node(session,i,&n[i],label,"","","",0)==CJGUI_INTERNAL_RENDERER_OK,
                     "set_rejected_b_node")) return 0;
    }
    CjguiInternalRendererFrameObservation frame={0};
    if (!require(cjgui_internal_renderer_present_composable_scene(session,&frame)!=CJGUI_INTERNAL_RENDERER_OK,
                 "candidate_b_is_rejected")) return 0;
    if (!effect_stats(session,&rejectedB,"rejected_b_effect_stats")) return 0;
    if (!require(rejectedB.targetAllocations==acceptedA.targetAllocations &&
                 rejectedB.targetCurrentBytes==acceptedA.targetCurrentBytes,
                 "rejected_candidate_does_not_allocate_or_replace_targets")) return 0;
    if (!require(pixel_is(session,100,80,1,0,0,1,"rejected_candidate_keeps_a"),"old_accepted_pixel")) return 0;
    n[0]=rect(43,430,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(43,431,60,40,200,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(43,432,60,40,200,100,0,0,1,1);
    if (!require(stage(session,43,n,3),"legal_b_recovers") || !effect_stats(session,&recoveredB,"recovered_b_effect_stats")) return 0;
    if (!require(recoveredB.targetAllocations>rejectedB.targetAllocations &&
                 recoveredB.contentRedraws>rejectedB.contentRedraws &&
                 recoveredB.targetPeakBytes>=recoveredB.targetCurrentBytes,
                 "recovery_allocates_accepted_target_and_tracks_live_peak")) return 0;
    return require(pixel_is(session,100,80,0,0,1,1,"legal_b_replaces_a"),"recovered_b_pixel");
}

static int verify_cache_and_content_invalidation(uint64_t session) {
    CjguiInternalRendererComposableNode n[3];
    CjguiInternalRendererEffectStats before={0}, opacityOnly={0}, changed={0};
    n[0]=rect(50,500,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(50,501,60,40,180,100,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(50,502,60,40,180,100,1,0,0,1);
    if (!require(stage(session,50,n,3),"stage_cache_baseline") || !effect_stats(session,&before,"cache_stats_before")) return 0;
    if (!require(before.targetAllocations>0 && before.contentRedraws>0 && before.offscreenPasses>0 &&
                 before.targetCurrentBytes>0 && before.targetPeakBytes>=before.targetCurrentBytes,
                 "effect_target_allocation_and_pass_accounted")) return 0;

    // Pure opacity change must reuse the same group-content texture and avoid
    // another content pass. The changed pixel proves the new composite value
    // was consumed despite reuse.
    n[0]=rect(51,510,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(51,501,60,40,180,100,2,.5,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(51,502,60,40,180,100,1,0,0,1);
    if (!require(stage(session,51,n,3),"stage_opacity_only") || !effect_stats(session,&opacityOnly,"cache_stats_opacity")) return 0;
    if (!require(opacityOnly.targetAllocations==before.targetAllocations &&
                 opacityOnly.targetReuses>before.targetReuses &&
                 opacityOnly.contentRedraws==before.contentRedraws &&
                 opacityOnly.targetCurrentBytes==before.targetCurrentBytes,
                 "opacity_change_reuses_content_without_redraw")) return 0;
    if (!require(pixel_is(session,100,80,.60,.20,.30,1,"opacity_only_changes_composite"),"opacity_only_pixel")) return 0;

    // Content change under the same group identity and geometry must invalidate
    // the cached group target and produce a new offscreen content pass.
    n[0]=rect(52,520,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(52,501,60,40,180,100,2,.5,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(52,502,60,40,180,100,0,1,0,1);
    if (!require(stage(session,52,n,3),"stage_content_change") || !effect_stats(session,&changed,"cache_stats_changed")) return 0;
    if (!require(changed.targetAllocations>opacityOnly.targetAllocations &&
                 changed.contentRedraws>opacityOnly.contentRedraws &&
                 changed.offscreenPasses>opacityOnly.offscreenPasses,
                 "subtree_change_invalidates_content_cache")) return 0;
    return require(pixel_is(session,100,80,.10,.70,.30,1,"changed_content_pixel"),"content_change_pixel");
}

static int verify_multiply_background_recomposition(uint64_t session) {
    CjguiInternalRendererComposableNode n[3];
    CjguiInternalRendererEffectStats firstBackground={0}, secondBackground={0};
    const double sr=.8, sg=.3, sb=.1, sa=.5;
    n[0]=rect(55,550,0,0,420,180,.2,.4,.6,1);
    n[1]=group(55,551,80,50,180,80,2,1,1);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(55,552,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,55,n,3),"stage_multiply_background_a") ||
        !effect_stats(session,&firstBackground,"multiply_background_a_stats")) return 0;
    if (!require(pixel_is(session,140,80,.18,.26,.33,1,"multiply_background_a_pixel"),"multiply_background_a")) return 0;

    // Only the parent background changes. The isolated source texture must be
    // reused; multiply must still be recomputed against the new prior sibling.
    n[0]=rect(56,560,0,0,420,180,.6,.2,.1,1);
    n[1]=group(56,551,80,50,180,80,2,1,1);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(56,552,100,60,100,60,sr,sg,sb,sa);
    if (!require(stage(session,56,n,3),"stage_multiply_background_b") ||
        !effect_stats(session,&secondBackground,"multiply_background_b_stats")) return 0;
    if (!require(secondBackground.targetAllocations==firstBackground.targetAllocations &&
                 secondBackground.contentRedraws==firstBackground.contentRedraws &&
                 secondBackground.targetReuses>firstBackground.targetReuses,
                 "background_change_reuses_source_without_content_redraw")) return 0;
    // With B=(.6,.2,.1), S=(.4,.15,.05), a=.5, b=1, the declared
    // premultiplied multiply equation yields (.54,.13,.055), alpha=1.
    return require(pixel_is(session,140,80,.54,.13,.055,1,"multiply_uses_new_parent_background"),
                   "multiply_background_b_pixel");
}

static int verify_no_group_resource_baseline(uint64_t session) {
    CjguiInternalRendererComposableNode n[2];
    CjguiInternalRendererEffectStats before={0}, after={0};
    if (!effect_stats(session,&before,"pre_no_group_stats")) return 0;
    n[0]=rect(57,570,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=rect(57,571,100,60,100,60,.9,.2,.1,1);
    if (!require(stage(session,57,n,2),"stage_no_group_baseline") ||
        !effect_stats(session,&after,"no_group_stats")) return 0;
    return require(after.targetAllocations==before.targetAllocations &&
                   after.contentRedraws==before.contentRedraws &&
                   after.offscreenPasses==before.offscreenPasses,
                   "no_group_adds_zero_effect_targets_or_passes");
}

static int verify_mask_backing_scale(uint64_t session) {
    // A controlled backing-property notification changes only the pixel scale,
    // not the accepted point geometry. The mask midpoint must remain at the
    // same logical x in both drawable resolutions.
    CjguiInternalRendererComposableNode n[3];
    n[0]=rect(65,650,0,0,420,180,kBgR,kBgG,kBgB,1);
    n[1]=group(65,651,60,40,200,100,2,1,0);
    set_mask(&n[1],0,1,0,1);
    n[2]=rect(65,652,60,40,200,100,1,0,0,1);
    if (!require(stage(session,65,n,3),"stage_scale_mask")) return 0;
    uint64_t resizeA=0, resizeB=0;
    double beforeA=0, afterA=0, beforeB=0, afterB=0;
    uint32_t widthA=0, heightA=0, widthB=0, heightB=0;
    if (!require(cjgui_internal_renderer_test_toggle_composable_backing_scale(
            session,&resizeA,&beforeA,&afterA,&widthA,&heightA)==CJGUI_INTERNAL_RENDERER_OK,
                 "toggle_mask_scale_a")) return 0;
    // The readback seam accepts point coordinates and maps them to drawable
    // pixels itself, so the requested logical point remains (160,90).
    if (!require(pixel_is(session,160,90,
                          .60,.20,.30,1,"mask_midpoint_after_scale_a"),"mask_scale_a_pixel")) return 0;
    if (!require(cjgui_internal_renderer_test_toggle_composable_backing_scale(
            session,&resizeB,&beforeB,&afterB,&widthB,&heightB)==CJGUI_INTERNAL_RENDERER_OK &&
                 resizeB>resizeA && beforeB==afterA && afterB==beforeA &&
                 widthA!=widthB && heightA!=heightB,
                 "toggle_mask_scale_b")) return 0;
    if (!require(pixel_is(session,160,90,
                          .60,.20,.30,1,"mask_midpoint_after_scale_b"),"mask_scale_b_pixel")) return 0;
    printf("EFFECT_SCALE before=%.1f after=%.1f restored=%.1f drawable_a=%ux%u drawable_b=%ux%u\n",
           beforeA,afterA,afterB,widthA,heightA,widthB,heightB);
    return 1;
}

static int verify_target_budget_rejection(uint64_t session) {
    // A 2049 x 2049 target exceeds the renderer's 4 Mi-pixel admission bound
    // at 1x, and the 4096-pixel dimension bound at 2x. The oversize test
    // viewport keeps this geometry inside the measured drawable.
    uint32_t viewWidth=0, viewHeight=0;
    if (!require(cjgui_internal_renderer_test_set_composable_viewport_size(session,2049,2049,
                 &viewWidth,&viewHeight)==CJGUI_INTERNAL_RENDERER_OK && viewWidth>=2049 && viewHeight>=2049,
                 "set_controlled_oversize_viewport")) return 0;
    CjguiInternalRendererEffectStats accepted={0}, afterReject={0};
    if (!effect_stats(session,&accepted,"pre_budget_effect_stats")) return 0;
    CjguiInternalRendererComposableNode n[3];
    n[0]=rect(60,600,0,0,2049,2049,kBgR,kBgG,kBgB,1);
    n[1]=group(60,601,0,0,2049,2049,2,1,0);
    set_mask(&n[1],1,1,0,1);
    n[2]=rect(60,602,0,0,2049,2049,1,0,0,1);
    if (!require(cjgui_internal_renderer_configure_composable_scene(session,60,3)==CJGUI_INTERNAL_RENDERER_OK,
                 "configure_over_budget_candidate")) return 0;
    for (uint32_t i=0;i<3;i++) {
        char label[40]; snprintf(label,sizeof(label),"over-budget-%u",i);
        if (!require(cjgui_internal_renderer_set_composable_scene_node(session,i,&n[i],label,"","","",0)==CJGUI_INTERNAL_RENDERER_OK,
                     "set_over_budget_node")) return 0;
    }
    CjguiInternalRendererFrameObservation frame={0};
    CjguiInternalRendererStatus rejected=cjgui_internal_renderer_present_composable_scene(session,&frame);
    if (!require(rejected==CJGUI_INTERNAL_RENDERER_EFFECT_RESOURCE_BUDGET_EXCEEDED,
                 "over_budget_target_has_specific_rejection")) return 0;
    if (!effect_stats(session,&afterReject,"post_budget_effect_stats")) return 0;
    if (!require(afterReject.targetAllocations==accepted.targetAllocations &&
                 afterReject.targetCurrentBytes==accepted.targetCurrentBytes &&
                 afterReject.targetPeakBytes==accepted.targetPeakBytes,
                 "budget_rejection_allocates_no_target_and_keeps_accounting")) return 0;
    // The immediately preceding accepted scene is the no-group baseline: its
    // opaque test rectangle spans [100,200] x [60,120]. Sample its interior.
    return require(pixel_is(session,150,90,.9,.2,.1,1,"old_accepted_scene_survives_budget_rejection"),
                   "budget_old_frame_pixel");
}

static uint64_t monotonic_micros(void) {
    struct timespec ts={0};
    if (clock_gettime(CLOCK_MONOTONIC,&ts)!=0) return 0;
    return (uint64_t)ts.tv_sec*1000000ull+(uint64_t)ts.tv_nsec/1000ull;
}

static NSView *find_renderer_view(NSView *root) {
    if (!root) return nil;
    if ([NSStringFromClass(root.class) isEqualToString:@"CJGuiInternalMetalView"]) return root;
    for (NSView *child in root.subviews) {
        NSView *found=find_renderer_view(child);
        if (found) return found;
    }
    return nil;
}

static int renderer_queue_and_device(id<MTLCommandQueue> *outQueue, id<MTLDevice> *outDevice) {
    *outQueue=nil; *outDevice=nil;
    for (NSWindow *window in NSApp.windows) {
        if (![window.title isEqualToString:@"CJGUI Shared Operation"]) continue;
        NSView *metalView=find_renderer_view(window.contentView);
        if (!metalView) continue;
        // Test-only introspection of the renderer's existing owner lets this
        // probe place a shared-event gate on the exact production command queue.
        id queue=[metalView valueForKey:@"commandQueue"];
        id device=[metalView valueForKey:@"device"];
        if (queue && device) {
            *outQueue=queue; *outDevice=device;
            return 1;
        }
    }
    return 0;
}

static int wait_marker_with_main_pump(id<MTLCommandQueue> queue, uint32_t timeoutMs,
                                      uint64_t *outElapsedMicros, uint32_t *outPumpCount) {
    *outElapsedMicros=0; *outPumpCount=0;
    dispatch_semaphore_t completed=dispatch_semaphore_create(0);
    id<MTLCommandBuffer> marker=[queue commandBuffer];
    if (!marker) return 0;
    [marker addCompletedHandler:^(__unused id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(completed);
    }];
    uint64_t started=monotonic_micros();
    [marker commit];
    uint64_t deadline=started+(uint64_t)timeoutMs*1000ull;
    BOOL didComplete=NO;
    while (!didComplete) {
        if (dispatch_semaphore_wait(completed,DISPATCH_TIME_NOW)==0) {
            didComplete=YES;
            break;
        }
        uint64_t now=monotonic_micros();
        if (!now || now>=deadline) break;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,true);
        (*outPumpCount)++;
    }
    uint64_t ended=monotonic_micros();
    *outElapsedMicros=ended>=started?ended-started:0;
    return didComplete;
}

static int wait_renderer_frame_with_main_pump(uint64_t session, uint64_t minimumFrame,
        uint32_t timeoutMs, CjguiInternalRendererComposableDisplayProgress *outProgress,
        uint64_t *outElapsedMicros, uint32_t *outPumpCount) {
    *outElapsedMicros=0; *outPumpCount=0;
    uint64_t started=monotonic_micros();
    uint64_t deadline=started+(uint64_t)timeoutMs*1000ull;
    do {
        if (cjgui_internal_renderer_composable_display_progress(session,outProgress)!=CJGUI_INTERNAL_RENDERER_OK)
            return 0;
        if (outProgress->observedMetalCompletionFrameIndex>=minimumFrame) {
            uint64_t ended=monotonic_micros();
            *outElapsedMicros=ended>=started?ended-started:0;
            return 1;
        }
        uint64_t now=monotonic_micros();
        if (!now || now>=deadline) break;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,true);
        (*outPumpCount)++;
    } while (1);
    uint64_t ended=monotonic_micros();
    *outElapsedMicros=ended>=started?ended-started:0;
    return 0;
}

static int wait_effect_ledger_bytes_with_main_pump(uint64_t session, uint64_t expectedBytes,
        uint32_t timeoutMs, CjguiInternalRendererEffectStats *outStats,
        uint64_t *outElapsedMicros, uint32_t *outPumpCount) {
    *outElapsedMicros=0; *outPumpCount=0;
    uint64_t started=monotonic_micros();
    uint64_t deadline=started+(uint64_t)timeoutMs*1000ull;
    do {
        if (cjgui_internal_renderer_test_composable_effect_stats(session,outStats)!=CJGUI_INTERNAL_RENDERER_OK)
            return 0;
        if (outStats->targetCurrentBytes==expectedBytes) {
            uint64_t ended=monotonic_micros();
            *outElapsedMicros=ended>=started?ended-started:0;
            return 1;
        }
        uint64_t now=monotonic_micros();
        if (!now || now>=deadline) break;
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.005,true);
        (*outPumpCount)++;
    } while (1);
    uint64_t ended=monotonic_micros();
    *outElapsedMicros=ended>=started?ended-started:0;
    return 0;
}

static int verify_controlled_effect_target_lifetime(uint64_t session) {
    id<MTLCommandQueue> queue=nil; id<MTLDevice> device=nil;
    id<MTLCommandBuffer> gateBuffer=nil;
    id<MTLSharedEvent> gate=nil;
    BOOL gateCommitted=NO, gateReleased=NO;
    uint64_t gateValue=0;
    CjguiInternalRendererEffectStats baseline={0}, aStats={0}, removedStats={0}, bStats={0},
        afterFenceStats={0}, finalStats={0};
    CjguiInternalRendererComposableDisplayProgress aProgress={0}, removedProgress={0},
        bProgress={0}, completedProgress={0}, finalProgress={0};
    uint64_t frameA=0, frameRemoved=0, frameB=0;
    uint64_t fenceMicros=0, finalFenceMicros=0, completionPumpMicros=0,
        finalCompletionPumpMicros=0, ledgerDrainMicros=0;
    uint32_t pumpCount=0, finalPumpCount=0, completionPumpCount=0,
        finalCompletionPumpCount=0, ledgerDrainPumpCount=0;
    int ok=0;

    // Establish an empty starting ledger and drain any earlier probe frames
    // before the controlled fence is installed.
    uint32_t viewWidth=0, viewHeight=0;
    if (!require(cjgui_internal_renderer_test_set_composable_viewport_size(session,420,180,
                 &viewWidth,&viewHeight)==CJGUI_INTERNAL_RENDERER_OK && viewWidth>=420 && viewHeight>=180,
                 "lifecycle_restore_viewport")) goto cleanup;
    CjguiInternalRendererComposableNode clean=rect(70,700,0,0,420,180,kBgR,kBgG,kBgB,1);
    if (!require(stage(session,70,&clean,1),"lifecycle_stage_clean_baseline") ||
        !require(pixel_is(session,20,20,kBgR,kBgG,kBgB,1,"lifecycle_baseline_fence_pixel"),"lifecycle_baseline_readback") ||
        !effect_stats(session,&baseline,"lifecycle_baseline_stats") ||
        !require(baseline.targetCurrentBytes==0,"lifecycle_baseline_ledger_empty")) goto cleanup;
    if (!renderer_queue_and_device(&queue,&device) || !require(queue!=nil && device!=nil,"renderer_queue_access")) goto cleanup;
    if (@available(macOS 10.14,*)) {
        gate=[device newSharedEvent];
    }
    if (!require(gate!=nil,"shared_event_available")) goto cleanup;

    gateBuffer=[queue commandBuffer];
    if (!require(gateBuffer!=nil,"gate_command_buffer")) goto cleanup;
    gateValue=gate.signaledValue+1;
    [gateBuffer encodeWaitForEvent:gate value:gateValue];
    [gateBuffer commit];
    gateCommitted=YES;

    // The gate is ahead of the production renderer buffers on its own queue.
    // No drawable readback or waitUntilCompleted occurs until after CPU release.
    CjguiInternalRendererComposableNode a[3];
    a[0]=rect(71,710,0,0,420,180,kBgR,kBgG,kBgB,1);
    a[1]=group(71,711,80,50,180,80,2,1,0);
    set_mask(&a[1],1,1,0,1);
    a[2]=rect(71,712,100,60,100,60,.8,.2,.1,1);
    if (!require(stage(session,71,a,3),"lifecycle_accept_a") ||
        !effect_stats(session,&aStats,"lifecycle_a_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&aProgress)!=CJGUI_INTERNAL_RENDERER_OK) goto cleanup;
    frameA=aProgress.submittedFrameIndex;
    if (!require(frameA>aProgress.observedMetalCompletionFrameIndex,"a_is_behind_gate")) goto cleanup;

    CjguiInternalRendererComposableNode empty=rect(72,720,0,0,420,180,kBgR,kBgG,kBgB,1);
    if (!require(stage(session,72,&empty,1),"lifecycle_replace_with_no_group") ||
        !effect_stats(session,&removedStats,"lifecycle_after_remove_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&removedProgress)!=CJGUI_INTERNAL_RENDERER_OK) goto cleanup;
    frameRemoved=removedProgress.submittedFrameIndex;
    if (!require(removedProgress.observedMetalCompletionFrameIndex<frameA &&
                 removedStats.targetCurrentBytes>=aStats.targetCurrentBytes &&
                 removedStats.targetAllocations==aStats.targetAllocations,
                 "old_a_target_retained_before_completion")) goto cleanup;

    // Same group identity/content is accepted again while A is still held by
    // its uncompleted command buffer. Since the accepted cache was emptied by
    // the no-group scene, this must allocate a distinct target generation.
    a[0]=rect(73,730,0,0,420,180,kBgR,kBgG,kBgB,1);
    a[1]=group(73,711,80,50,180,80,2,1,0);
    set_mask(&a[1],1,1,0,1);
    a[2]=rect(73,712,100,60,100,60,.8,.2,.1,1);
    if (!require(stage(session,73,a,3),"lifecycle_accept_b_same_group") ||
        !effect_stats(session,&bStats,"lifecycle_b_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&bProgress)!=CJGUI_INTERNAL_RENDERER_OK) goto cleanup;
    frameB=bProgress.submittedFrameIndex;
    if (!require(bProgress.observedMetalCompletionFrameIndex<frameA &&
                 bStats.targetAllocations==aStats.targetAllocations+1 &&
                 bStats.targetCurrentBytes>=removedStats.targetCurrentBytes+aStats.targetCurrentBytes,
                 "inflight_a_generation_not_reused_for_b")) goto cleanup;

    printf("EFFECT_LIFECYCLE {\"phase\":\"before_release\",\"frameA\":%llu,\"frameRemoved\":%llu,\"frameB\":%llu,"
           "\"observedCompletionFrame\":%llu,\"bytesA\":%llu,\"bytesAfterRemove\":%llu,\"bytesAfterB\":%llu,"
           "\"allocationsA\":%llu,\"allocationsB\":%llu}\n",
           (unsigned long long)frameA,(unsigned long long)frameRemoved,(unsigned long long)frameB,
           (unsigned long long)bProgress.observedMetalCompletionFrameIndex,
           (unsigned long long)aStats.targetCurrentBytes,(unsigned long long)removedStats.targetCurrentBytes,
           (unsigned long long)bStats.targetCurrentBytes,(unsigned long long)aStats.targetAllocations,
           (unsigned long long)bStats.targetAllocations);

    gate.signaledValue=gateValue;
    gateReleased=YES;
    if (!require(wait_marker_with_main_pump(queue,5000,&fenceMicros,&pumpCount),"lifecycle_completion_marker")) goto cleanup;
    if (!require(wait_renderer_frame_with_main_pump(session,frameB,5000,&completedProgress,
                 &completionPumpMicros,&completionPumpCount),
                 "lifecycle_metal_completion_observed")) goto cleanup;
    if (!effect_stats(session,&afterFenceStats,"lifecycle_after_completion_stats")) goto cleanup;
    BOOL aReleasedAfterFence=afterFenceStats.targetCurrentBytes==
        bStats.targetCurrentBytes-aStats.targetCurrentBytes;

    CjguiInternalRendererComposableNode finalNode=rect(74,740,0,0,420,180,kBgR,kBgG,kBgB,1);
    if (!require(stage(session,74,&finalNode,1),"lifecycle_remove_b_after_completion") ||
        cjgui_internal_renderer_composable_display_progress(session,&finalProgress)!=CJGUI_INTERNAL_RENDERER_OK) goto cleanup;
    uint64_t finalFrame=finalProgress.submittedFrameIndex;
    if (!require(wait_marker_with_main_pump(queue,5000,&finalFenceMicros,&finalPumpCount),"lifecycle_final_completion_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,finalFrame,5000,&finalProgress,
                 &finalCompletionPumpMicros,&finalCompletionPumpCount),"lifecycle_final_metal_completion")) goto cleanup;
    (void)wait_effect_ledger_bytes_with_main_pump(session,0,5000,&finalStats,
        &ledgerDrainMicros,&ledgerDrainPumpCount);
    printf("EFFECT_STATS {\"phase\":\"lifecycle_final_no_group_stats\",\"targetAllocations\":%llu,"
           "\"targetReuses\":%llu,\"targetCurrentBytes\":%llu,\"targetPeakBytes\":%llu,"
           "\"contentRedraws\":%llu,\"offscreenPasses\":%llu,\"compositeDraws\":%llu}\n",
           (unsigned long long)finalStats.targetAllocations,(unsigned long long)finalStats.targetReuses,
           (unsigned long long)finalStats.targetCurrentBytes,(unsigned long long)finalStats.targetPeakBytes,
           (unsigned long long)finalStats.contentRedraws,(unsigned long long)finalStats.offscreenPasses,
           (unsigned long long)finalStats.compositeDraws);
    printf("EFFECT_LIFECYCLE {\"phase\":\"complete\",\"frameA\":%llu,\"frameRemoved\":%llu,\"frameB\":%llu,"
           "\"completionFrame\":%llu,\"finalFrame\":%llu,\"finalCompletionFrame\":%llu,\"gpuDurationMicros\":%lld,"
           "\"bytesA\":%llu,\"bytesAfterRemove\":%llu,\"bytesAfterB\":%llu,\"bytesAfterFence\":%llu,\"bytesFinal\":%llu,"
           "\"fenceCpuMicros\":%llu,\"completionPumpCpuMicros\":%llu,\"finalFenceCpuMicros\":%llu,"
           "\"finalCompletionPumpCpuMicros\":%llu,\"mainPumpCount\":%u,\"completionPumpCount\":%u,"
           "\"finalMainPumpCount\":%u,\"finalCompletionPumpCount\":%u,\"ledgerDrainCpuMicros\":%llu,"
           "\"ledgerDrainPumpCount\":%u,\"aReleasedAfterFence\":%s}\n",
           (unsigned long long)frameA,(unsigned long long)frameRemoved,(unsigned long long)frameB,
           (unsigned long long)completedProgress.observedMetalCompletionFrameIndex,(unsigned long long)finalFrame,
           (unsigned long long)finalProgress.observedMetalCompletionFrameIndex,
           (long long)completedProgress.observedMetalGpuDurationMicros,
           (unsigned long long)aStats.targetCurrentBytes,(unsigned long long)removedStats.targetCurrentBytes,
           (unsigned long long)bStats.targetCurrentBytes,(unsigned long long)afterFenceStats.targetCurrentBytes,
           (unsigned long long)finalStats.targetCurrentBytes,(unsigned long long)fenceMicros,
           (unsigned long long)completionPumpMicros,(unsigned long long)finalFenceMicros,
           (unsigned long long)finalCompletionPumpMicros,pumpCount,completionPumpCount,
           finalPumpCount,finalCompletionPumpCount,(unsigned long long)ledgerDrainMicros,
           ledgerDrainPumpCount,aReleasedAfterFence?"true":"false");
    if (!require(finalProgress.observedMetalCompletionFrameIndex>=finalFrame &&
                 finalStats.targetCurrentBytes==0,
                 "effect_target_ledger_converges_after_completion")) goto cleanup;
    ok=1;

cleanup:
    // Always unblock the queue before returning, including any assertion or
    // timeout path. No worker thread can remain stuck behind this test gate.
    if (gateCommitted && !gateReleased) gate.signaledValue=gateValue;
    if (gateCommitted && queue) {
        uint64_t cleanupMicros=0; uint32_t cleanupPumps=0;
        (void)wait_marker_with_main_pump(queue,2000,&cleanupMicros,&cleanupPumps);
    }
    return ok;
}

static CjguiInternalRendererStatus present_probe_clear(uint64_t session) {
    CjguiInternalRendererClearColor clear={kBgR,kBgG,kBgB,1.0};
    CjguiInternalRendererFrameObservation frame={0};
    return cjgui_internal_renderer_present_clear(session,&clear,&frame);
}

static int set_probe_backing_scale(uint64_t session, double desiredScale,
        double *outBefore, double *outAfter, uint32_t *outWidth, uint32_t *outHeight) {
    uint64_t resizeVersion=0;
    double before=0.0,after=0.0;
    uint32_t width=0,height=0;
    for (uint32_t attempt=0;attempt<2;attempt++) {
        if (cjgui_internal_renderer_test_toggle_composable_backing_scale(
                session,&resizeVersion,&before,&after,&width,&height)!=CJGUI_INTERNAL_RENDERER_OK) return 0;
        if (after==desiredScale) {
            *outBefore=before; *outAfter=after; *outWidth=width; *outHeight=height;
            return 1;
        }
    }
    return 0;
}

static int verify_accepted_main_encoder_retry(uint64_t session, uint8_t outReferenceBGRA[4]) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats accepted={0}, failed={0}, retried={0};
    CjguiInternalRendererComposableDisplayProgress beforeFailure={0},afterFailure={0},afterRetry={0};
    uint64_t acceptedVersion=0,afterFailureVersion=0;
    uint8_t retryPixel[4]={0},controlPixel[4]={0};
    double scaleBefore=0.0,scaleAfter=0.0;
    uint32_t drawableWidth=0,drawableHeight=0;

    nodes[0]=rect(90,8900,0,0,420,180,kBgR,kBgG,kBgB,1);
    nodes[1]=group(90,8901,80,50,180,80,2,.5,0);
    set_mask(&nodes[1],1,1,0,1);
    nodes[2]=rect(90,8902,80,50,180,80,0,0,1,1);
    if (!require(stage(session,90,nodes,3),"accepted_encoder_a") ||
        !effect_stats(session,&accepted,"accepted_encoder_a_stats") ||
        !require(pixel_is(session,140,80,.10,.20,.80,1,"accepted_encoder_a_pixel"),"accepted_encoder_a_readback") ||
        cjgui_internal_renderer_test_composable_scene_version(session,&acceptedVersion)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_composable_display_progress(session,&beforeFailure)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;

    // The viewport stays in points while backing scale changes. The next
    // ordinary accepted present must replace/redraw this same node's target.
    if (!require(set_probe_backing_scale(session,1.0,&scaleBefore,&scaleAfter,
                 &drawableWidth,&drawableHeight),"accepted_encoder_change_scale")) return 0;
    if (!require(cjgui_internal_renderer_test_fail_next_composable_main_encoder_after_effects(session)==
                 CJGUI_INTERNAL_RENDERER_OK,"accepted_encoder_arm_failure")) return 0;
    CjguiInternalRendererStatus failedStatus=present_probe_clear(session);
    if (!effect_stats(session,&failed,"accepted_encoder_after_failure_stats") ||
        cjgui_internal_renderer_test_composable_scene_version(session,&afterFailureVersion)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_composable_display_progress(session,&afterFailure)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    if (!require(failedStatus==CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE,
                 "accepted_encoder_specific_failure") ||
        !require(afterFailure.submittedFrameIndex==beforeFailure.submittedFrameIndex,
                 "accepted_encoder_failure_not_submitted") ||
        !require(afterFailureVersion==acceptedVersion,
                 "accepted_encoder_failure_scene_stays_accepted")) return 0;

    CjguiInternalRendererStatus retryStatus=present_probe_clear(session);
    if (!require(retryStatus==CJGUI_INTERNAL_RENDERER_OK,"accepted_encoder_retry_present") ||
        !effect_stats(session,&retried,"accepted_encoder_after_retry_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&afterRetry)!=CJGUI_INTERNAL_RENDERER_OK ||
        !sample_pixel_with_clear(session,140,80,1.0,retryPixel)) return 0;

    CjguiInternalRendererStatus status=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config={420,180,kBgR,kBgG,kBgB,1.0};
    uint64_t controlSession=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 controlSession!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"accepted_encoder_control_create")) return 0;
    nodes[0]=rect(91,8900,0,0,420,180,kBgR,kBgG,kBgB,1);
    nodes[1]=group(91,8901,80,50,180,80,2,.5,0);
    set_mask(&nodes[1],1,1,0,1);
    nodes[2]=rect(91,8902,80,50,180,80,0,0,1,1);
    double controlBefore=0.0,controlAfter=0.0;
    uint32_t controlWidth=0,controlHeight=0;
    int controlOK=set_probe_backing_scale(controlSession,scaleAfter,&controlBefore,&controlAfter,
                        &controlWidth,&controlHeight) && stage(controlSession,91,nodes,3) &&
                        sample_pixel_with_clear(controlSession,140,80,1.0,controlPixel);
    if (cjgui_internal_renderer_request_close(controlSession)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
    if (cjgui_internal_renderer_destroy(controlSession)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
    if (!require(controlOK,"accepted_encoder_control_present")) return 0;
    memcpy(outReferenceBGRA,controlPixel,sizeof(controlPixel));
    BOOL samePixel=memcmp(retryPixel,controlPixel,sizeof(controlPixel))==0;
    printf("EFFECT_ENCODER_ACCEPTED_RETRY {\"failedStatus\":%d,\"acceptedVersion\":%llu,"
           "\"versionAfterFailure\":%llu,\"submittedBeforeFailure\":%llu,"
           "\"submittedAfterFailure\":%llu,\"submittedAfterRetry\":%llu,"
           "\"offscreenPassesAccepted\":%llu,\"offscreenPassesAfterFailure\":%llu,"
           "\"offscreenPassesAfterRetry\":%llu,\"redrawsAccepted\":%llu,"
           "\"redrawsAfterFailure\":%llu,\"redrawsAfterRetry\":%llu,"
           "\"bytesAccepted\":%llu,\"bytesAfterFailure\":%llu,\"bytesAfterRetry\":%llu,"
           "\"scaleBefore\":%.2f,\"scaleAfter\":%.2f,\"drawableAfter\":%ux%u,"
           "\"retryBGRA\":[%u,%u,%u,%u],\"controlBGRA\":[%u,%u,%u,%u],"
           "\"retryMatchesControl\":%s}\n",
           (int)failedStatus,(unsigned long long)acceptedVersion,(unsigned long long)afterFailureVersion,
           (unsigned long long)beforeFailure.submittedFrameIndex,(unsigned long long)afterFailure.submittedFrameIndex,
           (unsigned long long)afterRetry.submittedFrameIndex,
           (unsigned long long)accepted.offscreenPasses,(unsigned long long)failed.offscreenPasses,
           (unsigned long long)retried.offscreenPasses,(unsigned long long)accepted.contentRedraws,
           (unsigned long long)failed.contentRedraws,(unsigned long long)retried.contentRedraws,
           (unsigned long long)accepted.targetCurrentBytes,(unsigned long long)failed.targetCurrentBytes,
           (unsigned long long)retried.targetCurrentBytes,scaleBefore,scaleAfter,drawableWidth,drawableHeight,
           retryPixel[0],retryPixel[1],retryPixel[2],retryPixel[3],
           controlPixel[0],controlPixel[1],controlPixel[2],controlPixel[3],samePixel?"true":"false");
    if (!require(afterRetry.submittedFrameIndex>afterFailure.submittedFrameIndex,
                 "accepted_encoder_retry_submits")) return 0;
    if (!require(retried.offscreenPasses>failed.offscreenPasses &&
                 retried.contentRedraws>failed.contentRedraws,
                 "accepted_encoder_retry_redraws_target")) return 0;
    return require(samePixel,"accepted_encoder_retry_matches_clean_control");
}

static int verify_cache_hit_inflight_generation(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats accepted={0},cacheHit={0},afterC={0},afterFence={0};
    CjguiInternalRendererComposableDisplayProgress first={0},inflight={0},cProgress={0},completed={0};
    id<MTLCommandQueue> queue=nil; id<MTLDevice> device=nil;
    id<MTLSharedEvent> gate=nil; id<MTLCommandBuffer> gateBuffer=nil;
    BOOL gateCommitted=NO,gateReleased=NO;
    uint64_t gateValue=0,firstFrame=0,aFrame=0,cFrame=0;
    double ignoredBefore=0.0,ignoredAfter=0.0;
    uint32_t ignoredWidth=0,ignoredHeight=0;
    uint64_t markerMicros=0,completionPumpMicros=0;
    uint32_t markerPumps=0,completionPumps=0;
    int ok=0;

    nodes[0]=rect(100,10000,0,0,420,180,kBgR,kBgG,kBgB,1);
    nodes[1]=group(100,10001,80,50,180,80,2,1,0);
    set_mask(&nodes[1],1,1,0,1);
    nodes[2]=rect(100,10002,80,50,180,80,.8,.2,.1,1);
    if (!require(set_probe_backing_scale(session,2.0,&ignoredBefore,&ignoredAfter,
                 &ignoredWidth,&ignoredHeight),"cache_inflight_scale_2x") ||
        !require(stage(session,100,nodes,3),"cache_inflight_accept_a") ||
        !effect_stats(session,&accepted,"cache_inflight_a_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&first)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    firstFrame=first.submittedFrameIndex;
    if (!renderer_queue_and_device(&queue,&device) || !require(queue!=nil && device!=nil,"cache_inflight_queue")) goto cleanup;
    if (!require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),"cache_inflight_a_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,firstFrame,5000,&first,
                 &completionPumpMicros,&completionPumps),"cache_inflight_a_completed")) goto cleanup;

    gate=[device newSharedEvent];
    if (!require(gate!=nil,"cache_inflight_shared_event")) goto cleanup;
    gateBuffer=[queue commandBuffer];
    if (!require(gateBuffer!=nil,"cache_inflight_gate_buffer")) goto cleanup;
    gateValue=gate.signaledValue+1;
    [gateBuffer encodeWaitForEvent:gate value:gateValue];
    [gateBuffer commit]; gateCommitted=YES;
    nodes[0]=rect(101,10000,0,0,420,180,kBgR,kBgG,kBgB,1);
    nodes[1]=group(101,10001,80,50,180,80,2,1,0);
    set_mask(&nodes[1],1,1,0,1);
    nodes[2]=rect(101,10002,80,50,180,80,.8,.2,.1,1);
    if (!require(stage(session,101,nodes,3),"cache_inflight_submit_cached_a") ||
        !effect_stats(session,&cacheHit,"cache_inflight_cached_a_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&inflight)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    aFrame=inflight.submittedFrameIndex;
    if (!require(inflight.observedMetalCompletionFrameIndex< aFrame &&
                 cacheHit.targetAllocations==accepted.targetAllocations &&
                 cacheHit.targetReuses>accepted.targetReuses &&
                 cacheHit.contentRedraws==accepted.contentRedraws,
                 "cache_inflight_a_is_cache_hit_and_pending")) goto cleanup;

    if (!require(set_probe_backing_scale(session,1.0,&ignoredBefore,&ignoredAfter,
                 &ignoredWidth,&ignoredHeight),"cache_inflight_change_scale_for_c") ||
        !require(present_probe_clear(session)==CJGUI_INTERNAL_RENDERER_OK,
                 "cache_inflight_present_c")) goto cleanup;
    if (!effect_stats(session,&afterC,"cache_inflight_c_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&cProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    cFrame=cProgress.submittedFrameIndex;
    // At 1x the changed 180x80-point group has 14,400 BGRA8 pixels.
    // Derive its bytes independently so a missing A generation cannot make
    // the expected C contribution collapse to zero.
    uint64_t cBytes=180u*80u*4u;
    BOOL oldGenerationHeld=afterC.targetAllocations==accepted.targetAllocations+1 &&
        afterC.targetCurrentBytes==accepted.targetCurrentBytes+cBytes &&
        cProgress.observedMetalCompletionFrameIndex<aFrame;
    printf("EFFECT_CACHE_INFLIGHT {\"phase\":\"before_fence\",\"firstFrame\":%llu,\"cachedAFrame\":%llu,"
           "\"cFrame\":%llu,\"completedFrame\":%llu,\"bytesA\":%llu,\"bytesAfterC\":%llu,"
           "\"bytesC\":%llu,\"allocationsA\":%llu,\"allocationsAfterC\":%llu,"
           "\"redrawsA\":%llu,\"redrawsAfterCacheHit\":%llu,\"redrawsAfterC\":%llu,"
           "\"oldGenerationHeld\":%s}\n",
           (unsigned long long)firstFrame,(unsigned long long)aFrame,(unsigned long long)cFrame,
           (unsigned long long)cProgress.observedMetalCompletionFrameIndex,
           (unsigned long long)accepted.targetCurrentBytes,(unsigned long long)afterC.targetCurrentBytes,
           (unsigned long long)cBytes,(unsigned long long)accepted.targetAllocations,
           (unsigned long long)afterC.targetAllocations,(unsigned long long)accepted.contentRedraws,
           (unsigned long long)cacheHit.contentRedraws,(unsigned long long)afterC.contentRedraws,
           oldGenerationHeld?"true":"false");

    gate.signaledValue=gateValue; gateReleased=YES;
    if (!require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),"cache_inflight_completion_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,cFrame,5000,&completed,
                 &completionPumpMicros,&completionPumps),"cache_inflight_c_completed") ||
        !effect_stats(session,&afterFence,"cache_inflight_after_fence_stats")) goto cleanup;
    BOOL retiredAfterFence=afterFence.targetCurrentBytes==cBytes &&
        completed.observedMetalCompletionFrameIndex>=aFrame;
    printf("EFFECT_CACHE_INFLIGHT {\"phase\":\"after_fence\",\"completedFrame\":%llu,"
           "\"bytesAfterFence\":%llu,\"bytesC\":%llu,\"retiredA\":%s,"
           "\"fenceCpuMicros\":%llu,\"completionPumpCpuMicros\":%llu}\n",
           (unsigned long long)completed.observedMetalCompletionFrameIndex,
           (unsigned long long)afterFence.targetCurrentBytes,(unsigned long long)cBytes,
           retiredAfterFence?"true":"false",(unsigned long long)markerMicros,
           (unsigned long long)completionPumpMicros);
    ok=require(oldGenerationHeld,"cache_hit_inflight_a_generation_remains_accounted") &&
       require(retiredAfterFence,"cache_hit_inflight_a_retires_after_fence");

cleanup:
    if (gateCommitted && !gateReleased) gate.signaledValue=gateValue;
    if (gateCommitted && queue) {
        uint64_t cleanupMicros=0; uint32_t cleanupPumps=0;
        (void)wait_marker_with_main_pump(queue,2000,&cleanupMicros,&cleanupPumps);
    }
    return ok;
}

static CjguiInternalRendererComposableNode large_view_rect(uint64_t version,uint64_t id,
        double x,double y,double width,double height,double r,double g,double b,double a) {
    CjguiInternalRendererComposableNode n=rect(version,id,x,y,width,height,r,g,b,a);
    n.clipX=x; n.clipY=y; n.clipWidth=width; n.clipHeight=height;
    n.clipConstraintCount=1; n.clip0X=0; n.clip0Y=0; n.clip0Width=2049; n.clip0Height=2049;
    return n;
}

static void make_total_budget_scene(CjguiInternalRendererComposableNode nodes[13],uint64_t version) {
    nodes[0]=large_view_rect(version,9500,0,0,2049,2049,kBgR,kBgG,kBgB,1);
    for (uint32_t i=0;i<6;i++) {
        uint64_t groupId=9510u+i*2u;
        nodes[1+i*2]=group(version,groupId,0,0,2048,512,2,1,0);
        nodes[1+i*2].clipConstraintCount=1;
        nodes[1+i*2].clip0X=0; nodes[1+i*2].clip0Y=0;
        nodes[1+i*2].clip0Width=2049; nodes[1+i*2].clip0Height=2049;
        set_mask(&nodes[1+i*2],1,1,0,1);
        nodes[2+i*2]=large_view_rect(version,groupId+1,0,0,2048,512,
                                      i%2?.2:.8,.2,i%2?.8:.1,1);
    }
}

static int verify_inflight_total_budget_recovery(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[13];
    CjguiInternalRendererEffectStats aStats={0},cacheStats={0},rejectedStats={0},
        drainedStats={0},recoveredStats={0};
    CjguiInternalRendererComposableDisplayProgress aProgress={0},cacheProgress={0},
        failedProgress={0},completed={0},removedProgress={0},recoveredProgress={0};
    id<MTLCommandQueue> queue=nil; id<MTLDevice> device=nil;
    id<MTLSharedEvent> gate=nil; id<MTLCommandBuffer> gateBuffer=nil;
    BOOL gateCommitted=NO,gateReleased=NO;
    uint64_t gateValue=0,aFrame=0;
    uint64_t markerMicros=0,completionPumpMicros=0;
    uint32_t markerPumps=0,completionPumps=0;
    int ok=0;

    uint32_t viewWidth=0,viewHeight=0;
    double viewportScaleBefore=0.0,viewportScaleAfter=0.0;
    if (!require(cjgui_internal_renderer_test_set_composable_viewport_size(session,2049,2049,
                &viewWidth,&viewHeight)==CJGUI_INTERNAL_RENDERER_OK &&
                viewWidth>=2049 && viewHeight>=2049,"total_budget_set_viewport") ||
        !require(set_probe_backing_scale(session,1.0,&viewportScaleBefore,
                &viewportScaleAfter,&viewWidth,&viewHeight),"total_budget_set_scale_1x"))
        goto cleanup;
    make_total_budget_scene(nodes,110);
    if (!require(stage(session,110,nodes,13),"total_budget_accept_a") ||
        !effect_stats(session,&aStats,"total_budget_a_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&aProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    const uint64_t aExpectedBytes=6u*2048u*512u*4u;
    if (!require(aStats.targetCurrentBytes==aExpectedBytes &&
                 aStats.targetAllocations==6,"total_budget_a_exact_1x_ledger")) goto cleanup;
    aFrame=aProgress.submittedFrameIndex;
    if (!renderer_queue_and_device(&queue,&device) ||
        !require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),"total_budget_a_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,aFrame,5000,&aProgress,
                &completionPumpMicros,&completionPumps),"total_budget_a_completed")) goto cleanup;
    gate=[device newSharedEvent];
    if (!require(gate!=nil,"total_budget_gate_event")) goto cleanup;
    gateBuffer=[queue commandBuffer];
    if (!require(gateBuffer!=nil,"total_budget_gate_buffer")) goto cleanup;
    gateValue=gate.signaledValue+1;
    [gateBuffer encodeWaitForEvent:gate value:gateValue];
    [gateBuffer commit]; gateCommitted=YES;
    make_total_budget_scene(nodes,111);
    if (!require(stage(session,111,nodes,13),"total_budget_submit_cached_a") ||
        !effect_stats(session,&cacheStats,"total_budget_cache_hit_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&cacheProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    aFrame=cacheProgress.submittedFrameIndex;
    if (!require(cacheProgress.observedMetalCompletionFrameIndex<aFrame &&
                 cacheStats.targetAllocations==aStats.targetAllocations &&
                 cacheStats.targetReuses>=aStats.targetReuses+6 &&
                 cacheStats.contentRedraws==aStats.contentRedraws,
                 "total_budget_cached_a_inflight")) goto cleanup;

    double oldScale=0.0,newScale=0.0; uint32_t cWidth=0,cHeight=0;
    if (!require(set_probe_backing_scale(session,2.0,&oldScale,&newScale,&cWidth,&cHeight),
                 "total_budget_change_to_2x")) goto cleanup;
    CjguiInternalRendererStatus budgetStatus=present_probe_clear(session);
    if (!effect_stats(session,&rejectedStats,"total_budget_after_c_reject_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&failedProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    const uint64_t cRequiredBytes=6u*4096u*1024u*4u;
    const uint64_t aggregateRequired=aExpectedBytes+cRequiredBytes;
    printf("EFFECT_TOTAL_BUDGET {\"phase\":\"rejected\",\"aFrame\":%llu,\"completedFrame\":%llu,"
           "\"scaleBefore\":%.2f,\"scaleAfter\":%.2f,\"drawableAfter\":%ux%u,"
           "\"aBytes\":%llu,\"cRequiredBytes\":%llu,\"aggregateRequiredBytes\":%llu,"
           "\"budgetBytes\":100663296,\"status\":%d,\"frameAfterReject\":%llu,"
           "\"allocationsAfterReject\":%llu,\"currentBytesAfterReject\":%llu}\n",
           (unsigned long long)aFrame,(unsigned long long)failedProgress.observedMetalCompletionFrameIndex,
           oldScale,newScale,cWidth,cHeight,(unsigned long long)aExpectedBytes,
           (unsigned long long)cRequiredBytes,(unsigned long long)aggregateRequired,(int)budgetStatus,
           (unsigned long long)failedProgress.submittedFrameIndex,
           (unsigned long long)rejectedStats.targetAllocations,
           (unsigned long long)rejectedStats.targetCurrentBytes);
    if (!require(budgetStatus==CJGUI_INTERNAL_RENDERER_EFFECT_RESOURCE_BUDGET_EXCEEDED &&
                 aggregateRequired>100663296u &&
                 failedProgress.submittedFrameIndex==aFrame &&
                 rejectedStats.targetAllocations==cacheStats.targetAllocations &&
                 rejectedStats.targetCurrentBytes==aExpectedBytes,
                 "total_budget_rejects_without_submission_or_allocation")) goto cleanup;

    gate.signaledValue=gateValue; gateReleased=YES;
    if (!require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),"total_budget_fence_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,aFrame,5000,&completed,
                &completionPumpMicros,&completionPumps),"total_budget_a_fence_completed")) goto cleanup;
    CjguiInternalRendererComposableNode noGroup=large_view_rect(112,9600,0,0,2049,2049,kBgR,kBgG,kBgB,1);
    if (!require(stage(session,112,&noGroup,1),"total_budget_retire_a_scene") ||
        cjgui_internal_renderer_composable_display_progress(session,&removedProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    uint64_t removedFrame=removedProgress.submittedFrameIndex;
    if (!require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),"total_budget_retire_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,removedFrame,5000,&removedProgress,
                &completionPumpMicros,&completionPumps),"total_budget_retire_frame")) goto cleanup;
    (void)wait_effect_ledger_bytes_with_main_pump(session,0,5000,&drainedStats,
        &markerMicros,&markerPumps);
    printf("EFFECT_TOTAL_BUDGET {\"phase\":\"after_fence\",\"completedFrame\":%llu,"
           "\"removedFrame\":%llu,\"ledgerBytes\":%llu}\n",
           (unsigned long long)removedProgress.observedMetalCompletionFrameIndex,
           (unsigned long long)removedFrame,(unsigned long long)drainedStats.targetCurrentBytes);
    if (!require(drainedStats.targetCurrentBytes==0,"total_budget_old_a_released_after_fence")) goto cleanup;

    nodes[0]=large_view_rect(113,9700,0,0,2049,2049,kBgR,kBgG,kBgB,1);
    nodes[1]=group(113,9510,0,0,300,160,2,1,0);
    nodes[1].clipConstraintCount=1; nodes[1].clip0Width=2049; nodes[1].clip0Height=2049;
    set_mask(&nodes[1],1,1,0,1);
    nodes[2]=large_view_rect(113,9511,0,0,300,160,.8,.2,.1,1);
    if (!require(stage(session,113,nodes,3),"total_budget_recover_c_same_group_identity") ||
        !effect_stats(session,&recoveredStats,"total_budget_recovered_c_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&recoveredProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    printf("EFFECT_TOTAL_BUDGET {\"phase\":\"recovered\",\"frame\":%llu,"
           "\"allocations\":%llu,\"currentBytes\":%llu,\"previousBytes\":%llu}\n",
           (unsigned long long)recoveredProgress.submittedFrameIndex,
           (unsigned long long)recoveredStats.targetAllocations,
           (unsigned long long)recoveredStats.targetCurrentBytes,
           (unsigned long long)drainedStats.targetCurrentBytes);
    ok=require(recoveredStats.targetAllocations==cacheStats.targetAllocations+1 &&
               recoveredStats.targetCurrentBytes>0,"total_budget_recovers_after_a_release");

cleanup:
    if (gateCommitted && !gateReleased) gate.signaledValue=gateValue;
    if (gateCommitted && queue) {
        uint64_t cleanupMicros=0; uint32_t cleanupPumps=0;
        (void)wait_marker_with_main_pump(queue,2000,&cleanupMicros,&cleanupPumps);
    }
    return ok;
}

static void make_backdrop_step_scene(CjguiInternalRendererComposableNode *nodes,
        uint64_t version, uint32_t edgeX, const double leftRGB[3],
        double opacity, double contentR, double contentG, double contentB,
        double contentAlpha, uint32_t radius, int laterSibling) {
    nodes[0]=rect(version,12000,0,0,edgeX,180,leftRGB[0],leftRGB[1],leftRGB[2],1);
    nodes[1]=group(version,12001,190,50,60,80,2,opacity,0);
    set_backdrop_blur(&nodes[1],radius,0);
    nodes[2]=rect(version,12002,190,50,60,80,contentR,contentG,contentB,contentAlpha);
    if (laterSibling)
        nodes[3]=rect(version,12003,202,80,16,20,contentR,contentG,contentB,1);
}

static int verify_backdrop_pixels_cache_clip(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[4];
    CjguiInternalRendererEffectStats before={0},cold={0},hot={0},sourceChanged={0},
        contentChanged={0},opacityChanged={0},laterChanged={0},clearChanged={0};
    const double red[3]={.96,.03,.02}, green[3]={.02,.91,.06};
    const double clear[3]={.08,.16,.20};
    const uint32_t edge=210,radius=4,sampleX=208,sampleY=90;
    double expectedBlur[3]={0};
    uint64_t started=0,ended=0;
    uint64_t coldMicros=0,hotMicros=0;
    double oldScale=0.0,newScale=0.0;
    uint32_t drawableWidth=0,drawableHeight=0;

    if (!require(set_probe_backing_scale(session,1.0,&oldScale,&newScale,
                 &drawableWidth,&drawableHeight) && drawableWidth==420 && drawableHeight==180,
                 "backdrop_oracle_fix_backing_scale_1x")) return 0;
    printf("BACKDROP_SCALE {\"before\":%.2f,\"after\":%.2f,\"drawable\":%ux%u}\n",
           oldScale,newScale,drawableWidth,drawableHeight);

    if (!effect_stats(session,&before,"backdrop_before_cold")) return 0;
    make_backdrop_step_scene(nodes,120,edge,red,1,0,0,0,0,radius,0);
    started=monotonic_micros();
    if (!require(stage(session,120,nodes,3),"backdrop_cold_accept")) return 0;
    ended=monotonic_micros(); coldMicros=ended>=started?ended-started:0;
    if (!effect_stats(session,&cold,"backdrop_cold_stats")) return 0;
    backdrop_step_oracle(sampleX,sampleY,420,180,edge,radius,clear,red,expectedBlur);
    if (!require(pixel_matches_oracle(session,sampleX,sampleY,expectedBlur,
                 clear[0],clear[1],clear[2],"backdrop_cold_scalar_gaussian"),
                 "backdrop_cold_oracle_pixel")) return 0;

    make_backdrop_step_scene(nodes,121,edge,red,1,0,0,0,0,radius,0);
    started=monotonic_micros();
    if (!require(stage(session,121,nodes,3),"backdrop_hot_accept")) return 0;
    ended=monotonic_micros(); hotMicros=ended>=started?ended-started:0;
    if (!effect_stats(session,&hot,"backdrop_hot_stats")) return 0;
    printf("BACKDROP_TIMING {\"phase\":\"cold_hot_static\",\"coldCpuPresentMicros\":%llu,"
           "\"hotCpuPresentMicros\":%llu,\"radiusPoints\":%u}\n",
           (unsigned long long)coldMicros,(unsigned long long)hotMicros,radius);
    if (!require(cold.backdropPrefixPasses>before.backdropPrefixPasses &&
                 cold.backdropHorizontalPasses>before.backdropHorizontalPasses &&
                 cold.backdropVerticalPasses>before.backdropVerticalPasses &&
                 hot.backdropPrefixPasses==cold.backdropPrefixPasses &&
                 hot.backdropCacheHits>cold.backdropCacheHits,
                 "backdrop_hot_reuses_unchanged_prefix")) return 0;
    if (!require(pixel_matches_oracle(session,sampleX,sampleY,expectedBlur,
                 clear[0],clear[1],clear[2],"backdrop_hot_scalar_gaussian"),
                 "backdrop_hot_oracle_pixel")) return 0;

    // Only a painter in front of the group changes. The cache must rebuild
    // the sampled prefix and the independent oracle predicts the new color.
    make_backdrop_step_scene(nodes,122,edge,green,1,0,0,0,0,radius,0);
    if (!require(stage(session,122,nodes,3),"backdrop_prefix_change_accept") ||
        !effect_stats(session,&sourceChanged,"backdrop_prefix_change_stats")) return 0;
    backdrop_step_oracle(sampleX,sampleY,420,180,edge,radius,clear,green,expectedBlur);
    if (!require(sourceChanged.backdropPrefixPasses>hot.backdropPrefixPasses &&
                 pixel_matches_oracle(session,sampleX,sampleY,expectedBlur,
                    clear[0],clear[1],clear[2],"backdrop_changed_prefix_scalar_gaussian"),
                 "backdrop_prefix_content_invalidates")) return 0;

    // Foreground content and group opacity are independent of the sampled
    // prefix. First make the group child translucent green over the blurred
    // background, then change group opacity and check the explicit equations.
    make_backdrop_step_scene(nodes,123,edge,green,1,.15,.85,.1,.25,radius,0);
    if (!require(stage(session,123,nodes,3),"backdrop_content_change_accept") ||
        !effect_stats(session,&contentChanged,"backdrop_content_change_stats")) return 0;
    double contentRGB[3]={expectedBlur[0]*.75+.15*.25,
                          expectedBlur[1]*.75+.85*.25,
                          expectedBlur[2]*.75+.10*.25};
    if (!require(contentChanged.backdropPrefixPasses==sourceChanged.backdropPrefixPasses &&
                 contentChanged.backdropCacheHits>sourceChanged.backdropCacheHits &&
                 pixel_matches_oracle(session,sampleX,sampleY,contentRGB,
                    clear[0],clear[1],clear[2],"backdrop_content_over_blur"),
                 "backdrop_content_reuses_sample")) return 0;

    make_backdrop_step_scene(nodes,124,edge,green,.5,.15,.85,.1,.25,radius,0);
    if (!require(stage(session,124,nodes,3),"backdrop_opacity_change_accept") ||
        !effect_stats(session,&opacityChanged,"backdrop_opacity_change_stats")) return 0;
    double unblurred[3]={sampleX<edge?green[0]:clear[0],
                         sampleX<edge?green[1]:clear[1],
                         sampleX<edge?green[2]:clear[2]};
    double opacityRGB[3]={.5*contentRGB[0]+.5*unblurred[0],
                          .5*contentRGB[1]+.5*unblurred[1],
                          .5*contentRGB[2]+.5*unblurred[2]};
    if (!require(opacityChanged.backdropPrefixPasses==contentChanged.backdropPrefixPasses &&
                 opacityChanged.backdropCacheHits>contentChanged.backdropCacheHits &&
                 pixel_matches_oracle(session,sampleX,sampleY,opacityRGB,
                    clear[0],clear[1],clear[2],"backdrop_group_opacity_equation"),
                 "backdrop_opacity_reuses_sample")) return 0;

    // A later painter overlays the result but is outside the sampled prefix.
    // Changing its color should not encode a new prefix or blur surface.
    const double laterA[3]={.9,.1,.7},laterB[3]={.1,.8,.3};
    make_backdrop_step_scene(nodes,125,edge,green,1,0,0,0,0,radius,1);
    nodes[3].fillRed=laterA[0]; nodes[3].fillGreen=laterA[1]; nodes[3].fillBlue=laterA[2];
    if (!require(stage(session,125,nodes,4),"backdrop_later_sibling_a_accept") ||
        !effect_stats(session,&laterChanged,"backdrop_later_sibling_a_stats")) return 0;
    if (!require(laterChanged.backdropPrefixPasses==opacityChanged.backdropPrefixPasses &&
                 laterChanged.backdropCacheHits>opacityChanged.backdropCacheHits &&
                 pixel_is_with_rgba_clear(session,sampleX,sampleY,clear[0],clear[1],clear[2],1,
                          laterA[0],laterA[1],laterA[2],1,"backdrop_later_sibling_paints_after_blur"),
                 "backdrop_later_sibling_a_does_not_invalidate")) return 0;
    make_backdrop_step_scene(nodes,126,edge,green,1,0,0,0,0,radius,1);
    nodes[3].fillRed=laterB[0]; nodes[3].fillGreen=laterB[1]; nodes[3].fillBlue=laterB[2];
    if (!require(stage(session,126,nodes,4),"backdrop_later_sibling_b_accept") ||
        !effect_stats(session,&clearChanged,"backdrop_later_sibling_b_stats")) return 0;
    if (!require(clearChanged.backdropPrefixPasses==laterChanged.backdropPrefixPasses &&
                 clearChanged.backdropCacheHits>laterChanged.backdropCacheHits &&
                 pixel_is_with_rgba_clear(session,sampleX,sampleY,clear[0],clear[1],clear[2],1,
                          laterB[0],laterB[1],laterB[2],1,"backdrop_later_sibling_b_paints_after_blur"),
                 "backdrop_later_sibling_change_is_not_prefix")) return 0;

    // A changed clear contributes to the sampled prefix even with unchanged
    // scene nodes. The CPU oracle is rerun from the new opaque clear color.
    const double alternateClear[3]={.88,.07,.11};
    backdrop_step_oracle(230,sampleY,420,180,edge,radius,alternateClear,green,expectedBlur);
    if (!require(pixel_matches_oracle(session,230,sampleY,expectedBlur,
                 alternateClear[0],alternateClear[1],alternateClear[2],
                 "backdrop_clear_change_scalar_gaussian"),
                 "backdrop_clear_change_pixel")) return 0;
    CjguiInternalRendererEffectStats afterAlternateClear={0};
    if (!effect_stats(session,&afterAlternateClear,"backdrop_clear_change_stats") ||
        !require(afterAlternateClear.backdropPrefixPasses>clearChanged.backdropPrefixPasses,
                 "backdrop_clear_is_part_of_prefix_key")) return 0;

    // The group clip limits where the blurred result is composited. Sampling
    // still reads the halo outside the clipped ROI.
    make_backdrop_step_scene(nodes,127,edge,green,1,0,0,0,0,radius,0);
    nodes[1].x=204; nodes[1].width=12;
    nodes[1].clipX=206; nodes[1].clipWidth=8;
    nodes[2].x=204; nodes[2].width=12; nodes[2].clipX=206; nodes[2].clipWidth=8;
    if (!require(stage(session,127,nodes,3),"backdrop_clip_accept")) return 0;
    double originalOutside[3]={green[0],green[1],green[2]};
    backdrop_step_oracle(207,sampleY,420,180,edge,radius,clear,green,expectedBlur);
    if (!require(pixel_is_with_rgba_clear(session,204,sampleY,clear[0],clear[1],clear[2],1,
                          originalOutside[0],originalOutside[1],originalOutside[2],1,
                          "backdrop_clip_outside_remains_unblurred"),
                 "backdrop_clip_outside_pixel") ||
        !require(pixel_matches_oracle(session,207,sampleY,expectedBlur,
                    clear[0],clear[1],clear[2],"backdrop_clip_inside_scalar_gaussian"),
                 "backdrop_clip_inside_pixel")) return 0;
    return 1;
}

static int verify_backdrop_failed_encode_retry(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats accepted={0},failed={0},retried={0};
    CjguiInternalRendererComposableDisplayProgress before={0},afterFailure={0},afterRetry={0};
    uint8_t retryPixel[4]={0},controlPixel[4]={0};
    uint64_t acceptedVersion=0,failedVersion=0;
    const double red[3]={.96,.03,.02}, green[3]={.02,.91,.06}, clear[3]={.08,.16,.20};
    const uint32_t edge=210,radius=4,sampleX=208,sampleY=90;
    double expected[3]={0};
    make_backdrop_step_scene(nodes,130,edge,red,1,0,0,0,0,radius,0);
    if (!require(stage(session,130,nodes,3),"backdrop_retry_accept_a") ||
        !effect_stats(session,&accepted,"backdrop_retry_a_stats") ||
        cjgui_internal_renderer_test_composable_scene_version(session,&acceptedVersion)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_composable_display_progress(session,&before)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    make_backdrop_step_scene(nodes,131,edge,green,1,0,0,0,0,radius,0);
    if (!require(cjgui_internal_renderer_test_fail_next_composable_main_encoder_after_effects(session)==
                 CJGUI_INTERNAL_RENDERER_OK,"backdrop_retry_arm_main_encoder_failure")) return 0;
    CjguiInternalRendererStatus failedStatus=stage_status(session,131,nodes,3);
    if (!effect_stats(session,&failed,"backdrop_retry_failed_stats") ||
        cjgui_internal_renderer_test_composable_scene_version(session,&failedVersion)!=CJGUI_INTERNAL_RENDERER_OK ||
        cjgui_internal_renderer_composable_display_progress(session,&afterFailure)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    printf("EFFECT_BACKDROP_RETRY {\"phase\":\"after_failure\",\"failedStatus\":%d,"
           "\"acceptedVersion\":%llu,\"versionAfterFailure\":%llu,"
           "\"submittedBeforeFailure\":%llu,\"submittedAfterFailure\":%llu,"
           "\"prefixPassesAccepted\":%llu,\"prefixPassesAfterFailure\":%llu,"
           "\"fallbacksAfterFailure\":%llu}\n",
           (int)failedStatus,(unsigned long long)acceptedVersion,(unsigned long long)failedVersion,
           (unsigned long long)before.submittedFrameIndex,(unsigned long long)afterFailure.submittedFrameIndex,
           (unsigned long long)accepted.backdropPrefixPasses,(unsigned long long)failed.backdropPrefixPasses,
           (unsigned long long)failed.backdropFallbacks);
    if (!require(failedStatus==CJGUI_INTERNAL_RENDERER_METAL_ENCODER_UNAVAILABLE,
                 "backdrop_retry_main_encoder_status") ||
        !require(afterFailure.submittedFrameIndex==before.submittedFrameIndex,
                 "backdrop_retry_failure_not_submitted") ||
        !require(afterFailure.effectSubmittedFrameIndex==before.effectSubmittedFrameIndex &&
                 afterFailure.effectMode==before.effectMode &&
                 afterFailure.effectFallbackReason==before.effectFallbackReason,
                 "backdrop_retry_precommit_keeps_public_effect_receipt") ||
        !require(failedVersion==acceptedVersion,"backdrop_retry_failure_keeps_accepted_scene")) return 0;

    CjguiInternalRendererStatus retryStatus=stage_status(session,131,nodes,3);
    if (!require(retryStatus==CJGUI_INTERNAL_RENDERER_OK,"backdrop_retry_same_candidate_accepted") ||
        !effect_stats(session,&retried,"backdrop_retry_retried_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&afterRetry)!=CJGUI_INTERNAL_RENDERER_OK ||
        !sample_pixel_with_rgba_clear(session,sampleX,sampleY,clear[0],clear[1],clear[2],1,retryPixel))
        return 0;
    backdrop_step_oracle(sampleX,sampleY,420,180,edge,radius,clear,green,expected);
    if (!require(afterRetry.submittedFrameIndex>afterFailure.submittedFrameIndex &&
                 retried.backdropPrefixPasses>=failed.backdropPrefixPasses+1 &&
                 retried.backdropFallbacks==failed.backdropFallbacks,
                 "backdrop_retry_reencodes_uncommitted_target")) return 0;
    int oracleOK=abs((int)retryPixel[2]-q(expected[0]))<=kTolerance &&
        abs((int)retryPixel[1]-q(expected[1]))<=kTolerance &&
        abs((int)retryPixel[0]-q(expected[2]))<=kTolerance &&
        abs((int)retryPixel[3]-255)<=kTolerance;
    CjguiInternalRendererStatus controlStatus=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config={420,180,kBgR,kBgG,kBgB,1.0};
    uint64_t controlSession=cjgui_internal_renderer_create(&config,&controlStatus);
    double ignoredBefore=0.0,ignoredAfter=0.0; uint32_t ignoredWidth=0,ignoredHeight=0;
    int controlOK=controlStatus==CJGUI_INTERNAL_RENDERER_OK &&
        controlSession!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN &&
        set_probe_backing_scale(controlSession,1.0,&ignoredBefore,&ignoredAfter,
                                &ignoredWidth,&ignoredHeight) &&
        stage(controlSession,131,nodes,3) &&
        sample_pixel_with_rgba_clear(controlSession,sampleX,sampleY,clear[0],clear[1],clear[2],1,controlPixel);
    if (controlSession!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN) {
        if (cjgui_internal_renderer_request_close(controlSession)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
        if (cjgui_internal_renderer_destroy(controlSession)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
    }
    int sameControl=bgra_close(retryPixel,controlPixel,kTolerance);
    printf("EFFECT_BACKDROP_RETRY {\"phase\":\"pixel_control\",\"oracleMatch\":%s,"
           "\"retryBGRA\":[%u,%u,%u,%u],\"controlBGRA\":[%u,%u,%u,%u],"
           "\"retryMatchesControl\":%s}\n",
           oracleOK?"true":"false",retryPixel[0],retryPixel[1],retryPixel[2],retryPixel[3],
           controlPixel[0],controlPixel[1],controlPixel[2],controlPixel[3],
           sameControl?"true":"false");
    if (!require(oracleOK,"backdrop_retry_matches_scalar_oracle") ||
        !require(controlOK,"backdrop_retry_control_scene_renders") ||
        !require(sameControl,"backdrop_retry_matches_no_failure_control")) return 0;
    printf("EFFECT_BACKDROP_RETRY {\"phase\":\"after_retry\",\"submittedAfterRetry\":%llu,"
           "\"prefixPassesAfterRetry\":%llu}\n",
           (unsigned long long)afterRetry.submittedFrameIndex,
           (unsigned long long)retried.backdropPrefixPasses);
    return 1;
}

static int verify_backdrop_encoder_fallback(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats before={0},after={0};
    CjguiInternalRendererComposableDisplayProgress beforeProgress={0},afterProgress={0};
    const double red[3]={.96,.03,.02},green[3]={.02,.91,.06};
    uint8_t unblurredBGRA[4]={0};
    make_backdrop_step_scene(nodes,135,210,red,1,0,0,0,0,4,0);
    if (!require(set_probe_backing_scale(session,1.0,&(double){0},&(double){0},
                 &(uint32_t){0},&(uint32_t){0}),"backdrop_fallback_scale_1x") ||
        !require(stage(session,135,nodes,3),"backdrop_fallback_accept_a") ||
        !effect_stats(session,&before,"backdrop_fallback_before_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&beforeProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    make_backdrop_step_scene(nodes,136,210,green,1,0,0,0,0,4,0);
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session,208,90)==
                 CJGUI_INTERNAL_RENDERER_OK,"backdrop_fallback_request_pixel") ||
        !require(cjgui_internal_renderer_test_fail_next_composable_backdrop_encode(session)==
                 CJGUI_INTERNAL_RENDERER_OK,"backdrop_fallback_arm_blur_failure")) return 0;
    CjguiInternalRendererStatus status=stage_status(session,136,nodes,3);
    if (cjgui_internal_renderer_test_composable_drawable_pixel(session,&unblurredBGRA[0],
            &unblurredBGRA[1],&unblurredBGRA[2],&unblurredBGRA[3])!=CJGUI_INTERNAL_RENDERER_OK ||
        !effect_stats(session,&after,"backdrop_fallback_after_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&afterProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    printf("EFFECT_BACKDROP_FALLBACK {\"status\":%d,\"frameBefore\":%llu,\"frameAfter\":%llu,"
           "\"fallbacksBefore\":%llu,\"fallbacksAfter\":%llu,\"pixelBGRA\":[%u,%u,%u,%u]}\n",
           (int)status,(unsigned long long)beforeProgress.submittedFrameIndex,
           (unsigned long long)afterProgress.submittedFrameIndex,
           (unsigned long long)before.backdropFallbacks,(unsigned long long)after.backdropFallbacks,
           unblurredBGRA[0],unblurredBGRA[1],unblurredBGRA[2],unblurredBGRA[3]);
    printf("EFFECT_PUBLIC_RECEIPT {\"phase\":\"encode_fallback\",\"scene\":%llu,"
           "\"frame\":%llu,\"requestedRadius\":%u,\"mode\":%u,\"reason\":%u,\"completion\":%u}\n",
           (unsigned long long)afterProgress.effectSubmittedSceneVersion,
           (unsigned long long)afterProgress.effectSubmittedFrameIndex,
           afterProgress.effectRequestedRadiusPoints,afterProgress.effectMode,
           afterProgress.effectFallbackReason,afterProgress.effectCompletion);
    return require(status==CJGUI_INTERNAL_RENDERER_OK &&
                   afterProgress.submittedFrameIndex>beforeProgress.submittedFrameIndex &&
                   after.backdropFallbacks==before.backdropFallbacks+1 &&
                   beforeProgress.effectSubmittedSceneVersion==135 &&
                   beforeProgress.effectRequestedRadiusPoints==4 &&
                   beforeProgress.effectMode==CJGUI_INTERNAL_BACKDROP_BLURRED &&
                   beforeProgress.effectFallbackReason==CJGUI_INTERNAL_BACKDROP_REASON_NONE &&
                   afterProgress.effectSubmittedSceneVersion==136 &&
                   afterProgress.effectSubmittedFrameIndex==afterProgress.submittedFrameIndex &&
                   afterProgress.effectRequestedRadiusPoints==4 &&
                   afterProgress.effectMode==CJGUI_INTERNAL_BACKDROP_UNBLURRED &&
                   afterProgress.effectFallbackReason==CJGUI_INTERNAL_BACKDROP_REASON_ENCODE_FAILED &&
                   (afterProgress.effectCompletion==CJGUI_INTERNAL_BACKDROP_COMPLETION_PENDING ||
                    afterProgress.effectCompletion==CJGUI_INTERNAL_BACKDROP_COMPLETION_SUCCEEDED) &&
                   abs((int)unblurredBGRA[2]-q(green[0]))<=kTolerance &&
                   abs((int)unblurredBGRA[1]-q(green[1]))<=kTolerance &&
                   abs((int)unblurredBGRA[0]-q(green[2]))<=kTolerance &&
                   abs((int)unblurredBGRA[3]-255)<=kTolerance,
                   "backdrop_encode_failure_commits_unblurred_fallback");
}

static void make_backdrop_budget_scene(CjguiInternalRendererComposableNode *nodes,uint64_t version) {
    nodes[0]=large_view_rect(version,13000,0,0,1024,2048,.96,.03,.02,1);
    // Five ordinary transparent groups consume 80 MiB. One small blur group
    // then needs a full-frame replay whose additional 16 MiB crosses the
    // 96 MiB ledger budget, while all accepted effect targets still fit.
    for (uint32_t i=0;i<5;i++) {
        uint32_t groupIndex=1+i*2;
        uint64_t groupId=13010u+(uint64_t)i*2u;
        nodes[groupIndex]=group(version,groupId,0,0,2048,2048,2,1,0);
        nodes[groupIndex].clipConstraintCount=1;
        nodes[groupIndex].clip0X=0; nodes[groupIndex].clip0Y=0;
        nodes[groupIndex].clip0Width=2049; nodes[groupIndex].clip0Height=2049;
        nodes[groupIndex+1]=large_view_rect(version,groupId+1,0,0,2048,2048,0,0,0,0);
    }
    nodes[11]=group(version,13030,1000,60,60,80,2,1,0);
    nodes[11].clipConstraintCount=1;
    nodes[11].clip0X=0; nodes[11].clip0Y=0;
    nodes[11].clip0Width=2049; nodes[11].clip0Height=2049;
    set_backdrop_blur(&nodes[11],16,0);
    nodes[12]=rect(version,13031,1000,60,80,60,0,0,0,0);
}

static int verify_backdrop_budget_fallback(uint64_t session) {
    uint32_t viewWidth=0,viewHeight=0;
    double beforeScale=0.0,afterScale=0.0;
    CjguiInternalRendererComposableNode nodes[13];
    CjguiInternalRendererEffectStats before={0},fallback={0};
    CjguiInternalRendererComposableDisplayProgress beforeProgress={0},fallbackProgress={0};
    uint8_t fallbackPixel[4]={0};
    if (!require(cjgui_internal_renderer_test_set_composable_viewport_size(session,2048,2048,
                 &viewWidth,&viewHeight)==CJGUI_INTERNAL_RENDERER_OK &&
                 viewWidth>=2048 && viewHeight>=2048,"backdrop_budget_viewport") ||
        !require(set_probe_backing_scale(session,1.0,&beforeScale,&afterScale,&viewWidth,&viewHeight),
                 "backdrop_budget_scale")) return 0;
    if (!effect_stats(session,&before,"backdrop_budget_before_stats") ||
        !cjgui_internal_renderer_composable_display_progress(session,&beforeProgress)) return 0;
    make_backdrop_budget_scene(nodes,140);
    if (!require(cjgui_internal_renderer_test_request_composable_drawable_pixel(session,1023,100)==
                 CJGUI_INTERNAL_RENDERER_OK,"backdrop_budget_request_fallback_pixel")) return 0;
    CjguiInternalRendererStatus fallbackStatus=stage_status(session,140,nodes,13);
    if (cjgui_internal_renderer_test_composable_drawable_pixel(session,&fallbackPixel[0],
            &fallbackPixel[1],&fallbackPixel[2],&fallbackPixel[3])!=CJGUI_INTERNAL_RENDERER_OK ||
        !effect_stats(session,&fallback,"backdrop_budget_fallback_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&fallbackProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    printf("EFFECT_BACKDROP_BUDGET {\"phase\":\"accepted_unblurred_fallback\","
           "\"status\":%d,\"frameBefore\":%llu,\"frameAfter\":%llu,"
           "\"targetBytesBefore\":%llu,\"targetBytesAfter\":%llu,\"allocationsAfter\":%llu,"
           "\"fallbacksBefore\":%llu,\"fallbacksAfter\":%llu,"
           "\"fallbackBGRA\":[%u,%u,%u,%u]}\n",
           (int)fallbackStatus,(unsigned long long)beforeProgress.submittedFrameIndex,
           (unsigned long long)fallbackProgress.submittedFrameIndex,
           (unsigned long long)before.targetCurrentBytes,(unsigned long long)fallback.targetCurrentBytes,
           (unsigned long long)fallback.targetAllocations,
           (unsigned long long)before.backdropFallbacks,(unsigned long long)fallback.backdropFallbacks,
           fallbackPixel[0],fallbackPixel[1],fallbackPixel[2],fallbackPixel[3]);
    return require(fallbackStatus==CJGUI_INTERNAL_RENDERER_OK &&
                   fallbackProgress.submittedFrameIndex>beforeProgress.submittedFrameIndex &&
                   fallback.backdropFallbacks==before.backdropFallbacks+1 &&
                   fallbackProgress.effectSubmittedSceneVersion==140 &&
                   fallbackProgress.effectSubmittedFrameIndex==fallbackProgress.submittedFrameIndex &&
                   fallbackProgress.effectRequestedRadiusPoints==16 &&
                   fallbackProgress.effectMode==CJGUI_INTERNAL_BACKDROP_UNBLURRED &&
                   fallbackProgress.effectFallbackReason==CJGUI_INTERNAL_BACKDROP_REASON_RESOURCE_BUDGET &&
                   abs((int)fallbackPixel[2]-q(.96))<=kTolerance &&
                   abs((int)fallbackPixel[1]-q(.03))<=kTolerance &&
                   abs((int)fallbackPixel[0]-q(.02))<=kTolerance &&
                   abs((int)fallbackPixel[3]-255)<=kTolerance,
                   "backdrop_budget_exhaustion_takes_accepted_unblurred_fallback");
}

static int verify_backdrop_cache_hit_inflight_generation(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats accepted={0},cacheHit={0},afterC={0},afterFence={0};
    CjguiInternalRendererComposableDisplayProgress first={0},inflight={0},cProgress={0},completed={0};
    id<MTLCommandQueue> queue=nil; id<MTLDevice> device=nil;
    id<MTLSharedEvent> gate=nil; id<MTLCommandBuffer> gateBuffer=nil;
    BOOL gateCommitted=NO,gateReleased=NO;
    uint64_t gateValue=0,markerMicros=0,completionMicros=0;
    uint32_t markerPumps=0,completionPumps=0;
    const double red[3]={.96,.03,.02},green[3]={.02,.91,.06};
    int ok=0;

    make_backdrop_step_scene(nodes,150,210,red,1,0,0,0,0,4,0);
    if (!require(set_probe_backing_scale(session,1.0,&(double){0},&(double){0},
                 &(uint32_t){0},&(uint32_t){0}),"backdrop_inflight_scale_1x") ||
        !require(stage(session,150,nodes,3),"backdrop_inflight_accept_a") ||
        !effect_stats(session,&accepted,"backdrop_inflight_a_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&first)!=CJGUI_INTERNAL_RENDERER_OK)
        return 0;
    if (!renderer_queue_and_device(&queue,&device) ||
        !require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),
                 "backdrop_inflight_a_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,first.submittedFrameIndex,5000,&first,
                 &completionMicros,&completionPumps),"backdrop_inflight_a_completed")) return 0;
    gate=[device newSharedEvent];
    if (!require(gate!=nil,"backdrop_inflight_gate_event")) return 0;
    gateBuffer=[queue commandBuffer];
    if (!require(gateBuffer!=nil,"backdrop_inflight_gate_buffer")) return 0;
    gateValue=gate.signaledValue+1;
    [gateBuffer encodeWaitForEvent:gate value:gateValue];
    [gateBuffer commit]; gateCommitted=YES;

    make_backdrop_step_scene(nodes,151,210,red,1,0,0,0,0,4,0);
    if (!require(stage(session,151,nodes,3),"backdrop_inflight_submit_cached_a") ||
        !effect_stats(session,&cacheHit,"backdrop_inflight_cache_hit_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&inflight)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    if (!require(inflight.observedMetalCompletionFrameIndex<inflight.submittedFrameIndex &&
                 cacheHit.backdropPrefixPasses==accepted.backdropPrefixPasses &&
                 cacheHit.backdropCacheHits>accepted.backdropCacheHits,
                 "backdrop_inflight_a_is_cache_hit_and_pending")) goto cleanup;

    make_backdrop_step_scene(nodes,152,210,green,1,0,0,0,0,4,0);
    if (!require(stage(session,152,nodes,3),"backdrop_inflight_submit_c_prefix_change") ||
        !effect_stats(session,&afterC,"backdrop_inflight_c_stats") ||
        cjgui_internal_renderer_composable_display_progress(session,&cProgress)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    BOOL oldPrefixHeld=afterC.targetCurrentBytes>cacheHit.targetCurrentBytes &&
        cProgress.observedMetalCompletionFrameIndex<inflight.submittedFrameIndex &&
        afterC.backdropPrefixPasses>cacheHit.backdropPrefixPasses;
    printf("EFFECT_BACKDROP_INFLIGHT {\"phase\":\"before_fence\",\"aFrame\":%llu,"
           "\"cFrame\":%llu,\"completedFrame\":%llu,\"bytesA\":%llu,\"bytesAfterC\":%llu,"
           "\"prefixPassesA\":%llu,\"prefixPassesAfterC\":%llu,\"cacheHitsA\":%llu,"
           "\"cacheHitsAfterHit\":%llu,\"oldPrefixHeld\":%s}\n",
           (unsigned long long)inflight.submittedFrameIndex,(unsigned long long)cProgress.submittedFrameIndex,
           (unsigned long long)cProgress.observedMetalCompletionFrameIndex,
           (unsigned long long)cacheHit.targetCurrentBytes,(unsigned long long)afterC.targetCurrentBytes,
           (unsigned long long)accepted.backdropPrefixPasses,(unsigned long long)afterC.backdropPrefixPasses,
           (unsigned long long)accepted.backdropCacheHits,(unsigned long long)cacheHit.backdropCacheHits,
           oldPrefixHeld?"true":"false");
    if (!require(oldPrefixHeld,"backdrop_cache_hit_generation_charged_until_fence")) goto cleanup;

    gate.signaledValue=gateValue; gateReleased=YES;
    if (!require(wait_marker_with_main_pump(queue,5000,&markerMicros,&markerPumps),
                 "backdrop_inflight_completion_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,cProgress.submittedFrameIndex,5000,&completed,
                 &completionMicros,&completionPumps),"backdrop_inflight_c_completed") ||
        !effect_stats(session,&afterFence,"backdrop_inflight_after_fence_stats")) goto cleanup;
    BOOL retired=afterFence.targetCurrentBytes<afterC.targetCurrentBytes &&
        afterFence.backdropPrefixPasses==afterC.backdropPrefixPasses;
    printf("EFFECT_BACKDROP_INFLIGHT {\"phase\":\"after_fence\",\"completedFrame\":%llu,"
           "\"bytesAfterC\":%llu,\"bytesAfterFence\":%llu,\"retiredOldPrefix\":%s,"
           "\"fenceCpuMicros\":%llu,\"completionPumpCpuMicros\":%llu}\n",
           (unsigned long long)completed.observedMetalCompletionFrameIndex,
           (unsigned long long)afterC.targetCurrentBytes,(unsigned long long)afterFence.targetCurrentBytes,
           retired?"true":"false",(unsigned long long)markerMicros,
           (unsigned long long)completionMicros);
    ok=require(retired,"backdrop_old_prefix_released_after_fence");

cleanup:
    if (gateCommitted && !gateReleased) gate.signaledValue=gateValue;
    if (gateCommitted && queue) {
        uint64_t cleanupMicros=0; uint32_t cleanupPumps=0;
        (void)wait_marker_with_main_pump(queue,2000,&cleanupMicros,&cleanupPumps);
    }
    return ok;
}

static int verify_backdrop_old_completion_keeps_new_fallback_receipt(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererComposableDisplayProgress initial={0},blurred={0},fallback={0},
        afterOld={0},afterNew={0};
    id<MTLCommandQueue> queue=nil; id<MTLDevice> device=nil;
    id<MTLSharedEvent> gateA=nil,gateB=nil;
    id<MTLCommandBuffer> waitB=nil;
    BOOL committedA=NO,committedB=NO,releasedA=NO,releasedB=NO;
    uint64_t aValue=0,bValue=0,micros=0;
    uint32_t pumps=0;
    const double red[3]={.96,.03,.02},green[3]={.02,.91,.06},blue[3]={.03,.04,.92};
    int ok=0;
    make_backdrop_step_scene(nodes,190,210,red,1,0,0,0,0,4,0);
    if (!require(set_probe_backing_scale(session,1.0,&(double){0},&(double){0},
                 &(uint32_t){0},&(uint32_t){0}),"backdrop_receipt_scale") ||
        !require(stage(session,190,nodes,3),"backdrop_receipt_initial_accept") ||
        cjgui_internal_renderer_composable_display_progress(session,&initial)!=CJGUI_INTERNAL_RENDERER_OK ||
        !renderer_queue_and_device(&queue,&device) ||
        !require(wait_marker_with_main_pump(queue,5000,&micros,&pumps),"backdrop_receipt_initial_marker") ||
        !require(wait_renderer_frame_with_main_pump(session,initial.submittedFrameIndex,5000,&initial,
                 &micros,&pumps),"backdrop_receipt_initial_completed")) return 0;
    gateA=[device newSharedEvent]; gateB=[device newSharedEvent];
    if (!require(gateA!=nil && gateB!=nil,"backdrop_receipt_gates")) return 0;
    id<MTLCommandBuffer> waitA=[queue commandBuffer];
    if (!require(waitA!=nil,"backdrop_receipt_gate_a_buffer")) return 0;
    aValue=gateA.signaledValue+1;
    [waitA encodeWaitForEvent:gateA value:aValue]; [waitA commit]; committedA=YES;
    make_backdrop_step_scene(nodes,191,210,green,1,0,0,0,0,4,0);
    if (!require(stage(session,191,nodes,3),"backdrop_receipt_blurred_submit") ||
        cjgui_internal_renderer_composable_display_progress(session,&blurred)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    waitB=[queue commandBuffer];
    if (!require(waitB!=nil,"backdrop_receipt_gate_b_buffer")) goto cleanup;
    bValue=gateB.signaledValue+1;
    [waitB encodeWaitForEvent:gateB value:bValue]; [waitB commit]; committedB=YES;
    make_backdrop_step_scene(nodes,192,210,blue,1,0,0,0,0,4,0);
    if (!require(cjgui_internal_renderer_test_fail_next_composable_backdrop_encode(session)==
                 CJGUI_INTERNAL_RENDERER_OK,"backdrop_receipt_force_fallback") ||
        !require(stage(session,192,nodes,3),"backdrop_receipt_fallback_submit") ||
        cjgui_internal_renderer_composable_display_progress(session,&fallback)!=CJGUI_INTERNAL_RENDERER_OK)
        goto cleanup;
    if (!require(blurred.effectMode==CJGUI_INTERNAL_BACKDROP_BLURRED &&
                 fallback.effectMode==CJGUI_INTERNAL_BACKDROP_UNBLURRED &&
                 fallback.effectFallbackReason==CJGUI_INTERNAL_BACKDROP_REASON_ENCODE_FAILED &&
                 fallback.effectCompletion==CJGUI_INTERNAL_BACKDROP_COMPLETION_PENDING,
                 "backdrop_receipt_new_fallback_pending")) goto cleanup;
    gateA.signaledValue=aValue; releasedA=YES;
    if (!require(wait_renderer_frame_with_main_pump(session,blurred.submittedFrameIndex,5000,&afterOld,
                 &micros,&pumps),"backdrop_receipt_old_blur_completed")) goto cleanup;
    BOOL staleIgnored=afterOld.effectSubmittedSceneVersion==192 &&
        afterOld.effectSubmittedFrameIndex==fallback.effectSubmittedFrameIndex &&
        afterOld.effectMode==CJGUI_INTERNAL_BACKDROP_UNBLURRED &&
        afterOld.effectFallbackReason==CJGUI_INTERNAL_BACKDROP_REASON_ENCODE_FAILED &&
        afterOld.effectCompletion==CJGUI_INTERNAL_BACKDROP_COMPLETION_PENDING;
    gateB.signaledValue=bValue; releasedB=YES;
    if (!require(wait_renderer_frame_with_main_pump(session,fallback.submittedFrameIndex,5000,&afterNew,
                 &micros,&pumps),"backdrop_receipt_fallback_completed")) goto cleanup;
    printf("EFFECT_PUBLIC_RECEIPT {\"phase\":\"stale_completion\",\"oldFrame\":%llu,"
           "\"newFrame\":%llu,\"oldIgnored\":%s,\"newCompletion\":%u}\n",
           (unsigned long long)blurred.submittedFrameIndex,
           (unsigned long long)fallback.submittedFrameIndex,staleIgnored?"true":"false",
           afterNew.effectCompletion);
    ok=require(staleIgnored && afterNew.effectSubmittedFrameIndex==fallback.effectSubmittedFrameIndex &&
        afterNew.effectCompletion==CJGUI_INTERNAL_BACKDROP_COMPLETION_SUCCEEDED,
        "backdrop_old_completion_cannot_confirm_new_fallback");
cleanup:
    if (committedA && !releasedA) gateA.signaledValue=aValue;
    if (committedB && !releasedB) gateB.signaledValue=bValue;
    if (queue) (void)wait_marker_with_main_pump(queue,2000,&micros,&pumps);
    return ok;
}

// Keep the drawable at 420x180 while changing the logical viewport from
// 420x180@1x to 210x90@2x. Both sample ROIs clip to the whole drawable, so a
// key made only from pixel ROI, drawable size and radius falsely hits.
static int verify_backdrop_same_drawable_scale_dependency(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats one={0},two={0};
    double before=0,after=0;
    uint32_t dw=0,dh=0,vw=0,vh=0;
    uint8_t twoPixel[4]={0},controlPixel[4]={0};
    const double clear[3]={.08,.16,.20};
    const double red[3]={.96,.03,.02};
    if (!require(cjgui_internal_renderer_test_set_composable_viewport_size(
            session,420,180,&vw,&vh)==CJGUI_INTERNAL_RENDERER_OK && vw==420 && vh==180,
            "backdrop_scale_initial_viewport") ||
        !require(set_probe_backing_scale(session,1.0,&before,&after,&dw,&dh) &&
            dw==420 && dh==180,"backdrop_scale_initial_drawable")) return 0;
    nodes[0]=rect(170,17000,0,0,105,180,red[0],red[1],red[2],1);
    nodes[1]=group(170,17001,0,0,420,180,2,1,0);
    set_backdrop_blur(&nodes[1],8,0);
    nodes[2]=rect(170,17002,0,0,420,180,0,0,0,0);
    if (!require(stage(session,170,nodes,3),"backdrop_scale_1x_accept") ||
        !effect_stats(session,&one,"backdrop_scale_1x_stats")) return 0;
    if (!require(set_probe_backing_scale(session,2.0,&before,&after,&dw,&dh) &&
            dw==840 && dh==360,"backdrop_scale_toggle_2x") ||
        !require(cjgui_internal_renderer_test_set_composable_viewport_size(
            session,210,90,&vw,&vh)==CJGUI_INTERNAL_RENDERER_OK && vw==210 && vh==90,
            "backdrop_scale_inverse_viewport")) return 0;
    for (uint32_t i=0;i<3;i++) nodes[i].projectionVersion=171;
    if (!require(stage(session,171,nodes,3),"backdrop_scale_2x_accept") ||
        !effect_stats(session,&two,"backdrop_scale_2x_stats") ||
        !sample_pixel_with_rgba_clear(session,104,45,clear[0],clear[1],clear[2],1,twoPixel)) return 0;

    CjguiInternalRendererConfig config={420,180,kBgR,kBgG,kBgB,1};
    CjguiInternalRendererStatus status=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    uint64_t control=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
            control!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_scale_control_create")) return 0;
    int controlOK=set_probe_backing_scale(control,2.0,&before,&after,&dw,&dh) &&
        cjgui_internal_renderer_test_set_composable_viewport_size(control,210,90,&vw,&vh)==CJGUI_INTERNAL_RENDERER_OK &&
        stage(control,171,nodes,3) &&
        sample_pixel_with_rgba_clear(control,104,45,clear[0],clear[1],clear[2],1,controlPixel);
    if (cjgui_internal_renderer_request_close(control)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
    if (cjgui_internal_renderer_destroy(control)!=CJGUI_INTERNAL_RENDERER_OK) controlOK=0;
    printf("BACKDROP_DEPENDENCY {\"kind\":\"same_drawable_scale\",\"drawable\":\"420x180\","
           "\"passesBefore\":%llu,\"passesAfter\":%llu,\"actualBGRA\":[%u,%u,%u,%u],"
           "\"recomputedBGRA\":[%u,%u,%u,%u]}\n",
           (unsigned long long)one.backdropPrefixPasses,(unsigned long long)two.backdropPrefixPasses,
           twoPixel[0],twoPixel[1],twoPixel[2],twoPixel[3],
           controlPixel[0],controlPixel[1],controlPixel[2],controlPixel[3]);
    return require(controlOK && two.backdropPrefixPasses>one.backdropPrefixPasses &&
        memcmp(twoPixel,controlPixel,sizeof(twoPixel))==0,
        "backdrop_same_drawable_scale_recomputes_matching_pixels");
}

static int verify_backdrop_caret_color_source_dependency(uint64_t session) {
    CjguiInternalRendererComposableNode nodes[3];
    CjguiInternalRendererEffectStats before={0},after={0};
    uint8_t accentPixel[4]={0},declaredPixel[4]={0},recomputedPixel[4]={0};
    const double clear[3]={.08,.16,.20};
    nodes[0]=rect(180,18000,150,50,100,80,0,0,0,0);
    nodes[0].nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT_INPUT;
    nodes[0].textRed=.95; nodes[0].textGreen=.04; nodes[0].textBlue=.02;
    nodes[0].textAlpha=1;
    nodes[1]=group(180,18001,0,0,420,180,2,1,0);
    set_backdrop_blur(&nodes[1],2,0);
    nodes[2]=rect(180,18002,0,0,420,180,0,0,0,0);
    if (!require(stage(session,180,nodes,3),"backdrop_caret_scene_accept") ||
        !require(cjgui_internal_renderer_test_set_composable_caret_color_source(
            session,18000,190,80,16,20,0)==CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_caret_accent_source") ||
        !sample_pixel_with_rgba_clear(session,194,90,clear[0],clear[1],clear[2],1,accentPixel) ||
        !effect_stats(session,&before,"backdrop_caret_accent_stats")) return 0;
    if (!require(cjgui_internal_renderer_test_set_composable_caret_color_source(
            session,18000,190,80,16,20,1)==CJGUI_INTERNAL_RENDERER_OK,
            "backdrop_caret_declared_source") ||
        !sample_pixel_with_rgba_clear(session,194,90,clear[0],clear[1],clear[2],1,declaredPixel) ||
        !effect_stats(session,&after,"backdrop_caret_declared_stats")) return 0;
    uint8_t ignored[4]={0};
    if (!sample_pixel_with_rgba_clear(session,194,90,.5,.3,.1,1,ignored) ||
        !sample_pixel_with_rgba_clear(session,194,90,clear[0],clear[1],clear[2],1,recomputedPixel)) return 0;
    printf("BACKDROP_DEPENDENCY {\"kind\":\"caret_color_source\","
           "\"sameCaretRect\":[190,80,16,20],\"passesBefore\":%llu,\"passesAfter\":%llu,"
           "\"accentBGRA\":[%u,%u,%u,%u],\"declaredBGRA\":[%u,%u,%u,%u],"
           "\"recomputedBGRA\":[%u,%u,%u,%u]}\n",
           (unsigned long long)before.backdropPrefixPasses,
           (unsigned long long)after.backdropPrefixPasses,
           accentPixel[0],accentPixel[1],accentPixel[2],accentPixel[3],
           declaredPixel[0],declaredPixel[1],declaredPixel[2],declaredPixel[3],
           recomputedPixel[0],recomputedPixel[1],recomputedPixel[2],recomputedPixel[3]);
    return require(after.backdropPrefixPasses>before.backdropPrefixPasses &&
        memcmp(accentPixel,recomputedPixel,sizeof(accentPixel))!=0 &&
        memcmp(declaredPixel,recomputedPixel,sizeof(declaredPixel))==0,
        "backdrop_same_caret_rect_color_source_recomputes_matching_pixels");
}

int main(void) {
    CjguiInternalRendererStatus status=CJGUI_INTERNAL_RENDERER_INTERNAL_ERROR;
    CjguiInternalRendererConfig config={420,180,kBgR,kBgG,kBgB,1.0};
    uint64_t session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK && session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"create")) return 1;
    int ok=verify_isolation_and_nesting(session) && verify_blend_and_order(session) &&
           verify_mask_domain_and_motion(session) && verify_clip_resize_and_rejection(session) &&
           verify_cache_and_content_invalidation(session) &&
           verify_multiply_background_recomposition(session) &&
           verify_no_group_resource_baseline(session) && verify_target_budget_rejection(session) &&
           verify_mask_backing_scale(session);
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    if (!ok) return 1;
    // Run the controlled in-flight lifetime experiment in a fresh session so
    // prior cache generations cannot contaminate its zero-byte ledger baseline.
    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK && session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,
                 "lifecycle_session_create")) return 1;
    @autoreleasepool {
        ok=verify_controlled_effect_target_lifetime(session);
    }
    CjguiInternalRendererEffectStats afterPool={0};
    if (!effect_stats(session,&afterPool,"lifecycle_after_outer_pool_drain") ||
        afterPool.targetCurrentBytes!=0) ok=0;
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    if (!ok) return 1;
    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"encoder_retry_session_create")) return 1;
    uint8_t controlBGRA[4]={0};
    @autoreleasepool {
        ok=verify_accepted_main_encoder_retry(session,controlBGRA);
    }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) ok=0;
    int acceptedEncoderOK=ok;
    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"cache_inflight_session_create")) return 1;
    int cacheInflightOK=0;
    @autoreleasepool {
        cacheInflightOK=verify_cache_hit_inflight_generation(session);
    }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) cacheInflightOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) cacheInflightOK=0;
    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"total_budget_session_create")) return 1;
    int totalBudgetOK=0;
    @autoreleasepool {
        totalBudgetOK=verify_inflight_total_budget_recovery(session);
    }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) totalBudgetOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) totalBudgetOK=0;
    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_session_create")) return 1;
    int backdropPixelsOK=0,backdropRetryOK=0,backdropFallbackOK=0;
    @autoreleasepool {
        backdropPixelsOK=verify_backdrop_pixels_cache_clip(session);
        backdropRetryOK=verify_backdrop_failed_encode_retry(session);
        backdropFallbackOK=verify_backdrop_encoder_fallback(session);
    }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropFallbackOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropFallbackOK=0;

    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_budget_session_create")) return 1;
    int backdropBudgetOK=0;
    @autoreleasepool { backdropBudgetOK=verify_backdrop_budget_fallback(session); }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropBudgetOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropBudgetOK=0;

    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_inflight_session_create")) return 1;
    int backdropInflightOK=0;
    @autoreleasepool { backdropInflightOK=verify_backdrop_cache_hit_inflight_generation(session); }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropInflightOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropInflightOK=0;

    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_dependency_session_create")) return 1;
    int backdropScaleDependencyOK=0;
    @autoreleasepool { backdropScaleDependencyOK=verify_backdrop_same_drawable_scale_dependency(session); }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropScaleDependencyOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropScaleDependencyOK=0;

    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_caret_dependency_session_create")) return 1;
    int backdropCaretDependencyOK=0;
    @autoreleasepool { backdropCaretDependencyOK=verify_backdrop_caret_color_source_dependency(session); }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropCaretDependencyOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropCaretDependencyOK=0;

    session=cjgui_internal_renderer_create(&config,&status);
    if (!require(status==CJGUI_INTERNAL_RENDERER_OK &&
                 session!=CJGUI_INTERNAL_RENDERER_INVALID_SESSION_TOKEN,"backdrop_receipt_session_create")) return 1;
    int backdropStaleReceiptOK=0;
    @autoreleasepool { backdropStaleReceiptOK=verify_backdrop_old_completion_keeps_new_fallback_receipt(session); }
    if (cjgui_internal_renderer_request_close(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropStaleReceiptOK=0;
    if (cjgui_internal_renderer_destroy(session)!=CJGUI_INTERNAL_RENDERER_OK) backdropStaleReceiptOK=0;

    if (!acceptedEncoderOK || !cacheInflightOK || !totalBudgetOK || !backdropPixelsOK ||
        !backdropRetryOK || !backdropFallbackOK || !backdropBudgetOK || !backdropInflightOK ||
        !backdropScaleDependencyOK || !backdropCaretDependencyOK || !backdropStaleReceiptOK) return 1;
    puts("effect group probe: passed isolation=true nested=true normal_multiply=true painter_order=true mask=true domain=true movement=true clip=true resize=true scale=true rejection_recovery=true backdrop_blur=true backdrop_cache=true backdrop_retry=true backdrop_fallback=true backdrop_budget=true backdrop_inflight=true");
    return 0;
}
