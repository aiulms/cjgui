// Controlled AppKit menu construction/removal; real UI restore is tested by
// the normal consumer separately. No private restore action is introduced.
#import "../cjgui_internal_renderer.m"
#include <stdio.h>

static int failures;
static void check(BOOL ok,const char *message) {
    if(!ok){failures++;fprintf(stderr,"WINDOW_MENU FAIL: %s\n",message);}
}
static NSUInteger titles(NSMenu *menu,NSString *title) {
    NSUInteger count=0;
    for(NSMenuItem *item in menu.itemArray)if([item.title isEqual:title])count++;
    return count;
}
int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        CjguiInternalRendererConfig cfg={.windowWidth=360,.windowHeight=240};
        CjguiInternalRendererStatus status;
        uint64_t a=cjgui_internal_renderer_create(&cfg,&status);
        check(status==CJGUI_INTERNAL_RENDERER_OK,"create A");
        uint64_t b=cjgui_internal_renderer_create(&cfg,&status);
        check(status==CJGUI_INTERNAL_RENDERER_OK,"create B");
        CjguiLookupSession(a).window.title=@"System menu A";
        CjguiLookupSession(b).window.title=@"System menu B";
        CjguiRebuildComposableCommandMenuForKeyWindow();
        NSMenu *menu=NSApp.windowsMenu;
        check(menu!=nil,"framework has no standard Window menu");
        check(titles(menu,@"System menu A")==1 && titles(menu,@"System menu B")==1,
            "both native windows must have one system-managed entry");
        CjguiRebuildComposableCommandMenuForKeyWindow();
        menu=NSApp.windowsMenu;
        check(titles(menu,@"System menu A")==1 && titles(menu,@"System menu B")==1,
            "command-menu rebuild lost or duplicated system window entries");
        check(cjgui_internal_renderer_destroy(a)==CJGUI_INTERNAL_RENDERER_OK,"close A");
        CjguiRebuildComposableCommandMenuForKeyWindow();
        menu=NSApp.windowsMenu;
        check(titles(menu,@"System menu A")==0 && titles(menu,@"System menu B")==1,
            "closed window remained in the system menu or live peer disappeared");
        check(cjgui_internal_renderer_destroy(b)==CJGUI_INTERNAL_RENDERER_OK,"close B");
        printf("WINDOW_MENU failures=%d occupied=%u\n",failures,
            cjgui_internal_renderer_occupied_session_count());
        return failures?1:0;
    }
}
