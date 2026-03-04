import Foundation
import SwiftData

// MARK: - Model Container Factory

enum PersistenceConfiguration {

    /// All SwiftData model types used by the app.
    static var allModelTypes: [any PersistentModel.Type] {
        [
            SyncConfiguration.self,
            PairedDevice.self,
            AuditEventRecord.self,
            ExportRecord.self,
            AutomationConfiguration.self,
            UserPreferences.self,
            SyncedHealthSample.self,
            CorrelationRecord.self,
        ]
    }

    /// Store file URLs to delete on recovery. Checked in both group container and default location.
    private static var storeURLCandidates: [URL] {
        [
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.caseysimon.HealthAppTransfer")?
                .appending(path: "Library/Application Support/default.store"),
            URL.applicationSupportDirectory.appending(path: "default.store"),
        ].compactMap { $0 }
    }

    /// Deletes the persistent store files (main + WAL/SHM) from all candidate locations.
    static func deleteStoreFiles() {
        for base in storeURLCandidates {
            for suffix in ["", "-shm", "-wal"] {
                let url = URL(filePath: base.path() + suffix)
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// Creates the shared ModelContainer for the app.
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Creates a fresh in-memory ModelContainer as a last-resort fallback.
    /// Data won't persist across launches, but the app won't crash-loop.
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
