// Private, explicitly injected once-plan fixture. Not part of normal delivery.
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#include <stdatomic.h>
#include <libproc.h>
#include <mach/mach_time.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#include <pthread.h>

static uint64_t CjFixtureNow(void) {
    mach_timebase_info_data_t t;mach_timebase_info(&t);uint64_t n=mach_absolute_time();
    return n/t.denom*t.numer+n%t.denom*t.numer/t.denom;
}
static void CjFixtureSleepUntil(uint64_t deadline) {
    uint64_t now=CjFixtureNow();if(now<deadline)usleep((useconds_t)MIN((deadline-now+999)/1000,UINT32_MAX));
}
static NSArray<NSEvent *> *CjFixturePrepare(NSDictionary *plan,NSWindow *window,uint64_t origin,NSString **failure) {
    NSCAssert(NSThread.isMainThread,@"fixture preparation must remain on main");
    NSArray *rows=plan[@"events"];
    if (![plan[@"nonce"] isKindOfClass:NSString.class] || [plan[@"nonce"] length]<16 ||
        (![plan[@"target_pid"] isKindOfClass:NSNumber.class] || [plan[@"target_pid"] intValue]!=getpid()) || !window ||
        ![rows isKindOfClass:NSArray.class] || rows.count<3 || rows.count>4096) {
        *failure=@"plan_scope_or_count";return nil;
    }
    NSMutableArray *result=[NSMutableArray arrayWithCapacity:rows.count];double previous=-1;
    CGFloat top=NSMaxY(NSScreen.screens.firstObject.frame);
    for(NSUInteger i=0;i<rows.count;i++) {
        NSDictionary *row=rows[i];NSString *kind=i==0?@"down":i==rows.count-1?@"up":@"move";
        if(![row isKindOfClass:NSDictionary.class] || ![row[@"kind"] isEqual:kind] ||
           ![row[@"at_ms"] isKindOfClass:NSNumber.class] || ![row[@"x"] isKindOfClass:NSNumber.class] ||
           ![row[@"y"] isKindOfClass:NSNumber.class]) { *failure=@"plan_row";return nil; }
        double at=[row[@"at_ms"] doubleValue],x=[row[@"x"] doubleValue],y=[row[@"y"] doubleValue];
        if(!isfinite(at)||!isfinite(x)||!isfinite(y)||at<0||at<=previous||at>120000) {*failure=@"plan_time_or_coordinate";return nil;}
        previous=at;
        NSEventType type=i==0?NSEventTypeLeftMouseDown:i==rows.count-1?NSEventTypeLeftMouseUp:NSEventTypeLeftMouseDragged;
        NSPoint local=[window convertPointFromScreen:NSMakePoint(x,top-y)];
        NSUInteger flags=[row[@"flags"] unsignedLongLongValue];NSInteger clicks=row[@"clickCount"]?[row[@"clickCount"] integerValue]:1;
        NSInteger number=row[@"eventNumber"]?[row[@"eventNumber"] integerValue]:(NSInteger)i+1;
        NSEvent *event=[NSEvent mouseEventWithType:type location:local modifierFlags:flags
            timestamp:(origin+(uint64_t)(at*1e6))/1e9 windowNumber:window.windowNumber context:nil
            eventNumber:number clickCount:clicks pressure:1.0];
        if(!event || event.windowNumber!=window.windowNumber || !NSEqualPoints(event.locationInWindow,local) ||
            event.type!=type || event.modifierFlags!=flags || event.clickCount!=clicks || event.eventNumber!=number) {
            *failure=@"native_event_intent";return nil;
        }
        [result addObject:event];
    }
    return result;
}
static NSArray<NSEvent *> *CjFixtureCancelUps(NSArray<NSEvent *> *events,NSWindow *window) {
    NSCAssert(NSThread.isMainThread,@"cancel edges prepared on main");
    NSMutableArray *ups=[NSMutableArray arrayWithCapacity:events.count];
    for(NSEvent *event in events) {
        NSEvent *up=[NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:event.locationInWindow modifierFlags:event.modifierFlags
            timestamp:event.timestamp windowNumber:window.windowNumber context:nil eventNumber:events.lastObject.eventNumber clickCount:event.clickCount pressure:1];
        if(!up)return nil;[ups addObject:up];
    }
    return ups;
}
// The scheduler has no owner/accepted/frame query. Mock only its OS boundary.
typedef struct {
    uint64_t (*now)(void *);
    void (*sleepUntil)(void *,uint64_t);
    BOOL (*valid)(void *,BOOL);
    void (*post)(void *,NSEvent *,NSUInteger,uint64_t,BOOL);
} CjFixtureOps;
static BOOL CjFixtureRun(NSArray<NSEvent *> *events,NSArray<NSEvent *> *cancelUps,NSArray *rows,
    uint64_t origin,CjFixtureOps ops,void *context,NSString **failure) {
    BOOL held=NO;NSUInteger last=0;
    for(NSUInteger i=0;i<events.count;i++) {
        uint64_t deadline=origin+(uint64_t)([rows[i][@"at_ms"] doubleValue]*1e6);
        ops.sleepUntil(context,deadline);
        if(!ops.valid(context,NO)) {
            *failure=@"scope_instance_window_geometry_foreground_or_cancelled";
            if(held && ops.valid(context,YES)) ops.post(context,cancelUps[last],events.count-1,ops.now(context),YES);
            return NO;
        }
        ops.post(context,events[i],i,deadline,NO);last=i;
        held=i!=events.count-1;
    }
    return YES;
}
static NSData *CjFixtureReadPrivate(NSString *path,NSUInteger limit) {
    int fd=open(path.fileSystemRepresentation,O_RDONLY|O_NOFOLLOW);if(fd<0)return nil;
    struct stat st;NSData *data=nil;
    if(fstat(fd,&st)==0 && S_ISREG(st.st_mode) && st.st_uid==getuid() && (st.st_mode&0077)==0 &&
        st.st_nlink==1 && st.st_size>0 && (uint64_t)st.st_size<=limit) {
        NSMutableData *bytes=[NSMutableData dataWithLength:(NSUInteger)st.st_size];size_t done=0;
        while(done<bytes.length) {ssize_t n=read(fd,(char *)bytes.mutableBytes+done,bytes.length-done);if(n<=0)break;done+=(size_t)n;}
        if(done==bytes.length)data=bytes;
    }
    close(fd);return data;
}

