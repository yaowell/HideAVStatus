TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

# 确保引入 Theos 环境
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HideAVControls

HideAVControls_FILES = Tweak.x
HideAVControls_CFLAGS = -fobjc-arc

# 关键修正：使用 $(THEOS)/makefiles/tweak.mk
include $(THEOS)/makefiles/tweak.mk
