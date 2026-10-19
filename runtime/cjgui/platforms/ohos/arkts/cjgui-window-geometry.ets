import { window } from '@kit.ArkUI';
import { UIContext, KeyboardAvoidMode } from '@ohos.arkui.UIContext';
import { hilog } from '@kit.PerformanceAnalysisKit';
import componentUtils from '@ohos.arkui.componentUtils';
import systemDateTime from '@ohos.systemDateTime';

interface CjguiGeometrySurfaceObservation {
  size: componentUtils.Size;
  windowOffset: componentUtils.Offset;
  screenOffset: componentUtils.Offset;
}
interface CjguiGeometryObservation {
  sequence: number;
  timestamp: number;
  monotonicMs: number;
  event: string;
  eventType: number;
  eventArea: window.AvoidArea | null;
  getterArea: window.AvoidArea;
  keyboardHeight: number;
  windowRect: window.Rect;
  surface: CjguiGeometrySurfaceObservation | null;
  publishedTop: number | null;
  geometryStatus: string;
}
interface CjguiGeometryResolution {
  topPx: number | null;
  status: string;
}

// A self-drawn surface owns caret reveal. ArkUI must not separately translate
// the whole canvas to keep an invisible full-document TextArea on screen.
export class CjguiWindowGeometry {
  private previousMode: KeyboardAvoidMode;
  private released: boolean = false;
  private keyboardChanged: (height: number) => void;
  private avoidChanged: (event: window.AvoidAreaOptions) => void;
  private lastKeyboardHeight: number = -1;
  private observeUntil: number = 0;
  private observationEnabled: boolean = false;
  private observedEvents: number = 0;
  private observedBytes: number = 0;
  private observationError: string = '';
  private ui: UIContext;
  private win: window.Window;
  private surfaceId: string;
  private publishOverlay: (topPx: number) => void;

  constructor(ui: UIContext, win: window.Window,
    surfaceId: string, publishOverlay: (topPx: number) => void, observeForDiagnostics: boolean = false) {
    this.ui = ui;
    this.win = win;
    this.surfaceId = surfaceId;
    this.publishOverlay = publishOverlay;
    this.previousMode = ui.getKeyboardAvoidMode();
    ui.setKeyboardAvoidMode(KeyboardAvoidMode.NONE);
    this.observationEnabled = observeForDiagnostics;
    this.keyboardChanged = (height: number) => {
      this.lastKeyboardHeight = height;
      this.report('keyboardHeightChange');
    };
    this.avoidChanged = (event: window.AvoidAreaOptions) => { this.report('avoidAreaChange', event); };
    win.on('keyboardHeightChange', this.keyboardChanged);
    win.on('avoidAreaChange', this.avoidChanged);
    this.report('initial');
  }

