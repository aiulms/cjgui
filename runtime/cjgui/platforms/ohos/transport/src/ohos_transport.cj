// OHOS 薄传输桥 v3：loopback TCP ⇄ CjguiSharedOperationExternalConnection.dispatchPayload。
//
// 并发归属协议（Astra 定稿 + 第二次指导复核返工）：
//  - 一帧一票一连接（单次交换模型）：每个连接读一帧→建票→排队→等待自己的票
//    →回写→关闭。无共享结果槽，晚到结果结算原票不转发。
//  - 票状态机：Pending → Executing（owner 原子认领）→ Done；
//    Pending 超时/关闭 → Cancelled（确定未执行）；Executing 上等待者超时 →
//    waiterAbandoned（结果未定，不谎称拒绝；晚到完成只结算原票）。
//  - 有界：待处理票数/队列字节/活动连接数上限；连接额度在 **spawn 之前** 扣减，
//    满额直接拒绝连接（不是先 spawn 再让 submit 判 busy）。
//  - 读帧限额：header 长度上限、帧字节上限、整帧绝对单调期限、每步关闭检查。
//  - 额度与队列统一在锁内结算，且任一路径只结算一次（settled 标志）。
//  - 上下文绑定：worker 只使用创建它的 BridgeContext，不读全局 ctx；
//    旧实例的 worker/票据/连接不可能进入新实例。
//  - 关闭：requestStop（Pending→Cancelled，拒新连接/认领）→ 自连接唤醒 accept →
//    worker 按绝对期限感知 Closing 退出 → waitClosed 要求 listener、活动连接、
//    队列与在途票据全部终结。Closing 不被新 ctx 替换。
//  - 业务执行仍只在仓颉 owner 线程 dispatchPayload（与 macOS 同契约路径）；
//    本文件不做任何业务解释。
//  - 验证接缝默认**未注册**：普通产物不解析任何控制帧，见 VERIFY_CONTROL 的说明。

package cjgui_ohos_transport

import std.net.*
import std.sync.*
import std.time.*
import std.collection.ArrayList

let TAG_TRANSPORT = "CjguiTransport"

// Fixed diagnostic vocabulary only. Never place AUTH, field values or a
// generated candidate payload in hilog while timing the owner queue.
func ownerClaimOperation(payload: String): String {
    // Diagnostics never need to scan a large generated candidate. Keep the
    // owner-claim path's allocation bounded before splitting protocol lines.
    if (payload.size > 512) { return "OTHER" }
    let lines = payload.split("\n")
    if (lines.size >= 3) {
        if (lines[2] == "GET_CONTEXT 0") {
            return "GET_CONTEXT_0"
        }
        if (lines[2] == "GET_GENERATED_UI_INSTANCES") {
            return "GET_GENERATED_UI_INSTANCES"
        }
    }
    return "OTHER"
}

// 桥接错误原因码（扩展官方错误帧语法；消费方不得把 unknown 映射为"未应用"）
public let REASON_TIMEOUT_NOT_EXECUTED = "transport_timeout_not_executed"
public let REASON_CLOSED_NOT_EXECUTED = "transport_closed_not_executed"
public let REASON_OUTCOME_UNKNOWN = "transport_outcome_unknown"
public let REASON_SERVER_BUSY = "server_busy"
public let REASON_FRAME_TOO_LARGE = "transport_frame_rejected"

// 官方错误帧（KIND ERROR），外层帧格式由连接处理统一包装。
public func transportErrorFrame(reason: String): String {
    return "PROTOCOL CJGUI_SHARED_OPERATION/2\nKIND ERROR\nERROR ${reason}\nEND"
}

// 票据/队列唯一锁：所有状态转换、容器操作、额度增减在同一把锁内。
let BRIDGE_LOCK = Mutex()

// 执行保持（A2/A3「不可取消提交」反例的确定性窗口）：owner 在 claimNext 与
// dispatch 之间读到正值时等待到期。只能由**已注册的验证接缝**写入——未注册
// 产物恒 0（能力没有触发路径），owner 循环读到的永远是「无需等待」。
var EXECUTION_HOLD_UNTIL: MonoTime = MonoTime.now()

// 执行中票据登记（B.3 取证）：仅在接缝已注册的构建里记录，使验证方能在
// 生产 stop 裁决处采样目标票的 ID/阶段。普通产物不登记（能力无触发路径）。
var EXECUTING_TICKETS: ArrayList<TransportTicket> = ArrayList<TransportTicket>()

