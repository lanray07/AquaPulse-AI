import SwiftData
import SwiftUI

struct AchievementsView: View {
    @Query(sort: \Achievement.title) private var achievements: [Achievement]
    @StateObject private var viewModel = AchievementsViewModel()

    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            if achievements.isEmpty {
                ContentUnavailableView("No badges yet", systemImage: "medal", description: Text("Badges are created when your profile is set up."))
                    .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(viewModel.sortedAchievements(achievements)) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Achievements")
    }
}
