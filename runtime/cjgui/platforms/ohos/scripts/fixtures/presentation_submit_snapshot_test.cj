package cjgui
import std.unittest.*
import std.unittest.testmacro.*

func frozenAB(): CjguiPresentationHitTicket {
    return CjguiPresentationHitTicket(25, 1, "AB", 7, 9801, 3, 11u64, "AB", 2)
}

func frozenEA(): CjguiPresentationHitTicket {
    return CjguiPresentationHitTicket(25, 2, "éA", 7, 9801, 3, 11u64, "éA", 1)
}

@Test
func legalAsciiInsertAdoptsExactCaret(): Unit {
    let r = verifyPresentationHitTicket(frozenAB(), "AB", 7, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 0)
    @Assert(r[1], 1)
}

@Test
func multiByteDisplayConvertsOnFrozenText(): Unit {
    // é = 2 字节 1 单位：byte2 落在第 1 位（指导 éA 反例的合法面）。
    let r = verifyPresentationHitTicket(frozenEA(), "éA", 7, 9801, 3, 11u64, "éA", 1)
    @Assert(r[0], 0)
    @Assert(r[1], 1)
    // CJK 3 字节 1 单位；emoji 4 字节 2 单位。
    let c = CjguiPresentationHitTicket(25, 3, "文A", 7, 9801, 3, 11u64, "文A", 1)
    @Assert(verifyPresentationHitTicket(c, "文A", 7, 9801, 3, 11u64, "文A", 1)[1], 1)
    let m = CjguiPresentationHitTicket(25, 4, "😀A", 7, 9801, 3, 11u64, "😀A", 1)
    @Assert(verifyPresentationHitTicket(m, "😀A", 7, 9801, 3, 11u64, "😀A", 1)[1], 2)
}

@Test
func displayAdvancedRefusesStaleDisplayCoordinate(): Unit {
    // 当前显示 D 已变（éA→AB）：冻结 byte2 若换算会错位，必须整体拒绝。
    let r = verifyPresentationHitTicket(frozenEA(), "AB", 7, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 4)
    @Assert(r[1], -1)
}

@Test
func mirrorAdvancedRefusesOldDisplay(): Unit {
    // 指导原样复现形状：显示 D 仍为 éA，会话 M 已推进 AB/v2。
    // 旧 byte2→UTF16 1 若登记到 v2 即错写，必须拒 5，选区与正文零写入。
    let r = verifyPresentationHitTicket(frozenEA(), "éA", 7, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 5)
    @Assert(r[1], -1)
}

@Test
func sameBytesNewMirrorVersionRefuses(): Unit {
    // 同字节新版本：D 与 M 正文皆 éA，但 M 版本 1→3，票据关联已不可证。
    let r = verifyPresentationHitTicket(frozenEA(), "éA", 7, 9801, 3, 11u64, "éA", 3)
    @Assert(r[0], 6)
    @Assert(r[1], -1)
}

@Test
func sceneAdvancedRefusesEvenWhenTextAlsoChanged(): Unit {
    // 场景先判：外部改版推进场景（同改正文）→ 3，不是把旧坐标将就着用。
    let r = verifyPresentationHitTicket(frozenEA(), "AB", 9, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 3)
    @Assert(r[1], -1)
}

@Test
func rebindToOtherResourceRefuses(): Unit {
    let r = verifyPresentationHitTicket(frozenAB(), "AB", 7, 7700, 3, 11u64, "AB", 2)
    @Assert(r[0], 1)
    @Assert(r[1], -1)
}

@Test
func abaBindingChangeRefusesDespiteSameText(): Unit {
    // 同节点同正文同场景同镜像，但绑定代已换（解绑→重绑）：旧票据不得复活。
    let r = verifyPresentationHitTicket(frozenAB(), "AB", 7, 9801, 3, 12u64, "AB", 2)
    @Assert(r[0], 2)
    @Assert(r[1], -1)
}

@Test
func geometryNewFrameRefuses(): Unit {
    // 纯几何新帧：正文/身份/绑定/镜像全同，场景已走 → 3，调用方重冻重查。
    let r = verifyPresentationHitTicket(frozenAB(), "AB", 8, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 3)
    @Assert(r[1], -1)
}

@Test
func offsetPastEndClampsToFullLength(): Unit {
    let e = CjguiPresentationHitTicket(25, 99, "AB", 7, 9801, 3, 11u64, "AB", 2)
    let r = verifyPresentationHitTicket(e, "AB", 7, 9801, 3, 11u64, "AB", 2)
    @Assert(r[0], 0)
    @Assert(r[1], 2)
}
