// Deterministic display-clock delivery; actual Metal submission stays real.
#import <QuartzCore/CADisplayLink.h>
@interface CjguiTestManualDisplayLink : NSObject
@property(nonatomic, strong) id target;
@property(nonatomic, assign) SEL selector;
@property(nonatomic, assign) BOOL paused;
@property(nonatomic, assign) BOOL invalidated;
@property(nonatomic, assign) BOOL registered;
- (void)addToRunLoop:(NSRunLoop *)loop forMode:(NSRunLoopMode)mode;
- (void)invalidate;
- (void)fire;
@end
@implementation CjguiTestManualDisplayLink
- (void)addToRunLoop:(NSRunLoop *)loop forMode:(NSRunLoopMode)mode {
    self.registered = loop == NSRunLoop.mainRunLoop && [mode isEqualToString:NSRunLoopCommonModes];
}
- (void)invalidate { self.invalidated = YES; self.target = nil; }
- (void)fire {
    if (self.paused || self.invalidated || !self.target) return;
    void (*callback)(id, SEL, id) = (void *)[self.target methodForSelector:self.selector];
    callback(self.target, self.selector, self);
}
@end
static CjguiTestManualDisplayLink *CjguiTestLastDisplayLink;
@interface NSView (CjguiTestManualDisplayClock)
- (CADisplayLink *)cjguiTestDisplayLinkWithTarget:(id)target selector:(SEL)selector;
@end
@implementation NSView (CjguiTestManualDisplayClock)
- (CADisplayLink *)cjguiTestDisplayLinkWithTarget:(id)target selector:(SEL)selector {
    CjguiTestManualDisplayLink *link = [CjguiTestManualDisplayLink new];
    link.target = target; link.selector = selector; CjguiTestLastDisplayLink = link;
    return (id)link;
}
@end
static void CjguiTestExchangeDisplayClock(void) {
    method_exchangeImplementations(class_getInstanceMethod(NSView.class,
        @selector(displayLinkWithTarget:selector:)), class_getInstanceMethod(NSView.class,
        @selector(cjguiTestDisplayLinkWithTarget:selector:)));
}
