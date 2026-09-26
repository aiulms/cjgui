// CJGUI 鸿蒙宿主层（仓颉侧）。
//
// 职责：保存 entry 桥注册的 ingress，等待 surface 就绪后启动与 macOS
// 同源的应用循环（同一份领域/控制器，同一个 CjguiMacosApplicationHost
// 泵语义——该类是平台无关的仓颉代码，只是名字沿用了历史）。
//
// 阶段1空闲行为：pump 循环以 ≤16ms 粒度唤醒（渲染器 pump_event 的
// bounded sleep），空闲时不重建场景、不提交帧。

package cjgui_app

import std.sync.*
import std.collection.ArrayList
import kit.PerformanceAnalysisKit.Hilog
import ohos.ark_interop.JSModule
import ohos.ark_interop.JSContext
import ohos.ark_interop.JSCallInfo
import ohos.ark_interop.JSValue
import cjgui.*
import cjgui_settings_counter_application.*
import cjgui_ohos_transport.*
import cjgui_shared_operation_core.*
import std.convert.*

// 渲染器提供的 ingress 观察（实现在 ohos_renderer.cpp，静态链入本模块）。
foreign func cjgui_ohos_surface_ready(): UInt8
foreign func ohos_renderer_shutdown_render_thread(): Int32
foreign func cjgui_ohos_application_stop_requested(): Int32
foreign func cjgui_ohos_renderer_shutdown_done(): Int32

// A1 矩阵：renderer test-gates 的 foreign 入口。两个产物变体都导出同名符号，
// 普通产物返回 -1（无闸门行为）；测试产物由 verify 探针经接缝命令驱动。
foreign func cjgui_ohos_test_gate_set_fail_next(jobs: Int32, acks: Int32): Int32
foreign func cjgui_ohos_test_gate_set_flush_hold_ms(ms: Int32, count: Int32): Int32
foreign func cjgui_ohos_test_gate_set_dequeue_hold_ms(ms: Int32): Int32
foreign func cjgui_ohos_test_inject_touch(action: UInt32, x: Float32, y: Float32): Int32
foreign func cjgui_ohos_test_gate_set_flush_hold_release(): Int32
foreign func cjgui_ohos_test_gate_job_fail_count(): Int32
foreign func cjgui_ohos_test_gate_fail_armed(): Int32
foreign func cjgui_ohos_permit_pair_packed(): Int64
foreign func cjgui_ohos_test_gate_ack_fail_count(): Int32
foreign func cjgui_ohos_test_settlement_committed(): Int32
foreign func cjgui_ohos_test_settlement_aborted(): Int32
foreign func cjgui_ohos_test_gate_set_hold_permit(ms: Int32, holdN: Int32): Int32
foreign func cjgui_ohos_test_gate_set_hold_create(ms: Int32, holdN: Int32): Int32
foreign func cjgui_ohos_test_gate_set_hold_create_return(ms: Int32, holdN: Int32): Int32
foreign func cjgui_ohos_test_gate_set_hold_draw(ms: Int32, holdN: Int32): Int32
foreign func cjgui_ohos_test_gate_set_hold_admission(ms: Int32, holdN: Int32): Int32
foreign func cjgui_ohos_test_simulate_surface_retired(): Int32
foreign func cjgui_ohos_test_simulate_surface_created(): Int32
// A3：owner 就绪声明（渲染器转发到 entry 宿主桥的 ingress.appReady）。
foreign func cjgui_ohos_notify_app_ready(): Int32

let TAG = "CjguiApp"

// ---------------------------------------------------------------------------
// 官方互操作导出（ArkTS 直接 import 'libcjgui_app.so' 使用）。
// ---------------------------------------------------------------------------

class ProbeCanary {
    public let label: String
    public var touchCount: Int64
    init() {
        this.label = "设置与计数 CJGUI canary"
        this.touchCount = 0
    }
}

let PROBE_CANARY = ProbeCanary()

func probeRuntime(context: JSContext, callInfo: JSCallInfo): JSValue {
    // 探针仅由 ArkTS 主线程调用，无需加锁。
    PROBE_CANARY.touchCount += 1
    let payload = "${PROBE_CANARY.label}:${PROBE_CANARY.touchCount}"
    return context.number(Float64(payload.size)).toJSValue()
}

func probeMagic(context: JSContext, callInfo: JSCallInfo): JSValue {
    return context.number(1129465333.0).toJSValue()
}

let EXPORT_MODULE = JSModule.registerModule {
    runtime, exports =>
        exports["probeRuntime"] = runtime.function(probeRuntime).toJSValue()
        exports["probeMagic"] = runtime.function(probeMagic).toJSValue()
}

// ---------------------------------------------------------------------------
// 原始 @C 导出（entry C++ 桥经 dlsym 调用；不经过 JS 层）。
// ---------------------------------------------------------------------------

