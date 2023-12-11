export SDKVERSION = 13.7
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickSearch

QuickSearch_FILES = Tweak.xm QuickSearchWindow.m
QuickSearch_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += quicksearchprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
