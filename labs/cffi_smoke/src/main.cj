foreign func cj_gui_add_i32(left: Int32, right: Int32): Int32

main(): Int64 {
    let result = unsafe { cj_gui_add_i32(20, 22) }
    println("C FFI result: ${result}")
    return 0
}
