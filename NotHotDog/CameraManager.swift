//
//  CameraManager.swift
//  Not Hot Dog
//
//  AVFoundation camera handling for hot dog detection
//

import AVFoundation
import UIKit
import SwiftUI
import os

// MARK: - CameraManager
class CameraManager: NSObject, ObservableObject {
    private let log = Logger(subsystem: "com.nothotdog.app", category: "camera")

    // MARK: - Published Properties
    @Published var showPermissionAlert = false
    @Published var isSessionRunning = false

    // MARK: - AVFoundation Properties
    private let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.seefood.camera.session")

    // Preview layer for SwiftUI
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    // Photo capture completion handler
    private var photoCaptureCompletion: ((UIImage?) -> Void)?

    // MARK: - Initialization
    override init() {
        super.init()
        setupPreviewLayer()
    }

    // MARK: - Preview Layer Setup
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
    }

    // MARK: - Permission Handling
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCaptureSession()
                } else {
                    self?.showPermissionAlert = true
                }
            }
        }
    }

    // MARK: - Capture Session Setup
    // @Codex: Review session configuration for optimal performance on older devices
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo

            // Add video input
            do {
                guard let videoDevice = self.getPreferredCamera() else {
                    self.log.error("No camera available")
                    self.captureSession.commitConfiguration()
                    return
                }

                let videoInput = try AVCaptureDeviceInput(device: videoDevice)

                if self.captureSession.canAddInput(videoInput) {
                    self.captureSession.addInput(videoInput)
                    self.videoDeviceInput = videoInput
                } else {
                    self.log.error("Could not add video input")
                    self.captureSession.commitConfiguration()
                    return
                }
            } catch {
                self.log.error("Could not create video input: \(String(describing: error))")
                self.captureSession.commitConfiguration()
                return
            }

            // Add photo output
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .balanced
            } else {
                self.log.error("Could not add photo output")
                self.captureSession.commitConfiguration()
                return
            }

            self.captureSession.commitConfiguration()

            // Start the session
            self.captureSession.startRunning()
            self.log.log(level: .info, "Capture session started")

            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        }
    }

    // MARK: - Camera Selection
    // @Codex: Optimize camera selection for different device capabilities
    private func getPreferredCamera() -> AVCaptureDevice? {
        // Prefer the back dual camera, then wide angle, then any available
        let deviceTypes: [AVCaptureDevice.DeviceType] = [
            .builtInDualCamera,
            .builtInDualWideCamera,
            .builtInWideAngleCamera,
            .builtInTelephotoCamera
        ]

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .back
        )

        // Return the first available device
        return discoverySession.devices.first ?? AVCaptureDevice.default(for: .video)
    }

    // MARK: - Photo Capture
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.photoCaptureCompletion = completion

        sessionQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            var photoSettings = AVCapturePhotoSettings()

            // Configure photo settings
            if self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }

            photoSettings.isHighResolutionPhotoEnabled = true
            photoSettings.flashMode = .auto

            // Capture the photo
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }

    // MARK: - Session Control
    func startSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = self?.captureSession.isRunning ?? false
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.log.log(level: .info, "Capture session stopped")
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {

    // @Codex: Optimize this buffer conversion for memory efficiency
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            self.log.error("Photo capture failed: \(error.localizedDescription)")
            Task { @MainActor in
                self.photoCaptureCompletion?(nil)
            }
            return
        }

        // Convert to UIImage
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            self.log.error("Could not create image from photo data")
            Task { @MainActor in
                self.photoCaptureCompletion?(nil)
            }
            return
        }

        // Return the captured image
        Task { @MainActor in
            self.photoCaptureCompletion?(image)
        }
    }
}
