// 验证专用控制接缝（**只在显式测试构建中被编入**）。
//
// 隔离方式（B1 返工）：
//   - 本文件所有声明都由条件编译 `@When[cjgui_transport_verify == "on"]` 门控。
//     该 cfg 由 sync_platform.sh 生成 transport 模块的 cjpm.toml 时写入**字面值**：
//       普通产物  → cjgui_transport_verify=off（本文件编译为**空**，@C 符号不存在）
//       测试产物  → cjgui_transport_verify=on
//     因为 cjpm.toml 是脚本生成的，不存在「cfg 键未定义 → 编译报错」的风险。
//   - 普通产物因此既没有 @C 符号 cjgui_ohos_transport_verify_install，也没有任何
//     控制帧解析代码。宿主桥 dlsym 取不到符号 → 永不注册 → 基础文件里的
//     VERIFY_CONTROL 恒为 None → 认领闸门与整帧解析都不可达。
//     这不是「用注释禁用」，而是**没有编入**。
//   - 测试构建也要求本轮一次性凭据：注册时生成 token 并写入 hilog，验证脚本从
//     hilog 读回后才可能切换认领开关。凭据不符的控制帧被显式拒绝，不会被当作业务帧。
//
// 目的（环境约束）：模拟器 hdc shell 是 uid=2000(shell)，kill -STOP 应用进程被拒且
// 设备无 su，无法从外部暂停 owner 认领。要复现「owner 停止消费时票据到期取消、额度
// 正确释放、恢复后能再次应用」与「暂停认领后直接调用生产 stop」，必须由本包自己提供
// 可复位的驱动接缝。所有 OP 都只调用**生产入口**（VerificationSeam → 生产
// requestStop/awaitClosed/snapshotCounters），不复制一份平行实现。

package cjgui_ohos_transport

import std.sync.*
import std.time.*
import std.collection.ArrayList
import std.convert.*

// 第九次复核 C/D：替身状态/放行/退役的**宿主直连通道**——不依赖 owner
// serveOnce 转发（owner 阻塞于 host.start 首帧或退出时仍可达）。

// 第九次复核 C/D：替身状态/放行/退役的**宿主直连通道**——不依赖 owner
// serveOnce 转发（owner 阻塞于 host.start 首帧或退出时仍可达）。
foreign func cjgui_ohos_test_stub_release(): Int32
foreign func cjgui_ohos_test_stub_lease_retire(gen: Int64): Int32
foreign func cjgui_ohos_test_stub_state(): Int64
foreign func cjgui_ohos_test_stub_counts(gen: Int64): Int64
foreign func cjgui_ohos_test_platform_call_packed(): Int64

// 控制协议常量（整帧严格匹配，不做子串搜索）。
@When[cjgui_transport_verify == "on"]
let CONTROL_PROTOCOL = "CONTROL CJGUI_VERIFY/1"

var BOOT_GENERATION: Int64 = 0
let TAG_VERIFY = "CjguiTransportVerify"
// close+boot 线程的落点。SETTLE 帧本身**不能**内联做 Closed 确认：控制处理器
// 就跑在本帧自己的连接 worker 里，响应写回前连接计数不可能归零，同步
// awaitClosed 恒为假。所以 SETTLE 只分离一个线程：等本帧连接终结 → 生产
// awaitClosed → 生产 boot，结果写进下面这组变量，验证方经新 listener 的
// BOOT_STATE 读取（新实例上旧结果仍可读，CLOSED 证据因此不丢）。
@When[cjgui_transport_verify == "on"]
let BOOT_RESULT_LOCK = Mutex()
@When[cjgui_transport_verify == "on"]
var BOOT_PENDING = false
@When[cjgui_transport_verify == "on"]
var BOOT_CLOSED = false
@When[cjgui_transport_verify == "on"]
var BOOT_BOOTED = false
@When[cjgui_transport_verify == "on"]
var BOOT_NEW_ID = ""
// 本轮一次性凭据。每次注册重新生成：只有读到本轮 hilog 的验证者才可能切换闸门。
@When[cjgui_transport_verify == "on"]
var VERIFY_TOKEN = ""

