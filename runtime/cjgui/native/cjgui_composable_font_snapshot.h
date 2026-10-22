#ifndef CJGUI_COMPOSABLE_FONT_SNAPSHOT_H
#define CJGUI_COMPOSABLE_FONT_SNAPSHOT_H

#import <AppKit/AppKit.h>
#import <CoreText/CoreText.h>
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <dispatch/dispatch.h>

// Value-only resource codes extend the four legacy modes without widening the
// scene ABI. Each code denotes ONE immutable generation and is never reused.
// These declarations are internal to the Mac bridge; no NSFont crosses FFI.
NSFont *CjguiRegisteredFontSnapshot(uint32_t code, double size, uint32_t weight);
id CjguiFontResourceLease(uint32_t code) NS_RETURNS_RETAINED;
// Optional bounded lifetime diagnostics. These never retain inspected owners.
BOOL CjguiFontLifetimeDebugEnabled(void);
void CjguiFontLifetimeDebugTrack(id object,uint32_t kind);
void CjguiFontLifetimeDebugVisit(id object,const char *role,uint64_t owner);
void CjguiFontLifetimeDebugBoundary(const char *phase,uint64_t token,id retiring);
void CjguiAsyncFontLifetimeDebugOwners(void);
int32_t cjgui_internal_renderer_font_resource_register(uint32_t kind, const char *source,
    uint32_t fallback, uint32_t *outCode);
int32_t cjgui_internal_renderer_font_resource_release(uint32_t code);
int64_t cjgui_internal_renderer_font_resource_copy_family(uint32_t code, uint8_t *buffer, uint64_t capacity);
int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *values);
uint32_t cjgui_internal_renderer_font_resource_version(void);

// The common declaration is in logical points. Mac text APIs consume the
// absolute line-box height directly; no font-size multiplier or device-scale
// conversion belongs here. Zero restores the system's natural typography.
static inline double CjguiComposableLetterSpacing(double value) {
    return isfinite(value) && value > -1000.0 && value < 1000.0 && value != 0.0 ? value : 0.0;
}
static inline double CjguiComposableLineHeight(double value) {
    return isfinite(value) && value > 0.0 && value < 1000.0 ? value : 0.0;
}
static inline void CjguiApplyComposableTypography(NSMutableDictionary *attributes,
                                                  double letterSpacing, double lineHeight) {
    NSParagraphStyle *base = attributes[NSParagraphStyleAttributeName];
    NSMutableParagraphStyle *paragraph = base ? [base mutableCopy] : [NSMutableParagraphStyle new];
    CGFloat height = CjguiComposableLineHeight(lineHeight);
    paragraph.minimumLineHeight = height;
    paragraph.maximumLineHeight = height;
    paragraph.lineHeightMultiple = 0.0;
    attributes[NSParagraphStyleAttributeName] = [paragraph copy];
    double spacing = CjguiComposableLetterSpacing(letterSpacing);
    if (spacing != 0.0) attributes[NSKernAttributeName] = @(spacing);
    else [attributes removeObjectForKey:NSKernAttributeName];
}

typedef struct {
    CGFloat width, height, lineHeight, baseline;
} CjguiComposableTextMetrics;

// Ephemeral geometry from the same system line layout used by the painter.
// The caller supplies its immutable attributes (and therefore its wrap role).
static inline CjguiComposableTextMetrics CjguiMeasureComposableTypography(
    NSString *value, NSDictionary *attributes, NSFont *font, CGFloat width, double lineHeightPoints) {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithString:value attributes:attributes];
    NSLayoutManager *layout = [NSLayoutManager new];
    layout.backgroundLayoutEnabled = NO;
    [storage addLayoutManager:layout];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:
        NSMakeSize(width > 0.0 ? width : CGFLOAT_MAX / 4.0, CGFLOAT_MAX / 4.0)];
    container.lineFragmentPadding = 0.0;
    container.widthTracksTextView = NO;
    [layout addTextContainer:container];
    [layout ensureLayoutForTextContainer:container];
    CGFloat line = CjguiComposableLineHeight(lineHeightPoints);
    if (line == 0.0) line = MAX(1.0, font.ascender - font.descender + font.leading);
    NSRect used = [layout usedRectForTextContainer:container];
    CGFloat height = MAX(line, NSMaxY(used));
    if (layout.extraLineFragmentTextContainer == container)
        height = MAX(height, NSMaxY(layout.extraLineFragmentRect));
    CGFloat baseline = font.ascender;
    if (layout.numberOfGlyphs > 0) baseline = [layout locationForGlyphAtIndex:0].y +
        NSMinY([layout lineFragmentRectForGlyphAtIndex:0 effectiveRange:NULL]);
    return (CjguiComposableTextMetrics){NSWidth(used), height, line, baseline};
}

