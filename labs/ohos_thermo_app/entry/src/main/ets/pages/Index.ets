import { CjguiImeRestorePayload, CjguiImeRestoreTicket, CjguiImeFrameCallback } from '../proxy/cjgui-text-proxy';
import systemDateTime from '@ohos.systemDateTime';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { fileIo } from '@kit.CoreFileKit';
import inputMethod from '@ohos.inputMethod';
import entryNapi from 'libentry.so';
// 官方互操作导入：经 ark_interop_loader 加载仓颉模块并完成运行时初始化。
import { probeRuntime, probeMagic } from 'libcjgui_app.so';
import { CjguiTextProxyRegistry, CjguiTextProxyMount, CjguiTextProxyBridge, CjguiProxyKey, CjguiProxyInputChange, CjguiProxyGeometry, } from '../proxy/cjgui-text-proxy';
import { CjguiImeSelectionLifecycle, CjguiImeSelectionHost, CjguiImeSelectionRead } from '../proxy/cjgui-text-proxy';
import { CjguiTextSelectionMenu, CjguiMenuSnapshot } from '../proxy/cjgui-text-menu';
import { CjguiWindowGeometry } from '../proxy/cjgui-window-geometry';

const TAG: string = 'CjguiApp';
const DOMAIN: number = 0x0000;

// 渲染器焦点请求负载：只带不透明上下文编号、字段名与动作类型，平台不解释几何。
// action 缺省视为 "focus"（向后兼容无 action 的旧负载）。
interface ImeFocusPayload extends CjguiImeRestorePayload {
  action?: string;
  focusGeneration?: number;
  context: number;
  field: string;
  nodeId?: number;
  oldContext?: number;
  baseVersion?: number;
  selStart?: number;
  selEnd?: number;
  text?: string;
  request?: number;
}

interface ImeReconcilePending {
  oldMount: CjguiTextProxyMount;
  newContext: number;
  baseVersion: number;
  nodeId: number;
  sessionToken: number;
  appInstance: number;
  disappeared: boolean;
  // R3补轮：重挂目标的 field 身份。外部换版 reconcile 与旧节点相同
  //（= oldMount.fieldId）；焦点切换跨编辑面时是新目标（生成/手写互切）。
  targetField: string;
}

// 上下文快照（来自 ohos_renderer_ime_context_json）。
// 平台据此初始化代理：值、几何、字号、选区、基版本都来自 owner，
// 平台不凭空造初值，也不把字段名/几何写死在 ArkTS 里。
interface ImeSnapshot {
  appInstance: number;
  resourceId: number;
  nodeKind: number;
  bindingEpoch: number;
  restoreRequest: number;
  restoreDeadlineMonoMs: number;
  restoreProjectionVersion: number;
  restoreBindingEpoch: number;
  previewText?: string;
  previewStart?: number;
  previewEnd?: number;
  context: number;
  focusGeneration: number;
  field: string;
  nodeId: number;
  geometryUnit: string;
  proxyX: number;
  proxyY: number;
  proxyWidth: number;
  proxyHeight: number;
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

  inputWill(mount: CjguiTextProxyMount, change: CjguiProxyInputChange): string {
    const k = mount.key;
    return entryNapi.imeInputWill(change.before,change.after,mount.fieldId,change.start,change.end,
      change.afterStart,change.afterEnd,k.appInstance,k.sessionToken,k.contextId,k.editGeneration,k.mountGeneration,mount.focusGeneration) as string;
  }
  inputChange(mount: CjguiTextProxyMount, ticket: number, text: string): string {
    const k = mount.key;
    return entryNapi.imeInputChange(text,ticket,k.appInstance,k.sessionToken,k.contextId,
      k.editGeneration,k.mountGeneration,mount.focusGeneration) as string;
  }
  finishProxy(key: CjguiProxyKey, generation: number, text: string): string {
    return entryNapi.imeFinishProxy(text, key.appInstance, key.sessionToken, key.contextId,
      key.editGeneration, key.mountGeneration, generation) as string;
  }

