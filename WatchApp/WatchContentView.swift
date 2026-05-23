import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject private var store: WatchHydrationStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                WatchProgressView(progress: store.progress, intake: store.todayIntake, goal: store.dailyGoal)

                Text("Remaining \(Int(store.remaining)) ml")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("+100") { store.quickAdd(100) }
                    Button("+250") { store.quickAdd(250) }
                }
                .buttonStyle(.borderedProminent)

                Button("+500 ml") { store.quickAdd(500) }
                    .buttonStyle(.bordered)

                ComplicationPlaceholderView()

                Text(store.lastSyncMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }
}

struct ComplicationPlaceholderView: View {
    var body: some View {
        Label("Complication placeholder", systemImage: "gauge.medium")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}
