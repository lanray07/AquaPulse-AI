import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserHydrationProfile.createdAt) private var profiles: [UserHydrationProfile]

    @State private var isPreparing = true
    @State private var preparationError: String?

    var body: some View {
        Group {
            if isPreparing {
                LoadingStateView(title: "Preparing AquaPulse AI")
            } else if let preparationError {
                ErrorStateView(message: preparationError) {
                    Task { await prepareApp() }
                }
            } else if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .task {
            await prepareApp()
        }
    }

    @MainActor
    private func prepareApp() async {
        isPreparing = true
        preparationError = nil

        do {
            if AppConstants.mockDataEnabled {
                try MockDataService.seedIfNeeded(in: modelContext)
            }
            isPreparing = false
        } catch {
            preparationError = error.localizedDescription
            isPreparing = false
        }
    }
}

struct MainTabView: View {
    let profile: UserHydrationProfile

    var body: some View {
        TabView {
            NavigationStack {
                HomeDashboardView(profile: profile)
            }
            .tabItem { Label("Today", systemImage: "drop.circle.fill") }

            NavigationStack {
                DrinkLogView(profile: profile)
            }
            .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                RemindersView(profile: profile)
            }
            .tabItem { Label("Reminders", systemImage: "bell.badge") }

            NavigationStack {
                HistoryInsightsView(profile: profile)
            }
            .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                AchievementsView()
            }
            .tabItem { Label("Badges", systemImage: "medal.fill") }

            NavigationStack {
                SettingsView(profile: profile)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

struct LoadingStateView: View {
    let title: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something needs attention", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
