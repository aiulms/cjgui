// 平台字素服务的仓颉侧判别：期望值来自本机 CFString 实测（2026-09-29 独立
// clang 探针，/tmp/grapheme_probe2），不是由被测函数生成。
package cjgui

import std.unittest.*
import std.unittest.testmacro.*

func clusterIs(range: ?(Int64, Int64), start: Int64, end: Int64): Bool {
    match (range) {
        case Some((s, e)) => return s == start && e == end
        case None => return false
    }
}

@Test
func testGraphemeClusterRangeComposedAccent(): Unit {
    // "e\u{0301}x"：e[0,1) 重音符[1,3) x[3,4)；e+重音符是一个字素 [0,3)。
    let text = "e\u{0301}x"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 0), 0, 3))
    // 簇内部（重音符的尾字节）仍指认同一簇。
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 2), 0, 3))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 3), 3, 4))
}

@Test
func testGraphemeClusterRangeZwjFamily(): Unit {
    // "a👨‍👩‍👧b"：a[0,1) 家庭[1,19) b[19,20)；整个 ZWJ 序列是一个字素。
    let text = "a👨‍👩‍👧b"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 1), 1, 19))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 10), 1, 19))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 0), 0, 1))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 19), 19, 20))
}

@Test
func testGraphemeClusterRangeFlagAndSkinTone(): Unit {
    // 旗帜 = 两个 regional indicator 一个簇；肤色 = emoji+修饰符一个簇。
    let flag = "x🇨🇳y"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(flag, 1), 1, 9))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(flag, 5), 1, 9))
    let skin = "p👍🏽q"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(skin, 1), 1, 9))
}

@Test
func testGraphemeClusterRangeMidScalarResolvesAndOutOfRangeRefuses(): Unit {
    // 标量内部的偏移归入其所属标量的簇（与 CF 对代理对内部索引的契约一致）；
    // 越界/空文本：None（无簇可名），不是钳位后的答案。
    let text = "e\u{0301}x"
    // 重音符标量 [1,3) 内部的两个偏移都指认同一个簇 [0,3)。
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 1), 0, 3), true)
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 2), 0, 3), true)
    @Assert(cjguiGraphemeClusterRangeUtf8(text, 3 + 1).isNone(), true)
    @Assert(cjguiGraphemeClusterRangeUtf8(text, -1).isNone(), true)
    @Assert(cjguiGraphemeClusterRangeUtf8("", 0).isNone(), true)
}

@Test
func testGraphemeClusterRangeCjkAndEmojiSurrogates(): Unit {
    // "中😀文"：中[0,3) 😀[3,7) 文[7,10)。
    let text = "中😀文"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 0), 0, 3))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 4), 3, 7))
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 7), 7, 10))
}

@Test
func testGraphemeClusterRangeCrlfIsOneEditUnit(): Unit {
    // "a\r\nb"：CR[1,2) LF[2,3)。平台把 CRLF 分成两簇；编辑配置合并为一个
    // 删除单元 [1,3)。
    let text = "a\r\nb"
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 1), 1, 3), true)
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 2), 1, 3), true)
}

@Test
func testGraphemeClusterRangeLongCjkMidClusterOffset(): Unit {
    // 长 CJK 文本（全 3 字节标量）的簇内偏移必须指认整簇：折行导航的落点
    // 对齐依赖此语义（产品实测反例：命中 343 未吸附到簇边界 342）。
    var text = ""
    var i: Int64 = 0
    while (i < 135) {
        text += "字"
        i += 1
    }
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 0), 0, 3), true)
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 1), 0, 3), true)
    @Assert(clusterIs(cjguiGraphemeClusterRangeUtf8(text, 2), 0, 3), true)
    // 中段簇内偏移（3k+1 / 3k+2）都指认自己的整簇。
    var probe: Int64 = 0
    while (probe < 400) {
        match (cjguiGraphemeClusterRangeUtf8(text, probe)) {
            case Some((start, end)) =>
                @Assert(start % 3, 0)
                @Assert(end - start, 3)
                @Assert(start <= probe && probe < end, true)
            case None => @Fail("long cjk: offset ${probe} must resolve")
        }
        probe += 7
    }
}
