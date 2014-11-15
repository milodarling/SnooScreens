GO_EASY_ON_ME = 1
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest

include theos/makefiles/common.mk

BUNDLE_NAME = RedditScreens
RedditScreens_FILES = RedditScreens.mm
RedditScreens_INSTALL_PATH = /Library/PreferenceBundles
RedditScreens_FRAMEWORKS = UIKit Twitter
RedditScreens_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/RedditScreens.plist$(ECHO_END)
