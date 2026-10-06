// CJGUI 公共文字代理模板（框架拥有；由 sync_platform 同步进消费工程）。
//
// Sol 方案第 6 节：每个真实挂载捕获**不可变身份**；父组件的当前状态只用于
// 校验，绝不作为回调身份来源。回调一律捕获挂载实例——旧回调不能借新
// imeCtx 修改另一字段。
//
// ProxyKey = appInstance + sessionToken + contextId(editGeneration)
//          + mountGeneration
//  - contextId：native 编辑上下文编号（每次结束编辑递增，不复用）。
//  - mountGeneration：**每次真实挂载**递增；同一 context 的第二次挂载也得到
//    新 key，旧挂载的迟到回调一律被拒。

const TAG_PROXY = 'CjguiTextProxy';

export class CjguiProxyKey {
  readonly appInstance: number;
  readonly sessionToken: number;
  readonly contextId: number;
  readonly editGeneration: number;
  readonly mountGeneration: number;

  constructor(appInstance: number, sessionToken: number, contextId: number,
    editGeneration: number, mountGeneration: number) {
    this.appInstance = appInstance;
    this.sessionToken = sessionToken;
    this.contextId = contextId;
    this.editGeneration = editGeneration;
    this.mountGeneration = mountGeneration;
  }

  sameContext(other: CjguiProxyKey): boolean {
    return other !== undefined && other.contextId === this.contextId
      && other.editGeneration === this.editGeneration
      && other.mountGeneration === this.mountGeneration;
  }

  describe(): string {
    return `app${this.appInstance}/s${this.sessionToken}/c${this.contextId}` +
      `/e${this.editGeneration}/m${this.mountGeneration}`;
  }
}

// 一次挂载的全部可变状态。除模板外任何人不得写。
export class CjguiTextProxyMount {
  readonly key: CjguiProxyKey;
  readonly controlId: string;
  readonly fieldId: string;
  draft: string;
  alive: boolean;
  finishing: boolean;
  previewKnown: boolean = false;
  composing: boolean = false;
  // R2（2026-10-02 复核）：真实输入流证据是**本挂载**的观测——正文 A 上有过
  // 输入不能给新备注 B 的 12800009 开门。由注册表在真实改文（value != draft）
  // 时置位；页面级全局布尔已退役。
  trafficSeen: boolean = false;
  selectionText: string = '';
  selectionStart: number = -1;
  selectionEnd: number = -1;
  insertPending: boolean = false;
  deleteOperation: CjguiProxyDeleteOperation | null = null;

  constructor(key: CjguiProxyKey, controlId: string, fieldId: string, initialText: string) {
    this.key = key;
    this.controlId = controlId;
    this.fieldId = fieldId;
    this.draft = initialText;
    this.alive = true;
    this.finishing = false;
  }
}

// 平台程序改文的选择安装任务；普通恢复与菜单投影共用挂载/回声/观测纪律。
export class CjguiProxyInstallTask {
  mount: CjguiTextProxyMount;
  request: number;
  kind: string;
  targetText: string;
  targetStart: number;
  targetEnd: number;
  needsText: boolean;
  textObserved: boolean;
  selectionRetried: boolean;
  terminal: boolean;
  constructor(mount: CjguiTextProxyMount, request: number, targetText: string,
    targetStart: number, targetEnd: number, needsText: boolean, kind: string = 'restore') {
    this.mount = mount;
    this.request = request;
    this.kind = kind;
    this.targetText = targetText;
    this.targetStart = targetStart;
    this.targetEnd = targetEnd;
    this.needsText = needsText;
    this.textObserved = !needsText;
    this.selectionRetried = false;
    this.terminal = false;
  }
}

// A platform correction is observed, never pre-written into the owner/draft.
export class CjguiProxyDeleteOperation {
  readonly before: string;
  readonly expected: string;
  readonly start: number;
  readonly end: number;
  state: string = 'applying';
  constructor(before: string, expected: string, start: number, end: number) {
    this.before = before; this.expected = expected; this.start = start; this.end = end;
  }
}
interface CjguiProxyGraphemeRange { status: number; start: number; end: number; }

// 宿主页面注入的桥接能力（模板不直接依赖 entryNapi，便于复用与测试）。
export interface CjguiTextProxyBridge {
  grapheme(contextId: number, text: string, offset16: number): string;
  preview(contextId: number, text: string): string;   // rc '0' = 接受
  // text 是 TextInput 显示中的完整草稿；start/end 是其中的 marked UTF-16 半开范围。
  // native 同样按全文投影；不能把片段当成全文或把范围当成 owner 替换区间。
  previewRange(contextId: number, text: string, start: number, end: number): string;
  commit(contextId: number, text: string): string;    // rc '0' = 接受
  finish(contextId: number): string;                  // rc '0' = 结束
  logWarn(msg: string): void;
  logInfo(msg: string): void;
}

// 挂载注册表：单一 current 挂载 + 全部历史挂载的迟到回调防线。
export class CjguiTextProxyRegistry {
  private mounts: Map<number, CjguiTextProxyMount> = new Map();
  private current: CjguiTextProxyMount | null = null;
  private bridge: CjguiTextProxyBridge;
  private mountGeneration: number = 0;
  // R5（2026-10-02 Astra 裁决）：退役前驱（交接记录）。owned 节点同值换版会在
  // 页面挂载回声落地前把 context 推进（native external-version 分支），使该回声被
  // 以 stale 拒（native preview 唯一非零返回即 takeEditingContextLocked 失败）。
  // 输入必须立即关闭（isCurrent 一律拒），但保留**至多一条**可一次性消费的退役
  // 前驱，供合法 reconcile 交接；新挂载／明确终结／会话更换即令其失效。它不是
  // 「必有 successor」的断言，也不授权重挂——授权仍来自 reconcile 与有效目标快照。
  private retiredPredecessor: CjguiTextProxyMount | null = null;

