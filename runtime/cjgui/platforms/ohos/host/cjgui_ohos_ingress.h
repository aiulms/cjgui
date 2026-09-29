// CJGUI OHOS ingress ABI（entry 桥与渲染器共享的手工 C 契约）。
// 两侧结构布局必须一致；渲染器经函数指针消费，不做跨库符号解析。

#ifndef CJGUI_OHOS_INGRESS_H
#define CJGUI_OHOS_INGRESS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// 原始触摸动作（对齐 cjgui_internal_renderer.h 的指针事件词表 37..40）
enum {
    CJGUI_OHOS_TOUCH_BEGIN = 37,
    CJGUI_OHOS_TOUCH_UPDATE = 38,
    CJGUI_OHOS_TOUCH_END = 39,
    CJGUI_OHOS_TOUCH_CANCEL = 40,
};

struct CjguiOhosIngress {
    // surface lease 快照：active 返回 1 并填充全部输出；window 指针仅用于
    // OH_Drawing_SurfaceCreateOnScreen，不得解引用或长期保存。
    int (*surfaceActive)(void **outWindow, uint64_t *outGeneration, int32_t *outWidth,
                         int32_t *outHeight, double *outDensity,
                         uint64_t *outGeometryRevision);
    // 出队一个原始触摸；返回 1 有事件 / 0 空 / -1 旧代事件已受控丢弃。
    int (*touchDequeue)(uint32_t *outAction, float *outX, float *outY, uint64_t *outGeneration);
    // Frozen identity of this individual raw sample. None of these values may
    // be reconstructed from the currently active Surface or latest BEGIN.
    int (*touchDequeueEx)(uint32_t *outAction, float *outX, float *outY,
                          uint64_t *outAppInstance, uint64_t *outComponentInstance,
                          uint64_t *outGeneration, int64_t *outPointerId,
                          uint64_t *outGestureEpoch, int64_t *outTimestampNs,
                          uint32_t *outTimeSource);
    // 前后台观察：1 前台 / 0 后台。
    int (*foregroundLevel)();
    // 租约代际复核（退役屏障的判据）：返回 1 = 该代仍是宿主当前有效 lease，
    // 0 = 已退役。渲染器在绘制前与 Flush 后各核对一次，旧代不得晋升 accepted。
    // 为零时渲染器退回「无租约观察」行为（仅测试/无宿主环境）。
    int (*leaseValid)(uint64_t generation);

    // --- A2：surface 使用许可（RAII，覆盖创建/绘制/Flush/缓存/redraw/teardown）---
    //
    // 背景（Sol 复核）：只持有 NativeWindow 引用只保证**对象寿命**，不能证明
    // 渲染线程在创建、绘制、Flush、缓存 surface、redraw、拆除的整个使用期内都
    // 是安全的。因此宿主为每一代 surface 维护独立记录，渲染线程必须在**同一把
    // 宿主锁内**核对完整身份并取得一份不可复制的使用许可，直到该代真正拆除
    // （OH_Drawing_SurfaceDestroy + GPU 资源释放）才归还。
    //
    // 取得：身份不符、该代已退役、或 native 引用未成功持有时返回 0（不得取得）。
    // 成功时填出五元身份中的三项（appInstance/componentInstance/geometryRevision）
    // 供渲染器留证与后续复核；surfaceGeneration 即入参 generation。
    int (*surfacePermitAcquire)(uint64_t generation, uint64_t *outAppInstance,
                               uint64_t *outComponentInstance, uint64_t *outGeometryRevision);

    // --- 第九次复核 A3：替身会话表（宿主 SurfaceRecord 生产语义）---
    // 注册 active 替身会话（backend=1，window 为非空哨兵）；身份/准入/退役
    // 规则与真实记录同一套。返回 0 成功；-2 代际冲突。
    int (*stubSessionRegister)(int64_t generation, int64_t width, int64_t height);
    // 生产退役路径（与真实 destroyed 同一实现）。返回 0 成功；-2 无活动会话。
    int (*stubSessionRetire)(int64_t generation);
    // 只读：当前 active 替身会话数。
    int (*stubSessionActive)(void);
    // 第九次复核 B：NEG4 隔离夹具（拦截 Reference/Create 逐命令断言）。
    int (*auditNegativeFixture)(void);
    // 第九次复核 A（零错类型调用）：按代际返回后端类型（0=真实 XComponent，
    // 1=替身会话）。渲染器据此分派——替身会话的假地址**绝不**进真实平台库。
    int (*sessionBackend)(uint64_t generation);
    // 归还：返回归还后该代**仍持有**的许可数。返回 0 表示已无任何使用者，
    // 宿主方可串行归还原生引用（由宿主在 UI 线程完成，不由渲染线程直接调用）。
    int (*surfacePermitRelease)(uint64_t generation);

    // --- A2：拆除确认回传（渲染线程 → 宿主）---
    //
    // 渲染线程在**真实结束使用**之后调用一次：该代 surface 已 OH_Drawing_SurfaceDestroy、
    // 平台/GPU 资源已释放、使用许可已归还。宿主收到后才在 UI 线程串行归还
    // NativeWindow 引用——这是引用归还的**唯一**判据，不以等待时长或
    // busyGeneration 之类的推测值代替。
    //
    // 宿主必须做代际去重：重复或迟到的通知（含对已拆除代的再次通知）不得
    // 造成重复归还。该回调从渲染线程发起，宿主实现须自行切换到 UI 线程。
    void (*surfaceTornDown)(uint64_t generation);

    // --- A3：owner 就绪声明（owner 线程 → 宿主）---
    //
    // 应用循环在**已完成启动**（surface 就绪、宿主窗口会话已建立、
    // 传输 listener 已起）并即将进入泵轮时调用一次。宿主据此把启动状态
    // 从 starting 推进到 running。
    //
    // 为什么需要它：`cjgui_ohos_app_main` 现在是**同步**跑完整个 owner 循环
    // 才返回（见 ohos_app.cj），因此「入口返回」只说明 owner 已退出，不能用它
    // 判断「已启动」。就绪必须由 owner 自己声明，不能由宿主按时间猜。
    void (*appReady)();

    // --- A1/A2 受控模拟（仅验证链路使用）---
    // 渲染器 export（cjgui_ohos_test_simulate_surface_retired/created）转回
    // 宿主执行**真实**的 surface 退役/重发布逻辑；宿主未注册时为空。
    int (*simulateSurfaceRetired)(void);
    int (*simulateSurfaceCreated)(void);
    // D 夹具：探针触摸注入（宿主推入触摸队列，带当前代际）。
    int (*injectTouch)(uint32_t action, float x, float y);
};

#ifdef __cplusplus
}
#endif

#endif  // CJGUI_OHOS_INGRESS_H
