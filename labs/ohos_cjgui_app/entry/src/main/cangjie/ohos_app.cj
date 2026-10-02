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
import std.time.*
import std.collection.ArrayList
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
foreign func cjgui_ohos_request_application_stop(): Int32
foreign func cjgui_ohos_renderer_shutdown_done(): Int32
foreign func cjgui_ohos_renderer_running(): Int32
foreign func cjgui_ohos_notify_owner_exit(reason: Int32): Unit
foreign func cjgui_ohos_trace_mark(code: Int32): Unit

// A1 矩阵：renderer test-gates 的 foreign 入口。两个产物变体都导出同名符号，
// 普通产物返回 -1（无闸门行为）；测试产物由 verify 探针经接缝命令驱动。
foreign func cjgui_ohos_test_gate_set_fail_next(jobs: Int32, acks: Int32): Int32
foreign func cjgui_ohos_test_gate_set_flush_hold_ms(ms: Int32, count: Int32): Int32
foreign func cjgui_ohos_test_gate_set_dequeue_hold_ms(ms: Int32): Int32
foreign func cjgui_ohos_test_inject_touch(action: UInt32, x: Float32, y: Float32): Int32
foreign func cjgui_ohos_test_gate_set_flush_hold_release(): Int32
foreign func cjgui_ohos_test_gate_job_fail_count(): Int32
foreign func cjgui_ohos_test_gate_fail_armed(): Int32
foreign func cjgui_ohos_test_gate_stage_held_packed(): Int64
foreign func cjgui_ohos_test_stub_arm(enable: Int64): Int32
foreign func cjgui_ohos_test_stub_hold_set(stage: Int32, gen: Int64, ms: Int32): Int32
foreign func cjgui_ohos_test_trigger_redraw(): Int32
foreign func cjgui_ohos_test_audit_negative_fixture_cj(): Int32
foreign func cjgui_ohos_test_stub_session_register_cj(gen: Int64, w: Int64, h: Int64): Int32
foreign func cjgui_ohos_test_stub_lease_retire(gen: Int64): Int32
foreign func cjgui_ohos_test_stub_release(): Int32
foreign func cjgui_ohos_test_stub_counts(gen: Int64): Int64
foreign func cjgui_ohos_test_stub_state(): Int64
foreign func cjgui_ohos_test_stub_disarm(): Int32
foreign func cjgui_ohos_test_platform_call_packed(): Int64
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
foreign func cjgui_ohos_test_image_hold_completion(resourceVersion: UInt64, held: Int32): Int32
foreign func cjgui_ohos_test_image_forget(resourceVersion: UInt64): Int32
foreign func cjgui_ohos_test_image_stats(out12: CPointer<Int64>): Int32
foreign func cjgui_ohos_test_image_stats_ext(out8: CPointer<Int64>): Int32
// A3：owner 就绪声明（渲染器转发到 entry 宿主桥的 ingress.appReady）。
foreign func cjgui_ohos_notify_app_ready(): Int32

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
    unsafe { cjgui_ohos_trace_mark(101) }
    cjguiOhosInfo("CjguiApp", "app_main_cangjie: ingress registered, running owner loop synchronously")
    unsafe { cjgui_ohos_trace_mark(102) }
    // A3（Sol 复核第 3 点）：不再 `spawn` 后立即返回。入口返回即代表
    // owner 已真实退出（停止接单 → 传输收敛 → 窗口会话关闭 → 渲染线程
    // teardown 并 join），使「已停止」有一个**可 join 的 owner 线程**判据，
    // 而不是依赖 detach 的引导线程或全局 shutdownDone。
    unsafe { cjgui_ohos_trace_mark(103) }
    ohosApplicationLoop()
    unsafe { cjgui_ohos_trace_mark(104) }
    return 0
}

// ---------------------------------------------------------------------------
// 应用循环（与 macOS 同源：同一 domain/controller + 同一宿主泵语义）
// ---------------------------------------------------------------------------