// A1 矩阵：验证接缝发布的渲染器/窗口闸门命令。只有已注册接缝的产物才有
// 写入者；owner 循环（cjgui_app）轮询并在本进程执行（renderer test-gates
// 的 foreign 入口），结果写回。普通产物四项恒为初值（无触发路径）。
var GATE_COMMAND_ID: Int64 = 0
var GATE_COMMAND: String = ""
var GATE_RESULT_ID: Int64 = -1
var GATE_RESULT: String = "none"
var WINDOW_CLOSE_REQUESTED = false

var VERIFY_CONTROL: ?(String) -> ?String = None

func verifySeamInstalled(): Bool {
    match (VERIFY_CONTROL) {
        case Some(_) => return true
        case None => return false
    }
}

// 已注册接缝可用的操作。全部作用于**当前实例**；未注册时调用是显式错误而不是静默成功。


// 读帧限额（B 返工）：header 最多 16 位数字 + 换行；帧体最多 8 MiB。
let MAX_HEADER_BYTES: Int64 = 16
let MAX_FRAME_BYTES: Int64 = 8 * 1024 * 1024
// 整帧读入的绝对期限（从连接建立起算，不被单次 read 重置）。
let FRAME_DEADLINE_MS: Int64 = 3000
// 单帧业务等待上限（与等待者的绝对期限一致）。
let TICKET_DEADLINE_MS: Int64 = 3000
let WORKER_WAIT_MS: Int64 = 4000

enum TicketPhase {
    | TpPending
    | TpExecuting
    | TpDone
    | TpCancelled
}


public class OhosTransportBridge {
    static var ctx: ?BridgeContext = None

    // ---- 生命周期 ----

    // start：同进程重开时 generation 必须变化（新实例身份，防 ABA）。
    // 前一实例必须已 Closed（listener/连接/票据全部终结）才允许替换；
    // Closing 中的实例不能被新 ctx 顶掉。
    public static func start(generation: Int64, port: UInt16): Bool {
        BRIDGE_LOCK.lock()
        var created = false
        if (let Some(c) <- ctx) {
            if (c.lifecycle == 0) {
                created = false   // 已有活动实例
            } else if (c.lifecycle == 1) {
                created = false   // 关闭中：不接受新实例身份
            } else if (!contextClosedLocked(c)) {
                created = false   // 名义 Closed 但仍有连接/票据未终结
            } else {
                ctx = Some(BridgeContext("ohos_transport_${generation}", port))
                created = true
            }
        } else {
            ctx = Some(BridgeContext("ohos_transport_${generation}", port))
            created = true
        }
        BRIDGE_LOCK.unlock()
        return created
    }

    // 关闭判据：listener 已退出、无活动连接、队列无票、无在途执行票据。
    static func contextClosedLocked(c: BridgeContext): Bool {
        return c.acceptExited && c.activeConnections <= 0 && c.queue.size == 0 && c.inFlightTickets <= 0
    }

    // requestStop：锁内 Closing；Pending→Cancelled（确定未执行），额度与队列
    // 在同一把锁内回收。Executing/Done 保留结算。线性化点在此。
    //
    // B2 返工（实测缺陷）：旧实现 `for (t in c.queue) { settleCancelledLocked(...) }`
    // 在遍历 ArrayList 的同时由 settleCancelledLocked 从**同一个**容器 remove，
    // 迭代器失效会抛异常；异常又发生在 BRIDGE_LOCK 持有期间，于是锁被永久占住
    // （后续所有 submit/claim/stop 全部卡死）。现在改为：
    //   1) 先在锁内把队列整体**分离**到局部变量并把 c.queue 换成空表——遍历期间
    //      不再有人改动被遍历的容器；
    //   2) 再对分离出来的票逐张结算（settleCancelledLocked 此时只可能操作新的空表）；
    //   3) 整个临界区用 try/finally 保证任何异常都不会把锁留下。
    // Pending 取消、Executing 结算、额度扣减仍各自恰好一次（settled/accounted 双重保护）。
    public static func requestStop(): Unit {
        BRIDGE_LOCK.lock()
        try {
            match (ctx) {
                case Some(c) =>
                    if (c.lifecycle == 0) {
                        // 先禁新连接/新认领，再处理在队票（顺序不可交换：
                        // 否则并发 submit 可能把票塞进刚分离的表里而逃过取消）。
                        c.lifecycle = 1
                        let detached = c.queue
                        c.queue = ArrayList<TransportTicket>()
                        for (t in detached) {
                            settleCancelledLocked(c, t, REASON_CLOSED_NOT_EXECUTED)
                        }
                    }
                case None => ()
            }
        } finally {
            BRIDGE_LOCK.unlock()
        }
    }

