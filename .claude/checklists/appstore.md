# App Store Submission Checklist

## Pre-Submission Requirements

### App Metadata
- [ ] App name (30 characters max, unique on App Store)
- [ ] Subtitle (30 characters max)
- [ ] Description (4000 characters max, compelling first paragraph)
- [ ] Keywords (100 characters, comma-separated)
- [ ] What's New text for updates
- [ ] Privacy Policy URL (required)
- [ ] Support URL (required)
- [ ] Marketing URL (optional)

### Screenshots
- [ ] 6.7" (iPhone 15 Pro Max) - Required for iPhone apps
- [ ] 6.5" (iPhone 11 Pro Max) - Required if supporting older devices
- [ ] 5.5" (iPhone 8 Plus) - Required if supporting older devices
- [ ] 12.9" (iPad Pro 6th gen) - Required for iPad apps
- [ ] 12.9" (iPad Pro 2nd gen) - Required if supporting older iPads
- [ ] Screenshots show actual app functionality
- [ ] No device bezels in screenshots (unless template provided)
- [ ] Text is localized if supporting multiple languages

### App Preview Videos (Optional)
- [ ] 15-30 seconds duration
- [ ] App footage only (no hands, devices)
- [ ] Proper resolution for each device size
- [ ] No calls-to-action directing off-platform

### App Icon
- [ ] 1024x1024 PNG (no transparency, no rounded corners)
- [ ] Matches in-app icon design
- [ ] No text unless part of logo
- [ ] Visible at small sizes

## Technical Requirements

### Build Configuration
- [ ] Archive build (not debug)
- [ ] Correct bundle identifier
- [ ] Version number incremented
- [ ] Build number unique for this version
- [ ] Deployment target matches App Store Connect settings
- [ ] All debug code removed
- [ ] Test flight builds tested

### Privacy
- [ ] App Privacy labels completed in App Store Connect
- [ ] Privacy manifest (PrivacyInfo.xcprivacy) included
- [ ] Required reason APIs declared if used:
  - [ ] User defaults
  - [ ] File timestamp
  - [ ] System boot time
  - [ ] Disk space
  - [ ] Active keyboards
- [ ] Tracking transparency implemented if tracking users
- [ ] Privacy policy accurately describes data collection

### Capabilities & Entitlements
- [ ] Only necessary capabilities enabled
- [ ] Associated Domains configured (if using Universal Links)
- [ ] Push notification entitlements (if applicable)
- [ ] Sign In with Apple (if offering third-party sign-in)
- [ ] HealthKit (if applicable) - usage description required

### Permissions
- [ ] All Info.plist usage descriptions present:
  - [ ] NSCameraUsageDescription
  - [ ] NSPhotoLibraryUsageDescription
  - [ ] NSLocationWhenInUseUsageDescription
  - [ ] NSMicrophoneUsageDescription
  - [ ] etc.
- [ ] Permissions requested only when needed (not at launch)
- [ ] Graceful handling when permission denied

## App Review Guidelines Compliance

### Content
- [ ] No placeholder content
- [ ] No "beta", "demo", "test" text
- [ ] All features functional
- [ ] Content appropriate for age rating
- [ ] User-generated content moderation (if applicable)

### Functionality
- [ ] App completes its intended purpose
- [ ] No crashes or obvious bugs
- [ ] Works offline where appropriate
- [ ] Deep links function correctly
- [ ] Universal Links work (if implemented)

### In-App Purchases
- [ ] All IAPs configured in App Store Connect
- [ ] Restore purchases functionality
- [ ] Subscription management accessible
- [ ] Clear pricing displayed before purchase
- [ ] Terms of service link (for subscriptions)

### Sign In
- [ ] Sign In with Apple offered (if other third-party sign-in present)
- [ ] Guest mode available (if possible)
- [ ] Account deletion option available

### Legal
- [ ] EULA accepted (or using standard Apple EULA)
- [ ] Copyright/trademark compliance
- [ ] No references to competing platforms
- [ ] Gambling/contests comply with local laws

## Testing Before Submission

### Device Testing
- [ ] Tested on oldest supported device
- [ ] Tested on newest device
- [ ] Tested on iPad (if universal app)
- [ ] Tested with different Dynamic Type sizes
- [ ] Tested with VoiceOver
- [ ] Tested in Dark Mode
- [ ] Tested with slow network
- [ ] Tested in airplane mode

### Performance
- [ ] App launches in reasonable time (< 5 seconds)
- [ ] No memory leaks
- [ ] No excessive battery drain
- [ ] No excessive CPU usage
- [ ] Smooth animations (60 fps)

### Localization
- [ ] All supported languages tested
- [ ] RTL layout works (if applicable)
- [ ] Date/time/number formatting correct
- [ ] No untranslated strings visible

## Submission Process

### App Store Connect
- [ ] Correct app version selected
- [ ] Build uploaded and processed
- [ ] All required fields completed
- [ ] Age rating questionnaire completed
- [ ] Export compliance answered
- [ ] Advertising identifier (IDFA) declaration accurate
- [ ] Review notes added (if needed for testing)
- [ ] Demo account provided (if login required)

### Final Checks
- [ ] App is signed with distribution certificate
- [ ] No TestFlight-only code paths
- [ ] Analytics/crash reporting configured
- [ ] Backend services production-ready
- [ ] Support team briefed on new features
