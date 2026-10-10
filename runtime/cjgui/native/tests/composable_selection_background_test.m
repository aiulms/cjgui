// Independent TextKit fixture: no window, event injection, application launch,
// Metal device, or shared cjpm output. Compile the paired native source.
#define CJGUI_INTERNAL_TESTING 1
#import "../cjgui_internal_renderer.m"

static int failures = 0;
static int checks = 0;
#define CHECK(condition, name) do { checks++; BOOL ok = (condition); \
    fprintf(stderr, "%s %s\n", ok ? "PASS" : "FAIL", name); if (!ok) failures++; } while (0)

static CJGuiInternalComposableSceneNode *SelectionNode(NSString *body) {
    CJGuiInternalComposableSceneNode *node = [CJGuiInternalComposableSceneNode new];
    CjguiInternalRendererComposableNode raw = {0};
    raw.nodeId = 901; raw.resourceId = 7; raw.projectionVersion = 1;
    raw.nodeKind = CJGUI_INTERNAL_RENDERER_COMPOSABLE_TEXT;
    raw.width = 215; raw.height = 350; raw.clipWidth = 215; raw.clipHeight = 350;
    raw.fontSize = 18; raw.fontWeight = 400; raw.textAlpha = 1;
    node.node = raw; node.value = body; node.label = @"";
    return node;
}

static NSDictionary *SelectionBaseAttributes(void) {
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.lineBreakStrategy = NSLineBreakStrategyNone;
    return @{ NSFontAttributeName:[NSFont systemFontOfSize:18],
              NSForegroundColorAttributeName:[NSColor blackColor],
              NSParagraphStyleAttributeName:paragraph };
}

static NSString *SelectionWire(NSString *body, BOOL explicitBackground) {
    return [NSString stringWithFormat:@"0:%lu:18:400:0:0:0:0:1:1:0.2:0.4:0.8:0.45%@",
        (unsigned long)[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
        explicitBackground ? @":1" : @""];
}

static NSString *OrdinaryRuns(void) {
    // Bold, oblique, monospaced inline code with its own background, and link.
    return @"0:4:24:700:0:0.6:0.1:0.2:1:0:0:0:0:0;"
            "5:11:18:400:2:0.1:0.6:0.2:1:0:0:0:0:0;"
            "12:16:20:400:1:0.3:0.2:0.7:1:1:0.8:0.8:0.8:1;"
            "17:21:18:400:0:0.1:0.2:0.9:1:0:0:0:0:0";
}

static NSAttributedString *BuildAttributes(CJGuiInternalComposableSceneNode *node,
                                          NSString *wire) {
    NSData *runs = CjguiComposableDecodeStyleRuns(wire);
    return CjguiComposableAttributedText(node, node.value, SelectionBaseAttributes(),
        runs.bytes, (uint32_t)(runs.length / sizeof(CjguiInternalTextStyleRun)));
}

static BOOL SameNonBackground(NSAttributedString *a, NSAttributedString *b) {
    if (![a.string isEqualToString:b.string]) return NO;
    for (NSUInteger index = 0; index < a.length; index++) {
        NSMutableDictionary *left = [[a attributesAtIndex:index effectiveRange:NULL] mutableCopy];
        NSMutableDictionary *right = [[b attributesAtIndex:index effectiveRange:NULL] mutableCopy];
        [left removeObjectForKey:NSBackgroundColorAttributeName];
        [right removeObjectForKey:NSBackgroundColorAttributeName];
        [left removeObjectForKey:CjguiActiveRunBackgroundOwner];
        [right removeObjectForKey:CjguiActiveRunBackgroundOwner];
        if (![left isEqualToDictionary:right]) return NO;
    }
    return YES;
}

static NSString *ChangeField(NSString *wire, NSUInteger index, NSString *value) {
    NSMutableArray *fields = [[wire componentsSeparatedByString:@":"] mutableCopy];
    fields[index] = value;
    return [fields componentsJoinedByString:@":"];
}

static NSString *RepeatWire(NSString *wire, NSUInteger count) {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger index = 0; index < count; index++) [items addObject:wire];
    return [items componentsJoinedByString:@";"];
}

