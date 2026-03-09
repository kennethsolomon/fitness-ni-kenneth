# Release Checklist

## Pre-TestFlight

### Code & Build
- [ ] Set `DEVELOPMENT_TEAM` in project.yml / Xcode to your Apple Developer team ID
- [ ] Set correct bundle ID (`com.yourname.FitnessNiKenneth`)
- [ ] Set Watch companion bundle ID (`com.yourname.FitnessNiKenneth.watchkitapp`)
- [ ] Bump `MARKETING_VERSION` (e.g. 1.0.0) and `CURRENT_PROJECT_VERSION` (e.g. 1) in Xcode
- [ ] Archive builds cleanly with no warnings treated as errors
- [ ] All unit tests pass
- [ ] App runs on a physical device (not just simulator)
- [ ] Watch app runs on physical Apple Watch

### App Icon
- [ ] Provide 1024×1024 App Icon in `Assets.xcassets/AppIcon.appiconset`
- [ ] Watch app icon: 1024×1024 in Watch app's Assets.xcassets

### Privacy Manifest (PrivacyInfo.xcprivacy)
Create `FitnessNiKenneth/PrivacyInfo.xcprivacy` with:
- **NSPrivacyAccessedAPITypes**: none required (no file timestamps, UserDefaults in unusual ways, etc.)
- **NSPrivacyCollectedDataTypes**: none (local-only app, no tracking)
- **NSPrivacyTrackingDomains**: empty
- **NSPrivacyTracking**: false

This app collects **no user data** and sends **no data to servers**. State this clearly in App Store privacy labels.

### App Store Privacy Labels (manual in App Store Connect)
Select: **Data Not Collected**

### Permissions Review
This app requests **no system permissions** in v1:
- No camera, microphone, location, contacts, calendar
- No HealthKit (deferred to v2)
- No push notifications (deferred)

If HealthKit is added later, add `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` to Info.plist.

### HealthKit
Not used in v1. Do not include HealthKit entitlement.

### Local Data Behavior
- All workout data is stored locally in SwiftData (SQLite)
- Database location: App sandbox `Documents/` or `Application Support/`
- Users can back up via iCloud backup (device backup) automatically
- No explicit iCloud sync in v1
- Data is lost if user deletes the app (warn in onboarding if added)

## TestFlight Setup

1. Archive app in Xcode: **Product → Archive**
2. Distribute via **Xcode Organizer → Distribute App → TestFlight**
3. In App Store Connect:
   - Create app record with bundle ID
   - Add test information (what to test)
   - Add internal testers (up to 100 with accepted NDA)
   - Submit for external testing review if needed (up to 10,000 testers)

## App Store Submission

### Required Assets
- [ ] App icon 1024×1024 (no alpha channel)
- [ ] At least 1 iPhone 6.9" screenshot (iPhone 16 Pro Max size: 1320×2868)
- [ ] At least 1 iPhone 6.1" screenshot (iPhone 16: 1179×2556)
- [ ] Optional: Apple Watch screenshots

### App Store Listing
- **App Name**: FitnessNiKenneth (or your marketing name)
- **Subtitle**: Strength Training Tracker
- **Category**: Health & Fitness
- **Age Rating**: 4+ (no objectionable content)
- **Price**: Free (or your pricing)

### Review Notes for App Review Team
> "This is a local-only strength training tracker. It requires no account, collects no personal data, and makes no network requests. All workout data is stored on-device using SwiftData. The Apple Watch companion shows active workout state synchronized via WatchConnectivity."

### Version Info
- **What's New in This Version** (for 1.0): First release. Track your workouts, exercises, and personal records.

## Post-Launch

- Monitor crash reports in App Store Connect / Xcode Organizer
- Set up TestFlight for beta releases before each App Store update
- Plan for HealthKit integration in v2 (write workouts to Health app)
- Plan for iCloud sync in v2 (CloudKit + SwiftData)
