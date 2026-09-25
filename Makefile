.PHONY: all test release-test example-builds

all: test release-test example-builds

test:
	swift test -c debug

release-test:
	swift test -c release

example-builds:
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme iOSExample -destination 'generic/platform=iOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme iOSExample -destination 'generic/platform=macOS,variant=Mac Catalyst' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme macOSExample -destination 'generic/platform=macOS' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme tvOSExample -destination 'generic/platform=tvOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme watchOSExample -destination 'generic/platform=watchOS Simulator' build
	xcodebuild -quiet -project Examples/DesignSystemExamples.xcodeproj -scheme visionOSExample -destination 'generic/platform=visionOS Simulator' build
