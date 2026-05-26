import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var healthKitService: HealthKitService
    @EnvironmentObject private var notificationService: NotificationService
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Basics") {
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.givenName)
                    Picker("Age Range", selection: $viewModel.ageRange) {
                        ForEach(AgeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    Stepper(value: $viewModel.weight, in: 35...180, step: 1) {
                        Text("Weight: \(Int(viewModel.weight)) kg")
                    }
                }

                Section("Hydration Context") {
                    Picker("Activity Level", selection: $viewModel.activityLevel) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    Picker("Climate", selection: $viewModel.climatePreference) {
                        ForEach(ClimatePreference.allCases) { climate in
                            Text(climate.rawValue).tag(climate)
                        }
                    }
                    DatePicker("Wake-Up", selection: $viewModel.wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Bedtime", selection: $viewModel.sleepTime, displayedComponents: .hourAndMinute)
                    Stepper(value: $viewModel.preferredCupSize, in: 100...1000, step: 50) {
                        Text("Preferred Cup: \(Int(viewModel.preferredCupSize)) ml")
                    }
                }

                Section("Estimated Goal") {
                    HStack {
                        Text("Daily goal")
                        Spacer()
                        Text(HydrationFormatter.amount(viewModel.estimatedDailyGoal, unit: viewModel.preferredUnit))
                            .font(.headline)
                    }
                    Text("This is an estimate based on weight and activity level. You can override it any time in Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Privacy and Apple Health (HealthKit)") {
                    Text("AquaPulse AI stores hydration data locally with SwiftData. Apple Health uses HealthKit only for optional water intake read and write sync, and only after you grant permission.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Connect Apple Health") {
                        Task { await healthKitService.requestAuthorization() }
                    }
                    Text(healthKitService.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        Task { await notificationService.requestAuthorization() }
                        viewModel.save(in: modelContext)
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Start Tracking")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.blue)
                }
            }
            .navigationTitle("AquaPulse AI")
            .alert("Onboarding", isPresented: errorAlertBinding) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
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
