//
//  ImageClassifier.swift
//  Not Hot Dog
//
//  Vision framework classifier - Hot Dog or Not Hot Dog
//  Binary classification logic
//

import Vision
import UIKit
import CoreML
import ImageIO
import os

// MARK: - ImageClassifier
@MainActor
class ImageClassifier: ObservableObject {
    private let log = Logger(subsystem: "com.nothotdog.app", category: "classifier")

    // MARK: - Constants
    private let confidenceThreshold: Float = 0.80

    // MARK: - Test Overrides
    enum ManualResult { case hotDog, notHotDog }
    static var overrideMode: ManualResult? = nil

    // Hot dog label variations to check against
    // @Codex: Expand this list if MobileNet uses different label conventions
    private let hotDogLabels: Set<String> = [
        "hot dog",
        "hotdog",
        "hot_dog",
        "frankfurter",
        "frank",
        "wiener",
        "weiner",
        "red hot",
        "vienna sausage",
        "chili dog"
    ]

    // MARK: - Classification Method
    /// Classifies an image as Hot Dog or Not Hot Dog
    /// - Parameters:
    ///   - image: The UIImage to classify
    ///   - completion: Returns true if hot dog detected with confidence > 80%, false otherwise
    func classify(image: UIImage, completion: @escaping (Bool) -> Void) {

        // Short-circuit for UI tests when override is set
        if let override = Self.overrideMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                completion(override == .hotDog)
            }
            return
        }

        // Downsize image to improve performance
        let inputImage = image.resizedForClassification(targetSize: CGSize(width: 448, height: 448)) ?? image

        // @Codex: Optimize this buffer conversion for large images
        guard let cgImage = inputImage.cgImage else {
            log.error("Could not get CGImage from UIImage")
            completion(false)
            return
        }

        // Create the Vision classification request
        let request = createClassificationRequest { [weak self] result in
            guard let self = self else {
                completion(false)
                return
            }

            switch result {
            case .success(let observations):
                let isHotDog = self.checkForHotDog(in: observations)
                completion(isHotDog)

            case .failure(let error):
                self.log.error("Classification failed: \(error.localizedDescription)")
                completion(false)
            }
        }

        // Perform the request
        // Preserve orientation from the original UIImage
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        performClassification(request: request, on: cgImage, orientation: orientation)
    }

    // MARK: - Request Creation
    // @Codex: Consider using a custom CoreML model for better hot dog accuracy
    private func createClassificationRequest(
        completion: @escaping (Result<[VNClassificationObservation], Error>) -> Void
    ) -> VNImageBasedRequest {

        // Use the built-in Vision classifier (uses Apple's neural engine)
        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNClassificationObservation] else {
                completion(.failure(ClassificationError.noResults))
                return
            }

            completion(.success(observations))
        }

        // Use the system's current revision when available (lets OS pick best model)
        if #available(iOS 15.0, *) {
            request.revision = VNClassifyImageRequest.currentRevision
        }

        return request
    }

    // MARK: - Classification Execution
    // @Codex: Optimize this for batch processing if needed
    private func performClassification(request: VNImageBasedRequest, on cgImage: CGImage, orientation: CGImagePropertyOrientation) {
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: orientation,
            options: [:]
        )

        // Run on background queue for performance
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                self.log.error("Failed to perform classification: \(String(describing: error))")
            }
        }
    }

    // MARK: - Hot Dog Detection Logic
    /// The core binary classification logic
    /// Checks if any observation matches hot dog labels with sufficient confidence
    // @Codex: Optimize this matching algorithm for large observation sets
    func checkForHotDog(in observations: [VNClassificationObservation]) -> Bool {

        // Debug: Print top 5 classifications
        #if DEBUG
        log.debug("Top classifications: \(observations.prefix(5).map { \"\($0.identifier) \(Int($0.confidence*100))%\" }.joined(separator: ", "))")
        #endif

        // Check each observation for hot dog match
        for observation in observations {
            let identifier = observation.identifier.lowercased()
            let confidence = observation.confidence

            // Check if this is a hot dog label
            if isHotDogLabel(identifier) {
                log.info("HOT DOG DETECTED: '\(identifier)' with \(Int(confidence * 100))% confidence")

                // Apply the 80% confidence threshold
                if confidence >= confidenceThreshold {
                    return true
                } else {
                    log.debug("Below confidence threshold (\(Int(confidenceThreshold * 100))%)")
                }
            }
        }

        // No hot dog found with sufficient confidence
        return false
    }

    // MARK: - Label Matching
    /// Checks if a label string matches known hot dog identifiers
    func isHotDogLabel(_ label: String) -> Bool {
        let normalizedLabel = label.lowercased().trimmingCharacters(in: .whitespaces)

        // Direct match
        if hotDogLabels.contains(normalizedLabel) {
            return true
        }

        // Partial match (for labels like "hot dog, frankfurter")
        for hotDogLabel in hotDogLabels {
            if normalizedLabel.contains(hotDogLabel) {
                return true
            }
        }

        return false
    }
}

// MARK: - Error Types
enum ClassificationError: Error, LocalizedError {
    case noResults
    case modelLoadFailed
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No classification results returned"
        case .modelLoadFailed:
            return "Failed to load ML model"
        case .imageProcessingFailed:
            return "Failed to process image for classification"
        }
    }
}

// MARK: - UIImage Extension for Preprocessing
extension UIImage {

    /// Resizes image for optimal classification performance
    // @Codex: Optimize this resize for memory efficiency on older devices
    func resizedForClassification(targetSize: CGSize = CGSize(width: 224, height: 224)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - Orientation Helpers
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
