TARGET := iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HideAVControls

HideAVControls_FILES = Tweak.x
HideAVControls_CFLAGS = -fobjc-arc
HideAVControls_FRAMEWORKS = UIKit Foundation

TOOL_NAME = RestoreAVControls

RestoreAVControls_FILES = RestoreAVControls.m
RestoreAVControls_CFLAGS = -fobjc-arc
RestoreAVControls_FRAMEWORKS = Foundation CoreFoundation
RestoreAVControls_INSTALL_PATH = /usr/bin

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk