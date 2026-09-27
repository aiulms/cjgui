package cjgui

// B2 光标几何回归:caret 矩形必须来自**已接受的排版**,并且覆盖两个真实缺陷 ——
// 空正文(没有任何字形)与行尾/换行后的位置(没有"下一个字形"可站)。二者此前都拿不到
// 矩形:空文本报 glyphCount==0,行尾被钳到最后一个字形的起点,于是光标画在最后一个字符
// **之前**,空段落看起来像没聚焦。
//
// 第二组用例覆盖 caret 的**资源归属**:caret 是表现几何,不是正文像素。此前 caret 坐标参与
// 正文纹理键并且被烤进位图,于是每次移动光标都重排/重光栅/重上传整段正文。现在 caret 走
// 既有装饰绘制链(shape batch,画在正文纹理之后),断言为:声明与移动 caret 时 raster/upload
// 计数不动、像素确实跟着移动,而正文内容变化时计数必须前进(否则计数本身是死的,前两条
// 断言没有意义)。
//
// 这个探针不点击、不合成按键:它只把正文放进正常窗口、让框架绘制,然后按 nodeId +
// 显示字节查询框架公开的光标矩形 API 并读回 drawable 像素。失败即返回非零。

foreign {
    // Cumulative text-work counters (TESTING-only). Raster is the offscreen bitmap +
    // normalization pass; upload is the texture replaceRegion pass. Neither may advance
    // while only the owner's caret declaration moves.
    func cjgui_internal_renderer_test_composable_text_work_stats(
        session: UInt64, outRasterCount: CPointer<UInt64>, outRasterBytes: CPointer<UInt64>,
        outRasterMicros: CPointer<UInt64>, outUploadCount: CPointer<UInt64>, outUploadBytes: CPointer<UInt64>,
        outUploadMicros: CPointer<UInt64>
    ): Int32
    // Drawable readback: request a point, present a frame, then read the captured pixel.
    func cjgui_internal_renderer_test_request_composable_drawable_pixel(
        session: UInt64, pointX: UInt32, pointY: UInt32
    ): Int32
    func cjgui_internal_renderer_test_composable_drawable_pixel(
        session: UInt64, outBlue: CPointer<UInt8>, outGreen: CPointer<UInt8>,
        outRed: CPointer<UInt8>, outAlpha: CPointer<UInt8>
    ): Int32
}

private func caretRect(window: CjguiComposableUiWindow, nodeId: Int64,
    displayByte: Int64): ?Array<Float64> {
    return cjguiTextGeometryCaretRect(window.testSessionToken(), nodeId, displayByte, 1.5)
}

private func caretReason(window: CjguiComposableUiWindow, nodeId: Int64,
    displayByte: Int64): String {
    return cjguiTextGeometryReasonForStatus(
        cjguiTextGeometryCaretStatus(window.testSessionToken(), nodeId, displayByte, 1.5))
}

/// 一个正文节点一族:值只由场景给出,几何只由框架的 accepted 排版给出。
private class CaretGeometryController <: CjguiComposableUiController {
    private var sceneRevision: Int64 = 1