// Shared by the accepted scene painter and the private multiline measurement
// worker's main-thread input preparation. The NSFont itself is copied before
// it crosses to the worker; AppKit font selection stays on the owning thread.
static inline NSFontWeight CjguiComposableFontWeightForCode(uint32_t fontWeight) {
    if (fontWeight == 0) return NSFontWeightRegular;
    if (fontWeight < 100) return NSFontWeightBold;
    if (fontWeight < 500) return NSFontWeightRegular;
    if (fontWeight < 600) return NSFontWeightMedium;
    if (fontWeight < 700) return NSFontWeightSemibold;
    return NSFontWeightBold;
}

static inline NSFont *CjguiComposableFontSnapshotForStyle(
    double requested, uint32_t fontWeight, uint32_t fontFamily) {
    CGFloat size = MIN(144.0, MAX(6.0, requested));
    if (fontFamily >= 4) return CjguiRegisteredFontSnapshot(fontFamily, size, fontWeight);
    NSFontWeight weight = CjguiComposableFontWeightForCode(fontWeight);
    BOOL italic = fontFamily == 2 || fontFamily == 3;
    NSFont *base = (fontFamily == 1 || fontFamily == 3)
        ? [NSFont monospacedSystemFontOfSize:size weight:weight]
        : [NSFont systemFontOfSize:size weight:weight];
    if (!italic) return base;
    NSFont *slanted = [[NSFontManager sharedFontManager]
        convertFont:base toHaveTrait:NSItalicFontMask];
    return slanted ?: base;
}

