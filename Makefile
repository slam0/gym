# Siłka - dziennik treningowy na iOS 6 (jailbreak), budowany w Theosie.
#
# SDKVER: wersja SDK iOS, z którą kompilujemy. Skrypt build.sh sam wybiera
# najstarsze dostępne. Ręcznie: make package SDKVER=9.3
SDKVER ?= 6.1

# armv7 działa na iPhone 3GS/4/4S/5 i iPod touch 4/5 (iOS 6.x)
export ARCHS = armv7
export TARGET = iphone:clang:$(SDKVER):6.0

# stary dpkg z iOS 6 nie czyta nowszej kompresji niż gzip
export THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

INSTALL_TARGET_PROCESSES = Silka

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Silka

Silka_FILES = main.m AppDelegate.m SLStore.m SLTheme.m SLViews.m SLWorkoutController.m SLPickerController.m SLHistoryController.m SLExercisesController.m SLSettingsController.m sl_core.c sl_libc.c
Silka_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore AudioToolbox
Silka_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-command-line-argument

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "uicache"