  constructor(bridge: CjguiTextProxyBridge) {
    this.bridge = bridge;
  }

  // 每次真实挂载：新建独立实例（含独立 draft），旧实例**保持 alive 但退位**——
  // 它的迟到回调仍会按自身 key 被校验拒绝，但不会误清新挂载。
  mount(contextId: number, editGeneration: number, controlId: string, fieldId: string,
    appInstance: number, sessionToken: number, initialText: string): CjguiTextProxyMount {
    this.mountGeneration += 1;
    const key = new CjguiProxyKey(appInstance, sessionToken, contextId,
      editGeneration, this.mountGeneration);
    const m = new CjguiTextProxyMount(key, controlId, fieldId, initialText);
    this.mounts.set(key.mountGeneration, m);
    this.current = m;
    // 新挂载取代任何待消费的退役前驱（交接记录至多一条）。
    this.retiredPredecessor = null;
    this.bridge.logInfo(`proxy mounted key=${key.describe()} field=${fieldId}`);
    return m;
  }

  currentMount(): CjguiTextProxyMount | null {
    return this.current;
  }

  // R2：真实输入流证据（12800009 开门判据）按**挂载身份**查询。
  hasTraffic(m: CjguiTextProxyMount): boolean {
    return m !== null && m !== undefined && m.trafficSeen;
  }

  // 只读身份查询：m 是否仍是当前挂载（存活且未在收尾）。
  // 页面 selection 转发等只读场景用它做事件时校验，不产生副作用。
  isCurrent(m: CjguiTextProxyMount): boolean {
    return m !== null && m !== undefined && m.alive && !m.finishing && this.current === m;
  }

  // 迟到回调防线：只有「存活 + 仍是 current」的挂载才被处理。
  private validate(m: CjguiTextProxyMount): boolean {
    if (m === undefined || m === null) {
      return false;
    }
    if (!m.alive || m.finishing) {
      this.bridge.logWarn(`proxy callback rejected (not alive/finishing) ctl=${m.controlId}`);
      return false;
    }
    if (this.current !== m) {
      this.bridge.logWarn(`proxy callback rejected (stale mount) ctl=${m.controlId}`);
      return false;
    }
    return true;
  }

  // JS/ArkTS 字符串下标为 UTF-16 码元；范围边界不得切开代理对。
  private utf16Boundary(value: string, offset: number): boolean {
    if (offset <= 0 || offset >= value.length) {
      return true;
    }
    const before = value.charCodeAt(offset - 1);
    const after = value.charCodeAt(offset);
    return !(before >= 0xD800 && before <= 0xDBFF && after >= 0xDC00 && after <= 0xDFFF);
  }

  // 平台只给 offset + value；必须确认它是显示全文内完整、标量安全的片段。
  // 任何缺值、空片段或无效哨兵都只保留全文草稿，不能推断一次取消。
  private validMarkedRange(value: string, previewText: PreviewText): boolean {
    const offset = previewText.offset;
    const fragment = previewText.value;
    if (!Number.isInteger(offset) || offset < 0 || typeof fragment !== 'string'
      || fragment.length === 0 || offset + fragment.length > value.length
      || !this.utf16Boundary(value, offset)
      || !this.utf16Boundary(value, offset + fragment.length)
      || value.slice(offset, offset + fragment.length) !== fragment) {
      return false;
    }
    return true;
  }

  observeSelection(m: CjguiTextProxyMount, start: number, end: number): void {
    if (!this.validate(m)) { return; }
    m.selectionText = m.draft;
    m.selectionStart = start;
    m.selectionEnd = end;
  }

  onWillInsert(m: CjguiTextProxyMount): boolean {
    if (!this.validate(m)) { return false; }
    // ArkUI calls WillInsert before WillDelete for an IME replacement.
    // Such a deletion keeps its explicit range; it is never a plain backspace.
    m.insertPending = true;
    return true;
  }

  onWillChange(m: CjguiTextProxyMount, value: EditableTextChangeValue): boolean {
    if (!this.validate(m)) { return false; }
    const op = m.deleteOperation;
    if (op !== null && op.state === 'applying') {
      const options = value.options;
      return options !== undefined && options.oldContent === op.before
        && value.content === op.expected && options.rangeBefore.start === op.start
        && options.rangeBefore.end === op.end && options.rangeAfter.start === op.start
        && options.rangeAfter.end === op.start;
    }
    m.insertPending = false;
    return true;
  }

