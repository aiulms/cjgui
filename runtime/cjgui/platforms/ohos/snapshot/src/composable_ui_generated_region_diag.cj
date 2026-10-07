// 生成 region 的诊断出口（OHOS 树）：经渲染器日志通道进 hilog，判定可见。
// macOS 主树的同名文件为空实现——共享 region 文件不得依赖平台专有通道。
package cjgui

func generatedRegionDiagLog(message: String): Unit {
    internalRendererWindowLog(message)
}
