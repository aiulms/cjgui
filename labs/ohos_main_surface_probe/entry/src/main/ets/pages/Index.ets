import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import probe from 'libentry.so';

const TAG: string = 'MainSurfaceProbe';
const DOMAIN: number = 0x1234;

/**
 * 页面只承担两件事：提供真实触摸落点（控件），以及把探针结果读回来。
 * 画面不被 ArkUI 覆盖：根容器透明，只有顶部一条控制卡有底色，其余区域
 * 若看到自绘 buffer 的颜色，就说明 frame 真的被合成了。
 */
@Entry
@Component
struct Index {
  @State report: string = '(尚未运行探针)';
  @State status: string = '';
  private candidate: number = 2;
  private win: window.Window | undefined = undefined;

  aboutToAppear(): void {
    const cand: number | undefined = AppStorage.get<number>('probeCandidate');
    if (cand !== undefined) {
      this.candidate = cand;
    }
    // 先把窗口底色改成透明：若 ArkUI 根节点在 RS 里画在不透明底色上，
    // 自绘 buffer 会永远被盖住；透明化是区分「没提交上」和「被盖住」的关键一步。
    window.getLastWindow(getContext(this)).then((w: window.Window) => {
      this.win = w;
      const skip: number | undefined = AppStorage.get<number>('arktsTransparency');
      if (skip === 0) {
        hilog.info(DOMAIN, TAG, 'skip ArkTS transparency (launch param arktsTransparency=0)');
      } else {
        this.applyWindowTransparency();
      }
      this.runAuto();
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, 'getLastWindow failed: %{public}s', JSON.stringify(e));
      this.runAuto();
    });
  }

  private applyOrientation(landscape: boolean): void {
    if (this.win === undefined) {
      return;
    }
    const target: window.Orientation = landscape ? window.Orientation.LANDSCAPE : window.Orientation.PORTRAIT;
    this.win.setPreferredOrientation(target).then(() => {
      hilog.info(DOMAIN, TAG, 'setPreferredOrientation(%{public}s) ok', landscape ? 'LANDSCAPE' : 'PORTRAIT');
      // 旋转是异步的：等窗口几何真正变化后再把新尺寸交给探针，并重新取一次 Surface。
      setTimeout(() => {
        this.reportRect('after-rotate');
        if (this.win !== undefined) {
          const r: window.Rect = this.win.getWindowProperties().windowRect;
          probe.setWindow(this.win.getWindowProperties().id, Math.round(r.width), Math.round(r.height));
        }
        this.runProbe(2);
      }, 3000);
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, 'setPreferredOrientation failed: %{public}s', JSON.stringify(e));
    });
  }

  private reportRect(tag: string): void {
    if (this.win === undefined) {
      return;
    }
    const props: window.WindowProperties = this.win.getWindowProperties();
    const r: window.Rect = props.windowRect;
    hilog.info(DOMAIN, TAG, '%{public}s window id=%{public}d rect=%{public}d,%{public}d %{public}dx%{public}d',
      tag, props.id, r.left, r.top, r.width, r.height);
  }

  private applyWindowTransparency(): void {
    if (this.win === undefined) {
      return;
    }
    try {
      this.win.setWindowBackgroundColor('#00000000');
      hilog.info(DOMAIN, TAG, 'setWindowBackgroundColor #00000000 (透明) ok');
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'setWindowBackgroundColor 透明失败: %{public}s', JSON.stringify(e));
    }
  }

  private runAuto(): void {
    const presetLevel: number | undefined = AppStorage.get<number>('probeLevel');
    if (presetLevel !== undefined) {
      hilog.info(DOMAIN, TAG, 'auto probe from launch param level=%{public}d cand=%{public}d',
        presetLevel, this.candidate);
      this.runProbe(presetLevel);
    }
    const presetRotate: number | undefined = AppStorage.get<number>('rotate');
    if (presetRotate !== undefined && presetRotate >= 0) {
      hilog.info(DOMAIN, TAG, 'auto rotate param=%{public}d', presetRotate);
      this.applyOrientation(presetRotate === 1);
    }
    const presetFrame: number | undefined = AppStorage.get<number>('frame');
    if (presetFrame !== undefined && presetFrame >= 0) {
      hilog.info(DOMAIN, TAG, 'auto frame from launch param frame=%{public}d', presetFrame);
      this.submit(presetFrame);
    }
  }

  private runProbe(level: number): void {
    const text: string = probe.probeRun(level, this.candidate) as string;
    this.report = text;
    this.status = probe.status() as string;
    hilog.info(DOMAIN, TAG, 'probe level=%{public}d cand=%{public}d report len=%{public}d',
      level, this.candidate, text.length);
  }

  private submit(frame: number): void {
    // frame 0 = 纯色蓝；frame 1 = 橙白棋盘；frame 2 = 青/黑竖条
    let rgb: number = 0x1E6BFF;
    let pattern: number = 0;
    if (frame === 1) {
      rgb = 0xFF8A00;
      pattern = 1;
    } else if (frame === 2) {
      rgb = 0x10E0C0;
      pattern = 2;
    }
    const rc: number = probe.submitFrame(rgb, pattern) as number;
    this.status = probe.status() as string;
    hilog.info(DOMAIN, TAG, 'submitFrame frame=%{public}d rc=%{public}d status=%{public}s',
      frame, rc, this.status);
  }

  build() {
    Column() {
      // 控制卡：唯一有 ArkUI 底色的区域
      Column({ space: 6 }) {
        Text('主窗口 Surface 探针（无 XComponent）').fontSize(15).fontColor('#FFFFFF')
        Row({ space: 4 }) {
          Button('公开层').onClick(() => this.runProbe(0)).fontSize(11).height(28)
          Button('私有库').onClick(() => this.runProbe(1)).fontSize(11).height(28)
          Button('取Surface').onClick(() => this.runProbe(2)).fontSize(11).height(28)
          Button('+硬件合成').onClick(() => this.runProbe(10)).fontSize(11).height(28)
        }
        Row({ space: 4 }) {
          Button('候选1').onClick(() => { this.candidate = 1; this.runProbe(2); }).fontSize(11).height(28)
          Button('候选2').onClick(() => { this.candidate = 2; this.runProbe(2); }).fontSize(11).height(28)
          Button('候选3').onClick(() => { this.candidate = 3; this.runProbe(2); }).fontSize(11).height(28)
          Button('候选4').onClick(() => { this.candidate = 4; this.runProbe(2); }).fontSize(11).height(28)
        }
        Row({ space: 4 }) {
          Button('帧0 蓝').onClick(() => this.submit(0)).fontSize(11).height(28)
          Button('帧1 橙格').onClick(() => this.submit(1)).fontSize(11).height(28)
          Button('帧2 青条').onClick(() => this.submit(2)).fontSize(11).height(28)
          Button('转横屏').onClick(() => this.applyOrientation(true)).fontSize(11).height(28)
          Button('转竖屏').onClick(() => this.applyOrientation(false)).fontSize(11).height(28)
          Button('释放').onClick(() => {
            probe.destroyNativeWindow();
            this.status = probe.status() as string;
          }).fontSize(11).height(28)
        }
        Text(this.status).fontSize(9).fontColor('#FFD060').maxLines(3)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#CC101010')

      // 报告区：透明底，读回探针文本
      Scroll() {
        Text(this.report).fontSize(9).fontColor('#FFE0E0E0').width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#00000000')
  }
}
