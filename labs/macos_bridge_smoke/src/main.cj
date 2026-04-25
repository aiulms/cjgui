foreign func cjgui_app_run(): Int32

main(): Int64 {
    println("Cangjie: calling cjgui_app_run")
    let code = unsafe { cjgui_app_run() }
    println("Cangjie: cjgui_app_run returned ${code}")
    return Int64(code)
}
