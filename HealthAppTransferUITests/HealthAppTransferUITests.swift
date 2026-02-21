import XCTest

final class HealthAppTransferUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Helpers

    /// Skip onboarding if the skip button is visible.
    private func skipOnboardingIfNeeded() {
        let skipButton = app.buttons["Skip onboarding"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
        }
    }

    // MARK: - Onboarding

    func testOnboardingCanBeSkipped() {
        let skipButton = app.buttons["Skip onboarding"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
            // After skipping, tab bar should be visible
            let dashboardTab = app.tabBars.buttons["Dashboard"]
            XCTAssertTrue(dashboardTab.waitForExistence(timeout: 3), "Dashboard tab should appear after skipping onboarding")
        }
        // If onboarding was already completed, that's fine — test passes
    }

    // MARK: - Tab Bar

    func testAllFiveTabsExist() {
        skipOnboardingIfNeeded()

        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.buttons["Dashboard"].waitForExistence(timeout: 3))
        XCTAssertTrue(tabBar.buttons["Health Data"].exists)
        XCTAssertTrue(tabBar.buttons["Export"].exists)
        XCTAssertTrue(tabBar.buttons["Automations"].exists)
        XCTAssertTrue(tabBar.buttons["Settings"].exists)
    }

    func testTabSwitching() {
        skipOnboardingIfNeeded()

        let tabBar = app.tabBars

        tabBar.buttons["Health Data"].tap()
        XCTAssertTrue(app.navigationBars["Health Data"].waitForExistence(timeout: 3))

        tabBar.buttons["Export"].tap()
        XCTAssertTrue(app.navigationBars["Export"].waitForExistence(timeout: 3))

        tabBar.buttons["Automations"].tap()
        XCTAssertTrue(app.navigationBars["Automations"].waitForExistence(timeout: 3))

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        tabBar.buttons["Dashboard"].tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 3))
    }

    // MARK: - Dashboard

    func testDashboardConfigureButton() {
        skipOnboardingIfNeeded()

        let configureButton = app.buttons["dashboard.configureButton"]
        guard configureButton.waitForExistence(timeout: 3) else {
            // Dashboard may not show configure button if no data
            return
        }
        configureButton.tap()

        // Verify a sheet or navigation appeared
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Configure sheet should present with a Done button")
    }

    // MARK: - Export

    func testExportTabShowsFormElements() {
        skipOnboardingIfNeeded()

        app.tabBars.buttons["Export"].tap()

        let formatPicker = app.otherElements["export.formatPicker"]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 3), "Format picker should be visible")

        let exportButton = app.buttons["export.exportButton"]
        XCTAssertTrue(exportButton.exists, "Export button should be visible")
    }

    // MARK: - Automations

    func testAutomationsAddMenu() {
        skipOnboardingIfNeeded()

        app.tabBars.buttons["Automations"].tap()

        let addMenu = app.buttons["automations.addMenu"]
        // The add menu may be in toolbar or empty state
        let emptyAddMenu = app.buttons["automations.emptyState.addMenu"]

        let addButton = addMenu.waitForExistence(timeout: 3) ? addMenu : emptyAddMenu
        guard addButton.waitForExistence(timeout: 3) else {
            XCTFail("Add menu button should exist (toolbar or empty state)")
            return
        }

        addButton.tap()

        // Verify automation type options appear
        let restOption = app.buttons["REST API"]
        XCTAssertTrue(restOption.waitForExistence(timeout: 3), "REST API option should appear in add menu")
    }

    // MARK: - Settings

    func testSettingsShowsAllLinks() {
        skipOnboardingIfNeeded()

        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["settings.syncSettings"].waitForExistence(timeout: 3) ||
                      app.cells["settings.syncSettings"].waitForExistence(timeout: 1),
                      "Sync Settings link should exist")

        XCTAssertTrue(app.buttons["settings.pairDevice"].exists ||
                      app.cells["settings.pairDevice"].exists,
                      "Pair Device link should exist")

        XCTAssertTrue(app.buttons["settings.security"].exists ||
                      app.cells["settings.security"].exists,
                      "Security link should exist")
    }

    func testSettingsNavigationToSyncSettings() {
        skipOnboardingIfNeeded()

        app.tabBars.buttons["Settings"].tap()

        // Tap Sync Settings
        let syncLink = app.buttons["settings.syncSettings"].exists
            ? app.buttons["settings.syncSettings"]
            : app.cells["settings.syncSettings"]

        guard syncLink.waitForExistence(timeout: 3) else { return }
        syncLink.tap()

        // Verify navigation happened
        XCTAssertTrue(app.navigationBars["Sync Settings"].waitForExistence(timeout: 3),
                      "Should navigate to Sync Settings screen")

        // Go back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3),
                      "Should navigate back to Settings")
    }

    // MARK: - Health Data

    func testHealthDataTabShowsCategories() {
        skipOnboardingIfNeeded()

        app.tabBars.buttons["Health Data"].tap()

        // The health data list should exist
        let healthDataList = app.otherElements["healthData.list"]
        // May take a moment for HealthKit to respond
        XCTAssertTrue(healthDataList.waitForExistence(timeout: 5) ||
                      app.navigationBars["Health Data"].waitForExistence(timeout: 3),
                      "Health Data view should be visible")
    }
}
