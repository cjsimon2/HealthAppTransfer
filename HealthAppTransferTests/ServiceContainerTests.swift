import XCTest
@testable import HealthAppTransfer

final class ServiceContainerTests: XCTestCase {

    // MARK: - Default Init

    func testDefaultInitCreatesAllServices() {
        let container = ServiceContainer()

        XCTAssertNotNil(container.keychain)
        XCTAssertNotNil(container.certificateService)
        XCTAssertNotNil(container.pairingService)
        XCTAssertNotNil(container.auditService)
        XCTAssertNotNil(container.healthKitService)
        XCTAssertNotNil(container.biometricService)
        XCTAssertNotNil(container.networkServer)
    }

    // MARK: - ViewModel Factories

    @MainActor
    func testMakePairingViewModelReturnsValidInstance() {
        let container = ServiceContainer()
        let viewModel = container.makePairingViewModel()
        XCTAssertNotNil(viewModel)
    }

    @MainActor
    func testMakeLANSyncViewModelReturnsValidInstance() {
        let container = ServiceContainer()
        let viewModel = container.makeLANSyncViewModel()
        XCTAssertNotNil(viewModel)
    }

    @MainActor
    func testMakeSecuritySettingsViewModelReturnsValidInstance() {
        let container = ServiceContainer()
        let viewModel = container.makeSecuritySettingsViewModel()
        XCTAssertNotNil(viewModel)
    }
}
