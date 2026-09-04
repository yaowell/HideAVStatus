TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HideAVControls

HideAVControls_FILES = Tweak.x
HideAVControls_CFLAGS = -fobjc-arc
HideAVControls_FRAMEWORKS = UIKit

include $(THEOS)/makefiles/tweak.mk
