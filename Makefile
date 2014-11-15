GO_EASY_ON_ME = 1

ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = RedditScreens
RedditScreens_FILES = Tweak.xm
RedditScreens_FRAMEWORKS = UIKit CoreGraphics
RedditScreens_FRAMEWORKS = UIKit CoreGraphics
RedditScreens_PRIVATE_FRAMEWORKS = PersistentConnection PhotoLibrary SpringBoardFoundation
RedditScreens_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	#$(ECHO_NOTHING)ssh iphone killall -9 MobileCydia$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += redditscreens
include $(THEOS_MAKE_PATH)/aggregate.mk