    // 自连接唤醒阻塞 accept；等 listener、连接与票据全部终结（Closed 判据）。
    public static func awaitClosed(timeoutMs: Int64): Bool {
        // 取当前实例端口（用于自连接唤醒阻塞中的 accept）。
        // 不写成裸块 `{ ... }`：仓颉会把它当尾随 lambda 解析。
        BRIDGE_LOCK.lock()
        var port: UInt16 = 7856
        if (let Some(c) <- ctx) {
            port = c.port
        }
        BRIDGE_LOCK.unlock()
        try {
            let wake = TcpSocket("127.0.0.1", port)
            wake.connect()
            wake.close()
        } catch (_) {
            // 端口可能尚未监听（竞争）；以轮询结果为准
        }
        var waited: Int64 = 0
        while (waited < timeoutMs) {
            BRIDGE_LOCK.lock()
            var done = false
            if (let Some(c) <- ctx) {
                done = c.lifecycle != 0 && contextClosedLocked(c)
                if (done && c.lifecycle == 1) {
                    c.lifecycle = 2
                }
            }
            BRIDGE_LOCK.unlock()
            if (done) { return true }
            sleep(Duration.millisecond * 10)
            waited += 10
        }
        return false
    }

    // ---- 提交/认领/完成 ----

    // 连接 worker 提交一帧：0 接纳 / 1 busy / 2 关闭。
    // 只使用传入的创建上下文，不读全局 ctx。
    static func submit(context: BridgeContext, payload: String): (Int32, ?TransportTicket) {
        BRIDGE_LOCK.lock()
        if (context.lifecycle != 0) {
            BRIDGE_LOCK.unlock()
            return (2, None)
        }
        if (context.queue.size >= context.maxPending ||
            context.queuedBytes + Int64(payload.size) > context.maxQueuedBytes) {
            BRIDGE_LOCK.unlock()
            return (1, None)
        }
        let enqueuedAt = MonoTime.now()
        let t = TransportTicket(context.nextRequestId, payload,
            enqueuedAt + Duration.millisecond * TICKET_DEADLINE_MS, enqueuedAt, context)
        context.nextRequestId += 1
        context.queue.add(t)
        context.queuedBytes += Int64(payload.size)
        BRIDGE_LOCK.unlock()
        return (0, Some(t))
    }

    // owner 认领下一张未到期 Pending 票；到期票就地取消并回收；
    // 已取消票在锁内出队（旧实现跳过 Cancelled，队列永久泄漏→永久 busy）。
    public static func claimNext(): ?ExecutionLease {
        BRIDGE_LOCK.lock()
        if (let Some(c) <- ctx) {
            if (c.lifecycle != 0) {
                BRIDGE_LOCK.unlock()
                return None
            }
            // 验证接缝闸门：只有**已注册接缝**的构建才可能暂停认领。
            // 普通产物 VERIFY_CONTROL 恒为 None，因此这一支不可达——即使 claimPaused
            // 因为任何原因被写入，普通产物也不会暂停（能力没有注册路径）。
            if (verifySeamInstalled() && c.claimPaused) {
                BRIDGE_LOCK.unlock()
                return None
            }
            var i: Int64 = 0
            while (i < c.queue.size) {
                let t = c.queue[i]
                if (phaseIs(t, TicketPhase.TpCancelled)) {
                    settleCancelledLocked(c, t, t.cancelReason)
                    // 兜底出队（settle 正常已出队；已结算票可能仍留在队列）。
                    if (i < c.queue.size && c.queue[i].requestId == t.requestId) {
                        let _ = c.queue.remove(at: i)
                    }
                    continue
                }
                if (!phaseIs(t, TicketPhase.TpPending)) {
                    let _ = c.queue.remove(at: i)
                    continue
                }
                let claimedAt = MonoTime.now()
                if (claimedAt >= t.deadline) {
                    settleCancelledLocked(c, t, REASON_TIMEOUT_NOT_EXECUTED)
                    continue
                }
                t.phase = TicketPhase.TpExecuting
                t.accounted = false
                c.queuedBytes -= Int64(t.payload.size)
                if (c.queuedBytes < 0) {
                    c.queuedBytes = 0
                }
                c.inFlightTickets += 1
                if (verifySeamInstalled()) {
                    EXECUTING_TICKETS.add(t)
                }
                let _ = c.queue.remove(at: i)
                BRIDGE_LOCK.unlock()
                // Queue time is complete-frame enqueue -> owner claim, sampled
                // before dispatch. Emit outside BRIDGE_LOCK and before returning
                // the lease, so the row precedes the corresponding response.
                try {
                    let queueUs = (claimedAt - t.enqueuedAt).toNanoseconds() / 1000
                    cjguiOhosInfo(TAG_TRANSPORT,
                        "transport-cost stage=owner-claim instance=${t.context.identity} " +
                        "requestId=${t.requestId} op=${ownerClaimOperation(t.payload)} queueUs=${queueUs}")
                } catch (_) {
                    // Diagnostics cannot leave a claimed business ticket stuck
                    // in Executing if string formatting or logging fails.
                }
                return Some(ExecutionLease(t))
            }
        }
        BRIDGE_LOCK.unlock()
        return None
    }

