# App Store Audit Command

Check for App Store rejection risks.

## Focus Area
$ARGUMENTS

## Common Rejection Reasons Checklist

### 1. Functionality (Guideline 2.1)

- [ ] App launches without crashing
- [ ] All buttons and features work
- [ ] No placeholder content
- [ ] No "beta" or "test" labels
- [ ] Features match App Store description
- [ ] Demo accounts provided if login required

### 2. Performance (Guideline 2.3)

- [ ] App is complete and functional
- [ ] No excessive battery drain
- [ ] No excessive memory usage
- [ ] Reasonable app size
- [ ] Works on minimum supported iOS version

### 3. Metadata (Guideline 2.3.7)

- [ ] App name matches functionality
- [ ] Description accurate and not misleading
- [ ] Screenshots show actual app
- [ ] Keywords relevant and not spammy
- [ ] Category appropriate
- [ ] No competitor names in metadata

### 4. Design (Guideline 4)

- [ ] Follows Human Interface Guidelines
- [ ] Native UI elements used appropriately
- [ ] No web views pretending to be native
- [ ] Supports standard system features (Dark Mode)
- [ ] Accessibility features present

### 5. Privacy (Guideline 5.1)

- [ ] Privacy policy accessible
- [ ] Data collection disclosed
- [ ] Permission prompts explain usage
- [ ] App Privacy labels accurate
- [ ] User data handled securely
- [ ] GDPR compliance if applicable

### 6. Permissions (Guideline 5.1.1)

Verify each permission has proper usage description in Info.plist:
```xml
<key>NSCameraUsageDescription</key>
<string>[Why camera access is needed]</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>[Why photo library access is needed]</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>[Why location access is needed]</string>
```

### 7. In-App Purchases (Guideline 3.1)

If using IAP:
- [ ] IAP properly implemented
- [ ] Restore purchases available
- [ ] Prices clearly displayed
- [ ] No external payment links
- [ ] Features delivered after purchase

### 8. Legal (Guideline 5.2)

- [ ] No intellectual property violations
- [ ] No trademarked names/images without permission
- [ ] Content is original or licensed
- [ ] Terms of service available

### Pre-Submission Checklist

#### Required Assets
- [ ] App icon (1024x1024)
- [ ] Screenshots for each device size
- [ ] App Preview video (optional)
- [ ] Privacy policy URL

#### App Store Connect
- [ ] Build uploaded
- [ ] Version number correct
- [ ] Build number incremented
- [ ] Export compliance answered
- [ ] Age rating questionnaire completed
- [ ] App Privacy labels configured

#### Testing
- [ ] TestFlight tested on real devices
- [ ] Tested on oldest supported iOS
- [ ] Tested on newest iOS
- [ ] Tested on multiple device sizes

## Output

1. Risk assessment (High/Medium/Low)
2. Issues found with guideline reference
3. Required fixes before submission
4. Recommended improvements
5. Missing assets or metadata
