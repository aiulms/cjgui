// Controlled drawable readback of the production clear/encode/submit path.
// This test alone intercepts nextDrawable to retain the exact submitted texture;
// it adds a bounded readback command after production work, never a runtime hook.
// GPU completion/readback is not proof of a physical display frame.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"
#import <objc/runtime.h>
#import <ImageIO/ImageIO.h>

static CAMetalLayer *probeLayer;
static id<CAMetalDrawable> capturedDrawable;
static IMP originalNextDrawable;
static id captureNextDrawable(id receiver, SEL selector) {
    id drawable = ((id (*)(id, SEL))originalNextDrawable)(receiver, selector);
    if (receiver == probeLayer) capturedDrawable = drawable;
    return drawable;
}

static CjguiInternalRendererComposableNode baseNode(uint64_t version, uint64_t nodeId,
        double x, double y, double w, double h) {
    CjguiInternalRendererComposableNode n = {0};
    n.projectionVersion=version; n.nodeId=nodeId; n.resourceId=-1;
    n.nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_VERTICAL;
    n.x=x; n.y=y; n.width=w; n.height=h;
    n.clipX=0; n.clipY=0; n.clipWidth=420; n.clipHeight=320;
    n.clipConstraintCount=1; n.clip0Width=420; n.clip0Height=320;
    n.effectGroupSubtreeCount=1;
    return n;
}

