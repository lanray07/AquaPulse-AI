import WidgetKit
import SwiftUI

struct HydrationWidgetEntry: TimelineEntry {
    let date: Date
    let intake: Double
    let goal: Double
}

struct HydrationWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HydrationWidgetEntry {
        HydrationWidgetEntry(date: .now, intake: 1200, goal: 2600)
    }

    func getSnapshot(in context: Context, completion: @escaping (HydrationWidgetEntry) -> Void) {
        completion(HydrationWidgetEntry(date: .now, intake: 1200, goal: 2600))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HydrationWidgetEntry>) -> Void) {
        let entry = HydrationWidgetEntry(date: .now, intake: 1200, goal: 2600)
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct AquaPulseAIWidgetEntryView: View {
    let entry: HydrationWidgetEntry

    private var progress: Double {
        guard entry.goal > 0 else { return 0 }
        return min(entry.intake / entry.goal, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.cyan)
                Text("Water")
                    .font(.headline)
            }
            ProgressView(value: progress)
                .tint(.cyan)
            Text("\(Int(entry.intake)) / \(Int(entry.goal)) ml")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.background, for: .widget)
    }
}

struct AquaPulseAIWidget: Widget {
    let kind = "AquaPulseAIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HydrationWidgetProvider()) { entry in
            AquaPulseAIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AquaPulse AI")
        .description("See hydration progress at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
