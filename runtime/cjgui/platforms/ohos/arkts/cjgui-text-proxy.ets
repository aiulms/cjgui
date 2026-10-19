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

import { FrameCallback } from '@ohos.arkui.UIContext';

const TAG_PROXY = 'CjguiTextProxy';

// onIdle is after rendering, rather than an elapsed-time guess that text has settled.
export class CjguiImeFrameCallback extends FrameCallback {
  private callback: (() => void) | null;
  constructor(callback: () => void) { super(); this.callback = callback; }
  onFrame(frameTimeInNano: number): void {}
  cancel(): void { this.callback = null; }
  onIdle(timeLeftInNano: number): void {
    const callback = this.callback;
    this.callback = null;
    if (callback !== null) { callback(); }
  }
}

// Selection reads belong to the next frame start, before SDK queued input is
// consumed by layout. Body settlement continues using the rendered idle phase.
export class CjguiImeSelectionFrameCallback extends FrameCallback {
  private callback: ((frameTime: number) => void) | null;
  constructor(callback: (frameTime: number) => void) { super(); this.callback=callback; }
  cancel(): void { this.callback=null; }
  onFrame(frameTimeInNano: number): void {
    const callback=this.callback;this.callback=null;
    if(callback!==null)callback(frameTimeInNano);
  }
  onIdle(timeLeftInNano: number): void {}
}

export interface CjguiImeRestorePayload {
  originalResult?: number;
  pendingFocus?: CjguiPendingFocusPayload;
  unmountedTransfer?: CjguiUnappearedTransferPayload;
  request?: number;
  context: number;
  generation?: number;
  focusGeneration?: number;
  appInstance?: number;
  sessionToken?: number;
  nodeId?: number;
  resourceId?: number;
  nodeKind?: number;
  bindingEpoch?: number;
  baseVersion?: number;
  deadlineMonoMs?: number;
  field: string;
  text?: string;
  selStart?: number;
  selEnd?: number;
}

export interface CjguiPendingFocusPayload {
  appInstance: number; sessionToken: number;
  sourceContext: number; sourceGeneration: number; focusGeneration: number;
  operation: number; context: number; generation: number;
  nodeId: number; resourceId: number; nodeKind: number; bindingEpoch: number;
  baseVersion: number; field: string; restoreRequest: number; deadlineMonoMs: number;
}
export interface CjguiUnappearedTransferPayload extends CjguiPendingFocusPayload {
  sourceMount: number;
}
export interface CjguiPendingFocusSnapshot {
  appInstance: number; sessionToken: number; context: number; generation: number;
  focusGeneration: number; nodeId: number; resourceId: number; nodeKind: number;
  bindingEpoch: number; baseVersion: number; field: string;
}
export interface CjguiImeRestoreTargetSnapshot extends CjguiPendingFocusSnapshot {
  restoreRequest: number; restoreDeadlineMonoMs: number;
  restoreProjectionVersion: number; restoreBindingEpoch: number;
}
// No fictitious component/mount is created for this scheduling source.
export class CjguiPendingFocusSource {
  readonly appInstance: number; readonly sessionToken: number;
  readonly contextId: number; readonly editGeneration: number; readonly focusGeneration: number;
  constructor(p: CjguiPendingFocusPayload) {
    this.appInstance=p.appInstance; this.sessionToken=p.sessionToken;
    this.contextId=p.sourceContext; this.editGeneration=p.sourceGeneration; this.focusGeneration=p.focusGeneration;
  }
}
export class CjguiPendingFocusSchedule {
  readonly source: CjguiPendingFocusSource;
  readonly operation: number; readonly context: number; readonly generation: number;
  readonly nodeId: number; readonly resourceId: number; readonly nodeKind: number;
  readonly bindingEpoch: number; readonly baseVersion: number; readonly field: string;
  readonly restoreRequest: number; readonly deadlineMonoMs: number;
  constructor(p: CjguiPendingFocusPayload) {
    this.source=new CjguiPendingFocusSource(p); this.operation=p.operation;
    this.context=p.context; this.generation=p.generation; this.nodeId=p.nodeId;
    this.resourceId=p.resourceId; this.nodeKind=p.nodeKind; this.bindingEpoch=p.bindingEpoch;
    this.baseVersion=p.baseVersion; this.field=p.field;
    this.restoreRequest=p.restoreRequest; this.deadlineMonoMs=p.deadlineMonoMs;
  }
  matches(snapshot: CjguiPendingFocusSnapshot): boolean {
    return snapshot.appInstance===this.source.appInstance && snapshot.sessionToken===this.source.sessionToken &&
      snapshot.context===this.context && snapshot.generation===this.generation &&
      snapshot.focusGeneration===this.source.focusGeneration && snapshot.nodeId===this.nodeId &&
      snapshot.resourceId===this.resourceId && snapshot.nodeKind===this.nodeKind &&
      snapshot.bindingEpoch===this.bindingEpoch && snapshot.baseVersion>=this.baseVersion && snapshot.field===this.field;
  }
}

// Native's frozen request. A mount is bound once later, never copied from current state.
export class CjguiImeRestoreTicket {
  readonly originalResult: number;
  readonly request: number;
  readonly context: number;
  readonly generation: number;
  readonly focusGeneration: number;
  readonly appInstance: number;
  readonly sessionToken: number;
  readonly nodeId: number;
  readonly resourceId: number;
  readonly nodeKind: number;
  readonly bindingEpoch: number;
  readonly baseVersion: number;
  readonly deadlineMonoMs: number;
  readonly field: string;
  readonly text: string;
  readonly start: number;
  readonly end: number;
  constructor(payload: CjguiImeRestorePayload) {
    this.originalResult=payload.originalResult ?? 0;
    this.request = payload.request ?? -1;
    this.context = payload.context;
    this.generation = payload.generation ?? -1;
    this.focusGeneration = payload.focusGeneration ?? -1;
    this.appInstance = payload.appInstance ?? -1;
    this.sessionToken = payload.sessionToken ?? -1;
    this.nodeId = payload.nodeId ?? -1;
    // -1 is native's valid no-resource presentation container, so missing
    // identity needs a distinct invalid sentinel. Exact target matching remains.
    this.resourceId = payload.resourceId ?? -2;
    this.nodeKind = payload.nodeKind ?? -1;
    this.bindingEpoch = payload.bindingEpoch ?? -1;
    this.baseVersion = payload.baseVersion ?? -1;
    this.deadlineMonoMs = payload.deadlineMonoMs ?? -1;
    this.field = payload.field;
    this.text = payload.text ?? '';
    this.start = payload.selStart ?? -1;
    this.end = payload.selEnd ?? -1;
  }
  valid(): boolean {
    return [this.originalResult, this.request, this.context, this.generation, this.focusGeneration, this.appInstance, this.sessionToken,
      this.nodeId, this.resourceId, this.nodeKind, this.bindingEpoch, this.baseVersion,
      this.deadlineMonoMs, this.start, this.end].every((value: number): boolean => Number.isSafeInteger(value))
      && this.originalResult >= 0 && this.request >= 0 && this.context > 0 && this.generation > 0 && this.focusGeneration > 0 && this.appInstance > 0
      && this.sessionToken > 0 && this.nodeId > 0 && this.resourceId >= -1 && this.nodeKind >= 0
      && this.bindingEpoch >= 0 && this.baseVersion >= 0 && this.field.length > 0
      && this.start >= 0 && this.end >= this.start && this.end <= this.text.length;
  }
  // Diagnostic of the same frozen validity contract. Never logs full text.
  validityMismatch(): string {
    const values: number[] = [this.originalResult,this.request,this.context,this.generation,this.focusGeneration,
      this.appInstance,this.sessionToken,this.nodeId,this.resourceId,this.nodeKind,this.bindingEpoch,
      this.baseVersion,this.deadlineMonoMs,this.start,this.end];
    const names: string[] = ['originalResult','request','context','generation','focusGeneration','appInstance',
      'sessionToken','nodeId','resourceId','nodeKind','bindingEpoch','baseVersion','deadlineMonoMs','start','end'];
    for(let i=0;i<values.length;i++) {
      if(!Number.isSafeInteger(values[i]))return `${names[i]} expected=safeInteger actual=${values[i]}`;
    }
    const minimums: number[] = [0,0,1,1,1,1,1,1,-1,0,0,0];
    for(let i=0;i<minimums.length;i++) {
      if(values[i]<minimums[i])return `${names[i]} expected>=${minimums[i]} actual=${values[i]}`;
    }
    if(this.field.length===0)return 'field expected=nonempty actual=empty';
    if(this.start<0)return `start expected>=0 actual=${this.start}`;
    if(this.end<this.start)return `end expected>=${this.start} actual=${this.end}`;
    if(this.end>this.text.length)return `end expected<=${this.text.length} actual=${this.end}`;
    return '';
  }
  targetMismatch(snap: CjguiImeRestoreTargetSnapshot | null, hostApp: number): string {
    if(snap===null)return 'snapshot expected=present actual=null';
    if(hostApp!==this.appInstance)return `hostAppInstance expected=${this.appInstance} actual=${hostApp}`;
    if(snap.appInstance!==this.appInstance)return `appInstance expected=${this.appInstance} actual=${snap.appInstance}`;
    if(snap.sessionToken!==this.sessionToken)return `sessionToken expected=${this.sessionToken} actual=${snap.sessionToken}`;
    if(snap.context!==this.context)return `context expected=${this.context} actual=${snap.context}`;
    if(snap.generation!==this.generation)return `generation expected=${this.generation} actual=${snap.generation}`;
    if(snap.focusGeneration!==this.focusGeneration)return `focusGeneration expected=${this.focusGeneration} actual=${snap.focusGeneration}`;
    if(snap.field!==this.field)return `field expected=${this.field} actual=${snap.field}`;
    if(snap.nodeId!==this.nodeId)return `nodeId expected=${this.nodeId} actual=${snap.nodeId}`;
    if(snap.resourceId!==this.resourceId)return `resourceId expected=${this.resourceId} actual=${snap.resourceId}`;
    if(snap.nodeKind!==this.nodeKind)return `nodeKind expected=${this.nodeKind} actual=${snap.nodeKind}`;
    if(this.request===0) {
      if(snap.baseVersion!==this.baseVersion)return `baseVersion expected=${this.baseVersion} actual=${snap.baseVersion}`;
      if(snap.bindingEpoch!==this.bindingEpoch)return `bindingEpoch expected=${this.bindingEpoch} actual=${snap.bindingEpoch}`;
      return '';
    }
    if(snap.restoreRequest!==this.request)return `restoreRequest expected=${this.request} actual=${snap.restoreRequest}`;
    if(snap.restoreDeadlineMonoMs!==this.deadlineMonoMs)return `restoreDeadlineMonoMs expected=${this.deadlineMonoMs} actual=${snap.restoreDeadlineMonoMs}`;
    if(snap.restoreProjectionVersion!==this.baseVersion)return `restoreProjectionVersion expected=${this.baseVersion} actual=${snap.restoreProjectionVersion}`;
    if(snap.restoreBindingEpoch!==this.bindingEpoch)return `restoreBindingEpoch expected=${this.bindingEpoch} actual=${snap.restoreBindingEpoch}`;
    return '';
  }
}

// NAPI geometry is already vp. The clipped viewport never changes the actual layout width.
export class CjguiProxyGeometry {
  readonly x: number; readonly y: number; readonly width: number; readonly height: number;
  readonly clipX: number; readonly clipY: number; readonly clipWidth: number; readonly clipHeight: number;
  constructor(x: number, proxyX: number, proxyY: number, layoutWidth: number, proxyWidth: number, proxyHeight: number) {
    this.x = x; this.y = proxyY; this.width = layoutWidth; this.height = proxyHeight;
    this.clipX = proxyX; this.clipY = proxyY; this.clipWidth = proxyWidth; this.clipHeight = proxyHeight;
  }
  valid(): boolean {
    return [this.x, this.y, this.width, this.height, this.clipX, this.clipY, this.clipWidth, this.clipHeight]
      .every((n: number): boolean => Number.isFinite(n)) && this.width > 0 && this.height > 0
      && this.clipWidth > 0 && this.clipHeight > 0;
  }
}

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
    return other !== undefined && other.appInstance === this.appInstance
      && other.sessionToken === this.sessionToken && other.contextId === this.contextId
      && other.editGeneration === this.editGeneration
      && other.mountGeneration === this.mountGeneration;
  }

  describe(): string {
    return `app${this.appInstance}/s${this.sessionToken}/c${this.contextId}` +
      `/e${this.editGeneration}/m${this.mountGeneration}`;
  }
}

export class CjguiProxyInputChange {
  readonly predecessor: number;
  readonly expectedPhysicalCommandId: number;
  readonly expectedCommandExecution: number;
  readonly id: number; readonly before: string; readonly after: string;
  readonly focusGeneration: number;
  // Local entry order only: a known older entry cannot complete this Will.
  // Not an SDK generation, and never used to select or grant an origin.
  readonly admittedAfterObservation: number;
  readonly start: number; readonly end: number; readonly afterStart: number; readonly afterEnd: number;
  constructor(id: number, before: string, after: string, start: number, end: number, afterStart: number, afterEnd: number, focusGeneration: number = 0, expectedPhysicalCommandId: number = 0, expectedCommandExecution: number = 0, predecessor: number = 0, admittedAfterObservation: number = 0) {
    this.id=id; this.before=before; this.after=after; this.start=start; this.end=end;
    this.afterStart=afterStart; this.afterEnd=afterEnd;
    this.focusGeneration=focusGeneration;this.expectedPhysicalCommandId=expectedPhysicalCommandId;
    this.expectedCommandExecution=expectedCommandExecution;
    this.predecessor=predecessor;
    this.admittedAfterObservation=admittedAfterObservation;
  }
}
// Compact observation-only identity. A digest can suppress an ambiguous late
// notification, never admit/complete an input; strong proof below uses exact
// original text/ranges and is independently checked against native tickets.
class CjguiProxyInputFingerprint {
  readonly units: number; readonly first: number; readonly second: number;
  constructor(value: string) {
    this.units=value.length;
    let first=0,second=0;
    for(let i=0;i<value.length;i++) {
      const unit=value.charCodeAt(i);
      first=((first<<5)-first+unit)>>>0;
      second=((second<<7)+second+unit)>>>0;
    }
    this.first=first;this.second=second;
  }
  same(other: CjguiProxyInputFingerprint): boolean {
    return this.units===other.units && this.first===other.first && this.second===other.second;
  }
}
class CjguiProxyCompletedInput {
  readonly id: number; readonly focusGeneration: number;
  readonly fingerprint: CjguiProxyInputFingerprint; readonly beforeFingerprint: CjguiProxyInputFingerprint;
  readonly start: number; readonly end: number; readonly afterStart: number; readonly afterEnd: number;
  constructor(input: CjguiProxyInputChange) {
    this.id=input.id;this.focusGeneration=input.focusGeneration;
    this.fingerprint=new CjguiProxyInputFingerprint(input.after);
    this.beforeFingerprint=new CjguiProxyInputFingerprint(input.before);
    this.start=input.start;this.end=input.end;this.afterStart=input.afterStart;this.afterEnd=input.afterEnd;
  }
  sameTransition(e: CjguiProxySDKChange): boolean {
    return this.focusGeneration===e.focus && e.beforeFingerprint!==null && this.beforeFingerprint.same(e.beforeFingerprint) &&
      this.fingerprint.same(e.fingerprint) && this.start===e.start && this.end===e.end &&
      this.afterStart===e.afterStart && this.afterEnd===e.afterEnd && e.previewPresent && e.previewOffset===-1 &&
      e.previewValue==='' && e.oldPreviewPresent && e.oldPreviewOffset===-1 && e.oldPreviewValue==='';
  }
}
// Immutable primitive values copied before logging, page gates or bridge reentry.
export class CjguiProxySDKChange {
  readonly key: CjguiProxyKey; readonly focus: number; readonly observation: number;
  readonly value: string; readonly before: string | undefined;
  readonly start: number | undefined; readonly end: number | undefined;
  readonly afterStart: number | undefined; readonly afterEnd: number | undefined;
  readonly previewPresent: boolean; readonly previewOffset: number | undefined; readonly previewValue: string | undefined;
  readonly oldPreviewPresent: boolean; readonly oldPreviewOffset: number | undefined; readonly oldPreviewValue: string | undefined;
  readonly rangesPresent: boolean;
  readonly fingerprint: CjguiProxyInputFingerprint;
  readonly beforeFingerprint: CjguiProxyInputFingerprint | null;
  constructor(m: CjguiTextProxyMount, observation: number, value: string, preview?: PreviewText, options?: TextChangeOptions) {
    this.key=m.key;this.focus=m.focusGeneration;this.observation=observation;this.value=value;
    this.before=options?.oldContent;this.start=options?.rangeBefore?.start;this.end=options?.rangeBefore?.end;
    this.afterStart=options?.rangeAfter?.start;this.afterEnd=options?.rangeAfter?.end;
    this.rangesPresent=options?.rangeBefore!==undefined && options?.rangeBefore!==null && options?.rangeAfter!==undefined && options?.rangeAfter!==null;
    this.previewPresent=preview!==undefined && preview!==null;this.previewOffset=preview?.offset;this.previewValue=preview?.value;
    this.oldPreviewPresent=options?.oldPreviewText!==undefined && options?.oldPreviewText!==null;
    this.oldPreviewOffset=options?.oldPreviewText?.offset;this.oldPreviewValue=options?.oldPreviewText?.value;
    this.fingerprint=new CjguiProxyInputFingerprint(value);
    this.beforeFingerprint=typeof this.before==='string'?new CjguiProxyInputFingerprint(this.before):null;
  }
  preview(): PreviewText | undefined {
    return this.previewPresent?{offset:this.previewOffset!,value:this.previewValue!}:undefined;
  }
  options(): TextChangeOptions | undefined {
    if(this.before===undefined || !this.rangesPresent)return undefined;
    return {oldContent:this.before,rangeBefore:{start:this.start,end:this.end},rangeAfter:{start:this.afterStart,end:this.afterEnd},
      oldPreviewText:this.oldPreviewPresent?{offset:this.oldPreviewOffset!,value:this.oldPreviewValue!}:undefined} as TextChangeOptions;
  }
  private validText(text: string): boolean {
    for(let i=0;i<text.length;i++) {
      const c=text.charCodeAt(i);
      if(c>=0xd800 && c<=0xdbff) {const next=text.charCodeAt(++i);if(!(next>=0xdc00 && next<=0xdfff))return false;}
      else if(c>=0xdc00 && c<=0xdfff)return false;
    }
    return true;
  }
  matches(input: CjguiProxyInputChange): boolean {
    return Number.isSafeInteger(this.observation) && this.observation>0 && this.focus===input.focusGeneration &&
      this.previewPresent && this.previewOffset===-1 && this.previewValue==='' &&
      this.oldPreviewPresent && this.oldPreviewOffset===-1 && this.oldPreviewValue==='' &&
      this.before===input.before && this.value===input.after && this.start===input.start && this.end===input.end &&
      this.afterStart===input.afterStart && this.afterEnd===input.afterEnd && this.validText(this.before) && this.validText(this.value);
  }
}
// Frozen at the actual original SDK callback, before its cancelled default.
export interface CjguiOrdinarySelectionSource { kind: number; id: number; deadline: number; }
export interface CjguiOriginalInsertExecution {
  readonly sourceKind: number; readonly sourceId: number; readonly focus: number;
  readonly mount: CjguiTextProxyMount; readonly text: string; readonly sequence: number;
  readonly deadline: number; readonly start: number; readonly end: number;
  installed: boolean;
  retentionCurrent(m: CjguiTextProxyMount): boolean;
  sourceCurrent(m: CjguiTextProxyMount): boolean;
  receiverExited(m: CjguiTextProxyMount): void;
}
export class CjguiOriginalInsertCommand {
  readonly callback: number; readonly text: string; readonly offset: number;
  readonly execution: CjguiOriginalInsertExecution;
  constructor(callback: number, value: InsertValue, execution: CjguiOriginalInsertExecution) {
    this.callback=callback;this.text=value.insertValue;this.offset=value.insertOffset;this.execution=execution;
  }
}
export class CjguiProxyPublication {
  readonly sequence: number; readonly key: CjguiProxyKey; readonly generation: number;
  readonly before: string; readonly after: string; readonly reason: string;
  readonly beforePreviewOffset: number; readonly beforePreviewText: string;
  willObserved: boolean = false; consumed: boolean = false;
  constructor(sequence: number, key: CjguiProxyKey, generation: number, before: string, after: string, reason: string, previewOffset: number, previewText: string) {
    this.sequence=sequence; this.key=key; this.generation=generation; this.before=before; this.after=after; this.reason=reason;
    this.beforePreviewOffset=previewOffset; this.beforePreviewText=previewText;
  }
}