static void CheckLayout(CJGuiInternalComposableSceneNode *node, NSString *ordinary, NSString *decorated) {
    CjguiPreparedTextNodeLayout *a = CjguiPrepareTextNodeLayout(node, node.value, 1,
        CjguiComposableDecodeStyleRuns(ordinary), nil);
    CjguiPreparedTextNodeLayout *b = CjguiPrepareTextNodeLayout(node, node.value, 1,
        CjguiComposableDecodeStyleRuns(decorated), nil);
    [a.layoutManager ensureLayoutForTextContainer:a.container];
    [b.layoutManager ensureLayoutForTextContainer:b.container];
    CHECK(a && b && SameNonBackground(a.storage, b.storage), "prepared_layout_preserves_all_non_background_attributes");
    CHECK(a && b && [a.storage isEqualToAttributedString:b.storage],
        "selection_only_run_reuses_immutable_text_layout_attributes");
    CHECK(a.positionLease != b.positionLease, "new_preparation_may_have_distinct_lease_without_changing_geometry");
    BOOL lines = a.layoutManager.numberOfGlyphs == b.layoutManager.numberOfGlyphs &&
        NSEqualRects([a.layoutManager usedRectForTextContainer:a.container],
                     [b.layoutManager usedRectForTextContainer:b.container]);
    BOOL hits = YES, stops = YES;
    NSUInteger lineCount = 0, hitCount = 0, stopCount = 0;
    for (NSUInteger glyph = 0; glyph < a.layoutManager.numberOfGlyphs;) {
        NSRange ar = NSMakeRange(0, 0), br = NSMakeRange(0, 0);
        NSRect ra = [a.layoutManager lineFragmentRectForGlyphAtIndex:glyph effectiveRange:&ar];
        NSRect rb = [b.layoutManager lineFragmentRectForGlyphAtIndex:glyph effectiveRange:&br];
        lines &= NSEqualRanges(ar, br) && NSEqualRects(ra, rb);
        if (ar.length == 0) { lines = NO; break; }
        lineCount++;
        for (CGFloat x = 0; x <= a.container.size.width; x += 3.25) {
            NSPoint point = NSMakePoint(x, NSMidY(ra));
            CGFloat af = 0, bf = 0;
            NSUInteger ai = [a.layoutManager characterIndexForPoint:point inTextContainer:a.container
                fractionOfDistanceBetweenInsertionPoints:&af];
            NSUInteger bi = [b.layoutManager characterIndexForPoint:point inTextContainer:b.container
                fractionOfDistanceBetweenInsertionPoints:&bf];
            hits &= ai == bi && fabs(af - bf) < 0.000001;
            hitCount++;
        }
        NSUInteger character = [a.layoutManager characterIndexForGlyphAtIndex:glyph];
        CjguiStopLine as = {0}, bs = {0};
        CjguiInternalRendererStatus ast = CjguiResolveStopLine(a.layoutManager, node.value, character, &as);
        CjguiInternalRendererStatus bst = CjguiResolveStopLine(b.layoutManager, node.value, character, &bs);
        stops &= ast == CJGUI_INTERNAL_RENDERER_OK && ast == bst && as.count == bs.count &&
            as.lineLocation == bs.lineLocation && as.lineLength == bs.lineLength &&
            NSEqualRanges(as.lineGlyphRange, bs.lineGlyphRange);
        if (as.count == bs.count) for (NSUInteger i = 0; i < as.count; i++) {
            stops &= as.points[i].charIndex == bs.points[i].charIndex &&
                as.points[i].branch == bs.points[i].branch && fabs(as.points[i].x - bs.points[i].x) < 0.000001;
            stopCount++;
        }
        CjguiFreeStopLine(&as); CjguiFreeStopLine(&bs);
        glyph = NSMaxRange(ar);
    }
    CHECK(lines && lineCount > 1, "actual_TextKit_line_breaks_and_rectangles_equal");
    CHECK(hits && hitCount > 100, "actual_TextKit_hit_indices_and_fractions_equal");
    CHECK(stops && stopCount > 10, "actual_primary_alternate_caret_stops_equal");
    fprintf(stderr, "geometry lines=%lu hits=%lu stops=%lu\n", (unsigned long)lineCount,
        (unsigned long)hitCount, (unsigned long)stopCount);
}

