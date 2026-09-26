import Foundation
import SnapshotTesting

enum SnapshotRecordingMode {
    static let environmentKey = "SNAPSHOT_TESTING_RECORD"

    static var current: SnapshotTestingConfiguration.Record {
#if SNAPSHOT_TESTING_RECORD_ALL
        .all
#else
        resolve(ProcessInfo.processInfo.environment[environmentKey])
#endif
    }

    static func resolve(_ override: String?) -> SnapshotTestingConfiguration.Record {
        override == "all" ? .all : .never
    }
}
