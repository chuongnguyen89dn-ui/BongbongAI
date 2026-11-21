ARCHS = arm64
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = rootless
include $(THEOS)/makefiles/common.mk
SUBPROJECTS = overlay settings
include $(THEOS_MAKE_PATH)/aggregate.mk