  onWillDelete(m: CjguiTextProxyMount, value: DeleteValue, actualStart: number,
    actualEnd: number, ready: boolean, deleteRange: (start: number, end: number) => void): boolean {
    if (!this.validate(m)) { return false; }
    if (m.insertPending || m.composing || !m.previewKnown) { return true; }
    if (!ready || m.deleteOperation !== null || actualStart !== m.selectionStart
      || actualEnd !== m.selectionEnd || m.selectionText !== m.draft) {
      this.bridge.logWarn('plain delete refused: proxy_observation_pending');
      return false;
    }
    // Explicit selection and forward deletion remain exact. The backward
    // formula below is bound to the verified WillDelete API, not DidDelete.
    if (actualStart !== actualEnd || value.direction !== TextDeleteDirection.BACKWARD) { return true; }
    const caret = actualStart;
    const count = value.deleteValue.length;
    const start = value.deleteOffset - count;
    if (count === 0 && caret === 0) { return true; }
    if (!Number.isInteger(caret) || value.deleteOffset !== caret || start < 0
      || caret > m.draft.length || !this.utf16Boundary(m.draft, start)
      || !this.utf16Boundary(m.draft, caret)
      || m.draft.slice(start, caret) !== value.deleteValue) {
      this.bridge.logWarn('plain delete refused: delete_observation_invalid');
      return false;
    }
    let range: CjguiProxyGraphemeRange;
    try { range = JSON.parse(this.bridge.grapheme(m.key.contextId, m.draft, caret - 1)) as CjguiProxyGraphemeRange; }
    catch (_) { this.bridge.logWarn('plain delete refused: grapheme_service_invalid'); return false; }
    if (!this.isCurrent(m) || range.status !== 0 || range.end !== caret || range.start < 0
      || range.start >= range.end) {
      this.bridge.logWarn('plain delete refused: grapheme_boundary_unavailable'); return false;
    }
    if (start <= range.start) { return true; } // exact whole cluster or explicit multi-cluster deletion
    const op = new CjguiProxyDeleteOperation(m.draft,
      m.draft.slice(0, range.start) + m.draft.slice(range.end), range.start, range.end);
    m.deleteOperation = op; // BEFORE controller: it re-enters WillChange.
    try { deleteRange(op.start, op.end); op.state = 'awaiting_echo'; }
    catch (_) { op.state = 'failed'; this.bridge.logWarn('plain delete failed: controller_exception'); }
    if (op.state === 'awaiting_echo') {
      setTimeout(() => {
        if (this.isCurrent(m) && m.deleteOperation === op && op.state === 'awaiting_echo') {
          op.state = 'failed';
          this.bridge.logWarn('plain delete failed: text_echo_unconfirmed');
        }
      }, 900);
    }
    // An attempted controller change ALWAYS cancels the original deletion.
    return false;
  }

  // change：预览被拒 = 上下文已失效 → 自我收场（键盘随之收起），不清新挂载。
  // 返回裁决：'ok'=已接受；'rejected'=预览被拒（挂载已自我收场）；
  // 'stale'=事件携带的身份不是当前挂载（迟到/退役实例，已拒绝）。
  // 页面据此决定显示更新与收尾：绝不能让退役实例驱动当前显示或页面状态。
  onChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText): string {
    if (!this.validate(m)) {
      return 'stale';
    }
    // R2：真实改文（value != 当前 draft）= 本挂载的真实输入流观测。
    if (value !== m.draft) {
      m.trafficSeen = true;
    }
    const operation = m.deleteOperation;
    if (operation !== null) {
      const observed = operation.state !== 'failed' && value === operation.expected;
      this.bridge.logInfo(`plain delete echo state=${operation.state} observed=${observed}`);
      // Always forward the REAL value once, including an unexpected/coalesced echo.
      m.deleteOperation = null;
    }
    m.previewKnown = previewText !== undefined && previewText !== null
      && previewText.offset === -1 && previewText.value === '';
    m.composing = previewText !== undefined && previewText !== null && typeof previewText.value === 'string' && previewText.value.length > 0;
    m.insertPending = false;
    m.draft = value;
    const hasMarkedRange = previewText !== undefined && previewText !== null
      && this.validMarkedRange(value, previewText);
    // 缺范围、空值与 -1 等无效哨兵均不证明取消。保留全文草稿投影。
    const rc: string = hasMarkedRange
      ? this.bridge.previewRange(m.key.contextId, value, previewText!.offset,
        previewText!.offset + previewText!.value.length)
      : this.bridge.preview(m.key.contextId, value);
    // bridge 可以同步触发新的焦点/挂载；旧回调不得更新页面显示。
    if (!this.isCurrent(m)) {
      return 'stale';
    }
    if (rc !== '0') {
      this.bridge.logWarn(`preview rejected ctx=${m.key.contextId} rc=${rc}; retiring mount`);
      // R5：输入立即关闭（isCurrent 一律拒），但保留可一次性消费的退役前驱，
      // 交合法 reconcile 交接——不得把这次 stale 拒绝当成终局拆除。
      m.alive = false;
      if (this.current === m) {
        this.current = null;
      }
      this.retiredPredecessor = m;
      return 'rejected';
    }
    return 'ok';
  }
  // submit/blur：先置 finishing，再提交回**它自己的** context，最后只清理 m。
  // 返回裁决：'ok'=提交与结束均接受；'rejected'=至少一步被 owner 拒绝；
  // 'stale'=身份校验失败（未触碰 owner）。
  submitAndFinish(m: CjguiTextProxyMount, reason: string): string {
    // R5：对退役前驱的明确终结请求直接使交接记录失效（不得留下可被迟到
    // reconcile 消费的幽灵）；前驱已 alive=false，validate 会判 stale。
    if (this.retiredPredecessor === m) {
      this.retiredPredecessor = null;
    }
    if (!this.validate(m)) {
      return 'stale';
    }
    m.finishing = true;
    const rc: string = this.bridge.commit(m.key.contextId, m.draft);
    this.bridge.logInfo(`commit reason=${reason} ctx=${m.key.contextId} rc=${rc}`);
    const end: string = this.bridge.finish(m.key.contextId);
    this.bridge.logInfo(`finish ctx=${m.key.contextId} rc=${end}`);
    m.alive = false;
    if (this.current === m) {
      this.current = null;
    }
    if (this.retiredPredecessor === m) {
      this.retiredPredecessor = null;
    }
    return rc === '0' && end === '0' ? 'ok' : 'rejected';
  }

  // owner 外部换版推送携旧 context；只撤掉这个当前挂载，不提交旧草稿，
  // 新 context 的初值必须由页面重新读取 owner 快照后另行 mount。
  // R5：也接受**本注册表认可的退役前驱**（preview 被 stale 拒后留下的交接记录），
  // 且只消费一次；绝不误清另一份 current。
  retireForReconcile(m: CjguiTextProxyMount, oldContext: number): string {
    const isCurrent: boolean = this.current === m && m.alive && !m.finishing;
    const isPredecessor: boolean = this.retiredPredecessor === m;
    if ((!isCurrent && !isPredecessor) || m.key.contextId !== oldContext) {
      return 'stale';
    }
    if (this.current === m) {
      this.current = null;
    }
    if (this.retiredPredecessor === m) {
      this.retiredPredecessor = null;
    }
    m.alive = false;
    this.bridge.logInfo(`proxy retired for external reconcile ctx=${oldContext}`);
    return 'retired';
  }

  // 迟到 focus 定时器：先校验存活 + 仍是 current，**再**交还页面执行
  // requestFocus——绝不能先收尾当前代理再验证（旧 A→B 顺序缺陷）。
  // 返回 true = 校验通过，页面应立即请求焦点。
  delayedFocus(m: CjguiTextProxyMount): boolean {
    if (m === null || m === undefined || !m.alive || m.finishing) {
      return false;
    }
    if (this.current !== m) {
      this.bridge.logWarn(`delayed focus rejected (stale mount) ctl=${m.controlId}`);
      return false;
    }
    return true;
  }

  // 框架侧 end 通知：只有当前挂载响应；其余一律记录并忽略。
  onFrameworkEnd(contextId: number): boolean {
    const cur = this.current;
    if (cur !== null && cur.key.contextId === contextId) {
      cur.alive = false;
      this.current = null;
      if (this.retiredPredecessor === cur) {
        this.retiredPredecessor = null;
      }
      this.bridge.logInfo(`proxy released by framework ctx=${contextId}`);
      return true;
    }
    // R5：退役前驱也响应框架 end（current 已为 null 不得使 end 静默失效）。
    const pred = this.retiredPredecessor;
    if (pred !== null && pred.key.contextId === contextId) {
      pred.alive = false;
      this.retiredPredecessor = null;
      this.bridge.logInfo(`proxy predecessor released by framework ctx=${contextId}`);
      return true;
    }
    this.bridge.logInfo(`framework end ignored: ctx=${contextId} (not current)`);
    return false;
  }
}

