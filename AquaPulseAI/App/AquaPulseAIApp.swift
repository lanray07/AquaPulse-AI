import SwiftData
import SwiftUI

@main
struct AquaPulseAIApp: App {
    @StateObject private var notificationService = NotificationService()
    @StateObject private var reminderService = ReminderService()
    @StateObject private var watchSyncService = WatchSyncService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var subscriptionManager = SubscriptionManager()

    private let modelContainer: ModelContainer = {
        let schema = Schema([
            UserHydrationProfile.self,
            DrinkEntry.self,
            ReminderSettings.self,
            Achievement.self,
            SubscriptionState.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .modelContainer(modelContainer)
                .environmentObject(notificationService)
                .environmentObject(reminderService)
                .environmentObject(watchSyncService)
                .environmentObject(healthKitService)
                .environmentObject(subscriptionManager)
                .task {
                    await notificationService.refreshAuthorizationStatus()
                    await subscriptionManager.loadProducts()
                }
        }
    }
}