#ifdef CJGUI_FONT_RESOURCE_IMPLEMENTATION
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#ifdef CJGUI_INTERNAL_TESTING
static void (*gCjguiFontTestReadAfterStat)(const char *path);
#endif
// Same opened-file/bounded-chunk/change checks as file-transfer admission.
// This narrow font loader owns no long-lived file descriptor or path state.
static NSData *CjguiReadBoundedFontFile(NSString *path,uint64_t retainedBytes,int32_t *status) {
    struct stat initial={0},before={0},after={0},current={0};
    const char *name=path.fileSystemRepresentation;
    *status=0;
    if (!name || lstat(name,&initial)!=0) {*status=2;return nil;}
    if (!S_ISREG(initial.st_mode)) {*status=3;return nil;}
    int fd=open(name,O_RDONLY|O_CLOEXEC|O_NOFOLLOW|O_NONBLOCK);
    if (fd<0) {*status=2;return nil;}
    NSData *result=nil;
    @try {
        if (fstat(fd,&before)!=0 || !S_ISREG(before.st_mode) || before.st_size<=0 ||
            before.st_dev!=initial.st_dev || before.st_ino!=initial.st_ino ||
            (uint64_t)before.st_size>16u*1024u*1024u) {*status=3;return nil;}
        if (retainedBytes>32u*1024u*1024u ||
            (uint64_t)before.st_size>32u*1024u*1024u-retainedBytes) {*status=4;return nil;}
        const NSUInteger wanted=(NSUInteger)before.st_size;
        NSMutableData *buffer=[NSMutableData dataWithLength:wanted];
        if (!buffer) {*status=3;return nil;}
#ifdef CJGUI_INTERNAL_TESTING
        if (gCjguiFontTestReadAfterStat) gCjguiFontTestReadAfterStat(name);
#endif
        NSUInteger offset=0;
        while (offset<wanted) {
            ssize_t count=read(fd,(uint8_t *)buffer.mutableBytes+offset,MIN((NSUInteger)16384,wanted-offset));
            if (count<0 && errno==EINTR) continue;
            if (count<=0) {*status=3;return nil;}
            offset+=(NSUInteger)count;
        }
        if (fstat(fd,&after)!=0 || after.st_dev!=before.st_dev || after.st_ino!=before.st_ino ||
            after.st_size!=before.st_size ||
            after.st_ctimespec.tv_sec!=before.st_ctimespec.tv_sec || after.st_ctimespec.tv_nsec!=before.st_ctimespec.tv_nsec ||
            after.st_mtimespec.tv_sec!=before.st_mtimespec.tv_sec || after.st_mtimespec.tv_nsec!=before.st_mtimespec.tv_nsec ||
            lstat(name,&current)!=0 || current.st_dev!=before.st_dev || current.st_ino!=before.st_ino ||
            current.st_size!=before.st_size || current.st_ctimespec.tv_sec!=before.st_ctimespec.tv_sec ||
            current.st_ctimespec.tv_nsec!=before.st_ctimespec.tv_nsec) {*status=3;return nil;}
        result=[buffer copy];
    } @catch(NSException *exception) {*status=3;result=nil;} @finally {close(fd);}
    return result;
}
// The existing application resource resolver is shared with raster assets.
static NSString *CjguiComposableImageResolvedPath(NSString *resourcePath);
// Compiled exactly once by the renderer. Other text adapters see the shared
// resolver above. Retirement drops the registry's strong reference; accepted
// nodes, immutable preparation inputs and jobs retain their generation leases.
@interface CjguiFontGeneration : NSObject
@property(nonatomic,strong) NSFont *base;
@property(nonatomic,assign) uint32_t debugCode;
@property(nonatomic,assign) uint64_t debugAcquires;
@property(nonatomic,strong) NSData *bytes;
@property(nonatomic,assign) uint32_t fallback;
@property(nonatomic,assign) BOOL usesFallback;
@property(nonatomic,strong) NSMutableDictionary<NSString *,NSFont *> *snapshots;
@end
@implementation CjguiFontGeneration
- (void)dealloc {
    if(CjguiFontLifetimeDebugEnabled())fprintf(stderr,"FONT_LIFE event=dealloc code=%u\n",_debugCode);
}
@end
BOOL CjguiFontLifetimeDebugEnabled(void){
    static dispatch_once_t once;static BOOL enabled;
    dispatch_once(&once,^{enabled=getenv("CJGUI_FONT_LIFETIME_DEBUG")!=NULL;});return enabled;
}

static NSRecursiveLock *gCjguiFontResourceLock;
static NSMutableDictionary<NSNumber *,CjguiFontGeneration *> *gCjguiActiveFonts;
static NSMapTable<NSNumber *,CjguiFontGeneration *> *gCjguiLeasedFonts;
static uint32_t gCjguiNextFontCode = 4;
static uint64_t gCjguiFontSnapshotBuilds, gCjguiFontRegistrations;
uint32_t cjgui_internal_renderer_font_resource_version(void) { return 1; }
static void CjguiInitFontResources(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        gCjguiFontResourceLock = [NSRecursiveLock new];
        gCjguiActiveFonts = [NSMutableDictionary new];
        gCjguiLeasedFonts = [NSMapTable strongToWeakObjectsMapTable];
    });
}
id CjguiFontResourceLease(uint32_t code) NS_RETURNS_RETAINED {
    if (code < 4) return nil;
    // Weak lookup may retain/autorelease internally. Own that temporary pool
    // here; the retained result transfers one ARC responsibility to the caller,
    // including direct property assignments across translation units.
    __strong CjguiFontGeneration *generation=nil;
    @autoreleasepool {
        CjguiInitFontResources();
        [gCjguiFontResourceLock lock];
        generation=[gCjguiLeasedFonts objectForKey:@(code)];
        if(CjguiFontLifetimeDebugEnabled())generation.debugAcquires++;
        [gCjguiFontResourceLock unlock];
    }
    return generation;
}

