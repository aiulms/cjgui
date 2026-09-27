#import <AppKit/AppKit.h>
#include <stdlib.h>

// Test-only general-pasteboard guard.  It snapshots every advertised type and
// byte payload, then restores only when both the expected byte image and the
// pasteboard change count still match.  A user copy during a verifier run is
// therefore left untouched, including custom non-text pasteboard values that
// AppleScript's `the clipboard` cannot coerce.

static NSArray<NSDictionary<NSString *, NSData *> *> *snapshotItems(NSArray<NSPasteboardItem *> *items) {
    NSMutableArray<NSDictionary<NSString *, NSData *> *> *records = [NSMutableArray array];
    for (NSPasteboardItem *item in items ?: @[]) {
        NSMutableDictionary<NSString *, NSData *> *record = [NSMutableDictionary dictionary];
        for (NSPasteboardType type in item.types) {
            NSData *data = [item dataForType:type];
            if (data) record[type] = data;
        }
        [records addObject:[record copy]];
    }
    return [records copy];
}

static NSArray<NSDictionary<NSString *, NSData *> *> *snapshot(NSPasteboard *pasteboard) {
    return snapshotItems(pasteboard.pasteboardItems ?: @[]);
}

static BOOL writeSnapshot(NSString *path, NSPasteboard *pasteboard) {
    NSDictionary *value = @{ @"changeCount": @(pasteboard.changeCount), @"items": snapshot(pasteboard) };
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:value
                                                                 format:NSPropertyListBinaryFormat_v1_0
                                                                options:0
                                                                  error:&error];
    return data && !error && [data writeToFile:path options:NSDataWritingAtomic error:&error] && !error;
}

static NSDictionary *readSnapshot(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    id value = data ? [NSPropertyListSerialization propertyListWithData:data
                                                                   options:NSPropertyListImmutable
                                                                    format:nil
                                                                     error:&error] : nil;
    if (error || ![value isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *snapshotValue = (NSDictionary *)value;
    if (![snapshotValue[@"changeCount"] isKindOfClass:[NSNumber class]] ||
        ![snapshotValue[@"items"] isKindOfClass:[NSArray class]]) return nil;
    return snapshotValue;
}

static BOOL restore(NSPasteboard *pasteboard, NSDictionary *snapshotValue) {
    NSArray *records = snapshotValue[@"items"];
    if (![pasteboard clearContents]) return NO;
    NSMutableArray<NSPasteboardItem *> *items = [NSMutableArray array];
    for (id rawRecord in records) {
        if (![rawRecord isKindOfClass:[NSDictionary class]]) return NO;
        NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
        for (id rawType in [(NSDictionary *)rawRecord allKeys]) {
            id rawData = ((NSDictionary *)rawRecord)[rawType];
            if (![rawType isKindOfClass:[NSString class]] || ![rawData isKindOfClass:[NSData class]]) return NO;
            [item setData:rawData forType:(NSPasteboardType)rawType];
        }
        [items addObject:item];
    }
    return items.count == 0 || [pasteboard writeObjects:items];
}

static NSPasteboardType pasteboardTypeForFormat(NSString *format) {
    if ([format isEqualToString:@"text/plain"]) return NSPasteboardTypeString;
    NSData *bytes = [format dataUsingEncoding:NSUTF8StringEncoding];
    if (!bytes || bytes.length == 0) return nil;
    NSMutableString *type = [NSMutableString stringWithString:@"org.cangjie.cjgui.transfer.f"];
    const uint8_t *raw = bytes.bytes;
    for (NSUInteger index = 0; index < bytes.length; index++) [type appendFormat:@"%02x", (unsigned int)raw[index]];
    return type;
}

static BOOL writeExpectedTransferSource(NSString *path, NSString *format, NSString *payload,
                                        NSString *sourceKind, NSString *sourceIdentity, int64_t sourceId) {
    NSPasteboardType type = pasteboardTypeForFormat(format);
    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *metadata = @{ @"kind": sourceKind, @"identity": sourceIdentity,
                                @"id": @(sourceId), @"format": format };
    NSError *error = nil;
    NSData *metadataData = [NSPropertyListSerialization dataWithPropertyList:metadata
                                                                         format:NSPropertyListBinaryFormat_v1_0
                                                                        options:0 error:&error];
    if (!type || !payloadData || !metadataData || error) return NO;
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setData:payloadData forType:type];
    [item setData:metadataData forType:@"org.cangjie.cjgui.transfer-source"];
    NSDictionary *value = @{ @"changeCount": @(-1), @"items": snapshotItems(@[ item ]) };
    NSData *serialized = [NSPropertyListSerialization dataWithPropertyList:value
                                                                        format:NSPropertyListBinaryFormat_v1_0
                                                                       options:0 error:&error];
    return serialized && !error && [serialized writeToFile:path options:NSDataWritingAtomic error:&error] && !error;
}

static BOOL startPNGFixture(NSString *originalPath, NSString *expectedPath, NSString *pngPath,
                            NSPasteboard *pasteboard) {
    NSData *pngBytes = [NSData dataWithContentsOfFile:pngPath];
    if (!pngBytes || !writeSnapshot(originalPath, pasteboard) || ![pasteboard clearContents]) return NO;
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setData:pngBytes forType:NSPasteboardTypePNG];
    if (![pasteboard writeObjects:@[ item ]]) return NO;
    return writeSnapshot(expectedPath, pasteboard);
}