@When[cjgui_transport_verify == "on"]
let VERIFY_INSTALL_COUNT = AtomicInt64(0)

// 进程内单调基准：MonoTime 之间可相减得到 Duration，用它作为凭据的时间成分
// （std.time 的 monoNow() 不是公开 API，这里不用）。
@When[cjgui_transport_verify == "on"]
let VERIFY_EPOCH = MonoTime.now()

@When[cjgui_transport_verify == "on"]
let HEX_DIGITS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"]

@When[cjgui_transport_verify == "on"]
func verifyHexOf(value0: Int64): String {
    var value = value0
    if (value < 0) {
        value = -value
    }
    if (value == 0) {
        return "0"
    }
    var out = ""
    while (value > 0) {
        out += HEX_DIGITS[Int64(value % 16)]
        value = value / 16
    }
    return out
}

@When[cjgui_transport_verify == "on"]
func newVerifyToken(): String {
    // 不做密码学保证：目的是「限制在本轮验证者」，即凭据随注册轮次变化且不写死在
    // 仓库里。用单调时钟（相对本进程模块载入点）+ 安装计数混合，避免同一进程内
    // 两次注册得到同值。
    let sinceLoad = (MonoTime.now() - VERIFY_EPOCH).toNanoseconds()
    var v = sinceLoad ^ (VERIFY_INSTALL_COUNT.fetchAdd(1) * 2654435761)
    if (v < 0) {
        v = -v
    }
    return "t" + verifyHexOf(v)
}

// 行切分：不依赖 String.split 的具体重载，直接按字节切（控制帧只含 ASCII）。
@When[cjgui_transport_verify == "on"]
func verifySplitLines(text: String): Array<String> {
    let bytes = text.toArray()
    let lines = ArrayList<String>()
    var start: Int64 = 0
    var i: Int64 = 0
    while (i < Int64(bytes.size)) {
        if (bytes[i] == 10) {
            lines.add(String.fromUtf8(bytes[start..i]))
            start = i + 1
        }
        i += 1
    }
    lines.add(String.fromUtf8(bytes[start..Int64(bytes.size)]))
    return lines.toArray()
}

// 前缀剥离：不依赖 String 的区间下标，按字节取。
@When[cjgui_transport_verify == "on"]
func verifyStripPrefix(line: String, prefix: String): String {
    if (!line.startsWith(prefix)) {
        return ""
    }
    let bytes = line.toArray()
    let start = Int64(prefix.size)
    if (start >= Int64(bytes.size)) {
        return ""
    }
    return String.fromUtf8(bytes[start..Int64(bytes.size)])
}

@When[cjgui_transport_verify == "on"]
func verifyErrorFrame(reason: String): String {
    return CONTROL_PROTOCOL + "\nKIND ERROR\nERROR " + reason + "\nEND"
}

@When[cjgui_transport_verify == "on"]
func verifyOkFrame(op: String, detail: String): String {
    return CONTROL_PROTOCOL + "\nKIND OK\nOP " + op + "\n" + detail + "\nEND"
}

