import { window } from '@kit.ArkUI';
import { UIContext, KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { hilog } from '@kit.PerformanceAnalysisKit';

// A self-drawn surface owns caret reveal. ArkUI must not separately translate
// the whole canvas to keep an invisible full-document TextArea on screen.
export class CjguiWindowGeometry {
  private previousMode: KeyboardAvoidMode;
  private released: boolean = false;
  private changed: () => void;
  private ui: UIContext;
  private win: window.Window;
  private surfaceId: string;
  private publishOverlay: (topPx: number) => void;

  constructor(ui: UIContext, win: window.Window,
    surfaceId: string, publishOverlay: (topPx: number) => void) {
    this.ui = ui;
    this.win = win;
    this.surfaceId = surfaceId;
    this.publishOverlay = publishOverlay;
    this.previousMode = ui.getKeyboardAvoidMode();
    ui.setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    this.changed = () => { this.report(); };
    win.on('keyboardHeightChange', this.changed);
    win.on('avoidAreaChange', this.changed);
    this.report();
  }

  report(): void {
    if (this.released) { return; }
    const area = this.win.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
    let top: number = -1;
    if (area.bottomRect.height > 0) { top = area.bottomRect.top; }
    else if (area.topRect.height > 0) { top = area.topRect.top; }
    let inSurface: number = -1;
    if (top >= 0) {
      const rect = this.ui.getComponentUtils().getRectangleById(this.surfaceId);
      if (rect.size.width <= 0 || rect.size.height <= 0) { return; }
      inSurface = Math.max(0, Math.floor(top - rect.windowOffset.y));
      hilog.info(0, 'CjguiWindow', 'surface geometry window_y=%{public}d screen_y=%{public}d width=%{public}d height=%{public}d',
        rect.windowOffset.y, rect.screenOffset.y, rect.size.width, rect.size.height);
    }
    this.publishOverlay(inSurface);
    hilog.info(0, 'CjguiWindow', 'keyboard overlay report top_window=%{public}d top_surface=%{public}d mode=NONE', top, inSurface);
  }

  release(): void {
    if (this.released) { return; }
    this.released = true;
    this.win.off('keyboardHeightChange', this.changed);
    this.win.off('avoidAreaChange', this.changed);
    if (this.ui.getKeyboardAvoidMode() === KeyboardAvoidMode.NONE) {
      this.ui.setKeyboardAvoidMode(this.previousMode);
    }
    this.publishOverlay(-1);
  }
}