#ifndef CJGUI_APPKIT_FIXTURE_UNIT_TEST
@interface CjFixtureSession:NSObject
@property NSApplication *app;
@property NSWindow *windowHold;
@property NSArray<NSEvent *> *events;
@property NSArray<NSEvent *> *cancelUps;
@property NSArray<NSDictionary *> *facts;
@property NSDictionary *plan;
@property NSDictionary *scope;
@property NSData *scopeBytes;
@property NSString *scopePath;
@property NSString *upPath;
@property CGRect frameQuartz;
@property uint32_t windowNumber;
@property uint64_t origin;
@property uint64_t preparedNs;
@property NSArray *observers;
@property BOOL upFactWritten;
@end
@implementation CjFixtureSession
@end
static atomic_bool gCjFixtureCancelled;
static atomic_bool gCjFixtureClosed;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
static pid_t CjFixtureFrontPid(void) {
    ProcessSerialNumber psn={0,0};pid_t pid=0;
    if(GetFrontProcess(&psn)!=noErr || GetProcessPID(&psn,&pid)!=noErr)return 0;
    return pid;
}
#pragma clang diagnostic pop
static BOOL CjFixtureProcessMatches(CjFixtureSession *s) {
    struct proc_bsdinfo b;char path[PROC_PIDPATHINFO_MAXSIZE];struct stat st;
    if(proc_pidinfo(getpid(),PROC_PIDTBSDINFO,0,&b,sizeof(b))!=sizeof(b) ||
       b.pbi_start_tvsec!=[s.scope[@"startSeconds"] unsignedLongLongValue] ||
       b.pbi_start_tvusec!=[s.scope[@"startMicros"] unsignedLongLongValue] ||
       proc_pidpath(getpid(),path,sizeof(path))<=0 || strcmp(path,[s.scope[@"executable"] UTF8String]) || stat(path,&st))return NO;
    return (uint64_t)st.st_dev==[s.scope[@"device"] unsignedLongLongValue] && st.st_ino==[s.scope[@"inode"] unsignedLongLongValue] &&
        st.st_size==[s.scope[@"size"] longLongValue] && st.st_mtimespec.tv_sec==[s.scope[@"modifiedSeconds"] longLongValue] &&
        st.st_mtimespec.tv_nsec==[s.scope[@"modifiedNanos"] longLongValue];
}
static BOOL CjFixtureWindowMatches(CjFixtureSession *s,BOOL releaseOnly) {
    NSArray *list=CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements,kCGNullWindowID));
    for(NSDictionary *row in list) {
        if([row[(__bridge NSString *)kCGWindowOwnerPID] intValue]!=getpid() ||
           [row[(__bridge NSString *)kCGWindowNumber] unsignedIntValue]!=s.windowNumber)continue;
        if(releaseOnly)return YES;
        CGRect frame;return CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)row[(__bridge NSString *)kCGWindowBounds],&frame) && CGRectEqualToRect(frame,s.frameQuartz);
    }
    return NO;
}
static BOOL CjFixtureValid(void *raw,BOOL releaseOnly) {
    CjFixtureSession *s=(__bridge CjFixtureSession *)raw;
    if(atomic_load(&gCjFixtureClosed) || !CjFixtureProcessMatches(s) || !CjFixtureWindowMatches(s,releaseOnly))return NO;
    if(releaseOnly)return YES;
    return !atomic_load(&gCjFixtureCancelled) && CjFixtureFrontPid()==getpid() &&
        [CjFixtureReadPrivate(s.scopePath,16384) isEqual:s.scopeBytes];
}
static uint64_t CjFixtureClock(void *raw) {(void)raw;return CjFixtureNow();}
static void CjFixtureWait(void *raw,uint64_t deadline) {(void)raw;CjFixtureSleepUntil(deadline);}
static void CjFixtureWriteUp(CjFixtureSession *s,uint64_t begin,uint64_t end,BOOL cancelled) {
    if(s.upFactWritten)return;s.upFactWritten=YES;
    NSDictionary *fact=@{@"pid":@(getpid()),@"window":@(s.windowNumber),@"nonce":s.plan[@"nonce"],
        @"up_begin_ns":@(begin),@"up_end_ns":@(end),@"cancelled":@(cancelled),@"input_primitive":@"in_process_AppKit_queue_synthetic"};
    NSData *data=[NSJSONSerialization dataWithJSONObject:fact options:NSJSONWritingSortedKeys error:nil];
    int fd=open(s.upPath.fileSystemRepresentation,O_CREAT|O_EXCL|O_WRONLY|O_NOFOLLOW,0600);
    if(fd>=0){size_t done=0;while(done<data.length){ssize_t n=write(fd,(const char *)data.bytes+done,data.length-done);if(n<=0)break;done+=(size_t)n;}close(fd);}
    else fprintf(stderr,"CJGUI_APPKIT_QUEUE_UP_FACT_FAILED errno=%d\n",errno);
}
static void CjFixturePost(void *raw,NSEvent *event,NSUInteger index,uint64_t deadline,BOOL cancelled) {
    CjFixtureSession *s=(__bridge CjFixtureSession *)raw;
    NSDictionary *facts=s.facts[index];uint64_t begin=CjFixtureNow();
    [s.app postEvent:event atStart:NO];
    uint64_t end=CjFixtureNow();
    fprintf(stderr,"CJGUI_APPKIT_QUEUE_POST pid=%d window=%u seq=%lu kind=%s event_ptr=%p desired_ns=%llu enqueue_begin_ns=%llu enqueue_end_ns=%llu lateness_ns=%lld x=%s y=%s flags=%llu click=%lld number=%lld cancelled=%d\n",
        getpid(),s.windowNumber,(unsigned long)index+1,cancelled?"cancel_up":[facts[@"kind"] UTF8String],(__bridge void *)event,
        (unsigned long long)deadline,(unsigned long long)begin,(unsigned long long)end,(long long)(begin-deadline),
        [facts[@"local_x"] description].UTF8String,[facts[@"local_y"] description].UTF8String,
        [facts[@"flags"] unsignedLongLongValue],[facts[@"click"] longLongValue],[facts[@"number"] longLongValue],cancelled);
    if(index==s.events.count-1)CjFixtureWriteUp(s,begin,end,cancelled);
}
static void CjFixtureExecute(NSString *planPath,NSString *scopePath,NSString *upPath,NSString *nonce) {
    uint64_t waitStart=CjFixtureNow();NSData *bytes=nil;
    while(CjFixtureNow()-waitStart<30000000000ULL && !(bytes=CjFixtureReadPrivate(planPath,1024*1024)))usleep(2000);
    NSDictionary *plan=bytes?[NSJSONSerialization JSONObjectWithData:bytes options:0 error:nil]:nil;
    NSData *scopeBytes=CjFixtureReadPrivate(scopePath,16384);
    NSDictionary *scope=scopeBytes?[NSJSONSerialization JSONObjectWithData:scopeBytes options:0 error:nil]:nil;
    if(![plan isKindOfClass:NSDictionary.class] || ![scope isKindOfClass:NSDictionary.class] ||
       ![plan[@"nonce"] isEqual:nonce] || ![scope[@"nonce"] isEqual:nonce] ||
       (![plan[@"target_pid"] isKindOfClass:NSNumber.class] || [plan[@"target_pid"] intValue]!=getpid()) || [scope[@"pid"] intValue]!=getpid() ||
       ![planPath.stringByDeletingLastPathComponent isEqual:upPath.stringByDeletingLastPathComponent] ||
       ![planPath.stringByDeletingLastPathComponent isEqual:scopePath.stringByDeletingLastPathComponent] || access(upPath.fileSystemRepresentation,F_OK)==0) {
        fprintf(stderr,"CJGUI_APPKIT_QUEUE_REFUSED reason=private_plan_scope pid=%d\n",getpid());return;
    }
    CjFixtureSession *s=[CjFixtureSession new];s.plan=plan;s.scope=scope;s.scopeBytes=scopeBytes;s.scopePath=scopePath;s.upPath=upPath;
    __block NSString *failure=nil;uint64_t requestNs=CjFixtureNow();
    dispatch_sync(dispatch_get_main_queue(),^{
        s.app=NSApp;s.windowNumber=[scope[@"window"] unsignedIntValue];NSWindow *window=[NSApp windowWithWindowNumber:s.windowNumber];
        if(!window || ![window isKindOfClass:NSWindow.class]){failure=@"actual_owned_window_missing";return;}
        s.windowHold=window;
        NSDictionary *bounds=scope[@"window_bounds"];
        CGRect frame;
        if(![bounds isKindOfClass:NSDictionary.class] || !CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)bounds,&frame)) {failure=@"frozen_geometry_missing";return;}
        s.frameQuartz=frame;
        s.origin=CjFixtureNow()+20000000ULL;s.events=CjFixturePrepare(plan,window,s.origin,&failure);if(!s.events)return;
        NSArray *cancelUps=CjFixtureCancelUps(s.events,window);NSMutableArray *facts=[NSMutableArray array];
        if(!cancelUps){failure=@"cancel_edge_creation";return;}
        for(NSUInteger i=0;i<s.events.count;i++) {
            NSEvent *event=s.events[i];[facts addObject:@{@"kind":plan[@"events"][i][@"kind"],@"local_x":@(event.locationInWindow.x),@"local_y":@(event.locationInWindow.y),
                @"flags":@(event.modifierFlags),@"click":@(event.clickCount),@"number":@(event.eventNumber)}];
        }
        s.cancelUps=cancelUps;s.facts=facts;s.preparedNs=CjFixtureNow();
        NSMutableArray *observers=[NSMutableArray array];
        for(NSNotificationName name in @[NSWindowWillCloseNotification,NSWindowDidMoveNotification,NSWindowDidResizeNotification,NSWindowDidResignKeyNotification]) {
            id observer=[NSNotificationCenter.defaultCenter addObserverForName:name object:window queue:nil usingBlock:^(NSNotification *note){if([note.name isEqual:NSWindowWillCloseNotification])atomic_store(&gCjFixtureClosed,true);atomic_store(&gCjFixtureCancelled,true);}];
            [observers addObject:observer];
        }
        s.observers=observers;
    });
    if(failure){fprintf(stderr,"CJGUI_APPKIT_QUEUE_REFUSED reason=%s pid=%d\n",failure.UTF8String,getpid());return;}
    fprintf(stderr,"CJGUI_APPKIT_QUEUE_PREPARED pid=%d window=%u events=%lu request_ns=%llu prepared_ns=%llu origin_ns=%llu seam_present=1 input=in_process_AppKit_queue_synthetic\n",
        getpid(),s.windowNumber,(unsigned long)s.events.count,(unsigned long long)requestNs,(unsigned long long)s.preparedNs,(unsigned long long)s.origin);
    CjFixtureOps ops={CjFixtureClock,CjFixtureWait,CjFixtureValid,CjFixturePost};BOOL pass=CjFixtureRun(s.events,s.cancelUps,plan[@"events"],s.origin,ops,(__bridge void *)s,&failure);
    if(!pass)CjFixtureWriteUp(s,CjFixtureNow(),CjFixtureNow(),YES);
    fprintf(stderr,"CJGUI_APPKIT_QUEUE_DONE pid=%d success=%d reason=%s\n",getpid(),pass,failure.UTF8String?:"none");
    dispatch_async(dispatch_get_main_queue(),^{for(id observer in s.observers)[NSNotificationCenter.defaultCenter removeObserver:observer];s.observers=nil;s.windowHold=nil;});
}
static void *CjFixtureWorker(void *unused) {(void)unused;@autoreleasepool {
    CjFixtureExecute([NSString stringWithUTF8String:getenv("CJGUI_APPKIT_LOCAL_PLAN")],
        [NSString stringWithUTF8String:getenv("CJGUI_APPKIT_LOCAL_SCOPE")],
        [NSString stringWithUTF8String:getenv("CJGUI_APPKIT_LOCAL_UP_FACT")],
        [NSString stringWithUTF8String:getenv("CJGUI_APPKIT_LOCAL_NONCE")]);
}return NULL;}
__attribute__((constructor)) static void CjFixtureLoad(void) {
    if(!getenv("CJGUI_APPKIT_LOCAL_PLAN") || !getenv("CJGUI_APPKIT_LOCAL_SCOPE") ||
       !getenv("CJGUI_APPKIT_LOCAL_UP_FACT") || !getenv("CJGUI_APPKIT_LOCAL_NONCE"))return;
    atomic_init(&gCjFixtureCancelled,false);atomic_init(&gCjFixtureClosed,false);pthread_t worker;
    if(pthread_create(&worker,NULL,CjFixtureWorker,NULL)==0)pthread_detach(worker);
}
#endif
