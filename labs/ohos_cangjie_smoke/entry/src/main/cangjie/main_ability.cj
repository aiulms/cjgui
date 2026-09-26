package ohos_app_cangjie_entry

import kit.PerformanceAnalysisKit.Hilog
import kit.AbilityKit.Want
import kit.AbilityKit.UIAbility
import kit.AbilityKit.LaunchParam
import kit.AbilityKit.LaunchReason
import kit.ArkUI.WindowStage

class MainAbility <: UIAbility {
    public init() {
        super()
        registerSelf()
        Hilog.info(0, "CangjiePoc", "MainAbility ctor + registerSelf done")
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        Hilog.info(0, "CangjiePoc", "MainAbility OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case LaunchReason.StartAbility => Hilog.info(0, "CangjiePoc", "START_ABILITY")
            case _ => ()
        }
    }

    public override func onWindowStageCreate(windowStage: WindowStage): Unit {
        Hilog.info(0, "CangjiePoc", "onWindowStageCreate begin")
        windowStage.loadContent("Index")
        Hilog.info(0, "CangjiePoc", "onWindowStageCreate loadContent returned")
    }

    public override func onForeground(): Unit {
        Hilog.info(0, "CangjiePoc", "onForeground")
    }

    public override func onDestroy(): Unit {
        Hilog.info(0, "CangjiePoc", "onDestroy")
    }
}
