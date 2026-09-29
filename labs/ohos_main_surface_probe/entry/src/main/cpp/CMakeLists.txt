cmake_minimum_required(VERSION 3.5.0)
project(ohos_main_surface_probe)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

add_library(entry SHARED
    main_surface_probe.cpp)

find_library(hilog-lib hilog_ndk.z)
find_library(napi-lib ace_napi.z)
find_library(window-lib native_window)
find_library(windowmgr-lib native_window_manager)
find_library(ohinput-lib ohinput)
find_library(ace-ndk ace_ndk.z)

target_link_libraries(entry PUBLIC
    ${hilog-lib}
    ${napi-lib}
    ${window-lib}
    ${windowmgr-lib}
    ${ohinput-lib}
    ${ace-ndk}
    dl)