static void CheckActiveRestoration(CJGuiInternalComposableSceneNode *node, NSString *ordinary,
                                   NSString *decorated, NSString *shrunk) {
    CJGuiInternalSession *session = [CJGuiInternalSession new];
    session.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 215, 350) session:session];
    overlay.inputProxy.string = node.value;
    NSTextStorage *storage = overlay.inputProxy.textStorage;
    [storage addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle)
        range:NSMakeRange(0, storage.length)];
    session.composableTextStyleRunsRaw[@(node.node.nodeId)] = ordinary;
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:SelectionBaseAttributes()];
    NSAttributedString *before = [storage copy];
    id codeBackground = [before attribute:NSBackgroundColorAttributeName atIndex:12 effectiveRange:NULL];
    session.composableTextStyleRunsRaw[@(node.node.nodeId)] = decorated;
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:SelectionBaseAttributes()];
    CHECK(SameNonBackground(before, storage), "active_proxy_preserves_non_background_and_platform_attributes");
    CHECK(![codeBackground isEqual:[storage attribute:NSBackgroundColorAttributeName atIndex:12 effectiveRange:NULL]],
        "active_proxy_selection_overrides_inline_code_background");
    session.composableTextStyleRunsRaw[@(node.node.nodeId)] = shrunk;
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:SelectionBaseAttributes()];
    CHECK([codeBackground isEqual:[storage attribute:NSBackgroundColorAttributeName atIndex:12 effectiveRange:NULL]],
        "active_proxy_shrinking_selection_restores_inline_code_background");
    session.composableTextStyleRunsRaw[@(node.node.nodeId)] = ordinary;
    [overlay applyActiveComposableTextAttributesForNode:node baseAttributes:SelectionBaseAttributes()];
    CHECK([before isEqualToAttributedString:storage], "active_proxy_clearing_selection_exactly_restores_ordinary_attributes");
}

