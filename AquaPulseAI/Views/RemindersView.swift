import SwiftData
import SwiftUI

struct RemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var notificationService: NotificationService
    @Query(sort: \ReminderSettings.createdAt) private var settingsItems: [ReminderSettings]

    let profile: UserHydrationProfile
    @StateObject private var viewModel = ReminderSettingsViewModel()

    var body: some View {
        Group {
            if let settings = settingsItems.first {
                ReminderSettingsForm(
                    profile: profile,
                    settings: settings,
                    viewModel: viewModel
                )
            } else {
                ContentUnavailableView("No reminder settings", systemImage: "bell", description: Text("Creating default reminder settings."))
            }
        }
        .navigationTitle("Reminders")
        .task {
            if settingsItems.isEmpty {
                modelContext.insert(ReminderSettings())
                try? modelContext.save()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
        }
    }
}

struct ReminderSettingsForm: View {
    let profile: UserHydrationProfile
    @Bindable var settings: ReminderSettings
    @ObservedObject var viewModel: ReminderSettingsViewModel

    @EnvironmentObject private var reminderService: ReminderService
    @EnvironmentObject private var notificationService: NotificationService

    var body: some View {
        Form {
            Section("Schedule") {
                Stepper(value: $settings.frequency, in: 30...240, step: 15) {
                    Text("Every \(settings.frequency) minutes")
                }
                DatePicker("Wake-Up", selection: Binding(get: { profile.wakeTime }, set: { profile.wakeTime = $0 }), displayedComponents: .hourAndMinute)
                DatePicker("Bedtime", selection: Binding(get: { profile.sleepTime }, set: { profile.sleepTime = $0 }), displayedComponents: .hourAndMinute)
                DatePicker("Quiet Start", selection: $settings.quietHoursStart, displayedComponents: .hourAndMinute)
                DatePicker("Quiet End", selection: $settings.quietHoursEnd, displayedComponents: .hourAndMinute)
            }

            Section("Smart Reminders") {
                Toggle("Smart Reminders", isOn: $settings.smartRemindersEnabled)
                Toggle("Activity-Based Placeholder", isOn: $settings.activityBasedRemindersEnabled)
                Toggle("Missed-Drink Reminder", isOn: $settings.missedDrinkReminderEnabled)
            }

            Section("Style") {
                Picker("Tone", selection: Binding(get: { settings.reminderTone }, set: { settings.reminderTone = $0 })) {
                    ForEach(ReminderTone.allCases) { tone in
                        Text(tone.rawValue).tag(tone)
                    }
                }
                Picker("Motivation", selection: Binding(get: { settings.motivationalStyle }, set: { settings.motivationalStyle = $0 })) {
                    ForEach(MotivationalStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
            }

            Section {
                Button {
                    Task {
                        await viewModel.schedule(settings: settings, profile: profile, reminderService: reminderService, notificationService: notificationService)
                    }
                } label: {
                    if reminderService.isScheduling {
                        ProgressView()
                    } else {
                        Label("Apply Reminder Schedule", systemImage: "bell.badge")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.blue)
            }
        }
    }
}