// ---------------------------------------------------------------------------
// S2 共享安装/确认生命周期（框架拥有；Pharos 与独立消费者共用，不各留一份
// 页面内实现）。页面只注入平台 seam；判据、序号门与终态收敛都在这里。
// ---------------------------------------------------------------------------

// 组件选区读数（页面从 imeTextController.getSelection() 映射；缺值用 -1）。
export class CjguiImeSelectionRead {
  readonly start: number;
  readonly end: number;
  constructor(start: number, end: number) {
    this.start = start;
    this.end = end;
  }
}

// 页面注入的平台 seam。桥不进模板：页面拥有 imeTextController / entryNapi /
// 输入流观测，生命周期只通过本接口读写它们。
export interface CjguiImeSelectionHost {
  // 系统输入会话发起（inputMethod.getController().showTextInput()）。
  attachSession(): Promise<void>;
  // S2/R2：12800009（client detached）的唯一开门证据——**本次挂载**观测到
  // 真实输入流（真人改文经代理 onChange 置位，注册表按挂载记账）。错误码
  // 本身不构成会话已建立的证据；前一编辑面（别的挂载）的输入也不行。
  hasImeTrafficEvidence(mount: CjguiTextProxyMount): boolean;
  // 组件选区读（getSelection）。实现抛异常由生命周期按终态证据处理。
  readSelection(): CjguiImeSelectionRead;
  // 组件选区写（start==end 用 caretPosition，否则 setTextSelection + HIDE）。
  setSelection(start: number, end: number): void;
  // 安装跨帧确认后向 native 结算（entryNapi.imeSetSelection）。
  // R2：必须回传 native 的真实接受结果（rc 字符串）；'0' 之外一律不是
  // INSTALLED——native 拒绝（rc=1）不能被记成安装成功。
  commitInstalled(start: number, end: number, contextId: number): string;
  // 挂载身份校验（proxyRegistry.isCurrent）。
  isCurrentMount(mount: CjguiTextProxyMount): boolean;
  // 恢复事务占用查询（非空时安装让位，具名 UNCONFIRMED）。
  restoreTaskActive(): boolean;
  logInfo(msg: string): void;
  logWarn(msg: string): void;
}