// Optional `--pb <name>` selects a named (non-user) pasteboard for branch
// tests; without it the general pasteboard is used for the real input chain.
static NSString *pasteboardNameFromArguments(int argc, const char *argv[]) {
    for (int index = 1; index + 1 < argc; index++) {
        if (strcmp(argv[index], "--pb") == 0) {
            return [NSString stringWithUTF8String:argv[index + 1]];
        }
    }
    return nil;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) return 2;
        NSString *pbName = pasteboardNameFromArguments(argc, argv);
        // Dispatch on an argument vector with the optional `--pb <name>` pair
        // removed, so positional argc checks stay independent of pasteboard
        // selection.
        const char *args[32];
        int count = 0;
        for (int index = 0; index < argc && count < 32; index++) {
            if (strcmp(argv[index], "--pb") == 0) {
                index += 1;
                continue;
            }
            args[count++] = argv[index];
        }
        if (count < 3) return 2;
        NSString *command = [NSString stringWithUTF8String:args[1]];
        NSPasteboard *pasteboard = pbName ? [NSPasteboard pasteboardWithName:pbName]
                                          : NSPasteboard.generalPasteboard;
        if (!pasteboard) return 1;
        if ([command isEqualToString:@"snapshot"] && count == 3) {
            return writeSnapshot([NSString stringWithUTF8String:args[2]], pasteboard) ? 0 : 1;
        }
        if ([command isEqualToString:@"start-text"] && count == 4) {
            NSString *original = [NSString stringWithUTF8String:args[2]];
            NSString *expected = [NSString stringWithUTF8String:args[3]];
            if (!writeSnapshot(original, pasteboard) || ![pasteboard clearContents]) return 1;
            NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
            [item setString:@"external-text" forType:NSPasteboardTypeString];
            if (![pasteboard writeObjects:@[ item ]]) return 1;
            return writeSnapshot(expected, pasteboard) ? 0 : 1;
        }
        if ([command isEqualToString:@"start-png"] && count == 5) {
            // Independent standard PNG producer: the file contents are copied
            // verbatim to NSPasteboardTypePNG, with no CJGUI transfer metadata.
            return startPNGFixture([NSString stringWithUTF8String:args[2]],
                [NSString stringWithUTF8String:args[3]],
                [NSString stringWithUTF8String:args[4]], pasteboard) ? 0 : 1;
        }
        if ([command isEqualToString:@"is-current"] && count == 3) {
            NSDictionary *expected = readSnapshot([NSString stringWithUTF8String:args[2]]);
            if (!expected) return 1;
            BOOL countMatches = [expected[@"changeCount"] integerValue] < 0 ||
                pasteboard.changeCount == [expected[@"changeCount"] integerValue];
            return countMatches && [snapshot(pasteboard) isEqual:expected[@"items"]] ? 0 : 1;
        }
        if ([command isEqualToString:@"expected-transfer-source"] && count == 8) {
            return writeExpectedTransferSource([NSString stringWithUTF8String:args[2]],
                [NSString stringWithUTF8String:args[3]], [NSString stringWithUTF8String:args[4]],
                [NSString stringWithUTF8String:args[5]], [NSString stringWithUTF8String:args[6]],
                strtoll(args[7], NULL, 10)) ? 0 : 1;
        }
        if ([command isEqualToString:@"restore-if-current"] && count == 4) {
            NSDictionary *original = readSnapshot([NSString stringWithUTF8String:args[2]]);
            NSDictionary *expected = readSnapshot([NSString stringWithUTF8String:args[3]]);
            if (!original || !expected) return 1;
            BOOL matchesExpected = ([expected[@"changeCount"] integerValue] < 0 ||
                pasteboard.changeCount == [expected[@"changeCount"] integerValue]) &&
                [snapshot(pasteboard) isEqual:expected[@"items"]];
            BOOL alreadyOriginal = [snapshot(pasteboard) isEqual:original[@"items"]];
            if (!matchesExpected) {
                // Never overwrite a value we do not own. `already-original`
                // means the user value is intact; `foreign` means someone else
                // wrote and we leave it alone.
                fprintf(stdout, "cjgui_clipboard_guard restored=false state=%s\n",
                        alreadyOriginal ? "already-original" : "foreign");
                return 0;
            }
            BOOL restored = restore(pasteboard, original);
            fprintf(stdout, "cjgui_clipboard_guard restored=%s state=%s\n",
                    restored ? "true" : "false", restored ? "restored" : "restore-failed");
            return restored ? 0 : 1;
        }
        if ([command isEqualToString:@"write-text"] && count == 3) {
            // Writes a plain text value to the selected pasteboard (used by
            // branch tests on a private pasteboard to simulate a foreign copy).
            NSString *text = [NSString stringWithUTF8String:args[2]];
            if (!text || ![pasteboard clearContents]) return 1;
            NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
            [item setString:text forType:NSPasteboardTypeString];
            return [pasteboard writeObjects:@[ item ]] ? 0 : 1;
        }
        if ([command isEqualToString:@"write-text-with-extra-type"] && count == 4) {
            // Writes the same text value plus one extra advertised type, so a
            // text-only comparison cannot pass for a different pasteboard
            // image. Test-only helper on a private pasteboard.
            NSString *text = [NSString stringWithUTF8String:args[2]];
            NSString *extraType = [NSString stringWithUTF8String:args[3]];
            if (!text || !extraType || ![pasteboard clearContents]) return 1;
            NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
            [item setString:text forType:NSPasteboardTypeString];
            [item setData:[@"extra" dataUsingEncoding:NSUTF8StringEncoding] forType:extraType];
            return [pasteboard writeObjects:@[ item ]] ? 0 : 1;
        }
        if ([command isEqualToString:@"restore-fixture"] && count == 4) {
            // Recovery for a fixture value this harness itself leaked (for
            // example a tested script was killed mid-write). It restores the
            // saved user snapshot only while the live pasteboard still holds
            // exactly the named fixture text; any other value - including a
            // user copy that raced us - is preserved and reported as foreign.
            NSDictionary *original = readSnapshot([NSString stringWithUTF8String:args[2]]);
            NSString *fixture = [NSString stringWithUTF8String:args[3]];
            if (!original || !fixture) return 1;
            NSString *live = [pasteboard stringForType:NSPasteboardTypeString];
            if (![live isEqualToString:fixture]) {
                fprintf(stdout, "cjgui_clipboard_guard fixture_restore=false state=%s\n",
                        live.length == 0 ? "empty" : "foreign");
                return 0;
            }
            BOOL restored = restore(pasteboard, original);
            fprintf(stdout, "cjgui_clipboard_guard fixture_restore=%s state=%s\n",
                    restored ? "true" : "false", restored ? "restored" : "restore-failed");
            return restored ? 0 : 1;
        }
        if ([command isEqualToString:@"status"] && count == 3) {
            // Reports the exact relationship between the live pasteboard and a
            // snapshot, comparing every item type's raw bytes.
            NSDictionary *expected = readSnapshot([NSString stringWithUTF8String:args[2]]);
            if (!expected) return 1;
            BOOL same = [snapshot(pasteboard) isEqual:expected[@"items"]];
            fprintf(stdout, "cjgui_clipboard_guard status=%s\n", same ? "match" : "mismatch");
            return same ? 0 : 1;
        }
        return 2;
    }
}