// The id belongs to native producer admission, never to an SDK callback.
export class CjguiPhysicalSelectionCommand {
  readonly id: number; readonly key: CjguiProxyKey; readonly focus: number; readonly text: string;
  readonly publication: CjguiProxyPublication | null;
  readonly confirmSameValue: (command: CjguiPhysicalSelectionCommand) => void;
  readonly requestCurrent: (command: CjguiPhysicalSelectionCommand) => boolean;
  readonly inputAdmitted: (command: CjguiPhysicalSelectionCommand, id: number) => void;
  readonly receiverExited: (command: CjguiPhysicalSelectionCommand) => void;
  installSequence: number = 0;
  platformObserved: boolean = false;
  constructor(id: number, key: CjguiProxyKey, focus: number, text: string, publication: CjguiProxyPublication | null,
    confirmSameValue: (command: CjguiPhysicalSelectionCommand) => void,
    requestCurrent: (command: CjguiPhysicalSelectionCommand) => boolean,
    inputAdmitted: (command: CjguiPhysicalSelectionCommand, id: number) => void,
    receiverExited: (command: CjguiPhysicalSelectionCommand) => void = (command: CjguiPhysicalSelectionCommand): void => {}) {
    this.id=id;this.key=key;this.focus=focus;this.text=text;this.publication=publication;
    this.confirmSameValue=confirmSameValue;this.requestCurrent=requestCurrent;this.inputAdmitted=inputAdmitted;this.receiverExited=receiverExited;
  }
  sourceCurrent(m: CjguiTextProxyMount): boolean {
    const e=m.commandExecution;
    if(e!==null && e.command===this) {
      return m.selectionCommand===this && e.mount===m && e.text===m.draft && e.installed &&
        this.focus===m.focusGeneration && this.requestCurrent(this);
    }
    return m.selectionCommand===this && this.key===m.key && this.focus===m.focusGeneration &&
      this.text===m.draft && this.publication===m.publication && this.requestCurrent(this);
  }
  rangeCurrent(m: CjguiTextProxyMount, before: string, start: number, end: number): boolean {
    const e=m.commandExecution;
    return e!==null && e.command===this ? before===e.text && start===e.start && end===e.end :
      before===this.text && start===0 && end===this.text.length;
  }
  // Candidate identification only. Native atomically grants the unique input
  // against these original execution facts and the SDK's exact before/range.
  willSourceCandidate(m: CjguiTextProxyMount): boolean {
    const e=m.commandExecution;
    return e!==null && e.command===this && m.selectionCommand===this && e.mount===m &&
      e.text===m.draft && e.bodySettled && e.setterSent && e.firstObserved && !e.consumedInput &&
      e.publication===m.publication && e.publication.consumed && this.focus===m.focusGeneration && this.requestCurrent(this);
  }
}

export class CjguiPhysicalCommandExecution implements CjguiOriginalInsertExecution {
  readonly sourceKind: number = 4; readonly sourceId: number; readonly focus: number;
  readonly command: CjguiPhysicalSelectionCommand;
  readonly mount: CjguiTextProxyMount; readonly text: string;
  readonly sequence: number; readonly publication: CjguiProxyPublication;
  readonly attach: number; readonly install: number; readonly deadline: number;
  readonly start: number; readonly end: number;
  bodySettled: boolean = false; installed: boolean = false;
  setterSent: boolean = false; consumedInput: number = 0;
  firstFrameReady: boolean = false; firstObserved: boolean = false; secondFrameReady: boolean = false;
  firstFrameTime: number = -1; secondFrameTime: number = -1;
  selectionFrame: CjguiImeSelectionFrameCallback | null = null;
  constructor(command: CjguiPhysicalSelectionCommand, mount: CjguiTextProxyMount, sequence: number,
    publication: CjguiProxyPublication, attach: number, install: number, deadline: number, start: number, end: number) {
    this.command=command;this.mount=mount;this.text=mount.draft;this.sequence=sequence;this.publication=publication;
    this.attach=attach;this.install=install;this.deadline=deadline;this.start=start;this.end=end;
    this.sourceId=command.id;this.focus=command.focus;
  }
  retentionCurrent(m: CjguiTextProxyMount): boolean { return this.mount===m && this.focus===m.focusGeneration && m.publication===this.publication && this.publication.consumed; }
  sourceCurrent(m: CjguiTextProxyMount): boolean { return this.command.sourceCurrent(m); }
  receiverExited(m: CjguiTextProxyMount): void { this.command.receiverExited(this.command); }
}
export class CjguiOrdinarySelectionExecution implements CjguiOriginalInsertExecution {
  readonly sourceKind: number = 1; readonly sourceId: number; readonly focus: number;
  readonly mount: CjguiTextProxyMount; readonly text: string; readonly sequence: number;
  readonly deadline: number; readonly start: number; readonly end: number; readonly install: number;
  installed: boolean = false;
  constructor(m: CjguiTextProxyMount, source: CjguiOrdinarySelectionSource, sequence: number, install: number,
    start: number, end: number) {
    this.mount=m;this.text=m.draft;this.focus=m.focusGeneration;this.sourceId=source.id;
    this.deadline=source.deadline;this.sequence=sequence;this.install=install;this.start=start;this.end=end;
  }
  retentionCurrent(m: CjguiTextProxyMount): boolean { return this.sequence>0 && this.mount===m && m.ordinaryExecution===this && this.text===m.draft && this.focus===m.focusGeneration; }
  sourceCurrent(m: CjguiTextProxyMount): boolean { return this.installed && this.retentionCurrent(m); }
  receiverExited(m: CjguiTextProxyMount): void { if(m.ordinaryExecution===this)m.ordinaryExecution=null; }
}

// Observation only, scoped to one real command's actual mount. No source grant,
// platform completion or business write is made by this diagnostic record.
class CjguiProxyInputDiagnostic {
  readonly command: number; readonly key: CjguiProxyKey; readonly focus: number;
  sequence: number = 0; attempt: number = 0; entries: number = 0; bytes: number = 0;
  reason: string = ''; nativeTicket: number = 0;
  constructor(command: number, key: CjguiProxyKey, focus: number) {
    this.command=command;this.key=key;this.focus=focus;
  }
  short(value: string | undefined): string {
    return value===undefined?'absent':`len:${value.length},text:${value.length<=16?JSON.stringify(value):'frozen-large'}`;
  }
  write(bridge: CjguiTextProxyBridge, m: CjguiTextProxyMount, stage: string, detail: string): void {
    if(this.entries>=128 || this.bytes>=65536)return;
    const line=`input-callback-observation q=${this.command} sequence=${++this.sequence} attempt=${this.attempt} stage=${stage} key=${this.key.describe()} focus=${this.focus} currentFocus=${m.focusGeneration} pending=${m.pendingInput?.id ?? 0} draft=${this.short(m.draft)} publication=${m.publication?.sequence ?? 0} publicationConsumed=${m.publication?.consumed ?? false} retiredEcho=${m.retiredPublicationEcho?.sequence ?? 0} ${detail}`;
    // Conservatively charge UTF-16 log length as up to four UTF-8 bytes.
    const bytes=line.length*4;if(bytes>65536-this.bytes)return;
    this.entries++;this.bytes+=bytes;bridge.logInfo(line);
  }
}

class CjguiProgramSelectionWrite {
  readonly mount: CjguiTextProxyMount; readonly focus: number; readonly text: string;
  readonly sequence: number; readonly start: number; readonly end: number;
  constructor(m: CjguiTextProxyMount, seq: number, start: number, end: number) {
    this.mount=m;this.focus=m.focusGeneration;this.text=m.draft;this.sequence=seq;this.start=start;this.end=end;
  }
  current(m: CjguiTextProxyMount): boolean {
    return this.mount===m && this.focus===m.focusGeneration && this.text===m.draft;
  }
}

// 一次挂载的全部可变状态。除模板外任何人不得写。
export class CjguiTextProxyMount {
  selectionCommand: CjguiPhysicalSelectionCommand | null = null;
  commandExecution: CjguiPhysicalCommandExecution | null = null;
  inputDiagnostic: CjguiProxyInputDiagnostic | null = null;
  originalInsertExecution: CjguiOriginalInsertExecution | null = null;
  ordinaryExecution: CjguiOrdinarySelectionExecution | null = null;
  originalInsertCallback: number = 0;
  originalInstalledResult: CjguiImeRestoreTicket | null = null;
  programWriteDepth: number = 0;
  componentAppeared: boolean = false;
  componentDisappeared: boolean = false;
  pendingFocusSource: CjguiPendingFocusSource | null = null;
  structuralPredecessor: CjguiTextProxyMount | null = null;
  readonly key: CjguiProxyKey;
  readonly controlId: string;
  readonly fieldId: string;
  draft: string;
  focusGeneration: number = 0;
  structuralOperation: number = 0;
  structuralFocusGeneration: number = 0;
  reconcileScheduledOperation: number = 0;
  alive: boolean;
  finishing: boolean;
  previewKnown: boolean = false;
  lastPreviewOffset: number = -1;
  lastPreviewText: string = "";
  composing: boolean = false;
  // R2（2026-10-02 复核）：真实输入流证据是**本挂载**的观测——正文 A 上有过
  // 输入不能给新备注 B 的 12800009 开门。由注册表在真实改文（value != draft）
  // 时置位；页面级全局布尔已退役。
  trafficSeen: boolean = false;
  selectionText: string = '';
  selectionStart: number = -1;
  selectionEnd: number = -1;
  // References to native-admitted tickets only. Native owns the unchanged
  // 32-ticket/1Mi budget, causal admission and owner completion.
  pendingInputs: CjguiProxyInputChange[] = [];
  pairedInputIds: number[] = [];
  lastPairedInput: CjguiProxyInputChange | null = null;
  // Observation-only ID/digests retain no text bodies and share the 32-record
  // bound; native original 32-ticket/1Mi text and source budgets are unchanged.
  completedInputs: CjguiProxyCompletedInput[] = [];
  sdkChangeSequence: number = 0;
  get pendingInput(): CjguiProxyInputChange | null {
    return this.pendingInputs.length > 0 ? this.pendingInputs[0] : null;
  }
  semanticEchoes: CjguiProxyInputChange[] = [];
  publication: CjguiProxyPublication | null = null;
  retiredPublicationEcho: CjguiProxyPublication | null = null;
  publicationSequence: number = 0;
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
  registerPublication(text: string, reason: string): void {
    this.selectionCommand=null; // A new actual publication retires the old command source.
    this.commandExecution=null;
    this.ordinaryExecution=null;
    this.inputDiagnostic=null;
    this.publication = new CjguiProxyPublication(++this.publicationSequence, this.key,
      this.focusGeneration, reason === 'mount' ? '' : this.draft, text, reason, this.lastPreviewOffset, this.lastPreviewText);
  }
  observePublication(text: string): boolean {
    const p = this.publication;
    if (p === null || this.pendingInput !== null || !p.key.sameContext(this.key)
      || p.generation !== this.focusGeneration || p.after !== text) { return false; }
    if (!p.consumed && !p.willObserved && p.reason !== 'mount') { return false; }
    p.consumed = true; this.draft = text; return true;
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
  finish(contextId: number): string;                  // legacy explicit finish seam
  finishProxy(key: CjguiProxyKey, generation: number, text: string): string;
  originalInsert(mount: CjguiTextProxyMount, command: CjguiOriginalInsertCommand): string;
  originalInsertStatus(mount: CjguiTextProxyMount): string;
  originalInsertCancel(mount: CjguiTextProxyMount): string;
  originalInsertExit(mount: CjguiTextProxyMount, execution: CjguiOriginalInsertExecution, ticket: CjguiImeRestoreTicket): string;
  inputWill(mount: CjguiTextProxyMount, change: CjguiProxyInputChange): string;
  inputChange(mount: CjguiTextProxyMount, ticket: number, text: string, focusGeneration: number): string;
  inputChangePrefix(mount: CjguiTextProxyMount, anchor: number, evidence: CjguiProxySDKChange): string;
  focusAuthority(key: CjguiProxyKey, operation: number, generation: number,
    targetContext: number, targetGeneration: number): string;
  transferAuthority(key: CjguiProxyKey, target: CjguiPendingFocusSchedule, register: boolean): string;
  pendingFocusAuthority(source: CjguiPendingFocusSource, operation: number,
    targetContext: number, targetGeneration: number): string;
  closeSelectionCommandCapture(mount: CjguiTextProxyMount): string;
  logWarn(msg: string): void;
  logInfo(msg: string): void;
}

// Only current/predecessor are retained here. Old closures carry their own identity and
// fail isCurrent/validate; an all-history map would retain every obsolete bounded draft.
class CjguiStructuralTransferSchedule {
  readonly source: CjguiTextProxyMount;
  readonly target: CjguiPendingFocusSchedule;
  readonly execute: (target: CjguiPendingFocusSchedule) => void;
  readonly qualify: (target: CjguiPendingFocusSchedule) => boolean;
  readonly retire: (mount: CjguiTextProxyMount) => void;
  readonly model: CjguiTextProxyMount | null;
  constructor(source: CjguiTextProxyMount, target: CjguiPendingFocusSchedule,
    execute: (target: CjguiPendingFocusSchedule) => void,
    qualify: (target: CjguiPendingFocusSchedule) => boolean,
    retire: (mount: CjguiTextProxyMount) => void, model: CjguiTextProxyMount | null) {
    this.source=source; this.target=target; this.execute=execute;
    this.qualify=qualify; this.retire=retire; this.model=model;
  }
}

// Terminal event metadata only: no mount, text, command or history graph.
class CjguiPhysicalKeyEventReceipt {
  readonly event: string;
  readonly key: CjguiProxyKey;
  readonly focus: number;
  readonly handled: boolean;
  constructor(event: string, key: CjguiProxyKey, focus: number, handled: boolean) {
    this.event=event;this.key=key;this.focus=focus;this.handled=handled;
  }
}

export class CjguiTextProxyRegistry {
  private current: CjguiTextProxyMount | null = null;
  private physicalKeyReceipts: Array<CjguiPhysicalKeyEventReceipt> = [];
  // One inert component lifecycle record. Native alone grants later structure.
  private endedComponent: CjguiTextProxyMount | null = null;
  private bridge: CjguiTextProxyBridge;
  private mountGeneration: number = 0;
  private pendingFocus: CjguiPendingFocusSchedule | null = null;
  private structuralPredecessor: CjguiTextProxyMount | null = null;
  private structuralTransfer: CjguiStructuralTransferSchedule | null = null;
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
    const previous=this.current, predecessor=this.structuralPredecessor;
    const ended=this.endedComponent, retired=this.retiredPredecessor, pending=this.pendingFocus;
    const transfer=this.structuralTransfer;
    const m = new CjguiTextProxyMount(key, controlId, fieldId, initialText);
    try {
      m.focusGeneration = Number(this.bridge.focusAuthority(key, 1, 0, 0, 0));
    } catch (error) {
      m.alive=false;
      this.bridge.logWarn(`proxy mount refused key=${key.describe()} reason=native_exception`);
      return m;
    }
    // Native admission is not a publication. A rejected or synchronously
    // superseded request must leave the original component and handoff intact.
    if (!Number.isSafeInteger(m.focusGeneration) || m.focusGeneration<=0 ||
      this.mountGeneration!==key.mountGeneration || this.current!==previous ||
      this.structuralTransfer!==transfer || this.structuralPredecessor!==predecessor ||
      this.endedComponent!==ended || this.retiredPredecessor!==retired || this.pendingFocus!==pending) {
      m.alive=false;
      this.bridge.logWarn(`proxy mount refused key=${key.describe()} reason=admission_or_superseded`);
      return m;
    }
    this.endedComponent=null;
    if (transfer!==null && (transfer.target.context!==contextId || transfer.target.generation!==editGeneration ||
      transfer.target.source.appInstance!==appInstance || transfer.target.source.sessionToken!==sessionToken ||
      transfer.target.field!==fieldId)) {
      this.structuralTransfer=null; this.structuralPredecessor=null;
    }
    this.current = m;
    m.structuralPredecessor = this.structuralPredecessor;
    if (pending !== null && contextId === pending.context && editGeneration === pending.generation &&
      appInstance === pending.source.appInstance && sessionToken === pending.source.sessionToken &&
      m.focusGeneration === pending.source.focusGeneration) { m.pendingFocusSource = pending.source; }
    // 新挂载取代任何待消费的退役前驱（交接记录至多一条）。
    this.retiredPredecessor = null;
    m.registerPublication(initialText, 'mount');
    this.bridge.logInfo(`proxy mounted key=${key.describe()} field=${fieldId}`);
    return m;
  }

