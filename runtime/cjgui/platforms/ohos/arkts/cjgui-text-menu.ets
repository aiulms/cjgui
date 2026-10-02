// CJGUI owns selection commands. ArkUI hosts their toolbar and the platform
// security PasteButton; system pasteboard bytes never become a second owner.
import pasteboard from '@ohos.pasteboard';
import { display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import entryNapi from 'libentry.so';

export interface CjguiMenuSnapshot {
  context: number;
  generation: number;
  baseVersion: number;
  selStart: number;
  selEnd: number;
  text: string;
  menuAvailable: boolean;
  previewText?: string;
  previewStart?: number;
  previewEnd?: number;
  menuX?: number;
  menuTop?: number;
  menuBottom?: number;
}

// 菜单有界元数据（B）：O(1) 字段，与整文上下文同一 menuValid 判定；正文只在
// 动作时按冻结身份取一次。menuX/Top/Bottom 仅在 menuAvailable 时出现。
export interface CjguiMenuMeta {
  context: number;
  generation: number;
  baseVersion: number;
  selStart: number;
  selEnd: number;
  menuAvailable: boolean;
  menuX?: number;
  menuTop?: number;
  menuBottom?: number;
}

export interface CjguiMenuBridge {
  command(action: string, inserted: string, snapshot: CjguiMenuSnapshot): boolean;
  write(text: string): Promise<void>;
  read(): Promise<string>;
  installed(context: number): void;
}

// Capture the original snapshot before await. The native command atomically
// checks it again; failure is terminal for this action, never an automatic retry.
export class CjguiMenuCommands {
  private bridge: CjguiMenuBridge;
  busy: boolean = false;
  constructor(bridge: CjguiMenuBridge) { this.bridge = bridge; }
  async copy(snapshot: CjguiMenuSnapshot, cut: boolean): Promise<boolean> {
    if (this.busy || snapshot.selStart >= snapshot.selEnd ||
      !this.bridge.command('validate', '', snapshot)) return false;
    this.busy = true;
    try {
      await this.bridge.write(snapshot.text.slice(snapshot.selStart, snapshot.selEnd));
      if (!this.bridge.command(cut ? 'replace' : 'validate', '', snapshot)) return false;
      if (cut) this.bridge.installed(snapshot.context);
      return true;
    } finally { this.busy = false; }
  }
  async paste(snapshot: CjguiMenuSnapshot, authorized: boolean): Promise<boolean> {
    if (!authorized || this.busy || !this.bridge.command('validate', '', snapshot)) return false;
    this.busy = true;
    try {
      const text = await this.bridge.read();
      if (!this.bridge.command('replace', text, snapshot)) return false;
      this.bridge.installed(snapshot.context);
      return true;
    } finally { this.busy = false; }
  }
  selectAll(snapshot: CjguiMenuSnapshot): boolean {
    if (this.busy || !this.bridge.command('selectAll', '', snapshot)) return false;
    this.bridge.installed(snapshot.context);
    return true;
  }
}

class EntryMenuBridge implements CjguiMenuBridge {
  private install: (context: number) => void;
  constructor(install: (context: number) => void) { this.install = install; }
  command(action: string, inserted: string, s: CjguiMenuSnapshot): boolean {
    return entryNapi.imeMenuCommand(action, inserted, s.context, s.generation,
      s.baseVersion, s.selStart, s.selEnd, s.text) === '0';
  }
  write(text: string): Promise<void> {
    return pasteboard.getSystemPasteboard().setData(pasteboard.createPlainTextData(text));
  }
  async read(): Promise<string> {
    const data = await pasteboard.getSystemPasteboard().getData();
    return data.getPrimaryText();
  }
  installed(context: number): void { this.install(context); }
}

@Component
export struct CjguiTextSelectionMenu {
  @Prop context: number = 0;
  onInstall: (context: number) => void = (_context: number): void => {};
  @State private visible: boolean = false;
  @State private selected: boolean = false;
  @State private menuX: number = 8;
  @State private menuY: number = 80;
  private snapshot: CjguiMenuSnapshot | null = null;
  private metaSnapshot: CjguiMenuMeta | null = null;
  private commands: CjguiMenuCommands | null = null;
  private timer: number = -1;
  private signature: string = '';

  aboutToAppear(): void {
    this.commands = new CjguiMenuCommands(new EntryMenuBridge((ctx: number) => this.onInstall(ctx)));
    this.refresh();
    this.timer = setInterval(() => this.refresh(), 100);
  }
  aboutToDisappear(): void {
    if (this.timer !== -1) clearInterval(this.timer);
    this.timer = -1; this.visible = false; this.snapshot = null; this.metaSnapshot = null;
  }
  // 周期消费只取 O(1) 元数据：菜单隐藏或正文不变时不再触发锁内整文
  // UTF-16→UTF-8/JSON 转义与拷贝（B 的成本缺口，实测 8–10 次/秒）。
  private refresh(): void {
    try {
      const raw = entryNapi.imeMenuMeta() as string;
      const m: CjguiMenuMeta | null = raw.length > 0 ? JSON.parse(raw) as CjguiMenuMeta : null;
      if (m === null || m.context !== this.context || !m.menuAvailable) {
        this.visible = false; this.snapshot = null; this.metaSnapshot = null; return;
      }
      this.metaSnapshot = m;
      this.selected = m.selStart < m.selEnd;
      const width = this.selected ? 256 : 136;
      const screen = display.getDefaultDisplaySync();
      const screenWidth = screen.width / screen.densityPixels;
      this.menuX = Math.max(8, Math.min((m.menuX ?? 8) - 24, screenWidth - width - 8));
      const top = m.menuTop ?? 80;
      this.menuY = top >= 96 ? top - 48 : (m.menuBottom ?? top) + 22;
      this.visible = true;
      const sig = `${m.context}:${m.selStart}:${m.selEnd}:${this.menuX}:${this.menuY}`;
      if (sig !== this.signature) {
        this.signature = sig;
        hilog.info(0, 'CjguiTextMenu', 'menu visible ctx=%{public}d range=%{public}d:%{public}d x=%{public}s y=%{public}s',
          m.context, m.selStart, m.selEnd, this.menuX.toFixed(2), this.menuY.toFixed(2));
      }
    } catch (_) { this.visible = false; this.snapshot = null; this.metaSnapshot = null; }
  }
  // 动作时按冻结身份取整文一次：imeMenuCommand 原子复验快照（含正文/选区/
  // 版本），迟到旧动作零写入的既有语义不变。
  private fetchActionSnapshot(): CjguiMenuSnapshot | null {
    try {
      const raw = entryNapi.imeEditingContext() as string;
      const s: CjguiMenuSnapshot | null = raw.length > 0 ? JSON.parse(raw) as CjguiMenuSnapshot : null;
      if (s === null || s.context !== this.context || !s.menuAvailable) return null;
      return s;
    } catch (_) { return null; }
  }
  private async copy(cut: boolean): Promise<void> {
    const s = this.fetchActionSnapshot(); const commands = this.commands;
    if (s === null || commands === null) return;
    try {
      const ok = await commands.copy(s, cut);
      hilog.info(0, 'CjguiTextMenu', 'menu %{public}s accepted=%{public}d', cut ? 'cut' : 'copy', ok ? 1 : 0);
    } catch (_) { hilog.warn(0, 'CjguiTextMenu', 'menu copy/cut pasteboard failed'); }
    this.refresh();
  }
  private async paste(authorized: boolean): Promise<void> {
    const s = this.snapshot; const commands = this.commands;
    if (s === null || commands === null) return;
    try {
      const ok = await commands.paste(s, authorized);
      hilog.info(0, 'CjguiTextMenu', 'menu paste authorized=%{public}d accepted=%{public}d', authorized ? 1 : 0, ok ? 1 : 0);
    } catch (_) { hilog.warn(0, 'CjguiTextMenu', 'menu pasteboard read failed'); }
    this.refresh();
  }
  private selectAll(): void {
    const s = this.snapshot; const commands = this.commands;
    if (s !== null && commands !== null) commands.selectAll(s);
    this.refresh();
  }
  build() {
    if (this.visible) {
      Row() {
        if (this.selected) {
          Button('剪切').id('cjgui-text-cut').width(60).height(40)
            .fontSize(16).fontColor('#161616').backgroundColor('#FFFFFF').padding({ left: 8, right: 8 })
            .focusable(false).focusOnTouch(false).onClick(() => this.copy(true))
          Button('复制').id('cjgui-text-copy').width(60).height(40)
            .fontSize(16).fontColor('#161616').backgroundColor('#FFFFFF').padding({ left: 8, right: 8 })
            .focusable(false).focusOnTouch(false).onClick(() => this.copy(false))
        }
        PasteButton({ text: PasteDescription.PASTE, buttonType: ButtonType.Normal })
          .id('cjgui-text-paste').width(68).height(40).fontSize(16)
          .fontColor('#161616').backgroundColor('#FFFFFF').padding(8)
          .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
            this.paste(result === PasteButtonOnClickResult.SUCCESS);
          })
        Button('全选').id('cjgui-text-select-all').width(68).height(40)
          .fontSize(16).fontColor('#161616').backgroundColor('#FFFFFF').padding({ left: 8, right: 8 })
          .focusable(false).focusOnTouch(false).onClick(() => this.selectAll())
      }
      .height(40).backgroundColor('#FFFFFF').borderRadius(20)
      .shadow({ radius: 8, color: '#30000000', offsetY: 3 })
      .position({ x: this.menuX, y: this.menuY })
      .zIndex(50)
    }
  }
}
