# CJGUI 鸿蒙消费方核心选择：标准构建入口（scripts/build_and_run.sh 及
# runtime/cjgui/platforms/ohos/scripts/build_and_run.sh）读取本文件。
#   main     = 冻结主树共同核心（main_core/MANIFEST.sha256）+ host_main 适配宿主
#   snapshot = 旧分叉快照（仅用于旧回退）
# 其他 lab 没有该文件时入口仍默认 snapshot，旧消费与回退 HAP 不受影响。
core_profile=main
