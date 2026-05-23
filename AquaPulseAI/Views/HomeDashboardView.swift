import SwiftData
import SwiftUI

struct HomeDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var watchSyncService: WatchSyncService
    @Query(sort: \DrinkEntry.date, order: .reverse) private var entries: [DrinkEntry]
    @Query(sort: \Achievement.title) private var achievements: [Achievement]
    @Query(sort: \ReminderSettings.createdAt) private var reminderSettings: [ReminderSettings]

    @Bindable var profile: UserHydrationProfile
    @StateObject private var viewModel = HomeDashboardViewModel()
    @State private var showingPaywall = false

    private var todayEntries: [DrinkEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var todayTotal: Double {
        viewModel.todayTotal(entries: entries)
    }

    private var progress: Double {
        guard profile.dailyGoal > 0 else { return 0 }
        return min(todayTotal / profile.dailyGoal, 1)
    }

    private var nextReminderText: String {
        guard let settings = reminderSettings.first else { return "Set up reminders" }
        let next = Calendar.current.date(byAdding: .minute, value: settings.frequency, to: .now) ?? .now
        return next.formatted(date: .omitted, time: .shortened)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(spacing: 18) {
                    HydrationProgressRing(
                        progress: progress,
                        currentAmount: HydrationFormatter.amount(todayTotal, unit: profile.preferredUnit),
                        goalAmount: HydrationFormatter.amount(profile.dailyGoal, unit: profile.preferredUnit)
                    )

                    HStack(spacing: 12) {
                        InsightCard(title: "Remaining", value: HydrationFormatter.amount(max(profile.dailyGoal - todayTotal, 0), unit: profile.preferredUnit), subtitle: "Goal is an estimate", symbolName: "target")
                        InsightCard(title: "Streak", value: "\(HistoryInsightsViewModel.currentStreak(entries: entries, dailyGoal: profile.dailyGoal)) days", subtitle: "Completed goals", symbolName: "flame.fill")
                    }

                    ReminderCard(title: "Next Reminder", detail: nextReminderText, symbolName: "bell")
                }
                .frame(maxWidth: .infinity)

                UpgradeBanner {
                    showingPaywall = true
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Add")
                        .font(.title3.bold())

                    Picker("Drink Type", selection: $viewModel.selectedDrinkType) {
                        ForEach(DrinkType.allCases) { type in
                            Label(type.rawValue, systemImage: type.symbolName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach([100.0, 250.0, 500.0], id: \.self) { amount in
                            QuickAddButton(amount: amount, unit: profile.preferredUnit) {
                                addDrink(amount)
                            }
                        }

                        Button {
                            viewModel.customAmountText = ""
                            viewModel.isShowingCustomAmount = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title2)
                                Text("Custom")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity, minHeight: 82)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Drinks")
                        .font(.title3.bold())

                    if todayEntries.isEmpty {
                        ContentUnavailableView("No drinks yet", systemImage: "drop", description: Text("Log your first drink to start today."))
                            .frame(maxWidth: .infinity, minHeight: 160)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(todayEntries.prefix(5)) { entry in
                                DrinkEntryRow(entry: entry, unit: profile.preferredUnit)
                                    .padding()
                                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Today")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("Custom Amount", isPresented: $viewModel.isShowingCustomAmount) {
            TextField("Amount in ml", text: $viewModel.customAmountText)
                .keyboardType(.decimalPad)
            Button("Add") {
                addDrink(Double(viewModel.customAmountText) ?? 0)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add a custom drink amount.")
        }
        .alert("AquaPulse AI", isPresented: errorAlertBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func addDrink(_ amount: Double) {
        guard let entry = viewModel.addDrink(amount: amount, drinkType: viewModel.selectedDrinkType, context: modelContext) else { return }
        viewModel.unlockAchievementsIfNeeded(achievements: achievements, entries: entries + [entry], dailyGoal: profile.dailyGoal)
        watchSyncService.sendHydrationSnapshot(intake: todayTotal + entry.amount, goal: profile.dailyGoal)
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
