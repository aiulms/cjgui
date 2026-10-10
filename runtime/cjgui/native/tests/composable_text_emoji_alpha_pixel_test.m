// Isolated native pixel consumer for separating text foreground RGB from
// textAlpha and isolated effect-group opacity. It uses production raster,
// Metal text drawing, effect-group preparation, and group compositing, while
// rendering into private offscreen textures (no window or drawable).
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { const char *name; const char *text; double r,g,b,alpha,group; } Case;

static BOOL renderCase(id<MTLDevice> device, Case c, uint64_t *outCount,
                       uint64_t *outAlpha, uint64_t *outR, uint64_t *outG,
                       uint64_t *outB, uint64_t *outDigest) {
    const uint32_t width=360, height=100;
    CJGuiInternalMetalView *view=[[CJGuiInternalMetalView alloc]
        initWithFrame:NSMakeRect(0,0,width,height) device:device commandQueue:[device newCommandQueue]];
    NSMutableArray<CJGuiInternalComposableSceneNode *> *nodes=[NSMutableArray array];
    view.composableNodes=nodes;
    CjguiInternalRendererComposableNode raw={0};
    raw.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.nodeId=401; raw.resourceId=402; raw.projectionVersion=1;
    raw.x=8; raw.y=8; raw.width=344; raw.height=84;
    raw.clipX=0; raw.clipY=0; raw.clipWidth=width; raw.clipHeight=height;
    raw.clipConstraintCount=1; raw.clip0X=0; raw.clip0Y=0; raw.clip0Width=width; raw.clip0Height=height;
    raw.fontSize=46; raw.fontWeight=0; raw.textRed=c.r; raw.textGreen=c.g; raw.textBlue=c.b;
    raw.textAlpha=c.alpha;
    CJGuiInternalComposableSceneNode *text=[CJGuiInternalComposableSceneNode new];
    text.node=raw; text.value=[NSString stringWithUTF8String:c.text];
    NSString *display=CjguiComposableGpuTextValue(text);
    text.textTextureRect=CjguiComposableTextTextureRectForNode(text);
    text.textTexture=CjguiComposableTextTexture(view,text,1.0,1.0,display,
        CjguiInternalTextWorkReasonStaticCandidate);
    if (!text.textTexture) return NO;
    if (c.group < 0.999999) {
        CJGuiInternalComposableSceneNode *group=[CJGuiInternalComposableSceneNode new];
        CjguiInternalRendererComposableNode g={0};
        g.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
        g.nodeId=403; g.resourceId=404; g.projectionVersion=1;
        g.x=0; g.y=0; g.width=width; g.height=height;
        g.clipX=0; g.clipY=0; g.clipWidth=width; g.clipHeight=height;
        g.effectGroupPresent=1; g.effectGroupSubtreeCount=2; g.effectGroupOpacity=c.group;
        group.node=g;
        [nodes addObject:group];
    }
    [nodes addObject:text];
    view.composableUsesMultisampling=NO;
    CGSize size=CGSizeMake(width,height);
    id<MTLCommandBuffer> command=[view.commandQueue commandBuffer];
    if (!command) return NO;
    NSMutableArray *redrawn=[NSMutableArray array];
    if (c.group < 0.999999 && CjguiEncodeEffectGroupContents(view,command,size,redrawn)!=CJGUI_INTERNAL_RENDERER_OK)
        return NO;
    MTLTextureDescriptor *td=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
        width:width height:height mipmapped:NO];
    td.storageMode=MTLStorageModeShared; td.usage=MTLTextureUsageRenderTarget;
    id<MTLTexture> target=[device newTextureWithDescriptor:td];
    MTLRenderPassDescriptor *pass=[MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].texture=target; pass.colorAttachments[0].loadAction=MTLLoadActionClear;
    pass.colorAttachments[0].storeAction=MTLStoreActionStore; pass.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,0);
    id<MTLRenderCommandEncoder> encoder=[command renderCommandEncoderWithDescriptor:pass];
    if (!encoder) return NO;
    BOOL ok=CjguiEncodeComposableNodesRange(view,encoder,size,0,0,width,height,0,view.composableNodes.count,NSUIntegerMax);
    [encoder endEncoding]; if (!ok) return NO;
    [command commit]; [command waitUntilCompleted];
    if (command.status!=MTLCommandBufferStatusCompleted) return NO;
    NSMutableData *data=[NSMutableData dataWithLength:width*height*4];
    [target getBytes:data.mutableBytes bytesPerRow:width*4 fromRegion:MTLRegionMake2D(0,0,width,height) mipmapLevel:0];
    const uint8_t *p=data.bytes; uint64_t n=0,a=0,r=0,g=0,b=0,h=1469598103934665603ULL;
    for (NSUInteger i=0;i<data.length;i+=4) {
        uint8_t bb=p[i],gg=p[i+1],rr=p[i+2],aa=p[i+3];
        if (aa) n++; a+=aa; r+=rr; g+=gg; b+=bb;
        for (int k=0;k<4;k++) { h^=p[i+k]; h*=1099511628211ULL; }
    }
    *outCount=n; *outAlpha=a; *outR=r; *outG=g; *outB=b; *outDigest=h;
    return YES;
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        const char *out=(argc>1?argv[1]:NULL);
        FILE *f=out?fopen(out,"w"):stdout;
        if (!f) return 2;
        id<MTLDevice> device=MTLCreateSystemDefaultDevice(); if (!device) return 3;
        const Case cases[]={
            {"plain_rgb_black","A",0.08,0.10,0.15,1,1},
            {"plain_rgb_red","A",0.92,0.08,0.04,1,1},
            {"emoji_rgb_black","🙂",0.08,0.10,0.15,1,1},
            {"emoji_rgb_red","🙂",0.92,0.08,0.04,1,1},
            {"plain_text_alpha_1","A",0.08,0.10,0.15,1,1},
            {"plain_text_alpha_half","A",0.08,0.10,0.15,0.5,1},
            {"emoji_text_alpha_1","🙂",0.08,0.10,0.15,1,1},
            {"emoji_text_alpha_half","🙂",0.08,0.10,0.15,0.5,1},
            {"plain_group_opacity_1","A",0.08,0.10,0.15,1,1},
            {"plain_group_opacity_half","A",0.08,0.10,0.15,1,0.5},
            {"emoji_group_opacity_1","🙂",0.08,0.10,0.15,1,1},
            {"emoji_group_opacity_half","🙂",0.08,0.10,0.15,1,0.5},
            {"emoji_both_half","🙂",0.08,0.10,0.15,0.5,0.5},
        };
        fprintf(f,"{\"source\":\"production_renderer_offscreen\",\"format\":\"BGRA8Unorm\",\"cases\":[\n");
        uint64_t metrics[sizeof(cases)/sizeof(cases[0])][6]={{0}};
        for (size_t i=0;i<sizeof(cases)/sizeof(cases[0]);i++) {
            uint64_t n=0,a=0,r=0,g=0,b=0,h=0;
            if (!renderCase(device,cases[i],&n,&a,&r,&g,&b,&h)) return 4;
            metrics[i][0]=n; metrics[i][1]=a; metrics[i][2]=r;
            metrics[i][3]=g; metrics[i][4]=b; metrics[i][5]=h;
            fprintf(f,"{\"case\":\"%s\",\"inkPixels\":%llu,\"sumAlpha\":%llu,\"sumR\":%llu,\"sumG\":%llu,\"sumB\":%llu,\"fnv1a\":\"%016llx\"}%s\n",
                cases[i].name,(unsigned long long)n,(unsigned long long)a,(unsigned long long)r,
                (unsigned long long)g,(unsigned long long)b,(unsigned long long)h,
                i+1<sizeof(cases)/sizeof(cases[0])?",":"");
        }
        fprintf(f,"]}\n"); if (out) fclose(f);
        const double halfTolerance=0.012, quarterTolerance=0.012;
        double ratios[]={
            (double)metrics[5][1]/metrics[4][1], (double)metrics[7][1]/metrics[6][1],
            (double)metrics[9][1]/metrics[8][1], (double)metrics[11][1]/metrics[10][1],
            (double)metrics[12][1]/metrics[6][1]
        };
        if (metrics[0][5]==metrics[1][5] || metrics[2][5]!=metrics[3][5] ||
            fabs(ratios[0]-0.5)>halfTolerance || fabs(ratios[1]-0.5)>halfTolerance ||
            fabs(ratios[2]-0.5)>halfTolerance || fabs(ratios[3]-0.5)>halfTolerance ||
            fabs(ratios[4]-0.25)>quarterTolerance) {
            fprintf(stderr,"PIXEL_ASSERT_FAIL plain_rgb_diff=%d emoji_rgb_equal=%d ratios=[%.6f,%.6f,%.6f,%.6f,%.6f]\n",
                metrics[0][5]!=metrics[1][5],metrics[2][5]==metrics[3][5],
                ratios[0],ratios[1],ratios[2],ratios[3],ratios[4]);
            return 5;
        }
        printf("PIXEL_ASSERT_PASS plain_rgb_diff=1 emoji_rgb_equal=1 text_alpha_half=%.6f emoji_alpha_half=%.6f plain_group_half=%.6f emoji_group_half=%.6f both_half=%.6f\n",
            ratios[0],ratios[1],ratios[2],ratios[3],ratios[4]);
        return 0;
    }
}
