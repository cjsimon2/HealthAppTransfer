import XCTest
import SwiftData
@testable import HealthAppTransfer

@MainActor
final class AutomationConfigurationTests: XCTestCase {

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(
            for: AutomationConfiguration.self,
            configurations: config
        )
    }

    private func makeConfig(
        name: String = "Test",
        automationType: String = "rest_api",
        endpoint: String? = "https://example.com",
        exportFormat: String = "json_v2"
    ) -> AutomationConfiguration {
        AutomationConfiguration(
            name: name,
            automationType: automationType,
            endpoint: endpoint,
            exportFormat: exportFormat
        )
    }

    // MARK: - Init Defaults

    func testInitSetsDefaults() throws {
        let config = makeConfig()
        XCTAssertEqual(config.name, "Test")
        XCTAssertEqual(config.automationType, "rest_api")
        XCTAssertEqual(config.endpoint, "https://example.com")
        XCTAssertEqual(config.exportFormat, "json_v2")
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.consecutiveFailures, 0)
        XCTAssertTrue(config.incrementalOnly)
        XCTAssertEqual(config.triggerIntervalSeconds, 0)
        XCTAssertEqual(config.mqttQoS, 0)
        XCTAssertFalse(config.mqttUseTLS)
        XCTAssertNil(config.lastTriggeredAt)
    }

    // MARK: - HTTP Headers Roundtrip

    func testHttpHeadersGetterSetterRoundtrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let config = makeConfig()
        context.insert(config)

        let headers = ["Authorization": "Bearer token123", "X-Custom": "value"]
        config.httpHeaders = headers

        XCTAssertEqual(config.httpHeaders["Authorization"], "Bearer token123")
        XCTAssertEqual(config.httpHeaders["X-Custom"], "value")
        XCTAssertNotNil(config.httpHeadersJSON)
    }

    // MARK: - HTTP Headers Empty Dict Clears JSON

    func testHttpHeadersWithEmptyDictClearsJSON() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let config = makeConfig()
        context.insert(config)

        config.httpHeaders = ["Key": "Value"]
        XCTAssertNotNil(config.httpHeadersJSON)

        config.httpHeaders = [:]
        XCTAssertNil(config.httpHeadersJSON)
    }

    // MARK: - HTTP Headers With Nil JSON Returns Empty Dict

    func testHttpHeadersWithNilJSONReturnsEmptyDict() throws {
        let config = makeConfig()
        config.httpHeadersJSON = nil
        XCTAssertEqual(config.httpHeaders, [:])
    }
}
