# AquaPulse AI

AquaPulse AI is a SwiftUI hydration tracker scaffold with SwiftData persistence, local notifications, StoreKit 2 subscription scaffolding, HealthKit and WatchConnectivity placeholders, Watch app source, WidgetKit placeholder source, and mock data enabled by default.

Open `AquaPulseAI.xcodeproj` in Xcode and run the `AquaPulseAI` iOS target. The app targets iOS 17 because SwiftData is used throughout the persistence layer.

## App Store Connect setup

- App Store Connect app: `AquaPulse AI`
- Apple app ID: `6772486162`
- iOS bundle identifier: `com.obankole.AquaPulse`
- Watch app bundle identifier: `com.obankole.AquaPulse.watchkitapp`
- Widget extension bundle identifier: `com.obankole.AquaPulse.widget`
- App group placeholder: `group.com.obankole.AquaPulse`

StoreKit product identifiers:

- Monthly Pro subscription: `aquapulseai.pro.monthly`
- Yearly Pro subscription: `aquapulseai.pro.yearly`
- Lifetime non-consumable: `aquapulseai.pro.lifetime`

Before archiving in Xcode, select your Apple Developer team for each target, enable the required capabilities, and replace placeholder entitlements with the matching App Store Connect identifiers.

## GitHub Xcode build

The repository includes a GitHub Actions workflow that runs a simulator build with code signing disabled. This is intended as a CI smoke test; App Store upload still needs a signed archive from Xcode or a configured Xcode Cloud workflow.
