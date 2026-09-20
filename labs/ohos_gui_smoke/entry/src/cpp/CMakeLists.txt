cmake_minimum_required(VERSION 3.5.0)
project(ohos_gui_smoke)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${NATIVERENDER_ROOT_PATH})

add_library(entry SHARED
    cards_owner.cpp
    cards_protocol.cpp
    cards_render.cpp
    state_server.cpp
    xcomp_bridge.cpp)

find_library(hilog-lib hilog_ndk.z)
find_library(napi-lib ace_napi.z)
find_library(egl-lib EGL)
find_library(gles-lib GLESv3)
find_library(window-lib native_window)

target_link_libraries(entry PUBLIC
    ${hilog-lib}
    ${napi-lib}
    ${egl-lib}
    ${gles-lib}
    ${window-lib})