NSFont *CjguiRegisteredFontSnapshot(uint32_t code, double size, uint32_t weight) {
    CjguiFontGeneration *generation = CjguiFontResourceLease(code);
    if (!generation) return nil; // Invalid/retired without a lease is a refusal, never a new system choice.
    @synchronized (generation) {
        NSString *key = [NSString stringWithFormat:@"%.17g:%u",size,weight];
        NSFont *font = generation.snapshots[key];
        if (font) return font;
        if (generation.usesFallback) {
            font = CjguiComposableFontSnapshotForStyle(size,weight,generation.fallback);
        } else {
            CTFontRef sized = CTFontCreateCopyWithAttributes((__bridge CTFontRef)generation.base,size,NULL,NULL);
            if (sized && CjguiComposableFontWeightForCode(weight) != NSFontWeightRegular) {
                NSDictionary *traits = @{(__bridge NSString *)kCTFontWeightTrait:@(CjguiComposableFontWeightForCode(weight))};
                CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)
                    @{(__bridge NSString *)kCTFontTraitsAttribute:traits});
                CTFontRef weighted = CTFontCreateCopyWithAttributes(sized,size,NULL,descriptor);
                CFRelease(descriptor);
                if (weighted) {
                    NSFont *candidate = (__bridge NSFont *)weighted;
                    if ([candidate.familyName isEqualToString:generation.base.familyName]) { CFRelease(sized); sized = weighted; }
                    else CFRelease(weighted);
                }
            }
            font = CFBridgingRelease(sized);
        }
        if (!font) return nil;
        if (generation.snapshots.count >= 64) [generation.snapshots removeObjectForKey:generation.snapshots.allKeys.firstObject];
        generation.snapshots[key] = font;
        [gCjguiFontResourceLock lock]; gCjguiFontSnapshotBuilds++; [gCjguiFontResourceLock unlock];
        return font;
    }
}
static int32_t CjguiRegisterFontResource(uint32_t kind,const char *source,uint32_t fallback,uint32_t *outCode) {
    if (outCode) *outCode=0;
    if (!outCode || !source || !source[0] || strnlen(source,4097)>4096 || fallback>3 || (kind!=1 && kind!=2)) return -1;
    NSString *text=[[NSString alloc] initWithUTF8String:source];
    if (!text) return -1;
    CjguiInitFontResources();
    [gCjguiFontResourceLock lock];
    uint64_t retainedBytes=0;NSUInteger live=0;
    for (NSNumber *key in gCjguiLeasedFonts.keyEnumerator.allObjects) {
        CjguiFontGeneration *old=[gCjguiLeasedFonts objectForKey:key];
        if (old) {live++;retainedBytes+=old.bytes.length;} else [gCjguiLeasedFonts removeObjectForKey:key];
    }
    if (gCjguiActiveFonts.count>=128 || live>=256 || gCjguiNextFontCode==UINT32_MAX) {
        [gCjguiFontResourceLock unlock];return 4;
    }
    CjguiFontGeneration *generation=[CjguiFontGeneration new];
    generation.fallback=fallback;generation.snapshots=[NSMutableDictionary new];
    int32_t status=0;
    if (kind==1) {
        CTFontDescriptorRef descriptor=CTFontDescriptorCreateWithAttributes((__bridge CFDictionaryRef)
            @{(__bridge NSString *)kCTFontFamilyNameAttribute:text});
        generation.base=CFBridgingRelease(CTFontCreateWithFontDescriptor(descriptor,13,NULL));
        CFRelease(descriptor);
        if (!generation.base || [generation.base.familyName caseInsensitiveCompare:text]!=NSOrderedSame) {
            generation.base=nil;status=1;
        }
    } else {
        text=CjguiComposableImageResolvedPath(text);
        generation.bytes=CjguiReadBoundedFontFile(text,retainedBytes,&status);
        if (status==4) {[gCjguiFontResourceLock unlock];return 4;}
        if (status==0) {
            CGDataProviderRef provider=generation.bytes ? CGDataProviderCreateWithCFData((__bridge CFDataRef)generation.bytes) : NULL;
            CGFontRef graphic=provider ? CGFontCreateWithDataProvider(provider) : NULL;
            if (graphic) {
                generation.base=CFBridgingRelease(CTFontCreateWithGraphicsFont(graphic,13,NULL,NULL));
                CGFontRelease(graphic);
            }
            if (provider) CGDataProviderRelease(provider);
            if (!generation.base) {generation.bytes=nil;status=3;}
        }
    }
    NSData *family=[generation.base.familyName dataUsingEncoding:NSUTF8StringEncoding];
    BOOL invalidName=family.length==0 || family.length>4096;
    const uint8_t *familyBytes=family.bytes;
    for(NSUInteger i=0;i<family.length && !invalidName;i++)if(familyBytes[i]<32 || familyBytes[i]==127)invalidName=YES;
    if(generation.base && invalidName){generation.base=nil;generation.bytes=nil;status=3;}
    generation.usesFallback=status!=0;
    // Use the actual legacy family (not CT's different user-fixed-pitch face).
    // System/monospaced NSFont values are immutable; no NSFontManager is used
    // during registration. Italic selection remains in the existing snapshot path.
    if (generation.usesFallback) generation.base=CjguiComposableFontSnapshotForStyle(13,0,fallback & 1u);
    if (!generation.base) {[gCjguiFontResourceLock unlock];return -1;}
    uint32_t code=gCjguiNextFontCode++;
    generation.debugCode=code;
    if(CjguiFontLifetimeDebugEnabled())fprintf(stderr,"FONT_LIFE event=register code=%u bytes=%lu\n",code,(unsigned long)generation.bytes.length);
    gCjguiActiveFonts[@(code)]=generation;[gCjguiLeasedFonts setObject:generation forKey:@(code)];
    gCjguiFontRegistrations++;*outCode=code;
    [gCjguiFontResourceLock unlock];return status;
}
int32_t cjgui_internal_renderer_font_resource_register(uint32_t kind,const char *source,uint32_t fallback,uint32_t *outCode) {
    // CoreText/CGFont registration is immutable and thread safe. In particular
    // it does not dispatch onto AppKit before an application starts its loop.
    @autoreleasepool { return CjguiRegisterFontResource(kind,source,fallback,outCode); }
}
int32_t cjgui_internal_renderer_font_resource_release(uint32_t code) {
    @autoreleasepool {
    CjguiInitFontResources();[gCjguiFontResourceLock lock];
    if(CjguiFontLifetimeDebugEnabled())fprintf(stderr,"FONT_LIFE event=retire code=%u\n",code);
    BOOL existed=gCjguiActiveFonts[@(code)]!=nil;[gCjguiActiveFonts removeObjectForKey:@(code)];
    [gCjguiFontResourceLock unlock];return existed?0:-1;
    }
}
int64_t cjgui_internal_renderer_font_resource_copy_family(uint32_t code,uint8_t *buffer,uint64_t capacity) {
    @autoreleasepool {
    CjguiFontGeneration *generation=CjguiFontResourceLease(code);
    NSData *name=[generation.base.familyName dataUsingEncoding:NSUTF8StringEncoding];
    if (!name || !buffer || name.length>capacity) return -1;
    memcpy(buffer,name.bytes,name.length);return (int64_t)name.length;
    }
}
int32_t cjgui_internal_renderer_font_resource_stats(uint64_t *values) {
    @autoreleasepool {
    if(!values)return -1;
    if(CjguiFontLifetimeDebugEnabled())CjguiFontLifetimeDebugBoundary("font_stats",0,nil);
    CjguiInitFontResources();[gCjguiFontResourceLock lock];
    memset(values,0,5*sizeof(uint64_t));values[0]=gCjguiActiveFonts.count;
    for(NSNumber *key in gCjguiLeasedFonts.keyEnumerator.allObjects){
        CjguiFontGeneration *generation=[gCjguiLeasedFonts objectForKey:key];
        if(generation){values[1]++;values[2]+=generation.bytes.length;}
        else [gCjguiLeasedFonts removeObjectForKey:key];
    }
    values[3]=gCjguiFontSnapshotBuilds;values[4]=gCjguiFontRegistrations;
    [gCjguiFontResourceLock unlock];return 0;
    }
}
#endif

#endif
