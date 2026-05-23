import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var watchSyncService: WatchSyncService
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Query private var entries: [DrinkEntry]
    @Query private var achievements: [Achievement]
    @Query private var settingsItems: [ReminderSettings]
    @Query private var subscriptions: [SubscriptionState]

    @Bindable var profile: UserHydrationProfile
    @State private var showingPaywall = false
    @State private var confirmDelete = false

    var body: some View {
        Form {
            Section("Profile") {
                TextField("Name", text: $profile.name)
                Stepper(value: $profile.dailyGoal, in: 1000...6000, step: 50) {
                    Text("Daily Goal: \(HydrationFormatter.amount(profile.dailyGoal, unit: profile.preferredUnit))")
                }
                Toggle("Manual Goal Override", isOn: $profile.goalIsManualOverride)
                Picker("Units", selection: Binding(get: { profile.preferredUnit }, set: { profile.preferredUnit = $0 })) {
                    ForEach(PreferredUnit.allCases) { unit in
                        Text(unit.symbol).tag(unit)
                    }
                }
            }

            Section("Connected Features") {
                NavigationLink("Reminder Schedule") {
                    RemindersView(profile: profile)
                }

                Button("Apple Health Permission") {
                    Task { await healthKitService.requestAuthorization() }
                }
                Text(healthKitService.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Apple Watch Sync")
                    Spacer()
                    Text(watchSyncService.lastSyncStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Subscription") {
                HStack {
                    Text("Current Plan")
                    Spacer()
                    Text(subscriptionManager.currentState.plan.rawValue)
                        .foregroundStyle(.secondary)
                }
                Button("Manage Subscription") {
                    showingPaywall = true
                }
                Button("Restore Purchases") {
                    Task { await subscriptionManager.restorePurchases() }
                }
            }

            Section("Legal") {
                Link("Privacy Policy", destination: URL(string: "https://github.com/lanray07/AquaPulse-AI/blob/main/PRIVACY.md")!)
                Link("Terms of Use", destination: URL(string: "https://github.com/lanray07/AquaPulse-AI/blob/main/TERMS.md")!)
            }

            Section {
                Button("Delete All Data", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .confirmationDialog("Delete all local hydration data?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive, action: deleteAllData)
            Button("Cancel", role: .cancel) { }
        }
    }

    private func deleteAllData() {
        for entry in entries { modelContext.delete(entry) }
        for achievement in achievements { modelContext.delete(achievement) }
        for settings in settingsItems { modelContext.delete(settings) }
        for subscription in subscriptions { modelContext.delete(subscription) }
        modelContext.delete(profile)
        try? modelContext.save()
    }
}