    public func uiSceneVersion(): Int64 {
        return this.sceneRevision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "caret-geometry-root",
            CjguiComposableUiStyle(padding: 12, gap: 10))
        // 11 空正文;12 行尾;13 以换行结尾(光标应落到第二条空行);14 非 ASCII 行尾。
        root.add(cjguiComposableText(11, "caret-empty", "",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 16.0)))
        root.add(cjguiComposableText(12, "caret-ascii", "abc",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 16.0)))
        root.add(cjguiComposableText(13, "caret-newline", "abc\n",
            CjguiComposableUiStyle(fixedHeight: 56, fontSize: 16.0)))
        root.add(cjguiComposableText(14, "caret-cjk", "中",
            CjguiComposableUiStyle(fixedHeight: 28, fontSize: 16.0)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

/// 单个正文节点、白底红字、根 padding 为 0:节点原点就是窗口原点,于是 accepted 排版给出的
/// 光标矩形可以直接当作 drawable 点坐标采样。正文 "a     b" 在两个采样位置之间留出一段没有
/// 字形的空白,像素差异只可能来自 caret 装饰本身。
private class CaretReuseController <: CjguiComposableUiController {
    private var revision: Int64 = 1
    private var body: String = "a     b"
    /// 交替根容器底色,逼出一次真实的 present 回合。根容器不是文本节点,它的填充不参与
    /// 正文纹理键 —— 于是"确实画了一帧"与"正文资源被复用"同时成立,而不是因为根本没画
    /// 才没有计数前进。正文节点自带白底,采样点落在它内部,不受根底色影响。
    private var frameTint: Float64 = 0.92

    public func setBody(value: String): Unit {
        this.body = value
        this.revision += 1
    }

    /// 推进代次并改变根底色:一次真实的绘制回合,但正文内容/样式/裁剪都不变。
    public func requestDrawableFrame(): Unit {
        this.frameTint = if (this.frameTint > 0.91) { 0.88 } else { 0.92 }
        this.revision += 1
    }

    public func uiSceneVersion(): Int64 {
        return this.revision
    }

    public func buildUi(): CjguiComposableUiNode {
        let root = cjguiComposableVertical(1, "caret-reuse-root",
            CjguiComposableUiStyle(background: CjguiComposableUiColor(this.frameTint, this.frameTint,
                this.frameTint, 1.0), fixedWidth: 240, fixedHeight: 60))
        root.add(cjguiComposableText(21, "caret-reuse-body", this.body,
            CjguiComposableUiStyle(background: CjguiComposableUiColor(1.0, 1.0, 1.0, 1.0),
                textColor: CjguiComposableUiColor(0.85, 0.10, 0.10, 1.0),
                fixedWidth: 240, fixedHeight: 28, fontSize: 16.0)))
        return root
    }

    public func applyUiEvent(event: CjguiComposableUiEvent): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func rejectUiEvent(eventKind: Int64, nodeId: Int64): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(false)
    }

    public func requestWindowClose(): CjguiComposableUiDispatchResult {
        return CjguiComposableUiDispatchResult(true, shouldClose: true)
    }
}

private func settle(window: CjguiComposableUiWindow): Bool {
    var i: Int64 = 0
    while (i < 12) {
        let _ = window.pump(4u32)
        i += 1
    }
    return window.isOpen()
}

/// 一次断言:名字、期望、实际都进日志,失败原因具名而不是只报 false。
private func report(name: String, ok: Bool, detail: String): Bool {
    println("CJGUI_CARET_CASE ${name} passed=${ok} ${detail}")
    return ok
}

private func describe(rect: ?Array<Float64>): String {
    return match (rect) {
        case Some(v) => "x=${v[0]} y=${v[1]} w=${v[2]} h=${v[3]}"
        case None => "unavailable"
    }
}

private func xOf(rect: ?Array<Float64>): Float64 {
    return match (rect) {
        case Some(v) => v[0]
        case None => -1.0
    }
}

private func yOf(rect: ?Array<Float64>): Float64 {
    return match (rect) {
        case Some(v) => v[1]
        case None => -1.0
    }
}

private func heightOf(rect: ?Array<Float64>): Float64 {
    return match (rect) {
        case Some(v) => v[3]
        case None => 0.0
    }
}

private func present(rect: ?Array<Float64>): Bool {
    return match (rect) {
        case Some(_) => true
        case None => false
    }
}

private func distance(a: Float64, b: Float64): Float64 {
    let d = a - b
    return if (d < 0.0) { -d } else { d }
}

private class TextWorkSnapshot {
    let status: Int32
    let rasterCount: UInt64
    let rasterBytes: UInt64
    let rasterMicros: UInt64
    let uploadCount: UInt64
    let uploadBytes: UInt64
    let uploadMicros: UInt64

    init(status: Int32, rasterCount: UInt64, rasterBytes: UInt64, rasterMicros: UInt64,
        uploadCount: UInt64, uploadBytes: UInt64, uploadMicros: UInt64) {
        this.status = status
        this.rasterCount = rasterCount
        this.rasterBytes = rasterBytes
        this.rasterMicros = rasterMicros
        this.uploadCount = uploadCount
        this.uploadBytes = uploadBytes
        this.uploadMicros = uploadMicros
    }

    public func describe(): String {
        return "status=${this.status} raster=${this.rasterCount}/${this.rasterBytes}B/${this.rasterMicros}us " +
            "upload=${this.uploadCount}/${this.uploadBytes}B/${this.uploadMicros}us"
    }
}

private func textWork(window: CjguiComposableUiWindow): TextWorkSnapshot {
    var rasterCount: UInt64 = 0u64
    var rasterBytes: UInt64 = 0u64
    var rasterMicros: UInt64 = 0u64
    var uploadCount: UInt64 = 0u64
    var uploadBytes: UInt64 = 0u64
    var uploadMicros: UInt64 = 0u64
    let status = unsafe { cjgui_internal_renderer_test_composable_text_work_stats(
        window.testSessionToken(), inout rasterCount, inout rasterBytes, inout rasterMicros,
        inout uploadCount, inout uploadBytes, inout uploadMicros) }
    return TextWorkSnapshot(status, rasterCount, rasterBytes, rasterMicros, uploadCount, uploadBytes, uploadMicros)
}

/// 六个计数全部相等才算"没有重做正文工作":只比 rasterCount 会漏掉同一次重上传。
private func sameWork(before: TextWorkSnapshot, after: TextWorkSnapshot): Bool {
    return before.status == CJGUI_INTERNAL_RENDERER_OK && after.status == CJGUI_INTERNAL_RENDERER_OK &&
        before.rasterCount == after.rasterCount && before.rasterBytes == after.rasterBytes &&
        before.rasterMicros == after.rasterMicros && before.uploadCount == after.uploadCount &&
        before.uploadBytes == after.uploadBytes && before.uploadMicros == after.uploadMicros
}

/// 一次 drawable 读回:请求点 → 逼出一帧 → 读取。两个状态分别记录,读不到时能区分
/// "请求被拒(点越界/会话失效)"与"这一帧根本没有被提交"。
private class PixelSample {
    let requestStatus: Int32
    let readStatus: Int32
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(requestStatus: Int32, readStatus: Int32, red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        this.requestStatus = requestStatus
        this.readStatus = readStatus
        this.red = red
        this.green = green
        this.blue = blue
        this.alpha = alpha
    }

    public func captured(): Bool {
        return this.requestStatus == CJGUI_INTERNAL_RENDERER_OK && this.readStatus == CJGUI_INTERNAL_RENDERER_OK
    }

    public func describe(): String {
        return "request=${this.requestStatus} read=${this.readStatus} rgb=${this.red},${this.green},${this.blue} " +
            "a=${this.alpha}"
    }
}

private func capturePixel(window: CjguiComposableUiWindow, controller: CaretReuseController,
    x: UInt32, y: UInt32): PixelSample {
    let session = window.testSessionToken()
    let request = unsafe { cjgui_internal_renderer_test_request_composable_drawable_pixel(session, x, y) }
    controller.requestDrawableFrame()
    let _ = window.refresh()
    let _ = window.pump(4u32)
    var blue: UInt8 = 0u8
    var green: UInt8 = 0u8
    var red: UInt8 = 0u8
    var alpha: UInt8 = 0u8
    let result = unsafe {
        cjgui_internal_renderer_test_composable_drawable_pixel(session, inout blue, inout green, inout red,
            inout alpha)
    }
    return PixelSample(request, result, red, green, blue, alpha)
}

private func samePixel(left: PixelSample, right: PixelSample): Bool {
    return left.captured() && right.captured() && left.red == right.red && left.green == right.green &&
        left.blue == right.blue && left.alpha == right.alpha
}

/// 节点声明的正文色是 (0.85, 0.10, 0.10):caret 装饰必须是不透明的正文色。
private func isCaretColour(pixel: PixelSample): Bool {
    return pixel.captured() && pixel.red > 150u8 && pixel.green < 100u8 && pixel.blue < 100u8
}

/// 白底:该点没有 caret 也没有字形。
private func isBackground(pixel: PixelSample): Bool {
    return pixel.captured() && pixel.red > 240u8 && pixel.green > 240u8 && pixel.blue > 240u8
}

private func pointOf(rect: ?Array<Float64>): UInt32 {
    // 装饰矩形按 floor(origin)/ceil(size) 落到像素,所以取整后的原点一定在条内。
    return UInt32(Int64(xOf(rect)))
}

private func midHeightOf(rect: ?Array<Float64>): UInt32 {
    return UInt32(Int64(yOf(rect) + heightOf(rect) / 2.0))
}

private func runCaretGeometryProbe(): Bool {
    let controller = CaretGeometryController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_CARET_RESULT start_failed=true")
        return false
    }
    if (!settle(window)) {
        println("CJGUI_CARET_RESULT settle_failed=true")
        window.close()
        return false
    }
    var passed = true

    // 1. 空正文:必须给出可信的插入点(高度>0),而不是"无字形⇒无矩形"。
    let empty = caretRect(window, 11, 0)
    passed = report("empty_value_has_caret", present(empty) && heightOf(empty) > 0.0,
        "${describe(empty)} reason=[${caretReason(window, 11, 0)}]") && passed

    // 2. 行尾:值 "abc",byte 3 必须严格在 byte 2 之后。钳到最后一字形起点时二者相等。
    let asciiStart = caretRect(window, 12, 0)
    let asciiMid = caretRect(window, 12, 2)
    let asciiEnd = caretRect(window, 12, 3)
    passed = report("end_of_value_caret_is_after_last_glyph",
        present(asciiStart) && present(asciiMid) && present(asciiEnd) &&
            xOf(asciiEnd) > xOf(asciiMid) + 0.5 && xOf(asciiMid) > xOf(asciiStart) + 0.5,
        "start=${describe(asciiStart)} mid=${describe(asciiMid)} end=${describe(asciiEnd)} " +
            "reason=[${caretReason(window, 12, 3)}]") && passed

    // 3. 换行后:值 "abc\n",byte 4 是文档末尾,光标必须落在**第二条行**的行首。
    let lineOne = caretRect(window, 13, 0)
    let afterNewline = caretRect(window, 13, 4)
    passed = report("caret_after_trailing_newline_uses_extra_line",
        present(lineOne) && present(afterNewline) && yOf(afterNewline) > yOf(lineOne) + 1.0 &&
            distance(xOf(afterNewline), xOf(lineOne)) < 1.0,
        "first=${describe(lineOne)} after=${describe(afterNewline)} " +
            "reason=[${caretReason(window, 13, 4)}]") && passed

    // 4. 非 ASCII 行尾:displayByte 是 UTF-8 偏移,必须换算成 UTF-16 索引再取字形;
    //    按字节当作字符会使范围越出排版。
    let cjkStart = caretRect(window, 14, 0)
    let cjkEnd = caretRect(window, 14, 3)
    passed = report("cjk_end_advances_by_glyph_width",
        present(cjkStart) && present(cjkEnd) && xOf(cjkEnd) > xOf(cjkStart) + 8.0,
        "start=${describe(cjkStart)} end=${describe(cjkEnd)} " +
            "reason=[${caretReason(window, 14, 3)}]") && passed

    // 5. 越出正文长度的请求不能被静默折算成一个看起来合法的位置。
    let beyond = caretRect(window, 12, 64)
    passed = report("beyond_value_still_answers_within_layout",
        present(beyond) && xOf(beyond) >= xOf(asciiEnd) - 0.5,
        "beyond=${describe(beyond)} end=${describe(asciiEnd)} " +
            "reason=[${caretReason(window, 12, 64)}]") && passed

    let _ = window.pump(4u32)
    window.close()
    println("CJGUI_CARET_SUMMARY passed=${passed}")
    return passed
}

