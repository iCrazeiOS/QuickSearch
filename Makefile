export PREFIX = $(THEOS)/toolchain/Xcode11.xctoolchain/usr/bin/
export SDKVERSION = 14.4
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = QuickSearch

QuickSearch_FILES = Tweak.xm
QuickSearch_CFLAGS = -fobjc-arc
QuickSearch_LDFLAGS = -lactivator
QuickSearch_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += quicksearchprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
