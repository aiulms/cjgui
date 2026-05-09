foreign func cjgui_native_bridge_surface_version(): UInt32
foreign func cjgui_native_bridge_surface_capabilities(): UInt32
foreign func cjgui_native_bridge_status_ok(): UInt32
foreign func cjgui_native_bridge_no_resource_admission(): UInt32
foreign func cjgui_native_bridge_is_main_thread(): Int32

main(): Int64 {
    println("cjgui native bridge ffi probe: requested=true")

    let surfaceVersion = unsafe {
        cjgui_native_bridge_surface_version()
    }
    let surfaceCapabilities = unsafe {
        cjgui_native_bridge_surface_capabilities()
    }
    let statusOk = unsafe {
        cjgui_native_bridge_status_ok()
    }
    let noResourceAdmission = unsafe {
        cjgui_native_bridge_no_resource_admission()
    }
    let mainThreadValue = unsafe {
        cjgui_native_bridge_is_main_thread()
    }

    let surfaceVersionObserved = surfaceVersion == UInt32(1)
    let capabilitiesObserved = surfaceCapabilities != UInt32(0)
    let statusObserved = statusOk == UInt32(0)
    let noResourceAdmissionObserved = noResourceAdmission == UInt32(0)
    let mainThreadQueryObserved =
        mainThreadValue == Int32(1) || mainThreadValue == Int32(0)
    let mainThreadObserved = mainThreadValue == Int32(1)
    let success = surfaceVersionObserved &&
        capabilitiesObserved &&
        statusObserved &&
        noResourceAdmissionObserved &&
        mainThreadQueryObserved &&
        mainThreadObserved

    println("cjgui native bridge ffi probe: surface_version_observed=${surfaceVersionObserved}")
    println("cjgui native bridge ffi probe: capabilities_observed=${capabilitiesObserved}")
    println("cjgui native bridge ffi probe: status_ok_observed=${statusObserved}")
    println("cjgui native bridge ffi probe: no_resource_admission_observed=${noResourceAdmissionObserved}")
    println("cjgui native bridge ffi probe: main_thread_query_observed=${mainThreadQueryObserved}")
    println("cjgui native bridge ffi probe: main_thread_observed=${mainThreadObserved}")

    if (success) {
        println("cjgui native bridge ffi probe: success=true reason=none")
        return 0
    }

    println("cjgui native bridge ffi probe: success=false reason=value_mismatch")
    return 1
}