  acceptNativeFocus(m: CjguiTextProxyMount, expectedGeneration: number): boolean {
    if (m === null || this.current !== m || !m.alive || m.finishing || expectedGeneration <= 0) { return false; }
    let generation: number=0;
    try { generation=Number(this.bridge.focusAuthority(m.key, 1, 0, 0, 0)); }
    catch (error) {
      this.bridge.logWarn(`proxy focus refused key=${m.key.describe()} reason=native_exception`);
      return false;
    }
    if (generation !== expectedGeneration || this.current!==m || !m.alive || m.finishing) {
      this.bridge.logWarn(`proxy focus refused key=${m.key.describe()} reason=admission_or_superseded expected=${expectedGeneration}`);
      return false;
    }
    if (m.focusGeneration!==generation) { m.selectionCommand=null; }
    m.focusGeneration = generation;
    return this.isCurrent(m);
  }
  componentMounted(m: CjguiTextProxyMount): boolean {
    if (!this.isCurrent(m) ||
      Number(this.bridge.focusAuthority(m.key,8,m.focusGeneration,0,0))!==m.focusGeneration) { return false; }
    m.componentAppeared=true;
    if (this.structuralTransfer?.target.context===m.key.contextId &&
      this.structuralTransfer.target.generation===m.key.editGeneration) { this.structuralTransfer=null; }
    if (m.structuralPredecessor===this.structuralPredecessor) { this.structuralPredecessor=null; }
    const pending=this.pendingFocus;
    if (pending!==null && pending.context===m.key.contextId && pending.generation===m.key.editGeneration &&
      pending.source.focusGeneration===m.focusGeneration) { this.pendingFocus=null; }
    return true;
  }
  retireUnappearedPendingModel(m: CjguiTextProxyMount, target: CjguiPendingFocusSchedule): boolean {
    const source=m.pendingFocusSource;
    if (this.current!==m || !m.alive || m.finishing || m.componentAppeared || source===null ||
      source.appInstance!==target.source.appInstance || source.sessionToken!==target.source.sessionToken ||
      source.contextId!==target.source.contextId || source.editGeneration!==target.source.editGeneration ||
      source.focusGeneration!==target.source.focusGeneration || m.key.contextId===target.context) { return false; }
    m.alive=false;
    this.current=null;
    return true;
  }
  retireUnappearedTransferModel(m: CjguiTextProxyMount, target: CjguiPendingFocusSchedule): boolean {
    const source=this.structuralPredecessor;
    if (source===null || this.current!==m || m.componentAppeared || !m.alive || m.finishing ||
      m.structuralPredecessor!==source || target.source.appInstance!==source.key.appInstance ||
      target.source.sessionToken!==source.key.sessionToken || target.source.contextId!==source.key.contextId ||
      target.source.editGeneration!==source.key.editGeneration ||
      target.source.focusGeneration!==source.structuralFocusGeneration ||
      source.structuralOperation!==target.operation ||
      !this.reconcileTargetCurrent(source,target.context,target.generation)) { return false; }
    m.alive=false;this.current=null;
    return true;
  }
  // The native record owns the first mounted A -> B and later unappeared
  // B -> C alike. A real component disappearance is a separate platform fact.
  receiveStructuralTransfer(payload: CjguiUnappearedTransferPayload,
    execute: (target: CjguiPendingFocusSchedule) => void,
    retire: (mount: CjguiTextProxyMount) => void,
    qualify: (target: CjguiPendingFocusSchedule) => boolean = (): boolean => true): string {
    const candidates: Array<CjguiTextProxyMount | null>=[this.current,this.structuralPredecessor,
      this.retiredPredecessor,this.endedComponent];
    let source: CjguiTextProxyMount | null=null;
    for (const candidate of candidates) {
      if (candidate!==null && payload.appInstance===candidate.key.appInstance &&
        payload.sessionToken===candidate.key.sessionToken && payload.sourceContext===candidate.key.contextId &&
        payload.sourceGeneration===candidate.key.editGeneration && payload.sourceMount===candidate.key.mountGeneration &&
        payload.field===candidate.fieldId && (candidate!==this.endedComponent ||
          payload.focusGeneration===candidate.focusGeneration)) { source=candidate; break; }
    }
    if (source===null || source.finishing || payload.context===source.key.contextId ||
      !Number.isSafeInteger(payload.operation) || payload.operation<=0 ||
      !Number.isSafeInteger(payload.focusGeneration) || payload.focusGeneration<=0 ||
      !Number.isSafeInteger(payload.context) || payload.context<=0 ||
      !Number.isSafeInteger(payload.generation) || payload.generation<=0) { return 'refused'; }
    const target=new CjguiPendingFocusSchedule(payload);
    if (!qualify(target)) { return 'refused'; }
    const prior=this.structuralTransfer;
    if (prior!==null && prior.source===source && prior.target.operation===target.operation) {
      return prior.target.context===target.context && prior.target.generation===target.generation &&
        Number(this.bridge.transferAuthority(source.key,target,false))===target.operation ? 'accepted' : 'refused';
    }
    const model=this.current;
    if (model!==null && model!==source &&
      (model.componentAppeared || model.finishing || !model.alive || model.structuralPredecessor!==source)) { return 'refused'; }
    // Exact operation and live binding are compared atomically by native before
    // this registry or the Page can retire anything. An old notification is inert.
    if (Number(this.bridge.transferAuthority(source.key,target,true))!==target.operation) { return 'refused'; }
    // The exact native operation grants this real component the new focus for
    // subsequent keys only. Existing input/command tickets retain their frozen
    // key/focus; this retired source receives no general new-Will authority.
    source.focusGeneration=target.source.focusGeneration;
    if (this.endedComponent===source) { this.endedComponent=null; }
    source.structuralOperation=target.operation;
    source.structuralFocusGeneration=target.source.focusGeneration;
    this.structuralPredecessor=source;
    this.structuralTransfer=new CjguiStructuralTransferSchedule(source,target,execute,qualify,retire,
      model!==source ? model : null);
    if (model===source || this.retiredPredecessor===source) {
      source.alive=false;
      if (this.current===source) { this.current=null; }
      if (this.retiredPredecessor===source) { this.retiredPredecessor=null; }
      retire(source);
    }
    this.scheduleStructuralTransfer();
    return 'accepted';
  }

  componentDisappeared(m: CjguiTextProxyMount): void {
    m.componentDisappeared=true;
    this.bridge.closeSelectionCommandCapture(m);
    if (this.structuralTransfer?.source===m) { this.scheduleStructuralTransfer(); }
  }

  private scheduleStructuralTransfer(): void {
    const pending=this.structuralTransfer;
    if (pending===null || (pending.source.componentAppeared && !pending.source.componentDisappeared)) { return; }
    const source=pending.source, target=pending.target;
    this.scheduleReconcileTarget(source,target.context,target.generation,()=>{
      if (this.structuralTransfer!==pending || !pending.qualify(target) ||
        Number(this.bridge.transferAuthority(source.key,target,false))!==target.operation) { return; }
      const model=pending.model;
      if (model!==null) {
        if (this.current!==model || !model.alive || model.finishing || model.componentAppeared ||
          model.structuralPredecessor!==source) { return; }
        model.alive=false; this.current=null; pending.retire(model);
      }
      if (this.current!==null) { return; }
      pending.execute(target);
    });
  }

  // Kept for callers that already own an unappeared intermediate model.
  receiveUnappearedTransfer(payload: CjguiUnappearedTransferPayload,
    execute: (target: CjguiPendingFocusSchedule) => void): boolean {
    return this.receiveStructuralTransfer(payload,execute,()=>{})==='accepted';
  }

  // Same UI-turn executor as mounted transfer. The native-origin record can
  // schedule a first target; actual mount/attach/restore still own input admission.
  receivePendingFocus(payload: CjguiPendingFocusPayload,
    execute: (target: CjguiPendingFocusSchedule) => void): boolean {
    if (!Number.isSafeInteger(payload.appInstance) || payload.appInstance<=0 ||
      !Number.isSafeInteger(payload.sessionToken) || payload.sessionToken<=0 ||
      !Number.isSafeInteger(payload.sourceContext) || payload.sourceContext<=0 ||
      !Number.isSafeInteger(payload.sourceGeneration) || payload.sourceGeneration<=0 ||
      !Number.isSafeInteger(payload.focusGeneration) || payload.focusGeneration<=0 ||
      !Number.isSafeInteger(payload.operation) || payload.operation<=0 ||
      !Number.isSafeInteger(payload.context) || payload.context<=0 ||
      !Number.isSafeInteger(payload.generation) || payload.generation<=0) { return false; }
    const target = new CjguiPendingFocusSchedule(payload);
    const registered = Number(this.bridge.pendingFocusAuthority(target.source,6,target.context,target.generation));
    if (registered!==target.operation) { return false; }
    const prior = this.pendingFocus;
    if (prior !== null && prior.operation===target.operation && prior.source.appInstance===target.source.appInstance &&
      prior.source.sessionToken===target.source.sessionToken && prior.source.focusGeneration===target.source.focusGeneration &&
      prior.source.contextId===target.source.contextId && prior.source.editGeneration===target.source.editGeneration &&
      prior.context===target.context && prior.generation===target.generation) { return true; }
    this.pendingFocus=target;
    setTimeout(() => {
      if (this.pendingFocus!==target ||
        Number(this.bridge.pendingFocusAuthority(target.source,7,target.context,target.generation))!==target.operation) { return; }
      execute(target);
    },0);
    return true;
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
    return m !== null && m !== undefined && m.alive && !m.finishing && this.current === m
      && m.focusGeneration > 0
      && Number(this.bridge.focusAuthority(m.key, 2, m.focusGeneration, 0, 0)) === m.focusGeneration;
  }

  tracePhysicalKey(m: CjguiTextProxyMount, event: KeyEvent, phase: string): void {
    this.bridge.logInfo(`physical key entry=${phase} key=${m.key.describe()} focus=${m.focusGeneration}` +
      ` type=${event.type} code=${event.keyCode} source=${event.keySource} device=${event.deviceId} timestamp=${event.timestamp}`);
  }

  private physicalEventIdentity(event: KeyEvent): string | null {
    if(![event.timestamp,event.type,event.keyCode,event.keySource,event.deviceId]
      .every((n: number): boolean => Number.isSafeInteger(n)) || event.timestamp<=0) { return null; }
    return `${event.timestamp}/${event.type}/${event.keyCode}/${event.keySource}/${event.deviceId}`;
  }

  physicalKeyPreImeEvent(m: CjguiTextProxyMount, event: KeyEvent, blocked: boolean,
    lifecycle: CjguiImeSelectionLifecycle,
    send: (context: number, generation: number, intent: string) => string): boolean {
    return this.dispatchPhysicalKeyEvent(m,event,blocked,lifecycle,send,true);
  }

  physicalKeyEvent(m: CjguiTextProxyMount, event: KeyEvent, blocked: boolean,
    lifecycle: CjguiImeSelectionLifecycle,
    send: (context: number, generation: number, intent: string) => string): boolean {
    return this.dispatchPhysicalKeyEvent(m,event,blocked,lifecycle,send,false);
  }

  private dispatchPhysicalKeyEvent(m: CjguiTextProxyMount, event: KeyEvent, blocked: boolean,
    lifecycle: CjguiImeSelectionLifecycle,
    send: (context: number, generation: number, intent: string) => string, preIme: boolean): boolean {
    const phase=preIme?'onKeyPreIme':'onKeyEvent';
    this.tracePhysicalKey(m,event,phase);
    if(preIme && (event.type!==KeyType.Down || event.keyCode!==2017)) { return false; }
    const identity=this.physicalEventIdentity(event);
    if(event.type===KeyType.Down && event.keyCode===2017 && identity!==null) {
      for(const receipt of this.physicalKeyReceipts)if(receipt.event===identity) {
        this.bridge.logInfo(`physical key original-terminal phase=${phase} event=${identity}`+
          ` original=${receipt.key.describe()}/${receipt.focus} callback=${m.key.describe()}/${m.focusGeneration}`+
          ` handled=${receipt.handled}`);
        return receipt.handled;
      }
    }
    if(event.getModifierKeyState===undefined) {
      this.bridge.logWarn(`physical key refused phase=${phase} code=${event.keyCode} timestamp=${event.timestamp} reason=modifier_unavailable`);
      return false;
    }
    let shift: boolean=false, ctrl: boolean=false;
    try {
      shift=event.getModifierKeyState(['Shift']);
      ctrl=event.getModifierKeyState(['Ctrl']);
      this.bridge.logInfo(`physical key modifiers key=${m.key.describe()} focus=${m.focusGeneration}` +
        ` available=${event.getModifierKeyState!==undefined} shift=${shift} ctrl=${ctrl}`);
    } catch (error) {
      this.bridge.logWarn(`physical key modifier exception phase=${phase} code=${event.keyCode} timestamp=${event.timestamp} key=${m.key.describe()} focus=${m.focusGeneration}`);
      throw new Error('physical key modifier API failed');
    }
    if(preIme && !ctrl) { return false; }
    const selectionCommand=event.type===KeyType.Down && ctrl && event.keyCode===2017;
    if(selectionCommand && identity===null) {
      this.bridge.logWarn(`physical select_all phase=refused reason=event_identity_unavailable entry=${phase}`);
      return true;
    }
    const key=m.key,focus=m.focusGeneration;
    const handled=this.physicalKey(m,event.keyCode,event.type===KeyType.Down,shift,ctrl,blocked,lifecycle,
      (context: number, generation: number, intent: string): string => {
        const reply=send(context,generation,intent);
        this.bridge.logInfo(`physical key admission phase=${phase} event=${identity ?? 'unavailable'} key=${key.describe()} focus=${focus} reply=${reply}`);
        return reply;
      });
    if(selectionCommand && identity!==null) {
      this.physicalKeyReceipts.push(new CjguiPhysicalKeyEventReceipt(identity,key,focus,handled));
      if(this.physicalKeyReceipts.length>32)this.physicalKeyReceipts.shift();
    }
    return handled;
  }

