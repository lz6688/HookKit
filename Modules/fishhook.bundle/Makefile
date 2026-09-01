ifneq ($(filter $(THEOS_PACKAGE_SCHEME),rootless roothide),)
ARCHS ?= arm64 arm64e
TARGET ?= iphone:clang:16.4:15.0
else
ARCHS ?= armv7 arm64 arm64e
TARGET ?= iphone:clang:14.5:8.0
endif

# vendor 子项目不参与混淆,并改用 Xcode clang(用户要求 + 崩溃修复):
# 顶层 export 的 llvm@21 编译器会给 arm64e __objc_data 的 data 指针加 ptrauth 编码
# (Xcode clang 不加),iOS 14 dyld 解码失败 → map_images readClass SIGSEGV
# (实测 /sbin/hidejb 启动崩,RootBridge __DATA+0x48);llvm@21+插件在本项目只用于
# 主项目的混淆,vendor 恒用系统工具链
TARGET_CC := $(shell xcrun -f clang)
TARGET_CXX := $(shell xcrun -f clang++)
TARGET_LD := $(shell xcrun -f clang)
ADDITIONAL_CFLAGS := $(filter-out -fpass-plugin=% -resource-dir %,$(ADDITIONAL_CFLAGS))
ADDITIONAL_CFLAGS := $(filter-out -mllvm -regalloc=basic -fno-ptrauth-objc-class-ro,$(ADDITIONAL_CFLAGS))
export COCOONS_ENABLE_STR := 0
export COCOONS_ENABLE_SUB := 0
export COCOONS_ENABLE_FLA := 0
export COCOONS_ENABLE_BCF := 0
export COCOONS_ENABLE_SPLIT := 0
export COCOONS_ENABLE_IBR := 0
export COCOONS_ENABLE_FW := 0
export COCOONS_ENABLE_ACD := 0
export COCOONS_ENABLE_FCO := 0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = HookKitFishhookModule
HookKitFishhookModule_BUNDLE_EXTENSION = bundle
HookKitFishhookModule_FILES = Module.m HKFH.m vendor/fishhook/fishhook.c
HookKitFishhookModule_EXTRA_FRAMEWORKS = HookKit
HookKitFishhookModule_CFLAGS = -fobjc-arc -Ivendor/HookKit.framework/Headers
HookKitFishhookModule_LDFLAGS = -rpath /Library/Frameworks -rpath /var/jb/Library/Frameworks -rpath /usr/lib -rpath /var/jb/usr/lib
HookKitFishhookModule_LDFLAGS += -Fvendor
HookKitFishhookModule_INSTALL_PATH = /Library/Modulous/HookKit

include $(THEOS_MAKE_PATH)/bundle.mk