// SETTLE 共享实现：停（若未停）→ 观察排队取消收敛 → 分离 close+boot 线程。
// holdBootMs>0（SETTLE_HOLD）时，close+boot 线程在 Closed 确认与 boot 之间
// 保持关闭窗口——让宿主侧**确定性地**观察到「listener 退出后连接被拒」；
// 这只拉长观察窗，不伪造任何状态（拒绝行为就是 listener-exited 的真实语义）。
// 普通 SETTLE 为 0：生产时序不变，窗口亚毫秒（fport 转发延迟会盖过它）。
@When[cjgui_transport_verify == "on"]
func runSettleWithBoot(frameOp: String, holdBootMs: Int64): String {
    // 停 + 观察收敛。必须与 STOP 在**同一帧**里完成：requestStop 之后
    // listener 会退出，新连接一律被拒，因此不可能再开一条控制连接来读计数。
    // 判据（验证侧口径，不改生产语义）：队列/字节/在途归零，且除本调用自身
    // 这条连接外没有别的连接。lifecycle 停在 Closing(1) 是预期的——它要等
    // 包括本调用在内的所有连接结束才会置 Closed(2)，那个判定属于生产
    // awaitClosed，不在本帧内伪造。
    let (q0, _b0, _c0, _f0, l0) = VerificationSeam.counters()
    if (l0 == 0) {
        VerificationSeam.requestProductionStop()
    }
    var settled = false
    var q: Int64 = 0
    var b: Int64 = 0
    var c: Int64 = 0
    var f: Int64 = 0
    var l: Int64 = 0
    var i: Int64 = 0
    while (i < 200) {
        let (qq, bb, cc, ff, ll) = VerificationSeam.counters()
        q = qq
        b = bb
        c = cc
        f = ff
        l = ll
        if (qq == 0 && ff == 0 && bb == 0 && cc <= 1) {
            settled = true
            break
        }
        sleep(Duration.millisecond * 10)
        i += 1
    }
    // A3：关闭确认 + 同进程 BOOT 不能在本帧内联——本帧自己的连接在响应
    // 写回前一直计入连接数，同步 awaitClosed 恒为假（实测假绿教训）。
    // 分离线程：等本帧连接终结（handleClient 写完响应即关闭并递减）→
    // 生产 awaitClosed → 生产 start+listen（新 generation 身份）。结果
    // 写入 BOOT_* 变量，由验证方经新 listener 的 BOOT_STATE 读取。
    BOOT_RESULT_LOCK.lock()
    BOOT_PENDING = true
    BOOT_RESULT_LOCK.unlock()
    spawn {
        var j: Int64 = 0
        while (j < 300) {
            let (_qa, _ba, ca, _fa, _la) = VerificationSeam.counters()
            if (ca == 0) { break }
            sleep(Duration.millisecond * 10)
            j += 1
        }
        let closedR = VerificationSeam.awaitProductionClosed(2000)
        var bootedR = false
        var newIdR = ""
        if (closedR) {
            if (holdBootMs > 0) {
                sleep(Duration.millisecond * holdBootMs)
            }
            let oldIdR = VerificationSeam.identity()
            newIdR = VerificationSeam.requestProductionBoot(g_nextBootGeneration(), 7856)
            bootedR = newIdR != "" && newIdR != oldIdR
            if (!bootedR) {
                cjguiOhosWarn("CjguiTransportVerify", "close+boot: booted=false oldId=" + oldIdR +
                    " newId=" + newIdR)
            }
        } else {
            cjguiOhosWarn("CjguiTransportVerify", "close+boot: awaitClosed=false (conns/queue not drained)")
        }
        BOOT_RESULT_LOCK.lock()
        BOOT_CLOSED = closedR
        BOOT_BOOTED = bootedR
        BOOT_NEW_ID = newIdR
        BOOT_PENDING = false
        BOOT_RESULT_LOCK.unlock()
        cjguiOhosInfo("CjguiTransportVerify", "close+boot done: closed=" + closedR.toString() +
            " booted=" + bootedR.toString() + " identity=" + newIdR)
    }
    let identity = VerificationSeam.identity()
    return verifyOkFrame(frameOp, "SETTLED " + settled.toString() + "\nQUEUED " + q.toString() +
        "\nBYTES " + b.toString() + "\nCONNS " + c.toString() +
        "\nINFLIGHT " + f.toString() + "\nLIFECYCLE " + l.toString() +
        "\nBOOT_PENDING true\nBOOT_HOLD " + holdBootMs.toString() +
        "\nOLD_IDENTITY " + identity)
}

