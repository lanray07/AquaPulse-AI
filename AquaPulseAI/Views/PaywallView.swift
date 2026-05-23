import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    private let options: [(plan: SubscriptionPlan, price: String, subtitle: String)] = [
        (.monthly, "£4.99", "Flexible monthly access"),
        (.yearly, "£29.99", "Best value for long-term habits"),
        (.lifetime, "£49.99", "One purchase, no renewal")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AquaPulse AI Pro")
                            .font(.largeTitle.bold())
                        Text("Smarter reminders, full history, custom goals, Apple Watch extras, widgets, and advanced insights.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Free Plan")
                            .font(.title3.bold())
                        Label("Basic water tracking", systemImage: "checkmark")
                        Label("Simple reminders", systemImage: "checkmark")
                        Label("7-day history", systemImage: "checkmark")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                    VStack(spacing: 12) {
                        ForEach(options, id: \.plan) { option in
                            Button {
                                Task {
                                    await subscriptionManager.purchase(plan: option.plan)
                                    dismiss()
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(option.plan.rawValue)
                                            .font(.headline)
                                        Text(option.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(option.price)
                                        .font(.headline)
                                }
                                .padding()
                                .background(AppTheme.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pro Includes")
                            .font(.title3.bold())
                        Label("Smart reminders", systemImage: "bell.badge")
                        Label("Apple Watch advanced features", systemImage: "applewatch")
                        Label("Full history and advanced insights", systemImage: "chart.xyaxis.line")
                        Label("Widgets and achievement themes", systemImage: "rectangle.3.group")
                    }
                    .foregroundStyle(.primary)
                }
                .padding()
            }
            .navigationTitle("Upgrade")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .overlay {
                if subscriptionManager.isLoading {
                    ProgressView("Loading StoreKit")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
