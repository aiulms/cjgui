// The existing read-only process/local observer must accept a requested raw
// key filter, without requiring the unrelated controlled-fixture marker.
// Events are constructed, never posted. The Cangjie runtime entry is unused.
#import "../cjgui_internal_renderer.m"
#import "../cjgui_macos_application_launcher.m"
int InitCJRuntime(const void *parameter) { (void)parameter; abort(); }
int main(void) {
    @autoreleasepool {
        CGEventRef q=CGEventCreateKeyboardEvent(NULL,12,true);
        if(!q)return 2;
        CGEventSetIntegerValueField(q,kCGEventSourceUserData,0);
        setenv("CJGUI_EARLY_KEY_FILTER","12",1);
        BOOL raw=CjguiIsObservedTestKey(q);
        setenv("CJGUI_EARLY_KEY_FILTER","0",1);
        BOOL unrelated=CjguiIsObservedTestKey(q);
        setenv("CJGUI_EARLY_KEY_FILTER","12x",1);
        BOOL malformed=CjguiIsObservedTestKey(q);
        unsetenv("CJGUI_EARLY_KEY_FILTER");
        CGEventSourceRef source=CGEventSourceCreate(kCGEventSourceStatePrivate);
        CGEventSourceSetUserData(source,1);
        CGEventRef marked=CGEventCreateKeyboardEvent(source,0,true);
        BOOL legacy=CjguiIsObservedTestKey(marked);
        BOOL nullAccepted=CjguiIsObservedTestKey(NULL);
        printf("APPLICATION_KEY_MARKER code=%lld data=%lld\n",
            (long long)CGEventGetIntegerValueField(marked,kCGKeyboardEventKeycode),
            (long long)CGEventGetIntegerValueField(marked,kCGEventSourceUserData));
        CFRelease(marked);CFRelease(source);
        CFRelease(q);
        printf("APPLICATION_KEY_FILTER raw=%d unrelated=%d malformed=%d legacy=%d null=%d\n",
            raw,unrelated,malformed,legacy,nullAccepted);
        return raw && !unrelated && !malformed && legacy && !nullAccepted ? 0 : 1;
    }
}
