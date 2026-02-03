import XCTest

final class OfflineCardsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddNewCard() throws {
        // Tap the add button
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Fill in card details
        let cardNumberField = app.textFields["cardNumberField"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 2))
        cardNumberField.tap()
        cardNumberField.typeText("1234567890")

        let storeNameField = app.textFields["storeNameField"]
        XCTAssertTrue(storeNameField.exists)
        storeNameField.tap()
        storeNameField.typeText("Test Store")

        // Save the card
        app.buttons["saveButton"].tap()

        // Verify card appears in list
        XCTAssertTrue(app.staticTexts["Test Store"].waitForExistence(timeout: 2))
    }

    func testToggleBetweenListAndGridView() throws {
        // Add a test card first
        addTestCard()

        // Find toggle button (grid/list icon)
        let initialViewMode = app.navigationBars.buttons.matching(
            NSPredicate(format: "identifier CONTAINS[c] 'grid' OR identifier CONTAINS[c] 'list'")
        ).element

        XCTAssertTrue(initialViewMode.exists)
        initialViewMode.tap()

        // View should still show the card
        XCTAssertTrue(app.buttons["Test Store"].exists)

        // Toggle back
        let toggledViewMode = app.navigationBars.buttons.matching(
            NSPredicate(format: "identifier CONTAINS[c] 'grid' OR identifier CONTAINS[c] 'list'")
        ).element
        toggledViewMode.tap()
        XCTAssertTrue(app.buttons["Test Store"].exists)
    }

    func testSearchFunctionality() throws {
        // Add multiple test cards
        addTestCard(number: "1111111111", store: "Metro")
        addTestCard(number: "2222222222", store: "Selgros")
        addTestCard(number: "3333333333", store: "Costco")

        // Search for "Metro"
        let searchField = app.searchFields.firstMatch
        searchField.tap()
        searchField.typeText("Metro")

        // Only Metro should be visible (check buttons since we're in grid view)
        XCTAssertTrue(app.buttons["Metro"].exists)
        XCTAssertFalse(app.buttons["Selgros"].exists)
        XCTAssertFalse(app.buttons["Costco"].exists)

        // Clear search by clearing text
        searchField.tap()
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5)
        searchField.typeText(deleteString)

        // Dismiss keyboard
        app.keyboards.buttons["search"].tap()

        // All cards should be visible again
        XCTAssertTrue(app.buttons["Metro"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Selgros"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Costco"].waitForExistence(timeout: 2))
    }

    func testViewCardDetails() throws {
        addTestCard()

        // Tap on the card
        app.buttons["Test Store"].firstMatch.tap()

        // Verify detail view is shown
        XCTAssertTrue(app.navigationBars["Test Store"].exists)
        // Card number is formatted with spaces: "12 3456 7890"
        XCTAssertTrue(app.staticTexts["12 3456 7890"].exists)

        // Verify barcode/QR code is displayed
        XCTAssertGreaterThan(app.images.count, 0)
    }

    func testEditCard() throws {
        addTestCard()

        // Navigate to detail view
        app.buttons["Test Store"].firstMatch.tap()

        // Tap edit button
        app.buttons["editButton"].tap()

        // Change store name
        let storeNameField = app.textFields["storeNameField"]
        storeNameField.tap()
        storeNameField.clearText()
        storeNameField.typeText("Updated Store")

        // Save
        app.buttons["saveButton"].tap()

        // Verify updated name is shown
        XCTAssertTrue(app.navigationBars["Updated Store"].exists)
    }

    func testDeleteCard() throws {
        let uniqueStoreName = "DeleteTest\(UUID().uuidString.prefix(8))"
        addTestCard(number: "9999999999", store: uniqueStoreName)

        // Navigate to detail view
        app.buttons[uniqueStoreName].firstMatch.tap()

        // Tap delete button
        app.buttons["deleteButton"].tap()

        // Confirm deletion (alert buttons are not localized in our code)
        app.alerts.buttons.element(boundBy: 1).tap()

        // Wait for navigation back to list
        XCTAssertTrue(app.navigationBars.buttons.matching(identifier: "plus").element.waitForExistence(timeout: 2))

        // Verify card is removed
        XCTAssertFalse(app.buttons[uniqueStoreName].exists)
    }

    func testAddCardWithQRCode() throws {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let cardNumberField = app.textFields["cardNumberField"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 2))
        cardNumberField.tap()
        cardNumberField.typeText("9999999999")

        let storeNameField = app.textFields["storeNameField"]
        storeNameField.tap()
        storeNameField.typeText("QR Store")

        // Toggle QR code
        app.switches.firstMatch.tap()

        app.buttons["saveButton"].tap()

        // Verify card was added
        XCTAssertTrue(app.staticTexts["QR Store"].waitForExistence(timeout: 2))
    }

    func testCancelAddCard() throws {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let cardNumberField = app.textFields["cardNumberField"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 2))
        cardNumberField.tap()
        cardNumberField.typeText("5555555555")

        // Cancel without saving
        app.buttons["cancelButton"].tap()

        // Card should not be added
        XCTAssertFalse(app.staticTexts["5555555555"].exists)
    }

    func testAddPhotosButtonExists() throws {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Verify "Add Photos" menu button exists in the form
        let addPhotosButton = app.buttons["addPhotosButton"]
        XCTAssertTrue(addPhotosButton.waitForExistence(timeout: 2))

        // Note: Menu items (Choose from Library, Take Photo) are difficult to test
        // in UI tests due to SwiftUI Menu accessibility limitations.
        // The camera availability check is tested implicitly - on simulator
        // the "Take Photo" option is hidden, preventing crashes.
    }

    func testScanButtonHiddenOnSimulator() throws {
        // On simulator, camera is not available, so scan button should be hidden
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        // Wait for form to appear
        let cardNumberField = app.textFields["cardNumberField"]
        XCTAssertTrue(cardNumberField.waitForExistence(timeout: 2))

        // Scan button should NOT exist on simulator (no camera)
        let scanButton = app.buttons["scanButton"]
        XCTAssertFalse(scanButton.exists, "Scan button should be hidden on simulator (no camera)")
    }

    // MARK: - Helper Methods

    private func addTestCard(number: String = "1234567890", store: String = "Test Store") {
        app.navigationBars.buttons.matching(identifier: "plus").element.tap()

        let cardNumberField = app.textFields["cardNumberField"]
        _ = cardNumberField.waitForExistence(timeout: 2)
        cardNumberField.tap()
        cardNumberField.typeText(number)

        let storeNameField = app.textFields["storeNameField"]
        storeNameField.tap()
        storeNameField.typeText(store)

        app.buttons["saveButton"].tap()

        // Wait for card to appear
        _ = app.staticTexts[store].waitForExistence(timeout: 2)
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}
