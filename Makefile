TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HidePrivacyModules

HidePrivacyModules_FILES = Tweak.x
HidePrivacyModules_CFLAGS = -fobjc-arc
HidePrivacyModules_FRAMEWORKS = UIKit

include $(THEOS)/makefiles/tweak.mk