  focusAuthority(key: CjguiProxyKey, operation: number, generation: number,
    targetContext: number, targetGeneration: number): string {
    return entryNapi.imeFocusAuthority(key.appInstance, key.sessionToken, key.contextId,
      key.editGeneration, key.mountGeneration, operation, generation, targetContext, targetGeneration) as string;
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

// R3（h-source-preview-followup 2026-10-02）：thermo 接入框架共享安装生命周期
// CjguiImeSelectionLifecycle 的页面 seam——与 Pharos 同一实现，页面只提供平台
// 能力（attach / 按挂载的输入流证据 / 选区读写 / native 结算）。内联的
// armProxySelection/installProxySelection 状态机退役。
class ThermoImeSelectionHost implements CjguiImeSelectionHost {
  private readonly page: Index;

  constructor(page: Index) {
    this.page = page;
  }

  attachSession(): Promise<void> {
    return inputMethod.getController().showTextInput();
  }

  hasImeTrafficEvidence(mount: CjguiTextProxyMount): boolean {
    // R2：证据按挂载身份（注册表在真实改文时记账），不借别的编辑面的输入。
    return this.page.proxyRegistry.hasTraffic(mount);
  }

  readSelection(): CjguiImeSelectionRead {
    const actual = this.page.imeTextController.getSelection();
    return new CjguiImeSelectionRead(actual?.start ?? -1, actual?.end ?? -1);
  }

  setSelection(start: number, end: number): void {
    if (start === end) {
      this.page.imeTextController.caretPosition(start);
    } else {
      this.page.imeTextController.setTextSelection(start, end, { menuPolicy: MenuPolicy.HIDE });
    }
  }

  commitInstalled(start: number, end: number, contextId: number): string {
    const rc: string = entryNapi.imeSetSelection(start, end, contextId) as string;
    // R2：只有 native 真实接受（rc=0）才落"已安装"账目。
    const m: CjguiTextProxyMount | null = this.page.imeMount;
    if (rc === '0') {
      this.page.imeSelStart = start;
      this.page.imeSelEnd = end;
      if (m !== null) {
        this.page.proxyRegistry.observeSelection(m, start, end);
      }
    }
    // 确认行携带**同一请求的完整身份**（挂载 key 含 context/mount 代 + field）：
    // 总门按身份配对，错字段/跨 mount 拼接不能借坐标相等误配（指导复核反例）。
    const mountKey: string = m !== null ? m.key.describe() : 'none';
    const mountField: string = m !== null ? m.fieldId : 'none';
    hilog.info(DOMAIN, TAG, 'ime selection confirmed [%{public}d,%{public}d) rc=%{public}s '
      + '(shared lifecycle) mount=%{public}s field=%{public}s', start, end, rc, mountKey, mountField);
    return rc;
  }

  isCurrentMount(mount: CjguiTextProxyMount): boolean {
    return this.page.proxyRegistry.isCurrent(mount);
  }

  restoreTaskActive(): boolean { return this.page.selectionLifecycle.hasRestore(); }

  currentMount(): CjguiTextProxyMount | null { return this.page.imeMount; }

  monotonicNowMs(): number { return systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false); }

  restoreTargetEligible(ticket: CjguiImeRestoreTicket): boolean {
    const snap = this.page.readLiveEditingSnapshot();
    if (snap === null || this.page.readHostAppInstance() !== ticket.appInstance ||
      snap.appInstance !== ticket.appInstance || snap.sessionToken !== ticket.sessionToken ||
      snap.context !== ticket.context || snap.generation !== ticket.generation ||
      snap.focusGeneration !== ticket.focusGeneration ||
      snap.field !== ticket.field || snap.nodeId !== ticket.nodeId ||
      snap.resourceId !== ticket.resourceId || snap.nodeKind !== ticket.nodeKind) { return false; }
    if (ticket.request === 0) {
      return snap.baseVersion === ticket.baseVersion && snap.bindingEpoch === ticket.bindingEpoch;
    }
    return snap.restoreRequest === ticket.request && snap.restoreDeadlineMonoMs === ticket.deadlineMonoMs &&
      snap.restoreProjectionVersion === ticket.baseVersion && snap.restoreBindingEpoch === ticket.bindingEpoch;
  }

  writeRestoreText(mount: CjguiTextProxyMount, text: string): void {
    if (!this.isCurrentMount(mount)) { return; }
    this.page.imeText = text;
  }

  afterComponentFrame(mount: CjguiTextProxyMount, callback: () => void): CjguiImeFrameCallback {
    const frame = new CjguiImeFrameCallback(callback);
    this.page.getUIContext().postFrameCallback(frame);
    return frame;
  }

  commitRestore(ticket: CjguiImeRestoreTicket, start: number, end: number,
    ok: boolean, reason: string): string {
    let rc: string = '1';
    try {
      // Anonymous menu installation keeps ordinary selection semantics; a named
      // request uses only its original native ACK, never both native outlets.
      rc = ticket.request === 0 ? (ok ? this.commitInstalled(start, end, ticket.context) : '1') :
        entryNapi.imeRestoreAck(ticket.context, ticket.request, start, end, ok ? 1 : 0) as string;
    } catch (err) { hilog.warn(DOMAIN, TAG, 'ime restore ack threw: %{public}s', String(err)); }
    const mount = this.page.imeMount;
    if (ok && rc === '0' && mount !== null && this.isCurrentMount(mount) &&
      mount.key.contextId === ticket.context && mount.key.editGeneration === ticket.generation) {
      this.page.imeSelStart = start; this.page.imeSelEnd = end;
      this.page.proxyRegistry.observeSelection(mount, start, end);
    }
    hilog.info(DOMAIN, TAG,
      'ime restore ack ctx=%{public}d req=%{public}d ok=%{public}s sel=%{public}d,%{public}d rc=%{public}s reason=%{public}s',
      ticket.context, ticket.request, ok ? 'true' : 'false', start, end, rc, reason);
    return rc;
  }


  logInfo(msg: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', msg);
  }

  logWarn(msg: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', msg);
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
  @State imeClipX: number = 0;
  @State imeClipY: number = 0;
  @State imeClipW: number = 0;
  @State imeClipH: number = 0;
  // 最近一次已收尾的上下文编号，用于「晚回调必须被拒」的负对照。
  @State imeLastClosedCtx: number = 0;
  @State imeLastCommitRc: string = '-';
  @State imeProjection: string = 'editing context: -';
  @State imeCapabilities: string = 'input capabilities: pending context';
  // 身份对象保持普通字段，避免 @State 对 class 包装后破坏引用相等；
  // imeCtx 是挂载/卸载的响应式开关，@Builder 仍捕获本次身份。
  /* package */ imeMount: CjguiTextProxyMount | null = null;
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
  // 交接在飞期间到达的恢复请求只登记冻结目标（请求号、区间、文本沿用原票），
  // 由就绪事件接续，不在旧组件卸载前创建新 current，也不重签。
  // native 落点安装槽（native→平台）。两个来源：挂载时按上下文快照装初值；native
  // 推 action=caret（命中、长按全选、编辑命令移动了落点）时装新值。平台把新聚焦
  // TextInput 的光标重置到末尾（华为 FAQ），不装回代理就会覆盖 native 刚落账的
  // caret/选区，人的下一次键入落在代理的旧偏移上。安装结果一律由组件自己的
  // onTextSelectionChange 观测收口，回声经 imeSetSelection 把「平台已安装」这一
  // 事实带回渲染器；没有观测到目标区间就不算安装成功（有界重投后具名失败）。
  /* package */ imeTextController: TextInputController = new TextInputController();
  /* package */ imeSelStart: number = -1;
  /* package */ imeSelEnd: number = -1;
  // R3（2026-10-02）：选区安装/确认/attach 生命周期改由框架共享类承担
  //（CjguiImeSelectionLifecycle；与 Pharos 同一实现）。内联的
  // proxySelMount/proxySelStart/proxySelEnd/proxySelSeq 状态机退役。
  /* package */ selectionLifecycle: CjguiImeSelectionLifecycle = new CjguiImeSelectionLifecycle(
    new ThermoImeSelectionHost(this));
  // 每次真实挂载递增，保证代理控件 id 唯一（见 mountEditingSnapshot 注释）。
  private proxyMountSerial: number = 1;

  // C：框架公共文字代理注册表（ProxyKey 五元冻结身份 + 单槽 current 校验）。
  // 桥接能力在此适配 entryNapi；模板不直接依赖具体桥。
  private faultAnnounced: boolean = false;
  /* package */ proxyRegistry: CjguiTextProxyRegistry = new CjguiTextProxyRegistry(new EntryNapiTextProxyBridge());

  build() {
    Stack() {
      Column() {
        if (this.surfaceMounted) {
          // The CJGUI self-drawn surface. ArkUI only hosts this XComponent; every
          // visible control is rendered by the Cangjie core scene through the
          // native bridge.
          XComponent({ id: 'cjgui_surface', type: XComponentType.SURFACE, libraryname: 'entry' })
            .id('cjgui_surface')
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
            .layoutWeight(1)
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
        // 结构身份 = 挂载键。ForEach 的键变即销毁旧节点并重建，新节点在**构造**时
        // 绑定当前 controller；不再依赖 `imeCtx` 恰好归零过一帧（见 liveProxyMounts）。
        ForEach(this.liveProxyMounts(), (m: CjguiTextProxyMount) => {
          this.proxyTextInput(m)
        }, (m: CjguiTextProxyMount) => m.key.describe())
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
      this.watchWindowGeometry();
    })
    .onDisAppear(() => {
      this.windowGeometryEpoch++;
      this.windowGeometry?.release();
      this.windowGeometry = null;
    })
  }

  private windowGeometry: CjguiWindowGeometry | null = null;
  private windowGeometryEpoch: number = 0;
  private async watchWindowGeometry(): Promise<void> {
    const epoch = ++this.windowGeometryEpoch;
    const win = await window.getLastWindow(getContext(this));
      if (epoch !== this.windowGeometryEpoch) { return; }
      this.windowGeometry?.release();
    this.windowGeometry = new CjguiWindowGeometry(this.getUIContext(), win,
      'cjgui_surface', (top: number) => { entryNapi.setKeyboardOverlay(top); });
  }

  // 代理组件的结构身份来源：只列出**当前**挂载。
  // 为什么必须由挂载键驱动重建（B 组 2026-10-06 Astra 复核）：
  // `imeMount` 与 `imeTextController` 都是普通字段（换挂载不触发渲染），而外层
  // `if (this.imeCtx !== 0)` 在 ctx 2→3 时仍落在同一分支——ArkUI 条件渲染只在
  // **分支改变**时移除/重建，`.id()` 也不是重建键。于是旧组件被复用、新 controller
  // 从未绑定到任何节点：getSelection() 返回 undefined、按新 controlId 的
  // requestFocus 打不到节点（设备原件 `Request focus id can not found` /
  // `JSTextEditableController is NULL`），FOCUSED 与 IME attach 双双落空，
  // 安装/窗口采纳链从此失联（ctx=3 八张票全部 platform_install_failed）。
  // 渲染本身仍由 `imeCtx` 触发（每个挂载点赋值非零、每个 end 归零），因此这里
  // 读取到的 `imeMount` 与本轮渲染一致；键变 → ForEach 销毁旧节点并按新
  // controller 重建，不再要求"归零恰好跨过一次渲染"。
  private liveProxyMounts(): CjguiTextProxyMount[] {
    const m: CjguiTextProxyMount | null = this.imeMount;
    return m === null ? [] : [m];
  }

  // 隐藏代理组件：m 为本次构建捕获的挂载身份。事件闭包一律使用 m 自身，
  // 由注册表按 ProxyKey 校验；'stale' 裁决只记日志，绝不影响当前挂载。
  @Builder
  proxyTextInput(m: CjguiTextProxyMount | null) {
    if (m !== null) {
      Stack({ alignContent: Alignment.TopStart }) {
      TextInput({ text: this.imeText, controller: this.imeTextController })
        .id(m.controlId)
        .enablePreviewText(true)
        .opacity(0)
        .selectionMenuHidden(true)
        .position({ x: this.imeX - this.imeClipX, y: 0 })
        .width(this.imeW)
        .height(this.imeH)
        // CJGUI receives pointer selection; this transparent IME mount takes
        // focus through the same native focus request used by Pharos.
        .focusable(true)
        .focusOnTouch(false)
        .hitTestBehavior(HitTestMode.None)
        // 焦点注册表就绪由节点自身入场事件驱动：组件进入渲染树之前 requestFocus 必然
        // `Request focus id can not found`（ctx=1 实测 attempt=0 抛、attempt=1 成），
        // 而换挂载后的 5 次固定重试可能整体落空（ctx=2 实测 0..4 全抛 ⇒
        // `ime proxy never focused` ⇒ 键盘会话从未建立 ⇒ 恢复票按观测超时终态）。
        // onAppear 是"节点已在树里"的就绪信号，由它重驱一次，不是再加时间等待。
        .onAppear(() => {
          if (this.proxyRegistry.delayedFocus(m) && !this.proxyFocused) {
            this.requestProxyFocus(m, 0);
          }
        })
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
          // R4（2026-10-02 Astra 裁决）：焦点到达是**无条件的会话补建点**——attach
          // 是会话级事实，与有无待装选区无关（与 Pharos 页面同一入口）。此前只调
          // maybeInstall 会在未 attach 时只记日志、不发起会话；恢复让位清 pending
          // 后同样会永久关闭会话建立入口。
          this.selectionLifecycle.requestAttach(m, 'focus');
          // 就绪接续：交接在飞时登记的冻结目标，只在这份挂载真正取得焦点后接续
          // 同一请求（沿用原请求号与既有截止，不重签票）。

        })
        .onKeyEvent((event: KeyEvent): boolean => this.proxyRegistry.plainKey(m,
          event.keyCode, event.type === KeyType.Down, event.getModifierKeyState?.(['Shift']) ?? false,
          this.selectionLifecycle.hasRestore() || this.selectionLifecycle.pendingMount() !== null,
          (context: number, generation: number, intent: string): string =>
            entryNapi.imePlainKey(intent, context, generation) as string))
        .onWillInsert((): boolean => this.proxyRegistry.onWillInsert(m))
        .onWillChange((value: EditableTextChangeValue): boolean => this.proxyRegistry.onWillChange(m, value))
        .onWillDelete((value: DeleteValue): boolean => {
          const actual = this.imeTextController.getSelection();
          return this.proxyRegistry.onWillDelete(m, value, actual.start ?? -1, actual.end ?? -1,
            !this.selectionLifecycle.hasRestore() && this.selectionLifecycle.pendingMount() === null,
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
      }.position({ x: this.imeClipX, y: this.imeClipY })
        .width(this.imeClipW).height(this.imeClipH).clip(true).hitTestBehavior(HitTestMode.None)
    }
  }

  // 平台只确认回调被接受；领域事务须由公开 GET_CONTEXT 精确读回。
  private recordProxyFinish(m: CjguiTextProxyMount, verdict: string, reason: string): void {
    if (verdict === 'stale') {
      return;
    }
    this.imeLastCommitRc = verdict;
    this.imeLastClosedCtx = m.key.contextId;
    // R2：挂载收场——它的安装待办与 attach 事实一并退场，旧计时器不作用于
    // 新挂载。
    this.selectionLifecycle.invalidateAttachmentFor(m);
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

  /* package */ readHostAppInstance(): number {
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

  // 编辑身份：contextId + editGeneration + sessionToken + appInstance。焦点切换
  // 是否必须经「卸载→等 onDisAppear→重挂」，判据是**这份身份变了没有**，不是
  // 「context 号变没变」——同号但 editGeneration 已推进（换绑/重建）时组件同样
  // 不会重建，同帧 finish+mount 就是注册表查不到新 id、requestFocus 落空那条
  // 已实测失败的路。onFocusRequest 与 mountEditingSnapshot 共用本判据。
  private sameEditIdentity(m: CjguiTextProxyMount, snap: ImeSnapshot, appInstance: number): boolean {
    return m.key.contextId === snap.context
      && m.key.editGeneration === snap.generation
      && m.key.sessionToken === snap.sessionToken
      && m.key.appInstance === appInstance;
  }

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

    // 框架侧回滚/安装票据：owner 拒绝了范围编辑或 owned 锚点恢复时，隐藏代理
    // 按票据安装 accepted 值与落点并 ACK。presentation 消费者（备注 TEXT 投影）
    // 的首次安装也走这张票。
    if (action === 'restore') {
      this.onProxyRestore(parsed);
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
        const endedMount: CjguiTextProxyMount | null = this.imeMount;
        this.imeLastClosedCtx = ctx;
        // R1/R2：end 只卸对应 context；该挂载的安装待办与 attach 事实退场。
        if (endedMount !== null && endedMount.key.contextId === ctx) {
          this.selectionLifecycle.invalidateAttachmentFor(endedMount);
        }
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
    if (snap === null || parsed === null || parsed.focusGeneration !== snap.focusGeneration) {
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
    if (oldMount !== null && this.sameEditIdentity(oldMount, snap, appInstance) &&
      parsed !== null && parsed.focusGeneration === snap.focusGeneration &&
      this.proxyRegistry.acceptNativeFocus(oldMount, snap.focusGeneration)) {
      return;
    }
    if (oldMount !== null) {
      // R3补轮：焦点切换必须走「卸载→等 onDisAppear 回执→重挂」，不能同帧
      // finish+mount——TextInput 组件不重建，新 controlId 不进焦点注册表，
      // requestFocus 全落空（设备实测 ctx3 注入零事件）。判据是**编辑身份变了没**
      // （含 editGeneration），不只 context 号：同号换代会绕过这一门。
      if (!this.sameEditIdentity(oldMount, snap, appInstance)) {
        const oldVerdict: string = this.proxyRegistry.submitAndFinish(oldMount, 'focus-moved');
        this.recordProxyFinish(oldMount, oldVerdict, 'focus-moved');
        this.pendingReconcile = {
          oldMount: oldMount,
          newContext: snap.context,
          baseVersion: snap.baseVersion,
          nodeId: snap.nodeId,
          sessionToken: snap.sessionToken,
          appInstance: this.readHostAppInstance(),
          disappeared: false,
          targetField: snap.field,
        };
        hilog.info(DOMAIN, TAG,
          'ime focus switch deferred to reconcile old=%{public}d new=%{public}d field=%{public}s',
          oldMount.key.contextId, snap.context, snap.field);
        return;
      }
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

  /* package */ readLiveEditingSnapshot(): ImeSnapshot | null {
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
    const verdict: string = this.proxyRegistry.retireForReconcile(oldMount, oldContext, snap.context, snap.generation);
    if (verdict !== 'retired') {
      hilog.info(DOMAIN, TAG, 'ime reconcile stale mount=%{public}s', oldMount.key.describe());
      return;
    }
    this.pendingReconcile = {
      oldMount: oldMount, newContext: snap.context, baseVersion: snap.baseVersion,
      nodeId: snap.nodeId,
      sessionToken: snap.sessionToken, appInstance: appInstance, disappeared: false,
        targetField: oldMount.fieldId,
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
        snap.nodeId !== pending.nodeId || snap.field !== pending.targetField ||
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
    // R3补轮：焦点切换跨上下文（生成/手写编辑面互切、直接换绑）时必须走
    // 「卸载→等 onDisAppear 回执→重挂」的同一 reconcile 纪律——同帧替换不
    // 重建 TextInput 组件，.id() 变更不进入焦点注册表，requestFocus 以新 id
    // 找不到节点（设备实测 ctx3 五次尝试全 throw、注入零事件）。
    const previousMount: CjguiTextProxyMount | null = this.imeMount;
    if (previousMount !== null &&
        !this.sameEditIdentity(previousMount, snap, this.readHostAppInstance())) {
      const verdict: string = this.proxyRegistry.submitAndFinish(previousMount, 'focus-moved');
      this.recordProxyFinish(previousMount, verdict, 'focus-moved');
      this.pendingReconcile = {
        oldMount: previousMount,
        newContext: snap.context,
        baseVersion: snap.baseVersion,
        nodeId: snap.nodeId,
        sessionToken: snap.sessionToken,
        appInstance: this.readHostAppInstance(),
        disappeared: false,
        targetField: snap.field,
      };
      hilog.info(DOMAIN, TAG,
        'ime focus switch deferred to reconcile old=%{public}d new=%{public}d field=%{public}s',
        previousMount.key.contextId, snap.context, snap.field);
      return;
    }


    const appInstance: number = this.readHostAppInstance();
    if (appInstance <= 0 || !Number.isSafeInteger(snap.sessionToken) || snap.sessionToken <= 0) {
      hilog.warn(DOMAIN, TAG, 'ime mount rejected: app/session identity unavailable');
      this.status = 'input unavailable: app/session identity missing';
      return;
    }
    const density: number = this.displayDensity();
    this.imeField = snap.field;
    this.updateInputCapabilities(snap);
    const geometry = new CjguiProxyGeometry(snap.x, snap.proxyX, snap.proxyY, snap.width, snap.proxyWidth, snap.proxyHeight);
    if (snap.geometryUnit !== 'vp' || !geometry.valid()) { return; }
    this.imeX = geometry.x;
    this.imeY = geometry.y;
    this.imeW = geometry.width;
    this.imeH = geometry.height;
    this.imeClipX = geometry.clipX; this.imeClipY = geometry.clipY;
    this.imeClipW = geometry.clipWidth; this.imeClipH = geometry.clipHeight;
    // hilog 只认 %{public}<conv>，不支持 %.0f 这类带精度的裸格式符；混用会让
    // 参数游标错位，把后面的字段读成别的实参（实测 s 会被吞成空串）。
    // 因此所有数值先在 ArkTS 里格式化好，日志只用 %{public}s。
    const geom: string =
      `layout_vp=${snap.x.toFixed(0)},${snap.y.toFixed(0)} ${snap.width.toFixed(0)}x${snap.height.toFixed(0)}`
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
    const retiredMount: CjguiTextProxyMount | null = this.imeMount;
    const mount: CjguiTextProxyMount = this.proxyRegistry.mount(
      snap.context, snap.generation,
      // R3补轮：控件 id 按挂载唯一——快速换挂载（直接焦点切换）时同 id 会让
      // ArkUI 的 id 查找解析到尚未卸载的旧 TextInput，requestFocus 全部落空
      //（设备实测 ctx3 五次尝试均无 FOCUSED，注入无事件）；唯一 id 保证聚焦
      // 命中新挂载。
      'cjguiImeProxy-c' + snap.context + '-m' + this.proxyMountSerial++, snap.field,
      appInstance, snap.sessionToken, snap.text);
    this.imeMount = mount;
    this.imeText = snap.text; // Common mount publication was registered before this property write.
    // 每次挂载换新 controller（与 Pharos 同一 2026-10-01 咨询 X4 修复）：跨挂载
    // 复用的 controller 可能仍指向上一份实例，程序化 setTextSelection 命中旧
    // 组件（IME 侧动、getSelection/onTextSelectionChange 冻结在旧值）。
    this.imeTextController = new TextInputController();
    // 新挂载即新会话身份——attach 事实只对建立它的那个挂载有效（R2/R3）。
    if (retiredMount !== null) {
      this.selectionLifecycle.invalidateAttachmentFor(retiredMount);
    }
    this.mountedBaseVersion = snap.baseVersion;
    this.mountedNodeId = snap.nodeId;
    this.imeCtx = snap.context;
    this.selectionLifecycle.restoreMountAvailable(mount);
    this.proxyFocused = false;
    // R3：挂载即经共享生命周期签发安装请求（attach 门控 + 截止 + 确认归它）。
    this.selectionLifecycle.arm(mount, snap.selStart, snap.selEnd, 'mount');
    this.requestProxyFocus(mount, 0);
  }

  // requestFocus 只设置 ArkUI 焦点，不会附加系统输入法会话：模拟器/真机的
  // 键盘键入经输入法框架路由到「有输入会话的聚焦文本组件」，只聚焦不附加
  // 会话时打字不落字（实测手动核验点击后全无反应）。因此聚焦达成后必须
  // 经共享生命周期显式 attach（showTextInput 的身份门控/退避/截止归它）；
  // 控件刚挂载可能尚未完成布局，requestFocus 允许重试。
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
      this.selectionLifecycle.requestAttach(mount, 'focus');
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

  // native 落点推送（action=caret）：命中、长按全选与外部换版都会移动 caret，而代理
  // 只按自己的事件更新落点。不装回代理，人的下一次键入就落在代理的旧偏移上，
  // 平台也从未真正持有 native 选中的那段区间。
  private onProxyTextChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText): void {
    if (!this.proxyRegistry.isCurrent(m)) return;
    if (this.selectionLifecycle.observeRestoreText(m, value)) { return; }
    const composing: boolean = previewText !== undefined && previewText !== null
      && previewText.value !== undefined && previewText.value.length > 0;
    if (composing) {
      hilog.info(DOMAIN, TAG, 'ime proxy composition len=%{public}d offset=%{public}d',
        previewText!.value.length, previewText!.offset ?? 0);
    }
    if (this.selectionLifecycle.pendingMount() === m && value !== m.draft) {
      // 真人改文优先于落点安装：不再把光标拉回 native 推来的旧位置。
      this.selectionLifecycle.supersededByHumanInput(m);
      // R2：真实输入流到达（注册表按本挂载记账）——关闭程序回声括号。
      this.selectionLifecycle.noteTraffic(m);
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
    if (this.selectionLifecycle.observeRestoreSelection(m, selectStart, selectEnd)) { return; }
    this.proxyRegistry.observeSelection(m, selectStart, selectEnd);
    if (this.selectionLifecycle.pendingMount() === m) {
      const target: CjguiImeSelectionRead = this.selectionLifecycle.target();
      if (selectStart === target.start && selectEnd === target.end) {
        // 代理已观测到目标落点：安装收口，不再重投。单帧事件不足以证明平台
        // 安装稳定——走共享生命周期的跨帧确认窗口（矛盾观测记为失败证据）。
        this.imeSelStart = selectStart;
        this.imeSelEnd = selectEnd;
        this.selectionLifecycle.confirm(m, target.start, target.end,
          this.selectionLifecycle.currentSeq(), 'event', 0);
      } else {
        // 安装待办期间的不匹配观测是平台折叠/迟到覆盖的证据，不当人的导航
        // 上报；按票据身份消费回声括号后按住，待办由有界重试收口。
        this.selectionLifecycle.consumeSelectionObservation(m, selectStart, selectEnd);
        hilog.warn(DOMAIN, TAG,
          'ime selection install mismatch held target=[%{public}d,%{public}d) observed=[%{public}d,%{public}d)',
          target.start, target.end, selectStart, selectEnd);
        return;
      }
    } else {
      // R2：无待办时按**票据身份**分流程序回声：括号开启的第一条观测按程序
      // 回声消费；括号关闭后的观测（含合法收拢）是平台事实，必须上报。
      if (this.selectionLifecycle.consumeSelectionObservation(m, selectStart, selectEnd) === 'echo') {
        hilog.info(DOMAIN, TAG,
          'ime selection echo consumed (program command) [%{public}d,%{public}d) mount=%{public}s',
          selectStart, selectEnd, m.key.describe());
        return;
      }
    }
    this.imeSelStart = selectStart;
    this.imeSelEnd = selectEnd;
    const rc: string = entryNapi.imeSetSelection(selectStart, selectEnd, m.key.contextId) as string;
    hilog.info(DOMAIN, TAG, 'ime select [%{public}d,%{public}d) rc=%{public}s mount=%{public}s',
      selectStart, selectEnd, rc, m.key.describe());
  }





  private onProxyRestore(payload: ImeFocusPayload): void {
    this.selectionLifecycle.restore(new CjguiImeRestoreTicket(payload));
  }







  private onMenuInstalled(context: number): void {
    const mount = this.imeMount;
    const snap = this.readLiveEditingSnapshot();
    if (mount === null || context !== this.imeCtx || !this.proxyRegistry.isCurrent(mount) ||
      snap === null || snap.context !== context || snap.generation !== mount.key.editGeneration) { return; }
    const text = snap.previewText !== undefined ? snap.text.slice(0, snap.previewStart ?? 0) +
      snap.previewText + snap.text.slice(snap.previewEnd ?? snap.text.length) : snap.text;
    this.selectionLifecycle.restore(new CjguiImeRestoreTicket({ request: 0, context: snap.context, focusGeneration: snap.focusGeneration,
      generation: snap.generation, appInstance: snap.appInstance, sessionToken: snap.sessionToken,
      nodeId: snap.nodeId, resourceId: snap.resourceId, nodeKind: snap.nodeKind,
      bindingEpoch: snap.bindingEpoch, baseVersion: snap.baseVersion, field: snap.field, text: text,
      selStart: snap.selStart, selEnd: snap.selEnd,
      deadlineMonoMs: systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false) + 1500 }));
  }

  private onProxyCaret(payload: ImeFocusPayload): void {
    const ctx: number = payload.context;
    const mount: CjguiTextProxyMount | null = this.imeMount;
    if (mount === null || ctx !== this.imeCtx || !this.proxyRegistry.isCurrent(mount)) {
      hilog.info(DOMAIN, TAG, 'ime caret ignored ctx=%{public}d active=%{public}d', ctx, this.imeCtx);
      return;
    }
    if (this.selectionLifecycle.hasRestore()) return;
    this.selectionLifecycle.arm(mount, payload.selStart ?? -1, payload.selEnd ?? -1, 'caret');
    // caret 推送落在已 attach 的挂载上时立即安装；未 attach 则由共享生命周期
    // 等 attach 完成后投首笔（requestAttach 幂等）。
    this.selectionLifecycle.requestAttach(mount, 'caret');
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