@C
public func cjgui_ohos_probe_magic(): UInt64 {
    return 0x434A4735_00000001
}

@C
public func cjgui_ohos_probe_heap(): UInt64 {
    let label = "设置与计数 CJGUI harmony probe"
    var total: UInt64 = UInt64(label.size)
    let samples = ArrayList<UInt64>()
    for (index in 0..64) {
        samples.add(UInt64(index) * 3)
    }
    for (value in samples) {
        total += value
    }
    return total
}

// 应用循环观测：循环线程写 tick，原入口经 napi probeCangjie 可读回。
let APP_LOOP_TICKS = AtomicInt64(0)

@C
public func cjgui_ohos_app_loop_ticks(): UInt64 {
    return UInt64(APP_LOOP_TICKS.load())
}

// entry 桥的启动入口：**同步**跑完整个 owner 循环，循环退出后才返回。
@C
public func cjgui_ohos_app_main_cangjie(ingress: CPointer<Unit>): Int32 {
    if (ingress.isNull()) {
        return -1
    }
    Hilog.info(0, TAG, "app_main_cangjie: ingress registered, running owner loop synchronously")
    // A3（Sol 复核第 3 点）：不再 `spawn` 后立即返回。入口返回即代表
    // owner 已真实退出（停止接单 → 传输收敛 → 窗口会话关闭 → 渲染线程
    // teardown 并 join），使「已停止」有一个**可 join 的 owner 线程**判据，
    // 而不是依赖 detach 的引导线程或全局 shutdownDone。
    ohosApplicationLoop()
    return 0
}

// ---------------------------------------------------------------------------
// 应用循环（与 macOS 同源：同一 domain/controller + 同一宿主泵语义）
// ---------------------------------------------------------------------------

