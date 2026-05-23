import Combine
import Foundation
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var name = ""
    @Published var ageRange: AgeRange = .age30To44
    @Published var weight = 72.0
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var climatePreference: ClimatePreference = .weatherBased
    @Published var wakeTime: Date = .timeToday(hour: 7, minute: 0)
    @Published var sleepTime: Date = .timeToday(hour: 22, minute: 30)
    @Published var preferredCupSize = 250.0
    @Published var preferredUnit: PreferredUnit = .milliliters
    @Published var isSaving = false
    @Published var errorMessage: String?

    var estimatedDailyGoal: Double {
        HydrationGoalService.estimateDailyGoal(weightKilograms: weight, activityLevel: activityLevel)
    }

    func save(in context: ModelContext) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Add your name to continue."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let profile = UserHydrationProfile(
            name: name,
            ageRange: ageRange,
            weight: weight,
            activityLevel: activityLevel,
            climatePreference: climatePreference,
            wakeTime: wakeTime,
            sleepTime: sleepTime,
            dailyGoal: estimatedDailyGoal,
            preferredUnit: preferredUnit,
            preferredCupSize: preferredCupSize
        )

        context.insert(profile)
        context.insert(ReminderSettings())
        context.insert(SubscriptionState(plan: .free, isActive: false))

        for achievement in MockDataService.defaultAchievements() {
            context.insert(achievement)
        }

        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published var selectedDrinkType: DrinkType = .water
    @Published var customAmountText = ""
    @Published var isShowingCustomAmount = false
    @Published var errorMessage: String?

    func todayTotal(entries: [DrinkEntry]) -> Double {
        entries
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    func addDrink(amount: Double, drinkType: DrinkType, context: ModelContext) -> DrinkEntry? {
        guard amount > 0 else {
            errorMessage = "Enter an amount above zero."
            return nil
        }

        let entry = DrinkEntry(amount: amount, drinkType: drinkType)
        context.insert(entry)

        do {
            try context.save()
            return entry
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func unlockAchievementsIfNeeded(achievements: [Achievement], entries: [DrinkEntry], dailyGoal: Double) {
        let todayTotal = todayTotal(entries: entries)
        let totalDrinkCount = entries.count
        let currentStreak = HistoryInsightsViewModel.currentStreak(entries: entries, dailyGoal: dailyGoal)
        let earlyStart = entries.contains { entry in
            Calendar.current.isDateInToday(entry.date) && Calendar.current.component(.hour, from: entry.date) < 9
        }

        unlock("First Glass", achievements: achievements, when: totalDrinkCount > 0)
        unlock("3-Day Streak", achievements: achievements, when: currentStreak >= 3)
        unlock("7-Day Streak", achievements: achievements, when: currentStreak >= 7)
        unlock("Hydration Hero", achievements: achievements, when: totalDrinkCount >= 50)
        unlock("Perfect Week", achievements: achievements, when: currentStreak >= 7)
        unlock("Early Starter", achievements: achievements, when: earlyStart)
        unlock("Goal Crusher", achievements: achievements, when: todayTotal >= dailyGoal * 1.25)
    }

    private func unlock(_ title: String, achievements: [Achievement], when condition: Bool) {
        guard condition, let achievement = achievements.first(where: { $0.title == title }), !achievement.unlocked else { return }
        achievement.unlocked = true
        achievement.unlockedAt = .now
    }
}

@MainActor
final class ReminderSettingsViewModel: ObservableObject {
    @Published var statusMessage: String?

    func schedule(settings: ReminderSettings, profile: UserHydrationProfile, reminderService: ReminderService, notificationService: NotificationService) async {
        await reminderService.apply(settings: settings, profile: profile, notificationService: notificationService)
        statusMessage = reminderService.errorMessage ?? "Reminders updated"
    }
}

final class HistoryInsightsViewModel: ObservableObject {
    func dailySummaries(entries: [DrinkEntry], goal: Double, days: Int) -> [HydrationDay] {
        let calendar = Calendar.current
        return (0..<days).reversed().map { offset in
            let day = calendar.startOfDay(offsetByDays: -offset)
            let total = entries
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }
            return HydrationDay(date: day, total: total, goal: goal)
        }
    }

    func averageDailyIntake(entries: [DrinkEntry], goal: Double, days: Int) -> Double {
        let summaries = dailySummaries(entries: entries, goal: goal, days: days)
        guard !summaries.isEmpty else { return 0 }
        return summaries.reduce(0) { $0 + $1.total } / Double(summaries.count)
    }

    func missedDays(entries: [DrinkEntry], goal: Double, days: Int) -> Int {
        dailySummaries(entries: entries, goal: goal, days: days).filter { $0.total == 0 }.count
    }

    func goalCompletionPercentage(entries: [DrinkEntry], goal: Double, days: Int) -> Double {
        let summaries = dailySummaries(entries: entries, goal: goal, days: days)
        guard !summaries.isEmpty else { return 0 }
        let complete = summaries.filter(\.completedGoal).count
        return Double(complete) / Double(summaries.count)
    }

    func bestStreak(entries: [DrinkEntry], dailyGoal: Double) -> Int {
        let summaries = dailySummaries(entries: entries, goal: dailyGoal, days: 30)
        var best = 0
        var current = 0

        for summary in summaries {
            if summary.completedGoal {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }

        return best
    }

    static func currentStreak(entries: [DrinkEntry], dailyGoal: Double) -> Int {
        let calendar = Calendar.current
        var streak = 0

        for offset in 0..<365 {
            let day = calendar.startOfDay(offsetByDays: -offset)
            let total = entries
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.amount }

            if total >= dailyGoal {
                streak += 1
            } else if offset == 0 {
                continue
            } else {
                break
            }
        }

        return streak
    }
}

final class AchievementsViewModel: ObservableObject {
    func sortedAchievements(_ achievements: [Achievement]) -> [Achievement] {
        achievements.sorted {
            if $0.unlocked != $1.unlocked {
                return $0.unlocked && !$1.unlocked
            }
            return $0.title < $1.title
        }
    }
}
