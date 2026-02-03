@testable import OfflineCards
import XCTest

final class CardModelTests: XCTestCase {
    func testCardInitialization() {
        let card = Card(
            cardNumber: "1234567890",
            storeName: "Test Store",
            holderName: "John Doe",
            useQRCode: true,
            colorHex: "#FF5733"
        )

        XCTAssertEqual(card.cardNumber, "1234567890")
        XCTAssertEqual(card.storeName, "Test Store")
        XCTAssertEqual(card.holderName, "John Doe")
        XCTAssertTrue(card.useQRCode)
        XCTAssertEqual(card.colorHex, "#FF5733")
        XCTAssertNil(card.photoData)
    }

    func testCardDefaultValues() {
        let card = Card(
            cardNumber: "9876543210",
            storeName: "Another Store"
        )

        XCTAssertEqual(card.cardNumber, "9876543210")
        XCTAssertEqual(card.storeName, "Another Store")
        XCTAssertNil(card.holderName)
        XCTAssertFalse(card.useQRCode)
        XCTAssertEqual(card.colorHex, "#007AFF")
        XCTAssertNil(card.photoData)
    }

    func testCardExportData() {
        let card = Card(
            cardNumber: "1111111111",
            storeName: "Export Test",
            holderName: "Jane Smith",
            useQRCode: false,
            colorHex: "#00FF00"
        )

        let exportData = card.toExportData()

        XCTAssertEqual(exportData.cardNumber, "1111111111")
        XCTAssertEqual(exportData.storeName, "Export Test")
        XCTAssertEqual(exportData.holderName, "Jane Smith")
        XCTAssertFalse(exportData.useQRCode)
        XCTAssertEqual(exportData.colorHex, "#00FF00")
    }

    func testCardFromExportData() {
        let exportData = Card.ExportData(
            cardNumber: "2222222222",
            storeName: "Import Test",
            holderName: "Bob Brown",
            useQRCode: true,
            colorHex: "#0000FF",
            photoDataBase64: nil,
            createdAt: Date()
        )

        let card = Card.fromExportData(exportData)

        XCTAssertEqual(card.cardNumber, "2222222222")
        XCTAssertEqual(card.storeName, "Import Test")
        XCTAssertEqual(card.holderName, "Bob Brown")
        XCTAssertTrue(card.useQRCode)
        XCTAssertEqual(card.colorHex, "#0000FF")
    }

    func testCardWithPhotoData() {
        let photoData = [Data("test1".utf8), Data("test2".utf8)]
        let card = Card(
            cardNumber: "3333333333",
            storeName: "Photo Test",
            photoData: photoData
        )

        XCTAssertEqual(card.photoData?.count, 2)

        let exportData = card.toExportData()
        XCTAssertEqual(exportData.photoDataBase64?.count, 2)

        let reimportedCard = Card.fromExportData(exportData)
        XCTAssertEqual(reimportedCard.photoData?.count, 2)
    }
}