    // owner 完成 dispatch：校验归属（Executing + 同一上下文）后结算原票。
    public static func complete(lease: ExecutionLease, response: String): Bool {
        BRIDGE_LOCK.lock()
        var ok = false
        let t = lease.ticket
        if (phaseIs(t, TicketPhase.TpExecuting) && !t.settled) {
            t.result = response
            t.phase = TicketPhase.TpDone
            t.settled = true
            t.context.inFlightTickets -= 1
            if (verifySeamInstalled()) {
                var ri: Int64 = 0
                while (ri < EXECUTING_TICKETS.size) {
                    if (EXECUTING_TICKETS[ri].requestId == t.requestId) {
                        let _ = EXECUTING_TICKETS.remove(at: ri)
                        break
                    }
                    ri += 1
                }
            }
            if (t.context.inFlightTickets < 0) {
                t.context.inFlightTickets = 0
            }
            ok = true
        }
        BRIDGE_LOCK.unlock()
        return ok
    }

    // ---- 连接 worker：等待自己的票（单次交换） ----

    static func serveFrame(context: BridgeContext, payload: String): String {
        // 验证接缝（默认未注册）。未注册时这一支完全跳过：任何负载——包括字段值里
        // 恰好含 "PAUSE_CLAIM" 的合法业务帧——都按正常业务提交处理，不存在子串嗅探。
        // 已注册时由处理器做**整帧严格解析**：不是控制协议的负载返回 None，仍走业务。
        match (VERIFY_CONTROL) {
            case Some(handler) =>
                match (handler(payload)) {
                    case Some(controlResponse) => return controlResponse
                    case None => ()
                }
            case None => ()
        }
        let (outcome, ticket) = submit(context, payload)
        if (outcome == 1) {
            return transportErrorFrame(REASON_SERVER_BUSY)
        }
        if (outcome == 2) {
            return transportErrorFrame(REASON_CLOSED_NOT_EXECUTED)
        }
        if (let Some(t) <- ticket) {
            var waitedMs: Int64 = 0
            while (waitedMs < WORKER_WAIT_MS) {
                BRIDGE_LOCK.lock()
                var verdict = 0
                if (phaseIs(t, TicketPhase.TpDone)) {
                    verdict = 1
                } else if (phaseIs(t, TicketPhase.TpCancelled)) {
                    verdict = 2
                } else if (phaseIs(t, TicketPhase.TpPending) && MonoTime.now() >= t.deadline) {
                    settleCancelledLocked(context, t, REASON_TIMEOUT_NOT_EXECUTED)
                    verdict = 2
                } else if (phaseIs(t, TicketPhase.TpExecuting) && MonoTime.now() >= t.deadline) {
                    t.waiterAbandoned = true   // 执行权已授：结果未定
                    verdict = 3
                }
                BRIDGE_LOCK.unlock()
                if (verdict == 1) { return t.result }
                if (verdict == 2) { return transportErrorFrame(t.cancelReason) }
                if (verdict == 3) { return transportErrorFrame(REASON_OUTCOME_UNKNOWN) }
                sleep(Duration.millisecond * 5)
                waitedMs += 5
            }
            BRIDGE_LOCK.lock()
            var final = transportErrorFrame(REASON_OUTCOME_UNKNOWN)
            if (phaseIs(t, TicketPhase.TpDone)) {
                final = t.result
            } else if (phaseIs(t, TicketPhase.TpCancelled)) {
                final = transportErrorFrame(t.cancelReason)
            } else if (phaseIs(t, TicketPhase.TpExecuting)) {
                t.waiterAbandoned = true
            }
            BRIDGE_LOCK.unlock()
            return final
        }
        return transportErrorFrame(REASON_CLOSED_NOT_EXECUTED)
    }

    // ---- 监听与连接（单次交换模型，连接额度在 spawn 前扣减） ----

