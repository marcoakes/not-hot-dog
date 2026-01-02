//
//  ContentView.swift
//  Not Hot Dog
//
//  The main UI - Silicon Valley "Not Hot Dog" style
//

import SwiftUI
import AVFoundation

// MARK: - Classification Result
enum ClassificationResult {
    case none
    case hotDog
    case notHotDog
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var classifier = ImageClassifier()
    private let soundManager = SoundManager.shared

    @State private var classificationResult: ClassificationResult = .none
    @State private var isAnalyzing = false
    @State private var showResult = false
    @State private var capturedImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Feed
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()

                // Frozen captured image overlay (shown during result)
                if let image = capturedImage, showResult {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()
                }

                // UI Overlay
                VStack {
                    // Top bar with app name
                    HStack {
                        Text("NOT HOT DOG")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)

                        Spacer()

                        // Reset button (only show when result is displayed)
                        if showResult {
                            Button(action: resetToCamera) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    // Result Banner
                    if showResult {
                        resultBanner
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Capture Button (hidden when showing result)
                    if !showResult {
                        captureButton
                            .padding(.bottom, 50)
                    }
                }
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                cameraManager.startSession()
            case .inactive, .background:
                cameraManager.stopSession()
            @unknown default:
                break
            }
        }
        .alert("Camera Access Required", isPresented: $cameraManager.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Not Hot Dog needs camera access to identify hot dogs. Please enable it in Settings.")
        }
    }

    // MARK: - Capture Button
    private var captureButton: some View {
        Button(action: captureAndClassify) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                // Inner circle
                Circle()
                    .fill(isAnalyzing ? Color.gray : Color.white)
                    .frame(width: 65, height: 65)

                // Loading indicator
                if isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(1.5)
                }
            }
        }
        .disabled(isAnalyzing)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
        .accessibilityLabel("Capture and classify")
        .accessibilityHint(isAnalyzing ? "Analyzing" : "Tap to capture")
    }

    // MARK: - Result Banner
    private var resultBanner: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(bannerColor)
                .frame(height: 180)
                .overlay(
                    HStack(spacing: 20) {
                        // Icon
                        Image(systemName: resultIcon)
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(.white)

                        // Text
                        Text(resultText)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                )
                .shadow(color: bannerColor.opacity(0.5), radius: 10, x: 0, y: -5)
        }
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(resultText.isEmpty ? "" : resultText)
    }

    // MARK: - Computed Properties for Result
    private var bannerColor: Color {
        switch classificationResult {
        case .hotDog:
            return Color.green
        case .notHotDog:
            return Color.red
        case .none:
            return Color.gray
        }
    }

    private var resultIcon: String {
        switch classificationResult {
        case .hotDog:
            return "checkmark.circle.fill"
        case .notHotDog:
            return "xmark.circle.fill"
        case .none:
            return "questionmark.circle.fill"
        }
    }

    private var resultText: String {
        switch classificationResult {
        case .hotDog:
            return "HOT DOG"
        case .notHotDog:
            return "NOT HOT DOG"
        case .none:
            return ""
        }
    }

    // MARK: - Actions
    private func captureAndClassify() {
        isAnalyzing = true

        // If UI tests requested a mock result, bypass camera capture
        if ImageClassifier.overrideMode != nil {
            let size = CGSize(width: 32, height: 32)
            let image = UIGraphicsImageRenderer(size: size).image { ctx in
                UIColor.black.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            self.capturedImage = image
            self.classifyAndPresent(image: image)
            return
        }

        // Capture the current frame
        cameraManager.capturePhoto { image in
            guard let image = image else {
                isAnalyzing = false
                return
            }

            self.capturedImage = image
            self.classifyAndPresent(image: image)
        }
    }

    private func classifyAndPresent(image: UIImage) {
        // Classify the image
        classifier.classify(image: image) { isHotDog in
            DispatchQueue.main.async {
                self.classificationResult = isHotDog ? .hotDog : .notHotDog
                self.isAnalyzing = false

                // Animate the result banner
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    self.showResult = true
                }

                // Add haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(isHotDog ? .success : .error)

                // Play sound effect
                self.soundManager.playSound(for: self.classificationResult)
            }
        }
    }

    private func resetToCamera() {
        withAnimation(.easeOut(duration: 0.3)) {
            showResult = false
            classificationResult = .none
            capturedImage = nil
        }
    }
}

// MARK: - Camera Preview View (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black

        // Add the preview layer
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame on layout changes
        DispatchQueue.main.async {
            if let previewLayer = cameraManager.previewLayer {
                previewLayer.frame = uiView.bounds
                if let connection = previewLayer.connection, connection.isVideoOrientationSupported {
                    let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.interfaceOrientation
                    switch orientation {
                    case .portrait:
                        connection.videoOrientation = .portrait
                    case .portraitUpsideDown:
                        connection.videoOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        connection.videoOrientation = .landscapeLeft
                    case .landscapeRight:
                        connection.videoOrientation = .landscapeRight
                    default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
