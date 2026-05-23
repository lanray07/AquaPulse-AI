import Charts
import SwiftData
import SwiftUI

struct HistoryInsightsView: View {
    @Query(sort: \DrinkEntry.date, order: .reverse) private var entries: [DrinkEntry]
    let profile: UserHydrationProfile
    @StateObject private var viewModel = HistoryInsightsViewModel()

    private var sevenDays: [HydrationDay] {
        viewModel.dailySummaries(entries: entries, goal: profile.dailyGoal, days: 7)
    }

    private var thirtyDays: [HydrationDay] {
        viewModel.dailySummaries(entries: entries, goal: profile.dailyGoal, days: 30)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if entries.isEmpty {
                    ContentUnavailableView("No insights yet", systemImage: "chart.xyaxis.line", description: Text("Insights appear after you log drinks."))
                        .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("7-Day Hydration")
                            .font(.title3.bold())
                        Chart(sevenDays) { day in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Intake", day.total)
                            )
                            .foregroundStyle(day.completedGoal ? AppTheme.teal : AppTheme.blue.opacity(0.55))

                            RuleMark(y: .value("Goal", profile.dailyGoal))
                                .foregroundStyle(.secondary)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                        }
                        .frame(height: 220)
                        .chartYAxisLabel("ml")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("30-Day Trend")
                            .font(.title3.bold())
                        Chart(thirtyDays) { day in
                            LineMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Intake", day.total)
                            )
                            .foregroundStyle(AppTheme.teal)
                            AreaMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Intake", day.total)
                            )
                            .foregroundStyle(AppTheme.teal.opacity(0.16))
                        }
                        .frame(height: 220)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        InsightCard(
                            title: "Best Streak",
                            value: "\(viewModel.bestStreak(entries: entries, dailyGoal: profile.dailyGoal)) days",
                            subtitle: "Past 30 days",
                            symbolName: "flame.fill"
                        )
                        InsightCard(
                            title: "Average",
                            value: HydrationFormatter.amount(viewModel.averageDailyIntake(entries: entries, goal: profile.dailyGoal, days: 30), unit: profile.preferredUnit),
                            subtitle: "Daily intake",
                            symbolName: "drop.fill"
                        )
                        InsightCard(
                            title: "Missed Days",
                            value: "\(viewModel.missedDays(entries: entries, goal: profile.dailyGoal, days: 30))",
                            subtitle: "No drinks logged",
                            symbolName: "calendar.badge.exclamationmark"
                        )
                        InsightCard(
                            title: "Completion",
                            value: HydrationFormatter.percentage(viewModel.goalCompletionPercentage(entries: entries, goal: profile.dailyGoal, days: 30)),
                            subtitle: "Goals completed",
                            symbolName: "checkmark.seal.fill"
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
    }
}