    public static func listen(port: UInt16): Unit {
        BRIDGE_LOCK.lock()
        let local = ctx
        BRIDGE_LOCK.unlock()
        if (let Some(context) <- local) {
            // server 句柄提出 try 作用域：同进程重开要在同一端口重新 bind，
            // 监听 fd 必须显式关闭（GC 回收不是确定性语义，旧 fd 未关会让
            // 重开的 bind 直接 EADDRINUSE）。acceptExited 也一并移入 finally，
            // 任何退出路径（含异常）都保证关闭判据可见。
            var server: ?TcpServerSocket = None
            try {
                let s = TcpServerSocket(bindAt: port)
                s.bind()
                server = Some(s)
                cjguiOhosInfo("CjguiTransport",
                    "listening on 127.0.0.1:${port} identity=${context.identity} maxConn=${context.maxConnections}")
                while (true) {
                    BRIDGE_LOCK.lock()
                    let running = context.lifecycle == 0
                    BRIDGE_LOCK.unlock()
                    if (!running) { break }
                    let client = s.accept()
                    // 连接额度在 spawn 之前落实：满额直接拒绝该连接（不建 worker），
                    // 关闭中也直接拒绝。这样活动连接数天然有界。
                    BRIDGE_LOCK.lock()
                    var shouldServe = context.lifecycle == 0
                    if (shouldServe && context.activeConnections >= context.maxConnections) {
                        shouldServe = false
                    }
                    if (shouldServe) { context.activeConnections += 1 }
                    BRIDGE_LOCK.unlock()
                    if (!shouldServe) {
                        client.close()
                        if (context.lifecycle == 0) {
                            cjguiOhosWarn("CjguiTransport",
                                "connection refused: quota reached (${context.activeConnections})")
                        }
                        continue
                    }
                    // worker 绑定创建它的 context（含 ctx 为闭包参数，不读全局）。
                    spawn {
                        handleClient(context, client)
                        BRIDGE_LOCK.lock()
                        context.activeConnections -= 1
                        if (context.activeConnections < 0) {
                            context.activeConnections = 0
                        }
                        BRIDGE_LOCK.unlock()
                    }
                }
            } catch (e: Exception) {
                cjguiOhosInfo("CjguiTransport", "listener exit: ${e.message}")
            } finally {
                match (server) {
                    case Some(s) =>
                        try {
                            s.close()
                        } catch (_) {
                        }
                    case None => ()
                }
                BRIDGE_LOCK.lock()
                context.acceptExited = true
                BRIDGE_LOCK.unlock()
            }
        }
        cjguiOhosInfo("CjguiTransport", "listener exited")
    }

    // 单次交换：读一帧→serveFrame→回写→关闭。
    // 读入限额：header ≤ 16 字节、帧体 ≤ 8 MiB、整帧绝对期限；每步检查 Closing。
    static func handleClient(context: BridgeContext, client: TcpSocket): Unit {
        let frameDeadline = MonoTime.now() + Duration.millisecond * FRAME_DEADLINE_MS
        client.readTimeout = Duration.millisecond * 500
        var buffer = ArrayList<UInt8>()
        let chunk = Array<UInt8>(4096, repeat: 0)
        var served = false
        try {
            while (!served) {
                if (MonoTime.now() >= frameDeadline) {
                    cjguiOhosWarn("CjguiTransport", "frame read deadline exceeded")
                    break
                }
                BRIDGE_LOCK.lock()
                let closing = context.lifecycle != 0
                BRIDGE_LOCK.unlock()
                if (closing) { break }
                var n: Int64 = 0
                try {
                    n = client.read(chunk)
                } catch (_) {
                    continue   // 读超时：回到期限与 Closing 检查，不重置总预算
                }
                if (n <= 0) { break }
                var i: Int64 = 0
                while (i < n && !served) {
                    buffer.add(chunk[i])
                    i += 1
                    // 未见到换行前的 header 上限（旧实现无换行可无限增长）。
                    var headerEnd: Int64 = -1
                    for (idx in 0..buffer.size) {
                        if (buffer[idx] == 10) { headerEnd = idx; break }
                    }
                    if (headerEnd < 0) {
                        if (buffer.size > MAX_HEADER_BYTES) {
                            throw Exception("header too long")
                        }
                        continue
                    }
                    if (headerEnd > MAX_HEADER_BYTES || headerEnd <= 0) {
                        throw Exception("invalid frame header")
                    }
                    var payloadSize: Int64 = 0
                    var valid = true
                    for (idx in 0..headerEnd) {
                        let b = buffer[idx]
                        if (b < 48 || b > 57) { valid = false; break }
                        payloadSize = payloadSize * 10 + Int64(b - 48)
                    }
                    if (!valid || payloadSize <= 0 || payloadSize > MAX_FRAME_BYTES) {
                        throw Exception("invalid frame header")
                    }
                    let total = headerEnd + 1 + payloadSize
                    if (Int64(buffer.size) >= total) {
                        var payloadBytes = Array<UInt8>(payloadSize, repeat: 0)
                        for (idx in 0..payloadSize) {
                            payloadBytes[idx] = buffer[headerEnd + 1 + idx]
                        }
                        let request = String.fromUtf8(payloadBytes)
                        let response = serveFrame(context, request)
                        let responseBytes = response.toArray()
                        var frame = ArrayList<UInt8>()
                        for (b in responseBytes.size.toString().toArray()) { frame.add(b) }
                        frame.add(10)
                        for (b in responseBytes) { frame.add(b) }
                        client.write(frame.toArray())
                        served = true
                    }
                }
            }
        } catch (e: Exception) {
            cjguiOhosInfo("CjguiTransport", "client closed: ${e.message}")
        }
        client.close()
    }

