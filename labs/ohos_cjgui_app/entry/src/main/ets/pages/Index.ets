import { hilog } from '@kit.PerformanceAnalysisKit';
import { display } from '@kit.ArkUI';
import inputMethod from '@ohos.inputMethod';
import entryNapi from 'libentry.so';
// 官方互操作导入：经 ark_interop_loader 加载仓颉模块并完成运行时初始化。
import { probeRuntime, probeMagic } from 'libcjgui_app.so';
import { CjguiTextProxyRegistry, CjguiTextProxyMount, CjguiTextProxyBridge } from '../proxy/cjgui-text-proxy';

const TAG: string = 'CjguiApp';
const DOMAIN: number = 0x0000;

// 渲染器焦点请求负载：只带不透明上下文编号、字段名与动作类型，平台不解释几何。
// action 缺省视为 "focus"（向后兼容无 action 的旧负载）。
interface ImeFocusPayload {
  action?: string;
  context: number;
  field: string;
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
  baseVersion: number;
  mode: string;
  text: string;
}

// C：桥接适配器（ArkTS 严格模式要求类实现，不接受对象字面量）。
class EntryNapiTextProxyBridge implements CjguiTextProxyBridge {
  preview(contextId: number, text: string): string {
    return entryNapi.imePreviewText(text, contextId) as string;
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
  @State imeReadback: string = '-';
  // 当前挂载实例（身份持有者）：经 @Builder 按值捕获进事件闭包。
  // 置 null = 代理卸载；绝不在事件回调里用 currentMount() 重取身份。
  @State imeMount: CjguiTextProxyMount | null = null;
  // A3：宿主生命周期读数（phase / rendererDone / started / seam / 原生引用配平）。
  @State hostState: string = 'host state: -';
  // 验证接缝是否存在（= 测试产物）。普通产物为 false，UI 上不出现停止入口。
  @State verifySeam: boolean = false;

  private cycling: boolean = false;
  // 隐藏代理是否已获得 ArkUI 焦点（onFocus/onBlur 维护）；驱动聚焦重试与
  // showTextInput 的单次触发，不参与渲染，无需 @State。
  private proxyFocused: boolean = false;

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
              entryNapi.startHost();
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

          // 重新查询上下文快照：核对 owner 当前值（精确读回）。
          Button('READBACK')
            .onClick(() => {
              this.readbackActiveContext('manual');
            })
            .layoutWeight(1)
            .margin({ left: 8 })
        }
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
        this.proxyTextInput(this.imeMount)
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
      TextInput({ text: this.imeText })
        .id(m.controlId)
        .opacity(0.01)
        .position({ x: this.imeX, y: this.imeY })
        .width(this.imeW)
        .height(this.imeH)
        // 手动核验兜底：直接点落在代理几何内的真实点击也允许夺取焦点，
        // 不只依赖渲染器焦点请求 → requestFocus 的程序化路径。
        .focusable(true)
        .focusOnTouch(true)
        .onFocus(() => {
          // 用户可见的聚焦信号（底部状态栏），同时日志留痕。
          this.proxyFocused = true;
          this.status = `editing ${m.fieldId}: 已聚焦，请直接打字（回车提交）`;
          hilog.info(DOMAIN, TAG, 'ime proxy FOCUSED field=%{public}s mount=%{public}s',
            m.fieldId, m.key.describe());
        })
        .onChange((value: string) => {
          const verdict: string = this.proxyRegistry.onChange(m, value);
          hilog.info(DOMAIN, TAG, 'ime proxy onChange len=%{public}d verdict=%{public}s mount=%{public}s',
            value.length, verdict, m.key.describe());
          if (verdict === 'ok') {
            this.imeText = m.draft;
          } else if (verdict === 'rejected') {
            this.imeLastClosedCtx = m.key.contextId;
            if (this.imeCtx === m.key.contextId) {
              this.imeCtx = 0;
              this.imeMount = null;
            }
            this.status = `editing closed: preview rejected`;
          }
          // 'stale'：迟到/退役实例，仅日志，当前挂载与显示不受影响。
        })
        .onSubmit(() => {
          const verdict: string = this.proxyRegistry.submitAndFinish(m, 'submit');
          hilog.info(DOMAIN, TAG, 'ime proxy submit verdict=%{public}s mount=%{public}s',
            verdict, m.key.describe());
          if (verdict === 'ok') {
            this.imeLastClosedCtx = m.key.contextId;
            if (this.imeCtx === m.key.contextId) {
              this.imeCtx = 0;
              this.imeMount = null;
            }
          }
        })
        .onTextSelectionChange((selectStart: number, selectEnd: number) => {
          // C selection：真实选区变化 → 渲染器；身份用创建时的 m，不用当前 imeCtx。
          if (this.proxyRegistry.isCurrent(m)) {
            const rc: string = entryNapi.imeSetSelection(selectStart, selectEnd, m.key.contextId) as string;
            hilog.info(DOMAIN, TAG, 'ime select [%{public}d,%{public}d) rc=%{public}s mount=%{public}s',
              selectStart, selectEnd, rc, m.key.describe());
          }
        })
        .onBlur(() => {
          this.proxyFocused = false;
          const verdict: string = this.proxyRegistry.submitAndFinish(m, 'blur');
          hilog.info(DOMAIN, TAG, 'ime proxy blur verdict=%{public}s mount=%{public}s',
            verdict, m.key.describe());
          if (verdict === 'ok') {
            this.imeLastClosedCtx = m.key.contextId;
            if (this.imeCtx === m.key.contextId) {
              this.imeCtx = 0;
              this.imeMount = null;
            }
          }
        })
    }
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

  // ---- 文字代理交接 -------------------------------------------------------

  private onFocusRequest(payload: string): void {
    hilog.info(DOMAIN, TAG, 'ime focus payload=%{public}s', payload);
    let ctx: number = 0;
    let action: string = 'focus';
    try {
      const parsed: ImeFocusPayload = JSON.parse(payload) as ImeFocusPayload;
      ctx = parsed.context;
      if (parsed.action !== undefined && parsed.action.length > 0) {
        action = parsed.action;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime focus rejected: unparsable payload');
      return;
    }

    // 结束通知：框架侧已经结束这段编辑（点到别的控件/空白/换绑/节点移除）。
    // 框架在发出本通知前已经按失焦语义结算过一次（未提交的组合预览 → owner），
    // 因此这里只释放代理，绝不能再提交一次：该上下文此刻已失效，重复提交会被
    // 拒绝（rc=1），而即便成功也构成第二次结算。
    // 只有当前挂载的那一个上下文才响应，避免旧通知关掉新焦点。
    if (action === 'end') {
      // C：经注册表校验「是否当前挂载」——只有当前挂载响应 end；其余记录忽略。
      if (this.proxyRegistry.onFrameworkEnd(ctx)) {
        this.imeLastClosedCtx = ctx;
        this.imeCtx = 0;
        this.imeMount = null;
        this.status = `editing ended by framework (${ctx})`;
      } else {
        hilog.info(DOMAIN, TAG,
          'ime end ignored: ctx=%{public}d active=%{public}d', ctx, this.imeCtx);
      }
      return;
    }

    // C 顺序修复：先校验来访焦点的真实性（快照存在 + context 一致），**再**
    // 收尾当前挂载——旧实现先收尾后验证，晚到焦点即使最终被拒也已把上一段
    // 编辑提交并结束（实测 A→B 顺序缺陷）。
    const snapshotJson: string = entryNapi.imeEditingContext() as string;
    if (snapshotJson.length === 0) {
      hilog.warn(DOMAIN, TAG, 'ime focus rejected: no live context ctx=%{public}d', ctx);
      this.status = `focus rejected: no live context (${ctx})`;
      return;
    }
    let snap: ImeSnapshot;
    try {
      snap = JSON.parse(snapshotJson) as ImeSnapshot;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime snapshot unparsable');
      return;
    }
    if (snap.context !== ctx) {
      hilog.warn(DOMAIN, TAG,
        'ime focus rejected: stale ctx=%{public}d live=%{public}d', ctx, snap.context);
      this.status = `focus rejected: stale (${ctx}->${snap.context})`;
      return;
    }

    // 校验通过：先收尾当前挂载（提交回它自己的上下文），再挂载新实例。
    if (this.imeCtx !== 0) {
      this.commitAndFinish('focus-moved');
    }

    const density: number = this.displayDensity();
    this.imeCtx = snap.context;
    this.imeField = snap.field;
    this.imeText = snap.text;         // 初值来自 owner，不清空
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
      snap.context, snap.generation, 'cjguiImeProxy', snap.field, 1, 1, snap.text);
    this.imeMount = mount;
    this.proxyFocused = false;
    this.requestProxyFocus(mount, 0);
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

  // 提交当前缓冲到它自己的上下文，然后精确读回，再收尾。
  private commitAndFinish(reason: string): void {
    const ctx: number = this.imeCtx;
    if (ctx === 0) {
      return;
    }
    const text: string = this.imeText;
    const rc: string = entryNapi.imeCommitText(text, ctx) as string;
    this.imeLastCommitRc = rc;
    hilog.info(DOMAIN, TAG,
      'ime commit reason=%{public}s ctx=%{public}d rc=%{public}s len=%{public}d',
      reason, ctx, rc, text.length);
    if (rc !== '0') {
      // 提交被拒 = 该上下文已失效（换代/已结束/基版本不符）。缓冲不得被当作
      // 已落盘；读回只作为「owner 里的真实值」证据，不做成功声明。
      hilog.warn(DOMAIN, TAG,
        'ime commit rejected: context no longer valid ctx=%{public}d reason=%{public}s', ctx, reason);
    }

    // 精确读回：仍在活动期时按同一上下文回查 owner 的值与基版本。
    this.readbackActiveContext(reason);

    const end: string = entryNapi.imeFinishEditing(ctx) as string;
    hilog.info(DOMAIN, TAG, 'ime finish ctx=%{public}d rc=%{public}s', ctx, end);
    this.imeLastClosedCtx = ctx;
    this.imeCtx = 0;
    this.imeMount = null;
  }

  private readbackActiveContext(reason: string): void {
    const snapshotJson: string = entryNapi.imeEditingContext() as string;
    if (snapshotJson.length === 0) {
      this.imeReadback = `closed(${reason})`;
      hilog.info(DOMAIN, TAG, 'ime readback reason=%{public}s state=closed', reason);
      return;
    }
    try {
      const snap: ImeSnapshot = JSON.parse(snapshotJson) as ImeSnapshot;
      const match: number = snap.text === this.imeText ? 1 : 0;
      this.imeReadback = `${snap.field}="${snap.text}" v=${snap.baseVersion} match=${match}`;
      hilog.info(DOMAIN, TAG,
        'ime readback reason=%{public}s ctx=%{public}d live=%{public}d base=%{public}d '
        + 'sel=%{public}d,%{public}d match=%{public}d text=%{public}s',
        reason, this.imeCtx, snap.context, snap.baseVersion,
        snap.selStart, snap.selEnd, match, snap.text);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'ime readback unparsable');
    }
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
