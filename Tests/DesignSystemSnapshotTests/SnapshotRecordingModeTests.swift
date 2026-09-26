import SnapshotTesting
import Testing

@Test
func snapshotRecordingDefaultsToNeverWithoutAnExplicitAllOverride() {
    #expect(SnapshotRecordingMode.resolve(nil) == .never)
    #expect(SnapshotRecordingMode.resolve("") == .never)
    #expect(SnapshotRecordingMode.resolve("unexpected") == .never)
    #expect(SnapshotRecordingMode.resolve("never") == .never)
}

@Test
func explicitAllOverrideSelectsTheRecordingPass() {
    #expect(SnapshotRecordingMode.resolve("all") == .all)
}
