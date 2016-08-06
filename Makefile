ARCHS = armv7 armv7s arm64
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PastelSizeChanger
PastelSizeChanger_FILES = Tweak.xm
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)
include $(THEOS_MAKE_PATH)/tweak.mk


SUBPROJECTS += pastelsizeprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
