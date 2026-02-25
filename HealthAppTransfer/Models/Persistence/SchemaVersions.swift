import Foundation
import SwiftData

// MARK: - Schema Versions

/// Schema versioning for SwiftData migrations.
/// Add new VersionedSchema conformances here when the model changes.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SyncConfiguration.self,
            PairedDevice.self,
            AuditEventRecord.self,
            ExportRecord.self,
            AutomationConfiguration.self,
            UserPreferences.self,
            SyncedHealthSample.self,
        ]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
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
}

// MARK: - Migration Plan

enum HealthAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}

// MARK: - Model Container Factory

enum PersistenceConfiguration {

    /// All SwiftData model types used by the app.
    static var allModelTypes: [any PersistentModel.Type] {
        SchemaV2.models
    }

    /// Creates the shared ModelContainer for the app.
    /// Uses the migration plan so future schema changes are handled automatically.
    /// Pass `deleteExisting: true` to wipe and recreate the store on corruption.
    static func makeModelContainer(deleteExisting: Bool = false) throws -> ModelContainer {
        let schema = Schema(allModelTypes)

        if deleteExisting {
            let base = URL.applicationSupportDirectory.appending(path: "default.store")
            for suffix in ["", "-shm", "-wal"] {
                try? FileManager.default.removeItem(at: URL(filePath: base.path() + suffix))
            }
        }

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: HealthAppMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