export class CjguiImeSelectionLifecycle {
  private host: CjguiImeSelectionHost;
  private selMount: CjguiTextProxyMount | null = null;
  private selStart: number = 0;
  private selEnd: number = 0;
  private selSeq: number = 0;
  private selTerminal: string = 'none';
  // attach 是**会话级**事实：同一挂载的输入会话一旦建立就一直有效，只随挂载
  // 变更失效；settle 不清它（否则拖选后的首笔非空 caret 被 waiting-for-attach
  // 挡住，非空选区丢失）。
  private attachedMount: CjguiTextProxyMount | null = null;
  private attachSeq: number = 0;
  // 12800009 是瞬时的（客户端随后重挂）：无证据时不清待办，有界重试 attach；
  // 只有重试耗尽才具名失败（fresh 挂载在首笔真人输入前恒无证据，一步终态
  // 会把瞬时分离变成永久失联——r17 实测）。
  private attachRetryLeft: number = 0;
  // R2（2026-10-02 复核）：一次安装请求的**固定截止**。覆盖整条链（attach
  // 无回调、退避重试、安装重投、跨帧确认），不只覆盖已 reject 后的重试——
  // attach Promise 永不回调时不再永久 pending。截止按 (mount, selSeq) 身份
  // 生效：旧请求的截止不得终结新请求；settle/换挂载即清理，计时器不累积。
  private deadlineTimer: number = -1;
  // R2：程序选区命令的回声括号。lifecycle 自己发的 setSelection/caretPosition
  // 会在平台产生 onTextSelectionChange 回声；括号开启时**第一条**观测按
  // 程序回声消费（丢弃），之后到来的观测（含合法收拢）都是新事实，必须
  // 上报 native——不得再按"非空→折叠"的形状规则吞掉（2026-10-02 复核）。
  private echoMount: CjguiTextProxyMount | null = null;
  private echoOpen: boolean = false;
  // R4：同一 (mount, selSeq) 的平台选区 setter 只下发一次。arm 与紧随的
  // requestAttach→maybeInstall 可能对同一 seq 各进一次 install（既有非幂等风险，
  // Astra 指出）；seq 单调递增，旧值不会撞上新请求，故无需跨请求复位。
  private installSentSeq: number = -1;
  // r18 接缝 1：让位只转移执行权。恢复事务占用期间保留同一待办（selMount/
  // selSeq）与原绝对截止（deadlineTimer 不清），零 setter、零采纳；恢复落定后
  // 原请求凭原 seq 与原截止继续，不重新 arm/重计截止。新 arm/显式退役清此旗。
  private yieldedToRestore: boolean = false;

  constructor(host: CjguiImeSelectionHost) {
    this.host = host;
  }

  // ---- 页面只读状态 ----
  terminal(): string {
    return this.selTerminal;
  }

  pendingMount(): CjguiTextProxyMount | null {
    return this.selMount;
  }

  target(): CjguiImeSelectionRead {
    return new CjguiImeSelectionRead(this.selStart, this.selEnd);
  }

  currentSeq(): number {
    return this.selSeq;
  }

  isAttachedTo(mount: CjguiTextProxyMount): boolean {
    return this.attachedMount === mount;
  }

  // 挂载变更：会话事实随旧挂载失效（新挂载必须重新走 attach）。
  invalidateAttachmentFor(mount: CjguiTextProxyMount): void {
    if (this.attachedMount === mount) {
      this.attachedMount = null;
    }
    if (this.selMount === mount) {
      // 换绑显式退役旧请求：具名恰一次终态（原 seq/截止随之收口），迟到旧回执
      // 凭 seq/挂载门零影响，不恢复已退役请求。
      this.settle(mount, 'UNCONFIRMED', 'mount_changed_retired');
    }
    if (this.echoMount === mount) {
      this.echoMount = null;
      this.echoOpen = false;
    }
  }

  // ---- 生命周期 ----

  // R2：为本请求排固定截止。清掉旧请求的计时器（不累积）。
  private scheduleDeadline(mount: CjguiTextProxyMount, seq: number): void {
    if (this.deadlineTimer !== -1) {
      clearTimeout(this.deadlineTimer);
      this.deadlineTimer = -1;
    }
    this.deadlineTimer = setTimeout(() => {
      this.deadlineTimer = -1;
      if (this.selMount === mount && this.selSeq === seq) {
        this.host.logWarn(`ime proxy selection deadline mount=${mount.key.describe()} seq=${seq}`);
        this.settle(mount, 'UNCONFIRMED', 'request_deadline');
      }
    }, 8000);
  }

