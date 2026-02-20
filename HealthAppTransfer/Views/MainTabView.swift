import Foundation
import SwiftUI

// MARK: - Main Tab View

/// Root navigation shell. iOS uses TabView; macOS uses NavigationSplitView with sidebar.
struct MainTabView: View {

    // MARK: - State

    @State private var selectedTab: AppTab = .dashboard

    // MARK: - Dependencies

    @ObservedObject var pairingViewModel: PairingViewModel
    @ObservedObject var lanSyncViewModel: LANSyncViewModel
    let healthKitService: HealthKitService
    @ObservedObject var securitySettingsViewModel: SecuritySettingsViewModel

    // MARK: - Body

    var body: some View {
        #if os(iOS)
        iOSTabView
        #else
        macOSSplitView
        #endif
    }

    // MARK: - iOS Tab View

    #if os(iOS)
    private var iOSTabView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(healthKitService: healthKitService)
            }
            .tabItem {
                Label("Dashboard", systemImage: "heart.text.square")
            }
            .tag(AppTab.dashboard)

            NavigationStack {
                HealthDataView(healthKitService: healthKitService)
            }
            .tabItem {
                Label("Health Data", systemImage: "list.bullet.clipboard")
            }
            .tag(AppTab.healthData)

            NavigationStack {
                AutomationsView()
            }
            .tabItem {
                Label("Automations", systemImage: "bolt.horizontal")
            }
            .tag(AppTab.automations)

            NavigationStack {
                SettingsView(pairingViewModel: pairingViewModel, lanSyncViewModel: lanSyncViewModel, securitySettingsViewModel: securitySettingsViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(AppTab.settings)
        }
    }
    #endif

    // MARK: - macOS Split View

    #if os(macOS)
    private var macOSSplitView: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $selectedTab) { tab in
                Label(tab.title, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("HealthAppTransfer")
        } detail: {
            switch selectedTab {
            case .dashboard:
                DashboardView(healthKitService: healthKitService)
            case .healthData:
                HealthDataView(healthKitService: healthKitService)
            case .automations:
                AutomationsView()
            case .settings:
                SettingsView(pairingViewModel: pairingViewModel, lanSyncViewModel: lanSyncViewModel, securitySettingsViewModel: securitySettingsViewModel)
            }
        }
    }
    #endif
}

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case healthData
    case automations
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: String(localized: "tab.dashboard", defaultValue: "Dashboard")
        case .healthData: String(localized: "tab.healthData", defaultValue: "Health Data")
        case .automations: String(localized: "tab.automations", defaultValue: "Automations")
        case .settings: String(localized: "tab.settings", defaultValue: "Settings")
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "heart.text.square"
        case .healthData: "list.bullet.clipboard"
        case .automations: "bolt.horizontal"
        case .settings: "gear"
        }
    }
}
