TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HideAVControls

HideAVControls_FILES = Tweak.x
HideAVControls_CFLAGS = -fobjc-arc

include $(THEOS_MAKEFILE_PATH)/tweak.mk
