import Foundation
import SwiftData

enum AgeRange: String, CaseIterable, Identifiable, Codable {
    case under18 = "Under 18"
    case age18To29 = "18-29"
    case age30To44 = "30-44"
    case age45To59 = "45-59"
    case age60Plus = "60+"

    var id: String { rawValue }
}

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case moderate = "Moderate"
    case active = "Active"
    case athlete = "Athlete"

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .low: 0.95
        case .moderate: 1.0
        case .active: 1.15
        case .athlete: 1.3
        }
    }
}

enum ClimatePreference: String, CaseIterable, Identifiable, Codable {
    case mild = "Mild"
    case warm = "Warm"
    case hot = "Hot"
    case weatherBased = "Use weather later"

    var id: String { rawValue }
}

enum PreferredUnit: String, CaseIterable, Identifiable, Codable {
    case milliliters = "ml"
    case ounces = "oz"

    var id: String { rawValue }
    var symbol: String { rawValue }
}

enum DrinkType: String, CaseIterable, Identifiable, Codable {
    case water = "Water"
    case tea = "Tea"
    case coffee = "Coffee"
    case juice = "Juice"
    case sportsDrink = "Sports Drink"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .water: "drop.fill"
        case .tea: "cup.and.saucer.fill"
        case .coffee: "mug.fill"
        case .juice: "takeoutbag.and.cup.and.straw.fill"
        case .sportsDrink: "figure.run"
        }
    }
}

enum ReminderTone: String, CaseIterable, Identifiable, Codable {
    case gentle = "Gentle"
    case motivational = "Motivational"
    case strict = "Strict"
    case funny = "Funny"

    var id: String { rawValue }

    var notificationBody: String {
        switch self {
        case .gentle: "A small sip now keeps the day flowing."
        case .motivational: "Hydration check. You are building the habit."
        case .strict: "Time to drink water. No skipping this one."
        case .funny: "Your future self requested water. Please comply."
        }
    }
}

enum MotivationalStyle: String, CaseIterable, Identifiable, Codable {
    case calm = "Calm"
    case coach = "Coach"
    case playful = "Playful"

    var id: String { rawValue }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
    case free = "Free"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case lifetime = "Lifetime"

    var id: String { rawValue }

    var productID: String? {
        switch self {
        case .free: nil
        case .monthly: "aquapulseai.pro.monthly"
        case .yearly: "aquapulseai.pro.yearly"
        case .lifetime: "aquapulseai.pro.lifetime"
        }
    }
}

@Model
final class UserHydrationProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var ageRangeRawValue: String
    var weight: Double
    var activityLevelRawValue: String
    var climatePreferenceRawValue: String
    var wakeTime: Date
    var sleepTime: Date
    var dailyGoal: Double
    var preferredUnitRawValue: String
    var preferredCupSize: Double
    var goalIsManualOverride: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        ageRange: AgeRange = .age30To44,
        weight: Double,
        activityLevel: ActivityLevel,
        climatePreference: ClimatePreference = .mild,
        wakeTime: Date,
        sleepTime: Date,
        dailyGoal: Double,
        preferredUnit: PreferredUnit = .milliliters,
        preferredCupSize: Double = 250,
        goalIsManualOverride: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.ageRangeRawValue = ageRange.rawValue
        self.weight = weight
        self.activityLevelRawValue = activityLevel.rawValue
        self.climatePreferenceRawValue = climatePreference.rawValue
        self.wakeTime = wakeTime
        self.sleepTime = sleepTime
        self.dailyGoal = dailyGoal
        self.preferredUnitRawValue = preferredUnit.rawValue
        self.preferredCupSize = preferredCupSize
        self.goalIsManualOverride = goalIsManualOverride
        self.createdAt = createdAt
    }

    var ageRange: AgeRange {
        get { AgeRange(rawValue: ageRangeRawValue) ?? .age30To44 }
        set { ageRangeRawValue = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRawValue) ?? .moderate }
        set { activityLevelRawValue = newValue.rawValue }
    }

    var climatePreference: ClimatePreference {
        get { ClimatePreference(rawValue: climatePreferenceRawValue) ?? .mild }
        set { climatePreferenceRawValue = newValue.rawValue }
    }

    var preferredUnit: PreferredUnit {
        get { PreferredUnit(rawValue: preferredUnitRawValue) ?? .milliliters }
        set { preferredUnitRawValue = newValue.rawValue }
    }
}

@Model
final class DrinkEntry {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var drinkTypeRawValue: String
    var date: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        drinkType: DrinkType = .water,
        date: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.drinkTypeRawValue = drinkType.rawValue
        self.date = date
        self.createdAt = createdAt
    }

    var drinkType: DrinkType {
        get { DrinkType(rawValue: drinkTypeRawValue) ?? .water }
        set { drinkTypeRawValue = newValue.rawValue }
    }
}

@Model
final class ReminderSettings {
    @Attribute(.unique) var id: UUID
    var frequency: Int
    var quietHoursStart: Date
    var quietHoursEnd: Date
    var reminderToneRawValue: String
    var motivationalStyleRawValue: String
    var smartRemindersEnabled: Bool
    var activityBasedRemindersEnabled: Bool
    var missedDrinkReminderEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        frequency: Int = 90,
        quietHoursStart: Date = .timeToday(hour: 22, minute: 0),
        quietHoursEnd: Date = .timeToday(hour: 7, minute: 0),
        reminderTone: ReminderTone = .gentle,
        motivationalStyle: MotivationalStyle = .calm,
        smartRemindersEnabled: Bool = true,
        activityBasedRemindersEnabled: Bool = false,
        missedDrinkReminderEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.frequency = frequency
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.reminderToneRawValue = reminderTone.rawValue
        self.motivationalStyleRawValue = motivationalStyle.rawValue
        self.smartRemindersEnabled = smartRemindersEnabled
        self.activityBasedRemindersEnabled = activityBasedRemindersEnabled
        self.missedDrinkReminderEnabled = missedDrinkReminderEnabled
        self.createdAt = createdAt
    }

    var reminderTone: ReminderTone {
        get { ReminderTone(rawValue: reminderToneRawValue) ?? .gentle }
        set { reminderToneRawValue = newValue.rawValue }
    }

    var motivationalStyle: MotivationalStyle {
        get { MotivationalStyle(rawValue: motivationalStyleRawValue) ?? .calm }
        set { motivationalStyleRawValue = newValue.rawValue }
    }

    func isInsideQuietHours(_ date: Date) -> Bool {
        let minute = Calendar.current.minuteOfDay(for: date)
        let start = Calendar.current.minuteOfDay(for: quietHoursStart)
        let end = Calendar.current.minuteOfDay(for: quietHoursEnd)

        if start <= end {
            return minute >= start && minute <= end
        }

        return minute >= start || minute <= end
    }
}

@Model
final class Achievement {
    @Attribute(.unique) var id: UUID
    var title: String
    var achievementDescription: String
    var unlocked: Bool
    var unlockedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        unlocked: Bool = false,
        unlockedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.achievementDescription = description
        self.unlocked = unlocked
        self.unlockedAt = unlockedAt
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var planRawValue: String
    var isActive: Bool
    var renewsAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        plan: SubscriptionPlan = .free,
        isActive: Bool = false,
        renewsAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.planRawValue = plan.rawValue
        self.isActive = isActive
        self.renewsAt = renewsAt
        self.createdAt = createdAt
    }

    var plan: SubscriptionPlan {
        get { SubscriptionPlan(rawValue: planRawValue) ?? .free }
        set { planRawValue = newValue.rawValue }
    }
}
