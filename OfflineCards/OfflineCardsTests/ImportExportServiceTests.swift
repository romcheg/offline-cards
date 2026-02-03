@testable import OfflineCards
import XCTest

final class ImportExportServiceTests: XCTestCase {
    func testExportSingleCard() throws {
        let card = Card(
            cardNumber: "1234567890",
            storeName: "Test Store",
            holderName: "John Doe"
        )

        let data = try ImportExportService.exportCards([card])
        XCTAssertGreaterThan(data.count, 0)

        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("1234567890") ?? false)
        XCTAssertTrue(jsonString?.contains("Test Store") ?? false)
    }

    func testExportMultipleCards() throws {
        let cards = [
            Card(cardNumber: "1111111111", storeName: "Store 1"),
            Card(cardNumber: "2222222222", storeName: "Store 2"),
            Card(cardNumber: "3333333333", storeName: "Store 3")
        ]

        let data = try ImportExportService.exportCards(cards)
        XCTAssertGreaterThan(data.count, 0)

        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertTrue(jsonString?.contains("1111111111") ?? false)
        XCTAssertTrue(jsonString?.contains("2222222222") ?? false)
        XCTAssertTrue(jsonString?.contains("3333333333") ?? false)
    }

    func testExportEmptyArrayThrowsError() {
        XCTAssertThrowsError(try ImportExportService.exportCards([])) { error in
            XCTAssertEqual(error as? ImportExportService.ExportError, .noCardsToExport)
        }
    }

    func testImportExportRoundTrip() throws {
        let originalCards = [
            Card(
                cardNumber: "1234567890",
                storeName: "Store A",
                holderName: "Alice",
                useQRCode: false,
                colorHex: "#FF0000"
            ),
            Card(
                cardNumber: "0987654321",
                storeName: "Store B",
                holderName: nil,
                useQRCode: true,
                colorHex: "#00FF00"
            )
        ]

        let exportedData = try ImportExportService.exportCards(originalCards)
        let importedCards = try ImportExportService.importCards(from: exportedData)

        XCTAssertEqual(importedCards.count, originalCards.count)

        for (imported, original) in zip(importedCards, originalCards) {
            XCTAssertEqual(imported.cardNumber, original.cardNumber)
            XCTAssertEqual(imported.storeName, original.storeName)
            XCTAssertEqual(imported.holderName, original.holderName)
            XCTAssertEqual(imported.useQRCode, original.useQRCode)
            XCTAssertEqual(imported.colorHex, original.colorHex)
        }
    }

    func testImportInvalidDataThrowsError() {
        let invalidData = Data("invalid json".utf8)
        XCTAssertThrowsError(try ImportExportService.importCards(from: invalidData)) { error in
            XCTAssertEqual(error as? ImportExportService.ImportError, .decodingFailed)
        }
    }

    func testFindDuplicates() {
        let existingCards = [
            Card(cardNumber: "1111111111", storeName: "Store 1"),
            Card(cardNumber: "2222222222", storeName: "Store 2"),
            Card(cardNumber: "3333333333", storeName: "Store 3")
        ]

        let importedCards = [
            Card(cardNumber: "2222222222", storeName: "Store 2 Updated"),
            Card(cardNumber: "4444444444", storeName: "Store 4"),
            Card(cardNumber: "3333333333", storeName: "Store 3 Updated")
        ]

        let duplicates = ImportExportService.findDuplicates(
            importedCards: importedCards,
            existingCards: existingCards
        )

        XCTAssertEqual(duplicates.count, 2)
        XCTAssertTrue(duplicates.contains("2222222222"))
        XCTAssertTrue(duplicates.contains("3333333333"))
        XCTAssertFalse(duplicates.contains("4444444444"))
    }

    func testIsDuplicate() {
        let existingCards = [
            Card(cardNumber: "1111111111", storeName: "Store 1"),
            Card(cardNumber: "2222222222", storeName: "Store 2")
        ]

        let duplicateCard = Card(cardNumber: "1111111111", storeName: "Different Name")
        let uniqueCard = Card(cardNumber: "9999999999", storeName: "Unique Store")

        XCTAssertTrue(ImportExportService.isDuplicate(card: duplicateCard, in: existingCards))
        XCTAssertFalse(ImportExportService.isDuplicate(card: uniqueCard, in: existingCards))
    }

    func testExportWithPhotoData() throws {
        let photoData = [Data("image1".utf8), Data("image2".utf8)]
        let card = Card(
            cardNumber: "5555555555",
            storeName: "Photo Store",
            photoData: photoData
        )

        let exportedData = try ImportExportService.exportCards([card])
        let importedCards = try ImportExportService.importCards(from: exportedData)

        XCTAssertEqual(importedCards.count, 1)
        XCTAssertEqual(importedCards[0].photoData?.count, 2)
        XCTAssertEqual(importedCards[0].photoData?[0], Data("image1".utf8))
        XCTAssertEqual(importedCards[0].photoData?[1], Data("image2".utf8))
    }

    func testExportContainerHasVersionAndDate() throws {
        let card = Card(cardNumber: "6666666666", storeName: "Version Test")
        let data = try ImportExportService.exportCards([card])

        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("\"version\"") ?? false)
        XCTAssertTrue(jsonString?.contains("\"exportDate\"") ?? false)
    }
}