func ohosApplicationLoop(): Unit {
    var ticks: Int64 = 0
    // 等待 XComponent surface 就绪（Astra：宿主等到 surface Ready 才 start）。
    while (unsafe { cjgui_ohos_surface_ready() } == 0) {
        if (ticks >= 1200) {
            Hilog.error(0, TAG, "surface not ready after 60s; app loop exits")
            return
        }
        sleep(Duration.millisecond * 50)
        ticks += 1
        APP_LOOP_TICKS.store(ticks)
    }
    Hilog.info(0, TAG, "surface ready; starting settings-counter host")
    // A1 首帧反例：首帧 PENDING 由启动参数重放的 flush 闸门制造（票据已发、
    // 提交在 Committing 内被按住 → 提交等待超时返回 PENDING，StartingPending
    // 可观察）。此处不再按 dequeue 闸门——那会让首帧在票据分配前被扣住，
    // 触发「PENDING 无票据」协议缺口路径（实测导致 host start failed）。

    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("设置与计数", 720u32, 1400u32))
    let window = host.window()
    let connection = CjguiSharedOperationExternalConnection(domain, settingsCounterAuthorization(), domain, window)
    let progressReady = connection.enableWindowProgressReads(window)
    if (!progressReady) {
        Hilog.warn(0, TAG, "window progress reads unavailable")
    }
    // 注意：不调用 connection.start()——其私有 unix 传输硬编码 /tmp，
    // OHOS 沙箱不可写。外部通道走 ohos_transport.cj 的 TCP→dispatchPayload 桥。
    if (!host.start()) {
        Hilog.error(0, TAG, "host start failed")
        host.close()
        return
    }
    Hilog.info(0, TAG, "host started; pumping turns")

    // 外部通道：票据桥（新实例身份）+ 监听线程 + owner 串行 dispatch。
    let bridgeGeneration = APP_LOOP_TICKS.load() + 1
    let _ = OhosTransportBridge.start(bridgeGeneration, 7856)
    let _ = spawn {
        OhosTransportBridge.listen(7856)
    }

    // 停止协议（Sol 归属）：surface 卸载只退役租约并保留 owner；
    // Ability 真正关闭由宿主置停止请求，owner 在轮间安全边界退出循环，
    // 之后依次：停止接单 → 传输收敛 → 渲染线程 teardown → 身份复位。
    //
    // A3：进入泵轮前先向宿主声明「已启动」。宿主据此把启动状态从 starting
    // 推进到 running；就绪必须由 owner 自己声明，宿主不按时间或入口返回推断。
    let _ = unsafe { cjgui_ohos_notify_app_ready() }
    Hilog.info(0, TAG, "owner declared app ready; entering pump loop")
    var stopRequested = false
    var faultAnnounced = false
    while (host.isOpen()) {
        // A1：终止收敛命名故障对外可见（一次播报；空串=无未收敛故障）。
        if (!faultAnnounced) {
            let fault = host.windowSettlementFault()
            if (fault != "") {
                Hilog.info(0, TAG, "settlement fault: ${fault}")
                faultAnnounced = true
            }
        }
        if (unsafe { cjgui_ohos_application_stop_requested() } == 1) {
            stopRequested = true
            break
        }
        // A1：一次 close 请求走生产 close 路径（close 意图→结算后自动收敛），
        // 不直接清状态。未注册接缝的产物恒 false。
        if (VerificationSeam.consumeWindowCloseRequest()) {
            Hilog.info(0, TAG, "verify close: host.close() via production path")
            host.close()
        }
        // A1 矩阵：执行验证接缝发布的闸门命令。未注册产物 pendingGateCommand
        // 恒 (0,"")，此分支不可达；结果按命令 ID 回填供验证者读数。
        let (gateId, gateName) = VerificationSeam.pendingGateCommand()
        if (gateId != 0) {
            var result = "unknown_command"
            if (gateName.startsWith("TOUCH_")) {
                // D 夹具：TOUCH_<action>_<x>_<y>（action: 0=down 1=up 2=move）
                let parts = gateName.split("_")
                if (parts.size >= 4) {
                    let action = UInt32.parse(parts[1])
                    let x = Float32.parse(parts[2])
                    let y = Float32.parse(parts[3])
                    let rc = unsafe { cjgui_ohos_test_inject_touch(action, x, y) }
                    result = "touch=${rc}"
                }
            }
            if (gateName == "GATE_REJECT_NEXT") {
                let r = unsafe { cjgui_ohos_test_gate_set_fail_next(1, 0) }
                let a = unsafe { cjgui_ohos_test_gate_fail_armed() }
                result = "set_fail_next=${r} armed_now=${a}"
            } else if (gateName == "GATE_FAIL_ACK_1") {
                let r = unsafe { cjgui_ohos_test_gate_set_fail_next(0, 1) }
                result = "set_fail_ack=${r}"
            } else if (gateName == "GATE_DEQUEUE_HOLD_30000") {
                let r = unsafe { cjgui_ohos_test_gate_set_dequeue_hold_ms(30000) }
                result = "set_dequeue_hold=${r}"
            } else if (gateName == "GATE_FLUSH_HOLD_30000") {
                let r = unsafe { cjgui_ohos_test_gate_set_flush_hold_ms(30000, -1) }
                result = "flush_hold=${r}"
            } else if (gateName == "GATE_HOLD_PERMIT_8000") {
                let r = unsafe { cjgui_ohos_test_gate_set_hold_permit(8000, -1) }
                result = "hold_permit=${r}"
            } else if (gateName == "GATE_HOLD_CREATE_8000") {
                let r = unsafe { cjgui_ohos_test_gate_set_hold_create(8000, -1) }
                result = "hold_create=${r}"
            } else if (gateName == "GATE_HOLD_CREATE_RET_8000") {
                let r = unsafe { cjgui_ohos_test_gate_set_hold_create_return(8000, -1) }
                result = "hold_create_return=${r}"
            } else if (gateName == "GATE_HOLD_DRAW_8000") {
                let r = unsafe { cjgui_ohos_test_gate_set_hold_draw(8000, -1) }
                result = "hold_draw=${r}"
            } else if (gateName == "GATE_HOLD_ADMIT_8000") {
                let r = unsafe { cjgui_ohos_test_gate_set_hold_admission(8000, -1) }
                result = "hold_admission=${r}"
            } else if (gateName == "GATE_SIM_RETIRED") {
                let r = unsafe { cjgui_ohos_test_simulate_surface_retired() }
                result = "sim_retired=${r}"
            } else if (gateName == "GATE_SIM_CREATED") {
                let r = unsafe { cjgui_ohos_test_simulate_surface_created() }
                result = "sim_created=${r}"
            } else if (gateName == "GATE_ACCEPT_THROW") {
                CJGUI_WINDOW_GATE_ACCEPTANCE_THROW = true
                result = "accept_throw armed"
            } else if (gateName == "GATE_ROLLBACK_THROW") {
                CJGUI_WINDOW_GATE_ROLLBACK_THROW = true
                result = "rollback_throw armed"
            } else if (gateName == "GATE_THROW_CLEAR") {
                CJGUI_WINDOW_GATE_ACCEPTANCE_THROW = false
                CJGUI_WINDOW_GATE_ROLLBACK_THROW = false
                result = "throw cleared"
            } else if (gateName == "GATE_A2_STATS") {
                let committed = unsafe { cjgui_ohos_test_settlement_committed() }
                let aborted = unsafe { cjgui_ohos_test_settlement_aborted() }
                let jf = unsafe { cjgui_ohos_test_gate_job_fail_count() }
                let af = unsafe { cjgui_ohos_test_gate_ack_fail_count() }
                let armed = unsafe { cjgui_ohos_test_gate_fail_armed() }
                let pair = unsafe { cjgui_ohos_permit_pair_packed() }
                let pa = pair >> 32
                let pr = pair & 0xFFFFFFFF
                result = "committed=${committed} aborted=${aborted} job_fails=${jf} ack_fails=${af} armed=${armed} permits=${pa}/${pr}"
            } else if (gateName == "GATE_CLEAR") {
                // 只解除「持有」类闸门；fail-next 是注入指令，不得被 CLEAR 抵消
                //（否则放行与注入同轮派发时注入永远打不中）。
                let r1 = unsafe { cjgui_ohos_test_gate_set_dequeue_hold_ms(0) }
                let r2 = unsafe { cjgui_ohos_test_gate_set_flush_hold_release() }
                let ra = unsafe { cjgui_ohos_test_gate_set_hold_permit(0, 0) }
                let rb = unsafe { cjgui_ohos_test_gate_set_hold_create(0, 0) }
                let rc2 = unsafe { cjgui_ohos_test_gate_set_hold_create_return(0, 0) }
                let rd = unsafe { cjgui_ohos_test_gate_set_hold_draw(0, 0) }
                let re = unsafe { cjgui_ohos_test_gate_set_hold_admission(0, 0) }
                if (r1 == 0 && ra == 0 && rb == 0 && rc2 == 0 && rd == 0 && re == 0) {
                    Hilog.info(0, TAG, "verify gate clear: a2 holds released")
                }
                let committed = unsafe { cjgui_ohos_test_settlement_committed() }
                let aborted = unsafe { cjgui_ohos_test_settlement_aborted() }
                let jf = unsafe { cjgui_ohos_test_gate_job_fail_count() }
                let af = unsafe { cjgui_ohos_test_gate_ack_fail_count() }
                result = "cleared=${r1}${r2} committed=${committed} aborted=${aborted} job_fails=${jf} ack_fails=${af}"
            }
            VerificationSeam.reportGateResult(gateId, result)
            Hilog.info(0, TAG, "verify gate ${gateName} -> ${result}")
        }
        // 外部请求 drain：每次只认领下一张票（Astra：不预标预算），
        // 认领→dispatch→complete 全部经票归属协议。
        var served: Int64 = 0
        while (served < 8) {
            let lease = OhosTransportBridge.claimNext()
            if (let Some(l) <- lease) {
                // 验证接缝的执行保持（未注册产物恒 0）：票据已认领（Executing、
                // 在途计数已加）但 dispatch 推迟，供「停止落在不可取消提交窗口」
                // 的确定性反例使用。到期自动放行，票据按真实终态结算。
                let holdMs = VerificationSeam.executionHoldRemainingMs()
                if (holdMs > 0) {
                    Hilog.info(0, TAG, "verify execution hold: dispatch withheld ${holdMs}ms")
                    sleep(Duration.millisecond * holdMs)
                }
                Hilog.info(0, TAG, "external payload dispatched (${l.payload.size} bytes)")
                let response = connection.dispatchPayload(l.payload)
                let _ = OhosTransportBridge.complete(l, response)
                served += 1
            } else {
                break
            }
        }
        // 外部 INVOKE 成功会置位刷新请求；connection 未 attach 到 host
        // （其 unix 传输在沙箱不可用），由宿主循环代为消费。
        if (connection.consumeWindowRefreshRequest()) {
            window.requestRefresh()
        }
        let _ = host.pumpOneTurn()
        ticks += 1
        APP_LOOP_TICKS.store(ticks)
    }
    // 关闭链（Sol 归属，每步唯一完成者）：
    //  1) 停止接单/认领（owner 已退出循环）
    //  2) 传输收敛：listener 退出 + 连接/票据全部终结
    //  3) 窗口会话关闭（owner 内容按应用生命周期契约保留在 owner 内）
    //  4) 渲染线程在自有线程 teardown surface/GPU context 后退出并 join
    //  5) 启动身份复位（渲染器代际已在请求时递增；本循环报告真实终态）
    OhosTransportBridge.requestStop()
    let transportClosed = OhosTransportBridge.awaitClosed(2000)
    let (queued, _qbytes, conns, inflight, lifecycle) = OhosTransportBridge.snapshotCounters()
    Hilog.info(0, TAG,
        "transport closing: closed=${transportClosed} queued=${queued} conns=${conns} inflight=${inflight} lifecycle=${lifecycle}")
    host.close()
    let shutdownStatus = unsafe { ohos_renderer_shutdown_render_thread() }
    let shutdownDone = unsafe { cjgui_ohos_renderer_shutdown_done() }
    Hilog.info(0, TAG,
        "host closed; stop_requested=${stopRequested} render_shutdown_status=${shutdownStatus} shutdown_done=${shutdownDone} ticks=${ticks}")
}
