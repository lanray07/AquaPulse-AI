import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    private let options: [PurchaseOption] = [
        PurchaseOption(
            plan: .monthly,
            title: "AquaPulse AI Pro Monthly",
            fallbackPrice: "GBP 4.99 per month",
            term: "1 month auto-renewable subscription",
            subtitle: "Flexible monthly access to Pro hydration tools."
        ),
        PurchaseOption(
            plan: .yearly,
            title: "AquaPulse AI Pro Yearly",
            fallbackPrice: "GBP 29.99 per year",
            term: "1 year auto-renewable subscription",
            subtitle: "Best value for long-term hydration habits."
        ),
        PurchaseOption(
            plan: .lifetime,
            title: "AquaPulse AI Lifetime",
            fallbackPrice: "GBP 49.99 one-time purchase",
            term: "Lifetime non-consumable purchase",
            subtitle: "One purchase for lifetime Pro access."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AquaPulse AI Pro")
                            .font(.largeTitle.bold())
                        Text("Choose a subscription or lifetime purchase for smart reminders, full history, custom goals, Apple Watch extras, widgets, and advanced insights.")
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
                        ForEach(options) { option in
                            Button {
                                Task {
                                    let previousPlan = subscriptionManager.currentState.plan
                                    await subscriptionManager.purchase(plan: option.plan)
                                    if subscriptionManager.currentState.isActive,
                                       subscriptionManager.currentState.plan != previousPlan {
                                        dismiss()
                                    }
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(option.title)
                                            .font(.headline)
                                        Text(option.term)
                                            .font(.subheadline)
                                        Text(option.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(priceText(for: option))
                                        .font(.headline)
                                        .multilineTextAlignment(.trailing)
                                }
                                .padding()
                                .background(AppTheme.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subscription Details")
                            .font(.title3.bold())
                        Text("Monthly and yearly plans renew automatically unless cancelled at least 24 hours before the end of the current period. Payment is charged to your Apple ID. You can manage or cancel subscriptions in your App Store account settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Link("Privacy Policy", destination: URL(string: AppConstants.privacyPolicyURL)!)
                        Link("Terms of Use (EULA)", destination: URL(string: AppConstants.termsOfUseURL)!)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pro Includes")
                            .font(.title3.bold())
                        Label("Smart reminders", systemImage: "bell.badge")
                        Label("Apple Watch advanced features", systemImage: "applewatch")
                        Label("Full history and advanced insights", systemImage: "chart.xyaxis.line")
                        Label("Widgets and achievement themes", systemImage: "rectangle.3.group")
                    }
                    .foregroundStyle(.primary)

                    if let errorMessage = subscriptionManager.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("AquaPulse AI Pro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Restore") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                }
            }
            .overlay {
                if subscriptionManager.isLoading {
                    ProgressView("Loading StoreKit")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .task {
                await subscriptionManager.loadProducts()
            }
        }
    }

    private func priceText(for option: PurchaseOption) -> String {
        guard let productID = option.plan.productID,
              let product = subscriptionManager.products.first(where: { $0.id == productID }) else {
            return option.fallbackPrice
        }

        switch option.plan {
        case .monthly:
            return "\(product.displayPrice) per month"
        case .yearly:
            return "\(product.displayPrice) per year"
        case .lifetime:
            return "\(product.displayPrice) one-time"
        case .free:
            return product.displayPrice
        }
    }
}

private struct PurchaseOption: Identifiable {
    let plan: SubscriptionPlan
    let title: String
    let fallbackPrice: String
    let term: String
    let subtitle: String

    var id: String { plan.rawValue }
}
