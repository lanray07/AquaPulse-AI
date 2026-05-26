import SwiftUI

struct HydrationProgressRing: View {
    let progress: Double
    let currentAmount: String
    let goalAmount: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.softBackground, lineWidth: 18)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(colors: [AppTheme.blue, AppTheme.teal, AppTheme.mint], center: .center),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)

            VStack(spacing: 4) {
                Text(HydrationFormatter.percentage(progress))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text(currentAmount)
                    .font(.headline)
                Text("of \(goalAmount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 210, height: 210)
        .accessibilityLabel("Hydration progress \(HydrationFormatter.percentage(progress))")
    }
}

struct QuickAddButton: View {
    let amount: Double
    let unit: PreferredUnit
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text(HydrationFormatter.amount(amount, unit: unit))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 82)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.blue)
        .accessibilityLabel("Add \(HydrationFormatter.amount(amount, unit: unit))")
    }
}

struct DrinkEntryRow: View {
    let entry: DrinkEntry
    let unit: PreferredUnit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.drinkType.symbolName)
                .font(.title3)
                .foregroundStyle(AppTheme.teal)
                .frame(width: 34, height: 34)
                .background(AppTheme.teal.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.drinkType.rawValue)
                    .font(.headline)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(HydrationFormatter.amount(entry.amount, unit: unit))
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ReminderCard: View {
    let title: String
    let detail: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(AppTheme.blue)
                .frame(width: 42, height: 42)
                .background(AppTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? AppTheme.teal.opacity(0.18) : Color.secondary.opacity(0.12))
                    .frame(width: 68, height: 68)

                Image(systemName: achievement.unlocked ? "medal.fill" : "lock.fill")
                    .font(.title)
                    .foregroundStyle(achievement.unlocked ? AppTheme.teal : .secondary)
            }

            Text(achievement.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(achievement.achievementDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 176)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .opacity(achievement.unlocked ? 1 : 0.72)
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbolName)
                    .foregroundStyle(AppTheme.blue)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct UpgradeBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 3) {
                    Text("AquaPulse AI Pro")
                        .font(.headline)
                    Text("View subscriptions and lifetime purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("View")
                    .font(.caption.bold())
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .padding()
            .background(AppTheme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct HealthKitDisclosureCard: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.text.square.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.teal)
                .frame(width: 42, height: 42)
                .background(AppTheme.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Health (HealthKit)")
                    .font(.headline)
                Text("Optional water intake read and write sync. Manage it in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