private func runCaretReuseProbe(): Bool {
    let controller = CaretReuseController()
    let window = CjguiComposableUiWindow(controller)
    if (!window.start()) {
        println("CJGUI_CARET_REUSE_RESULT start_failed=true")
        return false
    }
    if (!settle(window)) {
        println("CJGUI_CARET_REUSE_RESULT settle_failed=true")
        window.close()
        return false
    }
    var passed = true

    // 两个 caret 位置都取自框架的 accepted 排版(产品也是这么声明的):byte 1 紧跟 'a',
    // byte 6 紧跟五个空格、在 'b' 之前。二者之间没有字形,像素差异只能来自 caret 装饰。
    let first = caretRect(window, 21, 1)
    let second = caretRect(window, 21, 6)
    if (!present(first) || !present(second)) {
        println("CJGUI_CARET_REUSE_RESULT geometry_unavailable first=[${describe(first)}] " +
            "second=[${describe(second)}] reason=[${caretReason(window, 21, 1)}]")
        window.close()
        return false
    }
    let ax = pointOf(first)
    let bx = pointOf(second)
    let ay = midHeightOf(first)
    let by = midHeightOf(second)
    if (ax == bx || ay != by) {
        println("CJGUI_CARET_REUSE_RESULT sample_points_degenerate ax=${ax} bx=${bx} ay=${ay} by=${by}")
        window.close()
        return false
    }

    // 基线:没有任何 caret 声明时,两个采样点都必须是白底。
    let absent = window.declareInputCaretBarAbsent()
    let bareA = capturePixel(window, controller, ax, ay)
    let bareB = capturePixel(window, controller, bx, by)
    passed = report("baseline_points_are_empty_body_background",
        absent == CJGUI_INTERNAL_RENDERER_OK && isBackground(bareA) && isBackground(bareB),
        "a=[${bareA.describe()}] b=[${bareB.describe()}]") && passed

    // 6. 声明 caret:正文内容/样式没变,raster 与 upload 的六个计数一个都不能动。
    let before = textWork(window)
    let declareFirst = window.declareInputCaretBar(21, xOf(first), yOf(first), 1.5, heightOf(first))
    let caretA = capturePixel(window, controller, ax, ay)
    let afterFirst = textWork(window)
    passed = report("caret_declaration_does_not_rasterize_body",
        declareFirst == CJGUI_INTERNAL_RENDERER_OK && sameWork(before, afterFirst),
        "status=${declareFirst} before=[${before.describe()}] after=[${afterFirst.describe()}]") && passed

    // 7. 声明确实画出来了:该点变成不透明的正文色,而不是留在白底。
    passed = report("declared_caret_bar_is_drawn_in_node_text_colour",
        isCaretColour(caretA) && !isCaretColour(bareA),
        "bare=[${bareA.describe()}] caret=[${caretA.describe()}]") && passed

    // 8. 移动声明:计数仍然不动,旧点回到白底,新点变成 caret —— 装饰几何变了,正文资源复用。
    let declareSecond = window.declareInputCaretBar(21, xOf(second), yOf(second), 1.5, heightOf(second))
    let movedA = capturePixel(window, controller, ax, ay)
    let movedB = capturePixel(window, controller, bx, by)
    let afterSecond = textWork(window)
    passed = report("caret_move_reuses_body_texture",
        declareSecond == CJGUI_INTERNAL_RENDERER_OK && sameWork(before, afterSecond),
        "status=${declareSecond} before=[${before.describe()}] after=[${afterSecond.describe()}]") && passed
    passed = report("caret_move_moves_only_decoration_pixels",
        samePixel(movedA, bareA) && isCaretColour(movedB) && !samePixel(movedB, bareB),
        "oldPoint=[${movedA.describe()}] bareOld=[${bareA.describe()}] " +
            "newPoint=[${movedB.describe()}] bareNew=[${bareB.describe()}]") && passed

    // 9. 反向对照:正文真的变了,计数必须前进。否则上面的"没动"只是计数器坏了。
    controller.setBody("a     bc")
    let _ = window.refresh()
    let _ = settle(window)
    let afterEdit = textWork(window)
    passed = report("body_edit_rasterizes_and_uploads_again",
        afterEdit.rasterCount > afterSecond.rasterCount && afterEdit.uploadCount > afterSecond.uploadCount,
        "before=[${afterSecond.describe()}] after=[${afterEdit.describe()}]") && passed

    let _ = window.pump(4u32)
    window.close()
    println("CJGUI_CARET_REUSE_SUMMARY passed=${passed}")
    return passed
}

main(args: Array<String>): Int64 {
    let geometry = runCaretGeometryProbe()
    let reuse = runCaretReuseProbe()
    if (geometry && reuse) {
        return 0
    }
    return 91
}