    // ---- 取证查询（计数只用于证据，不参与判定） ----

    public static func snapshotCounters(): (Int64, Int64, Int64, Int64, Int64) {
        BRIDGE_LOCK.lock()
        var queued: Int64 = 0
        var bytes: Int64 = 0
        var conns: Int64 = 0
        var inflight: Int64 = 0
        var lifecycle: Int64 = -1
        if (let Some(c) <- ctx) {
            queued = c.queue.size
            bytes = c.queuedBytes
            conns = c.activeConnections
            inflight = c.inFlightTickets
            lifecycle = Int64(c.lifecycle)
        }
        BRIDGE_LOCK.unlock()
        return (queued, bytes, conns, inflight, lifecycle)
    }

    // B.3 取证读数：队列 + 登记中的执行中票据（仅接缝已注册时有内容）。
    public static func ticketEvidence(): String {
        BRIDGE_LOCK.lock()
        let s = ticketEvidenceLocked()
        BRIDGE_LOCK.unlock()
        return s
    }

    public static func currentIdentity(): String {
        BRIDGE_LOCK.lock()
        var identity = "none"
        if (let Some(c) <- ctx) {
            identity = c.identity
        }
        BRIDGE_LOCK.unlock()
        return identity
    }
}

// 取证读数：队列 + 登记中的执行中票据，格式 "ID <id> PHASE <p> SETTLED <b>" 行。
// 仅在接缝已注册时有内容。
func ticketEvidenceLocked(): String {
    if (!verifySeamInstalled()) {
        return ""
    }
    var out = ""
    var firstLine = true
    match (OhosTransportBridge.ctx) {
        case Some(c) =>
            var seq: Int64 = 0
            var i: Int64 = 0
            while (i < c.queue.size) {
                let t = c.queue[i]
                let phase = if (phaseIs(t, TicketPhase.TpPending)) {
                    "pending"
                } else if (phaseIs(t, TicketPhase.TpExecuting)) {
                    "executing"
                } else if (phaseIs(t, TicketPhase.TpDone)) {
                    "done"
                } else {
                    "cancelled"
                }
                if (!firstLine) { out += "\n" }
                out += "T${seq} ID ${t.requestId} PHASE ${phase} SETTLED ${t.settled}"
                firstLine = false
                seq += 1
                i += 1
            }
            var j: Int64 = 0
            while (j < EXECUTING_TICKETS.size) {
                let t = EXECUTING_TICKETS[j]
                let phase = if (phaseIs(t, TicketPhase.TpDone)) {
                    "done"
                } else if (phaseIs(t, TicketPhase.TpCancelled)) {
                    "cancelled"
                } else {
                    "executing"
                }
                if (!firstLine) { out += "\n" }
                out += "T${seq} ID ${t.requestId} PHASE ${phase} SETTLED ${t.settled}"
                firstLine = false
                seq += 1
                j += 1
            }
        case None => ()
    }
    return out
}

func phaseIs(t: TransportTicket, target: TicketPhase): Bool {
    match (t.phase) {
        case TpPending => return match (target) { case TpPending => true case _ => false }
        case TpExecuting => return match (target) { case TpExecuting => true case _ => false }
        case TpDone => return match (target) { case TpDone => true case _ => false }
        case TpCancelled => return match (target) { case TpCancelled => true case _ => false }
    }
}

// 一张请求票：连接 worker 与 owner 经同一实例交换归属与结果。
class TransportTicket {
    let requestId: Int64
    let payload: String
    let deadline: MonoTime
    let enqueuedAt: MonoTime
    let context: BridgeContext          // 归属上下文（旧实例票据不得进新实例）
    var phase: TicketPhase = TicketPhase.TpPending
    var result: String = ""
    var cancelReason: String = ""
    var waiterAbandoned = false   // 等待者已放弃；执行仍可能完成（结算原票）
    var accounted = true          // queuedBytes 是否仍计入（结算一次即置否）
    var settled = false           // 终态是否已唯一结算

    init(requestId: Int64, payload: String, deadline: MonoTime, enqueuedAt: MonoTime,
         context: BridgeContext) {
        this.requestId = requestId
        this.payload = payload
        this.deadline = deadline
        this.enqueuedAt = enqueuedAt
        this.context = context
    }
}

