import Combine
import Foundation
import HealthKit
import StoreKit
import SwiftData
import UserNotifications
import WatchConnectivity

enum HydrationGoalService {
    static func estimateDailyGoal(weightKilograms: Double, activityLevel: ActivityLevel) -> Double {
        let base = weightKilograms * 35
        let adjusted = base * activityLevel.multiplier
        let roundedToNearestCup = (adjusted / 50).rounded() * 50
        return min(max(roundedToNearestCup, 1200), 5000)
    }

    static func adjustedGoal(currentGoal: Double, manualOverride: Double?) -> Double {
        guard let manualOverride, manualOverride > 0 else { return currentGoal }
        return manualOverride
    }
}

@MainActor
final class NotificationService: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var lastErrorMessage: String?

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func scheduleHydrationReminders(settings: ReminderSettings, profile: UserHydrationProfile) async throws {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let hydrationIdentifiers = pending.map(\.identifier).filter { $0.hasPrefix("hydration.reminder") }
        center.removePendingNotificationRequests(withIdentifiers: hydrationIdentifiers)

        var requests: [UNNotificationRequest] = []
        var nextDate = nextReminderStartDate(profile: profile)
        let sleepMinute = Calendar.current.minuteOfDay(for: profile.sleepTime)
        var count = 0

        while count < 20 {
            let nextMinute = Calendar.current.minuteOfDay(for: nextDate)
            if nextMinute > sleepMinute && sleepMinute > Calendar.current.minuteOfDay(for: profile.wakeTime) {
                break
            }

            if !settings.isInsideQuietHours(nextDate) {
                let content = UNMutableNotificationContent()
                content.title = "AquaPulse AI"
                content.body = settings.reminderTone.notificationBody
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                requests.append(UNNotificationRequest(identifier: "hydration.reminder.\(count)", content: content, trigger: trigger))
                count += 1
            }

            nextDate = Calendar.current.date(byAdding: .minute, value: settings.frequency, to: nextDate) ?? nextDate.addingTimeInterval(Double(settings.frequency * 60))
        }

        for request in requests {
            try await center.add(request)
        }
    }

    private func nextReminderStartDate(profile: UserHydrationProfile) -> Date {
        let calendar = Calendar.current
        let nowMinute = calendar.minuteOfDay(for: .now)
        let wakeMinute = calendar.minuteOfDay(for: profile.wakeTime)

        if nowMinute <= wakeMinute {
            var components = calendar.dateComponents([.year, .month, .day], from: .now)
            components.hour = wakeMinute / 60
            components.minute = wakeMinute % 60
            return calendar.date(from: components) ?? .now
        }

        return calendar.date(byAdding: .minute, value: 30, to: .now) ?? .now
    }
}

@MainActor
final class ReminderService: ObservableObject {
    @Published var isScheduling = false
    @Published var lastScheduledAt: Date?
    @Published var errorMessage: String?

    func apply(settings: ReminderSettings, profile: UserHydrationProfile, notificationService: NotificationService) async {
        isScheduling = true
        defer { isScheduling = false }

        await notificationService.requestAuthorization()

        do {
            try await notificationService.scheduleHydrationReminders(settings: settings, profile: profile)
            lastScheduledAt = .now
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class HealthKitService: ObservableObject {
    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var isAuthorized = false
    @Published var statusMessage = "Apple Health (HealthKit) water intake sync is not connected."

    private let healthStore = HKHealthStore()

    func requestAuthorization() async {
        isAvailable = HKHealthStore.isHealthDataAvailable()
        guard HKHealthStore.isHealthDataAvailable(),
              let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            statusMessage = "Apple Health water intake sync is not available on this device. Local hydration tracking still works normally."
            return
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.requestAuthorization(toShare: [waterType], read: [waterType]) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: CocoaError(.userCancelled))
                    }
                }
            }
            isAuthorized = true
            statusMessage = "Apple Health (HealthKit) is connected for water intake read and write access."
        } catch {
            isAuthorized = false
            statusMessage = Self.friendlyAuthorizationMessage(for: error)
        }
    }

    private static func friendlyAuthorizationMessage(for error: Error) -> String {
        let description = error.localizedDescription
        let lowercasedDescription = description.lowercased()

        if lowercasedDescription.contains("entitlement") {
            return "Apple Health water intake sync is unavailable in this build. You can continue tracking hydration locally."
        }

        if lowercasedDescription.contains("cancel") || lowercasedDescription.contains("denied") {
            return "Apple Health permission was not granted. You can keep tracking locally or enable access later in Settings."
        }

        return "Apple Health could not be connected right now. Local hydration tracking still works normally."
    }
}

