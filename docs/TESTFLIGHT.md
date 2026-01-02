# TestFlight Build Guide

This project is ready for TestFlight distribution via Xcode. Below are concise steps to archive and upload.

## Prerequisites
- Xcode 15.x installed and signed in with your Apple ID that has access to App Store Connect.
- App Store Connect app record created with the bundle identifier `com.seefood.app` (or update the project to your own identifier).
- Valid iOS Distribution certificate and provisioning profile (Automatic signing recommended).

## Versioning
1. In Xcode, open `NotHotDog.xcodeproj`.
2. Select the `NotHotDog` target > General.
3. Bump `Version` (marketing version) if needed; keep `Build` auto-incremented.

## Archive and Upload (Xcode Organizer)
1. Set scheme to `Any iOS Device (arm64)`.
2. Product > Archive.
3. When Organizer opens, select the new archive and click `Distribute App`.
4. Choose `App Store Connect` > `Upload`.
5. Keep default options (bitcode off, symbols on) and proceed.
6. After upload, watch processing status in App Store Connect > TestFlight.

## Archive and Upload (CLI)
You can also upload via `xcodebuild`:

```
xcodebuild -scheme NotHotDog -configuration Release -archivePath build/NotHotDog.xcarchive archive \
  PRODUCT_BUNDLE_IDENTIFIER=com.seefood.app

xcodebuild -archivePath build/NotHotDog.xcarchive -exportPath build/export \
  -exportOptionsPlist <(cat <<'PLIST'
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
    <key>method</key><string>app-store</string>
    <key>uploadSymbols</key><true/>
    <key>signingStyle</key><string>automatic</string>
  </dict>
  </plist>
PLIST)
```

Then use Xcode Organizer or Transporter to upload the `.ipa` in `build/export` if not auto-uploaded.

## Test Mode for UI Tests
To run UI tests without requiring the camera:
- Launch with `SEEFOOD_MOCK_RESULT=hotdog` or `SEEFOOD_MOCK_RESULT=nothotdog`.

## Notes
- Ensure `NSCameraUsageDescription` is present (already configured in `Info.plist`).
- The app’s category in App Store Connect should be `Entertainment` for review context.