static void CheckAdmission(void) {
    NSString *body = @"a中🙂e\u0301";
    NSString *one = @"0:1:0:0:0:0:0:0:0:1:0.2:0.4:0.8:0.5:1";
    NSString *old = @"0:1:18:400:0:0:0:0:1:0:0:0:0:0";
    NSMutableArray *cases = [NSMutableArray array];
    for (NSString *tag in @[@"3", @"0", @"01", @"1junk", @""])
        [cases addObject:@[ChangeField(one, 14, tag), @36, [@"tag_" stringByAppendingString:tag]]];
    [cases addObject:@[[one stringByAppendingString:@":1"], @36, @"extra_field"]];
    [cases addObject:@[ChangeField(one, 9, @"0"), @36, @"background_authority_missing"]];
    for (NSString *color in @[@"nan", @"inf", @"-0.1", @"1.000001", @"0.2tail", @" 0.2", @"0.2 "])
        [cases addObject:@[ChangeField(one, 10, color), @36, [@"color_" stringByAppendingString:color]]];
    [cases addObject:@[ChangeField(one, 13, @"NaN"), @36, @"alpha_not_finite"]];
    for (NSString *endpoint in @[@"-1", @"+1", @"1junk", @"4294967296", @"18446744073709551616"])
        [cases addObject:@[ChangeField(one, 0, endpoint), @34, [@"start_" stringByAppendingString:endpoint]]];
    [cases addObject:@[ChangeField(one, 1, @"0"), @34, @"empty_range"]];
    [cases addObject:@[ChangeField(one, 0, @"2"), @34, @"inverted_range"]];
    [cases addObject:@[ChangeField(one, 1, @"100"), @34, @"past_value"]];
    [cases addObject:@[ChangeField(ChangeField(one, 0, @"2"), 1, @"4"), @34, @"split_start_CJK"]];
    [cases addObject:@[ChangeField(one, 1, @"2"), @34, @"split_end_CJK"]];
    [cases addObject:@[ChangeField(ChangeField(one, 0, @"4"), 1, @"6"), @34, @"split_end_emoji"]];
    [cases addObject:@[RepeatWire(one, 1025), @16, @"selection_count_1025"]];
    [cases addObject:@[[RepeatWire(old, 2048) stringByAppendingFormat:@";%@", one], @16, @"total_count_2049"]];

    CJGuiInternalSession *ctx = [CJGuiInternalSession new];
    uint64_t token = CjguiAllocateSession(ctx);
    ctx.view = [CJGuiInternalMetalView new]; // Invalid admission returns before any view/Metal operation.
    ctx.composableTextStyleRunsRaw = [NSMutableDictionary dictionary];
    CJGuiInternalComposableSceneNode *accepted = SelectionNode(@"old accepted value 🙂");
    accepted.styleRunsSignature = old;
    accepted.preparedTextLayout = CjguiPrepareTextNodeLayout(accepted, accepted.value, 1,
        CjguiComposableDecodeStyleRuns(old), nil);
    ctx.composableNodes = [NSMutableArray arrayWithObject:accepted];
    ctx.composableSceneVersion = 77;
    CjguiPreparedTextNodeLayout *acceptedLayout = accepted.preparedTextLayout;
    NSAttributedString *acceptedAttributes = [acceptedLayout.storage copy];
    CJGuiInternalComposableSceneOverlay *overlay = [[CJGuiInternalComposableSceneOverlay alloc]
        initWithFrame:NSMakeRect(0, 0, 215, 350) session:ctx];
    ctx.composableSceneOverlay = overlay;
    overlay.applyingProjection = YES;
    overlay.inputProxy.string = @"existing unaccepted local input";
    overlay.inputProxy.selectedRange = NSMakeRange(4, 3);
    overlay.applyingProjection = NO;
    NSString *proxyBefore = [overlay.inputProxy.string copy];
    NSRange selectionBefore = overlay.inputProxy.selectedRange;
    CJGuiInternalComposableSceneNode *candidate = SelectionNode(body);
    CjguiInternalRendererComposableNode raw = candidate.node;
    CjguiInternalRendererComposableGeometry geometry = {0}; geometry.nodeId = raw.nodeId;
    CjguiComposablePreparation *p = [CjguiComposablePreparation new];
    p.preparationId = 101; p.projectionVersion = 1;
    p.nodes = [NSMutableArray arrayWithObject:[CJGuiInternalComposableSceneNode new]];
    p.filled = [NSMutableIndexSet indexSet]; p.runs = [NSMutableDictionary dictionary];
    ctx.composablePreparation = p;
    ctx.stagedComposableNodes = [NSMutableArray arrayWithObject:candidate];
    for (NSArray *entry in cases) {
        NSString *wire = entry[0], *name = entry[2];
        CjguiInternalRendererStatus expected = [entry[1] intValue];
        CjguiInternalRendererStatus validation = CjguiComposableValidateSelectionBackgroundRuns(wire, body);
        CjguiInternalRendererStatus prepare = cjgui_internal_renderer_prepare_composable_node(token, 101, 0,
            &raw, &geometry, "", body.UTF8String, "plain-text", "binding", "", "", "", wire.UTF8String);
        ctx.composableTextStyleRunsRaw[@(raw.nodeId)] = wire;
        CjguiInternalRendererStatus stage = CjguiPrepareComposableTextResources(ctx);
        BOOL preserved = p.filled.count == 0 && p.runs.count == 0 && p.ownedPacketBytes == 0 &&
            candidate.preparedTextLayout == nil && ctx.view.textRasterCount == 0 &&
            ctx.composableSceneVersion == 77 && ctx.composableNodes.firstObject == accepted &&
            accepted.preparedTextLayout == acceptedLayout &&
            [acceptedLayout.storage isEqualToAttributedString:acceptedAttributes] &&
            [accepted.value isEqualToString:@"old accepted value 🙂"] &&
            [accepted.styleRunsSignature isEqualToString:old] &&
            [overlay.inputProxy.string isEqualToString:proxyBefore] &&
            NSEqualRanges(overlay.inputProxy.selectedRange, selectionBefore);
        NSString *label = [@"prepare_and_stage_named_refusal_" stringByAppendingString:name];
        CHECK(validation == expected && prepare == expected && stage == expected && preserved, label.UTF8String);
    }
    ctx.composableTextStyleRunsRaw[@(raw.nodeId)] = old;
    NSString *badTag = ChangeField(one, 14, @"3");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token, raw.nodeId, badTag.UTF8String) == 36 &&
        [ctx.composableTextStyleRunsRaw[@(raw.nodeId)] isEqualToString:old],
        "invalid_wire_setter_preserves_prior_declaration");
    CHECK(CjguiComposableDecodeStyleRuns(badTag) == nil &&
        CjguiComposableDecodeStyleRuns([old stringByAppendingFormat:@";%@", badTag]) == nil,
        "unknown_tag_never_decodes_partial_or_ordinary_fallback");
    CHECK(cjgui_internal_renderer_prepare_composable_node(token, 101, 0, &raw, &geometry, "", body.UTF8String,
        "plain-text", "binding", "", "", "", one.UTF8String) == 0 && p.filled.count == 1,
        "valid_tag_enters_same_private_preparation_once");
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token, raw.nodeId, one.UTF8String) == 0,
        "valid_tag_uses_normal_run_setter");

    for (NSArray *range in @[@[@1, @4], @[@4, @8], @[@8, @11], @[@9, @11]]) {
        NSString *wire = ChangeField(ChangeField(one, 0, [range[0] stringValue]), 1, [range[1] stringValue]);
        CHECK(CjguiComposableValidateSelectionBackgroundRuns(wire, body) == 0,
            "exact_CJK_emoji_combining_scalar_endpoints_accepted");
    }
    NSString *many = [RepeatWire(old, 1024) stringByAppendingFormat:@";%@", RepeatWire(one, 1024)];
    CHECK(CjguiComposableValidateSelectionBackgroundRuns(many, body) == 0,
        "exact_selection_1024_and_total_2048_budget_accepted");
    CHECK(CjguiComposableValidateSelectionBackgroundRuns(ChangeField(one, 10, @"1e-320"), body) == 0 &&
        CjguiComposableValidateSelectionBackgroundRuns(ChangeField(one, 10, @"0"), body) == 0 &&
        CjguiComposableValidateSelectionBackgroundRuns(ChangeField(one, 13, @"1"), body) == 0,
        "finite_small_color_and_zero_one_endpoints_accepted");
    NSString *limitBody = [@"a" stringByPaddingToLength:65536 withString:@"a" startingAtIndex:0];
    CHECK(CjguiComposableValidateSelectionBackgroundRuns(one, limitBody) == 0 &&
        CjguiComposableValidateSelectionBackgroundRuns(one, [limitBody stringByAppendingString:@"a"]) == 16,
        "new_tag_text_65536_byte_budget_exact");
    CHECK(CjguiComposableValidateSelectionBackgroundRuns(old, [limitBody stringByAppendingString:@"a"]) == 0 &&
        CjguiComposableValidateSelectionBackgroundRuns(RepeatWire(old, 2049), body) == 0,
        "ordinary_runs_do_not_inherit_new_tag_text_or_count_budget");
    NSString *overWire = [@"x" stringByPaddingToLength:CjguiTextStyleRunWireByteCapacity + 1
        withString:@"x" startingAtIndex:0];
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token, raw.nodeId, overWire.UTF8String) == 16,
        "wire_exceeding_two_MiB_rejected_before_copy");
    char invalidUtf8[] = { (char)0xC3, 0 };
    CHECK(cjgui_internal_renderer_set_composable_text_runs(token, raw.nodeId, invalidUtf8) == 14,
        "invalid_UTF8_wire_named_refusal");
    ctx.composablePreparation = nil;
    CjguiReleaseSession(token);
}

