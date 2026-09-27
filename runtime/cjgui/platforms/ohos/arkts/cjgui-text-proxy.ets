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

  constructor(key: CjguiProxyKey, controlId: string, fieldId: string, initialText: string) {
    this.key = key;
    this.controlId = controlId;
    this.fieldId = fieldId;
    this.draft = initialText;
    this.alive = true;
    this.finishing = false;
  }
}

// 宿主页面注入的桥接能力（模板不直接依赖 entryNapi，便于复用与测试）。
export interface CjguiTextProxyBridge {
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
    this.bridge.logInfo(`proxy mounted key=${key.describe()} field=${fieldId}`);
    return m;
  }

  currentMount(): CjguiTextProxyMount | null {
    return this.current;
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

  // change：预览被拒 = 上下文已失效 → 自我收场（键盘随之收起），不清新挂载。
  // 返回裁决：'ok'=已接受；'rejected'=预览被拒（挂载已自我收场）；
  // 'stale'=事件携带的身份不是当前挂载（迟到/退役实例，已拒绝）。
  // 页面据此决定显示更新与收尾：绝不能让退役实例驱动当前显示或页面状态。
  onChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText): string {
    if (!this.validate(m)) {
      return 'stale';
    }
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
      m.alive = false;
      if (this.current === m) {
        this.current = null;
      }
      return 'rejected';
    }
    return 'ok';
  }

  // submit/blur：先置 finishing，再提交回**它自己的** context，最后只清理 m。
  // 返回裁决：'ok'=提交与结束均接受；'rejected'=至少一步被 owner 拒绝；
  // 'stale'=身份校验失败（未触碰 owner）。
  submitAndFinish(m: CjguiTextProxyMount, reason: string): string {
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
    return rc === '0' && end === '0' ? 'ok' : 'rejected';
  }

  // owner 外部换版推送携旧 context；只撤掉这个当前挂载，不提交旧草稿，
  // 新 context 的初值必须由页面重新读取 owner 快照后另行 mount。
  retireForReconcile(m: CjguiTextProxyMount, oldContext: number): string {
    if (!this.isCurrent(m) || m.key.contextId !== oldContext) {
      return 'stale';
    }
    m.alive = false;
    this.current = null;
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
      this.bridge.logInfo(`proxy released by framework ctx=${contextId}`);
      return true;
    }
    this.bridge.logInfo(`framework end ignored: ctx=${contextId} (not current)`);
    return false;
  }
}