// 第九次复核 C：owner **统一清理尾部**——所有出口（Phase A 停止、
// host.start 失败、Phase B 正常结束）汇入此处：停止接单 → 传输收敛 →
// 按事实结束已启动 renderer → 终态日志。真正未启动的部件记 not_started，
// 不伪造成功 shutdown。
func ohosCleanupTail(reason: String): Bool {
    OhosTransportBridge.requestStop()
    let transportClosed = OhosTransportBridge.awaitClosed(2000)
    let (queued, _qbytes, conns, inflight, lifecycle) = OhosTransportBridge.snapshotCounters()
    let rendererStarted = unsafe { cjgui_ohos_renderer_running() } == 1
    var shutdownStatus: Int32 = -1
    var shutdownDone: Int32 = -1
    if (rendererStarted) {
        shutdownStatus = unsafe { ohos_renderer_shutdown_render_thread() }
        shutdownDone = unsafe { cjgui_ohos_renderer_shutdown_done() }
    }
    cjguiOhosInfo("CjguiApp",
        "cleanup tail [${reason}]: renderer_started=${rendererStarted} " +
        "shutdown_status=${shutdownStatus} shutdown_done=${shutdownDone} " +
        "transport_closed=${transportClosed} queued=${queued} conns=${conns} " +
        "inflight=${inflight} lifecycle=${lifecycle}")
    return transportClosed && queued == 0 && conns == 0 && inflight == 0 &&
        (!rendererStarted || (shutdownStatus == 0 && shutdownDone == 1))
}