static void CheckDeclaredDecoration(CJGuiInternalComposableSceneNode *node,
                                    NSString *ordinary, NSString *decorated) {
    node.preparedTextLayout = CjguiPrepareTextNodeLayout(node, node.value, 1,
        CjguiComposableDecodeStyleRuns(ordinary), nil);
    uint64_t lease = node.preparedTextLayout.positionLease;
    NSArray<NSDictionary *> *selected = CjguiComposableDeclaredSelectionDecorations(node,
        CjguiComposableDecodeStyleRuns(decorated));
    NSArray<NSDictionary *> *cleared = CjguiComposableDeclaredSelectionDecorations(node,
        CjguiComposableDecodeStyleRuns(ordinary));
    CHECK(selected != nil && selected.count > 0 && cleared.count == 0,
        "selection_decorations_appear_and_clear_without_body_relayout");
    CHECK(node.preparedTextLayout.positionLease == lease,
        "selection_decoration_keeps_same_accepted_layout_lease");
    BOOL valid = YES;
    for (NSDictionary *entry in selected) {
        NSRect rect = [entry[@"rect"] rectValue];
        NSColor *color = [[entry[@"color"] colorUsingColorSpace:NSColorSpace.sRGBColorSpace] copy];
        valid &= !NSIsEmptyRect(rect) && rect.origin.x >= 0 && rect.origin.y >= 0 &&
            NSMaxX(rect) <= node.node.width && NSMaxY(rect) <= node.node.height &&
            fabs(color.alphaComponent - 0.45) < 0.00001 &&
            fabs(color.redComponent - 0.2) < 0.00001 &&
            fabs(color.greenComponent - 0.4) < 0.00001 &&
            fabs(color.blueComponent - 0.8) < 0.00001;
    }
    CHECK(valid, "selection_decorations_keep_bounded_rects_and_exact_explicit_color");
}