@When[cjgui_transport_verify == "on"]
func handleVerifyControl(payload: String): ?String {
    let lines = verifySplitLines(payload)
    // 只有首行**精确**等于协议名时才进入控制协议解析；其它任何负载（含合法业务帧，
    // 哪怕字段值里恰好含 "PAUSE_CLAIM" 或整串协议名）都返回 None，交回业务路径。
    if (lines.size < 1 || lines[0] != CONTROL_PROTOCOL) {
        return None
    }
    // 控制协议要求恰好 4 行：CONTROL / TOKEN / OP / END。
    if (lines.size != 4) {
        return verifyErrorFrame("verify_malformed_frame")
    }
    if (lines[3] != "END") {
        return verifyErrorFrame("verify_malformed_frame")
    }
    let token = verifyStripPrefix(lines[1], "TOKEN ")
    if (token.size == 0) {
        return verifyErrorFrame("verify_missing_token")
    }
    if (token != VERIFY_TOKEN) {
        // 凭据不符：这就是「错误凭据」反例。不切换任何状态，也不落到业务路径。
        cjguiOhosWarn("CjguiTransportVerify", "verify control rejected: token mismatch")
        return verifyErrorFrame("verify_token_mismatch")
    }
    let op = verifyStripPrefix(lines[2], "OP ")
    if (op.size == 0) {
        return verifyErrorFrame("verify_malformed_frame")
    }
    // D 夹具：TOUCH_<action>_<x>_<y> 透传为 owner 闸门命令（参数化命令名）。
    if (op.startsWith("TOUCH_")) {
        let gid = VerificationSeam.publishGateCommand(op)
        return verifyOkFrame(op, "PUBLISHED " + gid.toString())
    }
    // 链2：替身命令带空格参数（如 "STUB_ARM 91 0 91 8000"）——按首词路由，
    // 完整 op 原样发布给 owner 派发（gateName 携带参数，executeGateCommand 解析）。
    let imageOp = op.startsWith("GATE_IMAGE_HOLD ") ||
        op.startsWith("GATE_IMAGE_RELEASE ") || op.startsWith("GATE_IMAGE_FORGET ")
    let opKey = if (op.startsWith("STUB_")) {
        op.split(" ")[0]
    } else if (imageOp) {
        op.split(" ")[0]
    } else { op }
    match (opKey) {
        case "PAUSE_CLAIM" =>
            let ok = VerificationSeam.setClaimPaused(true)
            cjguiOhosInfo("CjguiTransportVerify", "verify gate: claim paused ok=" + ok.toString())
            return verifyOkFrame(op, "PAUSED true")
        case "RESUME_CLAIM" =>
            let ok = VerificationSeam.setClaimPaused(false)
            cjguiOhosInfo("CjguiTransportVerify", "verify gate: claim resumed ok=" + ok.toString())
            return verifyOkFrame(op, "PAUSED false")
        case "DISARM" =>
            // 退出/收尾复位：闸门与注册一起回收，避免把暂停态留给下一个用例。
            let _ = VerificationSeam.setClaimPaused(false)
            VERIFY_CONTROL = None
            VERIFY_TOKEN = ""
            cjguiOhosInfo("CjguiTransportVerify", "verify gate: disarmed and claim resumed")
            return verifyOkFrame(op, "DISARMED true")
        case "STATE" =>
            let paused = VerificationSeam.claimPaused()
            let identity = VerificationSeam.identity()
            return verifyOkFrame(op, "PAUSED " + paused.toString() + "\nIDENTITY " + identity)
        case "COUNTERS" =>
            let (queued, bytes, conns, inflight, lifecycle) = VerificationSeam.counters()
            return verifyOkFrame(op, "QUEUED " + queued.toString() + "\nBYTES " + bytes.toString() +
                "\nCONNS " + conns.toString() + "\nINFLIGHT " + inflight.toString() +
                "\nLIFECYCLE " + lifecycle.toString())
        case "STOP" =>
            // 直接调用生产停止入口（与 owner 退出后同一条路径）。
            VerificationSeam.requestProductionStop()
            cjguiOhosInfo("CjguiTransportVerify", "verify gate: production stop requested")
            return verifyOkFrame(op, "STOP_REQUESTED true")
        case "SETTLE" =>
            return runSettleWithBoot(op, 0)
        case "SETTLE_HOLD" =>
            // 同 SETTLE，但 close+boot 之间保持 800ms 关闭窗口，供宿主侧
            // 确定性观察「关闭后连接被拒」。验证专用，不改生产时序。
            return runSettleWithBoot(op, 800)
        case "BOOT_STATE" =>
            // 关闭+重开结果读数。BOOT 失败时新 listener 不存在、本 op 不可达，
            // 验证方按超时判失败——失败本身不给假绿通道。
            BOOT_RESULT_LOCK.lock()
            let pendingR = BOOT_PENDING
            let closedR = BOOT_CLOSED
            let bootedR = BOOT_BOOTED
            let newIdR = BOOT_NEW_ID
            BOOT_RESULT_LOCK.unlock()
            return verifyOkFrame(op, "PENDING " + pendingR.toString() +
                "\nCLOSED " + closedR.toString() + "\nBOOTED " + bootedR.toString() +
                "\nNEW_IDENTITY " + newIdR)
        case "GATE_IMAGE_HOLD" | "GATE_IMAGE_RELEASE" | "GATE_IMAGE_FORGET"
           | "GATE_IMAGE_STATS" | "GATE_IMAGE_STATS_EXT"
           | "GATE_REJECT_NEXT" | "GATE_FAIL_ACK_1" | "GATE_DEQUEUE_HOLD_30000" | "GATE_CLEAR"
           | "GATE_HOLD_PERMIT_8000" | "GATE_HOLD_CREATE_8000" | "GATE_HOLD_CREATE_RET_8000"
           | "GATE_HOLD_DRAW_8000" | "GATE_HOLD_ADMIT_8000" | "GATE_SIM_RETIRED"
           | "GATE_SIM_CREATED" | "GATE_A2_STATS" | "GATE_FLUSH_HOLD_30000"
           | "GATE_FLUSH_HOLD_RELEASE" | "GATE_ACCEPT_THROW" | "GATE_ROLLBACK_THROW"
           | "GATE_THROW_CLEAR"
           | "STUB_DISARM"
           | "STUB_ARM" | "STUB_HOLD" | "STUB_SESSION" | "GATE_AUDIT_FIXTURE"
           | "GATE_REDRAW" =>
            // A1 矩阵：发布渲染器闸门命令。owner 循环在本进程执行（renderer
            // test-gates 的 foreign 入口），结果经 GATE_STATE 读回。这里只发布
            // 不执行——执行与结果归属在 owner 派发处记录，不在此伪造。
            let gid = VerificationSeam.publishGateCommand(op)
            return verifyOkFrame(op, "PUBLISHED " + gid.toString())
        case "STUB_RELEASE" =>
            let r = unsafe { cjgui_ohos_test_stub_release() }
            return verifyOkFrame(op, "stub_release=" + r.toString())
        case "STUB_RETIRE" =>
            let parts = op.split(" ")
            if (parts.size < 2) { return verifyOkFrame(op, "stub_retire=-1") }
            let r = unsafe { cjgui_ohos_test_stub_lease_retire(Int64.parse(parts[1])) }
            return verifyOkFrame(op, "stub_retire=" + r.toString())
        case "STUB_STATE" =>
            let st = unsafe { cjgui_ohos_test_stub_state() }
            return verifyOkFrame(op, "stub_state=" + st.toString())
        case "GATE_PC_CALLS" =>
            let p = unsafe { cjgui_ohos_test_platform_call_packed() }
            return verifyOkFrame(op, "pc_calls=" + p.toString())
        case "STUB_COUNTS" =>
            let parts = op.split(" ")
            if (parts.size < 2) { return verifyOkFrame(op, "stub_counts=-1") }
            let c = unsafe { cjgui_ohos_test_stub_counts(Int64.parse(parts[1])) }
            return verifyOkFrame(op, "stub_counts=" + c.toString())
        case "GATE_STATE" =>
            let (lastId, doneId, result) = VerificationSeam.gateState()
            return verifyOkFrame(op, "LAST_COMMAND " + lastId.toString() +
                "\nRESULT_ID " + doneId.toString() + "\nRESULT " + result)
        case "CLOSE_WINDOW" =>
            // A1：一次 close 请求。owner 走生产 close 路径（close 意图→结算后
            // 自动收敛→宿主停止链），此处不直接触碰窗口。
            let cok = VerificationSeam.requestWindowClose()
            return verifyOkFrame(op, "CLOSE_REQUESTED " + cok.toString())
        case "EXEC_HOLD_1200" =>
            // A2/A3「不可取消提交」窗口：owner 认领票据（Executing、在途计数已加）
            // 后推迟 dispatch 1200ms。验证方经 COUNTERS 观察 INFLIGHT=1 确认进入
            // 窗口，再 SETTLE——停止不取消 Executing 票，owner 到期放行按真实
            // 终态结算，awaitClosed 等在途归零后才 Closed。
            let ok = VerificationSeam.setExecutionHoldFor(1200)
            return verifyOkFrame(op, "HOLD_SET " + ok.toString() + "\nHOLD_MS 1200")
        case "TICKETS" =>
            // B.3 取证：队列与登记中执行中票据的 ID/阶段/结算位。
            // 需在 BRIDGE_LOCK 之外取：ticketEvidence 自带锁。
            let evidence = OhosTransportBridge.ticketEvidence()
            // 严格解析器要求每行 KEY VALUE 且键唯一：空表用 COUNT 0，
            // 每张票一行 T<n> ID .. PHASE .. SETTLED ..（末尾自带换行）。
            let detail = if (evidence == "") {
                "COUNT 0"
            } else {
                evidence
            }
            return verifyOkFrame(op, detail)
        case "AWAIT_CLOSED" =>
            let closed = VerificationSeam.awaitProductionClosed(2000)
            let (queued, bytes, conns, inflight, lifecycle) = VerificationSeam.counters()
            return verifyOkFrame(op, "CLOSED " + closed.toString() + "\nQUEUED " + queued.toString() +
                "\nBYTES " + bytes.toString() + "\nCONNS " + conns.toString() +
                "\nINFLIGHT " + inflight.toString() + "\nLIFECYCLE " + lifecycle.toString())
        case _ =>
            return verifyErrorFrame("verify_unknown_op")
    }
}

// 每次 BOOT 生成新的 generation（单调，不与旧实例重叠）。
func g_nextBootGeneration(): Int64 {
    BOOT_GENERATION += 1000
    return BOOT_GENERATION
}

// 安装入口：宿主桥经 dlsym 调用。**普通产物没有这个符号**（整段被条件编译排除）。
@When[cjgui_transport_verify == "on"]
@C
public func cjgui_ohos_transport_verify_install(): Int32 {
    VERIFY_TOKEN = newVerifyToken()
    VERIFY_CONTROL = Some(handleVerifyControl)
    // 凭据写入 hilog：验证脚本从这里读回本轮 token，其它连接无从得知。
    cjguiOhosInfo("CjguiTransportVerify", "verify seam armed token=" + VERIFY_TOKEN)
    return 1
}

// 卸载入口：把注册与闸门一起复位（普通产物同样没有该符号）。
@When[cjgui_transport_verify == "on"]
@C
public func cjgui_ohos_transport_verify_uninstall(): Int32 {
    let _ = VerificationSeam.setClaimPaused(false)
    VERIFY_CONTROL = None
    VERIFY_TOKEN = ""
    cjguiOhosInfo("CjguiTransportVerify", "verify seam disarmed")
    return 1
}