  physicalKey(m: CjguiTextProxyMount, keyCode: number, down: boolean, shift: boolean, ctrl: boolean,
    blocked: boolean, lifecycle: CjguiImeSelectionLifecycle,
    send: (context: number, generation: number, intent: string) => string): boolean {
    if (!down) { return false; }
    if(keyCode!==2014 && keyCode!==2015 && !(ctrl && keyCode===2017)) { return false; }
    if(m.originalInsertExecution!==null && (keyCode===2014 || keyCode===2015 || (ctrl && keyCode===2017))) {
      this.bridge.originalInsertCancel(m);m.originalInsertExecution=null;
      lifecycle.supersededByPhysicalNavigation(m);
    }
    const ordinaryEligible=this.validate(m);
    const captureEligible=ctrl && keyCode===2017 && m.componentAppeared && !m.componentDisappeared &&
      (this.current===m || this.structuralPredecessor===m || this.structuralTransfer?.source===m || this.endedComponent===m);
    this.bridge.logInfo(`physical key eligibility code=${keyCode} key=${m.key.describe()} focus=${m.focusGeneration}`+
      ` ordinary=${ordinaryEligible} capture=${captureEligible} alive=${m.alive} finishing=${m.finishing}`+
      ` appeared=${m.componentAppeared} disappeared=${m.componentDisappeared} current=${this.current===m}`+
      ` predecessor=${this.structuralPredecessor===m} transferSource=${this.structuralTransfer?.source===m} ended=${this.endedComponent===m}`);
    if (!ordinaryEligible && !captureEligible) {
      this.bridge.logInfo(`physical key refused code=${keyCode} reason=authority key=${m.key.describe()} focus=${m.focusGeneration}`);
      return false;
    }
    if (!ctrl || keyCode!==2017) {
      const handled=this.plainKey(m,keyCode,down,shift,blocked && m.selectionCommand===null,send);
      if (handled && m.selectionCommand!==null) {
        lifecycle.supersededByPhysicalNavigation(m);m.selectionCommand=null;
      }
      return handled;
    }
    if (m.composing) { this.bridge.logInfo('physical select_all phase=refused composition');return true; }
    const k=m.key;const focus=m.focusGeneration;const text=m.draft;const publication=m.publication;
    const reply=Number(send(k.contextId,k.editGeneration,
      `select_all,${k.appInstance},${k.sessionToken},${k.contextId},${k.editGeneration},${k.mountGeneration},${focus}`));
    if ((ordinaryEligible ? !this.isCurrent(m) : m.componentDisappeared) ||
      m.focusGeneration!==focus || m.draft!==text || m.publication!==publication) {
      this.bridge.logInfo('physical select_all phase=retired_during_admission');return true;
    }
    if (reply===2) { this.bridge.logInfo('physical select_all phase=unhandled');return false; }
    if (!Number.isSafeInteger(reply) || reply<=2) { this.bridge.logInfo('physical select_all phase=refused');return true; }
    const command=new CjguiPhysicalSelectionCommand(reply-2,k,focus,text,publication,
      (command: CjguiPhysicalSelectionCommand): void => lifecycle.completeCommandInput(
        lifecycle.commandMount(command) ?? m,command,'physical_command_range_observed_at_same_value_will'),
      (command: CjguiPhysicalSelectionCommand): boolean => lifecycle.commandCurrent(lifecycle.commandMount(command) ?? m,command),
      (command: CjguiPhysicalSelectionCommand, id: number): void => lifecycle.consumeCommandSourceAtWill(
        lifecycle.commandMount(command) ?? m,command,id),
      (command: CjguiPhysicalSelectionCommand): void => lifecycle.originalReceiverExited(command));
    m.selectionCommand=command;
    this.bridge.logInfo(`physical select_all phase=queued id=${reply-2} key=${k.describe()} focus=${m.focusGeneration}`);
    if(ordinaryEligible) { lifecycle.armPhysicalCommand(m); }
    else { lifecycle.capturePhysicalCommand(m,command); }
    return true;
  }