static void CheckPlatformSelection(CJGuiInternalComposableSceneNode *node, NSString *ordinary) {
    // A cross-node declaration must keep the same native selection colour as
    // the focused proxy. Supplying an application tint cannot establish that.
    for (NSString *name in @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]) {
        NSAppearance *appearance = [NSAppearance appearanceNamed:name];
        [appearance performAsCurrentDrawingAppearance:^{
            NSString *wire = ChangeField(SelectionWire(node.value, YES), 14, @"2");
            CjguiInternalRendererStatus admitted = CjguiComposableValidateSelectionBackgroundRuns(wire, node.value);
            CHECK(admitted == CJGUI_INTERNAL_RENDERER_OK, "platform_selection_colour_is_an_admitted_background_only_declaration");
            NSData *runs = CjguiComposableDecodeStyleRuns(wire);
            if (admitted != CJGUI_INTERNAL_RENDERER_OK || !runs) return;
            node.preparedTextLayout = CjguiPrepareTextNodeLayout(node, node.value, 1,
                CjguiComposableDecodeStyleRuns(ordinary), nil);
            CjguiPreparedTextNodeLayout *lease = node.preparedTextLayout;
            NSArray<NSDictionary *> *decorations = CjguiComposableDeclaredSelectionDecorations(node, runs);
            vector_float4 expected = CjguiMetalColorFromNSColor(NSColor.selectedTextBackgroundColor);
            BOOL same = decorations.count > 0;
            for (NSDictionary *entry in decorations) {
                vector_float4 actual = CjguiMetalColorFromNSColor(entry[@"color"]);
                for (NSUInteger c = 0; c < 4; c++) same &= fabs(actual[c] - expected[c]) < 0.000001;
            }
            CHECK(same, "single_proxy_and_cross_node_declarations_use_identical_native_colour_and_alpha");
            CHECK(node.preparedTextLayout == lease, "platform_selection_colour_never_rebuilds_glyph_layout");
            NSAttributedString *base = BuildAttributes(node, ordinary);
            NSAttributedString *selected = BuildAttributes(node, [ordinary stringByAppendingFormat:@";%@", wire]);
            CHECK(SameNonBackground(base, selected), "platform_selection_colour_cannot_change_text_style");
        }];
    }
}