final class WatchSyncService: NSObject, ObservableObject {
    @Published var isSupported = WCSession.isSupported()
    @Published var isReachable = false
    @Published var lastSyncStatus = "Mock watch sync ready"

    override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendHydrationSnapshot(intake: Double, goal: Double) {
        let payload: [String: Any] = [
            "todayIntake": intake,
            "dailyGoal": goal,
            "updatedAt": Date().timeIntervalSince1970
        ]

        if WCSession.isSupported(), WCSession.default.activationState == .activated {
            WCSession.default.transferUserInfo(payload)
        }

        DispatchQueue.main.async {
            self.lastSyncStatus = "Synced \(Int(intake)) ml to watch placeholder"
        }
    }
}

extension WatchSyncService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.lastSyncStatus = error?.localizedDescription ?? "Watch session active"
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentState = SubscriptionState(plan: .free, isActive: false)

    private let productIDs = [
        AppConstants.monthlyProductID,
        AppConstants.yearlyProductID,
        AppConstants.lifetimeProductID
    ]

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            errorMessage = nil
        } catch {
            errorMessage = "StoreKit products are unavailable. Check the App Store sandbox connection and product configuration."
        }
    }

    func purchase(plan: SubscriptionPlan) async {
        guard plan != .free else {
            currentState = SubscriptionState(plan: .free, isActive: false)
            return
        }

        if AppConstants.mockPurchasesEnabled {
            currentState = SubscriptionState(plan: plan, isActive: true, renewsAt: plan == .lifetime ? nil : Calendar.current.date(byAdding: .month, value: 1, to: .now))
            return
        }

        guard let productID = plan.productID,
              let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "Product is not available yet."
            return
        }

        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                currentState = SubscriptionState(plan: plan, isActive: true)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum MockDataService {
    @MainActor
    static func seedIfNeeded(in context: ModelContext) throws {
        let existingProfiles = try context.fetch(FetchDescriptor<UserHydrationProfile>())
        guard existingProfiles.isEmpty else { return }

        let profile = UserHydrationProfile(
            name: "Alex",
            ageRange: .age30To44,
            weight: 74,
            activityLevel: .moderate,
            climatePreference: .weatherBased,
            wakeTime: .timeToday(hour: 7, minute: 0),
            sleepTime: .timeToday(hour: 22, minute: 30),
            dailyGoal: HydrationGoalService.estimateDailyGoal(weightKilograms: 74, activityLevel: .moderate),
            preferredUnit: .milliliters,
            preferredCupSize: 250
        )

        context.insert(profile)
        context.insert(ReminderSettings())
        context.insert(SubscriptionState(plan: .free, isActive: false))

        for achievement in defaultAchievements() {
            context.insert(achievement)
        }

        let calendar = Calendar.current
        for dayOffset in (-29...0) {
            let dayGoal = profile.dailyGoal
            let completion = Double.random(in: 0.55...1.15)
            let total = min(dayGoal * completion, dayGoal + 700)
            let drinkCount = max(Int(total / 350), 1)
            for index in 0..<drinkCount {
            let baseDate = calendar.startOfDay(offsetByDays: dayOffset)
                let date = calendar.date(byAdding: .minute, value: 8 * 60 + index * 95, to: baseDate) ?? baseDate
                context.insert(DrinkEntry(amount: total / Double(drinkCount), drinkType: index % 5 == 0 ? .tea : .water, date: date))
            }
        }

        try context.save()
    }

    static func defaultAchievements() -> [Achievement] {
        [
            Achievement(title: "First Glass", description: "Log your first drink.", unlocked: true, unlockedAt: Calendar.current.date(byAdding: .day, value: -12, to: .now)),
            Achievement(title: "3-Day Streak", description: "Hit your goal three days in a row.", unlocked: true, unlockedAt: Calendar.current.date(byAdding: .day, value: -8, to: .now)),
            Achievement(title: "7-Day Streak", description: "Complete a full week of hydration goals."),
            Achievement(title: "Hydration Hero", description: "Log 50 drinks."),
            Achievement(title: "Perfect Week", description: "Reach your goal every day for seven days."),
            Achievement(title: "Early Starter", description: "Log water before 9 AM."),
            Achievement(title: "Goal Crusher", description: "Reach 125% of your daily goal.")
        ]
    }
}
