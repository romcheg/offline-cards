@testable import OfflineCards
import XCTest

final class BarcodeServiceTests: XCTestCase {
    func testGenerateBarcodeFromValidString() throws {
        let image = try BarcodeService.generateCode(from: "1234567890", asQRCode: false)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testGenerateQRCodeFromValidString() throws {
        let image = try BarcodeService.generateCode(from: "1234567890", asQRCode: true)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testGenerateHighResBarcodeFromValidString() throws {
        let image = try BarcodeService.generateHighResCode(from: "1234567890", asQRCode: false)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testGenerateHighResQRCodeFromValidString() throws {
        let image = try BarcodeService.generateHighResCode(from: "1234567890", asQRCode: true)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    func testGenerateBarcodeFromEmptyStringThrowsError() {
        XCTAssertThrowsError(try BarcodeService.generateCode(from: "", asQRCode: false)) { error in
            XCTAssertEqual(error as? BarcodeService.BarcodeError, .invalidInput)
        }
    }

    func testGenerateQRCodeFromEmptyStringThrowsError() {
        XCTAssertThrowsError(try BarcodeService.generateCode(from: "", asQRCode: true)) { error in
            XCTAssertEqual(error as? BarcodeService.BarcodeError, .invalidInput)
        }
    }

    func testHighResBarcodeIsLargerThanNormal() throws {
        let normalImage = try BarcodeService.generateCode(from: "1234567890", asQRCode: false)
        let highResImage = try BarcodeService.generateHighResCode(from: "1234567890", asQRCode: false)

        XCTAssertGreaterThan(highResImage.size.width, normalImage.size.width)
    }

    func testBarcodeWithDifferentInput() throws {
        let image1 = try BarcodeService.generateCode(from: "1111111111", asQRCode: false)
        let image2 = try BarcodeService.generateCode(from: "9999999999", asQRCode: false)

        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertNotEqual(image1.pngData(), image2.pngData())
    }

    func testQRCodeWithAlphanumericString() throws {
        let image = try BarcodeService.generateCode(from: "ABC123XYZ", asQRCode: true)
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }
}
