import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import probe from 'libentry.so';

const TAG: string = 'MainSurfaceProbe';
const DOMAIN: number = 0x1234;

/**
 * 极薄 ArkTS Ability：只做三件事——取主窗口、把 windowId 交给原生探针、载入页面。
 * 本实验不创建 XComponent。
 */
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
    this.applyLaunchParams(want);
  }

  private applyLaunchParams(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }
    const rawLevel: Object | undefined = params['probeLevel'];
    if (rawLevel !== undefined) {
      let level: number = 0;
      if (typeof rawLevel === 'number') {
        level = rawLevel as number;
      } else if (typeof rawLevel === 'string') {
        level = Number.parseInt(rawLevel as string, 10);
      }
      if (Number.isFinite(level)) {
        AppStorage.setOrCreate<number>('probeLevel', level);
        hilog.info(DOMAIN, TAG, 'launch param probeLevel=%{public}d', level);
      }
    }
    const rawFrame: Object | undefined = params['frame'];
    if (rawFrame !== undefined) {
      let frame: number = -1;
      if (typeof rawFrame === 'number') {
        frame = rawFrame as number;
      } else if (typeof rawFrame === 'string') {
        frame = Number.parseInt(rawFrame as string, 10);
      }
      if (Number.isFinite(frame)) {
        AppStorage.setOrCreate<number>('frame', frame);
        hilog.info(DOMAIN, TAG, 'launch param frame=%{public}d', frame);
      }
    }
    const rawSkip: Object | undefined = params['arktsTransparency'];
    if (rawSkip !== undefined) {
      let v: number = 1;
      if (typeof rawSkip === 'number') { v = rawSkip as number; }
      else if (typeof rawSkip === 'string') { v = Number.parseInt(rawSkip as string, 10); }
      if (Number.isFinite(v)) {
        AppStorage.setOrCreate<number>('arktsTransparency', v);
        hilog.info(DOMAIN, TAG, 'launch param arktsTransparency=%{public}d', v);
      }
    }
    const rawRotate: Object | undefined = params['rotate'];
    if (rawRotate !== undefined) {
      let rot: number = -1;
      if (typeof rawRotate === 'number') {
        rot = rawRotate as number;
      } else if (typeof rawRotate === 'string') {
        rot = Number.parseInt(rawRotate as string, 10);
      }
      if (Number.isFinite(rot)) {
        AppStorage.setOrCreate<number>('rotate', rot);
        hilog.info(DOMAIN, TAG, 'launch param rotate=%{public}d', rot);
      }
    }
    const rawCand: Object | undefined = params['probeCandidate'];
    if (rawCand !== undefined) {
      let cand: number = 2;
      if (typeof rawCand === 'number') {
        cand = rawCand as number;
      } else if (typeof rawCand === 'string') {
        cand = Number.parseInt(rawCand as string, 10);
      }
      if (Number.isFinite(cand)) {
        AppStorage.setOrCreate<number>('probeCandidate', cand);
        hilog.info(DOMAIN, TAG, 'launch param probeCandidate=%{public}d', cand);
      }
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let win: window.Window | undefined = undefined;
    try {
      win = windowStage.getMainWindowSync();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'getMainWindowSync failed: %{public}s', JSON.stringify(e));
    }
    if (win !== undefined) {
      const props: window.WindowProperties = win.getWindowProperties();
      const rect: window.Rect = props.windowRect;
      hilog.info(DOMAIN, TAG,
        'PUBLIC ArkTS main window id=%{public}d displayId=%{public}d rect=%{public}d,%{public}d %{public}dx%{public}d',
        props.id, props.displayId, rect.left, rect.top, rect.width, rect.height);
      AppStorage.setOrCreate<number>('mainWindowId', props.id);
      AppStorage.setOrCreate<number>('mainWindowW', Math.round(rect.width));
      AppStorage.setOrCreate<number>('mainWindowH', Math.round(rect.height));
      // 让整个窗口底色可判读：若自绘 buffer 未被合成，截图应看到这个底色。
      try {
        win.setWindowBackgroundColor('#FF202020');
        hilog.info(DOMAIN, TAG, 'setWindowBackgroundColor #FF202020 ok');
      } catch (e) {
        hilog.error(DOMAIN, TAG, 'setWindowBackgroundColor failed: %{public}s', JSON.stringify(e));
      }
      // 公开接口里没有任何 surface/surfaceId 取值入口；这里只把 windowId 交给原生探针。
      probe.setWindow(props.id, Math.round(rect.width), Math.round(rect.height));
    }

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }
}
