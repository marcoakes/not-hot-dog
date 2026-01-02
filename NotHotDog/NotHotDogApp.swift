//
//  Not Hot DogApp.swift
//  Not Hot Dog
//
//  Hot Dog / Not Hot Dog
//

import SwiftUI

@main
struct NotHotDogApp: App {
    init() {
        // Configure UI test overrides if provided via launch environment
        let env = ProcessInfo.processInfo.environment
        if let mock = env["SEEFOOD_MOCK_RESULT"]?.lowercased() {
            switch mock {
            case "hotdog", "hot_dog", "hot-dog":
                ImageClassifier.overrideMode = .hotDog
            case "nothotdog", "not_hot_dog", "not-hot-dog", "not" :
                ImageClassifier.overrideMode = .notHotDog
            default:
                ImageClassifier.overrideMode = nil
            }
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