  // Diagnostic lifetime follows the actual current TextInput focus, not app
  // startup/navigation. It never requests focus/geometry or refreshes a limit.
  beginObservation(): void {
    if (this.released || !this.observationEnabled || this.observeUntil > 0) { return; }
    this.observeUntil = systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false) + 30000;
  }

  private validRectangle(rect: window.Rect): boolean {
    return rect !== null && rect !== undefined && Number.isFinite(rect.left) && Number.isFinite(rect.top) &&
      Number.isFinite(rect.width) && Number.isFinite(rect.height) && rect.width >= 0 && rect.height >= 0;
  }

  private bottomOverlay(area: window.AvoidArea, surface: CjguiGeometrySurfaceObservation | null): CjguiGeometryResolution {
    if (area === null || area === undefined || typeof area.visible !== 'boolean') {
      return { topPx: null, status: 'unknown_area' };
    }
    if (!area.visible) { return { topPx: -1, status: 'hidden' }; }
    const rectangles: window.Rect[] = [area.leftRect, area.topRect, area.rightRect, area.bottomRect];
    for (const rect of rectangles) {
      if (!this.validRectangle(rect)) { return { topPx: null, status: 'unknown_rectangle' }; }
    }
    // Degenerate rectangles have no pixels, including width=0,height>0. A
    // visible AvoidArea with four empty rectangles is a real SDK result.
    if (!rectangles.some((rect: window.Rect) => rect.width > 0 && rect.height > 0)) {
      return { topPx: -1, status: 'empty' };
    }
    if (surface === null || !Number.isFinite(surface.windowOffset.x) || !Number.isFinite(surface.windowOffset.y) ||
      !Number.isFinite(surface.size.width) || !Number.isFinite(surface.size.height) ||
      surface.size.width <= 0 || surface.size.height <= 0) {
      return { topPx: null, status: 'unknown_surface' };
    }
    const left: number = surface.windowOffset.x;
    const top: number = surface.windowOffset.y;
    const right: number = left + surface.size.width;
    const bottom: number = top + surface.size.height;
    for (let i: number = 0; i < 3; i += 1) {
      const other: window.Rect = rectangles[i];
      if (other.width > 0 && other.height > 0 && other.left < right && other.left + other.width > left &&
        other.top < bottom && other.top + other.height > top) {
        return { topPx: null, status: 'unsupported_nonbottom' };
      }
    }
    const rect: window.Rect = area.bottomRect;
    if (rect.width <= 0 || rect.height <= 0 || rect.left >= right || rect.left + rect.width <= left ||
      rect.top >= bottom || rect.top + rect.height <= top) {
      return { topPx: -1, status: 'no_intersection' };
    }
    // This bridge represents only a full-width bottom cut. Do not silently
    // relabel a top/side/floating region as a full-surface occlusion.
    if (rect.left > left || rect.left + rect.width < right || rect.top + rect.height < bottom) {
      return { topPx: null, status: 'unsupported_shape' };
    }
    // AvoidArea and windowOffset are window-local px. Subtract exactly once;
    // never subtract keyboardHeight from an already resized surface.
    return { topPx: Math.max(0, Math.floor(rect.top - top)), status: 'bottom_intersection' };
  }

  report(event: string = 'manual', eventData: window.AvoidAreaOptions | null = null): void {
    if (this.released) { return; }
    if (eventData !== null && eventData.type !== window.AvoidAreaType.TYPE_KEYBOARD) { return; }
    const nowMono: number = this.observeUntil > 0 ? systemDateTime.getUptime(systemDateTime.TimeType.ACTIVE, false) : 0;
    const observing: boolean = this.observeUntil > 0 && nowMono <= this.observeUntil && this.observedEvents < 64;
    // A keyboard avoidance callback supplies its own immutable event facts.
    // A separately sampled getter is diagnostic data, not its replacement.
    const getterArea: window.AvoidArea = eventData === null || observing ?
      this.win.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD) : eventData.area;
    const area: window.AvoidArea = eventData === null ? getterArea : eventData.area;
    let rect: CjguiGeometrySurfaceObservation | null = null;
    try {
      const actual = this.ui.getComponentUtils().getRectangleById(this.surfaceId);
      rect = { size: actual.size, windowOffset: actual.windowOffset, screenOffset: actual.screenOffset };
    } catch (error) {
      hilog.warn(0, 'CjguiWindow', 'surface geometry unavailable event=%{public}s error=%{public}s', event, String(error));
    }
    const resolution: CjguiGeometryResolution = this.bottomOverlay(area, rect);
    if (observing) {
      this.observedEvents += 1;
      try {
        const properties = this.win.getWindowProperties();
        const observation: CjguiGeometryObservation = {
          sequence: this.observedEvents, timestamp: Date.now(), monotonicMs: nowMono, event: event,
          eventType: eventData === null ? -1 : eventData.type,
          eventArea: eventData === null ? null : eventData.area,
          getterArea: getterArea, keyboardHeight: this.lastKeyboardHeight,
          windowRect: properties.windowRect,
          surface: rect === null ? null : {
            size: rect.size, windowOffset: rect.windowOffset, screenOffset: rect.screenOffset
          },
          publishedTop: resolution.topPx, geometryStatus: resolution.status
        };
        const message: string = JSON.stringify(observation);
        this.observedBytes = message.length;
        if (message.length > 8192) {
          this.observationError = 'metadata_over_budget';
        } else {
          // Each immutable record is reconstructible, not a truncated JSON
          // assertion. Keep individual SDK log arguments smaller than the
          // scalar witness already observed on the normal device channel.
          const parts: number = Math.ceil(message.length / 160);
          for (let part: number = 0; part < parts; part += 1) {
            hilog.warn(0, 'CjguiWindow', 'geometry observation chunk seq=%{public}d part=%{public}d count=%{public}d %{public}s',
              this.observedEvents, part, parts, message.slice(part * 160, (part + 1) * 160));
          }
        }
      } catch (error) {
        this.observationError = String(error);
        hilog.warn(0, 'CjguiWindow', 'geometry observation unavailable event=%{public}s error=%{public}s', event, String(error));
      }
    }
    if (resolution.topPx === null) {
      hilog.warn(0, 'CjguiWindow', 'keyboard geometry unavailable event=%{public}s status=%{public}s', event, resolution.status);
      return;
    }
    this.publishOverlay(resolution.topPx);
    hilog.info(0, 'CjguiWindow', 'keyboard overlay report top_surface=%{public}d mode=NONE status=%{public}s geometry_v=3 observing=%{public}d events=%{public}d bytes=%{public}d error=%{public}s',
      resolution.topPx, resolution.status, observing ? 1 : 0, this.observedEvents, this.observedBytes, this.observationError);
  }

  release(): void {
    if (this.released) { return; }
    this.released = true;
    this.win.off('keyboardHeightChange', this.keyboardChanged);
    this.win.off('avoidAreaChange', this.avoidChanged);
    if (this.ui.getKeyboardAvoidMode() === KeyboardAvoidMode.NONE) {
      this.ui.setKeyboardAvoidMode(this.previousMode);
    }
    this.publishOverlay(-1);
  }
}
