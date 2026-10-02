import { hilog } from '@kit.PerformanceAnalysisKit';
import { display } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import inputMethod from '@ohos.inputMethod';
import entryNapi from 'libentry.so';
// 官方互操作导入：经 ark_interop_loader 加载仓颉模块并完成运行时初始化。
import { probeRuntime, probeMagic } from 'libcjgui_app.so';
import { CjguiTextProxyRegistry, CjguiTextProxyMount, CjguiTextProxyBridge, CjguiProxyInstallTask as ProxyRestoreTask } from '../proxy/cjgui-text-proxy';
import { CjguiTextSelectionMenu, CjguiMenuSnapshot } from '../proxy/cjgui-text-menu';

const TAG: string = 'CjguiApp';
const DOMAIN: number = 0x0000;

// 渲染器焦点请求负载：只带不透明上下文编号、字段名与动作类型，平台不解释几何。
// action 缺省视为 "focus"（向后兼容无 action 的旧负载）。
// action="caret"：native 移动了落点（命中/长按全选/编辑命令），载荷带该 UTF-16
// 选区，由壳装回当前代理并经组件观测收口。
interface ImeFocusPayload {
  action?: string;
  context: number;
  field: string;
  oldContext?: number;
  selStart?: number;
  selEnd?: number;
}

interface ImeReconcilePending {
  oldMount: CjguiTextProxyMount;
  newContext: number;
  baseVersion: number;
  nodeId: number;
  sessionToken: number;
  appInstance: number;
  disappeared: boolean;
}

// 上下文快照（来自 ohos_renderer_ime_context_json）。
// 平台据此初始化代理：值、几何、字号、选区、基版本都来自 owner，
// 平台不凭空造初值，也不把字段名/几何写死在 ArkTS 里。
interface ImeSnapshot {
  context: number;
  field: string;
  nodeId: number;
  x: number;
  y: number;
  width: number;
  height: number;
  fontSize: number;
  density: number;
  selStart: number;
  selEnd: number;
  generation: number;
  sessionToken: number;
  baseVersion: number;
  mode: string;
  text: string;
  inputCapabilities?: ImeInputCapabilities;
}

interface ImeInputCapabilities {
  fullDraft: string;
  selectionUtf16: string;
  markedRange: string;
  markedRangeObserved: boolean;
  cancelEvent: string;
}

// C：桥接适配器（ArkTS 严格模式要求类实现，不接受对象字面量）。
class EntryNapiTextProxyBridge implements CjguiTextProxyBridge {
  grapheme(contextId: number, text: string, offset16: number): string {
    return entryNapi.imeGraphemeRange(text, offset16, contextId) as string;
  }

  preview(contextId: number, text: string): string {
    return entryNapi.imePreviewText(text, contextId) as string;
  }
  // 第九次复核 §E：组合范围桥接（napi imePreviewRange）
  previewRange(contextId: number, text: string, start: number, end: number): string {
    const rc: string = (entryNapi.imePreviewRange(text, start, end, contextId) as string) ?? '1';
    return rc;
  }

  commit(contextId: number, text: string): string {
    return entryNapi.imeCommitText(text, contextId) as string;
  }

  finish(contextId: number): string {
    return entryNapi.imeFinishEditing(contextId) as string;
  }

  logWarn(msg: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', msg);
  }

  logInfo(msg: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', msg);
  }
}

@Entry
@Component
struct Index {
  @State status: string = 'CJGUI host idle';
  private imageInstall: Promise<void> | null = null;
  private hostStartPending: boolean = false;

