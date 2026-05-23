import Foundation
import SwiftUI

enum AppConstants {
    static let mockDataEnabled = true
    static let appGroupIdentifier = "group.com.obankole.AquaPulse"
    static let monthlyProductID = "aquapulseai.pro.monthly"
    static let yearlyProductID = "aquapulseai.pro.yearly"
    static let lifetimeProductID = "aquapulseai.pro.lifetime"
}

enum AppTheme {
    static let blue = Color(red: 0.05, green: 0.42, blue: 0.88)
    static let teal = Color(red: 0.0, green: 0.67, blue: 0.72)
    static let mint = Color(red: 0.22, green: 0.79, blue: 0.66)
    static let softBackground = Color(.secondarySystemBackground)
}

extension Date {
    static func timeToday(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? .now
    }

    var shortTimeString: String {
        formatted(date: .omitted, time: .shortened)
    }

    var shortDateString: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}

extension Calendar {
    func minuteOfDay(for date: Date) -> Int {
        let components = dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func startOfDay(offsetByDays offset: Int) -> Date {
        date(byAdding: .day, value: offset, to: startOfDay(for: .now)) ?? .now
    }
}

enum HydrationFormatter {
    static func amount(_ milliliters: Double, unit: PreferredUnit) -> String {
        switch unit {
        case .milliliters:
            return "\(Int(milliliters.rounded())) ml"
        case .ounces:
            let ounces = milliliters / 29.5735
            return "\(Int(ounces.rounded())) oz"
        }
    }

    static func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

struct HydrationDay: Identifiable {
    let id = UUID()
    let date: Date
    let total: Double
    let goal: Double

    var completedGoal: Bool {
        total >= goal
    }
}
