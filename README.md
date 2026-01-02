# Not Hot Dog

![iOS CI](https://github.com/marcoakes/not-hot-dog/actions/workflows/ios-ci.yml/badge.svg?branch=main)
[![Release](https://img.shields.io/github/v/release/marcoakes/Not Hot Dog?display_name=tag&sort=semver)](https://github.com/marcoakes/not-hot-dog/releases)

An iOS app that uses Apple's Vision framework to classify images as either **Hot Dog** or **Not Hot Dog**. Nothing else.

## Features

- **Full-screen camera view** - Opens directly to camera
- **One-tap classification** - Capture and classify in one action
- **Binary output** - It's either a hot dog, or it's not
- **Simple, playful UI** - Green checkmark for hot dogs, red X for everything else
- **80% confidence threshold** - Only confident predictions count

## Tech Stack

- **Language**: Swift 6
- **UI**: SwiftUI
- **ML**: Vision Framework (VNClassifyImageRequest)
- **Camera**: AVFoundation
- **Logging**: os.Logger
- **CI**: GitHub Actions (lint, unit tests, UI tests)
- **Release**: Fastlane + GitHub Actions optional automation

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Physical device recommended (camera required)

To run UI tests in CI or locally without a camera, the app supports a test-only override via the `SEEFOOD_MOCK_RESULT` launch environment (values: `hotdog` or `nothotdog`).

## Project Structure

```
NotHotDog/
├── NotHotDog.xcodeproj/
│   └── project.pbxproj
└── NotHotDog/
    ├── NotHotDogApp.swift        # App entry point
    ├── ContentView.swift         # Main UI with camera preview
    ├── CameraManager.swift       # AVFoundation camera handling
    ├── ImageClassifier.swift     # Vision classification logic
    ├── Info.plist                # Privacy descriptions
    └── Assets.xcassets/          # App icons and colors
```

## Optimization Notes

The code includes inline comments marking potential areas for optimization (session configuration, camera selection, buffer conversion, model choice, matching, and resizing).

## How It Works

1. Camera feed displays full-screen
2. User taps the capture button
3. Image is sent to Vision's `VNClassifyImageRequest`
4. Results are checked for "hot dog" labels (including synonyms)
5. If confidence > 80%, displays "HOT DOG" with green banner
6. Otherwise, displays "NOT HOT DOG" with red banner

## Privacy

The app processes images entirely on-device. Camera access is required to capture images for classification; nothing is uploaded.

## License

MIT License.