// owner 持有的执行租约：认领后 payload 不可变；complete 校验归属。
public class ExecutionLease {
    let ticket: TransportTicket
    public let payload: String
    init(ticket: TransportTicket) {
        this.ticket = ticket
        this.payload = ticket.payload
    }
}

class BridgeContext {
    let identity: String
    let port: UInt16
    var lifecycle: Int32 = 0   // 0 Running / 1 Closing / 2 Closed
    var queue = ArrayList<TransportTicket>()
    var queuedBytes: Int64 = 0
    var nextRequestId: Int64 = 1
    var activeConnections: Int64 = 0
    var acceptExited = false
    var inFlightTickets: Int64 = 0
    let maxPending: Int64
    let maxQueuedBytes: Int64
    let maxConnections: Int64
    // 认领闸门的目标位（B 节反例用）。它**只能**由已注册的验证接缝写入：
    // claimNext 只在接缝已注册时才读它，因此普通产物即使该字段为真也不会暂停
    // （普通产物没有注册路径，见 VERIFY_CONTROL）。新实例从 false 起步。
    var claimPaused: Bool = false

    init(identity: String, port: UInt16) {
        this.identity = identity
        this.port = port
        this.maxPending = 16
        this.maxQueuedBytes = 8 * 1024 * 1024
        this.maxConnections = 8
    }
}

// ---------------------------------------------------------------------------
// 验证接缝（默认不注册）
// ---------------------------------------------------------------------------
//
// 「暂停认领」是验证专用能力，不是产品功能。旧实现直接在 serveFrame 开头做
// `payload.contains("PAUSE_CLAIM")` 嗅探，于是普通构建里**任何**包含该串的合法
// 业务帧都会被吞掉。为满足「默认普通 HAP 不编入/不注册该能力」，这里改成：
//
//   1) 本文件默认不注册任何处理器（VERIFY_CONTROL == None）。serveFrame 在未注册时
//      直接走正常 submit 路径，对任何负载（包括字段值里含 PAUSE_CLAIM 的帧）都不做
//      控制解释；claimNext 也不读 claimPaused。因此普通产物的暂停能力不是「被注释
//      禁用」，而是**没有注册路径可达**。
//   2) 只有显式测试构建把 transport/verify/ohos_transport_verify.cj 一起编入
//      （由 sync_platform.sh 按 CJGUI_TRANSPORT_VERIFY 决定），并由宿主桥经 dlsym
//      调用其 @C 安装入口 cjgui_ohos_transport_verify_install 才注册。普通产物不含
//      该文件 → 符号缺失 → 永不注册。
//   3) 注册处理器要求本轮一次性凭据（注册时生成并写入 hilog），且只接受**整帧严格
//      解析**的控制协议，不做子串匹配；凭据不符的控制帧被显式拒绝，不会被当成业务帧。
//
// 测试构建的处理器同时提供「直接调用生产停止入口」的驱动（requestStop/awaitClosed），
// 因为模拟器上 shell 用户无 root、无法从外部暂停进程（实测 kill -STOP 被拒）。
public class VerificationSeam {
    // 切换认领闸门。返回 false 表示当前没有实例（而不是「已生效」）。
    public static func setClaimPaused(paused: Bool): Bool {
        BRIDGE_LOCK.lock()
        var ok = false
        match (OhosTransportBridge.ctx) {
            case Some(c) =>
                c.claimPaused = paused
                ok = true
            case None => ok = false
        }
        BRIDGE_LOCK.unlock()
        return ok
    }

    // 调用**生产**停止入口（不是平行实现）：与 owner 退出后走的同一条路径。
    public static func requestProductionStop(): Unit {
        OhosTransportBridge.requestStop()
    }

    // 调用**生产**收敛等待，返回是否真正 Closed。
    public static func awaitProductionClosed(timeoutMs: Int64): Bool {
        return OhosTransportBridge.awaitClosed(timeoutMs)
    }

    // 取证读数：队列 / 字节 / 连接 / 在途 / 生命周期。
    public static func counters(): (Int64, Int64, Int64, Int64, Int64) {
        return OhosTransportBridge.snapshotCounters()
    }

    public static func identity(): String {
        return OhosTransportBridge.currentIdentity()
    }

    // 调用**生产**启动入口完成同进程重开：新 generation 身份 + 监听线程。
    // 返回新身份；失败返回空串。调用方必须先确认 Closed。
    public static func requestProductionBoot(generation: Int64, port: UInt16): String {
        let ok = OhosTransportBridge.start(generation, port)
        if (!ok) {
            return ""
        }
        spawn {
            OhosTransportBridge.listen(port)
        }
        return OhosTransportBridge.currentIdentity()
    }

