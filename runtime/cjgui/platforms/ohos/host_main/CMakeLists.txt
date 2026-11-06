cmake_minimum_required(VERSION 3.5.0)
project(ohos_cjgui_app)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

add_library(entry SHARED
    cjgui_host_bridge.cpp)

find_library(hilog-lib hilog_ndk.z)
find_library(napi-lib ace_napi.z)
find_library(egl-lib EGL)
find_library(gles-lib GLESv3)
find_library(window-lib native_window)
find_library(ace-ndk ace_ndk.z)
find_library(drawing-lib native_drawing)
find_library(display-lib native_display_manager)

target_link_libraries(entry PUBLIC
    ${hilog-lib}
    ${napi-lib}
    ${egl-lib}
    ${gles-lib}
    ${window-lib}
    ${ace-ndk}
    ${drawing-lib}
    ${display-lib}
    dl)
