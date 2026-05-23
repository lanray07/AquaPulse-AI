import Combine
import Foundation
import WatchKit
import WatchConnectivity

final class WatchHydrationStore: NSObject, ObservableObject {
    @Published var todayIntake: Double {
        didSet { UserDefaults.standard.set(todayIntake, forKey: "watchTodayIntake") }
    }
    @Published var dailyGoal: Double {
        didSet { UserDefaults.standard.set(dailyGoal, forKey: "watchDailyGoal") }
    }
    @Published var lastSyncMessage = "WatchConnectivity placeholder ready"

    override init() {
        let storedIntake = UserDefaults.standard.double(forKey: "watchTodayIntake")
        let storedGoal = UserDefaults.standard.double(forKey: "watchDailyGoal")
        self.todayIntake = storedIntake
        self.dailyGoal = storedGoal == 0 ? 2600 : storedGoal
        super.init()
        activateSession()
    }

    var remaining: Double {
        max(dailyGoal - todayIntake, 0)
    }

    var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(todayIntake / dailyGoal, 1)
    }

    func quickAdd(_ amount: Double) {
        todayIntake += amount
        lastSyncMessage = "Logged \(Int(amount)) ml"
        WKInterfaceDevice.current().play(.click)
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchHydrationStore: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.lastSyncMessage = error?.localizedDescription ?? "Connected to iPhone placeholder"
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            if let intake = userInfo["todayIntake"] as? Double {
                self.todayIntake = intake
            }
            if let goal = userInfo["dailyGoal"] as? Double {
                self.dailyGoal = goal
            }
            self.lastSyncMessage = "Synced from iPhone"
        }
    }
}