int main(void) { @autoreleasepool {
    NSString *body = @"Bold italic code link 中🙂e\u0301 office אבג عربي tail\n第二行 👩‍💻";
    CJGuiInternalComposableSceneNode *node = SelectionNode(body);
    NSString *ordinary = OrdinaryRuns();
    NSAttributedString *base = BuildAttributes(node, ordinary);
    NSAttributedString *oldSelection = BuildAttributes(node,
        [ordinary stringByAppendingFormat:@";%@", SelectionWire(body, NO)]);
    NSAttributedString *selection = BuildAttributes(node,
        [ordinary stringByAppendingFormat:@";%@", SelectionWire(body, YES)]);
    NSString *decorated = [ordinary stringByAppendingFormat:@";%@", SelectionWire(body, YES)];
    CHECK(!SameNonBackground(base, oldSelection), "old_full_selection_run_overwrites_non_background_RED_control");
    CHECK(SameNonBackground(base, selection), "explicit_background_preserves_all_non_background_attributes");
    CHECK(![[base attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL]
        isEqual:[oldSelection attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL]],
        "old_full_selection_run_overwrites_bold_font");
    CHECK([[base attribute:NSFontAttributeName atIndex:12 effectiveRange:NULL]
        isEqual:[selection attribute:NSFontAttributeName atIndex:12 effectiveRange:NULL]],
        "explicit_background_preserves_inline_code_font");
    CHECK([[base attribute:NSForegroundColorAttributeName atIndex:17 effectiveRange:NULL]
        isEqual:[selection attribute:NSForegroundColorAttributeName atIndex:17 effectiveRange:NULL]],
        "explicit_background_preserves_link_foreground");
    CHECK([[base attribute:NSParagraphStyleAttributeName atIndex:22 effectiveRange:NULL]
        isEqual:[selection attribute:NSParagraphStyleAttributeName atIndex:22 effectiveRange:NULL]],
        "explicit_background_preserves_paragraph_policy");
    CHECK([[base attribute:NSObliquenessAttributeName atIndex:5 effectiveRange:NULL]
        isEqual:[selection attribute:NSObliquenessAttributeName atIndex:5 effectiveRange:NULL]],
        "explicit_background_preserves_obliqueness");
    CHECK(cjgui_internal_renderer_selection_background_version() == 2, "paired_native_capability_includes_platform_selection_colour");
    NSString *hostile = ChangeField(ChangeField(ChangeField(SelectionWire(body, YES), 2, @"999"), 4, @"3"), 5, @"nan");
    CHECK(SameNonBackground(base, BuildAttributes(node, [ordinary stringByAppendingFormat:@";%@", hostile])),
        "new_tag_placeholders_cannot_gain_font_foreground_or_oblique_authority");
    NSString *shrunk = [ordinary stringByAppendingFormat:@";%@", ChangeField(SelectionWire(body, YES), 1, @"4")];
    NSAttributedString *shrinkAttributes = BuildAttributes(node, shrunk);
    CHECK([[base attribute:NSBackgroundColorAttributeName atIndex:12 effectiveRange:NULL]
        isEqual:[shrinkAttributes attribute:NSBackgroundColorAttributeName atIndex:12 effectiveRange:NULL]] &&
        [shrinkAttributes attribute:NSBackgroundColorAttributeName atIndex:0 effectiveRange:NULL] != nil,
        "shrinking_selection_restores_code_background_and_retains_selected_background");
    CHECK([base isEqualToAttributedString:BuildAttributes(node, ordinary)], "clearing_selection_exactly_restores_base_and_ordinary_runs");
    CHECK([BuildAttributes(node, @"0:4:18:400:0:0:0:0:1") isEqualToAttributedString:
        BuildAttributes(node, @"0:4:18:400:0:0:0:0:1:0:0:0:0:0")], "legacy_9_and_ordinary_14_field_behavior_preserved");
    NSRect paintRect = CjguiComposableTextTextureRectForNode(node);
    node.styleRunsSignature = ordinary;
    NSString *ordinaryKey = CjguiComposableTextTextureKey(node, 1, 1, body, paintRect);
    node.styleRunsSignature = decorated;
    NSString *selectionKey = CjguiComposableTextTextureKey(node, 1, 1, body, paintRect);
    node.styleRunsSignature = shrunk;
    NSString *shrunkKey = CjguiComposableTextTextureKey(node, 1, 1, body, paintRect);
    node.styleRunsSignature = [ordinary stringByAppendingFormat:@";%@", ChangeField(SelectionWire(body, YES), 10, @"0.6")];
    NSString *recoloredKey = CjguiComposableTextTextureKey(node, 1, 1, body, paintRect);
    node.styleRunsSignature = [ordinary stringByAppendingFormat:@";%@", SelectionWire(body, NO)];
    NSString *fullRunKey = CjguiComposableTextTextureKey(node, 1, 1, body, paintRect);
    node.styleRunsSignature = ordinary;
    CHECK([ordinaryKey isEqualToString:selectionKey] && [selectionKey isEqualToString:shrunkKey] &&
        [selectionKey isEqualToString:recoloredKey] && ![selectionKey isEqualToString:fullRunKey] &&
        [ordinaryKey isEqualToString:CjguiComposableTextTextureKey(node, 1, 1, body, paintRect)],
        "selection_range_and_color_never_invalidate_glyph_texture_key");
    CheckLayout(node, ordinary, decorated);
    CheckDeclaredDecoration(node, ordinary, decorated);
    CheckActiveRestoration(node, ordinary, decorated, shrunk);
    CheckAdmission();
    CheckPlatformSelection(node, ordinary);
    fprintf(stderr, "selection_background_fixture checks=%d failures=%d\n", checks, failures);
    return failures ? 1 : 0;
} }
