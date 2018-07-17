GO_EASY_ON_ME = 1

THEOS_BUILD_DIR = Packages

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SnooScreens
SnooScreens_FILES = Tweak.xm
SnooScreens_FRAMEWORKS = UIKit CoreGraphics
SnooScreens_PRIVATE_FRAMEWORKS = PersistentConnection PhotoLibrary SpringBoardFoundation
SnooScreens_LDFLAGS = -lactivator

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	$(ECHO_NOTHING)find $(FW_STAGING_DIR) -iname '*.plist' -or -iname '*.strings' -exec plutil -convert binary1 {} \;$(ECHO_END)
	$(ECHO_NOTHING)find $(FW_STAGING_DIR) -iname '*.png' -exec pincrush-osx -i {} \;$(ECHO_END)
	$(ECHO_NOTHING)ssh iphone killall -9 MobileCydia || exit 0$(ECHO_END)

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += snooscreens
include $(THEOS_MAKE_PATH)/aggregate.mk