static BOOL submitScene(uint64_t session, uint64_t version, double y, BOOL translation, BOOL effect) {
    double layoutY=translation ? 0 : y;
    CjguiInternalRendererComposableNode nodes[4];
    nodes[0]=baseNode(version,100,0,0,420,320); nodes[0].fillAlpha=1;
    nodes[1]=baseNode(version,101,20,80+layoutY,380,130);
    nodes[1].effectGroupPresent=effect; nodes[1].effectGroupSubtreeCount=3;
    nodes[1].effectGroupOpacity=1;
    if(effect) {
        nodes[1].effectMaskPresent=1; nodes[1].effectMaskStopCount=2;
        nodes[1].effectMaskEndX=1; nodes[1].effectMaskStop1Position=1;
        nodes[1].effectMaskStop0Alpha=.75; nodes[1].effectMaskStop1Alpha=.75;
    }
    nodes[2]=baseNode(version,102,40,100+layoutY,24,16);
    nodes[2].fillGreen=1; nodes[2].fillAlpha=1;
    nodes[3]=baseNode(version,103,90,130+layoutY,260,34);
    nodes[3].nodeKind=CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    nodes[3].textRed=1; nodes[3].textGreen=1; nodes[3].textBlue=1; nodes[3].textAlpha=1;
    nodes[3].fontSize=18;
    if(cjgui_internal_renderer_configure_composable_scene(session,version,4)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
    for(int i=0;i<4;i++) {
        const char *text=i==3 ? "UNIQUE ROW 0123456789" : "";
        if(cjgui_internal_renderer_set_composable_scene_node(session,i,&nodes[i],"",text,
            "","",0)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
        if(translation) {
            CjguiInternalRendererComposableGeometry geometry={0}; geometry.nodeId=nodes[i].nodeId;
            geometry.translateY=i==0 ? 0 : y; geometry.clipCount=1;
            if(cjgui_internal_renderer_set_composable_scene_geometry(session,version,i,&geometry)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
        }
    }
    if(cjgui_internal_renderer_stage_window_background(session,version,0,1)!=CJGUI_INTERNAL_RENDERER_OK) return NO;
    capturedDrawable=nil;
    CjguiInternalRendererFrameObservation frame={0};
    return cjgui_internal_renderer_present_composable_scene(session,&frame)==CJGUI_INTERNAL_RENDERER_OK && capturedDrawable;
}

static BOOL checkDrawable(uint64_t session, uint64_t version, double y, BOOL effect, BOOL translation) {
    CJGuiInternalSession *ctx=CjguiLookupSession(session);
    id<MTLTexture> texture=capturedDrawable.texture;
    NSUInteger width=texture.width,height=texture.height,rowBytes=((width*4+255)/256)*256;
    id<MTLBuffer> buffer=[ctx.device newBufferWithLength:rowBytes*height options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> command=[ctx.view.commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> blit=[command blitCommandEncoder];
    CJGuiInternalComposableSceneNode *group=ctx.view.composableNodes[1];
    CJGuiInternalComposableEffectTarget *target=group.effectTarget;
    NSUInteger effectRowBytes=target ? ((target.pixelWidth*4+255)/256)*256 : 0;
    id<MTLBuffer> effectBuffer=target ? [ctx.device newBufferWithLength:effectRowBytes*target.pixelHeight
        options:MTLResourceStorageModeShared] : nil;
    if(effectBuffer) [blit copyFromTexture:target.resolvedTexture sourceSlice:0 sourceLevel:0
        sourceOrigin:MTLOriginMake(0,0,0) sourceSize:MTLSizeMake(target.pixelWidth,target.pixelHeight,1)
        toBuffer:effectBuffer destinationOffset:0 destinationBytesPerRow:effectRowBytes
        destinationBytesPerImage:effectRowBytes*target.pixelHeight];
    [blit copyFromTexture:texture sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0,0,0)
        sourceSize:MTLSizeMake(width,height,1) toBuffer:buffer destinationOffset:0
        destinationBytesPerRow:rowBytes destinationBytesPerImage:rowBytes*height];
    [blit endEncoding]; [command commit]; [command waitUntilCompleted];
    if(command.status!=MTLCommandBufferStatusCompleted) return NO;
    for(int attempt=0;attempt<4 && ctx.observedMetalCompletionFrameIndex<ctx.view.frameIndex;attempt++)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode,.001,true);
    const uint8_t *pixels=buffer.contents;
    double sy=(double)height/ctx.view.bounds.size.height;
    double sx=(double)width/ctx.view.bounds.size.width;
    NSUInteger targetGreen=0;
    if(effectBuffer) {
        const uint8_t *effectPixels=effectBuffer.contents;
        for(NSUInteger py=0;py<target.pixelHeight;py++) for(NSUInteger px=0;px<target.pixelWidth;px++) {
            const uint8_t *p=effectPixels+py*effectRowBytes+px*4;
            if(p[1]>120 && p[0]<8 && p[2]<8) targetGreen++;
        }
    }
    printf("MOTION_EFFECT scene=%llu roi=%u,%u,%u,%u target_green=%lu signature=%s "
        "translate=%.3f,%.3f,%.3f shape_count=%u alloc=%llu reuse=%llu redraw=%llu\n",
        (unsigned long long)version,target.pixelX,target.pixelY,target.pixelWidth,target.pixelHeight,
        (unsigned long)targetGreen,target.contentSignature.UTF8String ?: "none",
        group.geometry.translateY,ctx.view.composableNodes[2].geometry.translateY,
        ctx.view.composableNodes[3].geometry.translateY,ctx.view.testComposableShapeNodeCount,
        (unsigned long long)ctx.view.testEffectTargetAllocationCount,
        (unsigned long long)ctx.view.testEffectTargetReuseCount,
        (unsigned long long)ctx.view.testEffectContentRedrawCount);
    NSUInteger barcodeX=(NSUInteger)(52*sx),greenRows=0,ghostRows=0,whiteOutside=0,whiteInside=0;
    for(NSUInteger py=0;py<height;py++) {
        double pointY=((double)py+.5)/sy;
        const uint8_t *pixel=pixels+py*rowBytes+barcodeX*4;
        if(pixel[1]>120 && pixel[0]<8 && pixel[2]<8) {
            greenRows++;
            if(pointY<100+y-.6 || pointY>116+y+.6) ghostRows++;
        }
        for(NSUInteger px=(NSUInteger)(90*sx);px<MIN(width,(NSUInteger)(350*sx));px++) {
            const uint8_t *p=pixels+py*rowBytes+px*4;
            if(p[0]>25 && p[1]>25 && p[2]>25) {
                if(pointY<130+y-.6 || pointY>164+y+.6) whiteOutside++;
                else whiteInside++;
            }
        }
    }
    BOOL ok=greenRows>0 && fabs((double)greenRows-16*sy)<=2 && ghostRows==0 && whiteOutside==0 && whiteInside>0;
    printf("MOTION_DRAWABLE scene=%llu submitted=%llu completed=%llu source=controlled_drawable "
        "mode=%s effect=%d y=%.3f green_rows=%lu ghost_rows=%lu text_outside=%lu text_inside=%lu ok=%d\n",
        (unsigned long long)version,(unsigned long long)ctx.view.frameIndex,
        (unsigned long long)ctx.observedMetalCompletionFrameIndex,translation?"translate":"layout_offset",
        effect,y,(unsigned long)greenRows,(unsigned long)ghostRows,(unsigned long)whiteOutside,(unsigned long)whiteInside,ok);
    const char *directory=getenv("CJGUI_MOTION_GHOST_OUTPUT");
    if(directory && (version==1 || !ok || version==64)) {
        CGColorSpaceRef color=CGColorSpaceCreateDeviceRGB();
        CGDataProviderRef data=CGDataProviderCreateWithData(NULL,pixels,rowBytes*height,NULL);
        CGImageRef image=CGImageCreate(width,height,8,32,rowBytes,color,
            kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst,data,NULL,NO,kCGRenderingIntentDefault);
        NSString *path=[NSString stringWithFormat:@"%s/drawable-%llu.png",directory,(unsigned long long)version];
        NSData *png=[[[NSBitmapImageRep alloc] initWithCGImage:image] representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        [png writeToFile:path atomically:YES]; CGImageRelease(image); CGDataProviderRelease(data); CGColorSpaceRelease(color);
    }
    capturedDrawable=nil;
    return ok;
}

int main(void) {
    @autoreleasepool {
        CjguiInternalRendererConfig config={.windowWidth=420,.windowHeight=320,.clearColorAlpha=1};
        CjguiInternalRendererStatus result;
        uint64_t session=cjgui_internal_renderer_create(&config,&result);
        if(result!=CJGUI_INTERNAL_RENDERER_OK || !session) return 2;
        probeLayer=CjguiLookupSession(session).view.metalLayer;
        Method method=class_getInstanceMethod(CAMetalLayer.class,@selector(nextDrawable));
        originalNextDrawable=method_setImplementation(method,(IMP)captureNextDrawable);
        double positions[]={0,0,7,14,21,58,0,-16,-8,-58,0,3.375,6.75,9.125,0,0};
        uint64_t version=0; int failures=0;
        for(int translation=0;translation<2;translation++) for(int effect=0;effect<2;effect++) {
            for(int i=0;i<16;i++) {
                version++;
                if(!submitScene(session,version,positions[i],translation,effect) ||
                    !checkDrawable(session,version,positions[i],effect,translation)) failures++;
            }
        }
        method_setImplementation(method,originalNextDrawable); capturedDrawable=nil; probeLayer=nil;
        cjgui_internal_renderer_destroy(session);
        printf("MOTION_DRAWABLE_RESULT frames=%llu failures=%d physical_display=not_measured\n",(unsigned long long)version,failures);
        return failures ? 1 : 0;
    }
}
