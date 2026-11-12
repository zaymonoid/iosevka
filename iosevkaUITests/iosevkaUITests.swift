//
//  iosevkaUITests.swift
//  iosevkaUITests
//
//  Created by Zaymon Antonio on 5/10/2023.
//

import XCTest

final class iosevkaUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// End game asks first, then shows the summary.
    func testEndingAGameEarly() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Single Player"].tap()
        XCTAssertTrue(app.otherElements["Letter board"].waitForExistence(timeout: 5))

        app.buttons["End game"].tap()
        XCTAssertTrue(app.buttons["End Game"].waitForExistence(timeout: 5))
        app.buttons["End Game"].tap()

        XCTAssertTrue(app.buttons["Menu"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Rotate board"].exists)
        app.buttons["Menu"].tap()
        XCTAssertTrue(app.buttons["Single Player"].waitForExistence(timeout: 5))
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
