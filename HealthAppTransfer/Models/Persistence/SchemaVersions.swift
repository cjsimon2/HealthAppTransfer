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

// MARK: - Migration Plan

enum HealthAppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        // No migrations yet — add lightweight or custom stages here as schema evolves.
        []
    }
}

// MARK: - Model Container Factory

enum PersistenceConfiguration {

    /// All SwiftData model types used by the app.
    static var allModelTypes: [any PersistentModel.Type] {
        SchemaV1.models
    }

    /// Creates the shared ModelContainer for the app.
    /// Uses the migration plan so future schema changes are handled automatically.
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema(allModelTypes)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: HealthAppMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