  // Rawfiles are application assets. They are installed once into this app's
  // private filesDir before the Cangjie owner/renderer is allowed to start.
  private async installImages(): Promise<void> {
    const context = getContext(this);
    for (const name of ['cjgui_image_v1.png', 'cjgui_image_v2.png']) {
      let declaredSize: number = 0;
      try {
        const descriptor = await context.resourceManager.getRawFd(name);
        declaredSize = descriptor.length;
        await context.resourceManager.closeRawFd(name);
      } catch (e) {
        throw new Error(`image_asset_descriptor_failed:${name}:${String(e)}`);
      }
      if (!Number.isSafeInteger(declaredSize) || declaredSize < 64 || declaredSize > 131072) {
        throw new Error(`image_asset_size_rejected:${name}:${declaredSize}`);
      }
      let bytes: Uint8Array;
      try {
        bytes = await context.resourceManager.getRawFileContent(name);
      } catch (e) {
        throw new Error(`image_asset_read_failed:${name}:${String(e)}`);
      }
      if (bytes.byteLength !== declaredSize || bytes[0] !== 137 || bytes[1] !== 80 ||
        bytes[2] !== 78 || bytes[3] !== 71) {
        throw new Error(`image_asset_content_rejected:${name}:${bytes.byteLength}`);
      }
      const output = `${context.filesDir}/${name}`;
      const pending = `${output}.pending`;
      let file: fileIo.File;
      try {
        file = await fileIo.open(pending, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE |
          fileIo.OpenMode.TRUNC);
        try {
          let written: number = 0;
          while (written < bytes.byteLength) {
            const remaining: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset + written,
              bytes.byteOffset + bytes.byteLength);
            const amount = await fileIo.write(file.fd, remaining);
            if (amount <= 0 || amount > remaining.byteLength) {
              throw new Error(`short_write:${amount}`);
            }
            written += amount;
          }
          await fileIo.fsync(file.fd);
        } finally {
          await fileIo.close(file);
        }
        await fileIo.rename(pending, output);
      } catch (e) {
        throw new Error(`image_asset_install_failed:${name}:${String(e)}`);
      }
      hilog.info(DOMAIN, TAG, 'image asset installed %{public}s bytes=%{public}d', name, declaredSize);
    }
  }

  private async startHostWithImages(): Promise<void> {
    if (this.hostStartPending) { return; }
    this.hostStartPending = true;
    try {
      if (this.imageInstall === null) { this.imageInstall = this.installImages(); }
      await this.imageInstall;
      if (!this.surfaceMounted) { return; }
      entryNapi.startHost(getContext(this).filesDir);
    } catch (e) {
      this.imageInstall = null;
      this.status = `image install failed: ${String(e)}`;
      hilog.error(DOMAIN, TAG, 'image assets not ready; host not started: %{public}s', String(e));
    } finally {
      this.hostStartPending = false;
    }
  }
  // 第九次复核 B：NEG4 隔离夹具（拦截 Reference 逐命令断言）在页面构建时
  // 自动执行一次，结果写 hilog（audit fixture: PASS/FAIL）供探针断言。
  aboutToAppear(): void {
    // 延迟 2s：错开启动期渲染管线对真实 window 的 Reference（夹具只允许
    // 自己的调用进入计数窗口）。
    setTimeout(() => {
      try {
        const rc: number = entryNapi.auditNegativeFixture() as number;
        hilog.info(DOMAIN, TAG, 'audit fixture: rc=%{public}d', rc);
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'audit fixture unavailable: %{public}s', String(e));
      }
    }, 2000);
  }

  @State probeResult: string = '';
  // 工作包 D：条件挂载/卸载 XComponent，驱动真实的 surface 销毁/重建回调。
  @State surfaceMounted: boolean = true;
  // D：resize 驱动入口——切换 XComponent 宽度触发 onSurfaceChanged（几何修订）。
  @State surfaceWide: boolean = true;

  // 通用文字代理状态：
  //  imeCtx == 0 表示没有活动编辑上下文（代理不挂载）。
  //  代理的值/几何/字段名全部来自上下文快照，切换字段只换 context 编号。
  @State imeCtx: number = 0;
  @State imeField: string = '';
  @State imeText: string = '';
  @State imeX: number = 0;
  @State imeY: number = 0;
  @State imeW: number = 0;
  @State imeH: number = 0;
  // 最近一次已收尾的上下文编号，用于「晚回调必须被拒」的负对照。
  @State imeLastClosedCtx: number = 0;
  @State imeLastCommitRc: string = '-';
  @State imeProjection: string = 'editing context: -';
  @State imeCapabilities: string = 'input capabilities: pending context';
  // 身份对象保持普通字段，避免 @State 对 class 包装后破坏引用相等；
  // imeCtx 是挂载/卸载的响应式开关，@Builder 仍捕获本次身份。
  private imeMount: CjguiTextProxyMount | null = null;
  private mountedBaseVersion: number = 0;
  private mountedNodeId: number = 0;
  // A3：宿主生命周期读数（phase / rendererDone / started / seam / 原生引用配平）。
  @State hostState: string = 'host state: -';
  // 验证接缝是否存在（= 测试产物）。普通产物为 false，UI 上不出现停止入口。
  @State verifySeam: boolean = false;

  private cycling: boolean = false;
  // 隐藏代理是否已获得 ArkUI 焦点（onFocus/onBlur 维护）；驱动聚焦重试与
  // showTextInput 的单次触发，不参与渲染，无需 @State。
  private proxyFocused: boolean = false;
  // 旧 TextInput 必须真正卸载后才从外部换版的新 context 重新挂载。
  private pendingReconcile: ImeReconcilePending | null = null;
  // native 落点安装槽（native→平台）。两个来源：挂载时按上下文快照装初值；native
  // 推 action=caret（命中、长按全选、编辑命令移动了落点）时装新值。平台把新聚焦
  // TextInput 的光标重置到末尾（华为 FAQ），不装回代理就会覆盖 native 刚落账的
  // caret/选区，人的下一次键入落在代理的旧偏移上。安装结果一律由组件自己的
  // onTextSelectionChange 观测收口，回声经 imeSetSelection 把「平台已安装」这一
  // 事实带回渲染器；没有观测到目标区间就不算安装成功（有界重投后具名失败）。
  private imeTextController: TextInputController = new TextInputController();
  private imeSelStart: number = -1;
  private imeSelEnd: number = -1;
  private proxyRestoreTask: ProxyRestoreTask | null = null;
  private proxySelMount: CjguiTextProxyMount | null = null;
  private proxySelStart: number = -1;
  private proxySelEnd: number = -1;
  // seq 让上一次安装的重投在新目标到来后立刻失效。
  private proxySelSeq: number = 0;

  // C：框架公共文字代理注册表（ProxyKey 五元冻结身份 + 单槽 current 校验）。
  // 桥接能力在此适配 entryNapi；模板不直接依赖具体桥。
  private faultAnnounced: boolean = false;
  private proxyRegistry: CjguiTextProxyRegistry = new CjguiTextProxyRegistry(new EntryNapiTextProxyBridge());

  build() {
    Stack() {
      Column() {
        if (this.surfaceMounted) {
          // The CJGUI self-drawn surface. ArkUI only hosts this XComponent; every
          // visible control is rendered by the Cangjie core scene through the
          // native bridge.
          XComponent({ id: 'cjgui_surface', type: XComponentType.SURFACE, libraryname: 'entry' })
            .onLoad(() => {
              hilog.info(DOMAIN, TAG, 'XComponent loaded');
              this.startHostWithImages();
            })
            .onDestroy(() => {
              // A3 分流：surface 卸载**只**退役租约（原生 onSurfaceDestroyed 回调
              // 已经做了租约退役与原生引用归还），绝不调用 stopHost ——
              // stopHost 现在是真正的应用停止入口，一次 XComponent 重建会误关 owner。
              hilog.info(DOMAIN, TAG, 'XComponent destroyed (surface retired, host kept)');
            })
            .width(this.surfaceWide ? '100%' : '60%')
            // H 触摸滚动包：生成 scrollArea 位于手写场景末尾，画布需足够高
            // 使其在正常消费中可见可触（原 layoutWeight(1) 只有约 1/3 屏）。
            .layoutWeight(3)
        } else {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#101820')
        }

        Text(this.status)
          .fontSize(12)
          .margin(8)

        Row() {
          Button('PROBE')
            .onClick(() => {
              const runtimeProbe: number = probeRuntime();
              const magicProbe: number = probeMagic();
              const rawProbe: string = (entryNapi.probeCangjie() as string) ?? 'no-result';
              this.probeResult = `official=${runtimeProbe}/${magicProbe} raw=${rawProbe}`;
              this.status = this.probeResult;
            })
            .layoutWeight(1)

          Button('CYCLE×10')
            .onClick(() => {
              this.runSurfaceCycles();
            })
            .layoutWeight(1)
            .margin({ left: 8 })

          // D：resize 驱动入口（onSurfaceChanged → geometryRevision++）。
          Button(this.surfaceWide ? 'RESIZE→60%' : 'RESIZE→100%')
            .onClick(() => {
              this.surfaceWide = !this.surfaceWide;
            })
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .margin({ bottom: 6 })

        Row() {
          // 负对照：对已收尾的上下文再提交一次，期望必然被拒（rc=1）。
          Button('LATE COMMIT')
            .onClick(() => {
              this.probeLateCommit();
            })
            .layoutWeight(1)

          // 这里读取 renderer 编辑上下文投影；公开 owner 精确值由外部
          // GET_CONTEXT 读取，不能用本地编辑缓冲冒充已提交的领域值。
          Button('EDIT STATE')
            .onClick(() => {
              this.inspectEditingContext('manual');
            })
            .layoutWeight(1)
            .margin({ left: 8 })
        }
        .margin({ bottom: 6 })

        Text(this.imeProjection)
          .fontSize(11)
          .margin({ bottom: 6 })

        Text(this.imeCapabilities)
          .fontSize(11)
          .margin({ bottom: 6 })

        Row() {
          // 宿主生命周期读数：phase / rendererDone / started / seam / 原生引用配平。
          Text(this.hostState)
            .fontSize(11)
            .layoutWeight(3)

          Button('STATE')
            .onClick(() => {
              this.refreshHostState();
            })
            .layoutWeight(1)

          // A3 停止驱动入口只在验证构建里出现：seam 存在 = 测试产物。
          // 普通产物查不到该按钮，也不存在任何从 UI 触发应用停止的路径。
          if (this.verifySeam) {
            Button('STOP HOST')
              .onClick(() => {
                hilog.info(DOMAIN, TAG, 'verify stop host requested from UI');
                entryNapi.stopHost();
                setTimeout(() => {
                  this.refreshHostState();
                }, 1500);
              })
              .layoutWeight(1)
              .margin({ left: 8 })

            // A3 同进程重开入口（第六次复核第 1 项）：stopped/failed 相位允许
            // 再次 startHost——宿主回收旧 owner 线程、分配新 appInstance，同一
            // 进程内完成 owner/renderer 实退→重开；宿主从仍有效的 UI 挂载事实
            // 取得新引用并发布新代，已卸载时等待真实 OnSurfaceCreated。
                          Button('RESTART HOST')
                .onClick(() => {
                  hilog.info(DOMAIN, TAG, 'verify restart host requested from UI');
                  this.startHostWithImages();
                  // 第九次复核 B：固定 3s republish 猜测已删除——重开后的
                  // surface 事实由宿主挂载事实（UI 线程维护）承载，owner 就绪
                  // 后自动从仍挂载且身份匹配的事实取资源，不按时间猜。
                  setTimeout(() => {
                    this.refreshHostState();
                  }, 6000);
                })
              .layoutWeight(1)
              .margin({ left: 8 })
          }
        }
        .margin({ bottom: 12 })
      }
      .width('100%')
      .height('100%')

      // 隐藏系统输入代理：几何与初值来自上下文快照；透明且不可见。
      // 组合/候选/键盘生命周期全部由系统输入法框架保证，本层只做交接。
      // 挂载实例经 @Builder 按值捕获：事件闭包持有**创建时**身份（第六次
      // 复核第 3 项），迟到/退役实例的回调绝不借 currentMount() 改名。
      if (this.imeCtx !== 0) {
        this.proxyTextInput(this.imeMount)
        CjguiTextSelectionMenu({ context: this.imeCtx, onInstall: (ctx: number) => this.onMenuInstalled(ctx) })
      }
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      // 原生→ArkTS 焦点请求：负载只有 {context, field}；几何与初值一律回查快照。
      entryNapi.registerFocusRequest((payload: string) => {
        this.onFocusRequest(payload);
      });
      this.refreshHostState();
    })
  }

  // 隐藏代理组件：m 为本次构建捕获的挂载身份。事件闭包一律使用 m 自身，
  // 由注册表按 ProxyKey 校验；'stale' 裁决只记日志，绝不影响当前挂载。
  @Builder
  proxyTextInput(m: CjguiTextProxyMount | null) {
    if (m !== null) {
      TextInput({ text: this.imeText, controller: this.imeTextController })
        .id(m.controlId)
        .enablePreviewText(true)
        .opacity(0)
        .selectionMenuHidden(true)
        .position({ x: this.imeX, y: this.imeY })
        .width(this.imeW)
        .height(this.imeH)
        // 手动核验兜底：直接点落在代理几何内的真实点击也允许夺取焦点，
        // 不只依赖渲染器焦点请求 → requestFocus 的程序化路径。
        .focusable(true)
        .focusOnTouch(true)
        .onFocus(() => {
          if (!this.proxyRegistry.isCurrent(m)) {
            hilog.info(DOMAIN, TAG, 'ime stale focus ignored mount=%{public}s', m.key.describe());
            return;
          }
          // 用户可见的聚焦信号（底部状态栏），同时日志留痕。
          this.proxyFocused = true;
          this.status = `editing ${m.fieldId}: 已聚焦，请直接打字（回车提交）`;
          hilog.info(DOMAIN, TAG, 'ime proxy FOCUSED field=%{public}s mount=%{public}s',
            m.fieldId, m.key.describe());
          if (this.proxySelMount === m) {
            // 聚焦达成的这一帧平台把光标推到末尾：按上下文立刻重装一次。
            this.installProxySelection(m, this.proxySelStart, this.proxySelEnd, 0,
              this.proxySelSeq, 'focus');
          }
        })
        .onWillInsert((): boolean => this.proxyRegistry.onWillInsert(m))
        .onWillChange((value: EditableTextChangeValue): boolean => this.proxyRegistry.onWillChange(m, value))
        .onWillDelete((value: DeleteValue): boolean => {
          const actual = this.imeTextController.getSelection();
          return this.proxyRegistry.onWillDelete(m, value, actual.start ?? -1, actual.end ?? -1,
            this.proxyRestoreTask === null && this.proxySelMount === null,
            (start: number, end: number) => this.imeTextController.deleteText({ start: start, end: end }));
        })
        .onChange((value: string, previewText?: PreviewText) => this.onProxyTextChange(m, value, previewText))
        .onSubmit(() => {
          const verdict: string = this.proxyRegistry.submitAndFinish(m, 'submit');
          hilog.info(DOMAIN, TAG, 'ime proxy submit verdict=%{public}s mount=%{public}s',
            verdict, m.key.describe());
          this.recordProxyFinish(m, verdict, 'submit');
        })
        .onTextSelectionChange((selectStart: number, selectEnd: number) => this.onProxySelectionChange(m, selectStart, selectEnd))
        .onBlur(() => {
          if (!this.proxyRegistry.isCurrent(m)) {
            hilog.info(DOMAIN, TAG, 'ime stale blur ignored mount=%{public}s', m.key.describe());
            return;
          }
          this.proxyFocused = false;
          const verdict: string = this.proxyRegistry.submitAndFinish(m, 'blur');
          hilog.info(DOMAIN, TAG, 'ime proxy blur verdict=%{public}s mount=%{public}s',
            verdict, m.key.describe());
          this.recordProxyFinish(m, verdict, 'blur');
        })
        .onDisAppear(() => {
          this.onProxyDisappeared(m);
        })
    }
  }

  // 平台只确认回调被接受；领域事务须由公开 GET_CONTEXT 精确读回。
  private recordProxyFinish(m: CjguiTextProxyMount, verdict: string, reason: string): void {
    if (verdict === 'stale') {
      return;
    }
    this.imeLastCommitRc = verdict;
    this.imeLastClosedCtx = m.key.contextId;
    if (this.sameDisplayedMount(m)) {
      this.imeMount = null;
      this.imeCtx = 0;
      this.mountedBaseVersion = 0;
      this.mountedNodeId = 0;
      this.proxyFocused = false;
    }
    this.status = verdict === 'ok'
      ? `input sent (${reason}); owner value: GET_CONTEXT`
      : `input rejected (${reason}); inspect owner via GET_CONTEXT`;
  }

  private sameDisplayedMount(m: CjguiTextProxyMount): boolean {
    const current: CjguiTextProxyMount | null = this.imeMount;
    return current !== null && current.key.mountGeneration === m.key.mountGeneration &&
      current.key.contextId === m.key.contextId &&
      current.key.appInstance === m.key.appInstance &&
      current.key.sessionToken === m.key.sessionToken;
  }

  // A3：读取宿主状态；seam=1 说明这是测试产物，此时才显示停止入口。
  private refreshHostState(): void {
    const raw: string = (entryNapi.hostState() as string) ?? '';
    if (raw.length === 0) {
      this.hostState = 'host state: unavailable';
      return;
    }
    this.hostState = raw;
    this.verifySeam = raw.indexOf('seam=1') >= 0;
    hilog.info(DOMAIN, TAG, 'host state: %{public}s', raw);
  }

  private readHostAppInstance(): number {
    const raw: string = (entryNapi.hostState() as string) ?? '';
    const marker: string = 'appInstance=';
    const at: number = raw.indexOf(marker);
    if (at < 0) {
      return 0;
    }
    const rest: string = raw.substring(at + marker.length);
    const space: number = rest.indexOf(' ');
    const value: number = Number(space < 0 ? rest : rest.substring(0, space));
    return Number.isSafeInteger(value) && value > 0 ? value : 0;
  }

  // ---- 文字代理交接 -------------------------------------------------------

  private onFocusRequest(payload: string): void {
    hilog.info(DOMAIN, TAG, 'ime focus payload=%{public}s', payload);
    let ctx: number = 0;
    let oldContext: number = 0;
    let action: string = 'focus';
    let parsed: ImeFocusPayload | null = null;
    try {
      parsed = JSON.parse(payload) as ImeFocusPayload;
      ctx = parsed.context;
      oldContext = parsed.oldContext ?? 0;
      if (parsed.action !== undefined && parsed.action.length > 0) {
        action = parsed.action;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime focus rejected: unparsable payload');
      return;
    }

    if (action === 'reconcile') {
      this.onReconcileRequest(oldContext, ctx);
      return;
    }

    // native 落点推送：命中、长按全选与编辑命令都会移动 caret/选区，装回当前代理，
    // 人不需要重新点焦就能在命中处继续打字，平台也才真正持有这段选区。
    if (action === 'caret') {
      if (parsed !== null) {
        this.onProxyCaret(parsed);
      }
      return;
    }

    // 结束通知：框架侧已经结束这段编辑（点到别的控件/空白/换绑/节点移除）。
    // 框架在发出本通知前已经按失焦语义结算过一次（未提交的组合预览 → owner），
    // 因此这里只释放代理，绝不能再提交一次：该上下文此刻已失效，重复提交会被
    // 拒绝（rc=1），而即便成功也构成第二次结算。
    // 只有当前挂载的那一个上下文才响应，避免旧通知关掉新焦点。
    if (action === 'end') {
      const pending: ImeReconcilePending | null = this.pendingReconcile;
      if (pending !== null) {
        if (ctx === pending.newContext) {
          // 新 context 自身已结束，卸载回调不得再把它挂回来。
          this.pendingReconcile = null;
          this.status = `editing ended by framework (${ctx})`;
          hilog.info(DOMAIN, TAG, 'ime pending reconcile cancelled by end ctx=%{public}d', ctx);
        } else {
          // 旧 context 的 end 是预期退休事件；其他 context 的迟到 end
          // 也无权改动当前待重挂目标。
          hilog.info(DOMAIN, TAG,
            'ime end ignored during reconcile ctx=%{public}d old=%{public}d new=%{public}d',
            ctx, pending.oldMount.key.contextId, pending.newContext);
        }
        return;
      }
      // C：经注册表校验「是否当前挂载」——只有当前挂载响应 end；其余记录忽略。
      if (this.proxyRegistry.onFrameworkEnd(ctx)) {
        this.imeLastClosedCtx = ctx;
        this.imeMount = null;
        this.imeCtx = 0;
        this.mountedBaseVersion = 0;
        this.mountedNodeId = 0;
        this.status = `editing ended by framework (${ctx})`;
      } else {
        hilog.info(DOMAIN, TAG,
          'ime end ignored: ctx=%{public}d active=%{public}d', ctx, this.imeCtx);
      }
      return;
    }

    // 先验证快照，再处理旧挂载；迟到焦点不可使当前输入被提交。
    const snap: ImeSnapshot | null = this.readEditingSnapshot(ctx);
    if (snap === null) {
      return;
    }
    if (this.pendingReconcile !== null) {
      // 等待旧组件 onDisAppear 的真实卸载回执，避免同一 TextInput 只换初值。
      hilog.info(DOMAIN, TAG, 'ime focus deferred during reconcile ctx=%{public}d', ctx);
      return;
    }

    // 同一上下文的重复焦点通知不结束当前输入；真正换上下文时经公共注册表
    // 收尾旧挂载，页面不能绕过其身份判定直调 NAPI。
    const oldMount: CjguiTextProxyMount | null = this.imeMount;
    const appInstance: number = this.readHostAppInstance();
    if (oldMount !== null && oldMount.key.contextId === snap.context &&
      oldMount.key.editGeneration === snap.generation &&
      oldMount.key.appInstance === appInstance && oldMount.key.sessionToken === snap.sessionToken &&
      this.proxyRegistry.isCurrent(oldMount)) {
      return;
    }
    if (oldMount !== null) {
      const oldVerdict: string = this.proxyRegistry.submitAndFinish(oldMount, 'focus-moved');
      this.recordProxyFinish(oldMount, oldVerdict, 'focus-moved');
    }

    this.mountEditingSnapshot(snap);
  }

  private readEditingSnapshot(ctx: number): ImeSnapshot | null {
    const snap: ImeSnapshot | null = this.readLiveEditingSnapshot();
    if (snap !== null && snap.context !== ctx) {
      hilog.warn(DOMAIN, TAG,
        'ime snapshot rejected: stale ctx=%{public}d live=%{public}d', ctx, snap.context);
      return null;
    }
    return snap;
  }

  private readLiveEditingSnapshot(): ImeSnapshot | null {
    const snapshotJson: string = (entryNapi.imeEditingContext() as string) ?? '';
    if (snapshotJson.length === 0) {
      hilog.warn(DOMAIN, TAG, 'ime snapshot rejected: no live context');
      return null;
    }
    try {
      const snap: ImeSnapshot = JSON.parse(snapshotJson) as ImeSnapshot;
      if (!Number.isSafeInteger(snap.context) || snap.context <= 0 ||
        !Number.isSafeInteger(snap.nodeId) || !Number.isSafeInteger(snap.baseVersion) ||
        !Number.isSafeInteger(snap.sessionToken) || snap.sessionToken <= 0 ||
        typeof snap.field !== 'string') {
        hilog.warn(DOMAIN, TAG, 'ime snapshot rejected: invalid identity/version');
        return null;
      }
      return snap;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime snapshot unparsable');
      return null;
    }
  }

  private onReconcileRequest(oldContext: number, newContext: number): void {
    const pending: ImeReconcilePending | null = this.pendingReconcile;
    if (pending !== null) {
      // 外部第二次换版发生在旧 TextInput 卸载与新挂载之间时，只把目标
      // 更新为最新 context；仍等同一旧组件的卸载回执，绝不复活中间版。
      const oldMatches: boolean = oldContext === pending.newContext ||
        oldContext === pending.oldMount.key.contextId;
      if (!oldMatches || newContext <= pending.newContext || newContext === oldContext) {
        hilog.info(DOMAIN, TAG,
          'ime reconcile gap callback ignored old=%{public}d new=%{public}d expected=%{public}d',
          oldContext, newContext, pending.newContext);
        return;
      }
      const nextSnap: ImeSnapshot | null = this.readLiveEditingSnapshot();
      if (nextSnap !== null && nextSnap.context >= newContext &&
        nextSnap.context > pending.newContext && nextSnap.nodeId === pending.nodeId &&
        nextSnap.field === pending.oldMount.fieldId &&
        nextSnap.sessionToken === pending.sessionToken &&
        this.readHostAppInstance() === pending.appInstance &&
        Number.isSafeInteger(nextSnap.baseVersion) && nextSnap.baseVersion > pending.baseVersion) {
        pending.newContext = nextSnap.context;
        pending.baseVersion = nextSnap.baseVersion;
        hilog.info(DOMAIN, TAG,
          'ime reconcile pending target advanced ctx=%{public}d base=%{public}d',
          nextSnap.context, nextSnap.baseVersion);
      }
      return;
    }
    const oldMount: CjguiTextProxyMount | null = this.imeMount;
    if (oldContext <= 0 || newContext <= 0 || oldContext === newContext ||
      oldMount === null || this.imeCtx !== oldContext) {
      hilog.info(DOMAIN, TAG,
        'ime reconcile ignored old=%{public}d new=%{public}d active=%{public}d',
        oldContext, newContext, this.imeCtx);
      return;
    }
    const snap: ImeSnapshot | null = this.readLiveEditingSnapshot();
    const appInstance: number = this.readHostAppInstance();
    if (snap === null || newContext <= oldContext || snap.context < newContext ||
      snap.context <= oldContext || snap.nodeId !== this.mountedNodeId ||
      snap.field !== oldMount.fieldId ||
      !Number.isSafeInteger(snap.baseVersion) || snap.baseVersion <= this.mountedBaseVersion ||
      appInstance <= 0 || oldMount.key.appInstance !== appInstance ||
      snap.sessionToken <= 0 || oldMount.key.sessionToken !== snap.sessionToken) {
      hilog.info(DOMAIN, TAG, 'ime reconcile ignored: live target/identity/version mismatch');
      return;
    }
    if (snap.context !== newContext) {
      hilog.info(DOMAIN, TAG,
        'ime reconcile fast-forward announced=%{public}d live=%{public}d', newContext, snap.context);
    }
    const verdict: string = this.proxyRegistry.retireForReconcile(oldMount, oldContext);
    if (verdict !== 'retired') {
      hilog.info(DOMAIN, TAG, 'ime reconcile stale mount=%{public}s', oldMount.key.describe());
      return;
    }
    this.pendingReconcile = {
      oldMount: oldMount, newContext: snap.context, baseVersion: snap.baseVersion,
      nodeId: snap.nodeId,
      sessionToken: snap.sessionToken, appInstance: appInstance, disappeared: false
    };
    this.imeLastClosedCtx = oldContext;
    this.imeMount = null;
    this.imeCtx = 0;
    this.mountedBaseVersion = 0;
    this.mountedNodeId = 0;
    this.proxyFocused = false;
    this.status = `external update: remounting ${snap.field} v=${snap.baseVersion}`;
    hilog.info(DOMAIN, TAG,
      'ime reconcile retired old=%{public}d new=%{public}d base=%{public}d',
      oldContext, snap.context, snap.baseVersion);
  }

  private onProxyDisappeared(m: CjguiTextProxyMount): void {
    const pending: ImeReconcilePending | null = this.pendingReconcile;
    if (pending === null || pending.oldMount !== m || pending.disappeared) {
      return;
    }
    pending.disappeared = true;
    // onDisAppear 已确认旧 TextInput 实际卸载。下一 UI 任务再次读取原生
    // context：若又发生换版/切焦，旧通知不能挂回过期初值。
    setTimeout(() => {
      if (this.pendingReconcile !== pending) {
        return;
      }
      if (this.imeMount !== null || this.imeCtx !== 0) {
        this.pendingReconcile = null;
        return;
      }
      const snap: ImeSnapshot | null = this.readLiveEditingSnapshot();
      if (snap === null || snap.context < pending.newContext ||
        snap.baseVersion < pending.baseVersion ||
        snap.nodeId !== pending.nodeId || snap.field !== pending.oldMount.fieldId ||
        snap.sessionToken !== pending.sessionToken ||
        this.readHostAppInstance() !== pending.appInstance) {
        this.pendingReconcile = null;
        hilog.info(DOMAIN, TAG,
          'ime reconcile remount abandoned ctx=%{public}d base=%{public}d',
          pending.newContext, pending.baseVersion);
        return;
      }
      if (snap.context !== pending.newContext) {
        hilog.info(DOMAIN, TAG,
          'ime reconcile remount fast-forward pending=%{public}d live=%{public}d',
          pending.newContext, snap.context);
      }
      this.pendingReconcile = null;
      this.mountEditingSnapshot(snap);
    }, 0);
  }

  private mountEditingSnapshot(snap: ImeSnapshot): void {
    const staleTask = this.proxyRestoreTask;
    if (staleTask !== null) staleTask.terminal = true;
    this.proxyRestoreTask = null;

    const appInstance: number = this.readHostAppInstance();
    if (appInstance <= 0 || !Number.isSafeInteger(snap.sessionToken) || snap.sessionToken <= 0) {
      hilog.warn(DOMAIN, TAG, 'ime mount rejected: app/session identity unavailable');
      this.status = 'input unavailable: app/session identity missing';
      return;
    }
    const density: number = this.displayDensity();
    this.imeField = snap.field;
    this.imeText = snap.text;         // 初值来自 owner，不清空
    this.updateInputCapabilities(snap);
    this.imeX = snap.x / density;
    this.imeY = snap.y / density;
    this.imeW = Math.max(snap.width / density, 24);
    this.imeH = Math.max(snap.height / density, 24);
    // hilog 只认 %{public}<conv>，不支持 %.0f 这类带精度的裸格式符；混用会让
    // 参数游标错位，把后面的字段读成别的实参（实测 s 会被吞成空串）。
    // 因此所有数值先在 ArkTS 里格式化好，日志只用 %{public}s。
    const geom: string =
      `px=${snap.x.toFixed(0)},${snap.y.toFixed(0)} ${snap.width.toFixed(0)}x${snap.height.toFixed(0)}`
        + ` vp=${this.imeX.toFixed(1)},${this.imeY.toFixed(1)} ${this.imeW.toFixed(1)}x${this.imeH.toFixed(1)}`
        + ` density=${density.toFixed(2)}`;
    hilog.info(DOMAIN, TAG,
      'ime proxy mounted ctx=%{public}d field=%{public}s node=%{public}d gen=%{public}d base=%{public}d '
      + 'font=%{public}d %{public}s text=%{public}s',
      snap.context, snap.field, snap.nodeId, snap.generation, snap.baseVersion,
      snap.fontSize, geom, snap.text);
    this.status = `editing ${snap.field} ctx=${snap.context} v=${snap.baseVersion}`;

    // C：经注册表挂载（ProxyKey 五元冻结：context=editGeneration、generation=
    // surface 代、mount 代由注册表递增），迟到焦点定时器由注册表校验后定向。
    const mount: CjguiTextProxyMount = this.proxyRegistry.mount(
      snap.context, snap.generation, 'cjguiImeProxy', snap.field,
      appInstance, snap.sessionToken, snap.text);
    this.imeMount = mount;
    this.mountedBaseVersion = snap.baseVersion;
    this.mountedNodeId = snap.nodeId;
    this.imeCtx = snap.context;
    this.proxyFocused = false;
    this.requestProxyFocus(mount, 0);
    this.armProxySelection(mount, snap.selStart, snap.selEnd, 'mount');
  }

  // requestFocus 只设置 ArkUI 焦点，不会附加系统输入法会话：模拟器/真机的
  // 键盘键入经输入法框架路由到「有输入会话的聚焦文本组件」，只聚焦不附加
  // 会话时打字不落字（实测手动核验点击后全无反应）。因此聚焦达成后必须
  // 显式 showTextInput()；控件刚挂载可能尚未完成布局，requestFocus 允许重试。
  private requestProxyFocus(mount: CjguiTextProxyMount, attempt: number): void {
    if (!this.proxyRegistry.delayedFocus(mount)) {
      return; // 挂载已被新焦点/结束取代，过期定时器到此为止
    }
    if (!this.proxyFocused) {
      try {
        this.getUIContext().getFocusController().requestFocus(mount.controlId);
        hilog.info(DOMAIN, TAG, 'ime requestFocus sent attempt=%{public}d', attempt);
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'ime requestFocus threw attempt=%{public}d', attempt);
      }
    }
    if (this.proxyFocused) {
      inputMethod.getController().showTextInput().then(() => {
        hilog.info(DOMAIN, TAG, 'ime showTextInput ok field=%{public}s', mount.fieldId);
      }).catch((err: Object) => {
        hilog.warn(DOMAIN, TAG, 'ime showTextInput rejected: %{public}s', String(err));
      });
      return;
    }
    if (attempt >= 4) {
      hilog.error(DOMAIN, TAG,
        'ime proxy never focused field=%{public}s ctx=%{public}d', mount.fieldId, mount.key.contextId);
      return;
    }
    setTimeout(() => {
      this.requestProxyFocus(mount, attempt + 1);
    }, 100 * (attempt + 1));
  }

  private armProxySelection(mount: CjguiTextProxyMount, start: number, end: number,
    reason: string): void {
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || end < start) {
      hilog.info(DOMAIN, TAG, 'ime proxy selection not installable reason=%{public}s start=%{public}s end=%{public}s',
        reason, String(start), String(end));
      return;
    }
    this.proxySelMount = mount;
    this.proxySelStart = start;
    this.proxySelEnd = end;
    this.proxySelSeq += 1;
    this.installProxySelection(mount, start, end, 0, this.proxySelSeq, reason);
  }

  // 有界重投：焦点达成的那一帧平台会把光标推到末尾，早装会被随后的重置覆盖，
  // 因此按挂载身份重投至多 3 次；观测到目标值即由 onTextSelectionChange 终结。
  private installProxySelection(mount: CjguiTextProxyMount, start: number, end: number,
    attempt: number, seq: number, reason: string): void {
    if (seq !== this.proxySelSeq || this.proxySelMount !== mount ||
      !this.proxyRegistry.isCurrent(mount)) {
      return; // 已被新目标/新挂载/收尾取代的过期定时器
    }
    if (this.proxyRestoreTask !== null) {
      this.proxySelMount = null;
      return;
    }
    try {
      this.imeTextController.setTextSelection(start, end, { menuPolicy: MenuPolicy.HIDE });
      hilog.info(DOMAIN, TAG,
        'ime proxy selection set [%{public}d,%{public}d) reason=%{public}s attempt=%{public}d focused=%{public}s',
        start, end, reason, attempt, this.proxyFocused ? 'true' : 'false');
    } catch (err) {
      this.proxySelMount = null;
      hilog.warn(DOMAIN, TAG, 'ime proxy selection threw reason=%{public}s err=%{public}s',
        reason, String(err));
      return;
    }
    // 同值 setter 可不产生 onTextSelectionChange。聚焦且仍属本挂载时读组件
    // 实际落点；只把精确命中的观测交给冻结 context，绝不以请求值充当回声。
    if (this.proxyFocused && this.proxySelMount === mount && this.proxyRegistry.isCurrent(mount)) {
      try {
        const actual = this.imeTextController.getSelection();
        if (actual !== undefined && actual !== null && actual.start === start && actual.end === end) {
          const rc: string = entryNapi.imeSetSelection(actual.start ?? -1, actual.end ?? -1,
            mount.key.contextId) as string;
          if (rc === '0') {
            this.imeSelStart = actual.start ?? -1;
            this.imeSelEnd = actual.end ?? -1;
            this.proxyRegistry.observeSelection(mount, this.imeSelStart, this.imeSelEnd);
            this.proxySelMount = null;
            hilog.info(DOMAIN, TAG,
              'ime selection getter observed [%{public}d,%{public}d) rc=%{public}s reason=%{public}s',
              this.imeSelStart, this.imeSelEnd, rc, reason);
            return;
          }
        }
      } catch (err) {
        hilog.warn(DOMAIN, TAG, 'ime selection getter unavailable reason=%{public}s err=%{public}s',
          reason, String(err));
      }
    }
    if (attempt >= 3) {
      this.proxySelMount = null;
      hilog.warn(DOMAIN, TAG,
        'ime proxy selection never observed reason=%{public}s target=[%{public}d,%{public}d) '
        + 'observed=[%{public}d,%{public}d)',
        reason, start, end, this.imeSelStart, this.imeSelEnd);
      return;
    }
    setTimeout(() => {
      this.installProxySelection(mount, start, end, attempt + 1, seq, reason);
    }, 120 * (attempt + 1));
  }

  // native 落点推送（action=caret）：命中、长按全选与外部换版都会移动 caret，而代理
  // 只按自己的事件更新落点。不装回代理，人的下一次键入就落在代理的旧偏移上，
  // 平台也从未真正持有 native 选中的那段区间。
  private onProxyTextChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText): void {
    if (!this.proxyRegistry.isCurrent(m)) return;
    // 程序回声判定：必须是**本次挂载**的回声且携带**本次请求的目标文本**。
    // 旧挂载的回声先被拒；文本不同的（人真的打了字）照常走真实输入路径，
    // 绝不能被一个全局门禁吞掉。
    const task: ProxyRestoreTask | null = this.proxyRestoreTask;
    if (task !== null && !task.terminal && task.mount === m && task.needsText &&
      value === task.targetText) {
      // 正文证据成立：只推进阶段，不发成功 ACK（选区还没装）。同一截止继续
      // 覆盖后面的选择阶段，不重新计时。
      task.textObserved = true;
      m.draft = value;
      this.proxyRestoreTask = task;
      hilog.info(DOMAIN, TAG,
        'ime proxy onChange is program echo req=%{public}d len=%{public}d kind=%{public}s', task.request, value.length, task.kind);
      // 赋值把光标重置到末尾是平台的既有行为（华为 FAQ）：等这一帧的重置落定
      // 再装选区，否则 setTextSelection 会被随后的重置覆盖。
      setTimeout(() => {
        this.beginSelectionPhase(task);
      }, 30);
      return;
    }
    if (task !== null && !task.terminal && task.mount === m && value !== task.targetText) {
      // 真人输入先于程序回声到达：安装已被人的输入取代，如实回报失败，
      // 让窗口按有界重试重新签发，而不是把这次变化当回声丢掉。
      // 菜单已由 native 的同 owner FIFO 接受；首笔真人变更以该目标为基线。
      if (task.kind === 'menu') m.draft = task.targetText;
      task.terminal = true;
      this.proxyRestoreTask = null;
      hilog.info(DOMAIN, TAG,
        'ime %{public}s superseded by human input req=%{public}d len=%{public}d',
        task.kind, task.request, value.length);
      this.ackProxyRestore(m.key.contextId, task.request, 0, 0, false, 'superseded_by_input');
    }
    const composing: boolean = previewText !== undefined && previewText !== null
      && previewText.value !== undefined && previewText.value.length > 0;
    if (composing) {
      hilog.info(DOMAIN, TAG, 'ime proxy composition len=%{public}d offset=%{public}d',
        previewText!.value.length, previewText!.offset ?? 0);
    }
    if (this.proxySelMount === m && value !== m.draft) {
      // 真人改文优先于落点安装：不再把光标拉回 native 推来的旧位置。
      this.proxySelMount = null;
    }
    const verdict: string = this.proxyRegistry.onChange(m, value, previewText);
    hilog.info(DOMAIN, TAG, 'ime proxy onChange len=%{public}d verdict=%{public}s mount=%{public}s',
      value.length, verdict, m.key.describe());
    if (verdict === 'ok') {
      this.imeText = m.draft;
    } else if (verdict === 'rejected') {
      this.imeLastClosedCtx = m.key.contextId;
      if (this.imeCtx === m.key.contextId) {
        this.imeMount = null;
        this.imeCtx = 0;
        this.mountedBaseVersion = 0;
        this.mountedNodeId = 0;
      }
      this.status = `editing closed: preview rejected`;
    }
    // 'stale'：迟到/退役实例，仅日志，当前挂载与显示不受影响。
  }

  private onProxySelectionChange(m: CjguiTextProxyMount, selectStart: number, selectEnd: number): void {
    // 先验挂载身份再记账：旧组件退役后的迟到选择事件不得写当前观测账本，
    // 否则新挂载的待办会被上一代事件满足（H1-R 复核 e2 反例）。
    if (!this.proxyRegistry.isCurrent(m)) {
      hilog.info(DOMAIN, TAG, 'ime stale selection ignored [%{public}d,%{public}d) mount=%{public}s',
        selectStart, selectEnd, m.key.describe());
      return;
    }
    const task: ProxyRestoreTask | null = this.proxyRestoreTask;
    if (task !== null && !task.terminal && task.mount === m) {
      if (!task.textObserved) {
        hilog.info(DOMAIN, TAG, 'ime %{public}s selection deferred before text echo req=%{public}d', task.kind, task.request);
        return;
      }
      this.proxyRegistry.observeSelection(m, selectStart, selectEnd);
      // 恢复进行中的选择事件属于安装观测流：用它触发按票据的复核，
      // 不上报成人的导航，也不改写会话/书签。
      hilog.info(DOMAIN, TAG, 'ime %{public}s selection observed [%{public}d,%{public}d) req=%{public}d',
        task.kind, selectStart, selectEnd, task.request);
      this.observeSelection(task);
      return;
    }
    this.proxyRegistry.observeSelection(m, selectStart, selectEnd);
    this.imeSelStart = selectStart;
    this.imeSelEnd = selectEnd;
    if (this.proxySelMount === m && selectStart === this.proxySelStart &&
      selectEnd === this.proxySelEnd) {
      // 代理已观测到目标落点：安装收口，不再重投（重投只会和人后续的
      // 导航抢光标）。这次回声把 native 的值带回渲染器。
      this.proxySelMount = null;
    }
    const rc: string = entryNapi.imeSetSelection(selectStart, selectEnd, m.key.contextId) as string;
    hilog.info(DOMAIN, TAG, 'ime select [%{public}d,%{public}d) rc=%{public}s mount=%{public}s',
      selectStart, selectEnd, rc, m.key.describe());
  }

  private armRestoreDeadline(task: ProxyRestoreTask, ms: number): void {
    setTimeout(() => {
      const live: ProxyRestoreTask | null = this.proxyRestoreTask;
      if (live !== task || task.terminal) {
        return;
      }
      task.terminal = true;
      this.proxyRestoreTask = null;
      const reason: string = task.textObserved ? 'selection_observation_timeout' : 'text_observation_timeout';
      hilog.warn(DOMAIN, TAG, 'ime %{public}s timeout req=%{public}d ctx=%{public}d reason=%{public}s',
        task.kind, task.request, task.mount.key.contextId, reason);
      this.ackProxyRestore(task.mount.key.contextId, task.request,
        this.imeSelStart, this.imeSelEnd, false, reason);
    }, ms);
  }

  private beginSelectionPhase(task: ProxyRestoreTask): void {
    if (task.terminal || this.proxyRestoreTask !== task || !task.textObserved ||
      !this.proxyRegistry.isCurrent(task.mount)) {
      return;
    }
    // 调用前只记"已发出选择命令"：抛错就不更新观测、如实失败，不谎报成功。
    try {
      if (task.targetStart === task.targetEnd) {
        this.imeTextController.caretPosition(task.targetStart);
      } else {
        this.imeTextController.setTextSelection(task.targetStart, task.targetEnd, { menuPolicy: MenuPolicy.HIDE });
      }
    } catch (err) {
      task.terminal = true;
      this.proxyRestoreTask = null;
      hilog.warn(DOMAIN, TAG, 'ime %{public}s selection threw: %{public}s', task.kind, String(err));
      this.ackProxyRestore(task.mount.key.contextId, task.request, 0, 0, false, 'selection_threw');
      return;
    }
    this.observeSelection(task);
  }

  private observeSelection(task: ProxyRestoreTask): void {
    if (task.terminal || this.proxyRestoreTask !== task || !task.textObserved ||
      !this.proxyRegistry.isCurrent(task.mount)) {
      return;
    }
    let observedStart: number = -1;
    let observedEnd: number = -1;
    try {
      const range: TextRange = this.imeTextController.getSelection();
      if (range === undefined || range === null) {
        // 控制器未绑定组件/组件已释放：没有观测可用，不得当作"落点已确认"。
        hilog.warn(DOMAIN, TAG, 'ime restore selection query has no bound component');
      } else {
        // TextRange.start/end 在本机声明里是可选 number：缺位就是"没有观测"，
        // 不得当成 0（0 是一个合法落点）。
        observedStart = range.start !== undefined ? range.start : -1;
        observedEnd = range.end !== undefined ? range.end : -1;
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'ime restore selection query threw: %{public}s', String(err));
    }
    if (observedStart >= 0 && observedEnd >= observedStart) {
      // 观测账本只由组件报告的值推进。
      this.imeSelStart = observedStart;
      this.imeSelEnd = observedEnd;
    }
    if (observedStart === task.targetStart && observedEnd === task.targetEnd) {
      if (task.request === 0) {
        // 匿名菜单安装没有 kind-55 ACK；实际选区仍须经既有选择 FIFO 交窗口采纳。
        // 空正文的 reset 已是 [0,0)，控制器同值 setter 可不再发组件回调。
        let rc: string = '1';
        try {
          rc = entryNapi.imeSetSelection(observedStart, observedEnd, task.mount.key.contextId) as string;
        } catch (err) {
          hilog.warn(DOMAIN, TAG, 'ime menu selection forwarding threw: %{public}s', String(err));
        }
        if (rc !== '0') {
          task.terminal = true;
          this.proxyRestoreTask = null;
          hilog.warn(DOMAIN, TAG, 'ime menu observed selection rejected rc=%{public}s', rc);
          return;
        }
      }
      task.terminal = true;
      this.proxyRestoreTask = null;
      task.mount.draft = task.targetText;
      this.proxyRegistry.observeSelection(task.mount, observedStart, observedEnd);
      hilog.info(DOMAIN, TAG, 'ime %{public}s observed installed req=%{public}d sel=%{public}d,%{public}d',
        task.kind, task.request, observedStart, observedEnd);
      this.ackProxyRestore(task.mount.key.contextId, task.request, observedStart, observedEnd, true,
        'observed_installed');
      this.status = `proxy restored ctx=${task.mount.key.contextId} units=${task.targetText.length}`;
      return;
    }
    if (!task.selectionRetried) {
      // 正文写入引起的迟到重置把落点挪走了：同一请求内重跑选择阶段，不重写正文、
      // 不延长截止、不提前解锁。
      task.selectionRetried = true;
      setTimeout(() => {
        this.beginSelectionPhase(task);
      }, 30);
      return;
    }
    task.terminal = true;
    this.proxyRestoreTask = null;
    hilog.warn(DOMAIN, TAG,
      'ime %{public}s landing mismatch req=%{public}d target=%{public}d,%{public}d observed=%{public}d,%{public}d',
      task.kind, task.request, task.targetStart, task.targetEnd, observedStart, observedEnd);
    this.ackProxyRestore(task.mount.key.contextId, task.request, observedStart, observedEnd, false,
      'installed_range_mismatch');
  }

  private ackProxyRestore(ctx: number, request: number, start: number, end: number,
    ok: boolean, reason: string): void {
    if (request <= 0) {
      return;
    }
    let rc: string = '1';
    try {
      rc = entryNapi.imeRestoreAck(ctx, request, start, end, ok ? 1 : 0) as string;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime restore ack threw: %{public}s', String(err));
      return;
    }
    hilog.info(DOMAIN, TAG,
      'ime restore ack ctx=%{public}d req=%{public}d ok=%{public}s sel=%{public}d,%{public}d rc=%{public}s reason=%{public}s',
      ctx, request, ok ? 'true' : 'false', start, end, rc, reason);
  }

  private onMenuInstalled(context: number): void {
    const mount = this.imeMount;
    if (mount === null || context !== this.imeCtx || !this.proxyRegistry.isCurrent(mount)) return;
    const raw = entryNapi.imeEditingContext() as string;
    if (raw.length === 0) return;
    const snap = JSON.parse(raw) as CjguiMenuSnapshot;
    if (snap.context !== context || snap.generation !== mount.key.editGeneration) return;
    const text = snap.previewText !== undefined
      ? snap.text.slice(0, snap.previewStart ?? 0) + snap.previewText
        + snap.text.slice(snap.previewEnd ?? snap.text.length) : snap.text;
    const previous: ProxyRestoreTask | null = this.proxyRestoreTask;
    if (previous !== null && !previous.terminal) {
      previous.terminal = true;
      this.ackProxyRestore(previous.mount.key.contextId, previous.request,
        this.imeSelStart, this.imeSelEnd, false, 'superseded_by_menu');
    }
    // 匿名安装复用恢复事务槽，阻止 focus/caret 入口在新正文回声前抢装旧值。
    // request=0 不签发 native 恢复票，也不产生恢复 ACK；业务编辑已由 native 接受。
    const needsText: boolean = text !== this.imeText;
    const task = new ProxyRestoreTask(mount, 0, text, snap.selStart, snap.selEnd, needsText, 'menu');
    this.proxyRestoreTask = task;
    this.proxySelMount = null;
    hilog.info(DOMAIN, TAG, 'ime menu install waiting text=%{public}s target=%{public}d,%{public}d mount=%{public}s',
      needsText ? 'true' : 'false', snap.selStart, snap.selEnd, mount.key.describe());
    if (needsText) {
      this.imeText = text;
      this.armRestoreDeadline(task, 1500);
      return;
    }
    this.beginSelectionPhase(task);
  }

  private onProxyCaret(payload: ImeFocusPayload): void {
    const ctx: number = payload.context;
    const mount: CjguiTextProxyMount | null = this.imeMount;
    if (mount === null || ctx !== this.imeCtx || !this.proxyRegistry.isCurrent(mount)) {
      hilog.info(DOMAIN, TAG, 'ime caret ignored ctx=%{public}d active=%{public}d', ctx, this.imeCtx);
      return;
    }
    if (this.proxyRestoreTask !== null) return;
    this.armProxySelection(mount, payload.selStart ?? -1, payload.selEnd ?? -1, 'caret');
  }

  private inspectEditingContext(reason: string): void {
    const snapshotJson: string = entryNapi.imeEditingContext() as string;
    if (snapshotJson.length === 0) {
      this.imeProjection = `editing context: closed (${reason})`;
      hilog.info(DOMAIN, TAG, 'ime editing projection reason=%{public}s state=closed', reason);
      return;
    }
    try {
      const snap: ImeSnapshot = JSON.parse(snapshotJson) as ImeSnapshot;
      this.imeProjection = `editing context ${snap.field}="${snap.text}" base=${snap.baseVersion}`;
      this.updateInputCapabilities(snap);
      hilog.info(DOMAIN, TAG,
        'ime editing projection reason=%{public}s ctx=%{public}d live=%{public}d base=%{public}d '
        + 'sel=%{public}d,%{public}d text=%{public}s',
        reason, this.imeCtx, snap.context, snap.baseVersion,
        snap.selStart, snap.selEnd, snap.text);
    } catch (err) {
      this.imeProjection = 'editing context: unreadable';
      hilog.error(DOMAIN, TAG, 'ime editing projection unparsable');
    }
  }

  private updateInputCapabilities(snap: ImeSnapshot): void {
    const caps: ImeInputCapabilities | undefined = snap.inputCapabilities;
    if (caps === undefined) {
      this.imeCapabilities = 'input capabilities: unavailable';
      return;
    }
    this.imeCapabilities = `input: draft ${caps.fullDraft}, UTF-16 selection ${caps.selectionUtf16}, `
      + `marked ${caps.markedRange} (observed=${caps.markedRangeObserved}), cancel ${caps.cancelEvent}`;
  }

  // 负对照：对已收尾的上下文再提交，期望 rc=1（被拒），不写 owner。
  private probeLateCommit(): void {
    if (this.imeLastClosedCtx === 0) {
      this.status = 'late commit skipped: no closed context yet';
      hilog.info(DOMAIN, TAG, 'ime late commit skipped: no closed context');
      return;
    }
    const probe: string = 'late-probe';
    const rc: string = entryNapi.imeCommitText(probe, this.imeLastClosedCtx) as string;
    hilog.info(DOMAIN, TAG,
      'ime late commit ctx=%{public}d rc=%{public}s expected=1',
      this.imeLastClosedCtx, rc);
    this.status = `late commit ctx=${this.imeLastClosedCtx} rc=${rc} expected=1`;
  }

  private displayDensity(): number {
    try {
      return display.getDefaultDisplaySync().densityPixels;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'density query failed; falling back to 1.0');
      return 1.0;
    }
  }

  // ---- surface 生命周期反复（工作包 D）-----------------------------------

  private async runSurfaceCycles(): Promise<void> {
    if (this.cycling) {
      return;
    }
    this.cycling = true;
    for (let i = 1; i <= 10; i++) {
      this.status = `cycle ${i}: unmount`;
      hilog.info(DOMAIN, TAG, 'cycle %{public}d unmount', i);
      this.surfaceMounted = false;
      await this.delay(600);
      this.status = `cycle ${i}: remount`;
      hilog.info(DOMAIN, TAG, 'cycle %{public}d remount', i);
      this.surfaceMounted = true;
      await this.delay(600);
    }
    this.status = '10 surface cycles done';
    hilog.info(DOMAIN, TAG, '10 surface cycles done');
    this.cycling = false;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => {
      setTimeout(resolve, ms);
    });
  }
}
