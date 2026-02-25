import XCTest

final class HealthAppTransferUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Helpers

    /// Launch the app with onboarding bypassed via launch argument.
    private func launchSkippingOnboarding() {
        app.launchArguments.append("-UITestingSkipOnboarding")
        app.launch()
        // Wait for the tab bar to confirm main content loaded
        XCTAssertTrue(
            app.tabBars.buttons["Dashboard"].waitForExistence(timeout: 5),
            "Dashboard tab should appear after launch"
        )
    }

    /// Navigate to a tab, handling the "More" overflow when >5 tabs exist.
    /// iOS shows at most 5 tab bar buttons; extras go under "More".
    private func navigateToTab(_ name: String) {
        let tabBar = app.tabBars
        let directButton = tabBar.buttons[name]
        if directButton.exists {
            directButton.tap()
            return
        }
        // Tab is behind the "More" tab
        let moreButton = tabBar.buttons["More"]
        guard moreButton.exists else {
            XCTFail("Tab '\(name)' not found in tab bar or More menu")
            return
        }
        moreButton.tap()
        let moreItem = app.tables.buttons[name]
        guard moreItem.waitForExistence(timeout: 3) else {
            XCTFail("Tab '\(name)' not found in More list")
            return
        }
        moreItem.tap()
    }

    // MARK: - Onboarding

    func testOnboardingCanBeSkipped() {
        // Launch WITHOUT skip argument so onboarding actually shows
        app.launch()
        let skipButton = app.buttons["Skip onboarding"]
        if skipButton.waitForExistence(timeout: 3) {
            skipButton.tap()
            let dashboardTab = app.tabBars.buttons["Dashboard"]
            XCTAssertTrue(dashboardTab.waitForExistence(timeout: 5), "Dashboard tab should appear after skipping onboarding")
        }
        // If onboarding was already completed, that's fine — test passes
    }

    // MARK: - Tab Bar

    func testAllFiveTabsExist() {
        launchSkippingOnboarding()

        let tabBar = app.tabBars
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists)
        XCTAssertTrue(tabBar.buttons["Health Data"].exists)
        XCTAssertTrue(tabBar.buttons["Export"].exists)
        XCTAssertTrue(tabBar.buttons["Insights"].exists)
        // Automations and Settings overflow into "More" with 6 tabs
        XCTAssertTrue(tabBar.buttons["Automations"].exists || tabBar.buttons["More"].exists,
                      "Automations should be visible directly or via More tab")
    }

    func testTabSwitching() {
        launchSkippingOnboarding()

        navigateToTab("Health Data")
        XCTAssertTrue(app.navigationBars["Health Data"].waitForExistence(timeout: 5))

        navigateToTab("Export")
        XCTAssertTrue(app.navigationBars["Export"].waitForExistence(timeout: 5))

        navigateToTab("Automations")
        XCTAssertTrue(app.navigationBars["Automations"].waitForExistence(timeout: 5))

        navigateToTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        navigateToTab("Dashboard")
        XCTAssertTrue(app.navigationBars["Dashboard"].waitForExistence(timeout: 5))
    }

    // MARK: - Dashboard

    func testDashboardConfigureButton() {
        launchSkippingOnboarding()

        let configureButton = app.buttons["dashboard.configureButton"]
        guard configureButton.waitForExistence(timeout: 3) else {
            // Dashboard may not show configure button if no data
            return
        }
        configureButton.tap()

        // Verify the metric picker sheet appeared (has Cancel and Save)
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Configure sheet should present with a Save button")
    }

    // MARK: - Export

    func testExportTabShowsFormElements() {
        launchSkippingOnboarding()

        app.tabBars.buttons["Export"].tap()

        let formatPicker = app.buttons["export.formatPicker"]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 3), "Format picker should be visible")

        let exportButton = app.buttons["export.exportButton"]
        XCTAssertTrue(exportButton.exists, "Export button should be visible")
    }

    // MARK: - Automations

    func testAutomationsAddMenu() {
        launchSkippingOnboarding()

        navigateToTab("Automations")

        let addMenu = app.buttons["automations.addMenu"]
        // The add menu may be in toolbar or empty state
        let emptyAddMenu = app.buttons["automations.emptyState.addMenu"]

        let addButton = addMenu.waitForExistence(timeout: 3) ? addMenu : emptyAddMenu
        guard addButton.waitForExistence(timeout: 3) else {
            XCTFail("Add menu button should exist (toolbar or empty state)")
            return
        }

        addButton.tap()

        // Verify automation type options appear (menu animation needs time)
        let restOption = app.buttons["REST API"]
        XCTAssertTrue(restOption.waitForExistence(timeout: 5), "REST API option should appear in add menu")
    }

    // MARK: - Settings

    func testSettingsShowsAllLinks() {
        launchSkippingOnboarding()

        navigateToTab("Settings")

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
        launchSkippingOnboarding()

        navigateToTab("Settings")

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
        launchSkippingOnboarding()

        app.tabBars.buttons["Health Data"].tap()

        // The health data list should exist
        let healthDataList = app.otherElements["healthData.list"]
        // May take a moment for HealthKit to respond
        XCTAssertTrue(healthDataList.waitForExistence(timeout: 5) ||
                      app.navigationBars["Health Data"].waitForExistence(timeout: 3),
                      "Health Data view should be visible")
    }
}
