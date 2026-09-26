.PHONY: all test release-test snapshot-test-ios snapshot-test-macos snapshot-tests snapshot-record example-builds

IOS_SNAPSHOT_DESTINATION ?= platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0
SNAPSHOT_TESTING_RECORD ?= never

ifeq ($(SNAPSHOT_TESTING_RECORD),all)
IOS_SNAPSHOT_RECORDING_FLAGS = OTHER_SWIFT_FLAGS='$$(inherited) -DSNAPSHOT_TESTING_RECORD_ALL'
endif

all: test release-test example-builds snapshot-tests

test:
	swift test -c debug --filter DesignSystemTests

release-test:
	swift test -c release --filter DesignSystemTests

snapshot-test-ios:
	SNAPSHOT_TESTING_RECORD="$(SNAPSHOT_TESTING_RECORD)" xcodebuild -quiet -collect-test-diagnostics never -parallel-testing-enabled NO -scheme swift-design-system-Package -destination '$(IOS_SNAPSHOT_DESTINATION)' -only-testing:DesignSystemSnapshotTests $(IOS_SNAPSHOT_RECORDING_FLAGS) test

snapshot-test-macos:
	SNAPSHOT_TESTING_RECORD="$(SNAPSHOT_TESTING_RECORD)" swift test -c debug --filter DesignSystemSnapshotTests

snapshot-tests:
	$(MAKE) snapshot-test-ios
	$(MAKE) snapshot-test-macos

snapshot-record:
	-$(MAKE) SNAPSHOT_TESTING_RECORD=all snapshot-test-ios
	-$(MAKE) SNAPSHOT_TESTING_RECORD=all snapshot-test-macos
	$(MAKE) -k SNAPSHOT_TESTING_RECORD=never snapshot-test-ios snapshot-test-macos

example-builds:
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme iOSExample -destination 'generic/platform=iOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme iOSExample -destination 'generic/platform=macOS,variant=Mac Catalyst' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme macOSExample -destination 'generic/platform=macOS' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme tvOSExample -destination 'generic/platform=tvOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme watchOSExample -destination 'generic/platform=watchOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme visionOSExample -destination 'generic/platform=visionOS Simulator' build
