import XCTest

final class NotHotDogUITests: XCTestCase {

    func testHotDogFlowWithMock() {
        let app = XCUIApplication()
        app.launchEnvironment["SEEFOOD_MOCK_RESULT"] = "hotdog"
        app.launch()

        let capture = app.buttons["Capture and classify"]
        XCTAssertTrue(capture.waitForExistence(timeout: 3))
        capture.tap()

        let result = app.staticTexts["HOT DOG"]
        XCTAssertTrue(result.waitForExistence(timeout: 3))
    }

    func testNotHotDogFlowWithMock() {
        let app = XCUIApplication()
        app.launchEnvironment["SEEFOOD_MOCK_RESULT"] = "nothotdog"
        app.launch()

        let capture = app.buttons["Capture and classify"]
        XCTAssertTrue(capture.waitForExistence(timeout: 3))
        capture.tap()

        let result = app.staticTexts["NOT HOT DOG"]
        XCTAssertTrue(result.waitForExistence(timeout: 3))
    }
}

