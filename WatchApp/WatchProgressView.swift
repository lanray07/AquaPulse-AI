import SwiftUI

struct WatchProgressView: View {
    let progress: Double
    let intake: Double
    let goal: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.25), lineWidth: 10)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.title3.bold())
                Text("\(Int(intake))/\(Int(goal)) ml")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 118, height: 118)
    }
}
