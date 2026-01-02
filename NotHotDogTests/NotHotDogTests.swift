import XCTest
@testable import NotHotDog

final class NotHotDogTests: XCTestCase {

    func testIsHotDogLabel_DirectMatches() {
        let classifier = ImageClassifier()
        let labels = ["hot dog", "hotdog", "hot_dog", "frankfurter", "frank", "wiener", "weiner", "red hot", "vienna sausage", "chili dog"]
        for label in labels {
            XCTAssertTrue(classifier.isHotDogLabel(label), "Expected direct match for \(label)")
        }
    }

    func testIsHotDogLabel_CommaSeparated() {
        let classifier = ImageClassifier()
        XCTAssertTrue(classifier.isHotDogLabel("hot dog, frankfurter"))
        XCTAssertTrue(classifier.isHotDogLabel("Pizza, hotdog style"))
    }

    func testIsHotDogLabel_NegativeCases() {
        let classifier = ImageClassifier()
        let negatives = ["pizza", "sausage", "burger", "sandwich", "red house", "vienna" ]
        for label in negatives {
            XCTAssertFalse(classifier.isHotDogLabel(label), "Did not expect match for \(label)")
        }
    }

    func testResizedForClassification_DefaultSize() {
        let original = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 50)).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 50))
        }
        let resized = original.resizedForClassification()
        XCTAssertNotNil(resized)
        XCTAssertEqual(resized?.size.width, 224, accuracy: 0.5)
        XCTAssertEqual(resized?.size.height, 224, accuracy: 0.5)
    }

    func testResizedForClassification_CustomSize() {
        let original = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        let target = CGSize(width: 448, height: 320)
        let resized = original.resizedForClassification(targetSize: target)
        XCTAssertNotNil(resized)
        XCTAssertEqual(resized?.size.width, target.width, accuracy: 0.5)
        XCTAssertEqual(resized?.size.height, target.height, accuracy: 0.5)
    }
}
