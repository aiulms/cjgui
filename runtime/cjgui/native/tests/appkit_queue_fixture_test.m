#define CJGUI_APPKIT_FIXTURE_UNIT_TEST 1
#import "appkit_queue_fixture.m"
#include <assert.h>
typedef struct {uint64_t now;NSUInteger posted,releaseCount;NSInteger invalidAfter;BOOL originalAlive;uint64_t postCost;NSMutableArray *records;} Test;
static uint64_t Clock(void *p){return ((Test *)p)->now;}
static void SleepUntil(void *p,uint64_t at){Test *t=p;if(t->now<at)t->now=at;}
static BOOL Valid(void *p,BOOL release){Test *t=p;return t->originalAlive && (release || t->invalidAfter<0 || t->posted<(NSUInteger)t->invalidAfter);}
static void Post(void *p,NSEvent *event,NSUInteger index,uint64_t deadline,BOOL cancelled){
    Test *t=p;[t->records addObject:@{@"type":@(event.type),@"index":@(index),@"window":@(event.windowNumber),@"x":@(event.locationInWindow.x),@"y":@(event.locationInWindow.y),@"flags":@(event.modifierFlags),@"number":@(event.eventNumber),@"timestamp":@(event.timestamp),@"deadline":@(deadline),@"actual":@(t->now),@"cancelled":@(cancelled)}];
    t->posted++;if(cancelled)t->releaseCount++;t->now+=t->postCost;
}
int main(void) { @autoreleasepool {
    [NSApplication sharedApplication];
    NSWindow *window=[[NSWindow alloc] initWithContentRect:NSMakeRect(300,200,900,620)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];window.releasedWhenClosed=NO;
    NSDictionary *plan=@{@"target_pid":@(getpid()),@"nonce":@"private-fixture-test-token",
        @"events":@[@{@"kind":@"down",@"at_ms":@0,@"x":@345,@"y":@217,@"flags":@(NSEventModifierFlagShift),@"clickCount":@2},
                    @{@"kind":@"move",@"at_ms":@16,@"x":@1238,@"y":@217},
                    @{@"kind":@"up",@"at_ms":@32,@"x":@359,@"y":@217}]};
    NSString *failure=nil;NSArray<NSEvent *> *events=CjFixturePrepare(plan,window,1000000000,&failure);assert(events.count==3&&failure==nil);
    CGFloat top=NSMaxY(NSScreen.screens.firstObject.frame);NSRect frame=window.frame;
    for(NSUInteger i=0;i<events.count;i++) {
        NSDictionary *row=plan[@"events"][i];NSPoint expected=NSMakePoint([row[@"x"] doubleValue]-frame.origin.x,top-[row[@"y"] doubleValue]-frame.origin.y);
        assert(NSEqualPoints(events[i].locationInWindow,expected));assert(events[i].windowNumber==window.windowNumber);
        assert(events[i].eventNumber==i+1);assert(fabs(events[i].timestamp-(1+[row[@"at_ms"] doubleValue]/1000))<1e-9);
    }
    assert(events[0].modifierFlags==NSEventModifierFlagShift&&events[0].clickCount==2);assert(events[1].locationInWindow.x>frame.size.width);
    NSArray *ups=CjFixtureCancelUps(events,window);assert(ups.count==3);
    for(NSDictionary *change in @[@{@"nonce":@""},@{@"target_pid":@(getpid()+1)},@{@"events":@[]},@{@"target_pid":@"invalid"}]) {
        NSMutableDictionary *bad=[plan mutableCopy];[bad addEntriesFromDictionary:change];failure=nil;assert(!CjFixturePrepare(bad,window,1,&failure));assert(failure);
    }
    CjFixtureOps ops={Clock,SleepUntil,Valid,Post};
    Test positive={.now=1000000000,.invalidAfter=-1,.originalAlive=YES,.records=[NSMutableArray array]};failure=nil;
    assert(CjFixtureRun(events,ups,plan[@"events"],1000000000,ops,&positive,&failure));assert(positive.posted==3&&!positive.releaseCount);
    assert([positive.records[1][@"actual"] unsignedLongLongValue]==1016000000ULL);
    Test busy={.now=1000000000,.invalidAfter=-1,.originalAlive=YES,.postCost=25000000,.records=[NSMutableArray array]};failure=nil;
    assert(CjFixtureRun(events,ups,plan[@"events"],1000000000,ops,&busy,&failure));assert(busy.posted==3);
    assert([busy.records[1][@"deadline"] unsignedLongLongValue]==1016000000ULL);assert([busy.records[1][@"actual"] unsignedLongLongValue]==1025000000ULL);
    assert([busy.records[2][@"actual"] unsignedLongLongValue]==1050000000ULL);assert([busy.records[2][@"deadline"] unsignedLongLongValue]==1032000000ULL);
    for(NSInteger after=0;after<=2;after++) {
        Test stop={.now=1000000000,.invalidAfter=after,.originalAlive=YES,.records=[NSMutableArray array]};failure=nil;
        assert(!CjFixtureRun(events,ups,plan[@"events"],1000000000,ops,&stop,&failure));assert(stop.posted==(after?after+1:0));assert(stop.releaseCount==(after?1:0));
        if(after){NSDictionary *last=stop.records.lastObject;assert([last[@"type"] intValue]==NSEventTypeLeftMouseUp);assert([last[@"number"] intValue]==3);assert([last[@"window"] intValue]==window.windowNumber);}
    }
    Test dead={.now=1000000000,.invalidAfter=-1,.originalAlive=NO,.records=[NSMutableArray array]};failure=nil;
    assert(!CjFixtureRun(events,ups,plan[@"events"],1000000000,ops,&dead,&failure));assert(dead.posted==0);
    char temp[]="/private/tmp/cjgui-appkit-unit-XXXXXX";char *folder=mkdtemp(temp);assert(folder);
    NSString *file=[[NSString stringWithUTF8String:folder] stringByAppendingPathComponent:@"scope"];
    int fd=open(file.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY,0600);assert(fd>=0);assert(write(fd,"private",7)==7);close(fd);
    assert(CjFixtureReadPrivate(file,8).length==7);assert(!CjFixtureReadPrivate(file,6));chmod(file.fileSystemRepresentation,0644);assert(!CjFixtureReadPrivate(file,8));
    unlink(file.fileSystemRepresentation);rmdir(folder);[window close];puts("APPKIT_FIXTURE_PASS preparation/geometry/fields/deadlines/late-post-cost/cancel/identity/private-scope");
}return 0;}
