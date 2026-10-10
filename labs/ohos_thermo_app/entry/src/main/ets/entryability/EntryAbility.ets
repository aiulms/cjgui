import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import entryNapi from 'libentry.so';

const TAG: string = 'CjguiApp';
const DOMAIN: number = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');
    entryNapi.appForeground(false);
    // A1 §5：受控闸门由**启动参数**带入（`aa start --pi <key> <n>`）。
    // 这是测试控制进入应用内的唯一通道，不新增任何对外控制面；普通产物上
    // 转发必然返回 -1（不可用），时序不受影响。必须在 XComponent/host 启动
    // 之前生效，才能卡住首帧。
    this.applyTestGateFromLaunchParams(want);
    this.applyFailFirstFrameFromLaunchParams(want);
  }

  private applyTestGateFromLaunchParams(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }
    const rawMs: Object | undefined = params['cjguiTestGateFlushHoldMs'];
    if (rawMs === undefined) {
      return;
    }
    let ms: number = 0;
    if (typeof rawMs === 'number') {
      ms = rawMs as number;
    } else if (typeof rawMs === 'string') {
      ms = Number.parseInt(rawMs as string, 10);
    }
    if (!Number.isFinite(ms) || ms <= 0) {
      hilog.warn(DOMAIN, TAG, 'test gate launch param ignored: invalid ms');
      return;
    }
    let count: number = 1;
    const rawCount: Object | undefined = params['cjguiTestGateFlushHoldCount'];
    if (typeof rawCount === 'number') {
      count = rawCount as number;
    } else if (typeof rawCount === 'string') {
      count = Number.parseInt(rawCount as string, 10);
    }
    if (!Number.isFinite(count)) {
      count = 1;
    }
    const rc: number = entryNapi.setTestGate(ms, count) as number;
    hilog.info(DOMAIN, TAG,
      'test gate from launch params ms=%{public}d count=%{public}d rc=%{public}d',
      ms, count, rc);
  }

  // A3：首帧强制失败参数转发（启动失败→清理→重试反例的注入点）。
  private applyFailFirstFrameFromLaunchParams(want: Want): void {
    const params: Record<string, Object> | undefined = want.parameters;
    if (params === undefined) {
      return;
    }
    const raw: Object | undefined = params['cjguiTestGateFailFirstFrame'];
    if (raw === undefined) {
      return;
    }
    const flag: string = String(raw);
    if (flag !== '1' && flag !== 'true') {
      return;
    }
    const rc: number = entryNapi.setTestGateFailFirst() as number;
    hilog.info(DOMAIN, TAG, 'test gate fail-first-frame from launch params rc=%{public}d', rc);
  }

  onDestroy(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'onDestroy');
    // Keep the UI loop alive until the same host instance has really drained.
    return entryNapi.appShutdown();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent ok');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
    entryNapi.appForeground(true);
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
    entryNapi.appForeground(false);
  }
}