  // Physical key intent carries this mount's identity. Other fields and compositions
  // retain the platform's normal handling when native has no owned range session.
  plainKey(m: CjguiTextProxyMount, keyCode: number, down: boolean, shift: boolean,
    blocked: boolean, send: (context: number, generation: number, intent: string) => string): boolean {
    if (!down || blocked || !this.validate(m) || m.composing) { return false; }
    let intent: string = '';
    if (keyCode === 2014) { intent = shift ? 'extendLeft' : 'left'; }
    else if (keyCode === 2015) { intent = shift ? 'extendRight' : 'right'; }
    else { return false; }
    return send(m.key.contextId, m.key.editGeneration, intent) === '0';
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
    return this.isCurrent(m);
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

  onWillInsert(m: CjguiTextProxyMount, value?: InsertValue, lifecycle?: CjguiImeSelectionLifecycle): boolean {
    const d=m.inputDiagnostic;
    if(d!==null){d.attempt++;d.write(this.bridge,m,'WillInsert-in',`offset=${value?.insertOffset ?? -1} insert=${d.short(value?.insertValue)}`);}
    if (!this.validate(m)) { d?.write(this.bridge,m,'WillInsert-out','result=false reason=validate');return false; }
    lifecycle?.joinPendingOrdinary(m, 'original-WillInsert');
    const held=m.originalInsertExecution;
    const receiverStatus=held!==null?this.bridge.originalInsertStatus(m):'0';
    if(held!==null && receiverStatus==='4' && held.installed && held.sourceCurrent(m) &&
      m.selectionText===m.draft && m.selectionStart===held.start && m.selectionEnd===held.end) {
      m.originalInsertExecution=null; // New callback after terminal-without-owner and real original installation.
    }
    const installed=m.originalInstalledResult;
    if(held!==null && receiverStatus==='3' && installed!==null && installed.originalResult>0 &&
      m.pendingInput===null && this.bridge.originalInsertExit(m,held,installed)==='0') {
      m.originalInsertExecution=null;
      held.receiverExited(m);
    }
    const e=m.originalInsertExecution ?? m.commandExecution ?? m.ordinaryExecution;
    if(e!==null && (m.originalInsertExecution!==null || !e.installed)) {
      // Queued reception cannot confer SDK completion or owner acceptance.
      // All matching successors retain this SAME original Q and deadline.
      const eligible=value!==undefined && Number.isSafeInteger(value.insertOffset) && value.insertOffset>=0 &&
        value.insertValue.length>0 && value.insertValue.length<=32768 && !m.composing &&
        m.previewKnown && m.lastPreviewOffset===-1 && m.lastPreviewText==='' && m.pendingInput===null && m.programWriteDepth===0 &&
        e.mount===m && e.focus===m.focusGeneration &&
        (m.originalInsertExecution===e || e.retentionCurrent(m));
      if(eligible) {
        const original=new CjguiOriginalInsertCommand(++m.originalInsertCallback,value!,e);
        const id=Number(this.bridge.originalInsert(m,original));
        m.originalInsertExecution=e;
        d?.write(this.bridge,m,'WillInsert-out',`result=false originalCommand=${id} callback=${original.callback} sourceKind=${e.sourceKind} source=${e.sourceId} execution=${e.sequence} reason=${id>0?'original_retained':'original_refused'}`);
      } else {
        d?.write(this.bridge,m,'WillInsert-out','result=false reason=original_receiver_source_refused');
      }
      return false;
    }
    // ArkUI calls WillInsert before WillDelete for an IME replacement.
    // Such a deletion keeps its explicit range; it is never a plain backspace.
    m.insertPending = true;
    d?.write(this.bridge,m,'WillInsert-out','result=true reason=original_insert_guard');
    return true;
  }

  onDidInsert(m: CjguiTextProxyMount, value: InsertValue): void {
    const d=m.inputDiagnostic;
    d?.write(this.bridge,m,'DidInsert',`offset=${value.insertOffset} insert=${d.short(value.insertValue)} observationOnly=true`);
  }

  onWillChange(m: CjguiTextProxyMount, value: EditableTextChangeValue): boolean {
    const d=m.inputDiagnostic;const o=value.options;
    if(d!==null){d.reason='';d.nativeTicket=0;d.write(this.bridge,m,'WillChange-in',`old=${d.short(o?.oldContent)} value=${d.short(value.content)} oldEqualsDraft=${o?.oldContent===m.draft} oldEqualsExecution=${o?.oldContent===m.commandExecution?.text} rangeBefore=${JSON.stringify(o?.rangeBefore)} rangeAfter=${JSON.stringify(o?.rangeAfter)} preview=${JSON.stringify(value.previewText)} oldPreview=${JSON.stringify(o?.oldPreviewText)}`);}
    const result=this.classifyWillChange(m,value);
    d?.write(this.bridge,m,'WillChange-out',`result=${result} reason=${d.reason || 'original_classifier'} nativeTicket=${d.nativeTicket}`);
    return result;
  }
  private classifyWillChange(m: CjguiTextProxyMount, value: EditableTextChangeValue): boolean {
    if (!this.validate(m)) { if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='validate';return false; }
    const op = m.deleteOperation;
    if (op !== null && op.state === 'applying') {
      if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='delete_operation_echo';
      const options = value.options;
      return options !== undefined && options.oldContent === op.before
        && value.content === op.expected && options.rangeBefore.start === op.start
        && options.rangeBefore.end === op.end && options.rangeAfter.start === op.start
        && options.rangeAfter.end === op.start;
    }
    m.insertPending = false;
    const options = value.options;
    const publication = m.publication;
    if (publication !== null && !publication.consumed && options !== undefined &&
      publication.key.sameContext(m.key) && publication.generation === m.focusGeneration &&
      options.oldContent === publication.before && value.content === publication.after &&
      value.previewText !== undefined && value.previewText.offset === -1 && value.previewText.value === '' &&
      options.oldPreviewText !== undefined && options.oldPreviewText.offset === publication.beforePreviewOffset &&
      options.oldPreviewText.value === publication.beforePreviewText &&
      options.rangeBefore.start === 0 && options.rangeBefore.end === publication.before.length &&
      options.rangeAfter.start === 0 && options.rangeAfter.end === publication.after.length) {
      publication.willObserved = true;if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='publication_echo';return true;
    }
    const command=m.selectionCommand;
    const physicalInitialSameValue=publication!==null && publication.reason==='mount' && publication.before==='' &&
      publication.after.length>0 && command!==null && command.sourceCurrent(m) && command.publication===publication &&
      options!==undefined && options.oldContent===command.text && value.content===command.text &&
      value.previewText!==undefined && value.previewText.offset===-1 && value.previewText.value==='' &&
      options.oldPreviewText!==undefined && options.oldPreviewText.offset===-1 && options.oldPreviewText.value==='' &&
      options.rangeBefore.start===0 && options.rangeBefore.end===command.text.length &&
      options.rangeAfter.start===0 && options.rangeAfter.end===command.text.length;
    if (publication !== null && !publication.consumed && value.content === publication.after && !physicalInitialSameValue) {
      if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='publication_metadata_mismatch';
      this.bridge.logWarn('publication Will refused: frozen metadata mismatch'); return false;
    }
    const ordinary = value.previewText !== undefined && value.previewText.offset === -1 && value.previewText.value === '' &&
      options !== undefined && options.oldPreviewText !== undefined && options.oldPreviewText.offset === -1 && options.oldPreviewText.value === '';
    if (!ordinary) {
      if(m.originalInsertExecution!==null){this.bridge.originalInsertCancel(m);m.originalInsertExecution=null;}
      if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='marked_route';return true;
    }
    const predecessor=m.pendingInputs.length>0?m.pendingInputs[m.pendingInputs.length-1]:null;
    const beforeText=predecessor===null?m.draft:predecessor.after;
    if ((predecessor!==null && predecessor.focusGeneration!==m.focusGeneration) || options!.oldContent !== beforeText) { if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='old_content_mismatch';return false; }
    const before = options!.rangeBefore; const after = options!.rangeAfter;
    // SDK TextRange endpoints are optional. A missing endpoint is refused rather
    // than inferred from the current selection or the component's defaults.
    const start = before.start ?? -1; const end = before.end ?? -1;
    const afterStart = after.start ?? -1; const afterEnd = after.end ?? -1;
    if (![start,end,afterStart,afterEnd].every((n: number): boolean => Number.isSafeInteger(n)) ||
      start < 0 || end < start || end > beforeText.length || afterStart !== start ||
      afterEnd < afterStart || afterEnd > value.content.length || !this.utf16Boundary(beforeText,start) ||
      !this.utf16Boundary(beforeText,end) || !this.utf16Boundary(value.content,afterStart) ||
      !this.utf16Boundary(value.content,afterEnd) ||
      beforeText.slice(0,start)+value.content.slice(afterStart,afterEnd)+beforeText.slice(end) !== value.content) { if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='range_scalar_splice';return false; }
    return this.freezeInput(m, new CjguiProxyInputChange(0,beforeText,value.content,start,end,afterStart,afterEnd),true);
  }
  private freezeInput(m: CjguiTextProxyMount, change: CjguiProxyInputChange, actualOrdinaryWill: boolean = false): boolean {
    if (change.before === change.after && m.semanticEchoes.length >= 32) { if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='semantic_echo_capacity';return false; }
    const focusGeneration=m.focusGeneration;const publication=m.publication;const command=m.selectionCommand;
    const predecessor=m.pendingInputs.length>0?m.pendingInputs[m.pendingInputs.length-1]:null;
    if(predecessor!==null && (predecessor.after!==change.before || predecessor.focusGeneration!==focusGeneration)) { return false; }
    const commandRoot=predecessor===null && command!==null && (command.sourceCurrent(m) ||
      (actualOrdinaryWill && command.willSourceCandidate(m))) && command.rangeCurrent(m,change.before,change.start,change.end);
    const expectedCommand=commandRoot?command!.id:0;
    const expectedExecution=commandRoot?(m.commandExecution?.sequence ?? 0):0;
    const observedBeforeAdmission=m.sdkChangeSequence;
    const origin=new CjguiProxyInputChange(0,change.before,change.after,change.start,change.end,
      change.afterStart,change.afterEnd,focusGeneration,expectedCommand,expectedExecution,predecessor?.id ?? 0,observedBeforeAdmission);
    const id=Number(this.bridge.inputWill(m,origin));
    if(m.inputDiagnostic!==null){m.inputDiagnostic.nativeTicket=id;m.inputDiagnostic.reason='native_admission';}
    if (!Number.isSafeInteger(id) || id<=0) {
      this.bridge.logWarn('input Will refused: immutable origin or capacity unavailable');return false;
    }
    const admitted=new CjguiProxyInputChange(id,change.before,change.after,change.start,change.end,
      change.afterStart,change.afterEnd,focusGeneration,expectedCommand,expectedExecution,predecessor?.id ?? 0,observedBeforeAdmission);
    const sourceStillCurrent=this.isCurrent(m) && m.focusGeneration===focusGeneration &&
      (predecessor===null ? m.draft===change.before && m.pendingInput===null :
        m.pendingInputs[m.pendingInputs.length-1]===predecessor) &&
      m.publication===publication && (!commandRoot || (m.selectionCommand===command &&
        (command!.sourceCurrent(m) || (actualOrdinaryWill && command!.willSourceCandidate(m)))));
    // Keep the original completion reference even if admission synchronously
    // retires this mount. It grants no new source or successor coordinates.
    if(change.before!==change.after || predecessor!==null) {
      m.pendingInputs.push(admitted);
      // Native pairs a semantic same-value Will at admission. Its position
      // still waits behind the actual Change of the original predecessor.
      if(change.before===change.after) { m.pairedInputIds.push(admitted.id); }
    }
    this.trimCompletedInputs(m);
    if (!sourceStillCurrent) {
      if(m.inputDiagnostic!==null)m.inputDiagnostic.reason='admitted_then_source_retired';
      // The native admission remains its original ticket's responsibility. It
      // cannot confirm or overwrite a newer local command, publication or focus.
      this.bridge.logInfo(`input Will admitted then retired id=${id}`);return true;
    }
    if(publication!==null && publication.reason==='mount' && publication.after.length>0 && commandRoot) {
      m.retiredPublicationEcho=publication; // One bounded observation-only original publication.
    }
    m.publication=null;
    if(commandRoot && m.commandExecution!==null)command!.inputAdmitted(command!,id);
    if(change.before===change.after) {
      m.semanticEchoes.push(admitted);m.trafficSeen=true;
      if(commandRoot) {command!.platformObserved=true;command!.confirmSameValue(command!);}
    }
    return true;
  }

  onWillDelete(m: CjguiTextProxyMount, value: DeleteValue, actualStart: number,
    actualEnd: number, ready: boolean, deleteRange: (start: number, end: number) => void): boolean {
    if (!this.validate(m)) { return false; }
    if(m.originalInsertExecution!==null){this.bridge.originalInsertCancel(m);m.originalInsertExecution=null;return false;}
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
    if (!this.freezeInput(m,new CjguiProxyInputChange(0,op.before,op.expected,op.start,op.end,op.start,op.start))) { return false; }
    m.deleteOperation = op; // Original human command precedes controller publication; echo cannot issue another ticket.
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
  onChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText, options?: TextChangeOptions,
    original?: CjguiProxySDKChange): string {
    const evidence=original ?? new CjguiProxySDKChange(m,++m.sdkChangeSequence,value,previewText,options);
    value=evidence.value;previewText=evidence.preview();options=evidence.options();
    const d=m.inputDiagnostic;
    d?.write(this.bridge,m,'Change-classifier-in',`value=${d.short(value)} old=${d.short(options?.oldContent)} oldEqualsDraft=${options?.oldContent===m.draft} pendingAfterEqualsValue=${m.pendingInput?.after===value} rangeBefore=${JSON.stringify(options?.rangeBefore)} rangeAfter=${JSON.stringify(options?.rangeAfter)} preview=${JSON.stringify(previewText)} oldPreview=${JSON.stringify(options?.oldPreviewText)}`);
    const result=this.classifyChange(m,value,previewText,options,evidence);
    d?.write(this.bridge,m,'Change-classifier-out',`result=${result} value=${d.short(value)}`);
    return result;
  }
  observeSDKChange(m: CjguiTextProxyMount, value: string, previewText?: PreviewText, options?: TextChangeOptions): CjguiProxySDKChange {
    const evidence=new CjguiProxySDKChange(m,++m.sdkChangeSequence,value,previewText,options);
    value=evidence.value;previewText=evidence.preview();options=evidence.options();
    const d=m.inputDiagnostic;
    d?.write(this.bridge,m,'Change-SDK-entry',`value=${d.short(value)} old=${d.short(options?.oldContent)} rangeBefore=${JSON.stringify(options?.rangeBefore)} rangeAfter=${JSON.stringify(options?.rangeAfter)} preview=${JSON.stringify(previewText)} oldPreview=${JSON.stringify(options?.oldPreviewText)}`);
    return evidence;
  }
  private currentInputCompletion(m: CjguiTextProxyMount, evidence: CjguiProxySDKChange): CjguiProxyInputChange | null {
    if(!evidence.key.sameContext(m.key))return null;
    const candidates=m.pendingInputs.filter((c: CjguiProxyInputChange): boolean => c.before!==c.after && c.after===evidence.value);
    if(candidates.length!==1)return null; // Preserve pending ABA, even if mutable options appear unique.
    const input=candidates[0];
    return evidence.observation>input.admittedAfterObservation && evidence.matches(input)?input:null;
  }
  private historicalInputObservation(m: CjguiTextProxyMount, evidence: CjguiProxySDKChange): boolean {
    const historical=m.completedInputs.filter((c: CjguiProxyCompletedInput): boolean => c.focusGeneration===evidence.focus && c.fingerprint.same(evidence.fingerprint));
    if(historical.length===0 || this.currentInputCompletion(m,evidence)!==null)return false;
    // Compact history never vetoes a complete unique current original. Without
    // one it can classify only duplicate/ambiguous observations, not a new edit.
    const duplicate=historical.some((c: CjguiProxyCompletedInput): boolean => c.sameTransition(evidence));
    this.bridge.logInfo(duplicate?'input Change observation: completed transition':'input Change observation: historical postimage unattributed');
    return true;
  }
  private pairInputChange(m: CjguiTextProxyMount, value: string, options: TextChangeOptions | undefined,
    writeCurrent: boolean, evidence: CjguiProxySDKChange): string {
    if(!evidence.key.sameContext(m.key))return 'stale';
    const head=m.pendingInput;
    if(head===null) { return 'stale'; }
    if(m.pendingInputs.filter((c: CjguiProxyInputChange): boolean => c.before!==c.after && c.after===value).length>1) {
      // The SDK supplies no immutable callback sequence for identical ABA
      // payloads. Mutable options cannot distinguish these original Wills.
      this.bridge.logInfo('input Change observation unattributed: pending ABA overlap');return 'observation';
    }
    let input: CjguiProxyInputChange | null=head.after===value?head:null;
    if(input===null && options!==undefined) {
      // Only an exact frozen Will identifies an out-of-order callback. The
      // head can use its frozen source despite later mutable SDK options.
      const matches=m.pendingInputs.filter((c: CjguiProxyInputChange): boolean => c.after===value &&
        options.oldContent===c.before && options.rangeBefore.start===c.start && options.rangeBefore.end===c.end &&
        options.rangeAfter.start===c.afterStart && options.rangeAfter.end===c.afterEnd);
      if(matches.length===1) { input=matches[0]; }
    }
    if(input===null) {
      if(m.lastPairedInput!==null && m.lastPairedInput.after===value) { return writeCurrent?'ok':'settled'; }
      return writeCurrent?this.rejectInput(m):'stale';
    }
    if(this.historicalInputObservation(m,evidence) || evidence.observation<=input.admittedAfterObservation) {
      this.bridge.logInfo('input Change observation: no unique current original completion');return 'observation';
    }
    if(m.pairedInputIds.indexOf(input.id)>=0) { return writeCurrent?'ok':'settled'; }
    const prefix=input!==head && evidence.matches(input);
    const originalPending=m.pendingInputs.slice();
    if(prefix) {
      const boundary=Number(this.bridge.inputChangePrefix(m,input.id,evidence));
      const at=originalPending.findIndex((c: CjguiProxyInputChange): boolean => c.id===boundary);
      if(!Number.isSafeInteger(boundary) || boundary<=0 || at<0 || originalPending[at]!==input) {
        this.bridge.logWarn('input prefix refused: native original-chain proof failed');
        return writeCurrent?this.rejectInput(m):'stale';
      }
      // Only original refs below the native-confirmed boundary, never a new
      // mount's current prefix or any Will beyond the observed anchor.
      for(let i=0;i<=at;i++)if(m.pendingInputs.indexOf(originalPending[i])>=0 &&
        m.pairedInputIds.indexOf(originalPending[i].id)<0)m.pairedInputIds.push(originalPending[i].id);
    } else if(this.bridge.inputChange(m,input.id,value,input.focusGeneration)!=='0') {
      this.bridge.logWarn('input Change refused: exact native Will pairing failed');
      return writeCurrent?this.rejectInput(m):'stale';
    }
    if(!prefix)m.pairedInputIds.push(input.id);
    while(m.pendingInput!==null && m.pairedInputIds.indexOf(m.pendingInput!.id)>=0) {
      const done=m.pendingInputs[0];
      if(writeCurrent && this.isCurrent(m) && m.focusGeneration===done.focusGeneration) {
        if(m.draft!==done.before) { return this.rejectInput(m); }
        m.draft=done.after;m.trafficSeen=true;
      }
      m.pendingInputs.shift();m.pairedInputIds.splice(m.pairedInputIds.indexOf(done.id),1);
      m.lastPairedInput=done; // Platform completion, not one SDK callback per input.
      m.completedInputs.push(new CjguiProxyCompletedInput(done));this.trimCompletedInputs(m);
      const command=m.selectionCommand;
      if(writeCurrent && command!==null && command.id===done.expectedPhysicalCommandId &&
        command.focus===done.focusGeneration && command.rangeCurrent(m,done.before,done.start,done.end)) { command.platformObserved=true; }
    }
    if(!writeCurrent) { return 'settled'; }
    if(!this.isCurrent(m)) { return 'stale'; }
    m.previewKnown=true;m.composing=false;m.lastPreviewOffset=-1;m.lastPreviewText='';
    m.insertPending=false;m.deleteOperation=null;return 'ok';
  }
  private classifyChange(m: CjguiTextProxyMount, value: string, previewText: PreviewText | undefined, options: TextChangeOptions | undefined, evidence: CjguiProxySDKChange): string {
    if (!this.validate(m)) {
      const admitted = m.pendingInput;
      const ordinary = previewText !== undefined && previewText !== null && previewText.offset === -1 && previewText.value === '';
      // Completion only. Native checks this original admitted ID/key/focus;
      // neither a retired component nor its echo obtains new input authority.
      if (admitted !== null && ordinary) { return this.pairInputChange(m,value,options,false,evidence); }
      return 'stale';
    }
    const retired=m.retiredPublicationEcho;
    if(retired!==null && value===retired.after) {
      const ordinaryPreview=previewText!==undefined && previewText.offset===-1 && previewText.value==='';
      const exactInitial=ordinaryPreview && options!==undefined && options.oldContent===retired.before &&
        options.oldPreviewText!==undefined && options.oldPreviewText.offset===retired.beforePreviewOffset &&
        options.oldPreviewText.value===retired.beforePreviewText && options.rangeBefore.start===0 &&
        options.rangeBefore.end===retired.before.length && options.rangeAfter.start===0 && options.rangeAfter.end===retired.after.length;
      const semanticMatches: number[]=[];
      for(let i=0;i<m.semanticEchoes.length;i++) {const c=m.semanticEchoes[i];
        if(ordinaryPreview && options!==undefined && c.focusGeneration===m.focusGeneration && c.after===value &&
          options.oldContent===c.before && options.oldPreviewText!==undefined && options.oldPreviewText.offset===-1 &&
          options.oldPreviewText.value==='' && options.rangeBefore.start===c.start && options.rangeBefore.end===c.end &&
          options.rangeAfter.start===c.afterStart && options.rangeAfter.end===c.afterEnd)semanticMatches.push(i);
      }
      const pending=m.pendingInput;
      const exactPending=ordinaryPreview && pending!==null && options!==undefined && options.oldContent===pending.before &&
        options.oldPreviewText!==undefined && options.oldPreviewText.offset===-1 && options.oldPreviewText.value==='' &&
        options.rangeBefore.start===pending.start && options.rangeBefore.end===pending.end &&
        options.rangeAfter.start===pending.afterStart && options.rangeAfter.end===pending.afterEnd && pending.after===value;
      const matches=(exactInitial?1:0)+semanticMatches.length+(exactPending?1:0);
      if(matches!==1) {this.bridge.logInfo('input Change observation unattributed: original publication overlap');return 'observation';}
      if(exactInitial) {return 'observation';} // No draft write, command completion or consumption of another receipt.
      if(semanticMatches.length===1) {m.semanticEchoes.splice(semanticMatches[0],1);return 'observation';}
    }
    const publicationMetadata = previewText === undefined || previewText === null ||
      (previewText.offset === -1 && previewText.value === '');
    if (publicationMetadata && m.observePublication(value)) {
      m.previewKnown = previewText !== undefined && previewText !== null && previewText.offset === -1 && previewText.value === '';
      m.composing = false; m.lastPreviewOffset = -1; m.lastPreviewText = '';
      this.bridge.logInfo(`publication echo key=${m.key.describe()} sequence=${m.publication!.sequence}`); return 'ok';
    }
    const input = m.pendingInput;
    const ordinary = previewText !== undefined && previewText !== null && previewText.offset === -1 && previewText.value === '';
    // A late same-value Change is an observation of an already queued command,
    // never a second transaction or a surrogate for a different pending Change.
    if (ordinary && (input === null || input.after !== value)) {
      const index = m.semanticEchoes.findIndex((c: CjguiProxyInputChange): boolean => c.after === value);
      if (index >= 0) { m.semanticEchoes.splice(index, 1); return 'ok'; }
    }
    if(ordinary && this.historicalInputObservation(m,evidence)) {
      return 'observation'; // Complete current originals, not historical hashes, own completion.
    }
    if (input !== null) {
      if (!ordinary) {
        this.bridge.logWarn('input Change refused: exact Will pairing failed'); return this.rejectInput(m);
      }
      return this.pairInputChange(m,value,options,true,evidence);
    }
    if(ordinary && m.lastPairedInput!==null && value===m.lastPairedInput.after && value===m.draft) { return 'ok'; }
    const marked = previewText !== undefined && previewText !== null && typeof previewText.value === 'string' && previewText.value.length > 0;
    if (value !== m.draft && !marked && !m.composing) {
      this.bridge.logWarn('input Change refused: frozen Will missing'); return this.rejectInput(m);
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
    m.lastPreviewOffset = previewText?.offset ?? -2;
    m.lastPreviewText = previewText?.value ?? '';
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
      : (marked ? this.bridge.previewRange(m.key.contextId, value, -1, -1)
        : this.bridge.preview(m.key.contextId, value));
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
  private trimCompletedInputs(m: CjguiTextProxyMount): void {
    while(m.completedInputs.length>0 && m.completedInputs.length+m.pendingInputs.length+m.semanticEchoes.length>32) {
      m.completedInputs.shift();
    }
  }
  private rejectInput(m: CjguiTextProxyMount): string {
    m.alive = false;
    if (this.current === m) { this.current = null; }
    this.retiredPredecessor = m;
    return 'rejected';
  }
  // submit/blur：先置 finishing，再提交回**它自己的** context，最后只清理 m。
  // 返回裁决：'ok'=提交与结束均接受；'rejected'=至少一步被 owner 拒绝；
  // 'stale'=身份校验失败（未触碰 owner）。
  submitAndFinish(m: CjguiTextProxyMount, reason: string): string {
    if (m !== null && m !== undefined && m.structuralOperation > 0) {
      const end = this.bridge.focusAuthority(m.key, 4, m.focusGeneration, 0, 0);
      m.alive = false;
      return end === '0' ? 'stale' : 'rejected';
    }
    // R5：对退役前驱的明确终结请求直接使交接记录失效（不得留下可被迟到
    // reconcile 消费的幽灵）；前驱已 alive=false，validate 会判 stale。
    if (this.retiredPredecessor === m) {
      this.retiredPredecessor = null;
    }
    if (!this.validate(m)) {
      return 'stale';
    }
    m.finishing = true;
    const rc: string = this.bridge.finishProxy(m.key, m.focusGeneration, m.draft);
    this.bridge.logInfo(`qualified settlement reason=${reason} ctx=${m.key.contextId} rc=${rc}`);
    const end: string = rc;
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
  retireForReconcile(m: CjguiTextProxyMount, oldContext: number, targetContext: number, targetGeneration: number,
    targetFocusGeneration: number = m.focusGeneration): string {
    const isCurrent: boolean = this.current === m && m.alive && !m.finishing;
    const isPredecessor: boolean = this.retiredPredecessor === m;
    if ((!isCurrent && !isPredecessor) || m.key.contextId !== oldContext) {
      return 'stale';
    }
    const operation = Number(this.bridge.focusAuthority(m.key, 3, targetFocusGeneration, targetContext, targetGeneration));
    if (!Number.isSafeInteger(operation) || operation <= 0) { return 'stale'; }
    m.structuralOperation = operation; // Registration completes BEFORE page/controller unmount.
    m.structuralFocusGeneration = targetFocusGeneration;
    this.structuralPredecessor = m;
    if (this.current === m) { this.current = null; }
    if (this.retiredPredecessor === m) { this.retiredPredecessor = null; }
    m.alive = false;
    this.bridge.logInfo(`proxy retired for external reconcile ctx=${oldContext}`);
    return 'retired';
  }

  // A delayed disappear may mount only the target of the original registered
  // structure. An explicit newer reconcile can register a distinct operation.
  reconcileTargetCurrent(m: CjguiTextProxyMount, context: number, generation: number): boolean {
    if (m.structuralOperation <= 0) { return false; }
    const operation = Number(this.bridge.focusAuthority(m.key, 5, m.structuralFocusGeneration, context, generation));
    return Number.isSafeInteger(operation) && operation === m.structuralOperation;
  }

  advanceReconcileTarget(m: CjguiTextProxyMount, context: number, generation: number,
    focusGeneration: number = m.structuralFocusGeneration): boolean {
    if (m.structuralOperation <= 0) { return false; }
    const operation = Number(this.bridge.focusAuthority(m.key, 3, focusGeneration, context, generation));
    if (!Number.isSafeInteger(operation) || operation <= m.structuralOperation) { return false; }
    m.structuralOperation = operation;
    m.structuralFocusGeneration = focusGeneration;
    return true;
  }

  // The component has really disappeared. Only an explicitly registered target
  // may continue on the UI turn; a queued B task cannot be rebound to later C.
  scheduleReconcileTarget(m: CjguiTextProxyMount, context: number, generation: number,
    execute: () => void): boolean {
    if (!this.reconcileTargetCurrent(m, context, generation)) { return false; }
    const operation: number = m.structuralOperation;
    if (m.reconcileScheduledOperation === operation) { return true; }
    m.reconcileScheduledOperation = operation;
    setTimeout(() => {
      if (m.reconcileScheduledOperation !== operation || m.structuralOperation !== operation ||
        !this.reconcileTargetCurrent(m, context, generation)) { return; }
      execute();
    }, 0);
    return true;
  }

  // 迟到 focus 定时器：先校验存活 + 仍是 current，**再**交还页面执行
  // requestFocus——绝不能先收尾当前代理再验证（旧 A→B 顺序缺陷）。
  // 返回 true = 校验通过，页面应立即请求焦点。
  delayedFocus(m: CjguiTextProxyMount): boolean {
    if (m === null || m === undefined || !m.alive || m.finishing || !m.componentAppeared) {
      return false;
    }
    if (this.current !== m) {
      this.bridge.logWarn(`delayed focus rejected (stale mount) ctl=${m.controlId}`);
      return false;
    }
    return this.isCurrent(m);
  }

  // 框架侧 end 通知：只有当前挂载响应；其余一律记录并忽略。
  onFrameworkEnd(contextId: number): boolean {
    if (this.structuralTransfer?.target.context===contextId) {
      this.structuralTransfer=null; this.structuralPredecessor=null;
      return true;
    }
    if (this.pendingFocus !== null && this.pendingFocus.context === contextId) {
      this.pendingFocus = null;
      this.bridge.logInfo(`pending focus cancelled by original target end ctx=${contextId}`);
      return true;
    }
    const cur = this.current;
    if (cur !== null && cur.key.contextId === contextId) {
      cur.alive = false;
      this.endedComponent=cur;
      this.current = null;
      if (this.retiredPredecessor === cur) {
        this.retiredPredecessor = null;
      }
      this.bridge.logInfo(`proxy released by framework ctx=${contextId}`);
      return true;
    }
    if (this.current===null && this.endedComponent?.key.contextId===contextId) { return true; }
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
  pendingOrdinarySelection(mount: CjguiTextProxyMount): string;
  prepareOrdinarySelection(mount: CjguiTextProxyMount, source: CjguiOrdinarySelectionSource, install: number, start: number, end: number): string;
  observeOrdinarySelection(execution: CjguiOrdinarySelectionExecution, phase: number, start: number, end: number, attach: number): string;
  // 系统输入会话发起（inputMethod.getController().showTextInput()）。
  // Historical name: request showTextInput for ArkUI's client, never JS Attach.
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
  prepareSelectionCommand(mount: CjguiTextProxyMount, command: number, publication: number,
    attach: number, install: number): string;
  observeSelectionCommand(execution: CjguiPhysicalCommandExecution, round: number, start: number, end: number): string;
  // 挂载身份校验（proxyRegistry.isCurrent）。
  isCurrentMount(mount: CjguiTextProxyMount): boolean;
  // 恢复事务占用查询（非空时安装让位，具名 UNCONFIRMED）。
  restoreTaskActive(): boolean;
  currentMount(): CjguiTextProxyMount | null;
  restoreTargetEligible(ticket: CjguiImeRestoreTicket): boolean;
  // CLOCK_MONOTONIC domain: SDK systemDateTime.getUptime(ACTIVE, false).
  monotonicNowMs(): number;
  writeRestoreText(mount: CjguiTextProxyMount, text: string): void;
  afterComponentFrame(mount: CjguiTextProxyMount, callback: () => void): CjguiImeFrameCallback;
  beforeComponentFrame(mount: CjguiTextProxyMount, callback: (frameTime: number) => void): CjguiImeSelectionFrameCallback;
  commitRestore(ticket: CjguiImeRestoreTicket, start: number, end: number,
    ok: boolean, reason: string): string;
  logInfo(msg: string): void;
  logWarn(msg: string): void;
}

export class CjguiImeSelectionLifecycle {
  private host: CjguiImeSelectionHost;
  private capturedCommand: CjguiPhysicalSelectionCommand | null = null;
  private commandOriginMount: CjguiTextProxyMount | null = null;
  private commandFrame: CjguiImeFrameCallback | null = null;
  private commandTimer: number = -1;
  private commandDeadline: number = 0;
  private activeWrite: CjguiProgramSelectionWrite | null = null;
  private retiredWrite: CjguiProgramSelectionWrite | null = null;
  private selMount: CjguiTextProxyMount | null = null;
  private selStart: number = 0;
  private selEnd: number = 0;
  private selSeq: number = 0;
  private selFocusGeneration: number = 0;
  private selText: string = '';
  private selTerminal: string = 'none';
  // System preparation belongs to a mount/focus cycle, independent of pending
  // selection. A show result/valid original traffic retains the existing gate;
  // it is not a claim that this bridge executed ArkUI's real client Attach.
  private attachedMount: CjguiTextProxyMount | null = null;
  private attachedFocusGeneration: number = 0;
  private attachSeq: number = 0;
  private attachAttemptMount: CjguiTextProxyMount | null = null;
  private attachAttemptFocusGeneration: number = 0;
  private attachRetryTimer: number = -1;
  // Preserve the bounded show-retry policy for 12800009; the code does not
  // identify whether real Attach failed or a previously bound client detached.
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
  private restoreTicket: CjguiImeRestoreTicket | null = null;
  private restoreMount: CjguiTextProxyMount | null = null;
  private restoreBodyObserved: boolean = false;
  private restoreBodySettled: boolean = false;
  private restoreBodyEpoch: number = 0;
  private restoreWriteSent: boolean = false;
  private restoreSetterSent: boolean = false;
  private restoreExistingWrite: boolean = false;
  private restoreDeadlineTimer: number = -1;
  private restoreSerial: number = 1;
  private restoreSeq: number = -2;
  private restoreOlderSelectionSeq: number = -1;
  private restoreLastTerminal: CjguiImeRestoreTicket | null = null;
  private restoreBodyFrame: CjguiImeFrameCallback | null = null;
  private restoreInputFrame: CjguiImeFrameCallback | null = null;

  hasRestore(): boolean { return this.restoreTicket !== null; }

  restore(ticket: CjguiImeRestoreTicket): void {
    if(this.capturedCommand!==null && ticket.request===0 && ticket.focusGeneration===this.capturedCommand.focus) {
      this.host.logInfo('anonymous mount installation deferred to original captured command');return;
    }
    const last = this.restoreLastTerminal;
    if (ticket.request > 0 && last !== null && last.request === ticket.request && last.context === ticket.context &&
      last.sessionToken === ticket.sessionToken && last.appInstance === ticket.appInstance) { return; }
    const old = this.restoreTicket;
    if (ticket.request > 0 && old !== null && old.request === ticket.request && old.context === ticket.context &&
      old.sessionToken === ticket.sessionToken && old.appInstance === ticket.appInstance) {
      // Same request cannot replace its frozen text/identity/deadline.
      return;
    }
    if (old !== null) { this.finishRestore(false, -1, -1, 'superseded_request'); }
    this.restoreTicket = ticket;
    this.restoreMount = null;
    this.restoreBodyObserved = false;
    this.restoreBodySettled = false;
    this.restoreWriteSent = false;
    this.restoreSetterSent = false;
    this.restoreExistingWrite = false;
    this.restoreBodyEpoch += 1;
    this.restoreSeq = -(++this.restoreSerial);
    this.restoreOlderSelectionSeq = this.selMount === null ? -1 : this.selSeq;
    const valid = ticket.valid();
    if (!valid) { this.host.logWarn(`ime restore validity mismatch request=${ticket.request} context=${ticket.context} focus=${ticket.focusGeneration} deadline=${ticket.deadlineMonoMs} ${ticket.validityMismatch()}`); }
    if (!valid || !this.host.restoreTargetEligible(ticket)) {
      this.finishRestore(false, -1, -1, 'invalid_restore_target');
      return;
    }
    const remaining = ticket.deadlineMonoMs - this.host.monotonicNowMs();
    if (remaining <= 0) { this.finishRestore(false, -1, -1, 'original_deadline'); return; }
    this.restoreDeadlineTimer = setTimeout(() => {
      if (this.restoreTicket === ticket) { this.finishRestore(false, -1, -1, 'original_deadline'); }
    }, remaining);
    this.restoreMountAvailable(this.host.currentMount());
  }

  restoreMountAvailable(mount: CjguiTextProxyMount | null): void {
    const ticket = this.restoreTicket;
    if (ticket === null) { return; }
    if (!this.host.restoreTargetEligible(ticket) || this.host.monotonicNowMs() >= ticket.deadlineMonoMs) {
      this.finishRestore(false, -1, -1, 'restore_target_retired'); return;
    }
    if (this.restoreMount !== null) {
      if (mount !== this.restoreMount || !this.host.isCurrentMount(this.restoreMount)) {
        this.finishRestore(false, -1, -1, 'restore_bound_mount_retired');
      } else {
        this.prepareRestoreBody(this.restoreMount, ticket);
      }
      return;
    }
    // A valid native target can wait across old component disappearance. It does not
    // acquire the old component or follow another generation with the same context.
    if (mount === null || !this.host.isCurrentMount(mount) || mount.key.contextId !== ticket.context) { return; }
    if (mount.key.editGeneration !== ticket.generation || mount.focusGeneration !== ticket.focusGeneration || mount.key.appInstance !== ticket.appInstance ||
      mount.key.sessionToken !== ticket.sessionToken || mount.fieldId !== ticket.field) {
      this.finishRestore(false, -1, -1, 'restore_mount_identity_mismatch'); return;
    }
    this.restoreMount = mount;
    this.restoreBodyObserved = mount.draft === ticket.text;
    // A same-mount, same-body ordinary write already in flight is the same
    // platform command. Transfer confirmation ownership, never send it again.
    this.restoreExistingWrite = this.restoreBodyObserved && this.selMount === mount &&
      this.selSeq === this.restoreOlderSelectionSeq && this.installSentSeq === this.selSeq &&
      this.selStart === ticket.start && this.selEnd === ticket.end &&
      this.selFocusGeneration===mount.focusGeneration && this.selText===ticket.text;
    this.prepareRestoreBody(mount, ticket);
  }

  private waitForRestoreInput(mount: CjguiTextProxyMount, ticket: CjguiImeRestoreTicket,
    resume: () => void): boolean {
    if (mount.pendingInput === null) { return false; }
    // Will is waiting evidence, not a completed after-image. Keep this exact
    // target and original deadline; neither write nor confirm during that gap.
    if (this.restoreInputFrame === null) {
      this.restoreInputFrame = this.host.afterComponentFrame(mount, () => {
        this.restoreInputFrame = null;
        if (this.restoreTicket !== ticket || this.restoreMount !== mount) { return; }
        if (!this.host.isCurrentMount(mount) || !this.host.restoreTargetEligible(ticket) ||
          this.host.monotonicNowMs() >= ticket.deadlineMonoMs) {
          this.finishRestore(false, -1, -1, 'restore_execution_retired'); return;
        }
        resume();
      });
    }
    return true;
  }

  private prepareRestoreBody(mount: CjguiTextProxyMount, ticket: CjguiImeRestoreTicket): void {
    if (this.waitForRestoreInput(mount, ticket, () => { this.prepareRestoreBody(mount, ticket); })) { return; }
    if (!this.restoreBodyObserved && !this.restoreWriteSent) {
      this.restoreWriteSent = true;
      mount.registerPublication(ticket.text, 'restore');
      mount.programWriteDepth++;
      try { this.host.writeRestoreText(mount, ticket.text); } finally { mount.programWriteDepth--; }
    } else if (this.restoreBodyObserved && !this.restoreBodySettled && this.restoreBodyFrame === null) {
      this.waitRestoreBodyFrame(mount, ticket);
    }
    this.driveRestore('target-mounted');
  }

  observeRestoreText(mount: CjguiTextProxyMount, text: string): boolean {
    const ticket = this.restoreTicket;
    if (ticket === null || mount !== this.restoreMount || !this.host.isCurrentMount(mount)) { return false; }
    if (text !== ticket.text || mount.pendingInput !== null) {
      this.finishRestore(false, -1, -1, 'human_input_supersedes'); return false;
    }
    if (!this.restoreWriteSent) { return false; }
    if (this.restoreSetterSent) {
      this.finishRestore(false, -1, -1, 'text_changed_after_selection'); return true;
    }
    if (!mount.observePublication(text)) { return false; }
    this.restoreBodyObserved = true;
    mount.draft = text;
    this.waitRestoreBodyFrame(mount, ticket);
    return true;
  }

  private waitRestoreBodyFrame(mount: CjguiTextProxyMount, ticket: CjguiImeRestoreTicket): void {
    const epoch = ++this.restoreBodyEpoch;
    this.restoreBodySettled = false;
    if (this.restoreBodyFrame !== null) { this.restoreBodyFrame.cancel(); }
    this.restoreBodyFrame = this.host.afterComponentFrame(mount, () => {
      this.restoreBodyFrame = null;
      if (this.restoreTicket !== ticket || this.restoreMount !== mount || epoch !== this.restoreBodyEpoch ||
        !this.host.isCurrentMount(mount)) { return; }
      this.restoreBodySettled = true;
      this.driveRestore('body-rendered');
    });
  }

  observeRestoreSelection(mount: CjguiTextProxyMount, start: number, end: number): boolean {
    const ticket = this.restoreTicket;
    if (ticket === null || this.restoreMount !== mount) { return false; }
    if (this.restoreSetterSent && (start !== ticket.start || end !== ticket.end)) {
      this.finishRestore(false, start, end, 'late_selection_reset');
    }
    // An event can invalidate confirmation; it cannot provide both cross-frame reads.
    return true;
  }

  private driveRestore(reason: string): void {
    const ticket = this.restoreTicket;
    const mount = this.restoreMount;
    if (ticket === null || mount === null) { return; }
    if (!this.host.restoreTargetEligible(ticket) || !this.host.isCurrentMount(mount) ||
      this.host.monotonicNowMs() >= ticket.deadlineMonoMs) {
      this.finishRestore(false, -1, -1, 'restore_execution_retired'); return;
    }
    if (this.waitForRestoreInput(mount, ticket, () => { this.driveRestore(reason); })) { return; }
    if (!this.restoreBodyObserved || !this.restoreBodySettled || !this.isAttachedTo(mount)) { return; }
    this.install(mount, ticket.start, ticket.end, 0, this.restoreSeq, `restore-${ticket.request}-${reason}`);
  }

  private isRestoreExecution(mount: CjguiTextProxyMount, seq: number): boolean {
    return this.restoreTicket !== null && this.restoreMount === mount && seq === this.restoreSeq;
  }

  private executionCurrent(mount: CjguiTextProxyMount, seq: number): boolean {
    if (!this.host.isCurrentMount(mount)) { return false; }
    if (this.isRestoreExecution(mount, seq)) {
      const ticket = this.restoreTicket!;
      return this.host.restoreTargetEligible(ticket) && this.host.monotonicNowMs() < ticket.deadlineMonoMs;
    }
    const e=mount.commandExecution;
    if(e!==null && e.command===this.capturedCommand && e.install===seq) {
      return !e.consumedInput && this.selMount===mount && this.selSeq===seq && e.bodySettled && e.text===mount.draft &&
        mount.publication===e.publication && this.isAttachedTo(mount) && this.attachSeq===e.attach &&
        this.host.monotonicNowMs()<e.deadline;
    }
    return seq === this.selSeq && this.selMount === mount &&
      this.selFocusGeneration===mount.focusGeneration && this.selText===mount.draft;
  }

  private settleExecution(mount: CjguiTextProxyMount, seq: number, terminal: string, reason: string,
    start: number = -1, end: number = -1): void {
    if (this.isRestoreExecution(mount, seq)) {
      this.finishRestore(terminal === 'INSTALLED', start, end, reason);
    } else if (this.selMount === mount && this.selSeq === seq) { this.settle(mount, terminal, reason); }
  }

  private finishRestore(ok: boolean, start: number, end: number, reason: string): void {
    const ticket = this.restoreTicket;
    const mount = this.restoreMount;
    if (ticket === null) { return; }
    // Retire callbacks before calling native, including synchronous component callbacks.
    this.restoreTicket = null;
    this.restoreLastTerminal = ticket;
    this.restoreMount = null;
    this.restoreBodyEpoch += 1;
    if (this.restoreBodyFrame !== null) { this.restoreBodyFrame.cancel(); this.restoreBodyFrame = null; }
    if (this.restoreInputFrame !== null) { this.restoreInputFrame.cancel(); this.restoreInputFrame = null; }
    if (this.restoreDeadlineTimer !== -1) { clearTimeout(this.restoreDeadlineTimer); this.restoreDeadlineTimer = -1; }
    const rc = this.host.commitRestore(ticket, start, end, ok, reason);
    if(ok && rc==='0' && mount!==null && ticket.originalResult>0) {
      mount.originalInstalledResult=ticket;
      mount.selectionText=mount.draft;mount.selectionStart=start;mount.selectionEnd=end;
    }
    this.host.logInfo(`ime restore terminal request=${ticket.request} ctx=${ticket.context} ok=${ok} rc=${rc} reason=${reason}`);
    if (this.selMount !== null && mount === this.selMount &&
      (this.selSeq <= this.restoreOlderSelectionSeq || (ok && rc === '0' && this.selStart === start && this.selEnd === end))) {
      this.settle(this.selMount, ok && rc === '0' ? 'INSTALLED' : 'UNCONFIRMED', 'restore_owner_settled');
    } else if (this.selMount !== null && reason !== 'human_input_supersedes' &&
      reason !== 'mount_changed_retired' && reason !== 'restore_bound_mount_retired') {
      this.maybeInstall(this.selMount, 'restore-owner-released');
    }
    if(mount!==null && ok && rc==='0')this.joinPendingOrdinary(mount, 'restore-wake');
  }

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
    return this.attachedMount === mount && this.attachedFocusGeneration === mount.focusGeneration;
  }

  // 挂载变更：会话事实随旧挂载失效（新挂载必须重新走 attach）。
  invalidateAttachmentFor(mount: CjguiTextProxyMount): void {
    if (this.attachAttemptMount === mount) {
      this.attachSeq += 1;this.attachAttemptMount = null;
      this.attachRetryLeft = 0;
      if (this.attachRetryTimer !== -1) { clearTimeout(this.attachRetryTimer);this.attachRetryTimer = -1; }
    }
    if(mount.commandExecution?.command===this.capturedCommand) {
      // Retire this target execution, retaining the independently admitted Q.
      // Native decides whether the following target has the same owner cause.
      mount.commandExecution.selectionFrame?.cancel();mount.commandExecution.selectionFrame=null;
      mount.commandExecution=null;mount.selectionCommand=null;
    }
    if (this.restoreMount === mount) { this.finishRestore(false, -1, -1, 'mount_changed_retired'); }
    if (this.attachedMount === mount) {
      this.attachedMount = null;
      this.attachedFocusGeneration = 0;
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
  private scheduleDeadline(mount: CjguiTextProxyMount, seq: number, deadline: number = this.host.monotonicNowMs()+8000): void {
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
    }, Math.max(1,deadline-this.host.monotonicNowMs()));
  }

  armPhysicalCommand(mount: CjguiTextProxyMount): void {
    if (this.selMount===mount) { this.settle(mount,'UNCONFIRMED','physical_command_supersedes'); }
    this.arm(mount,0,mount.draft.length,'physical-select-all');
  }
  commandMount(command: CjguiPhysicalSelectionCommand): CjguiTextProxyMount | null {
    const mount=this.host.currentMount();
    return mount!==null && mount.commandExecution?.command===command ? mount : null;
  }
  capturePhysicalCommand(origin: CjguiTextProxyMount, command: CjguiPhysicalSelectionCommand): void {
    this.retireCapturedCommand('superseded_command');
    this.capturedCommand=command;this.commandOriginMount=origin;
    const status=this.host.prepareSelectionCommand(origin,command.id,0,0,0).split(',');
    const deadline=status.length===4 ? Number(status[3]) : 0;
    if(!Number.isSafeInteger(deadline) || deadline<=this.host.monotonicNowMs()) {
      this.retireCapturedCommand('native_origin_unavailable');return;
    }
    this.commandDeadline=deadline;this.driveCapturedCommand();
  }
  originalReceiverExited(command: CjguiPhysicalSelectionCommand): void {
    if(this.capturedCommand===command)this.retireCapturedCommand('actual_original_result_adopted');
  }
  private retireCapturedCommand(reason: string): void {
    const command=this.capturedCommand;const mount=this.commandMountIfPresent();
    const origin=this.commandOriginMount;
    if(this.commandFrame!==null){this.commandFrame.cancel();this.commandFrame=null;}
    if(this.commandTimer!==-1){clearTimeout(this.commandTimer);this.commandTimer=-1;}
    this.capturedCommand=null;this.commandOriginMount=null;this.commandDeadline=0;
    if(origin!==null && origin.selectionCommand===command)origin.selectionCommand=null;
    if(mount!==null) {
      mount.commandExecution?.selectionFrame?.cancel();
      if(mount.selectionCommand===command)mount.selectionCommand=null;
      if(mount.commandExecution?.command===command)mount.commandExecution=null;
    }
    if(command!==null)this.host.logInfo(`physical command executor retired id=${command.id} reason=${reason}`);
  }
  private commandMountIfPresent(): CjguiTextProxyMount | null {
    const command=this.capturedCommand;return command===null ? null : this.commandMount(command);
  }
  private driveCapturedCommand(): void {
    const command=this.capturedCommand,origin=this.commandOriginMount;
    if(command===null || origin===null)return;
    const status=this.host.prepareSelectionCommand(origin,command.id,0,0,0);
    const mount=this.host.currentMount();
    if(status.length===0){this.retireCapturedCommand('native_cancel');return;}
    if(mount?.commandExecution?.command===command && mount.commandExecution.installed)return;
    if(this.host.monotonicNowMs()>=this.commandDeadline){this.retireCapturedCommand('original_deadline');return;}
    if(mount!==null && mount.componentAppeared && this.host.isCurrentMount(mount) &&
      mount.focusGeneration===command.focus && this.isAttachedTo(mount) && mount.publication!==null &&
      mount.publication.consumed && mount.publication.after===mount.draft && mount.pendingInput===null) {
      const publication=mount.publication;
      const existing=mount.commandExecution;
      if(existing!==null && existing.command===command && existing.installed)return;
      const install=this.selSeq+1;
      const needsExecution=existing===null || existing.command!==command || existing.publication!==publication || existing.attach!==this.attachSeq;
      const reply=needsExecution ? this.host.prepareSelectionCommand(mount,command.id,publication.sequence,this.attachSeq,install).split(',') : [];
      if(needsExecution && reply.length===4 && Number(reply[0])>0) {
        const execution=new CjguiPhysicalCommandExecution(command,mount,Number(reply[0]),publication,this.attachSeq,install,
          Number(reply[3]),Number(reply[1]),Number(reply[2]));
        mount.commandExecution=execution;mount.selectionCommand=command;
        mount.inputDiagnostic=new CjguiProxyInputDiagnostic(command.id,mount.key,command.focus);
        if(this.commandFrame!==null)this.commandFrame.cancel();
        this.commandFrame=this.host.afterComponentFrame(mount,()=>{
          this.commandFrame=null;
          if(this.capturedCommand!==command || !this.host.isCurrentMount(mount) || mount.commandExecution!==execution ||
            mount.publication!==publication || mount.draft!==execution.text || !this.isAttachedTo(mount) ||
            this.attachSeq!==execution.attach || this.host.monotonicNowMs()>=execution.deadline)return;
          execution.bodySettled=true;
          this.host.logInfo(`physical command body rendered id=${command.id} execution=${execution.sequence} publication=${publication.sequence}`);
          this.arm(mount,execution.start,execution.end,'captured-physical-select-all');
        });
      }
    }
    // Wait only within the original native budget, without re-sending a key or
    // setter. New component/attach/publication facts are consumed here as well.
    if(this.commandTimer!==-1)clearTimeout(this.commandTimer);
    this.commandTimer=setTimeout(()=>{this.commandTimer=-1;this.driveCapturedCommand();},
      Math.min(16,Math.max(1,this.commandDeadline-this.host.monotonicNowMs())));
  }
  supersededByPhysicalNavigation(mount: CjguiTextProxyMount): void {
    if (this.selMount===mount) { this.settle(mount,'UNCONFIRMED','physical_navigation_supersedes'); }
  }
  commandCurrent(mount: CjguiTextProxyMount, command: CjguiPhysicalSelectionCommand): boolean {
    const e=mount.commandExecution;
    if(e!==null && e.command===command) {
      return this.capturedCommand===command && this.host.isCurrentMount(mount) && mount.selectionCommand===command &&
        e.mount===mount && command.focus===mount.focusGeneration && e.install===this.selSeq &&
        ((this.selMount===mount && this.selTerminal==='pending') || (e.installed && this.selTerminal==='INSTALLED') ||
          (e.consumedInput>0 && this.selTerminal==='CONSUMED_BY_INPUT'));
    }
    return this.host.isCurrentMount(mount) && mount.selectionCommand===command && command.key===mount.key &&
      command.focus===mount.focusGeneration && command.installSequence>0 && command.installSequence===this.selSeq &&
      ((this.selMount===mount && this.selTerminal==='pending') || this.selTerminal==='INSTALLED');
  }
  completeCommandInput(mount: CjguiTextProxyMount, command: CjguiPhysicalSelectionCommand | null,
    reason: string = 'physical_command_range_observed_at_change'): void {
    if(command===null || !command.platformObserved || !this.commandCurrent(mount,command))return;
    if(this.selMount===mount)this.settle(mount,'INSTALLED',reason);
    if(mount.selectionCommand===command) {mount.selectionCommand=null;this.noteTraffic(mount);}
    if(this.capturedCommand===command)this.retireCapturedCommand('first_input_consumed');
  }
  consumeCommandSourceAtWill(mount: CjguiTextProxyMount, command: CjguiPhysicalSelectionCommand, id: number): void {
    const e=mount.commandExecution;
    if(e===null || e.command!==command || !this.commandCurrent(mount,command) || e.consumedInput)return;
    e.consumedInput=id;
    e.selectionFrame?.cancel();e.selectionFrame=null;
    // Input consumption is not two-getter installation. Retire only the
    // installation work; retain this input's original fact until real Change.
    this.selTerminal='CONSUMED_BY_INPUT';this.selMount=null;
    if(this.deadlineTimer!==-1){clearTimeout(this.deadlineTimer);this.deadlineTimer=-1;}
    if(this.commandTimer!==-1){clearTimeout(this.commandTimer);this.commandTimer=-1;}
    if(this.commandFrame!==null){this.commandFrame.cancel();this.commandFrame=null;}
    if(this.echoMount===mount){this.echoMount=null;this.echoOpen=false;}
    this.host.logInfo(`physical command source consumed at Will id=${command.id} execution=${e.sequence} input=${id}`);
  }

  // Lifecycle wake and actual Will share the SAME native pending source/arm.
  // Native revalidates body/key/focus/owner/target/deadline, then prepare locks
  // the same id again. This cannot grant an unconfirmed or latest selection.
  joinPendingOrdinary(mount: CjguiTextProxyMount, reason: string): boolean {
    if(!this.host.isCurrentMount(mount) || this.hasRestore() || this.host.restoreTaskActive() ||
       this.capturedCommand!==null || mount.commandExecution!==null)return false;
    const values=(this.host.pendingOrdinarySelection?.(mount) ?? '').split(',');
    if(values.length!==4)return false;
    const id=Number(values[0]),start=Number(values[1]),end=Number(values[2]),deadline=Number(values[3]);
    if(!Number.isSafeInteger(id) || id<=0 || !Number.isSafeInteger(start) || start<0 ||
       !Number.isSafeInteger(end) || end<start || !Number.isSafeInteger(deadline) ||
       deadline<=this.host.monotonicNowMs())return false;
    this.arm(mount,start,end,reason,{kind:1,id:id,deadline:deadline});
    return mount.ordinaryExecution!==null && mount.ordinaryExecution.sourceId===id;
  }

  // 新目标入账（不立即安装：统一入口会等本次接续 attach 完成后投首笔；
  // 键盘/组合态同步在此之前会覆盖选区请求）。
  arm(mount: CjguiTextProxyMount, start: number, end: number, reason: string, source?: CjguiOrdinarySelectionSource): void {
    if(this.capturedCommand!==null && reason!=='captured-physical-select-all') {
      this.driveCapturedCommand();return;
    }
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || end < start) {
      this.host.logInfo(`ime proxy selection not installable reason=${reason} start=${start} end=${end}`);
      return;
    }
    if(!this.host.isCurrentMount(mount))return;
    const current=mount.ordinaryExecution;
    if(source===undefined && reason==='caret' && current!==null) {
      this.maybeInstall(mount,reason);return; // An untyped old coordinate is not a newer command.
    }
    let ordinarySequence=0;
    if(source!==undefined) {
      if(source.kind!==1 || !Number.isSafeInteger(source.id) || source.id<=0 ||
         !Number.isSafeInteger(source.deadline) || source.deadline<=this.host.monotonicNowMs()) {
        this.host.logInfo(`ordinary source not joined id=${source.id} reason=source_invalid`);return;
      }
      if(current!==null && current.sourceId===source.id) {
        if(current.deadline!==source.deadline || current.start!==start || current.end!==end ||
           current.focus!==mount.focusGeneration || current.text!==mount.draft) {
          this.host.logInfo(`ordinary source not joined id=${source.id} reason=duplicate_source_mismatch`);return;
        }
        this.maybeInstall(mount,reason);return; // Exact duplicate joins its original sequence/deadline.
      }
      const values=this.host.prepareOrdinarySelection(mount,source,this.selSeq+1,start,end).split(',');
      if(values.length!==4 || !Number.isSafeInteger(Number(values[0])) || Number(values[0])<=0 ||
         Number(values[1])!==start || Number(values[2])!==end || Number(values[3])!==source.deadline) {
        this.host.logInfo(`ordinary source not joined id=${source.id} reason=source_not_prepared`);return;
      }
      ordinarySequence=Number(values[0]);
    }
    const previous=mount.ordinaryExecution;
    if(previous!==null) {
      this.host.observeOrdinarySelection(previous,2,previous.start,previous.end,this.attachSeq);
      if(mount.originalInsertExecution===previous)mount.originalInsertExecution=null;
      mount.ordinaryExecution=null;
    }
    this.selMount = mount;
    this.selFocusGeneration=mount.focusGeneration;this.selText=mount.draft;
    this.selStart = start;
    this.selEnd = end;
    this.selSeq += 1;
    if(reason==='physical-select-all' && mount.selectionCommand!==null)mount.selectionCommand.installSequence=this.selSeq;
    this.selTerminal = 'pending';
    // 新意图取回执行权：旧让位状态随新 seq 终结（旧在飞计时器凭 seq 门自失效）。
    this.yieldedToRestore = false;
    // 新请求替代旧回声括号：旧请求的观测流到此为止。
    this.echoMount = null;
    this.echoOpen = false;
    if(reason==='captured-physical-select-all' && mount.commandExecution!==null) {
      const e=mount.commandExecution;
      if(e.install!==this.selSeq || !e.bodySettled){this.settle(mount,'UNCONFIRMED','command_execution_sequence');return;}
      if(mount.selectionCommand!==null)mount.selectionCommand.installSequence=this.selSeq;
      if(this.deadlineTimer!==-1)clearTimeout(this.deadlineTimer);
      this.deadlineTimer=setTimeout(()=>this.settle(mount,'UNCONFIRMED','command_original_deadline'),
        Math.max(1,e.deadline-this.host.monotonicNowMs()));
    } else {
      if(source!==undefined) {
        mount.ordinaryExecution=new CjguiOrdinarySelectionExecution(mount,source,ordinarySequence,this.selSeq,start,end);
      }
      this.scheduleDeadline(mount,this.selSeq,source?.deadline);
    }
    this.maybeInstall(mount, reason);
  }

  // Historical name: the host requests showTextInput, not an ArkUI client
  // Attach. One valid mount/focus preparation owns all its calls and retries;
  // selection/restore IDs and absolute deadlines remain independent.
  requestAttach(mount: CjguiTextProxyMount, reason: string): void {
    // R4（2026-10-02 Astra 裁决）：attach 是**会话级事实**，其发起只依赖挂载身份
    // （仍是当前挂载），不与 pending 选区耦合。此前 `selMount !== mount` 的门使
    // 恢复让位（settle 清 selMount）之后的焦点 attach 永久静默早退——H 线实测
    // 笔记面「让位清 pending → 焦点 attach 被门挡 → 后续 caret 只等待 → 8s
    // request_deadline」。pending 只决定「有无选区要装」，见 maybeInstall。
    if (!this.host.isCurrentMount(mount)) {
      return;
    }
    this.joinPendingOrdinary(mount, 'mount-wake');
    if (this.isAttachedTo(mount)) {
      this.maybeInstall(mount, reason);
      return;
    }
    const focusGeneration=mount.focusGeneration;
    if (this.attachAttemptMount===mount && this.attachAttemptFocusGeneration===focusGeneration) {
      this.host.logInfo(`ime showTextInput preparation joined field=${mount.fieldId} seq=${this.attachSeq} reason=${reason} retriesLeft=${this.attachRetryLeft}`);
      return; // Also retain the original exhausted budget until real invalidation.
    }
    if (this.attachRetryTimer!==-1) { clearTimeout(this.attachRetryTimer);this.attachRetryTimer=-1; }
    this.attachAttemptMount=mount;this.attachAttemptFocusGeneration=focusGeneration;
    this.attachedMount=null;this.attachedFocusGeneration=0;
    const attachSeq: number = ++this.attachSeq;
    this.attachRetryLeft = 4;
    this.requestShowForAttach(mount,attachSeq,focusGeneration,reason);
  }
  private attachAttemptCurrent(mount: CjguiTextProxyMount, seq: number, focus: number): boolean {
    return this.host.isCurrentMount(mount) && mount.focusGeneration===focus &&
      this.attachAttemptMount===mount && this.attachAttemptFocusGeneration===focus && this.attachSeq===seq;
  }
  private requestShowForAttach(mount: CjguiTextProxyMount, attachSeq: number, focusGeneration: number, reason: string): void {
    if(!this.attachAttemptCurrent(mount,attachSeq,focusGeneration))return;
    this.host.attachSession().then(() => {
      // R4：成功记账只要求「仍是当前挂载 + 本次尝试身份」——pending 选区可能已被
      // 恢复让位/真人输入清空，会话事实仍成立。若仍以 `selMount === mount` 门控，
      // 成功会被误判 stale、attachedMount 永不置位（Astra 反例 (b)）。
      if (!this.attachAttemptCurrent(mount,attachSeq,focusGeneration)) {
        this.host.logInfo(`ime attach completed but stale seq=${attachSeq} live=${this.attachSeq}`);
        return;
      }
      this.attachedMount = mount;
      this.attachedFocusGeneration = focusGeneration;
      if(this.attachRetryTimer!==-1){clearTimeout(this.attachRetryTimer);this.attachRetryTimer=-1;}
      this.host.logInfo(`ime showTextInput ok field=${mount.fieldId} seq=${attachSeq} reason=${reason}`);
      this.joinPendingOrdinary(mount, 'attach-wake');
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
      const sessionEligible: boolean = this.attachAttemptCurrent(mount,attachSeq,focusGeneration);
      const selectionPending: boolean = this.selMount === mount;
      if (code === 12800009 && sessionEligible) {
        if (this.host.hasImeTrafficEvidence(mount)) {
          this.attachedMount = mount;   // 会话事实：无 pending 也保留
          this.attachedFocusGeneration = focusGeneration;
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
            this.attachRetryTimer=setTimeout(() => {
              // R4：重试票据归属——只有创建它的尝试仍是 live 时才重试。否则重试
              // 会递增 attachSeq，把更新的在飞成功/重试误判成 stale（Astra 指出
              // 的抢占：焦点路径与重试链互相淘汰）。
              if (this.attachAttemptCurrent(retryMount,retrySeq,focusGeneration)) {
                this.attachRetryTimer=-1;
                this.requestShowForAttach(retryMount,retrySeq,focusGeneration,`retry-${retryReason}`);
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
    this.driveRestore(reason);
    if (this.selMount !== mount || !this.host.isCurrentMount(mount)) {
      return;
    }
    if (!this.isAttachedTo(mount)) {
      this.host.logInfo(`ime proxy selection waiting for attach reason=${reason} mount=${mount.key.describe()}`);
      return;
    }
    this.install(mount, this.selStart, this.selEnd, 0, this.selSeq, reason);
  }

  // 有界重投：焦点达成的那一帧平台会把光标推到末尾（或折叠选区），早装会被
  // 随后的重置覆盖，因此按挂载身份重投至多 8 次；观测到目标值即由回声终结。
  private install(mount: CjguiTextProxyMount, start: number, end: number,
    attempt: number, seq: number, reason: string): void {
    if (!this.executionCurrent(mount, seq)) {
      return; // 已被新目标/新挂载/收尾取代的过期定时器
    }
    if (!this.isRestoreExecution(mount, seq) && this.host.restoreTaskActive()) {
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
    if (!this.isAttachedTo(mount)) {
      this.host.logInfo(`ime proxy selection deferred (attach pending) reason=${reason} attempt=${attempt}`);
      if (attempt >= 8) {
        // 耗尽不是成功，也不静默清待办——记 UNCONFIRMED，由 native/窗口重签。
        this.settleExecution(mount, seq, 'UNCONFIRMED', `${reason}_attach_pending_exhausted`);
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
      if (this.isRestoreExecution(mount, seq) ? this.restoreSetterSent : seq === this.installSentSeq) {
        return;
      }
      if (this.isRestoreExecution(mount, seq)) { this.restoreSetterSent = true; }
      else { this.installSentSeq = seq; }
      if (this.isRestoreExecution(mount, seq) && this.restoreExistingWrite) {
        this.host.logInfo(`ime restore adopts in-flight selection request=${this.restoreTicket!.request}`);
      } else {
        if (this.activeWrite!==null) { this.retiredWrite=this.activeWrite; }
        this.activeWrite=new CjguiProgramSelectionWrite(mount,seq,start,end);
        this.host.setSelection(start, end);
        const ordinary=mount.ordinaryExecution;
        if(ordinary!==null && ordinary.install===seq &&
          this.host.observeOrdinarySelection(ordinary,3,start,end,this.attachSeq)!=='0')throw new Error('ordinary setter fact rejected');
        const e=mount.commandExecution;
        if(e!==null && e.install===seq && e.command===this.capturedCommand) {
          if(this.host.observeSelectionCommand(e,3,start,end)!=='0')throw new Error('command setter fact rejected');
          e.setterSent=true;
        }
      }
      // R2：程序选区命令已下发——它的平台回声按本命令的括号消费。
      this.echoMount = mount;
      this.echoOpen = true;
      this.host.logInfo(`ime proxy selection set [${start},${end}) reason=${reason} attempt=${attempt}`);
    } catch (err) {
      this.host.logWarn(`ime proxy selection threw reason=${reason} err=${String(err)}`);
      this.settleExecution(mount, seq, 'UNCONFIRMED', `${reason}_throw`);
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
    if(mount.commandExecution!==null && mount.commandExecution.install===seq) {
      const e=mount.commandExecution;
      this.scheduleCommandObservation(mount,e,start,end,seq,reason,0);
    } else {
      setTimeout(() => { this.confirm(mount, start, end, seq, reason, 0); }, 32);
    }
  }

  private scheduleCommandObservation(mount: CjguiTextProxyMount, e: CjguiPhysicalCommandExecution,
    start: number, end: number, seq: number, reason: string, round: number): void {
    e.selectionFrame?.cancel();
    if(round===0)e.firstFrameReady=false;else e.secondFrameReady=false;
    const frame=this.host.beforeComponentFrame(mount,(time: number)=>{
      if(e.selectionFrame!==frame)return;
      e.selectionFrame=null;
      if(mount.commandExecution!==e || e.command!==this.capturedCommand || e.consumedInput ||
        !this.executionCurrent(mount,seq) || !this.isAttachedTo(mount) || this.attachSeq!==e.attach)return;
      if(!Number.isFinite(time) || time<=0 || (round!==0 && time<=e.firstFrameTime)) {
        this.settle(mount,'UNCONFIRMED','command_distinct_frame_missing');return;
      }
      if(round===0){e.firstFrameTime=time;e.firstFrameReady=true;}
      else {e.secondFrameTime=time;e.secondFrameReady=true;}
      this.host.logInfo(`physical command onFrame id=${e.command.id} execution=${e.sequence} round=${round} frameTime=${time}`);
      this.confirm(mount,start,end,seq,reason,round);
    });
    e.selectionFrame=frame;
  }

  // 跨帧确认窗口：连续两帧读数精确命中目标才结算 INSTALLED；任何一次不命中
  // 即失败证据（终态，不重置预算重投）。
  confirm(mount: CjguiTextProxyMount, start: number, end: number,
    seq: number, reason: string, round: number): void {
    if (!this.executionCurrent(mount, seq) || !this.isAttachedTo(mount)) {
      return; // 已被新目标/新挂载/收尾取代
    }
    if (this.isRestoreExecution(mount, seq) && this.waitForRestoreInput(mount, this.restoreTicket!,
      () => { this.confirm(mount, start, end, seq, reason, round); })) { return; }
    const commandFrame=mount.commandExecution;
    if(commandFrame!==null && commandFrame.install===seq &&
      (round===0 ? (!commandFrame.firstFrameReady || commandFrame.firstObserved) :
        (!commandFrame.secondFrameReady || !commandFrame.firstObserved)))return;
    if(commandFrame!==null && commandFrame.install===seq) {
      if(round===0)commandFrame.firstFrameReady=false;else commandFrame.secondFrameReady=false;
    }
    if (!this.isRestoreExecution(mount, seq) && this.host.restoreTaskActive()) {
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
        const e=yieldMount.commandExecution;
        if(e!==null && e.install===yieldSeq && e.command===this.capturedCommand) {
          this.scheduleCommandObservation(yieldMount,e,yieldStart,yieldEnd,yieldSeq,yieldReason,yieldRound);
        } else {this.confirm(yieldMount, yieldStart, yieldEnd, yieldSeq, yieldReason, yieldRound);}
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
      this.settleExecution(mount, seq, 'UNCONFIRMED', `${reason}_confirm_getter_threw`);
      return;
    }
    if (observedStart !== start || observedEnd !== end) {
      this.host.logWarn(`ime selection confirm mismatch round=${round} target=[${start},${end}) ` +
        `observed=[${observedStart},${observedEnd}) reason=${reason}`);
      // 确认窗口内的失配是终态证据：setter 已下发而读数仍不等于目标，说明平台
      // 把落点折叠/覆盖了；以重置预算重装只会无界循环。结算 UNCONFIRMED，
      // 由窗口按恢复事务有界重签。
      this.settleExecution(mount, seq, 'UNCONFIRMED', `${reason}_confirm_mismatch`, observedStart, observedEnd);
      return;
    }
    if (round + 1 >= 2) {
      if (this.isRestoreExecution(mount, seq)) {
        this.settleExecution(mount, seq, 'INSTALLED', `${reason}_confirmed`, observedStart, observedEnd);
        return;
      }
      const execution=mount.commandExecution;
      if(execution!==null && execution.install===seq && execution.command===this.capturedCommand) {
        const rc=this.host.observeSelectionCommand(execution,1,observedStart,observedEnd);
        this.host.logInfo(`physical command getter id=${execution.command.id} execution=${execution.sequence} round=1 frameTime=${execution.secondFrameTime} range=${observedStart}:${observedEnd} native=${rc}`);
        if(rc==='2') {
          mount.commandExecution=null;mount.selectionCommand=null;
          this.settle(mount,'UNCONFIRMED','command_target_superseded');this.driveCapturedCommand();return;
        }
        if(rc!=='0'){this.settle(mount,'UNCONFIRMED','command_native_confirmation_rejected');return;}
        execution.installed=true;
        if(this.commandTimer!==-1){clearTimeout(this.commandTimer);this.commandTimer=-1;}
        this.settle(mount,'INSTALLED',`${reason}_confirmed`);return;
      }
      // 连续两帧命中：平台的稳定落点，而不是控制器自回声。
      // R2：native 的接受结果是 INSTALLED 的组成部分——rc != '0' 按具名
      // UNCONFIRMED 收口，保留可恢复源选择（生产反例：imeSetSelection
      // 返回 1 仍记 INSTALLED）。
      const ordinary=mount.ordinaryExecution;
      const rc: string = ordinary!==null && ordinary.install===seq ?
        this.host.observeOrdinarySelection(ordinary,1,observedStart,observedEnd,this.attachSeq) :
        this.host.commitInstalled(observedStart, observedEnd, mount.key.contextId);
      if (rc !== '0') {
        this.host.logWarn(`ime selection native rejected rc=${rc} target=[${start},${end}) ` +
          `mount=${mount.key.describe()}`);
        this.settle(mount, 'UNCONFIRMED', `native_rejected_rc_${rc}`);
        return;
      }
      if(ordinary!==null && ordinary.install===seq)ordinary.installed=true;
      this.settle(mount, 'INSTALLED', `${reason}_confirmed`);
      return;
    }
    const execution=mount.commandExecution;
    if(execution!==null && execution.install===seq && execution.command===this.capturedCommand) {
      const rc=this.host.observeSelectionCommand(execution,0,observedStart,observedEnd);
      this.host.logInfo(`physical command getter id=${execution.command.id} execution=${execution.sequence} round=0 frameTime=${execution.firstFrameTime} range=${observedStart}:${observedEnd} native=${rc}`);
      if(rc==='2') {
        mount.commandExecution=null;mount.selectionCommand=null;
        this.settle(mount,'UNCONFIRMED','command_target_superseded');this.driveCapturedCommand();return;
      }
      if(rc!=='0') {
        this.settle(mount,'UNCONFIRMED','command_first_observation_rejected');return;
      }
      execution.firstObserved=true;
      this.scheduleCommandObservation(mount,execution,start,end,seq,reason,round+1);
    } else {
      const ordinary=mount.ordinaryExecution;
      if(ordinary!==null && ordinary.install===seq && this.host.observeOrdinarySelection(ordinary,0,observedStart,observedEnd,this.attachSeq)!=='0') {
        this.settle(mount,'UNCONFIRMED','ordinary_first_observation_rejected');return;
      }
      setTimeout(() => { this.confirm(mount, start, end, seq, reason, round + 1); }, 32);
    }
  }

  // 安装待办的具名终态结算。INSTALLED 只在组件观测精确命中**且 native 接受**
  // 时给出；其余一律 UNCONFIRMED 并保留可恢复源选择——native 按失败取消该
  // 请求，由窗口的有界重试重新签发。不清 attachedMount（会话级事实）。
  settle(mount: CjguiTextProxyMount, terminal: string, reason: string): void {
    const ordinary=mount.ordinaryExecution;
    if(ordinary!==null && ordinary.install===this.selSeq && terminal!=='INSTALLED') {
      this.host.observeOrdinarySelection(ordinary,2,ordinary.start,ordinary.end,this.attachSeq);
      if(mount.originalInsertExecution===ordinary)mount.originalInsertExecution=null;
      mount.ordinaryExecution=null;
    }
    const execution=mount.commandExecution;
    execution?.selectionFrame?.cancel();
    if(terminal!=='INSTALLED' && execution!==null && execution.install===this.selSeq && execution.command===this.capturedCommand) {
      this.host.observeSelectionCommand(execution,2,execution.start,execution.end);
      this.retireCapturedCommand(reason);
    }
    if(terminal!=='INSTALLED' && mount.selectionCommand!==null && mount.selectionCommand.installSequence===this.selSeq) {
      mount.selectionCommand=null;
    }
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
    const captured=this.capturedCommand,origin=this.commandOriginMount;
    if(captured!==null && origin!==null && this.host.isCurrentMount(mount) &&
      mount.key.appInstance===captured.key.appInstance && mount.key.sessionToken===captured.key.sessionToken &&
      mount.fieldId===origin.fieldId && mount.focusGeneration===captured.focus) {
      if(this.host.prepareSelectionCommand(origin,captured.id,0,0,0).length===0) {
        this.retireCapturedCommand('native_selection_cancel');
      } else {
        const e=mount.commandExecution;
        // Untagged mount/default-caret callbacks cannot replace the admitted
        // full-source command while its actual target/body are still pending.
        return e!==null && e.command===captured && e.bodySettled && start===e.start && end===e.end ?
          'command-target' : 'unattributed-command';
      }
    }
    const command=mount.selectionCommand;
    if (command!==null && command.key===mount.key && command.focus!==mount.focusGeneration) {
      return 'unattributed-command';
    }
    if (this.activeWrite!==null && this.activeWrite.mount===mount &&
      this.activeWrite.focus!==mount.focusGeneration) { return 'unattributed-retired-write'; }
    if (command!==null && command.key===mount.key && command.focus===mount.focusGeneration && command.text===mount.draft) {
      return start===0 && end===command.text.length ? 'command-target' : 'unattributed-command';
    }
    const retired=this.retiredWrite;
    if (retired!==null && retired.current(mount) && start===retired.start && end===retired.end &&
      (this.activeWrite===null || this.activeWrite.sequence!==retired.sequence)) { return 'unattributed-retired-write'; }
    const active=this.activeWrite;
    if (active!==null && active.current(mount) && this.selMount===mount && active.sequence===this.selSeq &&
      start===active.start && end===active.end) { return 'installation'; }
    return 'fact';
  }

  // R2：真实改文到达 ⇒ 关闭回声括号。内容相关联的选区变化（组合提交后的
  // 收拢 caret 等）是平台事实，不是旧命令的回声。
  noteTraffic(mount: CjguiTextProxyMount): void {
    if (this.activeWrite!==null && this.activeWrite.mount===mount) { this.activeWrite=null; }
    if (this.retiredWrite!==null && this.retiredWrite.mount===mount) { this.retiredWrite=null; }
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
    if (this.restoreMount === mount) { this.finishRestore(false, -1, -1, 'human_input_supersedes'); }
    if (this.selMount === mount) {
      this.settle(mount, 'UNCONFIRMED', 'human_input_supersedes');
    }
  }
}