  // 新目标入账（不立即安装：统一入口会等本次接续 attach 完成后投首笔；
  // 键盘/组合态同步在此之前会覆盖选区请求）。
  arm(mount: CjguiTextProxyMount, start: number, end: number, reason: string): void {
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || end < start) {
      this.host.logInfo(`ime proxy selection not installable reason=${reason} start=${start} end=${end}`);
      return;
    }
    this.selMount = mount;
    this.selStart = start;
    this.selEnd = end;
    this.selSeq += 1;
    this.selTerminal = 'pending';
    // 新意图取回执行权：旧让位状态随新 seq 终结（旧在飞计时器凭 seq 门自失效）。
    this.yieldedToRestore = false;
    // 新请求替代旧回声括号：旧请求的观测流到此为止。
    this.echoMount = null;
    this.echoOpen = false;
    this.scheduleDeadline(mount, this.selSeq);
    this.maybeInstall(mount, reason);
  }

  // attach（系统输入会话）的唯一发起口。幂等、带本次安装序号门控：旧 show 的
  // 迟到完成不得为新挂载/新一次安装开门；被拒即具名 UNCONFIRMED。
  requestAttach(mount: CjguiTextProxyMount, reason: string): void {
    // R4（2026-10-02 Astra 裁决）：attach 是**会话级事实**，其发起只依赖挂载身份
    // （仍是当前挂载），不与 pending 选区耦合。此前 `selMount !== mount` 的门使
    // 恢复让位（settle 清 selMount）之后的焦点 attach 永久静默早退——H 线实测
    // 笔记面「让位清 pending → 焦点 attach 被门挡 → 后续 caret 只等待 → 8s
    // request_deadline」。pending 只决定「有无选区要装」，见 maybeInstall。
    if (!this.host.isCurrentMount(mount)) {
      return;
    }
    if (this.attachedMount === mount) {
      this.maybeInstall(mount, reason);
      return;
    }
    const attachSeq: number = ++this.attachSeq;
    if (!reason.startsWith('retry-')) {
      this.attachRetryLeft = 4;
    }
    this.host.attachSession().then(() => {
      // R4：成功记账只要求「仍是当前挂载 + 本次尝试身份」——pending 选区可能已被
      // 恢复让位/真人输入清空，会话事实仍成立。若仍以 `selMount === mount` 门控，
      // 成功会被误判 stale、attachedMount 永不置位（Astra 反例 (b)）。
      if (!this.host.isCurrentMount(mount) || attachSeq !== this.attachSeq) {
        this.host.logInfo(`ime attach completed but stale seq=${attachSeq} live=${this.attachSeq}`);
        return;
      }
      this.attachedMount = mount;
      this.host.logInfo(`ime showTextInput ok field=${mount.fieldId} seq=${attachSeq} reason=${reason}`);
      this.maybeInstall(mount, 'attach');
    }).catch((err: Object) => {
      // 12800009 `input method client detached`（SDK @ohos.inputMethod.d.ts:555）：
      // 控制器与输入法客户端已分离。错误码**不单独**作为"沿用既有会话"的依据
      // （S2）：必须有真实输入流观测才能开门；无证据按具名失败收口，由 native
      // 有界重签。其它错误码：同样具名 UNCONFIRMED，保留可恢复源选择。
      const detail: string = JSON.stringify(err);
      let code: number = 0;
      try {
        const parsed: object = JSON.parse(detail) as object;
        const rec: Record<string, Object> = parsed as Record<string, Object>;
        const v: Object | undefined = rec['code'];
        if (typeof v === 'number') {
          code = v as number;
        }
      } catch (parseErr) {
        code = 0;
      }
      // R4（Astra 裁决）：把「会话恢复资格」与「选区结算资格」分开。
      //   会话资格 = 仍是当前挂载 + 本次尝试身份（与 pending 无关——attach 是
      //     会话级事实，恢复让位清 pending 不得取消会话的建立/恢复）。
      //   结算资格 = 会话资格 **且** 当前确有该挂载的 pending 选区（settle 无入口
      //     守卫：对已让位/被输入取代的旧选区追加终态会污染它的终态）。
      const sessionEligible: boolean = this.host.isCurrentMount(mount) && attachSeq === this.attachSeq;
      const selectionPending: boolean = this.selMount === mount;
      if (code === 12800009 && sessionEligible) {
        if (this.host.hasImeTrafficEvidence(mount)) {
          this.attachedMount = mount;   // 会话事实：无 pending 也保留
          this.host.logInfo(`ime attach reused (client detached, traffic seen) field=${mount.fieldId}` +
            ` seq=${attachSeq} reason=${reason}`);
          this.maybeInstall(mount, 'attach-reused');
        } else {
          // 无证据 ≠ 会话不存在（fresh 挂载首笔输入前恒无证据）：按瞬时分离
          // 处理，有界退避重试 attach；耗尽只终结**确有 pending** 的选区请求，
          // 无 pending 时仅记录会话未恢复（不重写旧选区终态）。
          this.host.logWarn(`ime attach detached, retrying (no traffic evidence yet) field=${mount.fieldId}` +
            ` seq=${attachSeq} reason=${reason} retriesLeft=${this.attachRetryLeft}`);
          if (this.attachRetryLeft <= 0) {
            if (selectionPending) {
              this.settle(mount, 'UNCONFIRMED', 'attach_reused_without_evidence');
            } else {
              this.host.logWarn(`ime attach unrecovered (no traffic evidence, no pending)` +
                ` field=${mount.fieldId} seq=${attachSeq}`);
            }
          } else {
            this.attachRetryLeft -= 1;
            const retryMount: CjguiTextProxyMount = mount;
            const retryReason: string = reason;
            const retrySeq: number = attachSeq;
            setTimeout(() => {
              // R4：重试票据归属——只有创建它的尝试仍是 live 时才重试。否则重试
              // 会递增 attachSeq，把更新的在飞成功/重试误判成 stale（Astra 指出
              // 的抢占：焦点路径与重试链互相淘汰）。
              if (this.host.isCurrentMount(retryMount) && retrySeq === this.attachSeq) {
                this.requestAttach(retryMount, `retry-${retryReason}`);
              }
            }, 150 * (5 - this.attachRetryLeft));
          }
        }
        return;
      }
      this.host.logWarn(`ime showTextInput rejected: ${detail} seq=${attachSeq} reason=${reason}`);
      if (sessionEligible && selectionPending) {
        this.settle(mount, 'UNCONFIRMED', 'attach_rejected');
      }
    });
  }

  // 安装待办的唯一入口。所有来源（焦点、attach 完成、定时重投）都经这里；
  // 门控 = 本次挂载 + 已完成 attach（attach 之前发出的选区请求会被随后的
  // 接续动作覆盖；平台对未聚焦组件的 setTextSelection 是早退 no-op）。
  maybeInstall(mount: CjguiTextProxyMount, reason: string): void {
    if (this.selMount !== mount || !this.host.isCurrentMount(mount)) {
      return;
    }
    if (this.attachedMount !== mount) {
      this.host.logInfo(`ime proxy selection waiting for attach reason=${reason} mount=${mount.key.describe()}`);
      return;
    }
    this.install(mount, this.selStart, this.selEnd, 0, this.selSeq, reason);
  }

  // 有界重投：焦点达成的那一帧平台会把光标推到末尾（或折叠选区），早装会被
  // 随后的重置覆盖，因此按挂载身份重投至多 8 次；观测到目标值即由回声终结。
  private install(mount: CjguiTextProxyMount, start: number, end: number,
    attempt: number, seq: number, reason: string): void {
    if (seq !== this.selSeq || this.selMount !== mount || !this.host.isCurrentMount(mount)) {
      return; // 已被新目标/新挂载/收尾取代的过期定时器
    }
    if (this.host.restoreTaskActive()) {
      // 恢复事务自己按票据装选区，不与之争夺控制器。让位只转移执行权：保留
      // 同一待办（selMount/selSeq）与原绝对截止（不清 deadlineTimer），零
      // setter、零采纳；恢复落定后原请求凭原 seq 继续，不重新 arm/重计截止。
      if (!this.yieldedToRestore) {
        this.yieldedToRestore = true;
        this.host.logInfo(`ime proxy selection yielded to restore task seq=${seq} ` +
          `target=[${start},${end}) mount=${mount.key.describe()} ` +
          `restore_task_took_over (pending retained)`);
      }
      const yieldMount: CjguiTextProxyMount = mount;
      const yieldStart: number = start;
      const yieldEnd: number = end;
      const yieldSeq: number = seq;
      const yieldReason: string = reason.endsWith('-resumed') ? reason : reason + '-resumed';
      const yieldAttempt: number = attempt;
      setTimeout(() => {
        this.install(yieldMount, yieldStart, yieldEnd, yieldAttempt, yieldSeq, yieldReason);
      }, 150);
      return;
    }
    this.yieldedToRestore = false;
    if (this.attachedMount !== mount) {
      this.host.logInfo(`ime proxy selection deferred (attach pending) reason=${reason} attempt=${attempt}`);
      if (attempt >= 8) {
        // 耗尽不是成功，也不静默清待办——记 UNCONFIRMED，由 native/窗口重签。
        this.settle(mount, 'UNCONFIRMED', `${reason}_attach_pending_exhausted`);
        return;
      }
      setTimeout(() => {
        this.install(mount, start, end, attempt + 1, seq, reason);
      }, 120 * (attempt + 1));
      return;
    }
    try {
      // R4：同一请求不重复下发平台 setter（跨帧确认窗口仍在跑）；重复下发只会
      // 让平台把落点再推一次、与确认窗口抢光标。seq 单调，故不会误挡新请求。
      if (seq === this.installSentSeq) {
        return;
      }
      this.installSentSeq = seq;
      this.host.setSelection(start, end);
      // R2：程序选区命令已下发——它的平台回声按本命令的括号消费。
      this.echoMount = mount;
      this.echoOpen = true;
      this.host.logInfo(`ime proxy selection set [${start},${end}) reason=${reason} attempt=${attempt}`);
    } catch (err) {
      this.host.logWarn(`ime proxy selection threw reason=${reason} err=${String(err)}`);
      this.settle(mount, 'UNCONFIRMED', `${reason}_throw`);
      return;
    }
    // setter 返回不构成安装证据（同值 setter 可不产生回声）；只做一次读数
    // 记日志，然后进入跨帧确认窗口。
    try {
      const actual: CjguiImeSelectionRead = this.host.readSelection();
      this.host.logInfo(`ime selection immediate read [${actual.start},${actual.end}) ` +
        `target=[${start},${end}) reason=${reason} (not evidence by itself)`);
    } catch (err) {
      this.host.logWarn(`ime selection getter unavailable reason=${reason} err=${String(err)}`);
    }
    // 首轮确认必须跨帧：本函数内联 confirm(...,0) 与 setter 落在同一毫秒，读到的是
    // 平台尚未回声的旧落点。设备原件（外部改版后的新 ctx=2 挂载）：
    //   ime proxy selection set [8,8) reason=attach attempt=0
    //   ime selection immediate read [2,2) target=[8,8) reason=attach (not evidence by itself)
    //   ime selection confirm mismatch round=0 target=[8,8) observed=[2,2)
    //   ime proxy selection terminal=UNCONFIRMED reason=attach_confirm_mismatch
    // 三条同毫秒 —— 代码自己声明即时读数"not evidence by itself"，却把它当成终态
    // 证据，连烧 8 张恢复票（与历史 ctx=3 八票全 platform_install_failed 同形）。
    setTimeout(() => {
      this.confirm(mount, start, end, seq, reason, 0);
    }, 32);
  }

  // 跨帧确认窗口：连续两帧读数精确命中目标才结算 INSTALLED；任何一次不命中
  // 即失败证据（终态，不重置预算重投）。
  confirm(mount: CjguiTextProxyMount, start: number, end: number,
    seq: number, reason: string, round: number): void {
    if (seq !== this.selSeq || this.selMount !== mount ||
      !this.host.isCurrentMount(mount) || this.attachedMount !== mount) {
      return; // 已被新目标/新挂载/收尾取代
    }
    if (this.host.restoreTaskActive()) {
      // 在飞确认让位：保留同一待办（selMount/selSeq）与原绝对截止（不清
      // deadlineTimer），不读数、不采纳、不结算；恢复释放后接续原轮次
      // （同 round），绝不重发 setter（confirm 本来就不下发平台写）。
      if (!this.yieldedToRestore) {
        this.yieldedToRestore = true;
        this.host.logInfo(`ime proxy selection confirm yielded to restore task seq=${seq} ` +
          `round=${round} target=[${start},${end}) mount=${mount.key.describe()} ` +
          `restore_task_took_over (pending retained)`);
      }
      const yieldMount: CjguiTextProxyMount = mount;
      const yieldStart: number = start;
      const yieldEnd: number = end;
      const yieldSeq: number = seq;
      const yieldReason: string = reason;
      const yieldRound: number = round;
      setTimeout(() => {
        this.confirm(yieldMount, yieldStart, yieldEnd, yieldSeq, yieldReason, yieldRound);
      }, 150);
      return;
    }
    this.yieldedToRestore = false;
    let observedStart: number = -1;
    let observedEnd: number = -1;
    try {
      const actual: CjguiImeSelectionRead = this.host.readSelection();
      observedStart = actual.start;
      observedEnd = actual.end;
    } catch (err) {
      this.host.logWarn(`ime selection confirm getter threw reason=${reason} err=${String(err)}`);
      // S2：getter 异常是终态证据，不是可跳过的一次读数——裸 return 会让安装
      // 永久 pending（离线证据 getter_throw → pending、无后续计时）。按失配
      // 分支同一条路结算 UNCONFIRMED，保留可恢复源选择。
      this.settle(mount, 'UNCONFIRMED', `${reason}_confirm_getter_threw`);
      return;
    }
    if (observedStart !== start || observedEnd !== end) {
      this.host.logWarn(`ime selection confirm mismatch round=${round} target=[${start},${end}) ` +
        `observed=[${observedStart},${observedEnd}) reason=${reason}`);
      // 确认窗口内的失配是终态证据：setter 已下发而读数仍不等于目标，说明平台
      // 把落点折叠/覆盖了；以重置预算重装只会无界循环。结算 UNCONFIRMED，
      // 由窗口按恢复事务有界重签。
      this.settle(mount, 'UNCONFIRMED', `${reason}_confirm_mismatch`);
      return;
    }
    if (round + 1 >= 2) {
      // 连续两帧命中：平台的稳定落点，而不是控制器自回声。
      // R2：native 的接受结果是 INSTALLED 的组成部分——rc != '0' 按具名
      // UNCONFIRMED 收口，保留可恢复源选择（生产反例：imeSetSelection
      // 返回 1 仍记 INSTALLED）。
      const rc: string = this.host.commitInstalled(observedStart, observedEnd, mount.key.contextId);
      if (rc !== '0') {
        this.host.logWarn(`ime selection native rejected rc=${rc} target=[${start},${end}) ` +
          `mount=${mount.key.describe()}`);
        this.settle(mount, 'UNCONFIRMED', `native_rejected_rc_${rc}`);
        return;
      }
      this.settle(mount, 'INSTALLED', `${reason}_confirmed`);
      return;
    }
    setTimeout(() => {
      this.confirm(mount, start, end, seq, reason, round + 1);
    }, 32);
  }

  // 安装待办的具名终态结算。INSTALLED 只在组件观测精确命中**且 native 接受**
  // 时给出；其余一律 UNCONFIRMED 并保留可恢复源选择——native 按失败取消该
  // 请求，由窗口的有界重试重新签发。不清 attachedMount（会话级事实）。
  settle(mount: CjguiTextProxyMount, terminal: string, reason: string): void {
    this.selTerminal = terminal;
    if (this.selMount === mount) {
      this.selMount = null;
      this.yieldedToRestore = false;
    }
    // R2：终态即清理——固定截止计时器与回声括号不跨请求存活。
    if (this.deadlineTimer !== -1) {
      clearTimeout(this.deadlineTimer);
      this.deadlineTimer = -1;
    }
    if (this.echoMount === mount) {
      this.echoMount = null;
      this.echoOpen = false;
    }
    this.host.logInfo(`ime proxy selection terminal=${terminal} reason=${reason} ` +
      `target=[${this.selStart},${this.selEnd}) mount=${mount.key.describe()} ` +
      `field=${mount.fieldId}`);
  }

  // R2：回声票据门（页面 onTextSelectionChange 的统一分流入口）。
  // 'echo' = 本条观测是生命周期刚下发的程序选区命令的回声（按括号消费，
  // 页面不上报 native）；'fact' = 平台事实（含合法收拢），页面必须上报。
  consumeSelectionObservation(mount: CjguiTextProxyMount,
    start: number, end: number): string {
    if (this.echoOpen && this.echoMount === mount) {
      this.echoOpen = false;
      this.host.logInfo(`ime selection echo consumed [${start},${end}) mount=${mount.key.describe()}`);
      return 'echo';
    }
    return 'fact';
  }

  // R2：真实改文到达 ⇒ 关闭回声括号。内容相关联的选区变化（组合提交后的
  // 收拢 caret 等）是平台事实，不是旧命令的回声。
  noteTraffic(mount: CjguiTextProxyMount): void {
    if (this.echoMount === mount) {
      this.echoMount = null;
      this.echoOpen = false;
    }
  }

  // 回声辅助：待办目标的精确命中判断（页面 onTextSelectionChange 用它分流
  // "目标命中 → 进确认窗口"与"待办期间失配 → 挂起不上报"）。
  echoMatchesTarget(mount: CjguiTextProxyMount, start: number, end: number): boolean {
    return this.selMount === mount && start === this.selStart && end === this.selEnd;
  }

  // 待办被真人改文取代（输入优先于落点安装：不把光标拉回旧位置）。
  supersededByHumanInput(mount: CjguiTextProxyMount): void {
    if (this.selMount === mount) {
      this.selMount = null;
    }
  }
}
