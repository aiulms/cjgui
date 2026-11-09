// 生成 region 的诊断出口（macOS 主树）：无渲染器日志通道，空实现。
// 诊断绝不改变生产判定；OHOS 树的同名文件接 hilog。
package cjgui

func generatedRegionDiagLog(message: String): Unit {
    let _ = message
}
