TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HideAVControls

HideAVControls_FILES = Tweak.x
HideAVControls_CFLAGS = -fobjc-arc
HideAVControls_FRAMEWORKS = UIKit Foundation

TOOL_NAME = HideAVControlsRestore

HideAVControlsRestore_FILES = RestoreAVControls.m
HideAVControlsRestore_CFLAGS = -fobjc-arc
HideAVControlsRestore_FRAMEWORKS = Foundation

HideAVControlsRestore_INSTALL_PATH = /usr/bin

include $(THEOS)/makefiles/tweak.mk
include $(THEOS)/makefiles/tool.mk