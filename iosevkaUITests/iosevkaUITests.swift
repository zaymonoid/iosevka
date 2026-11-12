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

    /// Scanning an invite abandons a solo game in progress and holds the board
    /// back until Start. Rematch goes to round 2 on a new board, no scanning.
    func testOpeningADuelInviteAndRematching() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Single Player"].tap()
        let board = app.otherElements["Letter board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))

        app.open(URL(string: "iosevka://duel?s=8F3A21C07E5D9B10")!)

        XCTAssertTrue(app.staticTexts["Get ready"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["HEAD TO HEAD · ROUND 1"].exists)
        XCTAssertTrue(app.otherElements["Hidden board"].exists)
        XCTAssertFalse(board.exists)

        app.buttons["Start"].tap()
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let firstBoard = try XCTUnwrap(board.value as? String)

        app.buttons["End game"].tap()
        app.buttons["End Game"].tap()
        XCTAssertTrue(app.buttons["Rematch"].waitForExistence(timeout: 5))
        app.buttons["Rematch"].tap()

        XCTAssertTrue(app.staticTexts["HEAD TO HEAD · ROUND 2"].waitForExistence(timeout: 5))
        app.buttons["Start"].tap()
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertNotEqual(board.value as? String, firstBoard)
    }

    /// Hosting shows an invite code, then the ready screen; Start plays.
    /// DuelTests checks that host and guest get the same board.
    func testHostingADuel() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Head to Head"].tap()

        XCTAssertTrue(app.staticTexts["Scan to join"].waitForExistence(timeout: 5))
        let code = app.otherElements["Invite code"]
        XCTAssertTrue(code.exists)
        let url = try XCTUnwrap(code.value as? String)
        XCTAssertTrue(url.hasPrefix("iosevka://duel?s="), url)

        // The simulator has no camera to scan with, so the sheet says so.
        app.buttons["Scan a friend's code instead"].tap()
        XCTAssertTrue(app.navigationBars["Scan a friend's code"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Scan to join"].waitForExistence(timeout: 5))

        // Ready shows the same face-down board the guest sees.
        app.buttons["Ready"].tap()
        XCTAssertTrue(app.staticTexts["Get ready"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["Hidden board"].exists)
        app.buttons["Start"].tap()

        XCTAssertTrue(app.otherElements["Letter board"].waitForExistence(timeout: 5))
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
