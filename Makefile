XCODEBUILD=xcodebuild
OPTIONS=\
    -project Async.xcodeproj\
    -scheme Async\
    -destination "name=iPhone 7"
SHOW_BUILD_SETTINGS=$(XCODEBUILD) $(OPTIONS) -showBuildSettings
BUILD=$(XCODEBUILD) $(OPTIONS) build
CLEAN=$(XCODEBUILD) $(OPTIONS) clean

.PHONY: settings build clean

settings:
	$(SHOW_BUILD_SETTINGS)

build: clean
	$(BUILD)

clean:
	$(CLEAN)
