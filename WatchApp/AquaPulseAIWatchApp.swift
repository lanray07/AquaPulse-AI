import SwiftUI

@main
struct AquaPulseAIWatchApp: App {
    @StateObject private var store = WatchHydrationStore()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(store)
        }
    }
}
