import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'ImeControl';

@Entry
@Component
struct Index {
  @State private eventCount: number = 0;
  @State private focusState: string = 'Not focused';
  @State private lastValue: string = '(none)';
  @State private lastPreview: string = 'No onChange yet';
  @State private lastOptions: string = 'No onChange yet';

  build() {
    Column({ space: 16 }) {
      Text('ArkUI TextInput preview control')
        .fontSize(22)

      Text('Tap the visible field, type pinyin, and pause before choosing a candidate.')
        .fontSize(16)

      // Keep the native field uncontrolled: do not feed onChange value back into TextInput.text.
      TextInput({ placeholder: 'Type nihao here' })
        .id('ime-control-input')
        .enablePreviewText(true)
        .width('92%')
        .height(56)
        .onFocus(() => {
          this.focusState = 'Focused';
          hilog.info(DOMAIN, TAG, 'focused');
        })
        .onBlur(() => {
          this.focusState = 'Blurred';
          hilog.info(DOMAIN, TAG, 'blurred');
        })
        .onChange((value: string, previewText?: PreviewText, options?: TextChangeOptions) => {
          const present: boolean = previewText !== undefined && previewText !== null;
          const offset: number = present ? previewText!.offset : -1;
          const previewValue: string = present ? previewText!.value : '';
          const optionsPresent: boolean = options !== undefined && options !== null;

          this.eventCount += 1;
          this.lastValue = value;
          this.lastPreview = present
            ? `present; offset=${offset}; value="${previewValue}"`
            : 'absent';
          this.lastOptions = optionsPresent ? 'present' : 'absent';

          hilog.info(DOMAIN, TAG,
            'onChange seq=%{public}d value=%{public}s previewPresent=%{public}d previewOffset=%{public}d previewValue=%{public}s optionsPresent=%{public}d',
            this.eventCount, value, present ? 1 : 0, offset, previewValue, optionsPresent ? 1 : 0);
        })
        .onSubmit(() => {
          hilog.info(DOMAIN, TAG, 'submitted after %{public}d changes', this.eventCount);
        })

      Text(`Focus: ${this.focusState}`)
      Text(`onChange count: ${this.eventCount}`)
      Text(`Current value: ${this.lastValue}`)
      Text(`PreviewText: ${this.lastPreview}`)
      Text(`TextChangeOptions: ${this.lastOptions}`)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 32, left: 18, right: 18 })
  }
}
