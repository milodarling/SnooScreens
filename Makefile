GO_EASY_ON_ME = 1

ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = SnooScreens
SnooScreens_FILES = Tweak.xm
SnooScreens_FRAMEWORKS = UIKit CoreGraphics
SnooScreens_PRIVATE_FRAMEWORKS = PersistentConnection PhotoLibrary SpringBoardFoundation
SnooScreens_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)ssh iphone killcydia$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += snooscreens
include $(THEOS_MAKE_PATH)/aggregate.mk