// A1 矩阵：闸门命令派发（第八次复核链1：pre-surface 替身服务复用同一派发）。
func executeGateCommand(gateName: String): String {
    var result = "unknown_command"
    if (gateName.startsWith("TOUCH_")) {
        // D 夹具：TOUCH_<action>_<x>_<y>（action: 0=down 1=up 2=move）
        let parts = gateName.split("_")
        if (parts.size >= 4) {
            // 夹具约定 0=down 1=up 2=move → 渲染器 ingress 动作码
            // 37=BEGIN 38=UPDATE 39=END（此前直接透传 0/1/2，BEGIN 语义
            // 永不触发——触摸注入对焦点/指针路径实际上是惰性的，实测修复）。
            let raw = UInt32.parse(parts[1])
            var action = raw
            if (raw == 0) {
                action = 37
            } else if (raw == 1) {
                action = 39
            } else if (raw == 2) {
                action = 38
            }
            let x = Float32.parse(parts[2])
            let y = Float32.parse(parts[3])
            let rc = unsafe { cjgui_ohos_test_inject_touch(action, x, y) }
            result = "touch=${rc}"
        }
    }
    // 链2（Astra Q4）：替身适配器命令——STUB_<op> [参数]，经渲染线程真实
    // 路径驱动替身会话（替身自有对象/租约，不接收真实 window 指针）。
    if (gateName == "STUB_ARM") {
        let r = unsafe { cjgui_ohos_test_stub_arm(1) }
        result = "stub_arm=${r}"
    } else if (gateName.startsWith("STUB_HOLD ")) {
        // 第九次复核 A4：阻塞配置独立命令（任意时刻可设，不经准入）。
        let parts = gateName.split(" ")
        if (parts.size >= 4) {
            let r = unsafe { cjgui_ohos_test_stub_hold_set(Int32.parse(parts[1]),
                Int64.parse(parts[2]), Int32.parse(parts[3])) }
            result = "stub_hold=${r}"
        }
    } else if (gateName == "GATE_REDRAW") {
        // 第九次复核 A 验收：经真实 redraw 路径驱动（替身句柄由其 backend 分发）。
        let r = unsafe { cjgui_ohos_test_trigger_redraw() }
        result = "redraw=${r}"
    } else if (gateName == "GATE_PC_CALLS") {
        // 平台调用生命周期计数（按代 enter/exit packed）——零错类型调用断言读数。
        let p = unsafe { cjgui_ohos_test_platform_call_packed() }
        result = "pc_calls=${p}"
    } else if (gateName == "GATE_AUDIT_FIXTURE") {
        // 第九次复核 B：NEG4 隔离夹具（拦截 Reference 逐命令断言）。
        let r = unsafe { cjgui_ohos_test_audit_negative_fixture_cj() }
        result = "audit_fixture=${r}"
    } else if (gateName.startsWith("STUB_SESSION ")) {
        // 第九次复核 A3：注册宿主表替身会话（active 即租约）。
        let parts = gateName.split(" ")
        if (parts.size >= 4) {
            let r = unsafe { cjgui_ohos_test_stub_session_register_cj(Int64.parse(parts[1]),
                Int64.parse(parts[2]), Int64.parse(parts[3])) }
            result = "stub_session=${r}"
        }
    } else if (gateName.startsWith("STUB_RETIRE ")) {
        let parts = gateName.split(" ")
        if (parts.size >= 2) {
            let r = unsafe { cjgui_ohos_test_stub_lease_retire(Int64.parse(parts[1])) }
            result = "stub_retire=${r}"
        }
    } else if (gateName == "STUB_RELEASE") {
        let r = unsafe { cjgui_ohos_test_stub_release() }
        result = "stub_release=${r}"
    } else if (gateName.startsWith("STUB_COUNTS ")) {
        let parts = gateName.split(" ")
        if (parts.size >= 2) {
            let packed = unsafe { cjgui_ohos_test_stub_counts(Int64.parse(parts[1])) }
            result = "stub_counts=${packed}"
        }
    } else if (gateName == "STUB_STATE") {
        let st = unsafe { cjgui_ohos_test_stub_state() }
        result = "stub_state=${st}"
    } else if (gateName == "STUB_DISARM") {
        let r = unsafe { cjgui_ohos_test_stub_disarm() }
        result = "stub_disarm=${r}"
    }
    if (gateName.startsWith("GATE_IMAGE_HOLD ") || gateName.startsWith("GATE_IMAGE_RELEASE ") ||
        gateName.startsWith("GATE_IMAGE_FORGET ")) {
        let parts = gateName.split(" ")
        if (parts.size == 2) {
            try {
                let version = UInt64.parse(parts[1])
                if (parts[0] == "GATE_IMAGE_FORGET") {
                    let r = unsafe { cjgui_ohos_test_image_forget(version) }
                    result = "image_forget_version=${version} rc=${r}"
                } else {
                    let held: Int32 = if (parts[0] == "GATE_IMAGE_HOLD") { 1 } else { 0 }
                    let r = unsafe { cjgui_ohos_test_image_hold_completion(version, held) }
                    result = "image_hold_version=${version} held=${held} rc=${r}"
                }
            } catch (_) {
                result = "image_hold_invalid_version"
            }
        } else {
            result = "image_hold_invalid_version"
        }
    } else if (gateName == "GATE_IMAGE_STATS" || gateName == "GATE_IMAGE_STATS_EXT") {
        let extended = gateName == "GATE_IMAGE_STATS_EXT"
        let count: Int64 = if (extended) { 8 } else { 12 }
        let stats = unsafe { LibC.malloc<Int64>(count: count) }
        if (stats.isNull()) {
            result = "image_stats_allocation_failed"
        } else {
            let r = if (extended) {
                unsafe { cjgui_ohos_test_image_stats_ext(stats) }
            } else {
                unsafe { cjgui_ohos_test_image_stats(stats) }
            }
            result = "image_stats_rc=${r}"
            if (r == 0) {
                if (extended) {
                    let names = ["encodedReadMicros", "decoderActiveBytes", "decoderPeakBytes",
                                 "reservationBytes", "peakTrackedBytes", "bitmapCreateMicros",
                                 "bitmapDestroyMicros", "idleCacheBytes"]
                    for (index in 0..8) {
                        result += " ${names[index]}=${unsafe { stats.read(Int64(index)) }}"
                    }
                } else {
                    let names = ["decodeStarts", "encodedReadBytes", "decodeMicros", "cacheHits",
                                 "inFlight", "queued", "awaiting", "readyRecords", "residentBytes",
                                 "bitmapCreates", "bitmapDestroys", "staleDiscards"]
                    for (index in 0..12) {
                        result += " ${names[index]}=${unsafe { stats.read(Int64(index)) }}"
                    }
                }
            }
            unsafe { LibC.free(stats) }
        }
    } else if (gateName == "GATE_REJECT_NEXT") {
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
    } else if (gateName == "GATE_FLUSH_HOLD_RELEASE") {
        // 第七次复核 A2：专用释放操作必须真实接通（此前回包
        // verify_unknown_op——命令从未存在）。
        let r = unsafe { cjgui_ohos_test_gate_set_flush_hold_release() }
        result = "flush_release=${r}"
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
        let stageHeld = unsafe { cjgui_ohos_test_gate_stage_held_packed() }
        result = "committed=${committed} aborted=${aborted} job_fails=${jf} ack_fails=${af} armed=${armed} permits=${pa}/${pr} stageHeld=${stageHeld}"
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
            cjguiOhosInfo("CjguiApp", "verify gate clear: a2 holds released")
        }
        let committed = unsafe { cjgui_ohos_test_settlement_committed() }
        let aborted = unsafe { cjgui_ohos_test_settlement_aborted() }
        let jf = unsafe { cjgui_ohos_test_gate_job_fail_count() }
        let af = unsafe { cjgui_ohos_test_gate_ack_fail_count() }
        result = "cleared=${r1}${r2} committed=${committed} aborted=${aborted} job_fails=${jf} ack_fails=${af}"
    }
    return result
}
// 单轮服务：闸门命令派发 + 外部票据认领/dispatch/complete（Phase A/B 共用）。
func serveOnce(connection: CjguiSharedOperationExternalConnection): Bool {
    var served = false
    let (gateId, gateName) = VerificationSeam.pendingGateCommand()
    if (gateId != 0) {
        served = true
        let result = executeGateCommand(gateName)
        VerificationSeam.reportGateResult(gateId, result)
        cjguiOhosInfo("CjguiApp", "verify gate ${gateName} -> ${result}")
    }
    var n: Int64 = 0
    while (n < 8) {
        let lease = OhosTransportBridge.claimNext()
        if (let Some(l) <- lease) {
            let holdMs = VerificationSeam.executionHoldRemainingMs()
            if (holdMs > 0) {
                sleep(Duration.millisecond * holdMs)
            }
            let response = connection.dispatchPayload(l.payload)
            let _ = OhosTransportBridge.complete(l, response)
            served = true
            n += 1
        } else {
            break
        }
    }
    return served
}
func ohosApplicationLoop(): Unit {
    var ticks: Int64 = 0
    // 第七次复核 Q3：域/外部连接/传输监听全部前移到 surface 等待之前——
    // KnownShimNoRef 拒绝发布 degradedActive 后 surface 永不就绪，owner/
    // 传输替身测试（外部协议在等待窗口内服务）仍可用；不做此前移则替身
    // 通道一并不可达（ConnectionReset 实证）。
    let bridgeGeneration = APP_LOOP_TICKS.load() + 1
    unsafe { cjgui_ohos_trace_mark(201) }
    let _ = OhosTransportBridge.start(bridgeGeneration, 7856)
    unsafe { cjgui_ohos_trace_mark(202) }
    let _ = spawn {
        OhosTransportBridge.listen(7856)
    }
    // 第八次复核链1：启动准备与替身服务不依赖 surface——
    // 域/控制器/外部连接（无 window 重载）与传输监听先于 surface 等待建立；
    // KnownShimNoRef 档下 owner/传输替身持续服务（无渲染，明确发布后端不可用），
    // surface 就绪后无缝创建 host 进入渲染（真实引用平台不受影响）。
    let domain = CjguiSettingsCounterDomain()
    let controller = CjguiSettingsCounterController(domain)
    // 链1：三参重载——changeDomain 必须给（否则 visibleActions 无业务动作，
    // hasSafeAuthorization 的 scope 核对失败 → unauthorized_caller，实测）。
    let connection = CjguiSharedOperationExternalConnection(domain, settingsCounterAuthorization(), domain)
    // The region and its candidate table belong to this owner instance. Register
    // before Surface readiness so discovery and a pending candidate remain
    // available through the same TCP owner queue during Phase A.
    let generatedReady = connection.enableGeneratedUiProvider(controller.generatedUiRegion())
    if (!generatedReady) {
        unsafe { cjgui_ohos_trace_mark(204) }
        cjguiOhosError("CjguiApp", "generated provider registration failed")
        let _ = ohosCleanupTail("generated provider registration failed")
        unsafe { cjgui_ohos_notify_owner_exit(1) }
        return
    }
    unsafe { cjgui_ohos_trace_mark(203) }

    // Phase A：替身服务循环——surface 未就绪也持续服务闸门命令、外部请求
    // 与停止（不再空等 60s 后退出；KnownShimNoRef 档按 Astra Q3 持续替身运行）
    var surfaceReady = false
    var standinAnnounced = false
    var standinStop = false
    while (!surfaceReady) {
        if (unsafe { cjgui_ohos_application_stop_requested() } == 1) {
            standinStop = true
            break
        }
        // 链1：停止可先服务——close 请求在替身阶段同样可达。无 host/窗口
        // 可关，close 意图即应用停止：置停止请求，下一轮循环边界退出，
        // 走同一收敛路径（不因 surface 未发布而不可停，实测修复 C6）。
        if (VerificationSeam.consumeWindowCloseRequest()) {
            cjguiOhosInfo("CjguiApp", "stand-in close: no host yet; close intent = application stop")
            let _ = unsafe { cjgui_ohos_request_application_stop() }
        }
        let _ = serveOnce(connection)
        surfaceReady = (unsafe { cjgui_ohos_surface_ready() } == 1)
        if (!surfaceReady) {
            if (!standinAnnounced) {
                cjguiOhosInfo("CjguiApp", "surface pending; owner service active")
                standinAnnounced = true
            }
            sleep(Duration.millisecond * 50)
            ticks += 1
            APP_LOOP_TICKS.store(ticks)
        }
    }
    if (standinStop && !surfaceReady) {
        // 第九次复核 C：替身阶段停止走统一清理尾部
        // STUB_ARM 等测试路径启动过 renderer 时按事实 shutdown；成功与否
        // 在清理后声明，避免失败的收尾被宿主当作有序退出。
        controller.generatedUiRegion().rejectPendingOnClose()
        let cleaned = ohosCleanupTail("stand-in stopped")
        unsafe { cjgui_ohos_notify_owner_exit(if (cleaned) { 0 } else { 1 }) }
        return
    }
    unsafe { cjgui_ohos_trace_mark(205) }
    cjguiOhosInfo("CjguiApp", "surface ready; starting settings-counter host")
    // A1 首帧反例：首帧 PENDING 由启动参数重放的 flush 闸门制造（票据已发、
    // 提交在 Committing 内被按住 → 提交等待超时返回 PENDING，StartingPending
    // 可观察）。此处不再按 dequeue 闸门——那会让首帧在票据分配前被扣住，
    // 触发「PENDING 无票据」协议缺口路径（实测导致 host start failed）。

    let host = CjguiMacosApplicationHost(controller,
        configuration: CjguiMacosApplicationWindowConfiguration("设置与计数", 720u32, 1400u32))
    let window = host.window()
    controller.generatedUiRegion().attachWindow(window)
    let progressReady = connection.enableWindowProgressReads(window)
    if (!progressReady) {
        cjguiOhosWarn("CjguiApp", "window progress reads unavailable")
    }
    // 注意：不调用 connection.start()——其私有 unix 传输硬编码 /tmp，
    // OHOS 沙箱不可写。外部通道走 ohos_transport.cj 的 TCP→dispatchPayload 桥。
    unsafe { cjgui_ohos_trace_mark(206) }
    if (!host.start()) {
        unsafe { cjgui_ohos_trace_mark(207) }
        let progress = window.windowProgress()
        cjguiOhosError("CjguiApp",
            "host start progress: pendingRefreshReason=${progress.pendingRefreshReason} " +
            "lastNativeFailure=${progress.lastNativeFailure} " +
            "presentationState=${progress.presentationState} " +
            "acceptedSceneVersion=${progress.acceptedSceneVersion}")
        // 第九次复核 C：启动失败同样汇入统一清理尾部（明确 failed 可重试），
        // 不再绕过传输/renderer 收尾。
        cjguiOhosError("CjguiApp", "host start failed")
        unsafe { cjgui_ohos_notify_owner_exit(1) }   // 启动失败
        controller.generatedUiRegion().rejectPendingOnClose()
        host.close()
        let _ = ohosCleanupTail("host start failed")
        return
    }
    unsafe { cjgui_ohos_trace_mark(208) }
    cjguiOhosInfo("CjguiApp", "host started; pumping turns")
    // H2：滚动物理策略是**窗口声明**（不是全局开关）。手写与公开生成的
    // scrollArea 走同一个可发现 token、同一套校验与公布；非法 token 具名拒绝
    // 并保持原配置。
    let physicsDeclared = window.configureScrollPhysicsToken("experimental_exponential")
    let physics = window.scrollPhysicsInfo()
    cjguiOhosInfo("CjguiApp", "scroll physics declared=${physicsDeclared} " +
        "declared_token=${physics.declared} effective=${physics.effective} support=${physics.support}")
    cjguiOhosInfo("CjguiApp", "generated_work phase=host_started ${controller.generatedUiRegion().testWorkCounts()}")

    // 停止协议（Sol 归属）：surface 卸载只退役租约并保留 owner；
    // Ability 真正关闭由宿主置停止请求，owner 在轮间安全边界退出循环，
    // 之后依次：停止接单 → 传输收敛 → 渲染线程 teardown → 身份复位。
    //
    // A3：进入泵轮前先向宿主声明「已启动」。宿主据此把启动状态从 starting
    // 推进到 running；就绪必须由 owner 自己声明，宿主不按时间或入口返回推断。
    let _ = unsafe { cjgui_ohos_notify_app_ready() }
    cjguiOhosInfo("CjguiApp", "owner declared app ready; entering pump loop")
    var stopRequested = false
    var faultAnnounced = false
    while (host.isOpen()) {
        // A1：终止收敛命名故障对外可见（一次播报；空串=无未收敛故障）。
        if (!faultAnnounced) {
            let fault = host.windowSettlementFault()
            if (fault != "") {
                cjguiOhosError("CjguiApp", "settlement fault: ${fault}")
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
            cjguiOhosInfo("CjguiApp", "verify close: host.close() via production path")
            host.close()
        }
        // A1 矩阵：闸门命令 + 外部票据单轮服务（executeGateCommand 独立成
        // 函数，供 pre-surface 替身阶段复用——第八次复核链1）。
        let _ = serveOnce(connection)
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
                    cjguiOhosInfo("CjguiApp", "verify execution hold: dispatch withheld ${holdMs}ms")
                    sleep(Duration.millisecond * holdMs)
                }
                cjguiOhosInfo("CjguiApp", "external payload dispatched (${l.payload.size} bytes)")
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
        // H2：滚动活动由**共同宿主**在 pumpOneTurn 内推进（changed→刷新、
        // active→有界唤醒）；样例本地 step 已退役——宿主与样例各推一次会把
        // 活动按双倍速率推进。下方诊断只读，不再 step。
        // C（触摸包指导接续）：屏外 reveal 的显式目标导航——应用控制器在
        // ACTIVATE 中挂起的语义焦点请求，在 pump 后经窗口公共
        // focusAcceptedSemanticNode 提交（内部 reveal→新 accepted→commit 后
        // flush→focusProjectedNode→平台编辑上下文）。
        if (let Some(semantic) <- controller.takePendingFocusRequest()) {
            let focused = window.focusAcceptedSemanticNode(semantic)
            cjguiOhosInfo("CjguiApp", "nav focus ${semantic} -> focused=${focused}")
        }
        ticks += 1
        APP_LOOP_TICKS.store(ticks)
        if (ticks % 500 == 0) {
            // 诊断只查询，不再额外 step（此前第二份 step 会在日志里推进活动，
            // 制造与生产循环无关的副作用）。
            cjguiOhosInfo("CjguiApp", "inertia check: active=${window.hasActiveWindowActivities()} " +
                "bindings=${window.acceptedScrollBindingCount()} " +
                "declared=${window.scrollPhysicsInfo().declared} " +
                "effective=${window.scrollPhysicsInfo().effective}")
        }
        if (ticks % 200 == 0) {
            cjguiOhosInfo("CjguiApp", "generated_work tick=${ticks} ${controller.generatedUiRegion().testWorkCounts()}")
        }
    }
    // 关闭链（Sol 归属，每步唯一完成者）：
    //  1) 停止接单/认领（owner 已退出循环）
    //  2) 传输收敛：listener 退出 + 连接/票据全部终结
    //  3) 窗口会话关闭（owner 内容按应用生命周期契约保留在 owner 内）
    //  4) 渲染线程在自有线程 teardown surface/GPU context 后退出并 join
    //  5) 启动身份复位（渲染器代际已在请求时递增；本循环报告真实终态）
    // 第九次复核 C：Phase B 正常结束汇入统一清理尾部（renderer 必已启动，
    // shutdown 真实执行；字段与渲染档终态判据兼容）。
    OhosTransportBridge.requestStop()
    let transportClosed = OhosTransportBridge.awaitClosed(2000)
    let (queued, _qbytes, conns, inflight, lifecycle) = OhosTransportBridge.snapshotCounters()
    cjguiOhosInfo("CjguiApp",
        "transport closing: closed=${transportClosed} queued=${queued} conns=${conns} inflight=${inflight} lifecycle=${lifecycle}")
    host.close()
    let shutdownStatus = unsafe { ohos_renderer_shutdown_render_thread() }
    let shutdownDone = unsafe { cjgui_ohos_renderer_shutdown_done() }
    // Committing 超时的原票据在平台 Flush 返回前仍是 PENDING。host.close()
    // 只记录 close 意图；渲染线程停止并不替 owner 查询、ACK 与销毁会话。
    // 在同一 owner 上有界推进原窗口的前置结算门，直到 close 意图被消费。
    var closeWaitMs: Int64 = 0
    while (window.isOpen() && closeWaitMs < 10000) {
        let _ = window.refreshIfNeeded()
        if (window.isOpen()) {
            sleep(Duration.millisecond * 10)
            closeWaitMs += 10
        }
    }
    let windowClosed = !window.isOpen()
    cjguiOhosInfo("CjguiApp", "window close settlement: closed=${windowClosed} waited_ms=${closeWaitMs}")
    controller.generatedUiRegion().rejectPendingOnClose()
    let tailCleaned = ohosCleanupTail("phase-b closed")
    let orderly = tailCleaned && shutdownStatus == 0 && shutdownDone == 1 && windowClosed && !host.isOpen()
    unsafe { cjgui_ohos_notify_owner_exit(if (orderly) { 0 } else { 1 }) }
    cjguiOhosInfo("CjguiApp",
        "host closed; stop_requested=${stopRequested} render_shutdown_status=${shutdownStatus} shutdown_done=${shutdownDone} " +
        "tail_cleaned=${tailCleaned} owner_orderly=${orderly} ticks=${ticks}")
}