    public static func claimPaused(): Bool {
        BRIDGE_LOCK.lock()
        var paused = false
        match (OhosTransportBridge.ctx) {
            case Some(c) => paused = c.claimPaused
            case None => paused = false
        }
        BRIDGE_LOCK.unlock()
        return paused
    }

    // 设定执行保持窗口（ms）。票据被认领（Executing）但 dispatch 被推迟，
    // 用于让停止/结算确定性地落在「不可取消提交」窗口内。返回 false 表示
    // 当前没有实例或接缝未注册（不生效）。
    public static func setExecutionHoldFor(ms: Int64): Bool {
        if (!verifySeamInstalled()) {
            return false
        }
        BRIDGE_LOCK.lock()
        EXECUTION_HOLD_UNTIL = MonoTime.now() + Duration.millisecond * ms
        BRIDGE_LOCK.unlock()
        return true
    }

    // owner 循环读：剩余保持毫秒数（≤0 表示无需等待）。未注册接缝的构建恒 0。
    public static func executionHoldRemainingMs(): Int64 {
        if (!verifySeamInstalled()) {
            return 0
        }
        BRIDGE_LOCK.lock()
        let remaining = (EXECUTION_HOLD_UNTIL - MonoTime.now()).toMilliseconds()
        BRIDGE_LOCK.unlock()
        if (remaining < 0) {
            return 0
        }
        return remaining
    }

    // ---- A1 矩阵：闸门命令通道（仅注册接缝可用；普通产物无路径） ----

    public static func installed(): Bool {
        return verifySeamInstalled()
    }

    // 发布一条闸门命令，返回命令 ID（owner 派发后以同 ID 回填结果）。
    public static func publishGateCommand(name: String): Int64 {
        if (!verifySeamInstalled()) {
            return -1
        }
        BRIDGE_LOCK.lock()
        GATE_COMMAND_ID += 1
        GATE_COMMAND = name
        let id = GATE_COMMAND_ID
        BRIDGE_LOCK.unlock()
        return id
    }

    // owner 轮询：取当前未回填结果的命令（返回 (id, name)；无待办返回 (0, "")）。
    public static func pendingGateCommand(): (Int64, String) {
        BRIDGE_LOCK.lock()
        let id = GATE_COMMAND_ID
        let name = GATE_COMMAND
        let done = GATE_RESULT_ID
        BRIDGE_LOCK.unlock()
        if (id == 0 || id == done) {
            return (0, "")
        }
        return (id, name)
    }

    // owner 回填执行结果。
    public static func reportGateResult(id: Int64, result: String): Unit {
        BRIDGE_LOCK.lock()
        GATE_RESULT_ID = id
        GATE_RESULT = result
        BRIDGE_LOCK.unlock()
    }

    // 验证方读数：(最后命令 ID, 已回填结果 ID, 结果文本)。
    public static func gateState(): (Int64, Int64, String) {
        BRIDGE_LOCK.lock()
        let r = (GATE_COMMAND_ID, GATE_RESULT_ID, GATE_RESULT)
        BRIDGE_LOCK.unlock()
        return r
    }

    // 窗口关闭请求（一次 close，放行后自动收敛）。仅注册接缝可置位。
    public static func requestWindowClose(): Bool {
        if (!verifySeamInstalled()) {
            return false
        }
        BRIDGE_LOCK.lock()
        WINDOW_CLOSE_REQUESTED = true
        BRIDGE_LOCK.unlock()
        return true
    }

    public static func consumeWindowCloseRequest(): Bool {
        if (!verifySeamInstalled()) {
            return false
        }
        BRIDGE_LOCK.lock()
        let requested = WINDOW_CLOSE_REQUESTED
        WINDOW_CLOSE_REQUESTED = false
        BRIDGE_LOCK.unlock()
        return requested
    }
}

// 锁内唯一结算点：取消/关闭/超时的额度回收与出队都走这里，置 settled 防二次结算。
func settleCancelledLocked(c: BridgeContext, t: TransportTicket, reason: String): Unit {
    if (t.settled) {
        return
    }
    t.phase = TicketPhase.TpCancelled
    t.cancelReason = reason
    t.settled = true
    if (t.accounted) {
        t.accounted = false
        c.queuedBytes -= Int64(t.payload.size)
        if (c.queuedBytes < 0) {
            c.queuedBytes = 0
        }
    }
    var i: Int64 = 0
    while (i < c.queue.size) {
        if (c.queue[i].requestId == t.requestId) {
            let _ = c.queue.remove(at: i)
            break
        }
        i += 1
    }
}
